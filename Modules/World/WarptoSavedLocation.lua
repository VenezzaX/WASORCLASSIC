local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHRP = Utils.getHRP
local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("World", "Warp to Saved Location", 580, 50, false, false, function() if S.SavedWaypointCF then local hrp = getHRP(); if hrp then hrp.CFrame = S.SavedWaypointCF; notify("Returned to saved waypoint!", Color3.fromRGB(50, 195, 75)) else notify("HumanoidRootPart not found", Color3.fromRGB(218, 38, 38)) end else notify("No waypoint saved yet", Color3.fromRGB(218, 38, 38)) end end)
