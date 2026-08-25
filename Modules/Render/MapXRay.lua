local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleMapXray = Utils.toggleMapXray

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Map X-Ray", 440, 50, true, S.MapXray, function(v) toggleMapXray(v); saveConfig() end)
