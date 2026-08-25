local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleWaterWalk = Utils.toggleWaterWalk

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Water Walk", 300, 50, true, S.WaterWalk, function(v) toggleWaterWalk(v); saveConfig() end)
