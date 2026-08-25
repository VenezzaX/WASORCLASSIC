local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleFloat = Utils.toggleFloat

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Float Mode", 300, 50, true, S.Float, function(v) toggleFloat(v); saveConfig() end)
