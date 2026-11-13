local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local flyOn = Utils.flyOn
local flyOff = Utils.flyOff

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Fly Mode", 300, 50, true, S.Fly, function(v)
    S.Fly = v
    if v then
        if S.FlyBypass then
            S.FlyBypass = false
            local mod = moduleButtons and moduleButtons["Fly Bypass"]
            if mod and mod.SetActive then mod.SetActive(false) end
        end
        flyOn()
    else
        flyOff()
    end
    saveConfig()
end, function(drawer) addSliderOption(drawer, "Fly Speed factor", 10, 300, S.FlySpeed, function(v) S.FlySpeed = v; saveConfig() end) end, false)