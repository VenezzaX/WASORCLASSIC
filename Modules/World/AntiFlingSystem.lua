local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Players = Services.Players
local RunService = Services.RunService
local LP = Players.LocalPlayer

local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local addToggleOption = UI.addToggleOption
local saveConfig = VH.Config.saveConfig

local antifling = nil

local function startAntiFling()
    if antifling then
        antifling:Disconnect()
        antifling = nil
    end
    antifling = RunService.Stepped:Connect(function()
        if not S.AntiFling then return end
        local isFlinging = S.FlingActive or S.FlingAllActive or S.WalkFling
        if isFlinging then return end

        local myChar = LP.Character
        local myHRP = myChar and (myChar.PrimaryPart or myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
        if not myChar or not myHRP then return end

        local myPos = myHRP.Position
        local maxDist = S.AntiFlingDistance or 35

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local char = player.Character
                local hrp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if hrp then
                    local dist = (hrp.Position - myPos).Magnitude
                    if dist <= maxDist then
                        for _, child in ipairs(char:GetChildren()) do
                            if child:IsA("BasePart") then
                                child.CanCollide = false
                                child.AssemblyLinearVelocity = Vector3.zero
                                child.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end
                end
            end
        end

        if S.AntiFlingAbsorb ~= false then
            local vel = myHRP.AssemblyLinearVelocity
            local angVel = myHRP.AssemblyAngularVelocity
            local isMovingFast = S.Fly or S.FlyBypass or (S.ForceWalkSpeed and S.WalkSpeed and S.WalkSpeed > 100)
            if not isMovingFast and (vel.Magnitude > 250 or angVel.Magnitude > 250) then
                myHRP.AssemblyLinearVelocity = Vector3.new(0, math.clamp(vel.Y, -50, 50), 0)
                myHRP.AssemblyAngularVelocity = Vector3.zero
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
end, function(drawer)
    addSliderOption(drawer, "Detection Range (studs)", 15, 100, S.AntiFlingDistance or 35, function(v)
        S.AntiFlingDistance = v
        saveConfig()
    end)
    addToggleOption(drawer, "Absorb Fling Momentum", S.AntiFlingAbsorb ~= false, function(v)
        S.AntiFlingAbsorb = v
        saveConfig()
    end)
end, false)

if S.AntiFling then
    startAntiFling()
end
