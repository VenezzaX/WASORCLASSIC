local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Skeleton ESP", 440, 50, true, S.SkeletonESP, function(v) S.SkeletonESP = v; saveConfig() end)
