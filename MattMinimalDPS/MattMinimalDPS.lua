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

local function MMDPS_RegisterFontMedia()
 if not LSM then return end
 if not LSM:IsValid(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT) then
  LSM:Register(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT, DEFAULT_FONT_PATH)
 end
end

local function MMDPS_GetGlobalFontPathByName(fontName)
 local selected = NormalizeMediaName(fontName) or MMDPS_FONT_DEFAULT
 if LSM then
  local fetched = LSM:Fetch(FONT_MEDIA_TYPE, selected, true)
  if fetched and IsUsableFontPath(fetched) then return fetched, true end
  local fallback = LSM:Fetch(FONT_MEDIA_TYPE, MMDPS_FONT_DEFAULT, true)
  if fallback and IsUsableFontPath(fallback) then return fallback, false end
 end
 return DEFAULT_FONT_PATH, selected == MMDPS_FONT_DEFAULT
end

local function MMDPS_GetGlobalFontName()
 local selected = NormalizeMediaName(MattMinimalDPSDB and MattMinimalDPSDB.globalFont)
 return selected or MMDPS_FONT_DEFAULT
end

local function MMDPS_GetGlobalFontPath()
 local fontPath = MMDPS_GetGlobalFontPathByName(MMDPS_GetGlobalFontName())
 return fontPath or DEFAULT_FONT_PATH
end

local function MMDPS_GetFontOptions()
 local list = {}
 if LSM then
  local names = LSM:List(FONT_MEDIA_TYPE) or {}
  for _, name in ipairs(names) do
   local normalized = NormalizeMediaName(name)
   if normalized then
    list[#list + 1] = normalized
   end
  end
 end
 if #list == 0 then
  list[#list + 1] = MMDPS_FONT_DEFAULT
 end
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

local function applyEntryFont(entry)
    if not entry then return end
    pcall(function()
        local nameFS = entry:GetStatusBar() and entry:GetStatusBar().Name
        if nameFS and nameFS.SetFont then nameFS:SetFont(FONT_PATH, GetItemFontSize("entryName"), FONT_FLAGS) end
        local valueFS = entry:GetStatusBar() and entry:GetStatusBar().Value
        if valueFS and valueFS.SetFont then valueFS:SetFont(FONT_PATH, GetItemFontSize("entryValue"), FONT_FLAGS) end
    end)
end


local entryHookInstalled = false
local function installEntryFontHook()
 if entryHookInstalled then return end
 if not DamageMeterEntryMixin or not DamageMeterEntryMixin.Init then return end
 hooksecurefunc(DamageMeterEntryMixin, "Init", function(self)
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
   applyEntryFont(self)
  end
 end)
 entryHookInstalled = true
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

 local sb = w.ScrollBox
 local header = w.HeaderBar or w.Header
 local insetL, insetR = 10, 10
 if sb and header then
  pcall(function() sb:ClearAllPoints(); sb:SetPoint("TOPLEFT", header, "BOTTOMLEFT", insetL, -5); sb:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -insetR, 6) end)
 end

 pcall(function()
  local typeName = dropdown and dropdown.TypeName
  if typeName and typeName.SetFont then typeName:SetFont(FONT_PATH, GetItemFontSize("typeLabel"), FONT_FLAGS); typeName:SetTextColor(1, 1, 1, 1) end

  if dropdown and dropdown.Text and dropdown.Text.SetFont then dropdown.Text:SetFont(FONT_PATH, GetItemFontSize("typeLabel"), FONT_FLAGS); dropdown.Text:SetTextColor(1, 1, 1, 1) end
  local sessionDD = w.SessionDropdown
  local sessionName = sessionDD and sessionDD.SessionName

    if sessionName and not sessionName.__mmdpsHooked then
        pcall(function()
            if sessionName.SetTextColor then sessionName:SetTextColor(1, 1, 1, 1) end
            if sessionName.SetFont then sessionName:SetFont(FONT_PATH, GetItemFontSize("sessionName"), FONT_FLAGS) end
        end)
        hooksecurefunc(sessionName, "SetTextColor", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsColorGuard = false
        end)
        hooksecurefunc(sessionName, "SetFont", function(fs, _, _, flags)
            if fs.__mmdpsFontGuard then return end
            fs.__mmdpsFontGuard = true
            if fs.SetFont then fs:SetFont(FONT_PATH, GetItemFontSize("sessionName"), flags or FONT_FLAGS) end
            fs.__mmdpsFontGuard = false
        end)
        hooksecurefunc(sessionName, "SetText", function(fs, ...)
            if fs.__mmdpsColorGuard or fs.__mmdpsFontGuard then return end
            fs.__mmdpsColorGuard = true
            fs.__mmdpsFontGuard = true
            if fs.SetFont then fs:SetFont(FONT_PATH, GetItemFontSize("sessionName"), FONT_FLAGS) end
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsFontGuard = false
            fs.__mmdpsColorGuard = false
        end)
        sessionName.__mmdpsHooked = true
    end
    local sessionTimer = w.SessionTimer
    if sessionTimer and not sessionTimer.__mmdpsHooked then
        pcall(function()
            if sessionTimer.SetTextColor then sessionTimer:SetTextColor(1, 1, 1, 1) end
            if sessionTimer.SetFont then sessionTimer:SetFont(FONT_PATH, GetItemFontSize("sessionTimer"), FONT_FLAGS) end
        end)
        hooksecurefunc(sessionTimer, "SetTextColor", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsColorGuard = false
        end)
        hooksecurefunc(sessionTimer, "SetFont", function(fs, _, _, flags)
            if fs.__mmdpsFontGuard then return end
            fs.__mmdpsFontGuard = true
            if fs.SetFont then fs:SetFont(FONT_PATH, GetItemFontSize("sessionTimer"), flags or FONT_FLAGS) end
            fs.__mmdpsFontGuard = false
        end)
        hooksecurefunc(sessionTimer, "SetText", function(fs, ...)
            if fs.__mmdpsColorGuard or fs.__mmdpsFontGuard then return end
            fs.__mmdpsColorGuard = true
            fs.__mmdpsFontGuard = true
            if fs.SetFont then fs:SetFont(FONT_PATH, GetItemFontSize("sessionTimer"), FONT_FLAGS) end
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsFontGuard = false
            fs.__mmdpsColorGuard = false
        end)
        sessionTimer.__mmdpsHooked = true
    end
    pcall(function()
     for _, frame in sb:EnumerateFrames() do
        applyEntryFont(frame)
     end
    end)
 end)
end

local function apply()
 local dm = _G.DamageMeter
 if not dm then return end

 installEntryFontHook()

 C_Timer.After(0, function()

  for i = 1, 10 do
   local w = _G["DamageMeterSessionWindow"..i]
   if w then s(w) end
  end
 end)
end

local function MMDPS_SetGlobalFont(fontName)
 fontName = NormalizeMediaName(fontName)
 if not fontName then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.globalFont = fontName
 FONT_PATH = MMDPS_GetGlobalFontPath()
 if MattMinimalDPSDB.useCustomTheme then
  apply()
 end
end

local function MMDPS_SetFontSizeForItem(itemKey, fontSize)
 if not itemKey or not FONT_SIZE_DEFAULTS[itemKey] then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 EnsureFontSizeSettings()
 MattMinimalDPSDB.fontSizes[itemKey] = ClampFontSize(fontSize)
 if MattMinimalDPSDB.useCustomTheme then
  apply()
 end
end

MattMinimalDPSDB = MattMinimalDPSDB or {}
MattMinimalDPSDB.useCustomTheme = MattMinimalDPSDB.useCustomTheme ~= false 
MattMinimalDPSDB.backdropStyle = MattMinimalDPSDB.backdropStyle or "black"
MattMinimalDPSDB.backdropOpacity = tonumber(MattMinimalDPSDB.backdropOpacity) or DEFAULT_BACKDROP_OPACITY
MattMinimalDPSDB.globalFont = NormalizeMediaName(MattMinimalDPSDB.globalFont) or MMDPS_FONT_DEFAULT
if MattMinimalDPSDB.fontSize and not MattMinimalDPSDB.fontSizes then
 MattMinimalDPSDB.fontSizes = {}
 for _, key in ipairs(FONT_SIZE_KEYS) do
  MattMinimalDPSDB.fontSizes[key] = ClampFontSize(MattMinimalDPSDB.fontSize)
 end
end
EnsureFontSizeSettings()
FONT_SIZE = DEFAULT_FONT_SIZE

MMDPS_RegisterFontMedia()
FONT_PATH = MMDPS_GetGlobalFontPath()

if LSM and LSM.RegisterCallback then
 LSM.RegisterCallback("MMDPS_SHARED_MEDIA_WATCHER", "LibSharedMedia_Registered", function(eventName, mediaType, mediaKey)
  if eventName ~= "LibSharedMedia_Registered" then return end
  if mediaType ~= FONT_MEDIA_TYPE then return end
  if NormalizeMediaName(mediaKey) ~= NormalizeMediaName(MattMinimalDPSDB and MattMinimalDPSDB.globalFont) then return end
  FONT_PATH = MMDPS_GetGlobalFontPath()
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
   apply()
  end
 end)
end


f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent",function(_, ev)
 if MattMinimalDPSDB.useCustomTheme then apply() end
 if not f._t then f._t=C_Timer.NewTicker(2, function() if MattMinimalDPSDB.useCustomTheme then apply() end end) end
 if not f._retry then f._retry = C_Timer.NewTicker(1, function() if MattMinimalDPSDB.useCustomTheme then apply() end end, 8) end
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
SlashCmdList["MATTMINIMALDPS"]=function()
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
 for _, pane in pairs(panes) do
  pane:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -148)
  pane:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -20, 20)
 end

 local function SetActiveTab(tabKey)
  if not panes[tabKey] then tabKey = "general" end
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
  local data = BACKDROP_STYLES[style]
  local info = UIDropDownMenu_CreateInfo()
  info.text = data.text
  info.value = style
  info.func = function()
   SetBackdropStyle(style)
   UIDropDownMenu_SetSelectedValue(backdropDropdown, style)
   UIDropDownMenu_SetText(backdropDropdown, data.text)
  end
  info.checked = (style == selected)
  UIDropDownMenu_AddButton(info)
 end
end)
UIDropDownMenu_SetWidth(backdropDropdown, 190)
do
 local selectedStyle = getBackdropStyle()
 UIDropDownMenu_SetSelectedValue(backdropDropdown, selectedStyle)
 UIDropDownMenu_SetText(backdropDropdown, GetBackdropStyleText(selectedStyle))
end

UIDropDownMenu_Initialize(fontDropdown, function(self, level, menuList)
 local selected = MMDPS_GetGlobalFontName()
 for _, fontName in ipairs(MMDPS_GetFontOptions()) do
  local info = UIDropDownMenu_CreateInfo()
  info.text = fontName
  info.value = fontName
  info.func = function()
   MMDPS_SetGlobalFont(fontName)
   UIDropDownMenu_SetSelectedValue(fontDropdown, fontName)
   UIDropDownMenu_SetText(fontDropdown, GetFontDropdownText(fontName))
  end
  info.checked = (fontName == selected)
  UIDropDownMenu_AddButton(info)
 end
end)
UIDropDownMenu_SetWidth(fontDropdown, 190)
do
 local selectedFont = MMDPS_GetGlobalFontName()
 UIDropDownMenu_SetSelectedValue(fontDropdown, selectedFont)
 UIDropDownMenu_SetText(fontDropdown, GetFontDropdownText(selectedFont))
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
	    local selectedFont = MMDPS_GetGlobalFontName()
	    UIDropDownMenu_SetSelectedValue(fontDropdown, selectedFont)
	    UIDropDownMenu_SetText(fontDropdown, GetFontDropdownText(selectedFont))
	    RefreshFontSizeUI()
	    RefreshBackdropOpacityUI()
	    SetActiveTab((MattMinimalDPSDB and MattMinimalDPSDB.activeTab) or "general")
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
