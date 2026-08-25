local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("World", "Auto-Jump Edges", 580, 50, true, S.AutoJump, function(v) S.AutoJump = v; saveConfig() end)
