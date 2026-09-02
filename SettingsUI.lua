local MMDPS = MattMinimalDPS or {}
local LibStub = MMDPS.LibStub or _G.LibStub
local GUI_FONT_PATH = MMDPS.GUI_FONT_PATH
local GUI_FONT_SIZE = MMDPS.GUI_FONT_SIZE
local GUI_FONT_FLAGS = MMDPS.GUI_FONT_FLAGS
local MMDPS_FONT_DEFAULT = MMDPS.MMDPS_FONT_DEFAULT
local DEFAULT_TITLE_OPACITY = MMDPS.DEFAULT_TITLE_OPACITY
local BACKDROP_STYLES = MMDPS.BACKDROP_STYLES
local BACKDROP_STYLE_ORDER = MMDPS.BACKDROP_STYLE_ORDER
local NormalizeMediaName = MMDPS.NormalizeMediaName
local MediaNamesEqual = MMDPS.MediaNamesEqual
local ClampFontSize = MMDPS.ClampFontSize
local GetItemFontSize = MMDPS.GetItemFontSize
local EnsureFontSizeSettings = MMDPS.EnsureFontSizeSettings
local MMDPS_GetGlobalFontName = MMDPS.GetGlobalFontName
local MMDPS_GetFontOptions = MMDPS.GetFontOptions
local MMDPS_SetGlobalFont = MMDPS.SetGlobalFont
local MMDPS_SetFontSizeForItem = MMDPS.SetFontSizeForItem
local getBackdropStyle = MMDPS.GetBackdropStyle
local getBackdropOpacity = MMDPS.GetBackdropOpacity
local getTitleOpacity = MMDPS.GetTitleOpacity
local getMouseoverButtonsEnabled = MMDPS.GetMouseoverButtonsEnabled
local getShowSessionInTypeLabel = MMDPS.GetShowSessionInTypeLabel
local MMDPS_UpdateAllWindowButtonsMouseover = MMDPS.UpdateAllWindowButtonsMouseover
local MMDPS_UpdateAllWindowTypeLabels = MMDPS.UpdateAllWindowTypeLabels
local MMDPS_CreateClassIconSizeSlider = MMDPS.CreateClassIconSizeSlider
local MMDPS_ShowSettingsFrame = MMDPS.ShowSettingsFrame
local MMDPS_ResetPrimaryWindowPosition = MMDPS.ResetPrimaryWindowPosition
local EnsureMinimapIconSettings = MMDPS.EnsureMinimapIconSettings
local ApplyMinimapIconVisibility = MMDPS.ApplyMinimapIconVisibility
local apply = MMDPS.Apply

local settingsFrame

local MMDPS_StyleMinimalScrollFrame = MMDPS.StyleMinimalScrollFrame
local MMDPS_UpdateMinimalScrollFrameVisibility = MMDPS.UpdateMinimalScrollFrameVisibility
local MMDPS_StyleMinimalSlider = MMDPS.StyleMinimalSlider
local MMDPS_StyleMinimalDropdown = MMDPS.StyleMinimalDropdown
local MMDPS_StyleMinimalButton = MMDPS.StyleMinimalButton

local SETTINGS_SIZE = {
 defaultWidth = 420,
 defaultHeight = 340,
 minWidth = 420,
 minHeight = 300,
 maxWidth = 720,
 maxHeight = 620,
}

local function MMDPS_GetAddonVersion()
 local addonName = MMDPS.addonName or "MattMinimalDPS"
 local version = nil
 if C_AddOns and C_AddOns.GetAddOnMetadata then
  version = C_AddOns.GetAddOnMetadata(addonName, "Version")
 elseif GetAddOnMetadata then
  version = GetAddOnMetadata(addonName, "Version")
 end
 return version
end

local function MMDPS_CreateScrollPane(key, contentHeight)
 local scrollFrame = CreateFrame("ScrollFrame", "MattMinimalDPSSettingsScroll"..key, settingsFrame, "UIPanelScrollFrameTemplate")
 scrollFrame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 28, -148)
 scrollFrame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -32, 18)
 scrollFrame:EnableMouseWheel(true)

 local content = CreateFrame("Frame", nil, scrollFrame)
 content:SetSize(352, contentHeight)
 scrollFrame:SetScrollChild(content)
 content._scrollFrame = scrollFrame

 scrollFrame:SetScript("OnMouseWheel", function(self, delta)
  local offset = self:GetVerticalScroll() - (delta * 24)
  local minOffset, maxOffset = 0, 0
  local scrollBar = self.ScrollBar or (self.GetName and _G[self:GetName().."ScrollBar"])
  if scrollBar and scrollBar.GetMinMaxValues then
   minOffset, maxOffset = scrollBar:GetMinMaxValues()
  end
  if offset < minOffset then offset = minOffset end
  if offset > maxOffset then offset = maxOffset end
  self:SetVerticalScroll(offset)
 end)

 MMDPS_StyleMinimalScrollFrame(scrollFrame)
 return content
end

settingsFrame = CreateFrame("Frame", "MattMinimalDPSSettingsFrame", UIParent, "BackdropTemplate")
 settingsFrame:SetSize(SETTINGS_SIZE.defaultWidth, SETTINGS_SIZE.defaultHeight)
 settingsFrame:SetPoint("CENTER")
 settingsFrame:SetMovable(true)
 settingsFrame:SetResizable(true)
 if settingsFrame.SetResizeBounds then
  settingsFrame:SetResizeBounds(SETTINGS_SIZE.minWidth, SETTINGS_SIZE.minHeight, SETTINGS_SIZE.maxWidth, SETTINGS_SIZE.maxHeight)
 elseif settingsFrame.SetMinResize then
  settingsFrame:SetMinResize(SETTINGS_SIZE.minWidth, SETTINGS_SIZE.minHeight)
  if settingsFrame.SetMaxResize then
   settingsFrame:SetMaxResize(SETTINGS_SIZE.maxWidth, SETTINGS_SIZE.maxHeight)
  end
 end
 settingsFrame:EnableMouse(true)
 settingsFrame:RegisterForDrag("LeftButton")
 settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
 settingsFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
 end)
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
 settingsFrame:SetBackdropBorderColor(0.88, 0.88, 0.88, 0.95)
 
 local titleBg = settingsFrame:CreateTexture(nil, "ARTWORK")
 titleBg:SetPoint("TOPLEFT", 10, -10)
 titleBg:SetPoint("TOPRIGHT", -10, -10)
 titleBg:SetHeight(30)
 titleBg:SetColorTexture(0.08, 0.08, 0.08, 0.85)
 
 settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
 settingsFrame.title:SetPoint("LEFT", titleBg, "LEFT", 10, 0)
 settingsFrame.title:SetPoint("RIGHT", titleBg, "RIGHT", -86, 0)
 settingsFrame.title:SetFont(GUI_FONT_PATH, 13, GUI_FONT_FLAGS)
 settingsFrame.title:SetJustifyH("LEFT")
 settingsFrame.title:SetText("Matt's Minimal DPS")
 settingsFrame.title:SetTextColor(0.95, 0.95, 0.95, 1)

 settingsFrame.versionText = settingsFrame:CreateFontString(nil, "OVERLAY")
 settingsFrame.versionText:SetPoint("RIGHT", titleBg, "RIGHT", -36, 0)
 settingsFrame.versionText:SetFont(GUI_FONT_PATH, 12, GUI_FONT_FLAGS)
 settingsFrame.versionText:SetJustifyH("RIGHT")
 settingsFrame.versionText:SetTextColor(0.88, 0.88, 0.88, 1)
 local addonVersion = MMDPS_GetAddonVersion()
 settingsFrame.versionText:SetText(addonVersion and ("v"..addonVersion) or "")
 
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

 local resizeGrip = CreateFrame("Button", nil, settingsFrame)
 resizeGrip:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -5, 5)
 resizeGrip:SetSize(18, 18)
 resizeGrip:SetFrameLevel(settingsFrame:GetFrameLevel() + 5)
 resizeGrip:EnableMouse(true)
 resizeGrip.dot = resizeGrip:CreateTexture(nil, "OVERLAY")
 resizeGrip.dot:SetPoint("BOTTOMRIGHT", resizeGrip, "BOTTOMRIGHT", -3, 3)
 resizeGrip.dot:SetSize(4, 4)
 resizeGrip.dot:SetColorTexture(1, 1, 1, 0.42)
 resizeGrip:SetScript("OnEnter", function(self)
  self.dot:SetColorTexture(1, 1, 1, 0.85)
 end)
 resizeGrip:SetScript("OnLeave", function(self)
  self.dot:SetColorTexture(1, 1, 1, 0.42)
 end)
 resizeGrip:SetScript("OnMouseDown", function()
  settingsFrame:StartSizing("BOTTOMRIGHT")
 end)
 resizeGrip:SetScript("OnMouseUp", function()
  settingsFrame:StopMovingOrSizing()
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.settingsWidth = math.floor(settingsFrame:GetWidth() + 0.5)
  MattMinimalDPSDB.settingsHeight = math.floor(settingsFrame:GetHeight() + 0.5)
 end)
 
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
 general = MMDPS_CreateScrollPane("General", 220),
 sessions = MMDPS_CreateScrollPane("Sessions", 270),
 font = MMDPS_CreateScrollPane("Font", 340),
 style = MMDPS_CreateScrollPane("Style", 310),
 system = MMDPS_CreateScrollPane("System", 180),
 }
 local HideFontPicker = nil
 local tabOrder = { "general", "sessions", "font", "style", "system" }

 local function ClampSettingsSize(width, height)
  width = tonumber(width) or SETTINGS_SIZE.defaultWidth
  height = tonumber(height) or SETTINGS_SIZE.defaultHeight
  if width < SETTINGS_SIZE.minWidth then width = SETTINGS_SIZE.minWidth end
  if width > SETTINGS_SIZE.maxWidth then width = SETTINGS_SIZE.maxWidth end
  if height < SETTINGS_SIZE.minHeight then height = SETTINGS_SIZE.minHeight end
  if height > SETTINGS_SIZE.maxHeight then height = SETTINGS_SIZE.maxHeight end
  return width, height
 end

 local function UpdateScrollPaneVisibility()
  for _, pane in pairs(panes) do
   local scrollFrame = pane._scrollFrame
   if scrollFrame then
    local paneWidth = scrollFrame:GetWidth()
    if paneWidth and paneWidth > 1 then
     pane:SetWidth(math.max(300, paneWidth - 4))
    end
    if MMDPS_UpdateMinimalScrollFrameVisibility then
     MMDPS_UpdateMinimalScrollFrameVisibility(scrollFrame)
    end
   end
  end
 end

 local function UpdateTabLayout()
  local tabInset = 14
  local tabSpacing = 4
  local tabCount = #tabOrder
  local tabUsableWidth = settingsFrame:GetWidth() - (tabInset * 2) - (tabSpacing * (tabCount - 1))
  local tabWidth = math.floor(tabUsableWidth / tabCount)
  local tabRemainder = tabUsableWidth - (tabWidth * tabCount)
  local x = tabInset
  for idx, key in ipairs(tabOrder) do
   local btn = tabButtons[key]
   if btn then
    local width = tabWidth + (tabRemainder >= idx and 1 or 0)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", x, -110)
    btn:SetSize(width, 22)
    x = x + width + tabSpacing
   end
  end
 end

 local function UpdateSettingsLayout()
  UpdateTabLayout()
  UpdateScrollPaneVisibility()
  if C_Timer then
   C_Timer.After(0, UpdateScrollPaneVisibility)
  end
 end

 settingsFrame:HookScript("OnSizeChanged", function(self)
  UpdateSettingsLayout()
  if not self:IsShown() then return end
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.settingsWidth = math.floor(self:GetWidth() + 0.5)
  MattMinimalDPSDB.settingsHeight = math.floor(self:GetHeight() + 0.5)
 end)

 local function SetActiveTab(tabKey)
  if tabKey == "appearance" then
   tabKey = "font"
  end
  if not panes[tabKey] then tabKey = "general" end
  if HideFontPicker then
   HideFontPicker()
  end
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.activeTab = tabKey
  for key, pane in pairs(panes) do
   if pane._scrollFrame then
    pane._scrollFrame:SetShown(key == tabKey)
   else
    pane:SetShown(key == tabKey)
   end
  end
  UpdateSettingsLayout()
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
 local tabCount = #tabOrder
 local tabUsableWidth = settingsFrame:GetWidth() - (tabInset * 2) - (tabSpacing * (tabCount - 1))
 local tabWidth = math.floor(tabUsableWidth / tabCount)
 local tabRemainder = tabUsableWidth - (tabWidth * tabCount)
 local tabX = tabInset
 for idx, key in ipairs(tabOrder) do
  local width = tabWidth + (tabRemainder >= idx and 1 or 0)
  local label = key == "system" and "System" or key:gsub("^%l", string.upper)
  CreateTabButton(key, label, tabX, width)
  tabX = tabX + width + tabSpacing
 end
 UpdateSettingsLayout()

 local tabDivider = settingsFrame:CreateTexture(nil, "ARTWORK")
 tabDivider:SetPoint("TOPLEFT", tabInset, -136)
 tabDivider:SetPoint("TOPRIGHT", -tabInset, -136)
 tabDivider:SetHeight(1)
 tabDivider:SetColorTexture(0.18, 0.18, 0.18, 0.9)

 local fontLabel = panes.font:CreateFontString(nil, "OVERLAY")
 fontLabel:SetPoint("TOPLEFT", 0, -8)
 fontLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 fontLabel:SetText("Font:")
 fontLabel:SetTextColor(1, 1, 1, 1)

 local fontDropdown = CreateFrame("Frame", nil, panes.font, "UIDropDownMenuTemplate")
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
  MMDPS_StyleMinimalScrollFrame(fontPickerScrollFrame)
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

 local fontScaleTitle = panes.font:CreateFontString(nil, "OVERLAY")
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
  local label = panes.font:CreateFontString(nil, "OVERLAY")
  label:SetPoint("TOPLEFT", 0, row.y)
  label:SetFont(GUI_FONT_PATH, 10, GUI_FONT_FLAGS)
  label:SetText(row.text)
  label:SetTextColor(0.85, 0.85, 0.85, 1)

  local valueText = panes.font:CreateFontString(nil, "OVERLAY")
  valueText:SetPoint("LEFT", label, "RIGHT", 8, 0)
  valueText:SetFont(GUI_FONT_PATH, 10, GUI_FONT_FLAGS)
  valueText:SetTextColor(0.8, 0.8, 0.8, 1)

  local slider = CreateFrame("Slider", "MattMinimalDPSFontSizeSlider"..idx, panes.font, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 190, row.y + 2)
  slider:SetMinMaxValues(8, 20)
  slider:SetValueStep(1)
  slider:SetObeyStepOnDrag(true)
  slider:SetWidth(170)
  slider:SetHeight(14)
  _G[slider:GetName().."Low"]:SetText("")
  _G[slider:GetName().."High"]:SetText("")
  _G[slider:GetName().."Text"]:SetText("")
  MMDPS_StyleMinimalSlider(slider)

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

 local backdropLabel = panes.style:CreateFontString(nil, "OVERLAY")
 backdropLabel:SetPoint("TOPLEFT", 0, -8)
 backdropLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 backdropLabel:SetText("Backdrop Style:")
 backdropLabel:SetTextColor(1, 1, 1, 1)

 local backdropDropdown = CreateFrame("Frame", nil, panes.style, "UIDropDownMenuTemplate")
 backdropDropdown:SetPoint("TOPLEFT", backdropLabel, "BOTTOMLEFT", -15, -2)
 local opacitySliderLabel = panes.style:CreateFontString(nil, "OVERLAY")
 opacitySliderLabel:SetPoint("TOPLEFT", backdropDropdown, "BOTTOMLEFT", 15, -6)
 opacitySliderLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 opacitySliderLabel:SetText("Backdrop Opacity:")
 opacitySliderLabel:SetTextColor(1, 1, 1, 1)

 local opacityValueText = panes.style:CreateFontString(nil, "OVERLAY")
 opacityValueText:SetPoint("LEFT", opacitySliderLabel, "RIGHT", 8, 0)
 opacityValueText:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 opacityValueText:SetTextColor(0.8, 0.8, 0.8, 1)

local opacitySlider = CreateFrame("Slider", "MattMinimalDPSBackdropOpacitySlider", panes.style, "OptionsSliderTemplate")
opacitySlider:SetPoint("TOPLEFT", opacitySliderLabel, "BOTTOMLEFT", 0, -8)
 opacitySlider:SetMinMaxValues(0, 1)
 opacitySlider:SetValueStep(0.05)
 opacitySlider:SetObeyStepOnDrag(true)
 opacitySlider:SetWidth(180)
 opacitySlider:SetHeight(16)
 _G[opacitySlider:GetName().."Low"]:SetText("0%")
 _G[opacitySlider:GetName().."High"]:SetText("100%")
 _G[opacitySlider:GetName().."Text"]:SetText("")
 MMDPS_StyleMinimalSlider(opacitySlider)

 local titleOpacitySliderLabel = panes.style:CreateFontString(nil, "OVERLAY")
 titleOpacitySliderLabel:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -14)
 titleOpacitySliderLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 titleOpacitySliderLabel:SetText("Title Opacity:")
 titleOpacitySliderLabel:SetTextColor(1, 1, 1, 1)

 local titleOpacityValueText = panes.style:CreateFontString(nil, "OVERLAY")
 titleOpacityValueText:SetPoint("LEFT", titleOpacitySliderLabel, "RIGHT", 8, 0)
 titleOpacityValueText:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 titleOpacityValueText:SetTextColor(0.8, 0.8, 0.8, 1)

 local titleOpacitySlider = CreateFrame("Slider", "MattMinimalDPSTitleOpacitySlider", panes.style, "OptionsSliderTemplate")
 titleOpacitySlider:SetPoint("TOPLEFT", titleOpacitySliderLabel, "BOTTOMLEFT", 0, -6)
 titleOpacitySlider:SetMinMaxValues(0, 1)
 titleOpacitySlider:SetValueStep(0.05)
 titleOpacitySlider:SetObeyStepOnDrag(true)
 titleOpacitySlider:SetWidth(180)
 titleOpacitySlider:SetHeight(16)
 _G[titleOpacitySlider:GetName().."Low"]:SetText("0%")
 _G[titleOpacitySlider:GetName().."High"]:SetText("100%")
 _G[titleOpacitySlider:GetName().."Text"]:SetText("")
 MMDPS_StyleMinimalSlider(titleOpacitySlider)

 panes.style.classIconSizeSlider = MMDPS_CreateClassIconSizeSlider(panes.style, titleOpacitySlider)
 MMDPS_StyleMinimalSlider(panes.style.classIconSizeSlider)

 panes.style.backdropUIUpdating = false
 local function RefreshBackdropOpacityUI()
  panes.style.backdropUIUpdating = true
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
  panes.style.backdropUIUpdating = false
 end

 panes.style.titleOpacityUIUpdating = false
 local function RefreshTitleOpacityUI()
  panes.style.titleOpacityUIUpdating = true
  local opacity = getTitleOpacity()
  titleOpacitySlider:SetValue(opacity)
  titleOpacityValueText:SetText(string.format("%d%%", math.floor(opacity * 100 + 0.5)))
  panes.style.titleOpacityUIUpdating = false
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
 if MMDPS.StyleOpenDropdownLists then
  MMDPS.StyleOpenDropdownLists()
 end
end)
UIDropDownMenu_SetWidth(backdropDropdown, 190)
MMDPS_StyleMinimalDropdown(backdropDropdown, 190)
do
 local selectedStyle = getBackdropStyle()
 UIDropDownMenu_SetSelectedValue(backdropDropdown, selectedStyle)
 UIDropDownMenu_SetText(backdropDropdown, GetBackdropStyleText(selectedStyle))
end

RefreshFontDropdownMenu()
UIDropDownMenu_SetWidth(fontDropdown, 190)
MMDPS_StyleMinimalDropdown(fontDropdown, 190)
do
 local selectedFont = MMDPS_GetGlobalFontName()
 SetFontDropdownDisplay(selectedFont)
end
for key, widgets in pairs(fontSizeWidgets) do
 local itemKey = key
 local itemWidgets = widgets
 widgets.slider:SetScript("OnValueChanged", function(self, value)
  if fontSizeUIUpdating then return end
  local size = ClampFontSize(value)
  itemWidgets.valueText:SetText(tostring(size))
  MMDPS_SetFontSizeForItem(itemKey, size)
 end)
end
RefreshFontSizeUI()

opacitySlider:SetScript("OnValueChanged", function(self, value)
 if panes.style.backdropUIUpdating then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local clamped = math.max(0, math.min(1, value or 1))
 MattMinimalDPSDB.backdropOpacity = clamped
 RefreshBackdropOpacityUI()
 if getBackdropStyle() ~= "transparent" and MattMinimalDPSDB.useCustomTheme then
  apply()
 end
end)
RefreshBackdropOpacityUI()

titleOpacitySlider:SetScript("OnValueChanged", function(self, value)
 if panes.style.titleOpacityUIUpdating then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 local clamped = math.max(0, math.min(1, value or DEFAULT_TITLE_OPACITY))
 MattMinimalDPSDB.titleOpacity = clamped
 RefreshTitleOpacityUI()
 if MattMinimalDPSDB.useCustomTheme then
  apply()
 end
end)
RefreshTitleOpacityUI()

panes.style.mouseoverButtonsCheckbox = CreateFrame("CheckButton", nil, panes.style, "UICheckButtonTemplate")
panes.style.mouseoverButtonsCheckbox:SetPoint("TOPLEFT", panes.style.classIconSizeSlider, "BOTTOMLEFT", 0, -18)
panes.style.mouseoverButtonsCheckbox:SetSize(24, 24)
panes.style.mouseoverButtonsCheckbox.text = panes.style.mouseoverButtonsCheckbox:CreateFontString(nil, "OVERLAY")
panes.style.mouseoverButtonsCheckbox.text:SetPoint("LEFT", panes.style.mouseoverButtonsCheckbox, "RIGHT", 5, 0)
panes.style.mouseoverButtonsCheckbox.text:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
panes.style.mouseoverButtonsCheckbox.text:SetText("Mouseover Buttons")
panes.style.mouseoverButtonsCheckbox.text:SetTextColor(1, 1, 1, 1)
panes.style.mouseoverButtonsCheckbox:SetChecked(getMouseoverButtonsEnabled())
panes.style.mouseoverButtonsCheckbox:SetScript("OnClick", function(self)
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.mouseoverButtons = self:GetChecked()
 MMDPS_UpdateAllWindowButtonsMouseover()
end)

UIDropDownMenu_Initialize(resetModeDropdown, function(self, level, menuList)
    local selected = GetResetMode()
    for _, mode in ipairs(resetModes) do
        local modeValue = mode.value
        local modeText = mode.text
        local info = UIDropDownMenu_CreateInfo()
        info.text = modeText
        info.value = modeValue
        info.func = function()
            SetResetMode(modeValue)
            UIDropDownMenu_SetSelectedValue(resetModeDropdown, modeValue)
            UIDropDownMenu_SetText(resetModeDropdown, modeText)
        end
        info.checked = (modeValue == selected)
        UIDropDownMenu_AddButton(info)
    end
    if MMDPS.StyleOpenDropdownLists then
        MMDPS.StyleOpenDropdownLists()
    end
end)
UIDropDownMenu_SetWidth(resetModeDropdown, 190)
MMDPS_StyleMinimalDropdown(resetModeDropdown, 190)
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
MMDPS_StyleMinimalButton(resetNowBtn)
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

local typeLabelSessionCheckbox = CreateFrame("CheckButton", nil, panes.sessions, "UICheckButtonTemplate")
typeLabelSessionCheckbox:SetPoint("TOPLEFT", resetModeDropdown, "BOTTOMLEFT", 15, -12)
typeLabelSessionCheckbox:SetSize(24, 24)
typeLabelSessionCheckbox.text = typeLabelSessionCheckbox:CreateFontString(nil, "OVERLAY")
typeLabelSessionCheckbox.text:SetPoint("LEFT", typeLabelSessionCheckbox, "RIGHT", 5, 0)
typeLabelSessionCheckbox.text:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
typeLabelSessionCheckbox.text:SetText("Show Current/Overall Next to DPS")
typeLabelSessionCheckbox.text:SetTextColor(1, 1, 1, 1)
typeLabelSessionCheckbox:SetChecked(getShowSessionInTypeLabel())
typeLabelSessionCheckbox:SetScript("OnClick", function(self)
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.showSessionInTypeLabel = self:GetChecked()
 MMDPS_UpdateAllWindowTypeLabels()
end)

local systemLabel = panes.system:CreateFontString(nil, "OVERLAY")
systemLabel:SetPoint("TOPLEFT", 0, -8)
systemLabel:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
systemLabel:SetText("Window Position:")
systemLabel:SetTextColor(1, 1, 1, 1)

local resetWindowBtn = CreateFrame("Button", nil, panes.system, "UIPanelButtonTemplate")
resetWindowBtn:SetSize(170, 20)
resetWindowBtn:SetPoint("TOPLEFT", systemLabel, "BOTTOMLEFT", -15, -8)
resetWindowBtn:SetText("Center Main Window")
MMDPS_StyleMinimalButton(resetWindowBtn)
resetWindowBtn:SetScript("OnClick", function()
    if MMDPS_ResetPrimaryWindowPosition then
        MMDPS_ResetPrimaryWindowPosition()
    end
end)
resetWindowBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Move the main DPS window back to the middle of the screen")
    GameTooltip:Show()
end)
resetWindowBtn:SetScript("OnLeave", function()
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
  local minimapDB = EnsureMinimapIconSettings()
  if self:GetChecked() then
   minimapDB.hide = false
  else
   minimapDB.hide = true
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
    MattMinimalDPSDB = MattMinimalDPSDB or {}
    settingsFrame:SetSize(ClampSettingsSize(MattMinimalDPSDB.settingsWidth, MattMinimalDPSDB.settingsHeight))
    local minimapDB = EnsureMinimapIconSettings()
    minimapCheckbox:SetChecked(not minimapDB.hide)
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
     typeLabelSessionCheckbox:SetChecked(getShowSessionInTypeLabel())
	    local selectedStyle = getBackdropStyle()
	    UIDropDownMenu_SetSelectedValue(backdropDropdown, selectedStyle)
	    UIDropDownMenu_SetText(backdropDropdown, GetBackdropStyleText(selectedStyle))
	    RefreshFontDropdownMenu()
	    local selectedFont = MMDPS_GetGlobalFontName()
	    SetFontDropdownDisplay(selectedFont)
	    RefreshFontSizeUI()
	    RefreshBackdropOpacityUI()
     RefreshTitleOpacityUI()
     if panes.style.classIconSizeSlider and panes.style.classIconSizeSlider.RefreshValue then
      panes.style.classIconSizeSlider.RefreshValue()
     end
     panes.style.mouseoverButtonsCheckbox:SetChecked(getMouseoverButtonsEnabled())
     if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
      MMDPS_UpdateAllWindowButtonsMouseover()
      MMDPS_UpdateAllWindowTypeLabels()
     end
	    SetActiveTab((MattMinimalDPSDB and MattMinimalDPSDB.activeTab) or "general")
     UpdateSettingsLayout()
end)
settingsFrame:HookScript("OnHide", function()
 if HideFontPicker then
  HideFontPicker()
 end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.settingsWidth = math.floor(settingsFrame:GetWidth() + 0.5)
 MattMinimalDPSDB.settingsHeight = math.floor(settingsFrame:GetHeight() + 0.5)
end)
