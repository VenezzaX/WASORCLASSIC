local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Noclip", 300, 50, true, S.NoClip, function(v) S.NoClip = v; saveConfig() end)
