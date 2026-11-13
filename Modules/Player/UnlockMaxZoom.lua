local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local notify = Utils.notify
local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("Player", "Unlock Max Zoom", 160, 50, true, S.CameraMaxZoomEnabled, function(v)
    S.CameraMaxZoomEnabled = v
    if v then
        State.originalMaxZoom = LP.CameraMaxZoomDistance or 128
        LP.CameraMaxZoomDistance = S.CameraMaxZoom or 100000
        notify("Camera zoom unlocked!", Color3.fromRGB(50, 195, 75))
    else
        LP.CameraMaxZoomDistance = State.originalMaxZoom or 128
        notify("Camera zoom set to normal.", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Max Zoom Distance", 128, 100000, S.CameraMaxZoom or 100000, function(v)
        S.CameraMaxZoom = v
        if S.CameraMaxZoomEnabled then
            LP.CameraMaxZoomDistance = v
        end
        saveConfig()
    end, 100000)
end, false)
