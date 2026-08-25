local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Camera = Services.Camera

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Blink Teleport", 300, 50, false, false, nil, function(drawer)
    addSliderOption(drawer, "Blink Range (studs)", 5, 150, S.BlinkDistance, function(v) S.BlinkDistance = v; saveConfig() end)
    addDropdownOption(drawer, "Blink Vector Direction", {"Camera Look", "Movement Direction"}, S.BlinkDirection == "Movement Direction" and 2 or 1, function(_, opt) S.BlinkDirection = opt; saveConfig() end)
    addKeybindOption(drawer, "Blink Key Bind", S.BlinkKey, function(k) S.BlinkKey = k; saveConfig() end)
end, false)
