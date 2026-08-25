local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("World", "Auto-Trigger Prompts", 580, 50, true, S.AutoInteract, function(v) S.AutoInteract = v; saveConfig() end, function(drawer) addSliderOption(drawer, "Trigger Radius (studs)", 5, 50, S.AutoInteractRadius, function(v) S.AutoInteractRadius = v; saveConfig() end) end, false)
