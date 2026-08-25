local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Kill Aura", 20, 50, true, S.KillAura, function(v) S.KillAura = v; saveConfig() end, function(drawer) addSliderOption(drawer, "Range (studs)", 5, 50, S.KillAuraRange, function(v) S.KillAuraRange = v; saveConfig() end) end, false)
