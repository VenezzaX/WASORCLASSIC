local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Gravity Modifier", 300, 50, true, S.GravityEnabled, function(v) S.GravityEnabled = v; if not v then Workspace.Gravity = 196.2 end; saveConfig() end, function(drawer) addSliderOption(drawer, "Gravity Level", 0, 500, S.CustomGravity, function(v) S.CustomGravity = v; saveConfig() end) end, false)
