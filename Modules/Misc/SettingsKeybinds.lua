local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local setupAutoReinject = Utils.setupAutoReinject

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

registerModule("Misc", "Settings & Keybinds", 720, 50, false, false, nil, function(drawer)
    addToggleOption(drawer, "Auto-Reinject", S.AutoReinject, function(v) S.AutoReinject = v; saveConfig(); setupAutoReinject() end)
    addToggleOption(drawer, "Join/Leave Toasts", S.JoinLeaveToasts, function(v) S.JoinLeaveToasts = v; saveConfig() end)
    addKeybindOption(drawer, "Fly Bind", S.FlyKey, function(k) S.FlyKey = k; saveConfig() end)
    addKeybindOption(drawer, "NoClip Bind", S.NoClipKey, function(k) S.NoClipKey = k; saveConfig() end)
    addKeybindOption(drawer, "Bunnyhop Bind", S.BHopKey, function(k) S.BHopKey = k; saveConfig() end)
    addKeybindOption(drawer, "InfJump Bind", S.InfJumpKey, function(k) S.InfJumpKey = k; saveConfig() end)
    addKeybindOption(drawer, "Ghost Bind", S.GhostKey, function(k) S.GhostKey = k; saveConfig() end)
    addKeybindOption(drawer, "Blink Bind", S.BlinkKey, function(k) S.BlinkKey = k; saveConfig() end)
    addKeybindOption(drawer, "JumpStrength Bind", S.JumpStrengthKey, function(k) S.JumpStrengthKey = k; saveConfig() end)
end, false)
