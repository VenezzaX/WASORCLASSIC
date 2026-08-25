local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Aimbot", 20, 50, true, S.AimbotActive, function(v) S.AimbotActive = v; notify("Aimbot " .. (v and "Enabled" or "Disabled"), Color3.fromRGB(50, 195, 75)); saveConfig() end, function(drawer)
    addToggleOption(drawer, "Aimbot Team Check", S.AimbotTeamCheck, function(v) S.AimbotTeamCheck = v; saveConfig() end)
    addToggleOption(drawer, "Aimbot Ignore Friends", S.AimbotIgnoreFriends, function(v) S.AimbotIgnoreFriends = v; saveConfig() end)
    addToggleOption(drawer, "Draw FOV Circle", S.AimbotShowFOV, function(v) S.AimbotShowFOV = v; saveConfig() end)
    addSliderOption(drawer, "FOV Circle Radius", 20, 600, S.AimbotFOV, function(v) S.AimbotFOV = v; saveConfig() end)
    addSliderOption(drawer, "Aimbot Smoothness", 1, 30, S.AimbotSmooth, function(v) S.AimbotSmooth = v; saveConfig() end)
    addToggleOption(drawer, "Wall Visibility Check", S.AimbotVisibility, function(v) S.AimbotVisibility = v; saveConfig() end)
    addDropdownOption(drawer, "Locked Target Part", {"Head", "Torso", "Random"}, table.find({"Head", "Torso", "Random"}, S.AimbotPart) or 1, function(_, opt) S.AimbotPart = opt; saveConfig() end)
    addDropdownOption(drawer, "Aimbot Hold Mode", {"M2", "Keyboard"}, S.AimbotHoldMode == "Keyboard" and 2 or 1, function(_, opt) S.AimbotHoldMode = opt; saveConfig() end)
    addKeybindOption(drawer, "Aimbot Hold Key", S.AimbotHoldKey, function(k) S.AimbotHoldKey = k; saveConfig() end)
end, false)
