local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local enableGhostMode = Utils.enableGhostMode
local disableGhostMode = Utils.disableGhostMode

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Ghost Mode", 300, 50, true, S.GhostMode, function(v) S.GhostMode = v; if v then enableGhostMode() else disableGhostMode() end; saveConfig() end, function(drawer) addToggleOption(drawer, "Teleport to Ghost End", S.GhostTeleportToEnd, function(v) S.GhostTeleportToEnd = v; saveConfig() end) end, false)
