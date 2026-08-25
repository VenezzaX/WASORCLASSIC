local VH = _G.VoidHub
local Services = VH.Services
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("World", "Destroy Seats", 580, 50, false, false, function()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do if (v:IsA("Seat") or v:IsA("VehicleSeat")) and not v:IsDescendantOf(LP.Character) then pcall(function() v:Destroy(); count = count + 1 end) end end
    notify(string.format("Destroyed %d seats client-side!", count), Color3.fromRGB(50, 195, 75))
end)
