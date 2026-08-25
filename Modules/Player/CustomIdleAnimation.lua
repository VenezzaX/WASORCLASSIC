local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local applyCustomIdle = Utils.applyCustomIdle
local animPresets = State.animPresets

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

local addTextboxOption = UI.addTextboxOption
local addButtonOption = UI.addButtonOption

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Custom Idle Animation", 160, 50, true, S.CustomIdleAnim, function(v) S.CustomIdleAnim = v; if LP.Character then applyCustomIdle(LP.Character) end; saveConfig() end, function(drawer)
    addTextboxOption(drawer, "Animation ID", "rbxassetid://507766666", function(txt) S.CustomIdleID = txt; if S.CustomIdleAnim and LP.Character then applyCustomIdle(LP.Character) end; saveConfig() end)
    addButtonOption(drawer, "Load Random Preset", function() S.CustomIdleID = animPresets[math.random(1, #animPresets)]; if S.CustomIdleAnim and LP.Character then applyCustomIdle(LP.Character) end; saveConfig(); notify("Loaded random animation preset!", Color3.fromRGB(50, 195, 75)) end)
end, false)
