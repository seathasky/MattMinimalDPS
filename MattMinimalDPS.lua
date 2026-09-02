local ADDON_NAME = ... or "MattMinimalDPS"
MattMinimalDPS = MattMinimalDPS or {}
local MMDPS = MattMinimalDPS
MMDPS.addonName = ADDON_NAME
local LibStub = LibStub or _G.LibStub
local DEFAULT_FONT_PATH="Interface\\AddOns\\MattMinimalDPS\\Fonts\\Naowh.ttf"
local FONT_PATH=DEFAULT_FONT_PATH
local DEFAULT_FONT_SIZE=12
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
local CLASS_ICON_SIZE_DEFAULT = 24

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

local function ClampClassIconSize(value)
 local n = math.floor(tonumber(value) or CLASS_ICON_SIZE_DEFAULT)
 if n < 8 then n = 8 end
 if n > 24 then n = 24 end
 return n
end

local function GetClassIconSize()
 if MattMinimalDPSDB and MattMinimalDPSDB.classIconSize then
  return ClampClassIconSize(MattMinimalDPSDB.classIconSize)
 end
 return CLASS_ICON_SIZE_DEFAULT
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

local BACKDROP_STYLES = {
 transparent = { text = "Transparent", color = {0, 0, 0, 0} },
 black = { text = "Black", color = {0, 0, 0, 1} },
 white = { text = "White (Translucent)", color = {1, 1, 1, 0.18} },
 brown = { text = "Dark Brown", color = {0.17, 0.11, 0.07, 0.65} },
 gray = { text = "Gray", color = {0.16, 0.16, 0.16, 0.65} },
}
local BACKDROP_STYLE_ORDER = {"transparent", "white", "brown", "gray", "black"}
local DEFAULT_BACKDROP_OPACITY = 0.65
local DEFAULT_TITLE_OPACITY = 0.22

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

local function getTitleOpacity()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local opacity = tonumber(MattMinimalDPSDB.titleOpacity)
 if not opacity then
  opacity = DEFAULT_TITLE_OPACITY
 end
 if opacity < 0 then opacity = 0 end
 if opacity > 1 then opacity = 1 end
 return opacity
end

local function getMouseoverButtonsEnabled()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 return MattMinimalDPSDB.mouseoverButtons ~= false
end

local function getShowSessionInTypeLabel()
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 return MattMinimalDPSDB.showSessionInTypeLabel ~= false
end

local function apply()
 if MMDPS.Apply then
  return MMDPS.Apply()
 end
end

local function MMDPS_ApplyNowOrDefer()
 if MMDPS.ApplyNowOrDefer then
  return MMDPS.ApplyNowOrDefer()
 end
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
MattMinimalDPSDB.titleOpacity = tonumber(MattMinimalDPSDB.titleOpacity) or DEFAULT_TITLE_OPACITY
MattMinimalDPSDB.mouseoverButtons = MattMinimalDPSDB.mouseoverButtons ~= false
MattMinimalDPSDB.showSessionInTypeLabel = MattMinimalDPSDB.showSessionInTypeLabel ~= false
MattMinimalDPSDB.classIconSize = ClampClassIconSize(MattMinimalDPSDB.classIconSize)
MattMinimalDPSDB.globalFont = NormalizeMediaName(MattMinimalDPSDB.globalFont) or MMDPS_FONT_DEFAULT
 MattMinimalDPSDB.globalFontPath = MMDPS_GetUsableFontPath(MattMinimalDPSDB.globalFontPath) or nil
 MattMinimalDPSDB.globalFontPathName = NormalizeMediaName(MattMinimalDPSDB.globalFontPathName)
 if type(MattMinimalDPSDB.minimapIcon) ~= "table" then
  MattMinimalDPSDB.minimapIcon = {}
 end
 if MattMinimalDPSDB.minimapIcon.hide == nil then
  MattMinimalDPSDB.minimapIcon.hide = false
 end
 if MattMinimalDPSDB.fontSize and not MattMinimalDPSDB.fontSizes then
  MattMinimalDPSDB.fontSizes = {}
  for _, key in ipairs(FONT_SIZE_KEYS) do
   MattMinimalDPSDB.fontSizes[key] = ClampFontSize(MattMinimalDPSDB.fontSize)
  end
 end
 EnsureFontSizeSettings()
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

-- Internal API for split addon modules loaded after this core file.
MMDPS.LibStub = LibStub
MMDPS.FONT_SIZE_DEFAULTS = FONT_SIZE_DEFAULTS
MMDPS.FONT_FLAGS = FONT_FLAGS
MMDPS.GetFontPath = function() return FONT_PATH end
MMDPS.GUI_FONT_PATH = GUI_FONT_PATH
MMDPS.GUI_FONT_SIZE = GUI_FONT_SIZE
MMDPS.GUI_FONT_FLAGS = GUI_FONT_FLAGS
MMDPS.MMDPS_FONT_DEFAULT = MMDPS_FONT_DEFAULT
MMDPS.DEFAULT_TITLE_OPACITY = DEFAULT_TITLE_OPACITY
MMDPS.BACKDROP_STYLES = BACKDROP_STYLES
MMDPS.BACKDROP_STYLE_ORDER = BACKDROP_STYLE_ORDER
MMDPS.NormalizeMediaName = NormalizeMediaName
MMDPS.MediaNamesEqual = MediaNamesEqual
MMDPS.ClampFontSize = ClampFontSize
MMDPS.ClampClassIconSize = ClampClassIconSize
MMDPS.GetItemFontSize = GetItemFontSize
MMDPS.GetClassIconSize = GetClassIconSize
MMDPS.EnsureFontSizeSettings = EnsureFontSizeSettings
MMDPS.RegisterManagedFontString = MMDPS_RegisterManagedFontString
MMDPS.SetFontSafe = MMDPS_SetFontSafe
MMDPS.SetRegionFont = MMDPS_SetRegionFont
MMDPS.GetGlobalFontName = MMDPS_GetGlobalFontName
MMDPS.GetGlobalFontPathByName = MMDPS_GetGlobalFontPathByName
MMDPS.GetFontOptions = MMDPS_GetFontOptions
MMDPS.SetGlobalFont = MMDPS_SetGlobalFont
MMDPS.SetFontSizeForItem = MMDPS_SetFontSizeForItem
MMDPS.InitializeSettings = MMDPS_InitializeSettings
MMDPS.EnsureInitialized = function()
 if not mmdpsInitialized then
  MMDPS_InitializeSettings()
 end
end
MMDPS.GetBackdropStyle = getBackdropStyle
MMDPS.GetBackdropOpacity = getBackdropOpacity
MMDPS.GetBackdropColor = getBackdropColor
MMDPS.GetTitleOpacity = getTitleOpacity
MMDPS.GetMouseoverButtonsEnabled = getMouseoverButtonsEnabled
MMDPS.GetShowSessionInTypeLabel = getShowSessionInTypeLabel

