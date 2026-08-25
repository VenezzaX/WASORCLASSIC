local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local RunService = Services.RunService

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local notify = Utils.notify
local registerModule = UI.registerModule
local saveConfig = VH.Config.saveConfig

local originalGravity = 196.2
local swimBeatConn = nil
local swimDiedConn = nil

local function enableAirSwim()
    local char = Utils.getChar()
    local hum = getHum()
    local hrp = getHRP()
    if not char or not hum or not hrp then return end

    originalGravity = Workspace.Gravity > 0 and Workspace.Gravity or 196.2
    Workspace.Gravity = 0

    local enums = Enum.HumanoidStateType:GetEnumItems()
    for _, st in ipairs(enums) do
        if st ~= Enum.HumanoidStateType.None then
            hum:SetStateEnabled(st, false)
        end
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)

    swimDiedConn = hum.Died:Connect(function()
        if S.AirSwim then
            S.AirSwim = false
            local mod = UI.moduleButtons["Air Swim"]
            if mod then mod.SetActive(false) end
        end
        Workspace.Gravity = originalGravity
    end)

    swimBeatConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local currentHrp = getHRP()
            local currentHum = getHum()
            if currentHrp and currentHum then
                local moving = (currentHum.MoveDirection ~= Vector3.zero or UserInputService:IsKeyDown(Enum.KeyCode.Space))
                if not moving then
                    currentHrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    end)

    notify("Air Swim enabled", Color3.fromRGB(50, 195, 75))
end

local function disableAirSwim()
    if swimDiedConn then
        pcall(function() swimDiedConn:Disconnect() end)
        swimDiedConn = nil
    end
    if swimBeatConn then
        pcall(function() swimBeatConn:Disconnect() end)
        swimBeatConn = nil
    end

    Workspace.Gravity = originalGravity > 0 and originalGravity or 196.2

    local hum = getHum()
    if hum then
        local enums = Enum.HumanoidStateType:GetEnumItems()
        for _, st in ipairs(enums) do
            if st ~= Enum.HumanoidStateType.None then
                hum:SetStateEnabled(st, true)
            end
        end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    notify("Air Swim disabled", Color3.fromRGB(218, 170, 42))
end

registerModule("Movement", "Air Swim", 300, 50, true, S.AirSwim, function(v)
    S.AirSwim = v
    if v then
        enableAirSwim()
    else
        disableAirSwim()
    end
    saveConfig()
end, nil, false)
