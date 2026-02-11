local f=CreateFrame("Frame")
local FONT_PATH="Interface\\AddOns\\MattMinimalDPS\\Fonts\\Naowh.ttf"
local FONT_SIZE=12
local FONT_FLAGS="OUTLINE"

-- TAINT PREVENTION: Never write custom keys to Blizzard frames.
-- Track our own state in a separate weak-keyed table so we don't taint Blizzard's frame tables.
local mmdps_state = setmetatable({}, { __mode = "k" })

local function m(h) if not h then return end if h.IsForbidden and h:IsForbidden() then return end if h.Hide then h:Hide() end if h.SetAlpha then h:SetAlpha(0) end end

local function b(w)
 if not w then return end
 if w.Background and w.Background.SetColorTexture then
  w.Background:SetColorTexture(0,0,0,1)
  return
 end
 -- Use our own table to track the background texture, NEVER write to the Blizzard frame
 local state = mmdps_state[w]
 if not state then state = {} mmdps_state[w] = state end
 if not state.bg then
  local t = w:CreateTexture(nil,"BACKGROUND",nil,-8)
  t:SetAllPoints(w)
  t:SetColorTexture(0,0,0,1)
  state.bg = t
 else
  if state.bg.SetColorTexture then state.bg:SetColorTexture(0,0,0,1) end
 end
end

-- Apply Naowh font to a damage meter entry's Name and Value FontStrings (widget-only, no taint)
local function applyEntryFont(entry)
 if not entry then return end
 pcall(function()
  local nameFS = entry:GetStatusBar() and entry:GetStatusBar().Name
  if nameFS and nameFS.SetFont then nameFS:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS) end
  local valueFS = entry:GetStatusBar() and entry:GetStatusBar().Value
  if valueFS and valueFS.SetFont then valueFS:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS) end
 end)
end

-- Hook DamageMeterEntryMixin.Init once so every new/recycled entry gets the Naowh font
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
 -- Apply Naowh font to header text elements (TypeName, SessionName, SessionTimer)
 pcall(function()
  local typeName = dropdown and dropdown.TypeName
  if typeName and typeName.SetFont then typeName:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); typeName:SetTextColor(1, 1, 1, 1) end
  -- Also style the dropdown button's own Text FontString if present
  if dropdown and dropdown.Text and dropdown.Text.SetFont then dropdown.Text:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); dropdown.Text:SetTextColor(1, 1, 1, 1) end
  local sessionDD = w.SessionDropdown
  local sessionName = sessionDD and sessionDD.SessionName
  if sessionName and sessionName.SetFont then sessionName:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); sessionName:SetTextColor(1, 1, 1, 1) end
  if sessionDD and sessionDD.Text and sessionDD.Text.SetFont then sessionDD.Text:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); sessionDD.Text:SetTextColor(1, 1, 1, 1) end
  local sessionTimer = w.SessionTimer
  if sessionTimer and sessionTimer.SetFont then sessionTimer:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); sessionTimer:SetTextColor(1, 1, 1, 1) end
  local notActive = w.NotActive
  if notActive and notActive.SetFont then notActive:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS); notActive:SetTextColor(1, 1, 1, 1) end
 end)
 -- Apply Naowh font to all currently visible entry frames in the ScrollBox
 if sb and sb.EnumerateFrames then
  pcall(function()
   for _, frame in sb:EnumerateFrames() do
    applyEntryFont(frame)
   end
  end)
 end
end

local function apply()
 local dm = _G.DamageMeter
 if not dm then return end
 -- Install the entry font hook once DamageMeterEntryMixin is available
 installEntryFontHook()
 -- Defer so we're never in Blizzard's call stack
 C_Timer.After(0, function()
  -- Find session windows by name from _G instead of calling dm:ForEachSessionWindow (avoids tainting dm's execution path)
  for i = 1, 10 do
   local w = _G["DamageMeterSessionWindow"..i]
   if w then s(w) end
  end
 end)
end

MattMinimalDPSDB = MattMinimalDPSDB or {}
MattMinimalDPSDB.useCustomTheme = MattMinimalDPSDB.useCustomTheme ~= false 

-- TAINT NOTE: Do NOT call dm:SetStyle, dm:SetBarSpacing, dm:SetShowBarIcons, etc. from addon code.
-- Those methods chain into ForEachEntryFrame -> frame:SetStyle(style) which writes self.style = style
-- to the entry frame table from addon execution context, tainting the entire entry and causing
-- "attempt to compare local 'text' (a secret string value tainted by 'MattMinimalDPS')" in UpdateName.
-- Users should configure meter settings via Blizzard's built-in settings dropdown instead.

-- Options panel (settings dropdown only, no "reset defaults" - calling dm methods taints entry frames)

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent",function(_, ev)
 if MattMinimalDPSDB.useCustomTheme then apply() end
 if not f._t then f._t=C_Timer.NewTicker(2, function() if MattMinimalDPSDB.useCustomTheme then apply() end end) end
 if not f._retry then f._retry = C_Timer.NewTicker(1, function() if MattMinimalDPSDB.useCustomTheme then apply() end end, 8) end
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
    -- Toggle visibility via SetShown (don't write to dm.visibility - causes taint)
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
 settingsFrame:SetSize(400, 200)
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
 end)
 
 local function forceOpenDamageMeter()
  pcall(function() SetCVar("damageMeterEnabled", "1") end)
  -- Only use CVar + SetShown. Never call dm:RefreshLayout() (chains into entry frame writes and taints).
  local dm = _G.DamageMeter
  if dm then
   if dm.SetShown then pcall(dm.SetShown, dm, true) end
  end
 end
 
 C_Timer.After(2, forceOpenDamageMeter)
end
