local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Lighting = Services.Lighting

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Time of Day Cycle", 440, 50, true, S.TimeCycle, function(v) S.TimeCycle = v; saveConfig() end, function(drawer)
    addSliderOption(drawer, "Time of Day (Hours)", 0, 24, S.TimeOfDay or 14, function(v) S.TimeOfDay = v; Lighting.ClockTime = v; saveConfig() end)
    addToggleOption(drawer, "Auto Cinematic Time Cycle", S.TimeCycle, function(v) S.TimeCycle = v; saveConfig() end)
    addSliderOption(drawer, "Time Cycle speed rate", 1, 10, S.TimeCycleSpeed, function(v) S.TimeCycleSpeed = v; saveConfig() end)
end, false)
