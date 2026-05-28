local MMDPS = MattMinimalDPS or {}
local GUI_FONT_PATH = MMDPS.GUI_FONT_PATH
local GUI_FONT_FLAGS = MMDPS.GUI_FONT_FLAGS

local function HideVisualRegion(region)
 if region and region.Hide then region:Hide() end
 if region and region.SetAlpha then region:SetAlpha(0) end
end

local function HideFrameTextures(frame, except)
 if not frame then return end
 local exceptMap = type(except) == "table" and except or nil
 if frame.GetRegions then
  for _, region in ipairs({frame:GetRegions()}) do
   if region ~= except and (not exceptMap or not exceptMap[region]) and region.GetObjectType and region:GetObjectType() == "Texture" then
    HideVisualRegion(region)
   end
  end
 end
 if frame.GetChildren then
  for _, child in ipairs({frame:GetChildren()}) do
   HideFrameTextures(child, except)
  end
 end
end

local function StyleOpenDropdownLists()
 for i = 1, 2 do
 local list = _G["DropDownList"..i]
  if list and list:IsShown() then
   local preserve = {}
   if list._mmdpsBg then preserve[list._mmdpsBg] = true end
   if list._mmdpsBorder then preserve[list._mmdpsBorder] = true end
   HideFrameTextures(list, preserve)
   if not list._mmdpsBg then
    local bg = list:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -12)
    bg:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -12, 12)
    bg:SetColorTexture(0.015, 0.015, 0.018, 0.95)
    list._mmdpsBg = bg
    local border = list:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", bg, "TOPLEFT")
    border:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    border:SetColorTexture(1, 1, 1, 0.12)
    list._mmdpsBorder = border
   end
  end
 end
end

local function CreateChevron(button, direction, r, g, b)
 local line = button:CreateLine(nil, "OVERLAY")
 line:SetThickness(1.5)
 line:SetColorTexture(r, g, b, 1)
 local line2 = button:CreateLine(nil, "OVERLAY")
 line2:SetThickness(1.5)
 line2:SetColorTexture(r, g, b, 1)
 if direction == "up" then
  line:SetStartPoint("BOTTOMLEFT", button, 5, 4)
  line:SetEndPoint("TOP", button, 0, -4)
  line2:SetStartPoint("BOTTOMRIGHT", button, -5, 4)
  line2:SetEndPoint("TOP", button, 0, -4)
 else
  line:SetStartPoint("TOPLEFT", button, 5, -4)
  line:SetEndPoint("BOTTOM", button, 0, 4)
  line2:SetStartPoint("TOPRIGHT", button, -5, -4)
  line2:SetEndPoint("BOTTOM", button, 0, 4)
 end
 button._mmdpsArrow = line
 button._mmdpsArrow2 = line2
end

function MMDPS.StyleMinimalScrollFrame(scrollFrame)
 if not scrollFrame then return end
 local scrollBar = scrollFrame.ScrollBar or (scrollFrame.GetName and _G[scrollFrame:GetName().."ScrollBar"])
 if not scrollBar then return end
 if scrollBar.SetWidth then scrollBar:SetWidth(6) end
 if scrollBar.SetAlpha then scrollBar:SetAlpha(0.85) end

 local thumb = (scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()) or scrollBar.ThumbTexture or (scrollBar.Track and scrollBar.Track.Thumb)
 HideFrameTextures(scrollBar, thumb)
 for _, button in ipairs({scrollBar.ScrollUpButton, scrollBar.ScrollDownButton, scrollBar.UpButton, scrollBar.DownButton, scrollBar.Backward, scrollBar.Forward}) do
  HideVisualRegion(button)
  if button and button.EnableMouse then button:EnableMouse(false) end
 end

 if not scrollFrame._mmdpsScrollTrack then
  local track = scrollFrame:CreateTexture(nil, "BACKGROUND")
  track:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 10, -2)
  track:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 10, 2)
  track:SetWidth(2)
  track:SetColorTexture(1, 1, 1, 0.08)
  scrollFrame._mmdpsScrollTrack = track
 end
 if thumb then
  if thumb.SetTexture then thumb:SetTexture("Interface\\Buttons\\WHITE8X8") end
  if thumb.SetVertexColor then thumb:SetVertexColor(0.75, 0.75, 0.75, 0.85) end
  if thumb.SetWidth then thumb:SetWidth(4) end
 end

 if not scrollFrame._mmdpsScrollUp then
  local function StepScroll(delta)
   local offset = scrollFrame:GetVerticalScroll() + delta
   local minOffset, maxOffset = 0, 0
   if scrollBar.GetMinMaxValues then minOffset, maxOffset = scrollBar:GetMinMaxValues() end
   if offset < minOffset then offset = minOffset end
   if offset > maxOffset then offset = maxOffset end
   scrollFrame:SetVerticalScroll(offset)
  end
  local up = CreateFrame("Button", nil, scrollFrame)
  up:SetSize(16, 14)
  up:SetPoint("BOTTOM", scrollFrame, "TOPRIGHT", 10, -1)
  CreateChevron(up, "up", 0.9, 0.9, 0.9)
  up:SetScript("OnClick", function() StepScroll(-32) end)
  local down = CreateFrame("Button", nil, scrollFrame)
  down:SetSize(16, 14)
  down:SetPoint("TOP", scrollFrame, "BOTTOMRIGHT", 10, 1)
  CreateChevron(down, "down", 0.9, 0.9, 0.9)
  down:SetScript("OnClick", function() StepScroll(32) end)
  scrollFrame._mmdpsScrollUp = up
  scrollFrame._mmdpsScrollDown = down
 end
end

function MMDPS.UpdateMinimalScrollFrameVisibility(scrollFrame)
 if not scrollFrame then return end
 local scrollBar = scrollFrame.ScrollBar or (scrollFrame.GetName and _G[scrollFrame:GetName().."ScrollBar"])
 local content = scrollFrame.GetScrollChild and scrollFrame:GetScrollChild()
 local viewHeight = scrollFrame.GetHeight and scrollFrame:GetHeight() or 0
 local contentHeight = content and content.GetHeight and content:GetHeight() or 0
 local needsScroll = contentHeight > (viewHeight + 1)

 if not needsScroll then
  if scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
  if scrollBar and scrollBar.SetValue then scrollBar:SetValue(0) end
 end

 if scrollBar then
  if scrollBar.SetAlpha then scrollBar:SetAlpha(needsScroll and 0.85 or 0) end
  if scrollBar.EnableMouse then scrollBar:EnableMouse(needsScroll) end
  if needsScroll and scrollBar.Show then scrollBar:Show() end
 end
 if scrollFrame._mmdpsScrollTrack then scrollFrame._mmdpsScrollTrack:SetShown(needsScroll) end
 if scrollFrame._mmdpsScrollUp then scrollFrame._mmdpsScrollUp:SetShown(needsScroll) end
 if scrollFrame._mmdpsScrollDown then scrollFrame._mmdpsScrollDown:SetShown(needsScroll) end
end

function MMDPS.StyleMinimalSlider(slider)
 if not slider then return end
 local sliderName = slider.GetName and slider:GetName()
 local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
 if sliderName then
  for _, region in ipairs({_G[sliderName.."Left"], _G[sliderName.."Middle"], _G[sliderName.."Right"], _G[sliderName.."Background"]}) do
   HideVisualRegion(region)
  end
 end
 local preserve = {}
 if thumb then preserve[thumb] = true end
 if slider._mmdpsTrack then preserve[slider._mmdpsTrack] = true end
 HideFrameTextures(slider, preserve)
 if not slider._mmdpsTrack then
  local track = slider:CreateTexture(nil, "OVERLAY")
  track:SetPoint("LEFT", slider, "LEFT", 0, 0)
  track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
  track:SetHeight(3)
  track:SetColorTexture(1, 1, 1, 0.16)
  slider._mmdpsTrack = track
 end
 if slider._mmdpsTrack then
  slider._mmdpsTrack:Show()
  if slider._mmdpsTrack.SetAlpha then slider._mmdpsTrack:SetAlpha(1) end
 end
 if thumb then
  thumb:Show()
  if thumb.SetAlpha then thumb:SetAlpha(1) end
  if thumb.SetTexture then thumb:SetTexture("Interface\\Buttons\\WHITE8X8") end
  if thumb.SetVertexColor then thumb:SetVertexColor(0.8, 0.8, 0.8, 1) end
  if thumb.SetSize then thumb:SetSize(8, 14) end
 end
 if sliderName then
  local lowText = _G[sliderName.."Low"]
  local highText = _G[sliderName.."High"]
  if lowText then
   lowText:ClearAllPoints()
   lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 2)
  end
  if highText then
   highText:ClearAllPoints()
   highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 2)
  end
 end
end

function MMDPS.StyleMinimalDropdown(dropdown, width)
 if not dropdown then return end
 local dropdownName = dropdown.GetName and dropdown:GetName()
 if dropdownName then
  for _, region in ipairs({_G[dropdownName.."Left"], _G[dropdownName.."Middle"], _G[dropdownName.."Right"], _G[dropdownName.."ButtonNormalTexture"], _G[dropdownName.."ButtonPushedTexture"], _G[dropdownName.."ButtonDisabledTexture"], _G[dropdownName.."ButtonHighlightTexture"]}) do
   HideVisualRegion(region)
  end
 end
 local preserve = {}
 if dropdown._mmdpsBg then preserve[dropdown._mmdpsBg] = true end
 HideFrameTextures(dropdown, preserve)
 if not dropdown._mmdpsBg then
  local bg = dropdown:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("LEFT", dropdown, "LEFT", 16, 2)
  bg:SetSize(width or 190, 22)
  bg:SetColorTexture(0.03, 0.03, 0.035, 0.92)
  dropdown._mmdpsBg = bg
 end
 dropdown._mmdpsBg:SetSize(width or 190, 22)
 dropdown._mmdpsBg:Show()
 if dropdown._mmdpsBg.SetAlpha then dropdown._mmdpsBg:SetAlpha(1) end
 local button = dropdown.Button
 if button then
  if button.SetSize then button:SetSize(22, 22) end
  button:ClearAllPoints()
  button:SetPoint("LEFT", dropdown, "LEFT", (width or 190) - 4, 1)
  HideFrameTextures(button)
  if not button._mmdpsArrow then CreateChevron(button, "down", 0.92, 0.92, 0.92) end
  if button.HookScript and not button._mmdpsDropdownListHooked then
   button:HookScript("OnClick", function()
    if C_Timer then C_Timer.After(0, StyleOpenDropdownLists) end
   end)
   button._mmdpsDropdownListHooked = true
  end
 end
 local text = dropdown.Text
 if text then
  text:ClearAllPoints()
  text:SetPoint("LEFT", dropdown, "LEFT", 24, 1)
  text:SetPoint("RIGHT", dropdown, "LEFT", (width or 190) - 14, 1)
  text:SetJustifyH("RIGHT")
  text:SetTextColor(1, 1, 1, 1)
 end
end

MMDPS.StyleOpenDropdownLists = StyleOpenDropdownLists

function MMDPS.StyleMinimalButton(button)
 if not button then return end
 HideFrameTextures(button)
 if not button._mmdpsBg then
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.035, 0.035, 0.04, 0.92)
  button._mmdpsBg = bg
  local border = button:CreateTexture(nil, "BORDER")
  border:SetAllPoints()
  border:SetColorTexture(1, 1, 1, 0.14)
  button._mmdpsBorder = border
 end
 button._mmdpsBg:Show()
 if button._mmdpsBg.SetAlpha then button._mmdpsBg:SetAlpha(1) end
 if button.SetNormalFontObject then button:SetNormalFontObject(GameFontNormalSmall) end
 if button.SetHighlightFontObject then button:SetHighlightFontObject(GameFontHighlightSmall) end
 if button.SetTextColor then button:SetTextColor(1, 1, 1, 1) end
 if button.HookScript and not button._mmdpsMinimalHoverHooked then
  button:HookScript("OnEnter", function(self)
   if self._mmdpsBg then self._mmdpsBg:SetColorTexture(0.07, 0.07, 0.08, 0.95) end
  end)
  button:HookScript("OnLeave", function(self)
   if self._mmdpsBg then self._mmdpsBg:SetColorTexture(0.035, 0.035, 0.04, 0.92) end
  end)
  button._mmdpsMinimalHoverHooked = true
 end
end
