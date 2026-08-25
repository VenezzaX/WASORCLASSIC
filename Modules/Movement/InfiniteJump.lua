local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Infinite Jump", 300, 50, true, S.InfJump, function(v) S.InfJump = v; saveConfig() end)
