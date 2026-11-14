local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players or game:GetService("Players")
local RunService = Services.RunService or game:GetService("RunService")
local UserInputService = Services.UserInputService or game:GetService("UserInputService")
local Workspace = Services.Workspace or game:GetService("Workspace")
local LP = Services.LP or Players.LocalPlayer

local moduleButtons = UI.moduleButtons
local flyOff = Utils.flyOff
local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local addToggleOption = UI.addToggleOption
local addDropdownOption = UI.addDropdownOption
local addKeybindOption = UI.addKeybindOption
local saveConfig = VH.Config.saveConfig

if S.FlyBypassVersion == nil then
    S.FlyBypassVersion = "V2"
end
if S.FlyBypassAutoNoclip == nil then
    S.FlyBypassAutoNoclip = true
end
if S.FlyBypassShiftBoost == nil then
    S.FlyBypassShiftBoost = true
end

if VH.FlyBypassCleanup then
    pcall(VH.FlyBypassCleanup)
elseif getgenv and getgenv()._FlyBypassCleanup then
    pcall(getgenv()._FlyBypassCleanup)
elseif _G._FlyBypassCleanup then
    pcall(_G._FlyBypassCleanup)
end

local virtualPos = nil
local animConn = nil
local steppedConn = nil
local heartbeatConn = nil
local renderConn = nil
local charAddedConn = nil
local savedCollisions = setmetatable({}, { __mode = "k" })
local noclipActive = false

local function getCharacterParts()
    local char = LP.Character or (Utils.getChar and Utils.getChar())
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
    return char, hum, hrp
end

local function cleanLegacyMovers(hrp)
    if not hrp then return end
    for _, name in ipairs({ "VoidBypassFly", "VoidBypassBG", "MizuAntiFallBV", "MizuLinearVel", "MizuAlignOri", "MizuFlyAttachment" }) do
        local obj = hrp:FindFirstChild(name)
        if obj then pcall(function() obj:Destroy() end) end
    end
end

local function getFallAnimationIds(char)
    local fallIds = {}
    if not char then return fallIds end
    local animateScript = char:FindFirstChild("Animate")
    if animateScript then
        for _, folderName in ipairs({ "fall", "freefall" }) do
            local folder = animateScript:FindFirstChild(folderName)
            if folder then
                for _, anim in ipairs(folder:GetDescendants()) do
                    if anim:IsA("Animation") and anim.AnimationId ~= "" then
                        fallIds[anim.AnimationId] = true
                    end
                end
            end
        end
    end
    return fallIds
end

local function isFallTrack(track, fallIds)
    if not track then return false end
    local lowerName = (track.Name or ""):lower()
    if lowerName:find("fall") or lowerName:find("freefall") then
        return true
    end
    local anim = track.Animation
    if anim and anim.AnimationId and fallIds[anim.AnimationId] then
        return true
    end
    return false
end

local function stopFallAnimationsNow(char, hum)
    if not (char and hum) then return end
    local fallIds = getFallAnimationIds(char)
    local animator = hum:FindFirstChildOfClass("Animator")
    pcall(function()
        local tracks = animator and animator:GetPlayingAnimationTracks() or hum:GetPlayingAnimationTracks()
        for _, track in ipairs(tracks) do
            if isFallTrack(track, fallIds) then
                track:Stop(0)
            end
        end
    end)
end

local function bindAntiFallAnimation(char, hum)
    if animConn then
        animConn:Disconnect()
        animConn = nil
    end
    if not (char and hum) then return end
    stopFallAnimationsNow(char, hum)
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        local fallIds = getFallAnimationIds(char)
        animConn = animator.AnimationPlayed:Connect(function(track)
            if S.FlyBypass and (S.FlyBypassVersion ~= "V1") and isFallTrack(track, fallIds) then
                track:Stop(0)
            end
        end)
    end
end

local function setHumanoidFlightStates(hum, active)
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, not active)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not active)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not active)
    end)
    if active then
        local currentState = hum:GetState()
        if currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.FallingDown then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
        hum.PlatformStand = true
    else
        hum.PlatformStand = false
    end
end

local function restoreCollisions()
    if not noclipActive then return end
    noclipActive = false
    local char = LP.Character or (Utils.getChar and Utils.getChar())
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                part.CanCollide = false
            elseif savedCollisions[part] ~= nil then
                part.CanCollide = savedCollisions[part]
            else
                local isCore = (
                    part.Name == "Torso"
                    or part.Name == "UpperTorso"
                    or part.Name == "LowerTorso"
                    or part.Name == "Head"
                )
                part.CanCollide = isCore
            end
        end
    end
    savedCollisions = setmetatable({}, { __mode = "k" })
end

local function applyNoclip(char)
    if not char then return end
    noclipActive = true
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if savedCollisions[part] == nil then
                savedCollisions[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end

local function getMoveDirection(hum)
    local Camera = Workspace.CurrentCamera or workspace.CurrentCamera
    if not Camera then return Vector3.zero, Vector3.new(0, 0, -1) end
    local camCF = Camera.CFrame
    local lookVec = camCF.LookVector
    local rightVec = camCF.RightVector

    local moveDir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVec end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVec end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVec end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVec end

    if moveDir.Magnitude == 0 and hum and hum.MoveDirection.Magnitude > 0 then
        local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
        local flatRight = Vector3.new(rightVec.X, 0, rightVec.Z)
        if flatLook.Magnitude > 0.01 and flatRight.Magnitude > 0.01 then
            local fwd = hum.MoveDirection:Dot(flatLook.Unit)
            local side = hum.MoveDirection:Dot(flatRight.Unit)
            moveDir = (lookVec * fwd) + (rightVec * side)
        end
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    if moveDir.Magnitude > 0 then
        return moveDir.Unit, lookVec
    end
    return Vector3.zero, lookVec
end

local function stopFlightV2()
    if steppedConn then steppedConn:Disconnect(); steppedConn = nil end
    if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if charAddedConn then charAddedConn:Disconnect(); charAddedConn = nil end
    if animConn then animConn:Disconnect(); animConn = nil end

    virtualPos = nil
    local char, hum, hrp = getCharacterParts()
    if hrp then
        cleanLegacyMovers(hrp)
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if hum then
        setHumanoidFlightStates(hum, false)
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    restoreCollisions()
end

local function startFlightV2()
    stopFlightV2()
    local char, hum, hrp = getCharacterParts()
    if hrp then
        cleanLegacyMovers(hrp)
        virtualPos = hrp.Position
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if char and hum then
        setHumanoidFlightStates(hum, true)
        bindAntiFallAnimation(char, hum)
    end

    steppedConn = RunService.Stepped:Connect(function()
        if not S.FlyBypass or (S.FlyBypassVersion == "V1") then return end
        local c, h, r = getCharacterParts()
        if not (c and h and r) then return end

        setHumanoidFlightStates(h, true)
        stopFallAnimationsNow(c, h)

        if S.FlyBypassAutoNoclip ~= false then
            applyNoclip(c)
        end

        if not virtualPos then
            virtualPos = r.Position
        end

        pcall(function()
            r.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
            r.AssemblyAngularVelocity = Vector3.zero
        end)

        local cam = Workspace.CurrentCamera or workspace.CurrentCamera
        local lookVec = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        r.CFrame = CFrame.new(virtualPos, virtualPos + lookVec)
    end)
    table.insert(S.Connections, steppedConn)

    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not S.FlyBypass or (S.FlyBypassVersion == "V1") then return end
        local c, h, r = getCharacterParts()
        if not (c and h and r) then return end

        setHumanoidFlightStates(h, true)
        cleanLegacyMovers(r)

        pcall(function()
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end)

        if not virtualPos then
            virtualPos = r.Position
        end

        local activeSpeed = S.FlySpeed or 60
        if (S.FlyBypassShiftBoost ~= false) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            activeSpeed = activeSpeed * 2.0
        end

        local frameDelta = math.min(dt or 0.016, 0.1)
        local moveDir, lookVec = getMoveDirection(h)

        if moveDir.Magnitude > 0 then
            virtualPos = virtualPos + (moveDir * (activeSpeed * frameDelta))
        end

        r.CFrame = CFrame.new(virtualPos, virtualPos + lookVec)
    end)
    table.insert(S.Connections, heartbeatConn)

    renderConn = RunService.RenderStepped:Connect(function()
        if not S.FlyBypass or (S.FlyBypassVersion == "V1") or not virtualPos then return end
        local _, _, r = getCharacterParts()
        if r then
            local cam = Workspace.CurrentCamera or workspace.CurrentCamera
            local lookVec = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
            r.CFrame = CFrame.new(virtualPos, virtualPos + lookVec)
        end
    end)
    table.insert(S.Connections, renderConn)

    charAddedConn = LP.CharacterAdded:Connect(function(newChar)
        virtualPos = nil
        restoreCollisions()
        if animConn then
            animConn:Disconnect()
            animConn = nil
        end
        if S.FlyBypass and (S.FlyBypassVersion ~= "V1") then
            local newHrp = newChar:WaitForChild("HumanoidRootPart", 5) or newChar:WaitForChild("Torso", 5) or newChar.PrimaryPart
            local newHum = newChar:WaitForChild("Humanoid", 5)
            if newHrp then
                virtualPos = newHrp.Position
            end
            if newHum then
                setHumanoidFlightStates(newHum, true)
                bindAntiFallAnimation(newChar, newHum)
            end
        end
    end)
    table.insert(S.Connections, charAddedConn)
end

local function cleanupAll()
    stopFlightV2()
    local char, hum, hrp = getCharacterParts()
    if hum and not S.Fly and not S.AirSwim and not S.HeadSitActive then
        hum.PlatformStand = false
    end
    if hrp then
        cleanLegacyMovers(hrp)
    end
end

VH.FlyBypassCleanup = cleanupAll
if getgenv then
    getgenv()._FlyBypassCleanup = cleanupAll
else
    _G._FlyBypassCleanup = cleanupAll
end

registerModule("Movement", "Fly Bypass", 300, 50, true, S.FlyBypass, function(v)
    S.FlyBypass = v
    if v then
        S.Fly = false
        flyOff()
        local mod = moduleButtons and moduleButtons["Fly Mode"]
        if mod and mod.SetActive then
            mod.SetActive(false)
        end
        if S.FlyBypassVersion ~= "V1" then
            startFlightV2()
        else
            stopFlightV2()
        end
    else
        cleanupAll()
    end
    saveConfig()
end, function(drawer)
    if addKeybindOption then
        addKeybindOption(drawer, "Fly Bypass Key", S.FlyBypassKey or Enum.KeyCode.Unknown, function(k)
            S.FlyBypassKey = k
            saveConfig()
        end)
    end
    if addDropdownOption then
        addDropdownOption(drawer, "Bypass Version", {"V2", "V1"}, (S.FlyBypassVersion == "V1") and 2 or 1, function(_, opt)
            local newVer = (opt == "V1") and "V1" or "V2"
            if S.FlyBypassVersion ~= newVer then
                S.FlyBypassVersion = newVer
                if S.FlyBypass then
                    if newVer == "V2" then
                        startFlightV2()
                    else
                        stopFlightV2()
                        local char, hum, hrp = getCharacterParts()
                        if hum then hum.PlatformStand = true end
                    end
                end
                saveConfig()
            end
        end)
    end
    addSliderOption(drawer, "Bypass Speed factor", 10, 300, S.FlySpeed or 60, function(v)
        S.FlySpeed = v
        saveConfig()
    end)
    if addToggleOption then
        addToggleOption(drawer, "Shift 2x Speed Boost", S.FlyBypassShiftBoost ~= false, function(v)
            S.FlyBypassShiftBoost = v
            saveConfig()
        end)
        addToggleOption(drawer, "Auto Noclip", S.FlyBypassAutoNoclip ~= false, function(v)
            S.FlyBypassAutoNoclip = v
            if not v then restoreCollisions() end
            saveConfig()
        end)
    end
end, false)

if S.FlyBypass and (S.FlyBypassVersion ~= "V1") then
    startFlightV2()
end