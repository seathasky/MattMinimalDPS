local MMDPS = MattMinimalDPS or {}
local LibStub = MMDPS.LibStub or _G.LibStub
local MMDPS_ShowSettingsFrame = MMDPS.ShowSettingsFrame

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

if LDB and LibDBIcon then
 local minimapLDB = LDB:NewDataObject("MattMinimalDPS", {
  type = "launcher",
  text = "MMDPS",
  icon = "Interface\\AddOns\\MattMinimalDPS\\Images\\mdps.png",
  OnClick = function(self, button)
   if button == "LeftButton" then
    if MattMinimalDPSSettingsFrame then
     if MattMinimalDPSSettingsFrame:IsShown() then
      MattMinimalDPSSettingsFrame:Hide()
     else
      MMDPS_ShowSettingsFrame()
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
 local minimapIconRegistered = false

 local function EnsureMinimapIconSettings()
  MattMinimalDPSDB = type(MattMinimalDPSDB) == "table" and MattMinimalDPSDB or {}
  if type(MattMinimalDPSDB.minimapIcon) ~= "table" then
   MattMinimalDPSDB.minimapIcon = {}
  end
  if MattMinimalDPSDB.minimapIcon.hide == nil then
   MattMinimalDPSDB.minimapIcon.hide = false
  end
  return MattMinimalDPSDB.minimapIcon
 end

 local function RegisterMinimapIconIfNeeded()
  if minimapIconRegistered then return end
  local minimapDB = EnsureMinimapIconSettings()
  if LibDBIcon.IsRegistered and LibDBIcon:IsRegistered("MattMinimalDPS") then
   LibDBIcon:Refresh("MattMinimalDPS", minimapDB)
  else
   LibDBIcon:Register("MattMinimalDPS", minimapLDB, minimapDB)
  end
  minimapIconRegistered = true
 end

 local function ApplyMinimapIconVisibility()
  local minimapDB = EnsureMinimapIconSettings()
  RegisterMinimapIconIfNeeded()
  if minimapDB.hide then
   LibDBIcon:Hide("MattMinimalDPS")
  else
   LibDBIcon:Show("MattMinimalDPS")
  end
 end

 MMDPS.EnsureMinimapIconSettings = EnsureMinimapIconSettings
 MMDPS.ApplyMinimapIconVisibility = ApplyMinimapIconVisibility

 local minimapInitFrame = CreateFrame("Frame")
 minimapInitFrame:RegisterEvent("PLAYER_LOGIN")
 minimapInitFrame:SetScript("OnEvent", function(self, event)
  if event ~= "PLAYER_LOGIN" then return end
  ApplyMinimapIconVisibility()
  C_Timer.After(0, ApplyMinimapIconVisibility)
  self:UnregisterEvent("PLAYER_LOGIN")
  self:SetScript("OnEvent", nil)
 end)
else
 MMDPS.EnsureMinimapIconSettings = function()
  MattMinimalDPSDB = type(MattMinimalDPSDB) == "table" and MattMinimalDPSDB or {}
  MattMinimalDPSDB.minimapIcon = type(MattMinimalDPSDB.minimapIcon) == "table" and MattMinimalDPSDB.minimapIcon or {}
  return MattMinimalDPSDB.minimapIcon
 end
 MMDPS.ApplyMinimapIconVisibility = function() end
end
