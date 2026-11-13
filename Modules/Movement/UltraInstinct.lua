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
local lastNotifyTime = 0
local threatCooldowns = {}

if S.UltraInstinctDetectNPCs == nil then
    S.UltraInstinctDetectNPCs = true
end
if S.UltraInstinctDetectProjectiles == nil then
    S.UltraInstinctDetectProjectiles = true
end
if S.UltraInstinctDetectTools == nil then
    S.UltraInstinctDetectTools = true
end

local function findSafeCollidableGround(targetPos, maxDist, baseIgnore)
    local maxDistance = maxDist or 30
    local origin = targetPos + Vector3.new(0, 3, 0)
    local rayDir = Vector3.new(0, -1, 0)

    local ignoreList = {}
    if baseIgnore then
        for _, inst in ipairs(baseIgnore) do
            if inst then table.insert(ignoreList, inst) end
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    pcall(function() rayParams.RespectCanCollide = true end)

    local currentOrigin = origin
    local traveled = 0

    for _ = 1, 8 do
        rayParams.FilterDescendantsInstances = ignoreList
        local distRemaining = maxDistance - traveled
        if distRemaining <= 0 then break end

        local res = Workspace:Raycast(currentOrigin, rayDir * distRemaining, rayParams)
        if not res or not res.Instance then
            break
        end

        local hitPart = res.Instance
        local isCollide = (hitPart.CanCollide == true)

        local lowerName = hitPart.Name:lower()
        local isHazard = lowerName:find("kill") or lowerName:find("death") or lowerName:find("lava") or lowerName:find("hazard") or lowerName:find("void")
        local isTruss = hitPart:IsA("TrussPart")

        if isCollide and not isHazard and not isTruss then
            return res.Position.Y + 3.2, hitPart
        end

        table.insert(ignoreList, hitPart)
        local stepDist = (res.Position - currentOrigin).Magnitude
        traveled = traveled + stepDist + 0.05
        currentOrigin = res.Position + (rayDir * 0.05)
    end

    return nil
end

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
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myChar or not myHRP or not myHum or myHum.Health <= 0 then
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
            local safeCircleY = findSafeCollidableGround(myHRP.Position, 25, {myChar, State.UI_CirclePart})
            if safeCircleY then
                groundY = safeCircleY - 3.2
            end
            pcall(function()
                State.UI_CirclePart.Size = Vector3.new(0.05, radius * 2, radius * 2)
                State.UI_CirclePart.CFrame = CFrame.new(myHRP.Position.X, groundY + 0.05, myHRP.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
                State.UI_CirclePart.Transparency = 0.85
            end)
        end

        local now = tick()
        local dodgeCooldown = S.UltraInstinctCooldown or 0
        if now - lastDodge >= dodgeCooldown then
            local myPos = myHRP.Position
            local threats = {}

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    if S.UltraInstinctTeamCheck and p.Team == LP.Team then
                        continue
                    end

                    local pCooldown = threatCooldowns[p] or 0
                    if now < pCooldown then
                        continue
                    end

                    local char = p.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hrp and (not hum or hum.Health > 0) then
                        local toMe = myPos - hrp.Position
                        local dist = toMe.Magnitude
                        local effectiveRadius = radius

                        local isFlinging = hrp.AssemblyLinearVelocity.Magnitude > 45 or hrp.AssemblyAngularVelocity.Magnitude > 45
                        if isFlinging then
                            effectiveRadius = radius * 1.5
                        end

                        local threatPos = hrp.Position
                        local threatDist = dist

                        if S.UltraInstinctDetectTools ~= false then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                                if handle then
                                    local toolDist = (myPos - handle.Position).Magnitude
                                    if toolDist < threatDist then
                                        threatDist = toolDist
                                        threatPos = handle.Position
                                    end
                                end
                            end
                        end

                        if threatDist <= effectiveRadius then
                            local relVel = hrp.AssemblyLinearVelocity - myHRP.AssemblyLinearVelocity
                            local isMovingCloser = relVel:Dot(toMe) > 0.1
                            local isFacingMe = hrp.CFrame.LookVector:Dot(toMe.Unit) > 0.35
                            local isClose = threatDist <= math.min(effectiveRadius, 7)
                            local hasToolEquipped = char:FindFirstChildOfClass("Tool") ~= nil

                            local isThreat = isClose or isMovingCloser or isFacingMe or isFlinging or hasToolEquipped
                            local onlyApproaching = (S.UltraInstinctOnlyApproaching == true)

                            if not onlyApproaching or isThreat then
                                table.insert(threats, {
                                    source = p,
                                    name = p.DisplayName,
                                    pos = threatPos,
                                    dist = threatDist,
                                    priority = isFlinging and 1 or (isMovingCloser and 2 or 3)
                                })
                            end
                        end
                    end
                end
            end

            if S.UltraInstinctDetectNPCs ~= false and #threats == 0 then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Model") and obj ~= myChar and not Players:GetPlayerFromCharacter(obj) then
                        local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        if hrp and (not hum or hum.Health > 0) then
                            local toMe = myPos - hrp.Position
                            local dist = toMe.Magnitude
                            if dist <= radius then
                                table.insert(threats, {
                                    source = obj,
                                    name = "NPC: " .. obj.Name,
                                    pos = hrp.Position,
                                    dist = dist,
                                    priority = 3
                                })
                            end
                        end
                    end
                end
                for _, folderName in ipairs({"Enemies", "NPCs", "Zombies", "Mobs", "Monsters"}) do
                    local folder = Workspace:FindFirstChild(folderName)
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if obj:IsA("Model") and obj ~= myChar and not Players:GetPlayerFromCharacter(obj) then
                                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
                                local hum = obj:FindFirstChildOfClass("Humanoid")
                                if hrp and (not hum or hum.Health > 0) then
                                    local toMe = myPos - hrp.Position
                                    local dist = toMe.Magnitude
                                    if dist <= radius then
                                        table.insert(threats, {
                                            source = obj,
                                            name = "Mob: " .. obj.Name,
                                            pos = hrp.Position,
                                            dist = dist,
                                            priority = 3
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if S.UltraInstinctDetectProjectiles ~= false and #threats == 0 then
                for _, fName in ipairs({"Projectiles", "Bullets", "Rockets", "Spells", "Debris"}) do
                    local f = Workspace:FindFirstChild(fName)
                    if f then
                        for _, part in ipairs(f:GetChildren()) do
                            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(myChar) then
                                local toMe = myPos - part.Position
                                if toMe.Magnitude <= radius + 8 then
                                    local vel = part.AssemblyLinearVelocity
                                    if vel.Magnitude > 15 and vel:Dot(toMe) > 0 then
                                        table.insert(threats, {
                                            source = part,
                                            name = "Projectile: " .. part.Name,
                                            pos = part.Position,
                                            dist = toMe.Magnitude,
                                            priority = 1
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
                for _, part in ipairs(Workspace:GetChildren()) do
                    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(myChar) then
                        local toMe = myPos - part.Position
                        if toMe.Magnitude <= radius + 5 then
                            local vel = part.AssemblyLinearVelocity
                            if vel.Magnitude > 25 and vel:Dot(toMe) > 0 then
                                table.insert(threats, {
                                    source = part,
                                    name = "Hazard: " .. part.Name,
                                    pos = part.Position,
                                    dist = toMe.Magnitude,
                                    priority = 1
                                })
                            end
                        end
                    end
                end
            end

            if #threats > 0 then
                table.sort(threats, function(a, b)
                    if a.priority ~= b.priority then
                        return a.priority < b.priority
                    end
                    return a.dist < b.dist
                end)

                local primaryThreat = threats[1]
                lastDodge = now
                threatCooldowns[primaryThreat.source] = now + dodgeCooldown

                pcall(function()
                    if S.UltraInstinctWalkBackward then
                        local dirAway = (myHRP.Position - primaryThreat.pos)
                        local dirH = Vector3.new(dirAway.X, 0, dirAway.Z)
                        local walkDir = dirH.Magnitude > 0.01 and dirH.Unit or -myHRP.CFrame.LookVector
                        local walkDist = radius + 4
                        local targetPos = myHRP.Position + (walkDir * walkDist)

                        if S.UltraInstinctAntiClip ~= false then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local ignoreInstances = {myChar, State.UI_CirclePart}
                            if primaryThreat.source.IsA and primaryThreat.source:IsA("Instance") then
                                table.insert(ignoreInstances, primaryThreat.source)
                            end
                            rayParams.FilterDescendantsInstances = ignoreInstances
                            local rayResult = Workspace:Raycast(myHRP.Position, walkDir * walkDist, rayParams)
                            if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
                                targetPos = rayResult.Position - (walkDir * 2)
                            end
                        end

                        local finalGroundY = targetPos.Y
                        local hasGround = true
                        if S.UltraInstinctSolidGround ~= false then
                            local safeY = findSafeCollidableGround(targetPos, 28, {myChar, State.UI_CirclePart})
                            if safeY then
                                finalGroundY = safeY
                            else
                                hasGround = false
                            end
                        end

                        if hasGround then
                            myHum:Move(walkDir, false)
                            myHum:MoveTo(Vector3.new(targetPos.X, finalGroundY, targetPos.Z))
                            if State.UI_CirclePart then
                                State.UI_CirclePart.Color = Color3.fromRGB(0, 255, 120)
                                task.delay(0.2, function()
                                    if State.UI_CirclePart and S.UltraInstinct then
                                        State.UI_CirclePart.Color = Color3.fromRGB(255, 0, 0)
                                    end
                                end)
                            end
                            if now - lastNotifyTime > 1.5 then
                                lastNotifyTime = now
                                notify("Ultra Instinct Evaded: " .. primaryThreat.name, Color3.fromRGB(50, 195, 75))
                            end
                        end
                    else
                        local dir = (myHRP.Position - primaryThreat.pos)
                        local dirH = Vector3.new(dir.X, 0, dir.Z)
                        local dodgeDir = dirH.Magnitude > 0.01 and dirH.Unit or myHRP.CFrame.LookVector

                        local success = false
                        local finalCF = myHRP.CFrame

                        for i = 0, 7 do
                            local angleOffset = (i == 0) and 0 or (math.rad(i * 45) * (i % 2 == 0 and 1 or -1))
                            local testDir = (CFrame.Angles(0, angleOffset, 0) * Vector3.new(dodgeDir.X, 0, dodgeDir.Z)).Unit
                            local testDist = radius + 6
                            local testPos = myHRP.Position + (testDir * testDist)

                            if S.UltraInstinctAntiClip ~= false then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                local ignoreInstances = {myChar, State.UI_CirclePart}
                                if primaryThreat.source.IsA and primaryThreat.source:IsA("Instance") then
                                    table.insert(ignoreInstances, primaryThreat.source)
                                end
                                rayParams.FilterDescendantsInstances = ignoreInstances
                                local rayResult = Workspace:Raycast(myHRP.Position, testDir * testDist, rayParams)
                                if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
                                    testPos = rayResult.Position - (testDir * 3)
                                end
                            end

                            local hasGround = true
                            local finalGroundY = testPos.Y
                            if S.UltraInstinctSolidGround ~= false then
                                local safeY = findSafeCollidableGround(testPos, 28, {myChar, State.UI_CirclePart})
                                if safeY then
                                    finalGroundY = safeY
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
                            myHRP.AssemblyAngularVelocity = Vector3.zero

                            if State.UI_CirclePart then
                                State.UI_CirclePart.Color = Color3.fromRGB(0, 255, 120)
                                task.delay(0.2, function()
                                    if State.UI_CirclePart and S.UltraInstinct then
                                        State.UI_CirclePart.Color = Color3.fromRGB(255, 0, 0)
                                    end
                                end)
                            end
                            if now - lastNotifyTime > 1.5 then
                                lastNotifyTime = now
                                notify("Ultra Instinct Dodged: " .. primaryThreat.name, Color3.fromRGB(50, 195, 75))
                            end
                        end
                    end
                end)
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
    addToggleOption(drawer, "Walk Backward (No Teleport)", S.UltraInstinctWalkBackward == true, function(v)
        S.UltraInstinctWalkBackward = v
        saveConfig()
    end)
    addToggleOption(drawer, "Dodge Only Approaching (Anti-Abuse)", S.UltraInstinctOnlyApproaching == true, function(v)
        S.UltraInstinctOnlyApproaching = v
        saveConfig()
    end)
    addToggleOption(drawer, "Anti-Clip (No Wall Dodge)", S.UltraInstinctAntiClip ~= false, function(v)
        S.UltraInstinctAntiClip = v
        saveConfig()
    end)
    addToggleOption(drawer, "Solid Ground Only", S.UltraInstinctSolidGround ~= false, function(v)
        S.UltraInstinctSolidGround = v
        saveConfig()
    end)
    addToggleOption(drawer, "Team Check", S.UltraInstinctTeamCheck, function(v)
        S.UltraInstinctTeamCheck = v
        saveConfig()
    end)
    addToggleOption(drawer, "Detect Tool Weapons", S.UltraInstinctDetectTools ~= false, function(v)
        S.UltraInstinctDetectTools = v
        saveConfig()
    end)
    addToggleOption(drawer, "Detect NPCs & Mobs", S.UltraInstinctDetectNPCs ~= false, function(v)
        S.UltraInstinctDetectNPCs = v
        saveConfig()
    end)
    addToggleOption(drawer, "Detect Projectiles & Fast Hazards", S.UltraInstinctDetectProjectiles ~= false, function(v)
        S.UltraInstinctDetectProjectiles = v
        saveConfig()
    end)
    addSliderOption(drawer, "Dodge Radius", 5, 30, S.UltraInstinctRadius or 12, function(v)
        S.UltraInstinctRadius = v
        saveConfig()
    end)
    addSliderOption(drawer, "Dodge Cooldown (ms)", 0, 1000, math.round((S.UltraInstinctCooldown or 0) * 1000), function(v)
        S.UltraInstinctCooldown = v / 1000
        saveConfig()
    end, 0)
end, false)

if S.UltraInstinct then
    startUltraInstinct()
end