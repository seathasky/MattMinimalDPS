local f=CreateFrame("Frame")
local FONT_PATH="Interface\\AddOns\\MattMinimalDPS\\Fonts\\Naowh.ttf"
local FONT_SIZE=12
local FONT_FLAGS="OUTLINE"
local function m(h) if not h then return end if h.IsForbidden and h:IsForbidden() then return end if h.Hide then h:Hide() end if h.SetAlpha then h:SetAlpha(0) end end
local function b(w) if not w then return end if w.Background and w.Background.SetColorTexture then w.Background:SetColorTexture(0,0,0,1) return end if not w.__dr_bg then local t=w:CreateTexture(nil,"BACKGROUND",nil,-8);t:SetAllPoints(w);t:SetColorTexture(0,0,0,1);w.__dr_bg=t else if w.__dr_bg.SetColorTexture then w.__dr_bg:SetColorTexture(0,0,0,1) end end end
local function s(w)
 if not w or type(w.GetName)~="function" then return end
 local hdr=w.HeaderBar or w.TitleBar or w.headerBar or w.titleBar or w.Header
 m(hdr)
 b(w)
 local function applyStyle(obj)
  if not obj then return end
  if obj.SetFont then pcall(obj.SetFont, obj, FONT_PATH, FONT_SIZE, FONT_FLAGS) end
  if obj.SetTextColor then pcall(obj.SetTextColor, obj, 1, 1, 1) end
  if obj.GetRegions then
   for _, r in ipairs({obj:GetRegions()}) do
    if r then
     if r.SetFont then pcall(r.SetFont, r, FONT_PATH, FONT_SIZE, FONT_FLAGS) end
     if r.SetTextColor then pcall(r.SetTextColor, r, 1, 1, 1) end
    end
   end
  end
  if obj.GetChildren then
   for _, c in ipairs({obj:GetChildren()}) do applyStyle(c) end
  end
 end

 applyStyle(w)
 local dropdown = w.DamageMeterTypeDropdown
 if dropdown and dropdown.Arrow then
  if not dropdown.__mmdps_arrowHooked then
   dropdown.__mmdps_arrowHooked = true
   if dropdown.OnButtonStateChanged then
    hooksecurefunc(dropdown, "OnButtonStateChanged", function(self)
     if self.Arrow then
      self.Arrow:SetDesaturation(1)
      self.Arrow:SetVertexColor(3, 3, 3, 1)
     end
    end)
   end
  end
  dropdown.Arrow:SetDesaturation(1)
  dropdown.Arrow:SetVertexColor(3, 3, 3, 1)
 end
 local settings = w.SettingsDropdown
 if settings and settings.Icon then
  if not settings.__mmdps_iconHooked then
   settings.__mmdps_iconHooked = true
   if settings.OnButtonStateChanged then
    hooksecurefunc(settings, "OnButtonStateChanged", function(self)
     if self.Icon then
      self.Icon:SetDesaturation(1)
      self.Icon:SetVertexColor(3, 3, 3, 1)
     end
    end)
   end
  end
  settings.Icon:SetDesaturation(1)
  settings.Icon:SetVertexColor(3, 3, 3, 1)
 end
 local sb = w.ScrollBox
 local header = w.HeaderBar or w.Header
 local insetL, insetR = 10, 10
 if sb and header then
  pcall(function() sb:ClearAllPoints(); sb:SetPoint("TOPLEFT", header, "BOTTOMLEFT", insetL, -5); sb:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -insetR, 6) end)
 end
 local st = sb and sb.ScrollTarget
 local fullWidth = (st and st.GetWidth and st:GetWidth()) or (sb and sb.GetWidth and sb:GetWidth())
 local BAR_ATLAS = "UI-HUD-CoolDownManager-Bar"
 local function styleRow(row)
  if not row or not row.StatusBar then return end
  local bar = row.StatusBar
  if not row.__mmdps_customBar then
   bar:SetAlpha(0)
   bar:Hide()
   if bar.SetStatusBarTexture then bar:SetStatusBarTexture("") end
   bar:ClearAllPoints()
   bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -10000, -10000)
   bar:EnableMouse(false)
   if bar.UnregisterAllEvents then bar:UnregisterAllEvents() end
   bar:SetScript("OnUpdate", nil)
   bar:SetScript("OnShow", nil)
   bar:SetScript("OnHide", nil)
   local customBar = CreateFrame("StatusBar", nil, row)
   customBar:SetFrameLevel(bar:GetFrameLevel() + 1)
   customBar:SetAllPoints(row)
   local barTex = customBar:CreateTexture(nil, "ARTWORK")
   barTex:SetAtlas(BAR_ATLAS)
   customBar:SetStatusBarTexture(barTex)
   customBar:SetMinMaxValues(0, 100)
   customBar:SetValue(100)
   customBar:Show()
   customBar:EnableMouse(false)
   if bar.Name then
    bar.Name:SetParent(customBar)
    bar.Name:ClearAllPoints()
    bar.Name:SetPoint("LEFT", customBar, "LEFT", 5, 0)
    if bar.Name.SetFont then pcall(bar.Name.SetFont, bar.Name, FONT_PATH, FONT_SIZE, FONT_FLAGS) end
    if bar.Name.SetTextColor then pcall(bar.Name.SetTextColor, bar.Name, 1, 1, 1) end
   end
   if bar.Value then
    bar.Value:SetParent(customBar)
    bar.Value:ClearAllPoints()
    bar.Value:SetPoint("RIGHT", customBar, "RIGHT", -5, 0)
    if bar.Value.SetFont then pcall(bar.Value.SetFont, bar.Value, FONT_PATH, FONT_SIZE, FONT_FLAGS) end
    if bar.Value.SetTextColor then pcall(bar.Value.SetTextColor, bar.Value, 1, 1, 1) end
   end
   customBar:SetScript("OnUpdate", function(self)
    if not bar:IsForbidden() then
     local min, max = bar:GetMinMaxValues()
     local value = bar:GetValue()
     self:SetMinMaxValues(min, max)
     self:SetValue(value)
     local r, g, b, a = bar:GetStatusBarColor()
     self:SetStatusBarColor(r, g, b, a or 1)
    end
    local iconFrame = row.Icon or row.icon
    self:ClearAllPoints()
    if iconFrame and iconFrame:IsShown() then 
     self:SetPoint("LEFT", iconFrame, "RIGHT", 2, 0)
    else 
     self:SetPoint("LEFT", row, "LEFT", 0, 0)
    end
    self:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    self:SetPoint("TOP", row, "TOP", 0, -1)
    self:SetPoint("BOTTOM", row, "BOTTOM", 0, 1)
   end)
   row.__mmdps_customBar = customBar
  end
  applyStyle(row)
  if fullWidth and fullWidth > 0 then
   if row.SetWidth then row:SetWidth(fullWidth) end
  end
 end
 if sb and sb.EnumerateFrames then
  for _, row in sb:EnumerateFrames() do styleRow(row) end
 end
end
local function apply()
 local dm = _G.DamageMeter
 if dm and dm.ForEachSessionWindow then
  dm:ForEachSessionWindow(s)
 else
  for i = 1, 10 do
   local n = _G["DamageMeterSessionWindow"..i] if n then s(n) end
   local o = _G["OtherSessionWindow"..i] if o then s(o) end
  end
  local fr = EnumerateFrames()
  while fr do
   if fr.GetName and type(fr.GetName)=="function" then
    local name = fr:GetName()
    if type(name)=="string" and (name:find("DamageMeterSessionWindow") or name:find("OtherSessionWindow")) then s(fr) end
   end
   fr = EnumerateFrames(fr)
  end
 end
end

MattMinimalDPSDB = MattMinimalDPSDB or {}
MattMinimalDPSDB.useCustomTheme = MattMinimalDPSDB.useCustomTheme ~= false 

local function setMeterToAddonDefaults()
 local dm = _G.DamageMeter
 if not dm or not dm.SetStyle then return false end
 local function safe(method, ...) if type(dm[method])=="function" then dm[method](dm, ...) end end
 safe("SetStyle", Enum.DamageMeterStyle.Default)
 safe("SetNumberDisplayType", Enum.DamageMeterNumbers.Compact)
 safe("SetBarSpacing", 2)
 safe("SetWindowTransparency", 100)
 safe("SetBackgroundTransparency", 65)
 safe("SetTextSize", 120)
 dm.visibility = Enum.DamageMeterVisibility.Always
 safe("SetShowBarIcons", true)
 safe("SetUseClassColor", true)
 if dm.UpdateShownState then dm:UpdateShownState() end
 if dm.RefreshLayout then dm:RefreshLayout() end
 return true
end

local function applyMeterDefaults()
 if MattMinimalDPSDB.meterDefaultsApplied then return end
 if InCombatLockdown() then return end
 if setMeterToAddonDefaults() then MattMinimalDPSDB.meterDefaultsApplied = true end
end

local opt = CreateFrame("Frame", "MattMinimalDPSOptionsFrame")
opt.name = "Matt's Minimal DPS"
opt:Hide()
opt:SetScript("OnShow", function()
 if opt.resetBtn then return end
 local btn = CreateFrame("Button", nil, opt, "UIPanelButtonTemplate")
 opt.resetBtn = btn
 btn:SetSize(280, 24)
 btn:SetPoint("TOPLEFT", 16, -24)
 btn:SetText("Reset Damage Meter to Addon Defaults")
 btn:SetScript("OnClick", function()
  if InCombatLockdown() then
   print("Matt's Minimal DPS: Cannot reset while in combat.") return
  end
  if setMeterToAddonDefaults() then
   print("Matt's Minimal DPS: Damage meter reset to addon defaults.")
  else
   print("Matt's Minimal DPS: Damage meter not available.")
  end
 end)
 local title = opt:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
 title:SetPoint("TOPLEFT", 16, -16)
 title:SetText("Matt's Minimal DPS")
end)
if InterfaceOptions_AddCategory then
 InterfaceOptions_AddCategory(opt)
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:SetScript("OnEvent",function(_, ev)
 if MattMinimalDPSDB.useCustomTheme then apply() end
 if not f._t then f._t=C_Timer.NewTicker(2, function() if MattMinimalDPSDB.useCustomTheme then apply() end end) end
 if not f._retry then f._retry = C_Timer.NewTicker(1, function() if MattMinimalDPSDB.useCustomTheme then apply() end end, 8) end
 if ev == "PLAYER_LOGIN" then
  C_Timer.After(1, function()
   if MattMinimalDPSDB.useCustomTheme then
    if InCombatLockdown() then f._meterDefaultsPending = true else applyMeterDefaults() end
   end
  end)
 elseif ev == "PLAYER_REGEN_ENABLED" and f._meterDefaultsPending then
  f._meterDefaultsPending = nil
  if MattMinimalDPSDB.useCustomTheme then applyMeterDefaults() end
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
     if dm.visibility == Enum.DamageMeterVisibility.Hidden then
      dm.visibility = Enum.DamageMeterVisibility.Always
     else
      dm.visibility = Enum.DamageMeterVisibility.Hidden
     end
     if dm.UpdateShownState then dm:UpdateShownState() end
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
  SetCVar("damageMeterEnabled", "1")
  
  local dm = _G.DamageMeter
  if dm then
   dm.visibility = Enum.DamageMeterVisibility.Always
   if dm.UpdateShownState then dm:UpdateShownState() end
   if dm.RefreshLayout then dm:RefreshLayout() end
  end
 end
 
 C_Timer.After(2, forceOpenDamageMeter)
end
