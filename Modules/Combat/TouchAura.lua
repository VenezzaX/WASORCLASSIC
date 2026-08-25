local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Touch Aura", 20, 50, true, S.TouchAura, function(v) S.TouchAura = v; saveConfig() end, function(drawer) addSliderOption(drawer, "Range (studs)", 5, 30, 15, function(v) S.KillAuraRange = v; saveConfig() end) end, false)
