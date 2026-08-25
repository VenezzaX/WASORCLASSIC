local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("World", "Anti Void", 580, 50, true, S.AntiVoid, function(v) S.AntiVoid = v; saveConfig() end, function(drawer) addSliderOption(drawer, "Anti-Void Height Y Offset", -2000, -100, S.AntiVoidY, function(v) S.AntiVoidY = v; saveConfig() end) end, false)
