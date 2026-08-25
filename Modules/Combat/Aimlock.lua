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

registerModule("Combat", "Aimlock", 20, 50, true, S.AimlockActive, function(v) S.AimlockActive = v; notify("Aimlock " .. (v and "Enabled" or "Disabled"), Color3.fromRGB(50, 195, 75)); saveConfig() end, function(drawer)
    addSliderOption(drawer, "Aimlock Smoothness", 1, 10, S.AimlockSmooth, function(v) S.AimlockSmooth = v; saveConfig() end)
    addToggleOption(drawer, "Aimlock Team Check", S.AimbotTeamCheck, function(v) S.AimbotTeamCheck = v; saveConfig() end)
    addToggleOption(drawer, "Aimlock Ignore Friends", S.AimbotIgnoreFriends, function(v) S.AimbotIgnoreFriends = v; saveConfig() end)
end, false)
