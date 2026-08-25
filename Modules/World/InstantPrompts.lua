local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("World", "Instant Prompts", 580, 50, true, S.InstantPrompts, function(v) S.InstantPrompts = v; if v then for _, p in ipairs(Workspace:GetDescendants()) do if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end end end; saveConfig() end)
