local MMDPS = MattMinimalDPS or {}
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, ev, arg1)
 if ev == "ADDON_LOADED" then
  if arg1 ~= MMDPS.addonName then return end
  MMDPS.InitializeSettings()
  return
 end

 MMDPS.EnsureInitialized()
 MMDPS_InstallEditModeSettingsHook()

 if ev == "PLAYER_REGEN_DISABLED" then
  if MattMinimalDPSSettingsFrame and MattMinimalDPSSettingsFrame:IsShown() then
   MattMinimalDPSSettingsFrame:Hide()
   print("|cff66ccffMMDPS|r Settings closed while in combat.")
  end
  return
 end

 if ev == "PLAYER_REGEN_ENABLED" and MMDPS.pendingDeferredApply then
  MMDPS.pendingDeferredApply = false
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and MMDPS.Apply then
   MMDPS.Apply()
  end
 end
 if ev == "PLAYER_REGEN_ENABLED" and MMDPS.pendingMouseoverRefreshAfterCombat then
  MMDPS.pendingMouseoverRefreshAfterCombat = false
  if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and MMDPS.Apply then
   MMDPS.Apply()
  end
 end
 if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and MMDPS.ApplyNowOrDefer then
  MMDPS.ApplyNowOrDefer()
 end
 if not self._retry and C_Timer and C_Timer.NewTicker then
  self._retry = C_Timer.NewTicker(1, function()
   if MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme and MMDPS.ApplyNowOrDefer then
    MMDPS.ApplyNowOrDefer()
   end
  end, 8)
 end

 if not self._resetEventsHooked then
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("CHALLENGE_MODE_START")
  self._resetEventsHooked = true
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
