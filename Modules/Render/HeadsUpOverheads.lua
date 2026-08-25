local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local refreshOverheads = Utils.refreshOverheads

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Heads-Up Overheads", 440, 50, true, S.OverheadInfo, function(v) S.OverheadInfo = v; refreshOverheads(); saveConfig() end)
