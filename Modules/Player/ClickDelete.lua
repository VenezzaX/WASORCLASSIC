local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Click-Delete", 160, 50, true, S.ClickDelete, function(v) S.ClickDelete = v; saveConfig() end)
