local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP
local Mouse = Services.Mouse
local Camera = Services.Camera
local RunService = Services.RunService
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local getChar = Utils.getChar
local getHRP = Utils.getHRP
local getHum = Utils.getHum
local checkFriendship = Utils.checkFriendship
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addKeybindOption = UI.addKeybindOption
local saveConfig = VH.Config.saveConfig

local lastReloadTime = 0
local shootTimer = 0
local lastAutoplayShootTime = 0
local autoplayConn = nil
local activeWaypoints = {}
local activeWaypointIndex = 1
local activeTarget = nil
local lastMoveToPos = nil

local lastPosition = nil
local lastPositionCheckTime = 0
local stuckTime = 0
local jumpDebounce = 0
local lastPathRecalcTime = 0

local currentLockTarget = nil
local lastVisibleTargetTime = 0
local randomTargetPart = "Head"
local randomizerTimer = 0
local clickFrame = 0

local pathLines = {}
local waypointCircles = {}
local pillarLines = {}
local targetTracer = nil
local scannerLine = nil
local scannerHitDot = nil

VH.AutoplayPathLines = pathLines
VH.AutoplayWaypointCircles = waypointCircles
VH.AutoplayPillarLines = pillarLines
VH.AutoplayTargetTracer = targetTracer

local function clearDrawings()
    for _, line in ipairs(pathLines) do
        pcall(function() line.Visible = false end)
    end
    for _, circ in ipairs(waypointCircles) do
        pcall(function() circ.Visible = false end)
    end
    for _, line in ipairs(pillarLines) do
        pcall(function() line.Visible = false end)
    end
    if targetTracer then
        pcall(function() targetTracer.Visible = false end)
    end
    if scannerLine then
        pcall(function() scannerLine.Visible = false end)
    end
    if scannerHitDot then
        pcall(function() scannerHitDot.Visible = false end)
    end
end

local function drawPath(waypoints, startIndex)
    clearDrawings()
    if not waypoints or #waypoints == 0 then return end

    local lineIndex = 1
    local circleIndex = 1
    local pillarIndex = 1

    for i = startIndex, #waypoints do
        local wp = waypoints[i]
        if wp then
            local pos, onScreen = Camera:WorldToViewportPoint(wp.Position)
            if onScreen then
                local circ = waypointCircles[circleIndex]
                if not circ then
                    circ = Drawing.new("Circle")
                    circ.Thickness = 1.5
                    circ.Filled = false
                    circ.Transparency = 0.7
                    waypointCircles[circleIndex] = circ
                end

                local dist = (wp.Position - Camera.CFrame.Position).Magnitude
                local radius = math.clamp(120 / math.max(dist, 1), 3, 20)

                circ.Color = (i == startIndex) and Color3.fromRGB(50, 205, 50) or (State.currentThemeColor or Color3.fromRGB(141, 47, 196))
                circ.Position = Vector2.new(pos.X, pos.Y)
                circ.Radius = radius
                circ.Visible = true

                circleIndex = circleIndex + 1
            end
        end
    end

    for i = startIndex, #waypoints - 1 do
        local wp1 = waypoints[i]
        local wp2 = waypoints[i+1]
        if wp1 and wp2 then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(wp1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(wp2.Position)

            if onScreen1 or onScreen2 then
                local line = pathLines[lineIndex]
                if not line then
                    line = Drawing.new("Line")
                    line.Thickness = 2
                    line.Transparency = 0.8
                    pathLines[lineIndex] = line
                end

                line.Color = State.currentThemeColor or Color3.fromRGB(141, 47, 196)
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = true
                lineIndex = lineIndex + 1
            end
        end
    end

    for i = startIndex, #waypoints do
        local wp = waypoints[i]
        if wp then
            local groundPos = wp.Position
            local ceilingPos = groundPos + Vector3.new(0, 8, 0)
            local pos1, onScreen1 = Camera:WorldToViewportPoint(groundPos)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(ceilingPos)

            if onScreen1 or onScreen2 then
                local line = pillarLines[pillarIndex]
                if not line then
                    line = Drawing.new("Line")
                    line.Thickness = 1.0
                    line.Transparency = 0.4
                    pillarLines[pillarIndex] = line
                end

                line.Color = (i == startIndex) and Color3.fromRGB(50, 205, 50) or (State.currentThemeColor or Color3.fromRGB(141, 47, 196))
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = true
                pillarIndex = pillarIndex + 1
            end
        end
    end

    for i = lineIndex, #pathLines do
        pcall(function() pathLines[i].Visible = false end)
    end
    for i = circleIndex, #waypointCircles do
        pcall(function() waypointCircles[i].Visible = false end)
    end
    for i = pillarIndex, #pillarLines do
        pcall(function() pillarLines[i].Visible = false end)
    end
end

local function drawTargetTracerLine(startPos, endPos)
    if not targetTracer then
        targetTracer = Drawing.new("Line")
        targetTracer.Thickness = 1.5
        targetTracer.Transparency = 0.8
        targetTracer.Color = Color3.fromRGB(220, 38, 38)
        VH.AutoplayTargetTracer = targetTracer
    end

    local start2D, on1 = Camera:WorldToViewportPoint(startPos)
    local end2D, on2 = Camera:WorldToViewportPoint(endPos)

    if on1 or on2 then
        targetTracer.From = Vector2.new(start2D.X, start2D.Y)
        targetTracer.To = Vector2.new(end2D.X, end2D.Y)
        targetTracer.Visible = true
    else
        targetTracer.Visible = false
    end
end

local function drawScanningLaser(startPos, hitPos, isWall)
    if not scannerLine then
        scannerLine = Drawing.new("Line")
        scannerLine.Thickness = 2.5
        VH.AutoplayScannerLine = scannerLine
    end
    if not scannerHitDot then
        scannerHitDot = Drawing.new("Circle")
        scannerHitDot.Radius = 5
        scannerHitDot.Filled = true
        scannerHitDot.Transparency = 0.9
        VH.AutoplayScannerHitDot = scannerHitDot
    end

    local start2D, on1 = Camera:WorldToViewportPoint(startPos)
    local hit2D, on2 = Camera:WorldToViewportPoint(hitPos)

    if on1 or on2 then
        scannerLine.Color = isWall and Color3.fromRGB(220, 38, 38) or Color3.fromRGB(241, 196, 15)
        scannerLine.From = Vector2.new(start2D.X, start2D.Y)
        scannerLine.To = Vector2.new(hit2D.X, hit2D.Y)
        scannerLine.Transparency = 0.75
        scannerLine.Visible = true

        scannerHitDot.Color = scannerLine.Color
        scannerHitDot.Position = Vector2.new(hit2D.X, hit2D.Y)
        scannerHitDot.Visible = true
    else
        scannerLine.Visible = false
        scannerHitDot.Visible = false
    end
end

local function isAimingAtMe(p, myHRP)
    local char = p.Character
    local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if head and myHRP then
        local look = head.CFrame.LookVector
        local dir = (myHRP.Position - head.Position).Unit
        return look:Dot(dir) > 0.75
    end
    return false
end

local function isTargetValid(p)
    if not p or p.Parent ~= Players then return false end
    if S.AutoplayTeamCheck and p.Team == LP.Team then return false end
    if S.AutoplayFriendCheck and checkFriendship(p.UserId) then return false end
    local char = p.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.Health > 0 then
        local myHRP = getHRP()
        if myHRP and (hrp.Position - myHRP.Position).Magnitude <= S.AutoplayRange then
            return true
        end
    end
    return false
end

local function checkLineOfSight(targetHRP)
    local char = getChar()
    if not char or not targetHRP then return false end

    local origin = Camera.CFrame.Position
    local destination = targetHRP.Position
    local direction = (destination - origin)

    local filterList = {char, Camera}
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    for i = 1, 5 do
        rp.FilterDescendantsInstances = filterList
        local res = workspace:Raycast(origin, direction, rp)
        if not res then
            return true
        end

        local hitPart = res.Instance
        if hitPart:IsDescendantOf(targetHRP.Parent) then
            return true
        end

        if hitPart.CanCollide == false or hitPart.Transparency >= 0.7 or hitPart.Name:lower():find("glass") or hitPart.Name:lower():find("clip") or hitPart.Name:lower():find("water") or hitPart.Name:lower():find("trigger") or hitPart.Name:lower():find("effect") then
            table.insert(filterList, hitPart)
        else
            return false
        end
    end
    return false
end

local function getBestTarget()
    local myHRP = getHRP()
    if not myHRP then return nil end

    local currentLockScore = -math.huge
    if currentLockTarget and isTargetValid(currentLockTarget) then
        local p = currentLockTarget
        local char = p.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            local pos2D, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local hasLOS = checkLineOfSight(hrp)
            local isAiming = isAimingAtMe(p, myHRP)

            local dangerScore = 0
            if isAiming and hasLOS then
                dangerScore = 200
            elseif isAiming then
                dangerScore = 50
            end
            if dist < 20 and hasLOS then
                dangerScore = dangerScore + 80
            end

            currentLockScore = dangerScore + (hasLOS and 100 or 0) + (onScreen and 30 or 0)
            currentLockScore = currentLockScore + (1.0 - math.clamp(dist / S.AutoplayRange, 0, 1)) * 40
        end
    end

    local bestTarget = currentLockTarget
    local bestScore = currentLockScore

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or p == currentLockTarget then continue end
        if S.AutoplayTeamCheck and p.Team == LP.Team then continue end
        if S.AutoplayFriendCheck and checkFriendship(p.UserId) then continue end

        local char = p.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist <= S.AutoplayRange then
                local pos2D, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local hasLOS = checkLineOfSight(hrp)
                local isAiming = isAimingAtMe(p, myHRP)

                local dangerScore = 0
                if isAiming and hasLOS then
                    dangerScore = 200
                elseif isAiming then
                    dangerScore = 50
                end
                if dist < 20 and hasLOS then
                    dangerScore = dangerScore + 80
                end

                local score = dangerScore + (hasLOS and 100 or 0) + (onScreen and 30 or 0)
                score = score + (1.0 - math.clamp(dist / S.AutoplayRange, 0, 1)) * 40

                if S.AutoplayTargetMode == "Lowest HP" then
                    score = score + (100 - hum.Health) * 0.4
                end

                local requiredScore = (bestScore == -math.huge) and -math.huge or (bestScore + 25.0)
                if score > requiredScore then
                    bestScore = score
                    bestTarget = p
                end
            end
        end
    end

    currentLockTarget = bestTarget
    return bestTarget
end

local function checkAmmo(tool)
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("ValueBase") and (obj.Name:lower():find("ammo") or obj.Name:lower():find("clip") or obj.Name:lower():find("mag")) then
            if type(obj.Value) == "number" and obj.Value <= 0 then
                return true
            end
        end
    end
    return false
end

local function simulateReload()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

local lastComputedTargetPos = nil
local lastTargetVelocity = Vector3.zero

task.spawn(function()
    while State.uiRunning do
        task.wait(0.1)
        if S.AutoplayBot then
            pcall(function()
                local myHRP = getHRP()
                if not myHRP then
                    activeTarget = nil
                    activeWaypoints = {}
                    return
                end

                local target = getBestTarget()
                activeTarget = target

                if target then
                    local targetHRP = target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso") or target.Character.PrimaryPart)
                    if targetHRP then
                        local targetPos = targetHRP.Position
                        local targetVel = targetHRP.AssemblyLinearVelocity
                        local shouldRecalculate = false

                        local velChange = (targetVel - lastTargetVelocity).Magnitude
                        lastTargetVelocity = targetVel

                        if not lastComputedTargetPos then
                            shouldRecalculate = true
                        else
                            local distMoved = (targetPos - lastComputedTargetPos).Magnitude
                            if distMoved > 3.0 or velChange > 8.0 then
                                shouldRecalculate = true
                            end
                        end

                        if not shouldRecalculate and (not lastPathRecalcTime or (tick() - lastPathRecalcTime) > 0.6) then
                            shouldRecalculate = true
                        end

                        if shouldRecalculate then
                            lastComputedTargetPos = targetPos
                            lastPathRecalcTime = tick()

                            local path = PathfindingService:CreatePath({
                                AgentRadius = 2.0,
                                AgentHeight = 5.0,
                                AgentCanJump = true,
                                AgentCanClimb = true
                            })
                            path:ComputeAsync(myHRP.Position, targetPos)
                            if path.Status == Enum.PathStatus.Success then
                                activeWaypoints = path:GetWaypoints()
                                activeWaypointIndex = 1
                            else
                                activeWaypoints = {}
                            end
                        end
                    end
                else
                    activeWaypoints = {}
                    lastComputedTargetPos = nil
                    lastTargetVelocity = Vector3.zero
                end
            end)
        else
            activeTarget = nil
            activeWaypoints = {}
            lastComputedTargetPos = nil
            lastTargetVelocity = Vector3.zero
            task.wait(0.5)
        end
    end
end)

local function stopAutoplay()
    if autoplayConn then
        pcall(function() autoplayConn:Disconnect() end)
        local idx = table.find(S.Connections, autoplayConn)
        if idx then
            table.remove(S.Connections, idx)
        end
        autoplayConn = nil
    end
    pcall(function()
        local hum = getHum()
        if hum then hum:Move(Vector3.new(0, 0, 0)) end
    end)
    activeTarget = nil
    activeWaypoints = {}
    lastMoveToPos = nil
    lastPosition = nil
    currentLockTarget = nil
    stuckTime = 0
    clearDrawings()
    for _, line in ipairs(pathLines) do
        pcall(function() line:Remove() end)
    end
    for _, circ in ipairs(waypointCircles) do
        pcall(function() circ:Remove() end)
    end
    for _, line in ipairs(pillarLines) do
        pcall(function() line:Remove() end)
    end
    if targetTracer then pcall(function() targetTracer:Remove() end) end
    if scannerLine then pcall(function() scannerLine:Remove() end) end
    if scannerHitDot then pcall(function() scannerHitDot:Remove() end) end
    pathLines = {}
    waypointCircles = {}
    pillarLines = {}
    targetTracer = nil
    scannerLine = nil
    scannerHitDot = nil
end

local function startAutoplay()
    stopAutoplay()

    lastPositionCheckTime = tick()
    stuckTime = 0
    lastVisibleTargetTime = 0

    autoplayConn = RunService.Heartbeat:Connect(function()
        if not S.AutoplayBot then
            stopAutoplay()
            return
        end

        local ok, err = pcall(function()
            local char = getChar()
            local hum = getHum()
            local myHRP = getHRP()
            if not char or not hum or not myHRP or hum.Health <= 0 then return end

            local target = activeTarget
            local targetHRP = target and target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso") or target.Character.PrimaryPart)

            local scanDir = myHRP.CFrame.LookVector
            local targetWP = (#activeWaypoints > 0) and activeWaypoints[activeWaypointIndex]
            if targetWP then
                local diff = (targetWP.Position - myHRP.Position)
                local diffH = Vector3.new(diff.X, 0, diff.Z)
                if diffH.Magnitude > 0.1 then
                    scanDir = diffH.Unit
                end
            elseif targetHRP then
                local diff = (targetHRP.Position - myHRP.Position)
                local diffH = Vector3.new(diff.X, 0, diff.Z)
                if diffH.Magnitude > 0.1 then
                    scanDir = diffH.Unit
                end
            end

            local yDiff = 0
            if targetWP then
                yDiff = targetWP.Position.Y - myHRP.Position.Y
            end

            local isMoving = (targetWP ~= nil) or (targetHRP ~= nil)
            local currentPos = myHRP.Position
            if isMoving then
                if lastPosition then
                    local deltaCheck = tick() - lastPositionCheckTime
                    if deltaCheck >= 0.5 then
                        local distTraveled = (Vector3.new(currentPos.X, lastPosition.Y, currentPos.Z) - lastPosition).Magnitude
                        if distTraveled < 1.8 then
                            stuckTime = stuckTime + deltaCheck
                        else
                            stuckTime = 0
                        end
                        lastPosition = currentPos
                        lastPositionCheckTime = tick()
                    end
                else
                    lastPosition = currentPos
                    lastPositionCheckTime = tick()
                end
            else
                lastPosition = nil
                stuckTime = 0
            end

            if stuckTime >= 1.0 and tick() - jumpDebounce > 0.4 then
                hum.Jump = true
                jumpDebounce = tick()

                if stuckTime >= 2.0 then
                    local rightVec = myHRP.CFrame.RightVector
                    local nudgeDir = (math.random() > 0.5) and rightVec or -rightVec
                    myHRP.CFrame = myHRP.CFrame + nudgeDir * 1.5
                    stuckTime = 0
                else
                    stuckTime = 0
                end
            elseif yDiff < -3.5 and stuckTime >= 0.5 and tick() - jumpDebounce > 0.4 then
                hum.Jump = true
                jumpDebounce = tick()
                stuckTime = 0
            end

            local isAiming = false
            local hasLOS = false
            if target and targetHRP then
                local dist = (targetHRP.Position - myHRP.Position).Magnitude
                local inRange = (dist <= S.AutoplayRange)
                hasLOS = checkLineOfSight(targetHRP)

                if hasLOS then
                    lastVisibleTargetTime = tick()
                end

                local targetIsRecent = (tick() - lastVisibleTargetTime) < 0.5

                if S.AutoplayShoot and inRange and (hasLOS or targetIsRecent) then
                    isAiming = true

                    if tick() - randomizerTimer > 0.5 then
                        randomizerTimer = tick()
                        if S.AutoplayPartRandomizer == "Random" then
                            randomTargetPart = (math.random() > 0.5) and "Head" or "HumanoidRootPart"
                        else
                            randomTargetPart = S.AutoplayPartRandomizer or "Head"
                        end
                    end

                    local targetPartObj = target.Character:FindFirstChild(randomTargetPart) or targetHRP
                    local aimPosition = targetPartObj.Position

                    local goalCF = CFrame.new(Camera.CFrame.Position, aimPosition)
                    Camera.CFrame = Camera.CFrame:Lerp(goalCF, 0.22)

                    if hasLOS then

                        local now = tick()
                        if not lastAutoplayShootTime or (now - lastAutoplayShootTime) >= 0.05 then
                            lastAutoplayShootTime = now
                            pcall(function()
                                if not Utils.isMouseOverHubUI() then
                                    if mouse1press and mouse1release then
                                        task.spawn(function()
                                            mouse1press()
                                            task.wait(0.01)
                                            mouse1release()
                                        end)
                                    elseif mouse1click then
                                        mouse1click()
                                    else
                                        local VirtualUser = game:GetService("VirtualUser")
                                        VirtualUser:CaptureController()
                                        VirtualUser:ClickButton1(Vector2.new(Mouse.X, Mouse.Y))
                                    end
                                end
                            end)
                        end
                        shootTimer = shootTimer + 0.016
                    end
                end

                if S.AutoplayReload then
                    local needsReload = false
                    if shootTimer >= (S.AutoplayReloadInterval or 10) then
                        needsReload = true
                        shootTimer = 0
                    end

                    if needsReload and tick() - lastReloadTime > 2.5 then
                        lastReloadTime = tick()
                        simulateReload()
                    end
                end

                drawTargetTracerLine(myHRP.Position, targetHRP.Position)
            else
                if targetTracer then targetTracer.Visible = false end
            end

            if not isAiming or not hasLOS then
                if clickFrame > 0 then
                    pcall(function()
                        if mouse1release then
                            mouse1release()
                        else
                            local viewport = Camera.ViewportSize
                            local clickX = viewport.X / 2
                            local clickY = viewport.Y / 2
                            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
                        end
                    end)
                    clickFrame = 0
                end
            end

            if #activeWaypoints > 0 then
                local currentWP = activeWaypoints[activeWaypointIndex]
                if currentWP then
                    local wpPos = currentWP.Position
                    local distToWP = (Vector3.new(myHRP.Position.X, wpPos.Y, myHRP.Position.Z) - wpPos).Magnitude

                    local wallParams = RaycastParams.new()
                    wallParams.FilterType = Enum.RaycastFilterType.Exclude
                    wallParams.FilterDescendantsInstances = {char}
                    local wpDir = (wpPos - myHRP.Position)
                    local wpRay = workspace:Raycast(myHRP.Position, wpDir, wallParams)
                    if wpRay and wpRay.Instance and not wpRay.Instance:IsDescendantOf(target.Character) then
                        lastComputedTargetPos = nil
                    end

                    if distToWP < 2.2 then
                        activeWaypointIndex = activeWaypointIndex + 1
                    end
                end

                local targetWP = activeWaypoints[activeWaypointIndex]
                if targetWP then
                    if S.WalkSpeed and S.WalkSpeed > (State.gameDefaultSpeed or 16) then
                        hum.WalkSpeed = S.WalkSpeed
                    end

                    local wpPos = targetWP.Position
                    if not lastMoveToPos or (lastMoveToPos - wpPos).Magnitude > 0.2 then
                        hum:MoveTo(wpPos)
                        lastMoveToPos = wpPos
                    end

                    if (wpPos.Y - myHRP.Position.Y) > 2.5 then
                        hum.Jump = true
                    end

                    if targetWP.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end

                    if not isAiming then
                        local moveDir = (targetWP.Position - myHRP.Position)
                        local horizontalDir = Vector3.new(moveDir.X, 0, moveDir.Z)
                        if horizontalDir.Magnitude > 0.1 then
                            local goalCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + horizontalDir.Unit)
                            Camera.CFrame = Camera.CFrame:Lerp(goalCF, 0.05)
                        end
                    end
                else
                    if targetHRP then
                        local tPos = targetHRP.Position
                        if not lastMoveToPos or (lastMoveToPos - tPos).Magnitude > 0.2 then
                            hum:MoveTo(tPos)
                            lastMoveToPos = tPos
                        end
                    end
                end

                drawPath(activeWaypoints, activeWaypointIndex)
            else
                clearDrawings()
                if targetHRP then
                    if S.WalkSpeed and S.WalkSpeed > (State.gameDefaultSpeed or 16) then
                        hum.WalkSpeed = S.WalkSpeed
                    end
                    local tPos = targetHRP.Position
                    if not lastMoveToPos or (lastMoveToPos - tPos).Magnitude > 0.2 then
                        hum:MoveTo(tPos)
                        lastMoveToPos = tPos
                    end
                else
                    hum:Move(Vector3.new(0, 0, 0))
                    lastMoveToPos = nil
                end
            end

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {char}

            local scanRight = Vector3.new(-scanDir.Z, 0, scanDir.X).Unit
            local scanLeft = -scanRight

            local scanDist = 4.5
            local offsets = { Vector3.zero, scanLeft * 1.2, scanRight * 1.2 }
            local hitRay = nil
            local hitHigh = false

            for _, offset in ipairs(offsets) do
                local originLow = myHRP.Position + offset - Vector3.new(0, 1.8, 0)
                local originMid = myHRP.Position + offset
                local originHigh = myHRP.Position + offset + Vector3.new(0, 2.2, 0)

                local rLow = workspace:Raycast(originLow, scanDir * scanDist, rayParams)
                local rMid = workspace:Raycast(originMid, scanDir * scanDist, rayParams)
                local rHigh = workspace:Raycast(originHigh, scanDir * scanDist, rayParams)

                if rLow or rMid then
                    hitRay = rLow or rMid
                    if rHigh then
                        hitHigh = true
                    end
                    break
                end
            end

            if hitRay and hitRay.Instance then
                local inst = hitRay.Instance

                local isClimbable = inst:IsA("TrussPart") or inst.Name:lower():find("ladder") or inst.Name:lower():find("truss") or inst.Name:lower():find("climb")

                if isClimbable then
                    if tick() - jumpDebounce > 0.4 then
                        hum.Jump = true
                        jumpDebounce = tick()
                    end
                elseif not hitHigh then
                    if not target or not inst:IsDescendantOf(target.Character) then
                        if tick() - jumpDebounce > 0.8 then
                            hum.Jump = true
                            jumpDebounce = tick()
                        end
                    end
                end

                if not target or not inst:IsDescendantOf(target.Character) then
                    drawScanningLaser(myHRP.Position, hitRay.Position, true)
                else
                    drawScanningLaser(myHRP.Position, hitRay.Position, false)
                end
            else
                local groundRay = workspace:Raycast(myHRP.Position, (scanDir * scanDist) - Vector3.new(0, 5, 0), rayParams)
                if groundRay and groundRay.Instance then
                    drawScanningLaser(myHRP.Position, groundRay.Position, false)
                else
                    if scannerLine then scannerLine.Visible = false end
                    if scannerHitDot then scannerHitDot.Visible = false end
                end
            end
        end)

        if not ok then
            warn("[WASOR Autoplay Error]: " .. tostring(err))
        end
    end)

    table.insert(S.Connections, autoplayConn)
end

registerModule("Combat", "Autoplay Bot", 20, 50, true, S.AutoplayBot, function(v)
    S.AutoplayBot = v
    saveConfig()
    if v then
        startAutoplay()
    else
        stopAutoplay()
    end
end, function(drawer)
    addToggleOption(drawer, "Auto Shoot Target", S.AutoplayShoot, function(v) S.AutoplayShoot = v; saveConfig() end)
    addToggleOption(drawer, "Auto Reload Gun", S.AutoplayReload, function(v) S.AutoplayReload = v; saveConfig() end)
    addToggleOption(drawer, "Ignore Team Targets", S.AutoplayTeamCheck, function(v) S.AutoplayTeamCheck = v; saveConfig() end)
    addToggleOption(drawer, "Ignore Friend Targets", S.AutoplayFriendCheck, function(v) S.AutoplayFriendCheck = v; saveConfig() end)
    addDropdownOption(drawer, "Target Hitbox Part", {"Head", "HumanoidRootPart", "Random"}, table.find({"Head", "HumanoidRootPart", "Random"}, S.AutoplayPartRandomizer) or 1, function(_, opt) S.AutoplayPartRandomizer = opt; saveConfig() end)
    addDropdownOption(drawer, "Target Select Mode", {"Closest", "Lowest HP"}, table.find({"Closest", "Lowest HP"}, S.AutoplayTargetMode) or 1, function(_, opt) S.AutoplayTargetMode = opt; saveConfig() end)
    addSliderOption(drawer, "Target Max Range", 10, 500, S.AutoplayRange, function(v) S.AutoplayRange = v; saveConfig() end)
    addSliderOption(drawer, "Auto Reload Interval", 3, 30, S.AutoplayReloadInterval, function(v) S.AutoplayReloadInterval = v; saveConfig() end)
    addKeybindOption(drawer, "Autoplay Bot Bind", S.AutoplayBotKey or Enum.KeyCode.Unknown, function(k) S.AutoplayBotKey = k; saveConfig() end)
end, false)

if S.AutoplayBot then
    startAutoplay()
end

