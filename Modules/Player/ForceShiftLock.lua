local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local LP = Services.LP

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Force Shift Lock", 160, 50, true, S.ForceShiftLock, function(v) S.ForceShiftLock = v; pcall(function() LP.DevEnableMouseLock = v end); saveConfig() end)
