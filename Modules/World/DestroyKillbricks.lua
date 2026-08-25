local VH = _G.VoidHub
local Services = VH.Services
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("World", "Destroy Killbricks", 580, 50, false, false, function()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("TouchTransmitter") and v.Parent and not v.Parent:IsDescendantOf(LP.Character) then local parentName = v.Parent.Name:lower(); if parentName:match("kill") or parentName:match("lava") or v.Parent.BrickColor.Name == "Bright red" then v:Destroy(); count = count + 1 end end end
    notify(string.format("Destroyed %d potential killbrick scripts!", count), Color3.fromRGB(50, 195, 75))
end)
