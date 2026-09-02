local MMDPS = MattMinimalDPS or {}
local MMDPS_ShowSettingsFrame = MMDPS.ShowSettingsFrame
local apply = MMDPS.Apply

SLASH_MATTMINIMALDPS1="/mattminimaldps"
SLASH_MATTMINIMALDPS2="/mmdps"
SlashCmdList["MATTMINIMALDPS"]=function()
 if MMDPS_ShowSettingsFrame() then
  apply()
 end
end
