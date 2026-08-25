local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Air Walk Platform", 300, 50, true, S.AirWalk, function(v) S.AirWalk = v; saveConfig() end)
