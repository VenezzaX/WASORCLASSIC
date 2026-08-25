local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Player Spin", 300, 50, true, S.Spin, function(v) S.Spin = v; saveConfig() end, function(drawer) addSliderOption(drawer, "Spin Speed", 1, 100, S.SpinSpeed, function(v) S.SpinSpeed = v; saveConfig() end) end, false)
