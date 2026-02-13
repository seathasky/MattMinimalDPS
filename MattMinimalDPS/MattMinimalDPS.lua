local f=CreateFrame("Frame")
local FONT_PATH="Interface\\AddOns\\MattMinimalDPS\\Fonts\\Naowh.ttf"
local FONT_SIZE=12
local FONT_FLAGS="OUTLINE"


local mmdps_state = setmetatable({}, { __mode = "k" })

local function m(h) if not h then return end if h.IsForbidden and h:IsForbidden() then return end if h.Hide then h:Hide() end if h.SetAlpha then h:SetAlpha(0) end end

local function b(w)
 if not w then return end
 if w.Background and w.Background.SetColorTexture then
  w.Background:SetColorTexture(0,0,0,1)
  return
 end

 local state = mmdps_state[w]
 if not state then state = {} mmdps_state[w] = state end
 if not state.bg then
  local t = w:CreateTexture(nil,"BACKGROUND",nil,-8)
  t:SetAllPoints(w)
  state.bg = t
 else
  if state.bg.SetColorTexture then state.bg:SetColorTexture(0,0,0,1) end
 end
end

-- Apply matt font

local function applyEntryFont(entry)
    if not entry then return end
    pcall(function()
        local nameFS = entry:GetStatusBar() and entry:GetStatusBar().Name
        if nameFS and nameFS.SetFont then nameFS:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS) end
        local valueFS = entry:GetStatusBar() and entry:GetStatusBar().Value
        if valueFS and valueFS.SetFont then valueFS:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS) end
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
  if typeName and typeName.SetFont then typeName:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); typeName:SetTextColor(1, 1, 1, 1) end

  if dropdown and dropdown.Text and dropdown.Text.SetFont then dropdown.Text:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); dropdown.Text:SetTextColor(1, 1, 1, 1) end
  local sessionDD = w.SessionDropdown
  local sessionName = sessionDD and sessionDD.SessionName

    if sessionName and not sessionName.__mmdpsHooked then
        pcall(function() if sessionName.SetTextColor then sessionName:SetTextColor(1, 1, 1, 1) end end)
        hooksecurefunc(sessionName, "SetTextColor", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsColorGuard = false
        end)
        hooksecurefunc(sessionName, "SetText", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsColorGuard = false
        end)
        sessionName.__mmdpsHooked = true
    end
    local sessionTimer = w.SessionTimer
    if sessionTimer and not sessionTimer.__mmdpsHooked then
        pcall(function() if sessionTimer.SetTextColor then sessionTimer:SetTextColor(1, 1, 1, 1) end end)
        hooksecurefunc(sessionTimer, "SetTextColor", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
            fs.__mmdpsColorGuard = false
        end)
        hooksecurefunc(sessionTimer, "SetText", function(fs, ...)
            if fs.__mmdpsColorGuard then return end
            fs.__mmdpsColorGuard = true
            if fs.SetTextColor then fs:SetTextColor(1, 1, 1, 1) end
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

MattMinimalDPSDB = MattMinimalDPSDB or {}
MattMinimalDPSDB.useCustomTheme = MattMinimalDPSDB.useCustomTheme ~= false 


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
        local mode = MattMinimalDPSDB and MattMinimalDPSDB.resetMode or "instance"
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
            if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
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

local LibStub = LibStub or _G.LibStub
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
 
 local settingsFrame = CreateFrame("Frame", "MattMinimalDPSSettingsFrame", UIParent, "BackdropTemplate")
 settingsFrame:SetSize(400, 250)
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
  edgeSize = 8,
  insets = {left = 1, right = 1, top = 1, bottom = 1}
 })
 settingsFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.85)
 settingsFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.85)
 
 local titleBg = settingsFrame:CreateTexture(nil, "ARTWORK")
 titleBg:SetPoint("TOPLEFT", 8, -8)
 titleBg:SetPoint("TOPRIGHT", -8, -8)
 titleBg:SetHeight(24)
 titleBg:SetColorTexture(0.01, 0.01, 0.01, 0.85)
 
 settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
 settingsFrame.title:SetPoint("TOP", titleBg, "TOP", 0, -3)
 settingsFrame.title:SetFont(FONT_PATH, 14, FONT_FLAGS)
 settingsFrame.title:SetText("Matt's Minimal DPS")
 settingsFrame.title:SetTextColor(1, 1, 1, 1)
 
 local closeBtn = settingsFrame:CreateFontString(nil, "OVERLAY")
 closeBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -8, -6)
 closeBtn:SetFont(FONT_PATH, 16, FONT_FLAGS)
 closeBtn:SetText("X")
 closeBtn:SetTextColor(1, 1, 1, 1)
 local closeFrame = CreateFrame("Button", nil, settingsFrame)
 closeFrame:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -2)
 closeFrame:SetSize(20, 20)
 closeFrame:SetScript("OnClick", function() settingsFrame:Hide() end)
 closeFrame:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
 
 local descText = settingsFrame:CreateFontString(nil, "OVERLAY")
 descText:SetPoint("TOPLEFT", 15, -35)
 descText:SetPoint("TOPRIGHT", -15, -35)
 descText:SetFont(FONT_PATH, 10, FONT_FLAGS)
 descText:SetText("A minimal skin for the Blizzard's Damage Meter.")
 descText:SetTextColor(0.8, 0.8, 0.8, 1)
 descText:SetWordWrap(true)
 
 local taglineText = settingsFrame:CreateFontString(nil, "OVERLAY")
 taglineText:SetPoint("TOPLEFT", 15, -55)
 taglineText:SetPoint("TOPRIGHT", -15, -55)
 taglineText:SetFont("Fonts\\FRIZQT__.ttf", 10, "ITALIC")
 taglineText:SetText("Does this thing really need any other options?")
 taglineText:SetTextColor(0.5, 0.5, 0.5, 1)
 taglineText:SetWordWrap(true)
-- Reset mode dropdown
local resetModeLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
resetModeLabel:SetPoint("TOPLEFT", 20, -160)
resetModeLabel:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS)
resetModeLabel:SetText("Auto Reset Mode:")
resetModeLabel:SetTextColor(1, 1, 1, 1)

local resetModeDropdown = CreateFrame("Frame", nil, settingsFrame, "UIDropDownMenuTemplate")
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
UIDropDownMenu_SetWidth(resetModeDropdown, 160)
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
local resetNowBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
resetNowBtn:SetSize(100, 22)
resetNowBtn:SetPoint("LEFT", resetModeDropdown, "RIGHT", 12, 0)
resetNowBtn:SetText("Reset Now")
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
  
 local minimapCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
 minimapCheckbox:SetPoint("TOPLEFT", 20, -120)
 minimapCheckbox:SetSize(24, 24)
 minimapCheckbox.text = minimapCheckbox:CreateFontString(nil, "OVERLAY")
 minimapCheckbox.text:SetPoint("LEFT", minimapCheckbox, "RIGHT", 5, 0)
 minimapCheckbox.text:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS)
 minimapCheckbox.text:SetText("Minimap Icon")
 minimapCheckbox.text:SetTextColor(1, 1, 1, 1)
 
 minimapCheckbox:SetScript("OnClick", function(self)
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.minimapIcon = MattMinimalDPSDB.minimapIcon or {}
  if self:GetChecked() then
   LibDBIcon:Show("MattMinimalDPS")
   MattMinimalDPSDB.minimapIcon.hide = false
  else
   LibDBIcon:Hide("MattMinimalDPS")
   MattMinimalDPSDB.minimapIcon.hide = true
  end
 end)
 
 local themeCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
 themeCheckbox:SetPoint("TOPLEFT", 20, -90)
 themeCheckbox:SetSize(24, 24)
 themeCheckbox.text = themeCheckbox:CreateFontString(nil, "OVERLAY")
 themeCheckbox.text:SetPoint("LEFT", themeCheckbox, "RIGHT", 5, 0)
 themeCheckbox.text:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS)
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
