local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Show Health Text", 440, 50, true, S.ESPHealth, function(v) S.ESPHealth = v; saveConfig() end)
