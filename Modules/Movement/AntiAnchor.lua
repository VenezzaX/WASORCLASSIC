local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Anti-Anchor", 300, 50, true, S.AntiAnchor, function(v) S.AntiAnchor = v; saveConfig() end)
