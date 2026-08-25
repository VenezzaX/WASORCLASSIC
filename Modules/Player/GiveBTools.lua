local VH = _G.VoidHub
local Services = VH.Services
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("Player", "Give BTools", 160, 50, false, false, function() for i = 1, 4 do local t = Instance.new("HopperBin"); t.BinType = i; t.Parent = LP.Backpack end; notify("HopperBins building tools granted to inventory!", Color3.fromRGB(50, 195, 75)) end)
