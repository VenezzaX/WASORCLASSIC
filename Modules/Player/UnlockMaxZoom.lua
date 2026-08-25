local VH = _G.VoidHub
local Services = VH.Services
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local Camera = Services.Camera

local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("Player", "Unlock Max Zoom", 160, 50, false, false, function() LP.CameraMaxZoomDistance = 100000; notify("Camera zoom limits unlocked infinitely!", Color3.fromRGB(50, 195, 75)) end)
