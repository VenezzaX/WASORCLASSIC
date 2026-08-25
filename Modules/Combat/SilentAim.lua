local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addInfoRowOption = UI.addInfoRowOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Silent Aim", 20, 50, true, S.SilentAim, function(v) S.SilentAim = v; saveConfig() end, function(drawer)
    local warning = addInfoRowOption(drawer, "Status", "BROKEN / CAM GLITCH")
    warning:SetColor(Color3.fromRGB(255, 50, 50))
    addToggleOption(drawer, "Silent Aim Team Check", S.AimbotTeamCheck, function(v) S.AimbotTeamCheck = v; saveConfig() end)
    addSliderOption(drawer, "Silent Aim FOV", 20, 600, S.AimbotFOV, function(v) S.AimbotFOV = v; saveConfig() end)
end, false)
