local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHum = Utils.getHum
local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Climb", 300, 50, true, S.Climb, function(v) S.Climb = v; if not v then local hum = getHum(); if hum then hum.PlatformStand = false end end; saveConfig() end, function(drawer) addSliderOption(drawer, "Climb Speed", 5, 50, S.ClimbSpeed, function(v) S.ClimbSpeed = v; saveConfig() end) end, false)
