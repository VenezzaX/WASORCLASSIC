local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule
local addKeybindOption = UI.addKeybindOption
local saveConfig = VH.Config.saveConfig

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local StudioTheme = {
    windowBg = Color3.fromRGB(37, 37, 38),
    headerBg = Color3.fromRGB(45, 45, 48),
    panelBg = Color3.fromRGB(42, 42, 45),
    insetBg = Color3.fromRGB(26, 26, 28),
    border = Color3.fromRGB(20, 20, 22),
    text = Color3.fromRGB(225, 225, 228),
    textMuted = Color3.fromRGB(160, 160, 165),
    blue = Color3.fromRGB(0, 122, 204),
    green = Color3.fromRGB(76, 175, 80),
    yellow = Color3.fromRGB(220, 170, 50),
    btnBg = Color3.fromRGB(50, 50, 54),
}

local CONFIG = {
    SizeSmall = UDim2.new(0, 260, 0, 260),
    SizeLarge = UDim2.new(0, 480, 0, 480),
    SizeFull = UDim2.new(0, 850, 0, 850),
    
    PosNormal = UDim2.new(1, -30, 0, 30),
    PosFull = UDim2.new(0.5, 0, 0.5, 0),
    
    MinZoomScale = 40,
    MaxZoomScale = 1200,
    ZoomIncrement = 30,
    
    UI_BackgroundColor = StudioTheme.windowBg,
    UI_StrokeColor = StudioTheme.border,
    UI_ZIndex_Map = 1,
    UI_ZIndex_Controls = 100,
    
    ShowOtherPlayers = true,
    ScanFolder = Workspace,
}

local currentMapState = "Small"
local mapPerspectiveMode = "2D"
local targetScale = 180
local actualLerpedScale = 180
local orbitAngleX = 0
local orbitAngleY = 45
local isDraggingAxis = false

local mapFrame = nil
local viewport = nil
local mapWorld = nil
local entitiesFolder = nil
local mapCamera = nil
local nameLabel = nil
local controlFrame = nil
local toggleBtn = nil
local maxBtn = nil
local perspectiveBtn = nil

local activeCharacterClones = {}
local minimapInitialized = false

local materialColors = {
    [Enum.Material.Grass] = Color3.fromRGB(75, 145, 90),
    [Enum.Material.Sand] = Color3.fromRGB(225, 195, 150),
    [Enum.Material.Concrete] = Color3.fromRGB(140, 140, 145),
    [Enum.Material.Rock] = Color3.fromRGB(115, 105, 100),
    [Enum.Material.Asphalt] = Color3.fromRGB(55, 55, 65),
    [Enum.Material.Water] = Color3.fromRGB(50, 130, 210),
}

local function deepSanitizeAndClone(object)
    if object:IsA("BasePart") then
        if object.Transparency >= 1 or object.Name == "Terrain" then return end
        if object:IsDescendantOf(Workspace) and object:FindFirstAncestorOfClass("Model") and Players:GetPlayerFromCharacter(object:FindFirstAncestorOfClass("Model")) then return end
        
        local shadowCopy = object:Clone()
        shadowCopy:ClearAllChildren()
        shadowCopy.Anchored = true
        shadowCopy.CanCollide = false
        shadowCopy.CanTouch = false
        shadowCopy.CanQuery = false
        shadowCopy.CastShadow = false
        
        if not object:IsA("MeshPart") and not object:IsA("UnionOperation") then
            shadowCopy.Material = Enum.Material.SmoothPlastic
            shadowCopy.Color = materialColors[object.Material] or object.Color
        end
        
        shadowCopy.Parent = mapWorld
        object.AncestryChanged:Connect(function(_, p) if not p then shadowCopy:Destroy() end end)
        
    elseif object:IsA("Model") or object:IsA("Folder") or object == CONFIG.ScanFolder then
        for _, node in ipairs(object:GetChildren()) do 
            deepSanitizeAndClone(node) 
        end
    end
end

local function cleanAndMirrorCharacter(player, character)
    if activeCharacterClones[player] then activeCharacterClones[player]:Destroy() end
    
    character.Archivable = true
    local charClone = character:Clone()
    charClone.Name = "RenderEntity_" .. player.Name
    
    for _, desc in ipairs(charClone:GetDescendants()) do
        if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("Sound") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
        end
    end
    
    charClone.Parent = entitiesFolder
    activeCharacterClones[player] = charClone
end

local function updateLayoutVisuals()
    local targetSize, targetPos, targetAnchor
    if currentMapState == "Small" then
        targetSize = CONFIG.SizeSmall; targetPos = CONFIG.PosNormal; targetAnchor = Vector2.new(1, 0); targetScale = 180
        toggleBtn.Text = "[+]"; maxBtn.Text = "[M]"
    elseif currentMapState == "Large" then
        targetSize = CONFIG.SizeLarge; targetPos = CONFIG.PosNormal; targetAnchor = Vector2.new(1, 0); targetScale = 360
        toggleBtn.Text = "[-]"; maxBtn.Text = "[M]"
    elseif currentMapState == "Full" then
        targetSize = CONFIG.SizeFull; targetPos = CONFIG.PosFull; targetAnchor = Vector2.new(0.5, 0.5); targetScale = 800
        toggleBtn.Text = "[+]"; maxBtn.Text = "[X]"
    end
    
    mapFrame.AnchorPoint = targetAnchor
    TweenService:Create(mapFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize, Position = targetPos}):Play()
end

local function styleButton(btn, text, order)
    btn.Size = UDim2.new(0, 44, 0, 26)
    btn.BackgroundColor3 = StudioTheme.btnBg
    btn.TextColor3 = StudioTheme.text
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.BorderSizePixel = 1
    btn.BorderColor3 = StudioTheme.border
    btn.LayoutOrder = order
    btn.ZIndex = CONFIG.UI_ZIndex_Controls
    btn.Parent = controlFrame
end

local function initMinimap()
    if minimapInitialized then return end
    minimapInitialized = true
    
    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    local parentGui = playerGui:FindFirstChild("MinimapGui") or Instance.new("ScreenGui", playerGui)
    parentGui.Name = "MinimapGui"
    parentGui.ResetOnSpawn = false
    
    mapFrame = Instance.new("Frame")
    mapFrame.Name = "MinimapContainer"
    mapFrame.Size = CONFIG.SizeSmall
    mapFrame.Position = CONFIG.PosNormal
    mapFrame.AnchorPoint = Vector2.new(1, 0)
    mapFrame.BackgroundColor3 = StudioTheme.windowBg
    mapFrame.BorderSizePixel = 1
    mapFrame.BorderColor3 = StudioTheme.border
    mapFrame.Visible = false
    mapFrame.Parent = parentGui
    
    viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, -8, 1, -8)
    viewport.Position = UDim2.new(0, 4, 0, 4)
    viewport.BackgroundColor3 = StudioTheme.insetBg
    viewport.BorderSizePixel = 1
    viewport.BorderColor3 = StudioTheme.border
    viewport.ClipsDescendants = true
    viewport.ZIndex = CONFIG.UI_ZIndex_Map
    viewport.Parent = mapFrame
    
    mapWorld = Instance.new("Folder", viewport)
    mapWorld.Name = "MapWorld"
    
    entitiesFolder = Instance.new("Folder", viewport)
    entitiesFolder.Name = "RenderedEntities"
    
    mapCamera = Instance.new("Camera")
    mapCamera.CameraType = Enum.CameraType.Scriptable
    mapCamera.FieldOfView = 50 
    viewport.CurrentCamera = mapCamera
    mapCamera.Parent = mapWorld 
    
    nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -16, 0, 20)
    nameLabel.Position = UDim2.new(0, 8, 1, -26)
    nameLabel.BackgroundColor3 = StudioTheme.headerBg
    nameLabel.BorderSizePixel = 1
    nameLabel.BorderColor3 = StudioTheme.border
    nameLabel.TextColor3 = StudioTheme.text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 12
    nameLabel.Text = "  " .. (localPlayer.DisplayName or localPlayer.Name)
    nameLabel.ZIndex = CONFIG.UI_ZIndex_Controls
    nameLabel.Parent = mapFrame
    
    controlFrame = Instance.new("Frame")
    controlFrame.Size = UDim2.new(0, 48, 0, 100)
    controlFrame.Position = UDim2.new(0, -54, 0, 0)
    controlFrame.BackgroundTransparency = 1
    controlFrame.Parent = mapFrame
    
    local controlLayout = Instance.new("UIListLayout", controlFrame)
    controlLayout.Padding = UDim.new(0, 4)
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    toggleBtn = Instance.new("TextButton"); styleButton(toggleBtn, "[+]", 1)
    maxBtn = Instance.new("TextButton"); styleButton(maxBtn, "[M]", 2)
    perspectiveBtn = Instance.new("TextButton"); styleButton(perspectiveBtn, "2D", 3)
    
    task.spawn(function()
        deepSanitizeAndClone(CONFIG.ScanFolder)
    end)
    CONFIG.ScanFolder.ChildAdded:Connect(function(c) task.wait(0.1); deepSanitizeAndClone(c) end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        currentMapState = (currentMapState == "Large") and "Small" or "Large"
        updateLayoutVisuals()
    end)
    
    maxBtn.MouseButton1Click:Connect(function()
        currentMapState = (currentMapState == "Full") and "Small" or "Full"
        updateLayoutVisuals()
    end)
    
    perspectiveBtn.MouseButton1Click:Connect(function()
        mapPerspectiveMode = (mapPerspectiveMode == "2D") and "3D" or "2D"
        perspectiveBtn.Text = mapPerspectiveMode
        orbitAngleX = 0 
    end)
    
    viewport.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if input.Position.Z > 0 then
                targetScale = math.clamp(targetScale - CONFIG.ZoomIncrement, CONFIG.MinZoomScale, CONFIG.MaxZoomScale)
            else
                targetScale = math.clamp(targetScale + CONFIG.ZoomIncrement, CONFIG.MinZoomScale, CONFIG.MaxZoomScale)
            end
        elseif isDraggingAxis and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if mapPerspectiveMode == "3D" then
                orbitAngleX = orbitAngleX - (input.Delta.X * 0.4)
                orbitAngleY = math.clamp(orbitAngleY + (input.Delta.Y * 0.4), 10, 80)
            end
        end
    end)
    
    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingAxis = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingAxis = false
        end
    end)
    
    local function onPlayerAdded(player)
        player.CharacterAdded:Connect(function(char)
            player.CharacterAppearanceLoaded:Wait()
            cleanAndMirrorCharacter(player, char)
        end)
        if player.Character and player:HasAppearanceLoaded() then
            cleanAndMirrorCharacter(player, player.Character)
        end
    end
    
    for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(function(p)
        if activeCharacterClones[p] then activeCharacterClones[p]:Destroy(); activeCharacterClones[p] = nil end
    end)
    
    table.insert(S.Connections, RunService.RenderStepped:Connect(function(deltaTime)
        if not S.MinimapActive then return end
        
        local localCharacter = localPlayer.Character
        local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        if not localRootPart then return end
        
        local currentFocusPosition = localRootPart.Position
        local mainCamera = Workspace.CurrentCamera
        if not mainCamera then return end
        
        actualLerpedScale = actualLerpedScale + (targetScale - actualLerpedScale) * math.clamp(deltaTime * 12, 0, 1)
        
        if mapPerspectiveMode == "2D" then
            local cameraHeight = (actualLerpedScale / 2) / math.tan(math.rad(mapCamera.FieldOfView / 2))
            mapCamera.CFrame = CFrame.new(currentFocusPosition + Vector3.new(0, cameraHeight, 0), currentFocusPosition)
        else
            local _, mainCamYaw, _ = mainCamera.CFrame:ToOrientation()
            local combinedYaw = mainCamYaw + math.rad(orbitAngleX)
            local radY = math.rad(orbitAngleY)
            local cameraDistance = (actualLerpedScale / 1.6)
            
            local offsetVector = Vector3.new(
                cameraDistance * math.cos(radY) * math.sin(combinedYaw),
                cameraDistance * math.sin(radY),
                cameraDistance * math.cos(radY) * math.cos(combinedYaw)
            )
            
            mapCamera.CFrame = CFrame.new(currentFocusPosition + offsetVector, currentFocusPosition)
        end
        
        for player, clonedModel in pairs(activeCharacterClones) do
            local realCharacter = player.Character
            local realRoot = realCharacter and realCharacter:FindFirstChild("HumanoidRootPart")
            local realHumanoid = realCharacter and realCharacter:FindFirstChildOfClass("Humanoid")
            
            if realRoot and realHumanoid and realHumanoid.Health > 0 then
                clonedModel.PrimaryPart = clonedModel:FindFirstChild("HumanoidRootPart")
                
                if clonedModel.PrimaryPart then
                    clonedModel:SetPrimaryPartCFrame(realRoot.CFrame)
                    for _, limb in ipairs(clonedModel:GetChildren()) do
                        if limb:IsA("BasePart") then limb.Transparency = 0 end
                    end
                end
            else
                for _, limb in ipairs(clonedModel:GetChildren()) do
                    if limb:IsA("BasePart") then limb.Transparency = 1 end
                end
            end
        end
    end))
end

registerModule("Render", "Minimap", 440, 50, true, S.MinimapActive, function(v)
    S.MinimapActive = v
    saveConfig()
    if v then
        initMinimap()
        if mapFrame then mapFrame.Visible = true end
    else
        if mapFrame then mapFrame.Visible = false end
    end
end, function(drawer)
    addKeybindOption(drawer, "Minimap Bind", S.MinimapKey or Enum.KeyCode.Unknown, function(k) S.MinimapKey = k; saveConfig() end)
end, false)
