local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Show Distance Text", 440, 50, true, S.ESPDistances, function(v) S.ESPDistances = v; saveConfig() end)
