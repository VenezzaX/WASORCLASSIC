local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("World", "Tool Magnet(Local)", 580, 50, true, S.ToolMagnet, function(v) S.ToolMagnet = v; saveConfig() end)
