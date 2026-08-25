local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Triggerbot", 20, 50, true, S.TriggerbotActive, function(v) S.TriggerbotActive = v; notify("Triggerbot " .. (v and "Enabled" or "Disabled"), Color3.fromRGB(50, 195, 75)); saveConfig() end, function(drawer)
    addToggleOption(drawer, "Triggerbot Team Check", S.TriggerbotTeamCheck, function(v) S.TriggerbotTeamCheck = v; saveConfig() end)
    addToggleOption(drawer, "Triggerbot Ignore Friends", S.TriggerbotIgnoreFriends, function(v) S.TriggerbotIgnoreFriends = v; saveConfig() end)
    addSliderOption(drawer, "Triggerbot Delay (ms)", 0, 500, math.round((S.TriggerbotDelay or 0.05) * 1000), function(v) S.TriggerbotDelay = v / 1000; saveConfig() end)
end, false)
