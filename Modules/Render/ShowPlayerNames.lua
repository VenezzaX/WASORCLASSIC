local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Show Player Names", 440, 50, true, S.ESPNames, function(v) S.ESPNames = v; saveConfig() end)
