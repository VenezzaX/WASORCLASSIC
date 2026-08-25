local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHum = Utils.getHum
local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Sprint Speed Boost", 300, 50, true, S.SprintEnabled, function(v) S.SprintEnabled = v; if not v then local hum = getHum(); if hum then hum.WalkSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or (State.gameDefaultSpeed or hum.WalkSpeed or 16) end end; saveConfig() end, function(drawer) addSliderOption(drawer, "Sprint Speed factor", 20, 150, S.SprintSpeed, function(v) S.SprintSpeed = v; saveConfig() end) end, false)
