local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local LP = Services.LP

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local notify = Utils.notify
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

local swimBeatConn = nil
local swimDiedConn = nil
local swimCharConn = nil
local swimBodyVelocity = nil

local function cleanupSwimMover()
    if swimBodyVelocity and swimBodyVelocity.Parent then
        pcall(function() swimBodyVelocity:Destroy() end)
    end
    swimBodyVelocity = nil
end

local function stopAirSwim()
    if swimBeatConn then
        pcall(function() swimBeatConn:Disconnect() end)
        swimBeatConn = nil
    end
    if swimDiedConn then
        pcall(function() swimDiedConn:Disconnect() end)
        swimDiedConn = nil
    end
    if swimCharConn then
        pcall(function() swimCharConn:Disconnect() end)
        swimCharConn = nil
    end

    cleanupSwimMover()

    local hum = getHum()
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

local function startAirSwim()
    stopAirSwim()

    local function attachSwim(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 3)
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if not hum or not hrp then return end

        cleanupSwimMover()

        local bv = Instance.new("BodyVelocity")
        bv.Name = "WASOR_AirSwimVelocity"
        bv.MaxForce = Vector3.new(2e5, 2e5, 2e5)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        swimBodyVelocity = bv

        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
        end)

        if swimDiedConn then swimDiedConn:Disconnect() end
        swimDiedConn = hum.Died:Connect(function()
            cleanupSwimMover()
        end)

        if swimBeatConn then swimBeatConn:Disconnect() end
        swimBeatConn = RunService.Heartbeat:Connect(function()
            if not S.AirSwim or not State.uiRunning then
                stopAirSwim()
                return
            end

            local curHum = getHum()
            local curHrp = getHRP()
            local cam = Workspace.CurrentCamera
            if not curHum or not curHrp or curHum.Health <= 0 or not cam then return end

            -- Maintain swimming state
            if curHum:GetState() ~= Enum.HumanoidStateType.Swimming then
                curHum:ChangeState(Enum.HumanoidStateType.Swimming)
            end

            -- Ensure body mover exists on active HRP
            if not swimBodyVelocity or swimBodyVelocity.Parent ~= curHrp then
                cleanupSwimMover()
                local newBv = Instance.new("BodyVelocity")
                newBv.Name = "WASOR_AirSwimVelocity"
                newBv.MaxForce = Vector3.new(2e5, 2e5, 2e5)
                newBv.Velocity = Vector3.zero
                newBv.Parent = curHrp
                swimBodyVelocity = newBv
            end

            local speed = S.AirSwimSpeed or 35
            local moveDir = curHum.MoveDirection
            local isMoving = moveDir.Magnitude > 0.05
            local spacePressed = UserInputService:IsKeyDown(Enum.KeyCode.Space)
            local shiftPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

            local targetVelocity = Vector3.zero

            if S.AirSwimCameraRelative ~= false then
                local camCFrame = cam.CFrame
                local lookVector = camCFrame.LookVector
                local rightVector = camCFrame.RightVector

                local horizDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then horizDir = horizDir + lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then horizDir = horizDir - lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then horizDir = horizDir + rightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then horizDir = horizDir - rightVector end

                if horizDir.Magnitude > 0.05 then
                    targetVelocity = horizDir.Unit * speed
                elseif isMoving then
                    targetVelocity = Vector3.new(moveDir.X * speed, 0, moveDir.Z * speed)
                end
            else
                if isMoving then
                    targetVelocity = Vector3.new(moveDir.X * speed, 0, moveDir.Z * speed)
                end
            end

            -- Vertical ascend / descend
            if spacePressed then
                targetVelocity = Vector3.new(targetVelocity.X, speed, targetVelocity.Z)
            elseif shiftPressed then
                targetVelocity = Vector3.new(targetVelocity.X, -speed, targetVelocity.Z)
            end

            swimBodyVelocity.Velocity = targetVelocity
            curHrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local char = Utils.getChar()
    if char then
        attachSwim(char)
    end

    swimCharConn = LP.CharacterAdded:Connect(function(newChar)
        if S.AirSwim then
            task.wait(0.2)
            attachSwim(newChar)
        end
    end)

    notify("Air Swim enabled", Color3.fromRGB(50, 195, 75))
end

registerModule("Movement", "Air Swim", 300, 50, true, S.AirSwim, function(v)
    S.AirSwim = v
    if v then
        startAirSwim()
    else
        stopAirSwim()
        notify("Air Swim disabled", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    if addSliderOption then
        addSliderOption(drawer, "Swim Speed", 16, 120, S.AirSwimSpeed or 35, function(val)
            S.AirSwimSpeed = val
            saveConfig()
        end)
    end

    addToggleOption(drawer, "Camera Direction (3D Swim)", S.AirSwimCameraRelative ~= false, function(v)
        S.AirSwimCameraRelative = v
        saveConfig()
    end)
end, false)
