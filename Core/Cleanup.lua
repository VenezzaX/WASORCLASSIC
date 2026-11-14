local VH = _G.VoidHub
local Cleanup = {}

local Services = VH.Services
local State = VH.State

local function getGuiContainers()
    local containers = {}
    pcall(function()
        if gethui then
            local h = gethui()
            if h and not table.find(containers, h) then table.insert(containers, h) end
        end
        if get_hidden_gui then
            local hg = get_hidden_gui()
            if hg and not table.find(containers, hg) then table.insert(containers, hg) end
        end
        if Services.CoreGui and not table.find(containers, Services.CoreGui) then
            table.insert(containers, Services.CoreGui)
        end
        if Services.LP then
            local pg = Services.LP:FindFirstChild("PlayerGui")
            if pg and not table.find(containers, pg) then table.insert(containers, pg) end
        end
    end)
    return containers
end

local function safeHideDrawing(d)
    if not d then return end
    pcall(function() d.Visible = false end)
end

local function safeRemoveDrawing(d)
    if not d then return end
    pcall(function() d.Visible = false end)
    pcall(function()
        if d.Destroy then
            d:Destroy()
        elseif d.Remove then
            d:Remove()
        end
    end)
    pcall(function() d:Remove() end)
    pcall(function() d:Destroy() end)
end

Cleanup.hideESP = function(p)
    local S = State.S
    if not S or not S.ESPPool then return end
    local pool = S.ESPPool[p]
    if not pool and type(p) == "userdata" then
        for playerObj, entry in pairs(S.ESPPool) do
            if playerObj == p or (p.UserId and playerObj.UserId and p.UserId == playerObj.UserId) or (p.Name and playerObj.Name and p.Name == playerObj.Name) then
                pool = entry
                break
            end
        end
    end
    if pool then
        safeHideDrawing(pool.boxOutline)
        safeHideDrawing(pool.boxFill)
        safeHideDrawing(pool.tracer)
        safeHideDrawing(pool.nameTag)
        safeHideDrawing(pool.healthText)
        safeHideDrawing(pool.distText)
        safeHideDrawing(pool.healthBarOutline)
        safeHideDrawing(pool.healthBarFill)
        safeHideDrawing(pool.losLine)
        safeHideDrawing(pool.indicator)
        if pool.skeleton then
            for _, line in ipairs(pool.skeleton) do safeHideDrawing(line) end
        end
        if pool.corners then
            for _, line in ipairs(pool.corners) do safeHideDrawing(line) end
        end
        if pool.lines3D then
            for _, line in ipairs(pool.lines3D) do safeHideDrawing(line) end
        end
        if pool.extraLines then
            for _, line in ipairs(pool.extraLines) do safeHideDrawing(line) end
        end
    end
end

Cleanup.hideAllESP = function()
    local S = State.S
    if S and S.ESPPool then
        for p, _ in pairs(S.ESPPool) do
            Cleanup.hideESP(p)
        end
    end
end

Cleanup.destroyESP = function(p)
    local S = State.S
    if not S or not S.ESPPool then return end
    local poolKey = p
    local pool = S.ESPPool[p]
    if not pool and type(p) == "userdata" then
        for playerObj, entry in pairs(S.ESPPool) do
            if playerObj == p or (p.UserId and playerObj.UserId and p.UserId == playerObj.UserId) or (p.Name and playerObj.Name and p.Name == playerObj.Name) then
                pool = entry
                poolKey = playerObj
                break
            end
        end
    end
    if pool then
        Cleanup.hideESP(poolKey)
        safeRemoveDrawing(pool.boxOutline)
        safeRemoveDrawing(pool.boxFill)
        safeRemoveDrawing(pool.tracer)
        safeRemoveDrawing(pool.nameTag)
        safeRemoveDrawing(pool.healthText)
        safeRemoveDrawing(pool.distText)
        safeRemoveDrawing(pool.healthBarOutline)
        safeRemoveDrawing(pool.healthBarFill)
        safeRemoveDrawing(pool.losLine)
        safeRemoveDrawing(pool.indicator)
        if pool.skeleton then
            for _, line in ipairs(pool.skeleton) do safeRemoveDrawing(line) end
        end
        if pool.corners then
            for _, line in ipairs(pool.corners) do safeRemoveDrawing(line) end
        end
        if pool.lines3D then
            for _, line in ipairs(pool.lines3D) do safeRemoveDrawing(line) end
        end
        if pool.extraLines then
            for _, line in ipairs(pool.extraLines) do safeRemoveDrawing(line) end
        end
        S.ESPPool[poolKey] = nil
    end
end

Cleanup.cleanupAll = function()
    local S = State.S
    State.uiRunning = false
    State.networkTagsRunning = false
    State.networkTagsLoopActive = false

    pcall(function()
        if _G.WASOR_ScreenGui and _G.WASOR_ScreenGui.Parent then
            pcall(function() _G.WASOR_ScreenGui:Destroy() end)
            _G.WASOR_ScreenGui = nil
        end
        local containers = getGuiContainers()
        for _, parent in ipairs(containers) do
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    if child.Name == "MeteorRobloxGUI" or child.Name == "DiscordNetworkHub" or child.Name == "MinimapGui" or child.Name == "VoidCustomNametag" or child.Name == "EulaFrame" or child.Name == "NetworkUserTag" or child.Name == "WASOR_PaperDollHUD" or child.Name == "WASOR_ESPPreviewGui" or child.Name == "WASOR_ModelViewerGui" or child.Name == "TranscendingViewportGui" or child.Name == "MinimalVisualizerGui" or child.Name == "VoidNo3DCoverGui" or child.Name == "WallWalkToggleUI" or child:FindFirstChild("MainUIContainer") or child:FindFirstChild("StudioTopRibbon") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end)
        end
        if State.clearNetworkTags then pcall(State.clearNetworkTags) end
    end)

    for _, c in ipairs(S.Connections) do pcall(function() c:Disconnect() end) end
    S.Connections = {}
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidESPUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidAimbotUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidFlyUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidFreecamUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidPaperDollUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("VoidESPPreviewUpdate") end)
    pcall(function() Services.RunService:UnbindFromRenderStep("TranscendingFluidSync") end)
    if State.stopViewportESP then pcall(State.stopViewportESP) end

    if S.GodModeConn then pcall(function() S.GodModeConn:Disconnect() end) S.GodModeConn = nil end
    if S.TallRunningConn then pcall(function() S.TallRunningConn:Disconnect() end) S.TallRunningConn = nil end
    if S.SpoofConn then pcall(function() S.SpoofConn:Disconnect() end) S.SpoofConn = nil end
    if S.UISpoofObjects then
        for obj, data in pairs(S.UISpoofObjects) do
            pcall(function()
                if data.Conn then data.Conn:Disconnect() end
                if data.DestConn then data.DestConn:Disconnect() end
            end)
        end
        S.UISpoofObjects = {}
    end

    for p, conn in pairs(S.ChatConnections) do pcall(function() conn:Disconnect() end) end
    S.ChatConnections = {}

    if S.ESPPool then for p, _ in pairs(S.ESPPool) do Cleanup.destroyESP(p) end; S.ESPPool = {} end
    S.OverheadPool = {}

    if S.AirWalkPlat then pcall(function() S.AirWalkPlat:Destroy() end) S.AirWalkPlat = nil end
    if S.GhostDummy then pcall(function() S.GhostDummy:Destroy() end) S.GhostDummy = nil end
    if S.FloatBody then pcall(function() S.FloatBody:Destroy() end) S.FloatBody = nil end
    if S.WaterPlat then pcall(function() S.WaterPlat:Destroy() end) S.WaterPlat = nil end
    if State.UI_CirclePart then pcall(function() State.UI_CirclePart:Destroy() end) State.UI_CirclePart = nil end

    pcall(function()
        for _, obj in ipairs(Services.Workspace:GetChildren()) do
            if obj.Name == "UltraInstinctCircle" or obj.Name == "VoidWaterPlat" or obj.Name == "VoidAirWalkPlatform" or obj.Name == "GhostDummy" then
                pcall(function() obj:Destroy() end)
            end
        end
    end)

    if State.playerCards then
        for p, item in pairs(State.playerCards) do
            pcall(function() if item.HPConn then item.HPConn:Disconnect() end; if item.CharConn then item.CharConn:Disconnect() end end)
        end
        State.playerCards = {}
    end

    pcall(function()
        if State.isFreecam then
            State.isFreecam = false
            local char = Services.LP.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
            if hrp then hrp.Anchored = false end
            if State.freecamConnection then State.freecamConnection:Disconnect() State.freecamConnection = nil end
            if State.freecamInputConn then State.freecamInputConn:Disconnect() State.freecamInputConn = nil end
            if State.freecamInputBeganConn then State.freecamInputBeganConn:Disconnect() State.freecamInputBeganConn = nil end
            if State.freecamInputEndedConn then State.freecamInputEndedConn:Disconnect() State.freecamInputEndedConn = nil end
            Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            Services.Camera.CameraType = Enum.CameraType.Custom
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then Services.Camera.CameraSubject = hum end
        end
    end)

    pcall(function()
        if Services.LP.Character then
            VH.Utils.revertTallAnimations(Services.LP.Character)
            VH.Utils.disableGodMode()
            local hum = Services.LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = State.gameDefaultSpeed or hum.WalkSpeed or 16
                hum.JumpPower = State.gameDefaultJumpPower or hum.JumpPower or 50
                hum.UseJumpPower = (State.gameDefaultUseJumpPower ~= nil) and State.gameDefaultUseJumpPower or hum.UseJumpPower
            end
            for _, part in ipairs(Services.LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Name == "HumanoidRootPart" then
                        part.CanCollide = false
                    else
                        local isTorsoOrHead = (part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head") and not part:IsA("Accessory") and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool")
                        part.CanCollide = isTorsoOrHead
                    end
                elseif part:IsA("Sound") and string.sub(part.Name, 1, 3) == "WW_" then
                    pcall(function() part:Destroy() end)
                end
            end
        end
    end)

    pcall(function() State.S.HeadSitActive = false; State.S.HeadSitTargetPlayer = nil; State.S.AirSwim = false end)
    pcall(function() if VH.WallWalkCleanup then pcall(VH.WallWalkCleanup) end end)
    pcall(function() VH.Utils.toggleMapXray(false); VH.Utils.toggleClearVision(false) end)
    pcall(function() if VH.Utils.toggleNo3DRenderCover then VH.Utils.toggleNo3DRenderCover(false) else Services.RunService:Set3dRenderingEnabled(true) end end)
    pcall(function() Services.Lighting.Ambient = State.originalAmbient; Services.Lighting.OutdoorAmbient = State.originalOutdoor end)
    pcall(function()
        local oldBlur = Services.Lighting:FindFirstChild("WeAreSkiddingBlur")
        if oldBlur then oldBlur:Destroy() end
    end)
    pcall(function()
        if getgenv().VoidFOVCircle then
            pcall(function() getgenv().VoidFOVCircle.Visible = false; getgenv().VoidFOVCircle:Remove() end)
            getgenv().VoidFOVCircle = nil
        end
        if State.fovCircle then
            pcall(function() State.fovCircle.Visible = false; State.fovCircle:Remove() end)
            State.fovCircle = nil
        end
    end)
    pcall(function()
        if VH.AutoplayPathLines then
            for _, line in ipairs(VH.AutoplayPathLines) do
                pcall(function() line.Visible = false; line:Remove() end)
            end
            VH.AutoplayPathLines = nil
        end
        if VH.AutoplayWaypointCircles then
            for _, circ in ipairs(VH.AutoplayWaypointCircles) do
                pcall(function() circ.Visible = false; circ:Remove() end)
            end
            VH.AutoplayWaypointCircles = nil
        end
        if VH.AutoplayPillarLines then
            for _, line in ipairs(VH.AutoplayPillarLines) do
                pcall(function() line.Visible = false; line:Remove() end)
            end
            VH.AutoplayPillarLines = nil
        end
        if VH.AutoplayTargetTracer then
            pcall(function() VH.AutoplayTargetTracer.Visible = false; VH.AutoplayTargetTracer:Remove() end)
            VH.AutoplayTargetTracer = nil
        end
        if VH.AutoplayScannerLine then
            pcall(function() VH.AutoplayScannerLine.Visible = false; VH.AutoplayScannerLine:Remove() end)
            VH.AutoplayScannerLine = nil
        end
        if VH.AutoplayScannerHitDot then
            pcall(function() VH.AutoplayScannerHitDot.Visible = false; VH.AutoplayScannerHitDot:Remove() end)
            VH.AutoplayScannerHitDot = nil
        end
    end)
end

VH.Cleanup = Cleanup
return Cleanup
