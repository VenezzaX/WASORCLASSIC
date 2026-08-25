local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleClearVision = Utils.toggleClearVision

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Clear Vision", 440, 50, true, S.ClearVision, function(v) toggleClearVision(v); saveConfig() end)
