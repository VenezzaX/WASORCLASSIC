local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "ESP Box Outlines", 440, 50, true, S.ESPBoxes, function(v) S.ESPBoxes = v; saveConfig() end, function(drawer)
    addSliderOption(drawer, "Box Transparency (%)", 0, 100, S.ESPTransparency * 100, function(v) S.ESPTransparency = v / 100; saveConfig() end)
    addDropdownOption(drawer, "ESP Scheme Color", {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, table.find({"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, S.ESPColor) or 1, function(_, opt) S.ESPColor = opt; saveConfig() end)
    addDropdownOption(drawer, "ESP Box Style", {"Full", "Corners"}, table.find({"Full", "Corners"}, S.ESPBoxStyle) or 1, function(_, opt) S.ESPBoxStyle = opt; saveConfig() end)
end, false)
