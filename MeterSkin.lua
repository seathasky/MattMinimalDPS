local MMDPS = MattMinimalDPS or {}
local FONT_SIZE_DEFAULTS = MMDPS.FONT_SIZE_DEFAULTS
local FONT_FLAGS = MMDPS.FONT_FLAGS
local GUI_FONT_PATH = MMDPS.GUI_FONT_PATH
local GUI_FONT_SIZE = MMDPS.GUI_FONT_SIZE
local GUI_FONT_FLAGS = MMDPS.GUI_FONT_FLAGS
local GetFontPath = MMDPS.GetFontPath
local GetItemFontSize = MMDPS.GetItemFontSize
local GetClassIconSize = MMDPS.GetClassIconSize
local ClampClassIconSize = MMDPS.ClampClassIconSize
local MMDPS_RegisterManagedFontString = MMDPS.RegisterManagedFontString
local MMDPS_SetFontSafe = MMDPS.SetFontSafe
local MMDPS_SetRegionFont = MMDPS.SetRegionFont
local getBackdropColor = MMDPS.GetBackdropColor
local getTitleOpacity = MMDPS.GetTitleOpacity
local getMouseoverButtonsEnabled = MMDPS.GetMouseoverButtonsEnabled
local getShowSessionInTypeLabel = MMDPS.GetShowSessionInTypeLabel

local mmdps_state = setmetatable({}, { __mode = "k" })
local MMDPS_EXPERIMENTAL_COMBAT_MOUSEOVER = true
local mmdpsEditModeHookRetries = 0
local HEADER_DIVIDER_COLOR = { 1, 1, 1, 0.18 }
local HEADER_DIVIDER_THICKNESS = 1
local HEADER_SHADE_RGB = { 0, 0, 0 }
local HEADER_BUTTON_GAP = 6
local HEADER_BUTTON_RIGHT_INSET = -18
local HEADER_BUTTON_SIZE = 24
local HEADER_BUTTON_ICON_SIZE = 16

local function m(h) if not h then return end if h.IsForbidden and h:IsForbidden() then return end if h.Hide then h:Hide() end if h.SetAlpha then h:SetAlpha(0) end end

local function MMDPS_HideFrameVisualRegions(frame)
 if not frame or type(frame.GetRegions) ~= "function" then return end
 if frame.IsForbidden and frame:IsForbidden() then return end
 for _, region in ipairs({frame:GetRegions()}) do
  if region and region.GetObjectType and region:GetObjectType() == "Texture" then
   if region.Hide then
    region:Hide()
   end
   if region.SetAlpha then
    region:SetAlpha(0)
   end
  end
 end
end

local function b(w)
 if not w then return end
 local r, g, bA, a = getBackdropColor()
 m(w.Background)

 local state = mmdps_state[w]
 if not state then state = {} mmdps_state[w] = state end
 if not state.bg then
  local t = w:CreateTexture(nil,"BACKGROUND",nil,-8)
  t:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -2)
  t:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -10, 8)
  state.bg = t
 end
 if state.bg.SetColorTexture then state.bg:SetColorTexture(r, g, bA, a) end
end

local function MMDPS_SetFrameMouseoverAlpha(frame, alpha)
 if not frame then return end
 if frame.IsForbidden and frame:IsForbidden() then return end
 if (not MMDPS_EXPERIMENTAL_COMBAT_MOUSEOVER) and InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end

 if frame.SetAlpha then frame:SetAlpha(alpha) end
 -- Some dropdown templates drive visuals via named regions that may not fully
 -- follow parent alpha on every state transition.
 local visualKeys = { "Background", "Arrow", "Icon", "Text", "SessionName" }
 for _, key in ipairs(visualKeys) do
  local region = frame[key]
  if region and region.SetAlpha then
   region:SetAlpha(alpha)
  end
 end
 if frame.GetRegions then
  for _, region in ipairs({frame:GetRegions()}) do
   if region and region.SetAlpha then
    region:SetAlpha(alpha)
   end
  end
 end
end

local mmdpsMouseoverTicker = nil
local mmdpsTypeLabelTicker = nil
local mmdpsTypeLabelHooksInstalled = false

local function MMDPS_IsCursorInFrameBounds(frame)
 if not frame then return false end
 if not (GetCursorPosition and UIParent and UIParent.GetEffectiveScale) then return false end
 local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
 if not (left and right and top and bottom) then return false end
 local scale = UIParent:GetEffectiveScale() or 1
 local cx, cy = GetCursorPosition()
 cx, cy = cx / scale, cy / scale
 return cx >= left and cx <= right and cy >= bottom and cy <= top
end

local function MMDPS_SetWindowButtonsAlpha(w, alpha)
 local state = mmdps_state[w]
 if not state then return end
 if state.buttonFrames then
  for frame in pairs(state.buttonFrames) do
   MMDPS_SetFrameMouseoverAlpha(frame, alpha)
  end
 end
end

local function MMDPS_UpdateWindowButtonsMouseover(w)
 if not w then return end
 local state = mmdps_state[w]
 if not state then return end

 local mouseoverEnabled = getMouseoverButtonsEnabled()
 local showButtons = not mouseoverEnabled
 if mouseoverEnabled then
  showButtons = MMDPS_IsCursorInFrameBounds(w)
  if not showButtons and state.buttonFrames then
   for frame in pairs(state.buttonFrames) do
    if MMDPS_IsCursorInFrameBounds(frame) then
     showButtons = true
     break
    end
   end
  end

  local now = GetTime and GetTime() or 0
  if showButtons then
   state.lastHoverTime = now
  elseif state.lastHoverTime and (now - state.lastHoverTime) < 0.18 then
   -- Small linger prevents rapid flicker when cursor rides frame edges.
   showButtons = true
  end
 else
  state.lastHoverTime = nil
 end

 if state.lastShowButtons ~= showButtons then
  state.lastShowButtons = showButtons
  MMDPS_SetWindowButtonsAlpha(w, showButtons and 1 or 0)
 end

 local sessionTimer = w.SessionTimer
 if sessionTimer then
  local showTimer = not showButtons
  if sessionTimer.SetShown then
   sessionTimer:SetShown(showTimer)
  elseif sessionTimer.SetAlpha then
   sessionTimer:SetAlpha(showTimer and 1 or 0)
  end
 end
end

local function MMDPS_UpdateAllWindowButtonsMouseover()
 if (not MMDPS_EXPERIMENTAL_COMBAT_MOUSEOVER) and InCombatLockdown and InCombatLockdown() then
  MMDPS.pendingMouseoverRefreshAfterCombat = true
  return
 end
 for i = 1, 40 do
  local w = _G["DamageMeterSessionWindow"..i]
  if w then
   MMDPS_UpdateWindowButtonsMouseover(w)
  end
 end
end

local function MMDPS_StartMouseoverTicker()
 if mmdpsMouseoverTicker then return end
 if not (C_Timer and C_Timer.NewTicker) then return end
 mmdpsMouseoverTicker = C_Timer.NewTicker(0.08, function()
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and getMouseoverButtonsEnabled() then
   MMDPS_UpdateAllWindowButtonsMouseover()
  end
 end)
end

local function MMDPS_GetSessionModeTextForWindow(w)
 if not w then return nil end
 local sessionType = nil
 if w.GetSessionType then
  sessionType = w:GetSessionType()
 end
 if sessionType == nil then
  sessionType = w.sessionType
 end

 if sessionType ~= nil and Enum and Enum.DamageMeterSessionType then
  if sessionType == Enum.DamageMeterSessionType.Overall then
   return "Overall"
  end
  if sessionType == Enum.DamageMeterSessionType.Current then
   return "Current"
  end
 end

 local sessionDD = w.SessionDropdown
 local sessionName = sessionDD and sessionDD.SessionName
 local sessionText = sessionName and sessionName.GetText and sessionName:GetText() or nil
 if type(sessionText) ~= "string" or sessionText == "" then return nil end
 local normalized = sessionText:lower()
 if normalized:find("overall", 1, true) then
  return "Overall"
 end
 if normalized:find("current", 1, true) then
  return "Current"
 end
 return nil
end

local function MMDPS_StripSessionSuffix(labelText)
 if type(labelText) ~= "string" then return nil end
 return (labelText:gsub("%s*%-%s*[Oo]verall%s*$", ""):gsub("%s*%-%s*[Cc]urrent%s*$", ""))
end

local function MMDPS_UpdateWindowTypeLabelWithSession(w)
 if not w then return end
 local dropdown = w.DamageMeterTypeDropdown
 local typeName = dropdown and dropdown.TypeName
 if not (typeName and typeName.GetText and typeName.SetText) then return end

 local state = mmdps_state[w]
 if not state then
  state = {}
  mmdps_state[w] = state
 end

 local currentText = typeName:GetText() or ""
 local baseFromCurrent = MMDPS_StripSessionSuffix(currentText)
 if baseFromCurrent and baseFromCurrent ~= "" then
  state.baseTypeLabel = baseFromCurrent
 end
 local baseText = state.baseTypeLabel or baseFromCurrent or currentText or ""
 if baseText == "" then return end

 local finalText = baseText
 if getShowSessionInTypeLabel() then
  local modeText = MMDPS_GetSessionModeTextForWindow(w)
  if modeText then
   finalText = baseText .. " - " .. modeText
  end
 end

 if typeName:GetText() ~= finalText then
  typeName:SetText(finalText)
 end
 if dropdown and dropdown.Text and dropdown.Text.SetText and dropdown.Text.GetText then
  if dropdown.Text:GetText() ~= finalText then
   dropdown.Text:SetText(finalText)
  end
 end
end

local function MMDPS_UpdateAllWindowTypeLabels()
 for i = 1, 40 do
  local w = _G["DamageMeterSessionWindow"..i]
  if w then
   MMDPS_UpdateWindowTypeLabelWithSession(w)
  end
 end
end

local function MMDPS_StartTypeLabelTicker()
 if mmdpsTypeLabelTicker then return end
 if not (C_Timer and C_Timer.NewTicker) then return end
 mmdpsTypeLabelTicker = C_Timer.NewTicker(0.35, function()
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and getShowSessionInTypeLabel() then
   MMDPS_UpdateAllWindowTypeLabels()
  end
 end)
end

local function MMDPS_InstallTypeLabelHooks()
 if mmdpsTypeLabelHooksInstalled or not hooksecurefunc then return end
 if not DamageMeterSessionWindowMixin then return end

 if type(DamageMeterSessionWindowMixin.SetSession) == "function" then
  hooksecurefunc(DamageMeterSessionWindowMixin, "SetSession", function(self)
   MMDPS_UpdateWindowTypeLabelWithSession(self)
  end)
 end
 if type(DamageMeterSessionWindowMixin.SetDamageMeterType) == "function" then
  hooksecurefunc(DamageMeterSessionWindowMixin, "SetDamageMeterType", function(self)
   local state = mmdps_state[self]
   if state then
    state.baseTypeLabel = nil
   end
   MMDPS_UpdateWindowTypeLabelWithSession(self)
  end)
 end

 mmdpsTypeLabelHooksInstalled = true
end

local function MMDPS_ConfigureMeterButtonsMouseover(w)
 if not w then return end
 local state = mmdps_state[w]
 if not state then
  state = {}
  mmdps_state[w] = state
 end

 state.buttonFrames = setmetatable({}, { __mode = "k" })
 local buttonCandidates = {
  w.SettingsDropdown,
  w.SessionDropdown,
  w.DamageMeterTypeDropdown,
  w.ResizeButton,
  w.MinimizeButton,
  w.MaximizeButton,
  w.CloseButton,
  w.ResizeGrip,
 }
 for _, frame in ipairs(buttonCandidates) do
  if frame then
   state.buttonFrames[frame] = true
  end
 end

 MMDPS_StartMouseoverTicker()
 MMDPS_StartTypeLabelTicker()
 MMDPS_UpdateWindowButtonsMouseover(w)
end

local function MMDPS_EnsureHeaderDivider(w)
 if not w then return end
 local state = mmdps_state[w]
 if not state then
  state = {}
  mmdps_state[w] = state
 end

 if not state.headerDivider then
  local divider = w:CreateTexture(nil, "OVERLAY", nil, 1)
  local header = w.HeaderBar or w.TitleBar or w.headerBar or w.titleBar or w.Header
  if header then
   divider:SetPoint("TOPLEFT", header, "TOPLEFT", 10, -24)
   divider:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -24)
  else
   divider:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -24)
   divider:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -24)
  end
  divider:SetHeight(HEADER_DIVIDER_THICKNESS)
  state.headerDivider = divider
 end

 local r, g, bA, a = unpack(HEADER_DIVIDER_COLOR)
 state.headerDivider:SetColorTexture(r, g, bA, a)
 state.headerDivider:Show()
end

local function MMDPS_EnsureHeaderShade(w)
 if not w then return end
 local state = mmdps_state[w]
 if not state then
  state = {}
  mmdps_state[w] = state
 end

 if not state.headerShade then
  -- Above window background, below header text/icons.
  -- Anchor to inner window bounds (not Blizzard header texture) to avoid bleed.
  local shade = w:CreateTexture(nil, "BACKGROUND", nil, -7)
  shade:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -2)
  shade:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -2)
  shade:SetHeight(24)
  state.headerShade = shade
 end

 local r, g, bA = unpack(HEADER_SHADE_RGB)
 state.headerShade:SetColorTexture(r, g, bA, getTitleOpacity())
 state.headerShade:Show()
end

-- Apply matt font

local function MMDPS_ApplyEntryFontString(fontString, sizeKey)
 if not fontString or not fontString.SetFont then return end
 local resolvedSizeKey = FONT_SIZE_DEFAULTS[sizeKey] and sizeKey or "entryName"
 MMDPS_RegisterManagedFontString(fontString, resolvedSizeKey, FONT_FLAGS)
 MMDPS_SetFontSafe(fontString, GetFontPath(), GetItemFontSize(resolvedSizeKey), FONT_FLAGS)
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

        local iconSize = GetClassIconSize()
        local candidates = {
         entry.Icon and entry.Icon.Icon, entry.Icon,
         entry.ClassIcon, entry.classIcon, entry.icon, entry.PlayerIcon,
         statusBar and statusBar.ClassIcon, statusBar and statusBar.classIcon,
         statusBar and statusBar.Icon, statusBar and statusBar.icon, statusBar and statusBar.PlayerIcon,
        }
        for _, tex in ipairs(candidates) do
         if tex and tex.SetSize then
          tex:SetSize(iconSize, iconSize)
         end
        end
    end)
end


local entryHookInstalled = false
local mmdpsHookedScrollBoxes = setmetatable({}, { __mode = "k" })
local MMDPS_StyleSessionScrollBar

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

    -- Track the owning session window so Blizzard's later ScrollBox updates
    -- cannot restore the 12.0.5 reserved scrollbar lane after our skin pass.
    local w = self._mmdpsOwnerWindow
    local header = w and (w.HeaderBar or w.Header)
    if w and header then
     pcall(function()
      self:ClearAllPoints()
      self:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 10, -5)
      self:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -5, 6)
     end)
     local scrollBar = (w.MinimizeContainer and w.MinimizeContainer.ScrollBar) or w.ScrollBar or self.ScrollBar
     MMDPS_StyleSessionScrollBar(scrollBar)
    end
   end
  end)
  end

  mmdpsHookedScrollBoxes[scrollBox] = true
end

MMDPS_StyleSessionScrollBar = function(scrollBar)
 if not scrollBar then return end

 -- Blizzard 12.0.5 moved the session scrollbar under MinimizeContainer and
 -- added multiple art layers. Hide the visuals without touching row layout.
  MMDPS_HideFrameVisualRegions(scrollBar)

 local track = scrollBar.Track
 if track then
  MMDPS_HideFrameVisualRegions(track)
  m(track)
  if track.Thumb then
   MMDPS_HideFrameVisualRegions(track.Thumb)
   m(track.Thumb)
   if track.Thumb.Middle then
    m(track.Thumb.Middle)
   end
  end
 end

 local back = scrollBar.Back
 if back then
  MMDPS_HideFrameVisualRegions(back)
  m(back)
  if back.Texture then
   m(back.Texture)
  end
 end

 if scrollBar.DecrementButton then
  m(scrollBar.DecrementButton)
 end
 if scrollBar.IncrementButton then
  m(scrollBar.IncrementButton)
 end
 if scrollBar.Backward then
  m(scrollBar.Backward)
 end
 if scrollBar.Forward then
  m(scrollBar.Forward)
 end

 if scrollBar.SetWidth then
  scrollBar:SetWidth(1)
 end
 if scrollBar.EnableMouse then
  scrollBar:EnableMouse(false)
 end
 if scrollBar.SetAlpha then
  scrollBar:SetAlpha(0)
 end
 if scrollBar.Hide then
  scrollBar:Hide()
 end
 if scrollBar.HookScript and not scrollBar._mmdpsHideHooked then
  scrollBar:HookScript("OnShow", function(self)
   if self.Hide then
    self:Hide()
   end
  end)
  scrollBar._mmdpsHideHooked = true
 end
end

local function installEntryFontHook()
 if entryHookInstalled then return end
 if not DamageMeterEntryMixin then return end

 local hookedAny = false
 local methodCandidates = {
  "Init",
  "SetTextScale",
  "Update",
  "Refresh",
 "SetData",
 "SetEntryData",
 "OnDataChanged",
  "UpdateIcon",
  "UpdateStyle",
  "SetupSharedStyleIconVisibility",
  "SetupDefaultStyle",
  "SetupBorderedStyle",
  "SetupFullBackgroundStyle",
  "SetupThinStyle",
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

function MMDPS_AllowUnrestrictedWindowMovement(frame)
 if not frame then return end
 if frame.SetMovable then
  frame:SetMovable(true)
 end
 if frame.SetClampedToScreen then
  frame:SetClampedToScreen(false)
 end
 if frame.SetClampRectInsets then
  frame:SetClampRectInsets(-10000, -10000, -10000, -10000)
 end
end

function MMDPS_SavePrimaryWrapperPosition()
 local wrapper = _G.MattMinimalDPSPrimaryDamageMeterFrame
 if not wrapper or not wrapper.GetCenter then return end
 if not UIParent then return end
 local centerX, centerY = wrapper:GetCenter()
 local parentCenterX, parentCenterY = UIParent:GetCenter()
 if not (centerX and centerY and parentCenterX and parentCenterY) then return end

 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.primaryWindow = MattMinimalDPSDB.primaryWindow or {}
 MattMinimalDPSDB.primaryWindow.x = centerX - parentCenterX
 MattMinimalDPSDB.primaryWindow.y = centerY - parentCenterY
 MattMinimalDPSDB.primaryWindow.w = wrapper:GetWidth()
 MattMinimalDPSDB.primaryWindow.h = wrapper:GetHeight()
end

function MMDPS_GetPrimaryWrapper()
 if _G.MattMinimalDPSPrimaryDamageMeterFrame then
  return _G.MattMinimalDPSPrimaryDamageMeterFrame
 end
 if not UIParent then return nil end

 local wrapper = CreateFrame("Frame", "MattMinimalDPSPrimaryDamageMeterFrame", UIParent)
 wrapper:SetMovable(true)
 wrapper:SetResizable(true)
 wrapper:SetClampedToScreen(false)
 if wrapper.SetClampRectInsets then
  wrapper:SetClampRectInsets(-10000, -10000, -10000, -10000)
 end
 if wrapper.SetResizeBounds then
  wrapper:SetResizeBounds(320, 140)
 elseif wrapper.SetMinResize then
  wrapper:SetMinResize(320, 140)
 end
 wrapper:EnableMouse(false)
 wrapper:SetFrameStrata("LOW")

 local drag = CreateFrame("Frame", "MattMinimalDPSPrimaryDamageMeterDragHandle", UIParent)
 drag:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
 drag:SetPoint("TOPRIGHT", wrapper, "TOPRIGHT", -110, 0)
 drag:SetHeight(28)
 drag:SetFrameStrata("DIALOG")
 drag:EnableMouse(true)
 drag:RegisterForDrag("LeftButton")
 drag:SetScript("OnDragStart", function()
  if InCombatLockdown and InCombatLockdown() then return end
  wrapper:StartMoving()
 end)
 drag:SetScript("OnDragStop", function()
  wrapper:StopMovingOrSizing()
  MMDPS_SavePrimaryWrapperPosition()
 end)
 wrapper.dragHandle = drag
 wrapper:HookScript("OnShow", function()
  drag:Show()
 end)
 wrapper:HookScript("OnHide", function()
  drag:Hide()
 end)

 wrapper:SetScript("OnSizeChanged", function()
  if wrapper._mmdpsSizingReady then
   MMDPS_SavePrimaryWrapperPosition()
  end
 end)

 _G.MattMinimalDPSPrimaryDamageMeterFrame = wrapper
 return wrapper
end

function MMDPS_PositionPrimaryWrapper(wrapper, sourceWindow)
 if not wrapper then return end
 MattMinimalDPSDB = MattMinimalDPSDB or {}
 MattMinimalDPSDB.primaryWindow = MattMinimalDPSDB.primaryWindow or {}
 local saved = MattMinimalDPSDB.primaryWindow

 local width = tonumber(saved.w) or (sourceWindow and sourceWindow.GetWidth and sourceWindow:GetWidth()) or 400
 local height = tonumber(saved.h) or (sourceWindow and sourceWindow.GetHeight and sourceWindow:GetHeight()) or 200
 if width < 320 then width = 320 end
 if height < 140 then height = 140 end
 wrapper:SetSize(width, height)

 wrapper:ClearAllPoints()
 if saved.x and saved.y then
  wrapper:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
 elseif sourceWindow and sourceWindow.GetCenter then
  local centerX, centerY = sourceWindow:GetCenter()
  local parentCenterX, parentCenterY = UIParent:GetCenter()
  if centerX and centerY and parentCenterX and parentCenterY then
   wrapper:SetPoint("CENTER", UIParent, "CENTER", centerX - parentCenterX, centerY - parentCenterY)
  else
   wrapper:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
 else
  wrapper:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
 end

 wrapper._mmdpsSizingReady = true
end

function MMDPS_HostPrimaryWindow(w)
 if not w or not w.GetName or w:GetName() ~= "DamageMeterSessionWindow1" then return false end
 if InCombatLockdown and InCombatLockdown() then return true end
 local wrapper = MMDPS_GetPrimaryWrapper()
 if not wrapper then return true end
 if not wrapper._mmdpsPositioned then
  MMDPS_PositionPrimaryWrapper(wrapper, w)
  wrapper._mmdpsPositioned = true
 end

 wrapper:Show()
 w:ClearAllPoints()
 w:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
 w:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
 if w.SetClampedToScreen then
  w:SetClampedToScreen(false)
 end
 if w.SetClampRectInsets then
  w:SetClampRectInsets(-10000, -10000, -10000, -10000)
 end
 return true
end

function MMDPS_ShowSettingsFrame(tabKey)
 if InCombatLockdown and InCombatLockdown() then
  print("|cff66ccffMMDPS|r Settings cannot be edited while in combat.")
  return false
 end

 local settings = _G.MattMinimalDPSSettingsFrame
 if not settings then return false end

 if tabKey then
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.activeTab = tabKey
 end

 settings:Show()
 settings:Raise()
 return true
end

function MMDPS_IsDamageMeterEditModeFrame(frame)
 if not frame then return false end
 if frame == _G.DamageMeter then return true end
 if frame.GetName and frame:GetName() == "DamageMeter" then return true end
 if frame.systemNameString == "Damage Meter" then return true end
 if _G.Enum and Enum.EditModeSystem and frame.system == Enum.EditModeSystem.DamageMeter then return true end
 return false
end

function MMDPS_OpenSettingsFromDamageMeterEditMode(frame)
 if not MMDPS_IsDamageMeterEditModeFrame(frame) then return end
 if InCombatLockdown and InCombatLockdown() then
  MMDPS_ShowSettingsFrame("general")
  return
 end

 if not MMDPS_ShowSettingsFrame("general") and C_Timer then
  C_Timer.After(0, function()
   MMDPS_ShowSettingsFrame("general")
  end)
 end
end

function MMDPS_InstallEditModeSettingsHook()
 local manager = _G.EditModeManagerFrame
 if manager and manager._mmdpsSettingsHooked then return end
 if not manager or type(manager.SelectSystem) ~= "function" then
  if C_Timer and mmdpsEditModeHookRetries < 10 then
   mmdpsEditModeHookRetries = mmdpsEditModeHookRetries + 1
   C_Timer.After(1, MMDPS_InstallEditModeSettingsHook)
  end
  return
 end

 hooksecurefunc(manager, "SelectSystem", function(_, selectFrame)
  MMDPS_OpenSettingsFromDamageMeterEditMode(selectFrame)
 end)

 manager._mmdpsSettingsHooked = true
end

local function s(w)
 if not w or type(w.GetName)~="function" then return end
 local inCombat = InCombatLockdown and InCombatLockdown()
 local hdr = w.HeaderBar or w.TitleBar or w.headerBar or w.titleBar or w.Header
 local isPrimaryWindow = w:GetName() == "DamageMeterSessionWindow1"
 if isPrimaryWindow then
  MMDPS_HostPrimaryWindow(w)
 else
  MMDPS_AllowUnrestrictedWindowMovement(w)
  MMDPS_AllowUnrestrictedWindowMovement(w.MinimizeContainer)
  MMDPS_AllowUnrestrictedWindowMovement(w.SourceWindow)
 end
 m(hdr)
 b(w)
 m(w.MinimizeButton)
 MMDPS_HideFrameVisualRegions(w.MinimizeContainer)
 if w.MinimizeContainer and w.MinimizeContainer.Background then
  m(w.MinimizeContainer.Background)
 end
 MMDPS_EnsureHeaderShade(w)
 MMDPS_EnsureHeaderDivider(w)
 MMDPS_ConfigureMeterButtonsMouseover(w)
 local dropdown = w.DamageMeterTypeDropdown
 if dropdown and dropdown.Arrow then
  dropdown.Arrow:SetDesaturation(1)
  dropdown.Arrow:SetVertexColor(3, 3, 3, 1)
 end
 local settings = w.SettingsDropdown
 if settings and settings.Icon then
  settings.Icon:SetDesaturation(1)
  settings.Icon:SetVertexColor(3, 3, 3, 1)
  if settings.Icon.SetSize then settings.Icon:SetSize(HEADER_BUTTON_ICON_SIZE, HEADER_BUTTON_ICON_SIZE) end
 end

 local sb = w.ScrollBox or (w.GetScrollBox and w:GetScrollBox())
 if sb then
  -- The ScrollBox update hook needs to know which session window to restore
  -- anchors against after Blizzard reapplies managed scrollbar layout.
  sb._mmdpsOwnerWindow = w
 end
 MMDPS_HookScrollBoxFontRefresh(sb)
 local header = w.HeaderBar or w.Header
 local scrollBar = (w.MinimizeContainer and w.MinimizeContainer.ScrollBar) or (sb and sb.ScrollBar)
 local resizeOwner = w.MinimizeContainer or w
 local resizeButton = w.ResizeButton or (w.MinimizeContainer and w.MinimizeContainer.ResizeButton)

 MMDPS_StyleSessionScrollBar(scrollBar)
 if w.SetResizeBounds then
  w:SetResizeBounds(320, 140)
 elseif w.SetMinResize then
  w:SetMinResize(320, 140)
 end
 if resizeOwner and resizeOwner ~= w then
  if resizeOwner.SetResizeBounds then
   resizeOwner:SetResizeBounds(320, 140)
  elseif resizeOwner.SetMinResize then
   resizeOwner:SetMinResize(320, 140)
  end
 end
 if resizeButton then
  resizeButton.minWidth = 320
  resizeButton.minHeight = 140
 end
 local insetL, insetR = 10, 5
 if sb and header then
  pcall(function()
   sb:ClearAllPoints()
   sb:SetPoint("TOPLEFT", header, "BOTTOMLEFT", insetL, -5)
   sb:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -insetR, 6)
  end)
 end

 pcall(function()
  local sessionDD = w.SessionDropdown
  local typeName = dropdown and dropdown.TypeName
  local sessionTimer = w.SessionTimer

  if not inCombat then
   local anchorFrame = header or w
   local headerButtonYOffset = 2
   if settings then
    settings:ClearAllPoints()
    settings:SetPoint("RIGHT", anchorFrame, "RIGHT", HEADER_BUTTON_RIGHT_INSET, headerButtonYOffset)
    if settings.SetSize then settings:SetSize(HEADER_BUTTON_SIZE, HEADER_BUTTON_SIZE) end
   end

   if dropdown then
    dropdown:ClearAllPoints()
    if dropdown.SetSize then dropdown:SetSize(HEADER_BUTTON_SIZE, HEADER_BUTTON_SIZE) end
    if settings then
     dropdown:SetPoint("RIGHT", settings, "LEFT", -HEADER_BUTTON_GAP, 0)
    else
     dropdown:SetPoint("RIGHT", anchorFrame, "RIGHT", HEADER_BUTTON_RIGHT_INSET - 28, headerButtonYOffset)
    end
   end

   if sessionDD then
    sessionDD:ClearAllPoints()
    if sessionDD.SetSize then sessionDD:SetSize(HEADER_BUTTON_SIZE, HEADER_BUTTON_SIZE) end
    if dropdown then
     sessionDD:SetPoint("RIGHT", dropdown, "LEFT", -HEADER_BUTTON_GAP, 2)
    elseif settings then
     sessionDD:SetPoint("RIGHT", settings, "LEFT", -HEADER_BUTTON_GAP, 2)
    end
    if sessionDD.Arrow then
     if sessionDD.Arrow.SetAlpha then sessionDD.Arrow:SetAlpha(0) end
     if sessionDD.Arrow.SetDesaturation then sessionDD.Arrow:SetDesaturation(1) end
    end
    if sessionDD.ResetButton then
     if sessionDD.ResetButton.SetAlpha then sessionDD.ResetButton:SetAlpha(0) end
     if sessionDD.ResetButton.Hide then sessionDD.ResetButton:Hide() end
    end
    if sessionDD.Background then
     -- WowStyle2 dropdown background extends beyond frame by default; clamp it
     -- so this control matches the visual footprint of the other header buttons.
     sessionDD.Background:ClearAllPoints()
     sessionDD.Background:SetPoint("TOPLEFT", sessionDD, "TOPLEFT", 0, 0)
     sessionDD.Background:SetPoint("BOTTOMRIGHT", sessionDD, "BOTTOMRIGHT", 0, 0)
     if sessionDD.Background.SetAtlas then
      sessionDD.Background:SetAtlas("common-dropdown-c-button", true)
     end
    end
   end
  end

  if sessionTimer and not inCombat then
   sessionTimer:ClearAllPoints()
   if header then
    sessionTimer:SetPoint("RIGHT", header, "RIGHT", -12, 2)
   else
    sessionTimer:SetPoint("RIGHT", w, "RIGHT", -12, 2)
   end
   if sessionTimer.SetJustifyH then sessionTimer:SetJustifyH("RIGHT") end
   if sessionTimer.SetWidth then sessionTimer:SetWidth(72) end
  end

  if typeName and not inCombat then
   if typeName.GetParent and typeName:GetParent() ~= w and typeName.SetParent then
    typeName:SetParent(w)
   end
   typeName:ClearAllPoints()
   if header then
    typeName:SetPoint("LEFT", header, "LEFT", 22, 2)
   else
    typeName:SetPoint("LEFT", w, "LEFT", 22, 3)
   end
   if sessionTimer then
    typeName:SetPoint("RIGHT", sessionTimer, "LEFT", -10, 0)
   else
    typeName:SetPoint("RIGHT", dropdown, "LEFT", -8, 0)
   end
   if typeName.SetJustifyH then typeName:SetJustifyH("LEFT") end
  end

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

  MMDPS_UpdateWindowTypeLabelWithSession(w)

  local sessionName = sessionDD and sessionDD.SessionName
  if sessionName then
   if sessionName.SetTextColor then sessionName:SetTextColor(1, 1, 1, 1) end
   if sessionName.SetFont then
    MMDPS_RegisterManagedFontString(sessionName, "sessionName", FONT_FLAGS)
    MMDPS_SetRegionFont(sessionName, GetItemFontSize("sessionName"), FONT_FLAGS)
   end
  end

  if sessionTimer then
   if sessionTimer.SetTextColor then sessionTimer:SetTextColor(1, 1, 1, 1) end
   if sessionTimer.SetFont then
    MMDPS_RegisterManagedFontString(sessionTimer, "sessionTimer", FONT_FLAGS)
    MMDPS_SetRegionFont(sessionTimer, GetItemFontSize("sessionTimer"), FONT_FLAGS)
   end
  end

  MMDPS_ApplyFontsToScrollBox(sb)
  local sourceWindow = w.SourceWindow
  if sourceWindow then
   local sourceSB = sourceWindow.ScrollBox or (sourceWindow.GetScrollBox and sourceWindow:GetScrollBox())
   if sourceSB then
    sourceSB._mmdpsOwnerWindow = sourceWindow
   end
   MMDPS_HookScrollBoxFontRefresh(sourceSB)
   local sourceScrollBar = (sourceWindow.MinimizeContainer and sourceWindow.MinimizeContainer.ScrollBar) or (sourceSB and sourceSB.ScrollBar)
   MMDPS_StyleSessionScrollBar(sourceScrollBar)
   MMDPS_ApplyFontsToScrollBox(sourceSB)
  end
  end)
end

local MMDPS_ApplyNowOrDefer

local function MMDPS_CreateClassIconSizeSlider(parent, anchorFrame)
 local label = parent:CreateFontString(nil, "OVERLAY")
 label:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -14)
 label:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 label:SetText("Class Icon Size:")
 label:SetTextColor(1, 1, 1, 1)

 local valueText = parent:CreateFontString(nil, "OVERLAY")
 valueText:SetPoint("LEFT", label, "RIGHT", 8, 0)
 valueText:SetFont(GUI_FONT_PATH, GUI_FONT_SIZE, GUI_FONT_FLAGS)
 valueText:SetTextColor(0.8, 0.8, 0.8, 1)

 local slider = CreateFrame("Slider", "MattMinimalDPSClassIconSizeSlider", parent, "OptionsSliderTemplate")
 slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
 slider:SetMinMaxValues(8, 24)
 slider:SetValueStep(1)
 slider:SetObeyStepOnDrag(true)
 slider:SetWidth(180)
 slider:SetHeight(16)
 _G[slider:GetName().."Low"]:SetText("8")
 _G[slider:GetName().."High"]:SetText("24")
 _G[slider:GetName().."Text"]:SetText("")

 local uiUpdating = false
 local function Refresh()
  uiUpdating = true
  local iconSize = GetClassIconSize()
  slider:SetValue(iconSize)
  valueText:SetText(tostring(iconSize))
  uiUpdating = false
 end
 slider.RefreshValue = Refresh

 slider:SetScript("OnValueChanged", function(self, value)
  if uiUpdating then return end
  MattMinimalDPSDB = MattMinimalDPSDB or {}
  MattMinimalDPSDB.classIconSize = ClampClassIconSize(value)
  Refresh()
  if MattMinimalDPSDB.useCustomTheme and type(MMDPS_ApplyNowOrDefer) == "function" then
   MMDPS_ApplyNowOrDefer()
  end
 end)

 Refresh()
 return slider
end
local mmdpsDamageMeterWindowHookInstalled = false

local function MMDPS_InstallDamageMeterWindowHook()
 if mmdpsDamageMeterWindowHookInstalled then return end
 if not hooksecurefunc then return end
 local dm = _G.DamageMeter
 if not dm then return end
 if type(dm.SetupSessionWindow) ~= "function" then return end

 hooksecurefunc(dm, "SetupSessionWindow", function()
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme then
   MMDPS_ApplyNowOrDefer()
  end
 end)

 mmdpsDamageMeterWindowHookInstalled = true
end

local function apply()
 MMDPS_InstallDamageMeterWindowHook()
 installEntryFontHook()
 MMDPS_InstallTypeLabelHooks()

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

MMDPS_ApplyNowOrDefer = function()
 if InCombatLockdown and InCombatLockdown() then
  MMDPS.pendingDeferredApply = true
  return false
 end
 apply()
 return true
end

MMDPS.Apply = apply
MMDPS.ApplyNowOrDefer = MMDPS_ApplyNowOrDefer
MMDPS.UpdateAllWindowButtonsMouseover = MMDPS_UpdateAllWindowButtonsMouseover
MMDPS.UpdateAllWindowTypeLabels = MMDPS_UpdateAllWindowTypeLabels
MMDPS.CreateClassIconSizeSlider = MMDPS_CreateClassIconSizeSlider
MMDPS.ShowSettingsFrame = MMDPS_ShowSettingsFrame

