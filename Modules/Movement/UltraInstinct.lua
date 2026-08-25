local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP
local Workspace = Services.Workspace

local getChar = Utils.getChar
local getHRP = Utils.getHRP
local notify = Utils.notify
local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption
local addToggleOption = UI.addToggleOption

local saveConfig = VH.Config.saveConfig

local ultraInstinctConn = nil
local lastDodge = 0

local function startUltraInstinct()
    if ultraInstinctConn then return end

    ultraInstinctConn = Services.RunService.Heartbeat:Connect(function()
        if not S.UltraInstinct or not State.uiRunning then
            if ultraInstinctConn then
                ultraInstinctConn:Disconnect()
                ultraInstinctConn = nil
            end
            if State.UI_CirclePart then
                pcall(function() State.UI_CirclePart:Destroy() end)
                State.UI_CirclePart = nil
            end
            return
        end

        local myChar = getChar()
        local myHRP = getHRP()
        if not myChar or not myHRP then
            if State.UI_CirclePart then
                State.UI_CirclePart.Transparency = 1
            end
            return
        end

        local radius = S.UltraInstinctRadius or 12
        if not State.UI_CirclePart or not State.UI_CirclePart.Parent then
            pcall(function()
                local p = Instance.new("Part")
                p.Name = "UltraInstinctCircle"
                p.Shape = Enum.PartType.Cylinder
                p.Material = Enum.Material.Neon
                p.Color = Color3.fromRGB(255, 0, 0)
                p.Transparency = 0.85
                p.CanCollide = false
                p.Anchored = true
                p.Parent = Workspace
                State.UI_CirclePart = p
            end)
        end

        if State.UI_CirclePart then
            local groundY = myHRP.Position.Y - 3.2
            pcall(function()
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {myChar, State.UI_CirclePart}
                local rayResult = Workspace:Raycast(myHRP.Position, Vector3.new(0, -15, 0), rayParams)
                if rayResult then
                    groundY = rayResult.Position.Y
                end
            end)
            pcall(function()
                State.UI_CirclePart.Size = Vector3.new(0.05, radius * 2, radius * 2)
                State.UI_CirclePart.CFrame = CFrame.new(myHRP.Position.X, groundY + 0.05, myHRP.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
                State.UI_CirclePart.Transparency = 0.85
            end)
        end

        local now = tick()
        if now - lastDodge > 0.15 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    if S.UltraInstinctTeamCheck and p.Team == LP.Team then
                        continue
                    end
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist <= radius then
                            lastDodge = now
                            local dir = (myHRP.Position - hrp.Position)
                            local dirH = Vector3.new(dir.X, 0, dir.Z)
                            local dodgeDir = dirH.Magnitude > 0.01 and dirH.Unit or myHRP.CFrame.LookVector

                            pcall(function()
                                local success = false
                                local finalCF = myHRP.CFrame
                                
                                for i = 0, 7 do
                                    local angleOffset = (i == 0) and 0 or (math.rad(i * 45) * (i % 2 == 0 and 1 or -1))
                                    local testDir = (CFrame.Angles(0, angleOffset, 0) * Vector3.new(dodgeDir.X, 0, dodgeDir.Z)).Unit
                                    
                                    local testDist = radius + 5
                                    local testPos = myHRP.Position + (testDir * testDist)
                                    
                                    if S.UltraInstinctAntiClip then
                                        local rayParams = RaycastParams.new()
                                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                        rayParams.FilterDescendantsInstances = {myChar, State.UI_CirclePart}
                                        local rayResult = Workspace:Raycast(myHRP.Position, testDir * testDist, rayParams)
                                        if rayResult then
                                            testPos = rayResult.Position - (testDir * 2)
                                        end
                                    end
                                    
                                    local hasGround = true
                                    local finalGroundY = testPos.Y
                                    if S.UltraInstinctSolidGround then
                                        local rayParams = RaycastParams.new()
                                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                        rayParams.FilterDescendantsInstances = {myChar, State.UI_CirclePart}
                                        local rayResult = Workspace:Raycast(testPos + Vector3.new(0, 2, 0), Vector3.new(0, -22, 0), rayParams)
                                        if rayResult then
                                            finalGroundY = rayResult.Position.Y + 3.2
                                        else
                                            hasGround = false
                                        end
                                    end
                                    
                                    if hasGround then
                                        finalCF = CFrame.new(testPos.X, finalGroundY, testPos.Z) * myHRP.CFrame.Rotation
                                        success = true
                                        break
                                    end
                                end
                                
                                if success then
                                    myHRP.CFrame = finalCF
                                    myHRP.AssemblyLinearVelocity = Vector3.zero
                                    
                                    if State.UI_CirclePart then
                                        State.UI_CirclePart.Color = Color3.fromRGB(0, 255, 0)
                                        task.delay(0.15, function()
                                            if State.UI_CirclePart and S.UltraInstinct then
                                                State.UI_CirclePart.Color = Color3.fromRGB(255, 0, 0)
                                            end
                                        end)
                                    end
                                    notify("Ultra Instinct Dodged: " .. p.DisplayName, Color3.fromRGB(50, 195, 75))
                                end
                            end)
                            break
                        end
                    end
                end
            end
        end
    end)
    table.insert(S.Connections, ultraInstinctConn)
end

registerModule("Movement", "Ultra Instinct", 300, 50, true, S.UltraInstinct, function(v)
    S.UltraInstinct = v
    if v then
        startUltraInstinct()
    else
        if State.UI_CirclePart then
            pcall(function() State.UI_CirclePart:Destroy() end)
            State.UI_CirclePart = nil
        end
    end
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Anti-Clip (No Wall Dodge)", S.UltraInstinctAntiClip, function(v) S.UltraInstinctAntiClip = v; saveConfig() end)
    addToggleOption(drawer, "Solid Ground Only", S.UltraInstinctSolidGround, function(v) S.UltraInstinctSolidGround = v; saveConfig() end)
    addToggleOption(drawer, "Team Check", S.UltraInstinctTeamCheck, function(v) S.UltraInstinctTeamCheck = v; saveConfig() end)
    addSliderOption(drawer, "Dodge Radius", 5, 30, S.UltraInstinctRadius or 12, function(v)
        S.UltraInstinctRadius = v
        saveConfig()
    end)
end, false)

if S.UltraInstinct then
    startUltraInstinct()
end

