local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Auto-Rejoin", 160, 50, true, S.AutoRejoin, function(v) S.AutoRejoin = v; saveConfig() end)
