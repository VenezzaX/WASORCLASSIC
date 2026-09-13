local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Players = Services.Players
local RunService = Services.RunService
local LP = Players.LocalPlayer

local registerModule = UI.registerModule
local saveConfig = VH.Config.saveConfig

local antifling = nil

local function startAntiFling()
    if antifling then
        antifling:Disconnect()
        antifling = nil
    end
    antifling = RunService.Stepped:Connect(function()
        local isFlinging = S.FlingActive or S.FlingAllActive or S.WalkFling
        if isFlinging then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end
    end)
    table.insert(S.Connections, antifling)
end

local function stopAntiFling()
    if antifling then
        antifling:Disconnect()
        antifling = nil
    end
end

VH.startAntiFling = startAntiFling
VH.stopAntiFling = stopAntiFling

registerModule("World", "Anti Fling", 580, 50, true, S.AntiFling, function(v)
    S.AntiFling = v
    if v then
        startAntiFling()
    else
        stopAntiFling()
    end
    saveConfig()
end)

if S.AntiFling then
    startAntiFling()
end
