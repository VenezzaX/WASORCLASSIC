local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Wall Run", 300, 50, true, S.WallRun, function(v) S.WallRun = v; saveConfig() end)
