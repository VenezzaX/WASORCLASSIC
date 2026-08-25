local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local flyOff = Utils.flyOff

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Fly Bypass", 300, 50, true, S.FlyBypass, function(v) S.FlyBypass = v; if v then S.Fly = false; flyOff(); local mod = moduleButtons["Fly Mode"]; if mod then mod.SetActive(false) end end; saveConfig() end, function(drawer) addSliderOption(drawer, "Bypass Speed factor", 10, 150, S.FlySpeed, function(v) S.FlySpeed = v; saveConfig() end) end, false)
