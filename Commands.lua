local MMDPS = MattMinimalDPS or {}
local NormalizeMediaName = MMDPS.NormalizeMediaName
local MMDPS_GetGlobalFontName = MMDPS.GetGlobalFontName
local MMDPS_GetGlobalFontPathByName = MMDPS.GetGlobalFontPathByName
local MMDPS_DebugDumpEntryFonts = MMDPS.DebugDumpEntryFonts
local MMDPS_ShowSettingsFrame = MMDPS.ShowSettingsFrame
local apply = MMDPS.Apply

SLASH_MATTMINIMALDPS1="/mattminimaldps"
SLASH_MATTMINIMALDPS2="/mmdps"
SlashCmdList["MATTMINIMALDPS"]=function(msg)
 local cmd = NormalizeMediaName(msg)
 if cmd and cmd:lower() == "fontdebug" then
  local selected = MMDPS_GetGlobalFontName()
  local path, matched, resolved = MMDPS_GetGlobalFontPathByName(selected)
  print(string.format("|cff66ccffMMDPS|r selected=%q resolved=%q matched=%s path=%q savedPath=%q savedName=%q theme=%s", tostring(selected), tostring(resolved), tostring(matched), tostring(path), tostring(MattMinimalDPSDB and MattMinimalDPSDB.globalFontPath), tostring(MattMinimalDPSDB and MattMinimalDPSDB.globalFontPathName), tostring(MattMinimalDPSDB and MattMinimalDPSDB.useCustomTheme)))
  return
 end
 if cmd and cmd:lower() == "fontrows" then
  MMDPS_DebugDumpEntryFonts()
  return
 end
 if MMDPS_ShowSettingsFrame() then
  apply()
 end
end
