local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Distance Based ESP", 440, 50, true, S.ESPDistanceColor, function(v) S.ESPDistanceColor = v; saveConfig() end)
