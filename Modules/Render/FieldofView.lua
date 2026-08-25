local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Camera = Services.Camera

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Field of View", 440, 50, false, false, nil, function(drawer)
    addSliderOption(drawer, "Camera FOV", 10, 120, S.CameraFOV, function(v) S.CameraFOV = v; local c = Workspace.CurrentCamera; if c then c.FieldOfView = v end; saveConfig() end)
    addSliderOption(drawer, "ViewModel FOV (1st Person)", 10, 120, S.ViewModelFOV, function(v) S.ViewModelFOV = v; saveConfig() end)
end, false)
