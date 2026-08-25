local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Instant Respawn", 160, 50, true, S.InstantRespawn, function(v) S.InstantRespawn = v; saveConfig() end)
