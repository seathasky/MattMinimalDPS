local ADDON_NAME = ... or "MattMinimalDPS"
local f=CreateFrame("Frame")
local LibStub = LibStub or _G.LibStub
local DEFAULT_FONT_PATH="Interface\\AddOns\\MattMinimalDPS\\Fonts\\Naowh.ttf"
local FONT_PATH=DEFAULT_FONT_PATH
local DEFAULT_FONT_SIZE=12
local FONT_SIZE=DEFAULT_FONT_SIZE
local FONT_FLAGS="OUTLINE"
local GUI_FONT_PATH=DEFAULT_FONT_PATH
local GUI_FONT_SIZE=12
local GUI_FONT_FLAGS="OUTLINE"
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local FONT_MEDIA_TYPE = LSM and LSM.MediaType and LSM.MediaType.FONT or "font"
local MMDPS_FONT_DEFAULT = "MMDPS Naowh"
local fontValidationString = nil
local fontApplyToken = 0
local FONT_SIZE_KEYS = {"entryName", "entryValue", "typeLabel", "sessionName", "sessionTimer"}
local FONT_SIZE_DEFAULTS = {
 entryName = 12,
 entryValue = 12,
 typeLabel = 12,
 sessionName = 12,
 sessionTimer = 12,
}

local function NormalizeMediaName(value)
 if type(value) ~= "string" then return nil end
 local trimmed = value:match("^%s*(.-)%s*$")
 if not trimmed or trimmed == "" then return nil end
 return trimmed
end

local function MediaNamesEqual(a, b)
 local left = NormalizeMediaName(a)
 local right = NormalizeMediaName(b)
 if not left or not right then return false end
 return left:lower() == right:lower()
end

local function ClampFontSize(value)
 local n = math.floor(tonumber(value) or DEFAULT_FONT_SIZE)
 if n < 8 then n = 8 end
 if n > 20 then n = 20 end
 return n
end

local function GetItemFontSize(key)
 if MattMinimalDPSDB and MattMinimalDPSDB.fontSizes and MattMinimalDPSDB.fontSizes[key] then
  return ClampFontSize(MattMinimalDPSDB.fontSizes[key])
 end
 return ClampFontSize(FONT_SIZE_DEFAULTS[key] or DEFAULT_FONT_SIZE)
end

local function EnsureFontSizeSettings()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.fontSizes = MattMinimalDPSDB.fontSizes or {}
 for _, key in ipairs(FONT_SIZE_KEYS) do
  MattMinimalDPSDB.fontSizes[key] = ClampFontSize(MattMinimalDPSDB.fontSizes[key] or FONT_SIZE_DEFAULTS[key])
 end
end

local function GetFontValidationString()
 if fontValidationString then return fontValidationString end
 if not UIParent then return nil end
 local probe = UIParent:CreateFontString(nil, "OVERLAY")
 probe:Hide()
 fontValidationString = probe
 return fontValidationString
end

local function IsUsableFontPath(fontPath)
 if type(fontPath) ~= "string" or fontPath == "" then return false end
 local probe = GetFontValidationString()
 if not probe then return false end
 local ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "OUTLINE")
 if ok and applied ~= false then return true end
 ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "")
 return ok and applied ~= false
end

local function MMDPS_SetFontSafe(region, fontPath, size, flags)
 if not region or not region.SetFont then return false end
 local requestedPath = (type(fontPath) == "string" and fontPath ~= "") and fontPath or DEFAULT_FONT_PATH
 local requestedSize = tonumber(size) or DEFAULT_FONT_SIZE
 local requestedFlags = flags or ""

 local ok, applied = pcall(region.SetFont, region, requestedPath, requestedSize, requestedFlags)
 if ok and applied ~= false then
  return true
 end

 if requestedFlags ~= "" then
  ok, applied = pcall(region.SetFont, region, requestedPath, requestedSize, "")
  if ok and applied ~= false then
   return true
  end
 end

 if requestedPath ~= DEFAULT_FONT_PATH then
  ok, applied = pcall(region.SetFont, region, DEFAULT_FONT_PATH, requestedSize, requestedFlags)
  if ok and applied ~= false then
   return true
  end
  ok, applied = pcall(region.SetFont, region, DEFAULT_FONT_PATH, requestedSize, "")
  if ok and applied ~= false then
   return true
  end
 end

 return false
end

local MMDPS_FONT_OBJECTS = {}

local function MMDPS_MakeFontObjectKey(size, flags)
 local sizeKey = tostring(ClampFontSize(size))
 local flagsKey = tostring(flags or ""):gsub("%s+", "_"):gsub("[^%w_]", "")
 if flagsKey == "" then
  flagsKey = "PLAIN"
 end
 return sizeKey .. "_" .. flagsKey
end

local function MMDPS_GetOrCreateFontObject(size, flags)
 local normalizedSize = ClampFontSize(size)
 local normalizedFlags = type(flags) == "string" and flags or ""
 local key = MMDPS_MakeFontObjectKey(normalizedSize, normalizedFlags)
 local entry = MMDPS_FONT_OBJECTS[key]
 if not entry then
  local globalName = "MMDPSFontObject_" .. key
  local fontObject = _G[globalName] or CreateFont(globalName)
  entry = {
   object = fontObject,
   size = normalizedSize,
   flags = normalizedFlags,
  }
  MMDPS_FONT_OBJECTS[key] = entry
 end
 MMDPS_SetFontSafe(entry.object, FONT_PATH, entry.size, entry.flags)
 return entry.object
end

local function MMDPS_RefreshFontObjects()
 for _, entry in pairs(MMDPS_FONT_OBJECTS) do
  MMDPS_SetFontSafe(entry.object, FONT_PATH, entry.size, entry.flags)
 end
end

local function MMDPS_SetRegionFont(region, size, flags)
 if not region then return false end
 local normalizedSize = ClampFontSize(size)
 local normalizedFlags = type(flags) == "string" and flags or ""

 if region.SetFontObject then
  local fontObject = MMDPS_GetOrCreateFontObject(normalizedSize, normalizedFlags)
  if fontObject then
   local ok = pcall(region.SetFontObject, region, fontObject)
   if ok then
    return true
   end
  end
 end

 return MMDPS_SetFontSafe(region, FONT_PATH, normalizedSize, normalizedFlags)
end

local function MMDPS_RegisterManagedFontString(fontString, sizeKey, defaultFlags)
 if not fontString or not fontString.SetFont or not FONT_SIZE_DEFAULTS[sizeKey] then return end
 -- Intentionally no method hooks here: hooking Blizzard DamageMeter FontString
 -- methods can taint secure update paths during combat.
end

local function MMDPS_RegisterFontMedia()
 if not LSM then return end
 if not LSM:IsValid(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT) then
  LSM:Register(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT, DEFAULT_FONT_PATH)
 end
end

local function MMDPS_GetFontMediaTable()
 if not LSM or not LSM.HashTable then return nil end
 local ok, mediaTable = pcall(LSM.HashTable, LSM, FONT_MEDIA_TYPE)
 if ok and type(mediaTable) == "table" then
  return mediaTable
 end
 return nil
end

local function MMDPS_FindFontKey(mediaTable, fontName)
 if type(mediaTable) ~= "table" then return nil end
 local selected = NormalizeMediaName(fontName)
 if not selected then return nil end
 if mediaTable[selected] then return selected end
 for key in pairs(mediaTable) do
  if MediaNamesEqual(key, selected) then
   return key
  end
 end
 return nil
end

local function MMDPS_GetUsableFontPath(path)
 if type(path) ~= "string" then return nil end
 local trimmed = path:match("^%s*(.-)%s*$")
 if not trimmed or trimmed == "" then return nil end
 return trimmed
end

local function MMDPS_ClearSavedGlobalFontPath()
 if type(MattMinimalDPSDB) ~= "table" then return end
 MattMinimalDPSDB.globalFontPath = nil
 MattMinimalDPSDB.globalFontPathName = nil
end

local function MMDPS_SetSavedGlobalFontPath(fontName, fontPath)
 if type(MattMinimalDPSDB) ~= "table" then return end
 local normalizedName = NormalizeMediaName(fontName)
 local normalizedPath = MMDPS_GetUsableFontPath(fontPath)
 if not normalizedName or not normalizedPath then
  MMDPS_ClearSavedGlobalFontPath()
  return
 end
 MattMinimalDPSDB.globalFontPath = normalizedPath
 MattMinimalDPSDB.globalFontPathName = normalizedName
end

local function MMDPS_GetSavedGlobalFontPath(fontName)
 if type(MattMinimalDPSDB) ~= "table" then return nil end
 local normalizedName = NormalizeMediaName(fontName)
 local savedName = NormalizeMediaName(MattMinimalDPSDB.globalFontPathName)
 if not normalizedName or not savedName or not MediaNamesEqual(normalizedName, savedName) then return nil end
 local savedPath = MMDPS_GetUsableFontPath(MattMinimalDPSDB.globalFontPath)
 if not savedPath then return nil end
 if not IsUsableFontPath(savedPath) then return nil end
 return savedPath
end

local function MMDPS_GetFontPathForName(fontName, mediaTable)
 local selected = NormalizeMediaName(fontName)
 if not selected then return nil, nil end

 if mediaTable then
  local matchedKey = MMDPS_FindFontKey(mediaTable, selected)
  if matchedKey then
   local direct = MMDPS_GetUsableFontPath(mediaTable[matchedKey])
   if direct and IsUsableFontPath(direct) then
    return direct, matchedKey
   end
  end
 end

 if LSM then
  local fetched = MMDPS_GetUsableFontPath(LSM:Fetch(FONT_MEDIA_TYPE, selected, true))
  if fetched and IsUsableFontPath(fetched) then
   return fetched, selected
  end
 end

 return nil, nil
end

local function MMDPS_GetGlobalFontPathByName(fontName)
 local selected = NormalizeMediaName(fontName) or MMDPS_FONT_DEFAULT
 local savedPath = MMDPS_GetSavedGlobalFontPath(selected)
 if savedPath then
  return savedPath, true, selected
 end

 local mediaTable = MMDPS_GetFontMediaTable()
 local selectedPath, selectedKey = MMDPS_GetFontPathForName(selected, mediaTable)
 if selectedPath then
  return selectedPath, true, selectedKey or selected
 end

 local fallbackPath, fallbackKey = MMDPS_GetFontPathForName(MMDPS_FONT_DEFAULT, mediaTable)
 if fallbackPath then
  return fallbackPath, false, fallbackKey or MMDPS_FONT_DEFAULT
 end

 if LSM then
  local defaultFetch = MMDPS_GetUsableFontPath(LSM:Fetch(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT, false))
  if defaultFetch then
   return defaultFetch, false, MMDPS_FONT_DEFAULT
  end
 end

 return DEFAULT_FONT_PATH, selected == MMDPS_FONT_DEFAULT, MMDPS_FONT_DEFAULT

end

local function MMDPS_EnsureFontSelection()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local selected = NormalizeMediaName(MattMinimalDPSDB.globalFont) or MMDPS_FONT_DEFAULT
 local mediaTable = MMDPS_GetFontMediaTable()
 if mediaTable then
  local matchedKey = MMDPS_FindFontKey(mediaTable, selected)
  if matchedKey then
   selected = matchedKey
  end
 end
 MattMinimalDPSDB.globalFont = selected
 return selected
end

local function MMDPS_GetGlobalFontName()
 return MMDPS_EnsureFontSelection()
end

local function MMDPS_GetGlobalFontPath()
 local fontPath = MMDPS_GetGlobalFontPathByName(MMDPS_GetGlobalFontName())
 return fontPath or DEFAULT_FONT_PATH
end

local function MMDPS_GetFontOptions()
 local list = {}
 local seenNames = {}
 if LSM then
  local mediaTable = MMDPS_GetFontMediaTable()
  local names = LSM:List(FONT_MEDIA_TYPE) or {}
  for _, name in ipairs(names) do
   local normalized = NormalizeMediaName(name)
   if normalized and not seenNames[normalized] then
    local fetched = MMDPS_GetFontPathForName(normalized, mediaTable)
    if fetched then
     seenNames[normalized] = true
     list[#list + 1] = normalized
    end
   end
  end
 end
 if #list == 0 or not seenNames[MMDPS_FONT_DEFAULT] then
  list[#list + 1] = MMDPS_FONT_DEFAULT
 end
 table.sort(list, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
 return list
end

local mmdps_state = setmetatable({}, { __mode = "k" })
local BACKDROP_STYLES = {
 transparent = { text = "Transparent", color = {0, 0, 0, 0} },
 black = { text = "Black", color = {0, 0, 0, 1} },
 white = { text = "White (Translucent)", color = {1, 1, 1, 0.18} },
 brown = { text = "Dark Brown", color = {0.17, 0.11, 0.07, 0.65} },
 gray = { text = "Gray", color = {0.16, 0.16, 0.16, 0.65} },
}
local BACKDROP_STYLE_ORDER = {"transparent", "white", "brown", "gray", "black"}
local DEFAULT_BACKDROP_OPACITY = 0.65

local function getBackdropStyle()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local style = MattMinimalDPSDB.backdropStyle or "black"
 if not BACKDROP_STYLES[style] then
  style = "black"
 end
 return style
end

local function getBackdropOpacity()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local opacity = tonumber(MattMinimalDPSDB.backdropOpacity)
 if not opacity then
  opacity = DEFAULT_BACKDROP_OPACITY
 end
 if opacity < 0 then opacity = 0 end
 if opacity > 1 then opacity = 1 end
 return opacity
end

local function getBackdropColor()
 local style = getBackdropStyle()
 local r, g, bA, baseAlpha = unpack(BACKDROP_STYLES[style].color)
 if style == "transparent" then
  return r, g, bA, 0
 end
 return r, g, bA, baseAlpha * getBackdropOpacity()
end

local function m(h) if not h then return end if h.IsForbidden and h:IsForbidden() then return end if h.Hide then h:Hide() end if h.SetAlpha then h:SetAlpha(0) end end

local function b(w)
 if not w then return end
 local r, g, bA, a = getBackdropColor()
 if w.Background and w.Background.SetColorTexture then
  w.Background:SetColorTexture(r, g, bA, a)
  return
 end

 local state = mmdps_state[w]
 if not state then state = {} mmdps_state[w] = state end
 if not state.bg then
  local t = w:CreateTexture(nil,"BACKGROUND",nil,-8)
  t:SetAllPoints(w)
  state.bg = t
 end
 if state.bg.SetColorTexture then state.bg:SetColorTexture(r, g, bA, a) end
end

-- Apply matt font

local function MMDPS_ApplyEntryFontString(fontString, sizeKey)
 if not fontString or not fontString.SetFont then return end
 local resolvedSizeKey = FONT_SIZE_DEFAULTS[sizeKey] and sizeKey or "entryName"
 MMDPS_RegisterManagedFontString(fontString, resolvedSizeKey, FONT_FLAGS)
 MMDPS_SetFontSafe(fontString, FONT_PATH, GetItemFontSize(resolvedSizeKey), FONT_FLAGS)
end

local function MMDPS_ApplyFontsToFrameTree(rootFrame)
 if not rootFrame then return end
 local visited = {}

 local function applyRegion(region)
  if not region or visited[region] then return end
  visited[region] = true
  if not (region.GetObjectType and region:GetObjectType() == "FontString" and region.SetFont) then return end

  local sizeKey = "entryName"
  if region.GetJustifyH and region:GetJustifyH() == "RIGHT" then
   sizeKey = "entryValue"
  end
  MMDPS_ApplyEntryFontString(region, sizeKey)
 end

 local function walk(frame, depth)
  if not frame or visited[frame] or depth > 8 then return end
  visited[frame] = true

  if frame.GetRegions then
   for _, region in ipairs({frame:GetRegions()}) do
    applyRegion(region)
   end
  end

  if frame.GetChildren then
   for _, child in ipairs({frame:GetChildren()}) do
    walk(child, depth + 1)
   end
  end
 end

 walk(rootFrame, 0)
end

local function applyFallbackEntryFontStrings(entry, statusBar, explicitName, explicitValue)
 local seen = {}
 if explicitName then seen[explicitName] = true end
 if explicitValue then seen[explicitValue] = true end

 local function applyToFontString(fontString)
  if not fontString or seen[fontString] then return end
  seen[fontString] = true
  if not fontString.SetFont then return end

  local sizeKey = "entryName"
  if fontString.GetJustifyH and fontString:GetJustifyH() == "RIGHT" then
   sizeKey = "entryValue"
  end

  MMDPS_ApplyEntryFontString(fontString, sizeKey)
 end

 local function scanFrame(frame, depth)
  if not frame or depth > 4 then return end

  if frame.GetRegions then
   for _, region in ipairs({frame:GetRegions()}) do
    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
     applyToFontString(region)
    end
   end
  end

  if frame.GetChildren then
   for _, child in ipairs({frame:GetChildren()}) do
    scanFrame(child, depth + 1)
   end
  end
 end

 scanFrame(entry, 0)
 if statusBar and statusBar ~= entry then
  scanFrame(statusBar, 0)
 end
end

local function applyEntryFont(entry)
    if not entry then return end
    pcall(function()
        local statusBar = (entry.GetStatusBar and entry:GetStatusBar()) or entry.StatusBar or entry.statusBar
        local nameFS = (statusBar and (statusBar.Name or statusBar.NameText or statusBar.LeftText)) or entry.Name or entry.name or entry.NameText
        MMDPS_ApplyEntryFontString(nameFS, "entryName")
        local valueFS = (statusBar and (statusBar.Value or statusBar.ValueText or statusBar.RightText or statusBar.Text)) or entry.Value or entry.value or entry.ValueText
        MMDPS_ApplyEntryFontString(valueFS, "entryValue")

        applyFallbackEntryFontStrings(entry, statusBar, nameFS, valueFS)
    end)
end


local entryHookInstalled = false
local mmdpsHookedScrollBoxes = setmetatable({}, { __mode = "k" })

local function MMDPS_ApplyFontsToScrollBox(scrollBox)
 if not scrollBox then return end

 if scrollBox.ForEachFrame then
  scrollBox:ForEachFrame(function(frame)
   applyEntryFont(frame)
  end)
  return
 end

 if scrollBox.EnumerateFrames then
  for frame in scrollBox:EnumerateFrames() do
   applyEntryFont(frame)
  end
 end
end

local function MMDPS_HookScrollBoxFontRefresh(scrollBox)
 if not scrollBox or mmdpsHookedScrollBoxes[scrollBox] then return end
 if not hooksecurefunc then return end

 if type(scrollBox.Update) == "function" then
  hooksecurefunc(scrollBox, "Update", function(self)
   if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
    MMDPS_ApplyFontsToScrollBox(self)
   end
  end)
 end

 mmdpsHookedScrollBoxes[scrollBox] = true
end

local function installEntryFontHook()
 if entryHookInstalled then return end
 if not DamageMeterEntryMixin then return end

 local hookedAny = false
 local methodCandidates = {
  "Init",
  "Update",
  "Refresh",
  "SetData",
  "SetEntryData",
  "OnDataChanged",
 }

 for _, method in ipairs(methodCandidates) do
  if type(DamageMeterEntryMixin[method]) == "function" then
   hooksecurefunc(DamageMeterEntryMixin, method, function(self)
    if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
     applyEntryFont(self)
    end
   end)
   hookedAny = true
  end
 end

 entryHookInstalled = hookedAny
end

local function s(w)
 if not w or type(w.GetName)~="function" then return end
 local hdr = w.HeaderBar or w.TitleBar or w.headerBar or w.titleBar or w.Header
 m(hdr)
 b(w)
 local dropdown = w.DamageMeterTypeDropdown
 if dropdown and dropdown.Arrow then
  dropdown.Arrow:SetDesaturation(1)
  dropdown.Arrow:SetVertexColor(3, 3, 3, 1)
 end
 local settings = w.SettingsDropdown
 if settings and settings.Icon then
  settings.Icon:SetDesaturation(1)
  settings.Icon:SetVertexColor(3, 3, 3, 1)
 end

 local sb = w.ScrollBox or (w.GetScrollBox and w:GetScrollBox())
 MMDPS_HookScrollBoxFontRefresh(sb)
 local header = w.HeaderBar or w.Header
 local insetL, insetR = 10, 10
 if sb and header and not (InCombatLockdown and InCombatLockdown()) then
  pcall(function() sb:ClearAllPoints(); sb:SetPoint("TOPLEFT", header, "BOTTOMLEFT", insetL, -5); sb:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -insetR, 6) end)
 end

 pcall(function()
  local typeName = dropdown and dropdown.TypeName
  if typeName and typeName.SetFont then
   MMDPS_RegisterManagedFontString(typeName, "typeLabel", FONT_FLAGS)
   MMDPS_SetRegionFont(typeName, GetItemFontSize("typeLabel"), FONT_FLAGS)
   typeName:SetTextColor(1, 1, 1, 1)
  end

  if dropdown and dropdown.Text and dropdown.Text.SetFont then
   MMDPS_RegisterManagedFontString(dropdown.Text, "typeLabel", FONT_FLAGS)
   MMDPS_SetRegionFont(dropdown.Text, GetItemFontSize("typeLabel"), FONT_FLAGS)
   dropdown.Text:SetTextColor(1, 1, 1, 1)
  end

  local sessionDD = w.SessionDropdown
  local sessionName = sessionDD and sessionDD.SessionName

  if sessionName then
   if sessionName.SetTextColor then sessionName:SetTextColor(1, 1, 1, 1) end
   if sessionName.SetFont then
    MMDPS_RegisterManagedFontString(sessionName, "sessionName", FONT_FLAGS)
    MMDPS_SetRegionFont(sessionName, GetItemFontSize("sessionName"), FONT_FLAGS)
   end
  end

  local sessionTimer = w.SessionTimer
  if sessionTimer then
   if sessionTimer.SetTextColor then sessionTimer:SetTextColor(1, 1, 1, 1) end
   if sessionTimer.SetFont then
    MMDPS_RegisterManagedFontString(sessionTimer, "sessionTimer", FONT_FLAGS)
    MMDPS_SetRegionFont(sessionTimer, GetItemFontSize("sessionTimer"), FONT_FLAGS)
   end
  end

  MMDPS_ApplyFontsToScrollBox(sb)
  MMDPS_ApplyFontsToFrameTree(w)
  if w.SourceWindow then
   MMDPS_ApplyFontsToFrameTree(w.SourceWindow)
  end
  end)
end

local function apply()
 installEntryFontHook()

 local function ApplyToSessionWindows()
  for i = 1, 40 do
   local w = _G["DamageMeterSessionWindow"..i]
   if w then
    s(w)
   end
  end
 end

 ApplyToSessionWindows()
 C_Timer.After(0, ApplyToSessionWindows)
 C_Timer.After(0.25, ApplyToSessionWindows)
end

local pendingDeferredApply = false
local function MMDPS_ApplyNowOrDefer()
 if InCombatLockdown and InCombatLockdown() then
  pendingDeferredApply = true
  return false
 end
 apply()
 return true
end

local function MMDPS_SetGlobalFont(fontName)
 fontName = NormalizeMediaName(fontName)
 if not fontName then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.globalFont = fontName
 local resolvedPath, matched, resolvedName = MMDPS_GetGlobalFontPathByName(fontName)
 if matched and resolvedName then
  MattMinimalDPSDB.globalFont = resolvedName
  fontName = resolvedName
  MMDPS_SetSavedGlobalFontPath(resolvedName, resolvedPath)
 else
  MMDPS_ClearSavedGlobalFontPath()
 end
 FONT_PATH = resolvedPath or FONT_PATH
 MMDPS_RefreshFontObjects()
 fontApplyToken = fontApplyToken + 1
 local thisToken = fontApplyToken
 if MattMinimalDPSDB.useCustomTheme then
  MMDPS_ApplyNowOrDefer()
 end

 -- Force a short burst of reapplies on every font switch so late UI updates
 -- inside Damage Meter don't revert or miss the newly selected font.
 if C_Timer and C_Timer.After then
  local burstAttempts = 0
  local function BurstApply()
   burstAttempts = burstAttempts + 1
   if thisToken ~= fontApplyToken then return end
   if not MattMinimalDPSDB or MattMinimalDPSDB.globalFont ~= fontName then return end
   if MattMinimalDPSDB.useCustomTheme then
    MMDPS_ApplyNowOrDefer()
   end
   if burstAttempts < 12 then
    C_Timer.After(0.1, BurstApply)
   end
  end
  C_Timer.After(0.05, BurstApply)
 end

 if (not matched) and C_Timer and C_Timer.After then
  local attempts = 0
  local function RetryApply()
   attempts = attempts + 1
   if thisToken ~= fontApplyToken then return end
   if not MattMinimalDPSDB or MattMinimalDPSDB.globalFont ~= fontName then return end

   local retryPath, retryMatched, retryResolvedName = MMDPS_GetGlobalFontPathByName(fontName)
   if retryPath then
    FONT_PATH = retryPath
    if retryMatched then
     MMDPS_SetSavedGlobalFontPath(retryResolvedName or fontName, retryPath)
    end
   end

   if MattMinimalDPSDB.useCustomTheme then
    MMDPS_ApplyNowOrDefer()
   end
   if (not retryMatched) and attempts < 40 then
    C_Timer.After(0.2, RetryApply)
   end
  end
  C_Timer.After(0.2, RetryApply)
 end
end

local function MMDPS_SetFontSizeForItem(itemKey, fontSize)
 if not itemKey or not FONT_SIZE_DEFAULTS[itemKey] then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 EnsureFontSizeSettings()
 MattMinimalDPSDB.fontSizes[itemKey] = ClampFontSize(fontSize)
 if MattMinimalDPSDB.useCustomTheme then
  MMDPS_ApplyNowOrDefer()
 end
end

local function MMDPS_DebugDumpEntryFonts()
 local printed = 0
 local maxLines = 16

 local function printRowFont(frame, region)
  if printed >= maxLines then return true end
  local text = region.GetText and region:GetText() or nil
  if not text or text == "" then return false end
  local path, size, flags = region:GetFont()
  print(string.format("|cff66ccffMMDPS|r rowfs frame=%q text=%q font=%q size=%s flags=%q", tostring(frame and frame.GetName and frame:GetName() or "<unnamed>"), tostring(text), tostring(path), tostring(size), tostring(flags)))
  printed = printed + 1
  return printed >= maxLines
 end

 local function dumpFrame(frame)
  if not frame or not frame.GetRegions then return false end
  for _, region in ipairs({frame:GetRegions()}) do
   if region and region.GetObjectType and region:GetObjectType() == "FontString" then
    if printRowFont(frame, region) then
     return true
    end
   end
  end
  return false
 end

 for i = 1, 40 do
  if printed >= maxLines then break end
  local window = _G["DamageMeterSessionWindow"..i]
  if window then
   local sb = window.ScrollBox or (window.GetScrollBox and window:GetScrollBox())
   if sb then
    if sb.ForEachFrame then
     sb:ForEachFrame(function(frame)
      if printed < maxLines then
       dumpFrame(frame)
      end
     end)
    elseif sb.EnumerateFrames then
     for frame in sb:EnumerateFrames() do
      if dumpFrame(frame) then
       break
      end
     end
    end
   end

   if printed < maxLines then
    local visited = {}
    local function walk(frame, depth)
     if printed >= maxLines then return end
     if not frame or visited[frame] or depth > 8 then return end
     visited[frame] = true
     dumpFrame(frame)
     if frame.GetChildren then
      for _, child in ipairs({frame:GetChildren()}) do
       walk(child, depth + 1)
      end
     end
    end
    walk(window, 0)
    if window.SourceWindow then
     walk(window.SourceWindow, 0)
    end
   end
  end
 end

 if printed == 0 then
  print("|cff66ccffMMDPS|r rowfs no visible row FontStrings found.")
 end
end

local mmdpsInitialized = false
local mmdpsSharedMediaHooked = false
local mmdpsFontPreloadFrame = nil

local function MMDPS_GetFontPreloadFrame()
 if mmdpsFontPreloadFrame then return mmdpsFontPreloadFrame end
 if not UIParent then return nil end
 local frame = CreateFrame("Frame", nil, UIParent)
 frame:SetPoint("TOP", UIParent, "BOTTOM", 0, -10000)
 frame:SetSize(1, 1)
 frame:Hide()
 mmdpsFontPreloadFrame = frame
 return mmdpsFontPreloadFrame
end

local function MMDPS_PreloadFontPath(fontPath)
 local path = MMDPS_GetUsableFontPath(fontPath)
 if not path then return end
 local preloadFrame = MMDPS_GetFontPreloadFrame()
 if not preloadFrame then return end
 local fs = preloadFrame:CreateFontString(nil, "OVERLAY")
 fs:SetAllPoints()
 local ok = pcall(fs.SetFont, fs, path, 12, "")
 if ok then
  pcall(fs.SetText, fs, "cache")
 end
end

local function MMDPS_PreloadKnownFonts()
 if not LSM or not LSM.HashTable then return end
 local mediaTable = MMDPS_GetFontMediaTable()
 if type(mediaTable) ~= "table" then return end
 for _, path in pairs(mediaTable) do
  MMDPS_PreloadFontPath(path)
 end
end

local function MMDPS_OnFontMediaRegistered(mediaKey, mediaPath)
 local registeredName = NormalizeMediaName(mediaKey)
 if mediaPath then
  MMDPS_PreloadFontPath(mediaPath)
 end

 if type(MattMinimalDPSDB) ~= "table" then return end
 local selected = NormalizeMediaName(MattMinimalDPSDB.globalFont)
 if not selected or not registeredName or not MediaNamesEqual(selected, registeredName) then return end

 local resolvedPath, matched, resolvedName = MMDPS_GetGlobalFontPathByName(selected)
 FONT_PATH = resolvedPath or DEFAULT_FONT_PATH
 if matched and resolvedName then
  MattMinimalDPSDB.globalFont = resolvedName
  MMDPS_SetSavedGlobalFontPath(resolvedName, resolvedPath)
 end
 MMDPS_RefreshFontObjects()
 if MattMinimalDPSDB.useCustomTheme then
  MMDPS_ApplyNowOrDefer()
 end
end

local function MMDPS_InstallSharedMediaHooks()
 if mmdpsSharedMediaHooked or not LSM then return end
 MMDPS_PreloadKnownFonts()
 if hooksecurefunc then
  hooksecurefunc(LSM, "Register", function(_, mediaType, mediaKey, mediaData)
   local normalizedType = type(mediaType) == "string" and mediaType:lower() or nil
   if normalizedType == FONT_MEDIA_TYPE then
    MMDPS_OnFontMediaRegistered(mediaKey, mediaData)
   end
  end)
 end
 mmdpsSharedMediaHooked = true
end

local function MMDPS_InitializeSettings()
MattMinimalDPSDB = type(MattMinimalDPSDB) == "table" and MattMinimalDPSDB or {}
MattMinimalDPSDB.useCustomTheme = MattMinimalDPSDB.useCustomTheme ~= false
MattMinimalDPSDB.backdropStyle = MattMinimalDPSDB.backdropStyle or "black"
MattMinimalDPSDB.backdropOpacity = tonumber(MattMinimalDPSDB.backdropOpacity) or DEFAULT_BACKDROP_OPACITY
MattMinimalDPSDB.globalFont = NormalizeMediaName(MattMinimalDPSDB.globalFont) or MMDPS_FONT_DEFAULT
 MattMinimalDPSDB.globalFontPath = MMDPS_GetUsableFontPath(MattMinimalDPSDB.globalFontPath) or nil
 MattMinimalDPSDB.globalFontPathName = NormalizeMediaName(MattMinimalDPSDB.globalFontPathName)
 if MattMinimalDPSDB.fontSize and not MattMinimalDPSDB.fontSizes then
  MattMinimalDPSDB.fontSizes = {}
  for _, key in ipairs(FONT_SIZE_KEYS) do
   MattMinimalDPSDB.fontSizes[key] = ClampFontSize(MattMinimalDPSDB.fontSize)
  end
 end
 EnsureFontSizeSettings()
 FONT_SIZE = DEFAULT_FONT_SIZE

 MMDPS_RegisterFontMedia()
 MMDPS_InstallSharedMediaHooks()
 local selected = MMDPS_GetGlobalFontName()
 local resolvedPath, matched, resolvedName = MMDPS_GetGlobalFontPathByName(selected)
 if matched and resolvedName then
  MattMinimalDPSDB.globalFont = resolvedName
  MMDPS_SetSavedGlobalFontPath(resolvedName, resolvedPath)
 else
  MMDPS_ClearSavedGlobalFontPath()
 end
 FONT_PATH = resolvedPath or DEFAULT_FONT_PATH
 MMDPS_RefreshFontObjects()
 mmdpsInitialized = true
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent",function(_, ev, arg1)
 if ev == "ADDON_LOADED" then
  if arg1 ~= ADDON_NAME then return end
  MMDPS_InitializeSettings()
  return
 end

 if not mmdpsInitialized then
  MMDPS_InitializeSettings()
 end

 if ev == "PLAYER_REGEN_ENABLED" and pendingDeferredApply then
  pendingDeferredApply = false
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
   apply()
  end
 end
 if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then MMDPS_ApplyNowOrDefer() end
 if not f._t then f._t=C_Timer.NewTicker(2, function() if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then MMDPS_ApplyNowOrDefer() end end) end
 if not f._retry then f._retry = C_Timer.NewTicker(1, function() if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then MMDPS_ApplyNowOrDefer() end end, 8) end
    -- Auto reset logic
    if not f._resetEventsHooked then
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("CHALLENGE_MODE_START")
        f._resetEventsHooked = true
    end
    if ev == "PLAYER_ENTERING_WORLD" or ev == "CHALLENGE_MODE_START" then
        local mode = MattMinimalDPSDB and MattMinimalDPSDB.resetMode or "mythic"
        if mode == "off" then
            return
        elseif mode == "instance" and ev == "PLAYER_ENTERING_WORLD" then
            local inInstance, instanceType = IsInInstance()
            if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
                if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
                    C_DamageMeter.ResetAllCombatSessions()
                end
            end
        elseif mode == "mythic" and ev == "CHALLENGE_MODE_START" then
            local challengeActive = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
            if challengeActive and C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
                C_DamageMeter.ResetAllCombatSessions()
            end
        end
    end
end)
SLASH_MATTMINIMALDPS1="/mattminimaldps"
SLASH_MATTMINIMALDPS2="/mmdps"
SlashCmdList["MATTMINIMALDPS"]=function(msg)
 local cmd = NormalizeMediaName(msg)
 if cmd and cmd:lower() == "fontdebug" then
  local selected = MMDPS_GetGlobalFontName()
  local path, matched, resolved = MMDPS_GetGlobalFontPathByName(selected)
  print(string.format("|cff66ccffMMDPS|r selected=%q resolved=%q matched=%s path=%q savedPath=%q savedName=%q theme=%s", tostring(selected), tostring(resolved), tostring(matched), tostring(path), tostring(MattMinimalDPSDB and MattMinimalDPSDB.globalFontPath), tostring(MattMinimalDPSDB and MattMinimalDPSDB.globalFontPathName), tostring(MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme)))
  return
 end
 if cmd and cmd:lower() == "fontrows" then
  MMDPS_DebugDumpEntryFonts()
  return
 end
 apply()
 if MattMinimalDPSSettingsFrame then
  MattMinimalDPSSettingsFrame:Show()
 end
end

local LDB = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)

if LDB and LibDBIcon then
 local minimapLDB = LDB:NewDataObject("MattMinimalDPS", {
  type = "launcher",
  text = "MMDPS",
  icon = "Interface\\AddOns\\MattMinimalDPS\\Images\\mdps.png",
  OnClick = function(self, button)
   if button == "LeftButton" then
    -- Toggle settings frame
    if MattMinimalDPSSettingsFrame then
     if MattMinimalDPSSettingsFrame:IsShown() then
      MattMinimalDPSSettingsFrame:Hide()
     else
      MattMinimalDPSSettingsFrame:Show()
     end
    end
   elseif button == "RightButton" then

    local dm = _G.DamageMeter
    if dm then
     if dm:IsShown() then
      dm:SetShown(false)
     else
      pcall(function() SetCVar("damageMeterEnabled", "1") end)
      dm:SetShown(true)
     end
    end
   end
  end,
  OnTooltipShow = function(tooltip)
   tooltip:AddLine("|cffffffffMatt's Minimal DPS|r")
   tooltip:AddLine("|cffffd200Left-click:|r Open Settings")
   tooltip:AddLine("|cffffd200Right-click:|r Toggle Damage Meter")
  end,
 })
 
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 if not MattMinimalDPSDB.minimapIcon then MattMinimalDPSDB.minimapIcon = {} end
 
 LibDBIcon:Register("MattMinimalDPS", minimapLDB, MattMinimalDPSDB.minimapIcon)

 local function ApplyMinimapIconVisibility()
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.minimapIcon = MattMinimalDPSDB.minimapIcon or {}
  if MattMinimalDPSDB.minimapIcon.hide then
   LibDBIcon:Hide("MattMinimalDPS")
  else
   LibDBIcon:Show("MattMinimalDPS")
  end
 end

 ApplyMinimapIconVisibility()
 C_Timer.After(0, ApplyMinimapIconVisibility)
 
 local settingsFrame = CreateFrame("Frame", "MattMinimalDPSSettingsFrame", UIParent, "BackdropTemplate")
 settingsFrame:SetSize(420, 500)
 settingsFrame:SetPoint("CENTER")
 settingsFrame:SetMovable(true)
 settingsFrame:EnableMouse(true)
 settingsFrame:RegisterForDrag("LeftButton")
 settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
 settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
 settingsFrame:Hide()
 
 settingsFrame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 10,
  insets = {left = 2, right = 2, top = 2, bottom = 2}
 })
 settingsFrame:SetBackdropColor(0.01, 0.01, 0.01, 0.92)
 settingsFrame:SetBackdropBorderColor(0.16, 0.16, 0.16, 0.95)
 
 local titleBg = settingsFrame:CreateTexture(nil, "ARTWORK")
 titleBg:SetPoint("TOPLEFT", 10, -10)
 titleBg:SetPoint("TOPRIGHT", -10, -10)
 titleBg:SetHeight(30)
 titleBg:SetColorTexture(0.08, 0.08, 0.08, 0.85)
 
 settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
 settingsFrame.title:SetPoint("LEFT", titleBg, "LEFT", 10, 0)
 settingsFrame.title:SetFont(GUI_FONT_PATH, 13, GUI_FONT_FLAGS)
 settingsFrame.title:SetText("Matt's Minimal DPS")
 settingsFrame.title:SetTextColor(0.95, 0.95, 0.95, 1)
 
 local closeBtn = settingsFrame:CreateFontString(nil, "OVERLAY")
 closeBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -10, -12)
 closeBtn:SetFont(GUI_FONT_PATH, 16, GUI_FONT_FLAGS)
 closeBtn:SetText("X")
 closeBtn:SetTextColor(0.85, 0.85, 0.85, 1)
 local closeFrame = CreateFrame("Button", nil, settingsFrame)
 closeFrame:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -8)
 closeFrame:SetSize(20, 20)
 closeFrame:SetScript("OnClick", function() settingsFrame:Hide() end)
 closeFrame:SetScript("OnEnter", function() closeBtn:SetTextColor(1, 1, 1, 1) end)
 closeFrame:SetScript("OnLeave", function() closeBtn:SetTextColor(0.85, 0.85, 0.85, 1) end)
 closeFrame:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
 
 local descText = settingsFrame:CreateFontString(nil, "OVERLAY")
 descText:SetPoint("TOPLEFT", 20, -50)
 descText:SetPoint("TOPRIGHT", -20, -50)
 descText:SetFont(GUI_FONT_PATH, 11, GUI_FONT_FLAGS)
 descText:SetText("A minimal skin for Blizzard's Damage Meter.\nKeep it clean, keep it minimal!")
 descText:SetTextColor(0.72, 0.72, 0.72, 1)
 descText:SetWordWrap(true)
 
 local dividerTop = settingsFrame:CreateTexture(nil, "ARTWORK")
 dividerTop:SetPoint("TOPLEFT", 20, -90)
 dividerTop:SetPoint("TOPRIGHT", -20, -90)
 dividerTop:SetHeight(1)
 dividerTop:SetColorTexture(0.22, 0.22, 0.22, 0.9)

 local tabButtons = {}
 local panes = {
  general = CreateFrame("Frame", nil, settingsFrame),
  sessions = CreateFrame("Frame", nil, settingsFrame),
  appearance = CreateFrame("Frame", nil, settingsFrame),
 }
 local HideFontPicker = nil
 for _, pane in pairs(panes) do
  pane:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -148)
  pane:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -20, 20)
 end

 local function SetActiveTab(tabKey)
  if not panes[tabKey] then tabKey = "general" end
  if HideFontPicker then
   HideFontPicker()
  end
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.activeTab = tabKey
  for key, pane in pairs(panes) do
   pane:SetShown(key == tabKey)
  end
  for key, btn in pairs(tabButtons) do
   if key == tabKey then
    btn.isActive = true
    btn:SetBackdropColor(0.12, 0.12, 0.15, 1)
    btn:SetBackdropBorderColor(0.22, 0.6, 0.72, 0.85)
    if btn.text then btn.text:SetTextColor(1, 1, 1, 1) end
   else
    btn.isActive = false
    btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    btn:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
    if btn.text then btn.text:SetTextColor(0.7, 0.7, 0.7, 1) end
   end
  end
 end

 local function CreateTabButton(tabKey, text, x, width)
  local btn = CreateFrame("Button", nil, settingsFrame, "BackdropTemplate")
  btn:SetSize(width, 22)
  btn:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", x, -110)
  btn:SetBackdrop({
   bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
   edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
   tile = true,
   tileSize = 16,
   edgeSize = 8,
   insets = {left = 2, right = 2, top = 2, bottom = 2},
  })
  btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
  btn:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
  local fs = btn:CreateFontString(nil, "OVERLAY")
  fs:SetPoint("CENTER")
  fs:SetFont(GUI_FONT_PATH, 10, "")
  fs:SetText(text)
  fs:SetTextColor(0.7, 0.7, 0.7, 1)
  btn.text = fs
  btn:SetScript("OnEnter", function(self)
   if self.isActive then return end
   self:SetBackdropBorderColor(0.24, 0.24, 0.3, 1)
   if self.text then self.text:SetTextColor(0.9, 0.9, 0.9, 1) end
  end)
  btn:SetScript("OnLeave", function(self)
   if self.isActive then return end
   self:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
   if self.text then self.text:SetTextColor(0.7, 0.7, 0.7, 1) end
  end)
  btn:SetScript("OnClick", function() SetActiveTab(tabKey) end)
  tabButtons[tabKey] = btn
  return btn
 end

 local tabInset = 14
 local tabSpacing = 4
 local tabUsableWidth = settingsFrame:GetWidth() - (tabInset * 2) - (tabSpacing * 2)
 local tabWidth = math.floor(tabUsableWidth / 3)
 local tabRemainder = tabUsableWidth - (tabWidth * 3)
 local tab1Width = tabWidth + (tabRemainder > 0 and 1 or 0)
 local tab2Width = tabWidth + (tabRemainder > 1 and 1 or 0)
 local tab3Width = tabWidth
 local tab1X = tabInset
 local tab2X = tab1X + tab1Width + tabSpacing
 local tab3X = tab2X + tab2Width + tabSpacing

 CreateTabButton("general", "General", tab1X, tab1Width)
 CreateTabButton("sessions", "Sessions", tab2X, tab2Width)
 CreateTabButton("appearance", "Appearance", tab3X, tab3Width)

 local tabDivider = settingsFrame:CreateTexture(nil, "ARTWORK")
 tabDivider:SetPoint("TOPLEFT", tabInset, -136)
 tabDivider:SetPoint("TOPRIGHT", -tabInset, -136)
 tabDivider:SetHeight(1)
 tabDivider:SetColorTexture(0.18, 0.18, 0.18, 0.9)

 local fontLabel = panes.appearance:CreateFontString(nil, "OVERLAY")
 fontLabel:SetPoint("TOPLEFT", 0, -8)
 fontLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 fontLabel:SetText("Font:")
 fontLabel:SetTextColor(1, 1, 1, 1)

 local fontDropdown = CreateFrame("Frame", nil, panes.appearance, "UIDropDownMenuTemplate")
 fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -15, -2)

 local function GetFontDropdownText(fontName)
  return NormalizeMediaName(fontName) or MMDPS_FONT_DEFAULT
 end

 local function SetFontDropdownDisplay(fontName)
  local shown = NormalizeMediaName(fontName) or MMDPS_FONT_DEFAULT
  UIDropDownMenu_SetSelectedValue(fontDropdown, shown)
  UIDropDownMenu_SetText(fontDropdown, GetFontDropdownText(shown))
 end

 local FONT_PICKER_ROW_HEIGHT = 20
 local FONT_PICKER_WIDTH = 214
 local FONT_PICKER_HEIGHT = 280
 local fontPickerFrame
 local fontPickerScrollFrame
 local fontPickerContent
 local fontPickerRows = {}
 local fontPickerFonts = {}

 local RefreshFontPickerRows
 local ScrollFontPickerToSelection

 local function EnsureFontPicker()
  if fontPickerFrame then return end

  fontPickerFrame = CreateFrame("Frame", "MattMinimalDPSFontPickerFrame", settingsFrame, "BackdropTemplate")
  fontPickerFrame:SetSize(FONT_PICKER_WIDTH, FONT_PICKER_HEIGHT)
  fontPickerFrame:SetPoint("TOPLEFT", fontDropdown, "BOTTOMLEFT", 16, -2)
  fontPickerFrame:SetFrameStrata("DIALOG")
  fontPickerFrame:SetFrameLevel(settingsFrame:GetFrameLevel() + 15)
  fontPickerFrame:SetClampedToScreen(true)
  fontPickerFrame:SetBackdrop({
   bgFile = "Interface\\Buttons\\WHITE8X8",
   edgeFile = "Interface\\Buttons\\WHITE8X8",
   edgeSize = 1,
   insets = {left = 1, right = 1, top = 1, bottom = 1},
  })
  fontPickerFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.97)
  fontPickerFrame:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
  fontPickerFrame:EnableMouse(true)
  fontPickerFrame:Hide()

  fontPickerScrollFrame = CreateFrame("ScrollFrame", nil, fontPickerFrame, "UIPanelScrollFrameTemplate")
  fontPickerScrollFrame:SetPoint("TOPLEFT", 6, -6)
  fontPickerScrollFrame:SetPoint("BOTTOMRIGHT", -27, 6)
  fontPickerScrollFrame:EnableMouseWheel(true)
  fontPickerScrollFrame:SetScript("OnMouseWheel", function(self, delta)
   local step = FONT_PICKER_ROW_HEIGHT * 3
   local nextOffset = self:GetVerticalScroll() - (delta * step)
   local minOffset, maxOffset = 0, 0
   local scrollBar = self.ScrollBar
   if scrollBar and scrollBar.GetMinMaxValues then
    minOffset, maxOffset = scrollBar:GetMinMaxValues()
   end
   if nextOffset < minOffset then nextOffset = minOffset end
   if nextOffset > maxOffset then nextOffset = maxOffset end
   self:SetVerticalScroll(nextOffset)
  end)

  fontPickerContent = CreateFrame("Frame", nil, fontPickerScrollFrame)
  fontPickerContent:SetSize(1, 1)
  fontPickerContent:SetPoint("TOPLEFT", fontPickerScrollFrame, "TOPLEFT", 0, 0)
  fontPickerScrollFrame:SetScrollChild(fontPickerContent)

  if type(UISpecialFrames) == "table" then
   local alreadyAdded = false
   for _, frameName in ipairs(UISpecialFrames) do
    if frameName == "MattMinimalDPSFontPickerFrame" then
     alreadyAdded = true
     break
    end
   end
   if not alreadyAdded then
    table.insert(UISpecialFrames, "MattMinimalDPSFontPickerFrame")
   end
  end
 end

 HideFontPicker = function()
  if fontPickerFrame and fontPickerFrame:IsShown() then
   fontPickerFrame:Hide()
  end
 end

 local function PromptReloadAfterFontChange()
  if not StaticPopupDialogs then return end
  if not StaticPopupDialogs["MATTMINIMALDPS_FONT_RELOAD"] then
   StaticPopupDialogs["MATTMINIMALDPS_FONT_RELOAD"] = {
    text = "Reload UI now to fully apply the new DPS meter font?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
     ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
   }
  end
  StaticPopup_Show("MATTMINIMALDPS_FONT_RELOAD")
 end

 local function SelectFontFromDropdown(fontName)
  local chosen = NormalizeMediaName(fontName)
  if not chosen then return end
  local previous = MMDPS_GetGlobalFontName()
  if MediaNamesEqual(previous, chosen) then return end
  MMDPS_SetGlobalFont(chosen)
  SetFontDropdownDisplay(chosen)
  if RefreshFontPickerRows and fontPickerFrame and fontPickerFrame:IsShown() then
   RefreshFontPickerRows()
   if ScrollFontPickerToSelection then
    ScrollFontPickerToSelection()
   end
  end
  PromptReloadAfterFontChange()
 end

 local function CycleFontDropdownByWheel(delta)
  local fonts = MMDPS_GetFontOptions()
  if #fonts == 0 then return end

  local selected = MMDPS_GetGlobalFontName()
  local index = 1
  for i, name in ipairs(fonts) do
   if MediaNamesEqual(name, selected) then
    index = i
    break
   end
  end

  if delta > 0 then
   index = index - 1
  else
   index = index + 1
  end
  if index < 1 then index = #fonts end
  if index > #fonts then index = 1 end

  SelectFontFromDropdown(fonts[index])
 end

 RefreshFontPickerRows = function()
  EnsureFontPicker()
  wipe(fontPickerFonts)
  for _, name in ipairs(MMDPS_GetFontOptions()) do
   fontPickerFonts[#fontPickerFonts + 1] = name
  end

  local viewWidth = fontPickerScrollFrame:GetWidth()
  if not viewWidth or viewWidth <= 1 then
   viewWidth = FONT_PICKER_WIDTH - 34
  end
  fontPickerContent:SetWidth(viewWidth)

  local selected = MMDPS_GetGlobalFontName()
  local previous
  for i, fontName in ipairs(fontPickerFonts) do
   local row = fontPickerRows[i]
   if not row then
    row = CreateFrame("Button", nil, fontPickerContent)
    row:SetHeight(FONT_PICKER_ROW_HEIGHT)

    row.selection = row:CreateTexture(nil, "BACKGROUND")
    row.selection:SetAllPoints()
    row.selection:SetColorTexture(0.85, 0.68, 0.1, 0.35)

    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 1, 1, 0.07)

    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetPoint("LEFT", 8, 0)
    row.text:SetPoint("RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.text:SetFont(GUI_FONT_PATH, 11, "")
    row.text:SetTextColor(0.95, 0.95, 0.95, 1)

    row:SetScript("OnClick", function(self)
     if not self.fontName then return end
     SelectFontFromDropdown(self.fontName)
     HideFontPicker()
    end)

    fontPickerRows[i] = row
   end

   row:ClearAllPoints()
   if previous then
    row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
    row:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, 0)
   else
    row:SetPoint("TOPLEFT", fontPickerContent, "TOPLEFT", 0, 0)
    row:SetPoint("TOPRIGHT", fontPickerContent, "TOPRIGHT", 0, 0)
   end

   row.fontName = fontName
   row.text:SetText(fontName)
   row.selection:SetShown(MediaNamesEqual(fontName, selected))
   row:Show()
   previous = row
  end

  for i = #fontPickerFonts + 1, #fontPickerRows do
   local row = fontPickerRows[i]
   row.fontName = nil
   row:Hide()
  end

  local viewHeight = fontPickerScrollFrame:GetHeight()
  if not viewHeight or viewHeight <= 1 then
   viewHeight = FONT_PICKER_HEIGHT - 12
  end
  local totalHeight = math.max(viewHeight, #fontPickerFonts * FONT_PICKER_ROW_HEIGHT)
  fontPickerContent:SetHeight(totalHeight)
 end

 ScrollFontPickerToSelection = function()
  if not fontPickerScrollFrame then return end

  local selected = MMDPS_GetGlobalFontName()
  local selectedIndex = 1
  for i, fontName in ipairs(fontPickerFonts) do
   if MediaNamesEqual(fontName, selected) then
    selectedIndex = i
    break
   end
  end

  local viewHeight = fontPickerScrollFrame:GetHeight()
  local contentHeight = math.max(viewHeight, #fontPickerFonts * FONT_PICKER_ROW_HEIGHT)
  local maxOffset = math.max(0, contentHeight - viewHeight)
  local targetOffset = ((selectedIndex - 1) * FONT_PICKER_ROW_HEIGHT) - ((viewHeight - FONT_PICKER_ROW_HEIGHT) * 0.5)
  if targetOffset < 0 then targetOffset = 0 end
  if targetOffset > maxOffset then targetOffset = maxOffset end
  fontPickerScrollFrame:SetVerticalScroll(targetOffset)
 end

 local function ToggleFontPicker()
  EnsureFontPicker()
  if fontPickerFrame:IsShown() then
   fontPickerFrame:Hide()
   return
  end

  CloseDropDownMenus()
  fontPickerFrame:Show()
  RefreshFontPickerRows()
  ScrollFontPickerToSelection()
 end

 local function RefreshFontDropdownMenu()
  RefreshFontPickerRows()
 end

 fontDropdown:EnableMouseWheel(true)
 fontDropdown:SetScript("OnMouseWheel", function(_, delta)
  CycleFontDropdownByWheel(delta)
 end)
 if fontDropdown.Button and fontDropdown.Button.EnableMouseWheel then
  fontDropdown.Button:EnableMouseWheel(true)
  fontDropdown.Button:SetScript("OnMouseWheel", function(_, delta)
   CycleFontDropdownByWheel(delta)
  end)
  fontDropdown.Button:SetScript("OnClick", function()
   ToggleFontPicker()
  end)
 else
  fontDropdown:SetScript("OnMouseDown", function(_, mouseButton)
   if mouseButton ~= "LeftButton" then return end
   ToggleFontPicker()
  end)
 end

 local fontScaleTitle = panes.appearance:CreateFontString(nil, "OVERLAY")
 fontScaleTitle:SetPoint("TOPLEFT", 0, -56)
 fontScaleTitle:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 fontScaleTitle:SetText("Font Scaling")
 fontScaleTitle:SetTextColor(1, 1, 1, 1)

 local fontSizeUIUpdating = false
 local fontSizeWidgets = {}
 local fontSizeSliderRows = {
  { key = "entryName", text = "Entry Name", y = -80 },
  { key = "entryValue", text = "Entry Value", y = -104 },
  { key = "typeLabel", text = "Type Label", y = -128 },
  { key = "sessionName", text = "Session Name", y = -152 },
  { key = "sessionTimer", text = "Session Timer", y = -176 },
 }

 for idx, row in ipairs(fontSizeSliderRows) do
  local label = panes.appearance:CreateFontString(nil, "OVERLAY")
  label:SetPoint("TOPLEFT", 0, row.y)
  label:SetFont(GUI_FONT_PATH, 10, GUI_FONT_FLAGS)
  label:SetText(row.text)
  label:SetTextColor(0.85, 0.85, 0.85, 1)

  local valueText = panes.appearance:CreateFontString(nil, "OVERLAY")
  valueText:SetPoint("LEFT", label, "RIGHT", 8, 0)
  valueText:SetFont(GUI_FONT_PATH, 10, GUI_FONT_FLAGS)
  valueText:SetTextColor(0.8, 0.8, 0.8, 1)

  local slider = CreateFrame("Slider", "MattMinimalDPSFontSizeSlider"..idx, panes.appearance, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 190, row.y + 2)
  slider:SetMinMaxValues(8, 20)
  slider:SetValueStep(1)
  slider:SetObeyStepOnDrag(true)
  slider:SetWidth(170)
  slider:SetHeight(14)
  _G[slider:GetName().."Low"]:SetText("")
  _G[slider:GetName().."High"]:SetText("")
  _G[slider:GetName().."Text"]:SetText("")

  fontSizeWidgets[row.key] = {
   slider = slider,
   valueText = valueText,
  }
 end

 local function RefreshFontSizeUI()
  fontSizeUIUpdating = true
  EnsureFontSizeSettings()
  for key, widgets in pairs(fontSizeWidgets) do
   local size = GetItemFontSize(key)
   widgets.slider:SetValue(size)
   widgets.valueText:SetText(tostring(size))
  end
  fontSizeUIUpdating = false
 end

 local resetModeLabel = panes.sessions:CreateFontString(nil, "OVERLAY")
 resetModeLabel:SetPoint("TOPLEFT", 0, -8)
 resetModeLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 resetModeLabel:SetText("Auto Reset Mode:")
 resetModeLabel:SetTextColor(1, 1, 1, 1)

 local resetModeDropdown = CreateFrame("Frame", nil, panes.sessions, "UIDropDownMenuTemplate")
 resetModeDropdown:SetPoint("TOPLEFT", resetModeLabel, "BOTTOMLEFT", -15, -2)
 local resetModes = {
     { text = "Off", value = "off" },
     { text = "On Instance Entry", value = "instance" },
     { text = "On Mythic+ Start", value = "mythic" },
 }

 local function SetResetMode(value)
     MattMinimalDPSDB = MattMinimalDPSDB or {}
     MattMinimalDPSDB.resetMode = value
 end

 local function GetResetMode()
     MattMinimalDPSDB = MattMinimalDPSDB or {}
     return MattMinimalDPSDB.resetMode or "mythic"
 end

 local backdropLabel = panes.appearance:CreateFontString(nil, "OVERLAY")
 backdropLabel:SetPoint("TOPLEFT", 0, -218)
 backdropLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 backdropLabel:SetText("Backdrop Style:")
 backdropLabel:SetTextColor(1, 1, 1, 1)

 local backdropDropdown = CreateFrame("Frame", nil, panes.appearance, "UIDropDownMenuTemplate")
 backdropDropdown:SetPoint("TOPLEFT", backdropLabel, "BOTTOMLEFT", -15, -2)
 local opacitySliderLabel = panes.appearance:CreateFontString(nil, "OVERLAY")
 opacitySliderLabel:SetPoint("TOPLEFT", 0, -266)
 opacitySliderLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 opacitySliderLabel:SetText("Backdrop Opacity:")
 opacitySliderLabel:SetTextColor(1, 1, 1, 1)

 local opacityValueText = panes.appearance:CreateFontString(nil, "OVERLAY")
 opacityValueText:SetPoint("LEFT", opacitySliderLabel, "RIGHT", 8, 0)
 opacityValueText:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 opacityValueText:SetTextColor(0.8, 0.8, 0.8, 1)

 local opacitySlider = CreateFrame("Slider", "MattMinimalDPSBackdropOpacitySlider", panes.appearance, "OptionsSliderTemplate")
 opacitySlider:SetPoint("TOPLEFT", opacitySliderLabel, "BOTTOMLEFT", 0, -8)
 opacitySlider:SetMinMaxValues(0, 1)
 opacitySlider:SetValueStep(0.05)
 opacitySlider:SetObeyStepOnDrag(true)
 opacitySlider:SetWidth(180)
 opacitySlider:SetHeight(16)
 _G[opacitySlider:GetName().."Low"]:SetText("0%")
 _G[opacitySlider:GetName().."High"]:SetText("100%")
 _G[opacitySlider:GetName().."Text"]:SetText("")

 local backdropUIUpdating = false
 local function RefreshBackdropOpacityUI()
  backdropUIUpdating = true
  local style = getBackdropStyle()
  local opacity = getBackdropOpacity()
  opacitySlider:SetValue(opacity)
  if style == "transparent" then
   opacitySlider:Disable()
   opacityValueText:SetText("N/A")
  else
   opacitySlider:Enable()
   opacityValueText:SetText(string.format("%d%%", math.floor(opacity * 100 + 0.5)))
  end
  backdropUIUpdating = false
 end

 local function SetBackdropStyle(style)
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.backdropStyle = BACKDROP_STYLES[style] and style or "black"
  RefreshBackdropOpacityUI()
  if MattMinimalDPSDB.useCustomTheme then
   apply()
  end
 end

 local function GetBackdropStyleText(style)
  if BACKDROP_STYLES[style] then
   return BACKDROP_STYLES[style].text
  end
  return BACKDROP_STYLES.transparent.text
 end

UIDropDownMenu_Initialize(backdropDropdown, function(self, level, menuList)
 local selected = getBackdropStyle()
 for _, style in ipairs(BACKDROP_STYLE_ORDER) do
  local styleValue = style
  local data = BACKDROP_STYLES[style]
  local info = UIDropDownMenu_CreateInfo()
  info.text = data.text
  info.value = styleValue
  info.func = function()
   SetBackdropStyle(styleValue)
   UIDropDownMenu_SetSelectedValue(backdropDropdown, styleValue)
   UIDropDownMenu_SetText(backdropDropdown, data.text)
  end
  info.checked = (styleValue == selected)
  UIDropDownMenu_AddButton(info)
 end
end)
UIDropDownMenu_SetWidth(backdropDropdown, 190)
do
 local selectedStyle = getBackdropStyle()
 UIDropDownMenu_SetSelectedValue(backdropDropdown, selectedStyle)
 UIDropDownMenu_SetText(backdropDropdown, GetBackdropStyleText(selectedStyle))
end

RefreshFontDropdownMenu()
UIDropDownMenu_SetWidth(fontDropdown, 190)
do
 local selectedFont = MMDPS_GetGlobalFontName()
 SetFontDropdownDisplay(selectedFont)
end
for key, widgets in pairs(fontSizeWidgets) do
 widgets.slider:SetScript("OnValueChanged", function(self, value)
  if fontSizeUIUpdating then return end
  local size = ClampFontSize(value)
  widgets.valueText:SetText(tostring(size))
  MMDPS_SetFontSizeForItem(key, size)
 end)
end
RefreshFontSizeUI()

opacitySlider:SetScript("OnValueChanged", function(self, value)
 if backdropUIUpdating then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local clamped = math.max(0, math.min(1, value or 1))
 MattMinimalDPSDB.backdropOpacity = clamped
 RefreshBackdropOpacityUI()
 if getBackdropStyle() ~= "transparent" and MattMinimalDPSDB.useCustomTheme then
  apply()
 end
end)
RefreshBackdropOpacityUI()

UIDropDownMenu_Initialize(resetModeDropdown, function(self, level, menuList)
    local selected = GetResetMode()
    for _, mode in ipairs(resetModes) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = mode.text
        info.value = mode.value
        info.func = function()
            SetResetMode(mode.value)
            UIDropDownMenu_SetSelectedValue(resetModeDropdown, mode.value)
            UIDropDownMenu_SetText(resetModeDropdown, mode.text)
        end
        info.checked = (mode.value == selected)
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetWidth(resetModeDropdown, 190)
do
    local selected = GetResetMode()
    local selectedText = nil
    for _, mode in ipairs(resetModes) do
        if mode.value == selected then selectedText = mode.text break end
    end
    UIDropDownMenu_SetSelectedValue(resetModeDropdown, selected)
    if selectedText then
        UIDropDownMenu_SetText(resetModeDropdown, selectedText)
    end
end

-- "Reset Now" button
local resetNowBtn = CreateFrame("Button", nil, panes.sessions, "UIPanelButtonTemplate")
resetNowBtn:SetSize(84, 20)
resetNowBtn:SetPoint("LEFT", resetModeDropdown, "RIGHT", 12, 0)
resetNowBtn:SetText("Reset")
resetNowBtn:SetScript("OnClick", function()
    pcall(function()
        if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
            C_DamageMeter.ResetAllCombatSessions()
        end
    end)
end)
resetNowBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Immediately reset Damage Meter sessions")
    GameTooltip:Show()
end)
resetNowBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
  
 local minimapCheckbox = CreateFrame("CheckButton", nil, panes.general, "UICheckButtonTemplate")
 minimapCheckbox:SetPoint("TOPLEFT", 0, -44)
 minimapCheckbox:SetSize(24, 24)
 minimapCheckbox.text = minimapCheckbox:CreateFontString(nil, "OVERLAY")
 minimapCheckbox.text:SetPoint("LEFT", minimapCheckbox, "RIGHT", 5, 0)
 minimapCheckbox.text:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 minimapCheckbox.text:SetText("Minimap Icon")
 minimapCheckbox.text:SetTextColor(1, 1, 1, 1)
 
 minimapCheckbox:SetScript("OnClick", function(self)
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.minimapIcon = MattMinimalDPSDB.minimapIcon or {}
  if self:GetChecked() then
   MattMinimalDPSDB.minimapIcon.hide = false
  else
   MattMinimalDPSDB.minimapIcon.hide = true
  end
  ApplyMinimapIconVisibility()
 end)
 
 local themeCheckbox = CreateFrame("CheckButton", nil, panes.general, "UICheckButtonTemplate")
 themeCheckbox:SetPoint("TOPLEFT", 0, -12)
 themeCheckbox:SetSize(24, 24)
 themeCheckbox.text = themeCheckbox:CreateFontString(nil, "OVERLAY")
 themeCheckbox.text:SetPoint("LEFT", themeCheckbox, "RIGHT", 5, 0)
 themeCheckbox.text:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 themeCheckbox.text:SetText("Use Minimal Theme")
 themeCheckbox.text:SetTextColor(1, 1, 1, 1)
 
 themeCheckbox:SetScript("OnClick", function(self)
  StaticPopupDialogs["MATTMINIMALDPS_THEME_RELOAD"] = {
   text = "Theme change requires a UI reload. Continue?",
   button1 = "Yes",
   button2 = "No",
   OnAccept = function()
    MattMinimalDPSDB.useCustomTheme = self:GetChecked()
    ReloadUI()
   end,
   OnCancel = function()
    self:SetChecked(not self:GetChecked())
   end,
   timeout = 0,
   whileDead = true,
   hideOnEscape = true,
  }
  StaticPopup_Show("MATTMINIMALDPS_THEME_RELOAD")
 end)
 
	SetActiveTab((MattMinimalDPSDB and MattMinimalDPSDB.activeTab) or "general")

settingsFrame:SetScript("OnShow", function()
    if MattMinimalDPSDB and MattMinimalDPSDB.minimapIcon then
        minimapCheckbox:SetChecked(not MattMinimalDPSDB.minimapIcon.hide)
    else
        minimapCheckbox:SetChecked(true)
    end
    themeCheckbox:SetChecked(MattMinimalDPSDB.useCustomTheme)
    local selected = GetResetMode()
    local selectedText = nil
    for _, mode in ipairs(resetModes) do
        if mode.value == selected then selectedText = mode.text break end
    end
    UIDropDownMenu_SetSelectedValue(resetModeDropdown, selected)
    if selectedText then
        UIDropDownMenu_SetText(resetModeDropdown, selectedText)
    end
	    local selectedStyle = getBackdropStyle()
	    UIDropDownMenu_SetSelectedValue(backdropDropdown, selectedStyle)
	    UIDropDownMenu_SetText(backdropDropdown, GetBackdropStyleText(selectedStyle))
	    RefreshFontDropdownMenu()
	    local selectedFont = MMDPS_GetGlobalFontName()
	    SetFontDropdownDisplay(selectedFont)
	    RefreshFontSizeUI()
	    RefreshBackdropOpacityUI()
	    SetActiveTab((MattMinimalDPSDB and MattMinimalDPSDB.activeTab) or "general")
end)
settingsFrame:HookScript("OnHide", function()
 if HideFontPicker then
  HideFontPicker()
 end
end)
 
 local function forceOpenDamageMeter()
  pcall(function() SetCVar("damageMeterEnabled", "1") end)

  local dm = _G.DamageMeter
  if dm then
   if dm.SetShown then pcall(dm.SetShown, dm, true) end
  end
 end
 
 C_Timer.After(2, forceOpenDamageMeter)
end
