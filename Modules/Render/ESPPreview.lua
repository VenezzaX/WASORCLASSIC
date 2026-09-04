local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addToggleOption = UI.addToggleOption
local addButtonOption = UI.addButtonOption
local addKeybindOption = UI.addKeybindOption
local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

local previewBoxStyleDropdown = nil
local previewColorDropdown = nil
local previewTracerOriginDropdown = nil
local previewTransparencySlider = nil
local hudStyleLabel = nil
local hudColorLabel = nil

local previewPartMap = {}
local previewBoneMap = {}
local previewMotorMap = {}

local previewTrackedParts = {}
local previewTrackedBones = {}
local previewTrackedMotors = {}
local previewTrackedDirty = true
local lastPreviewScanTime = 0

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

local previewFrame = nil
local viewport = nil
local previewWorld = nil
local previewCamera = nil
local previewCharClone = nil
local previewInitialized = false

local orbitAngle = 180
local autoSpin = false
local viewDistance = 7.5
local viewHeight = 0.2
local isDraggingOrbit = false
local dragStartPos = Vector2.zero
local startOrbitAngle = 0

-- Preview ESP Visual Overlay Elements
local espContainer = nil
local previewBoxOutline = nil
local previewBoxFill = nil
local previewCorners = {}
local previewLines3D = {}
local previewTracer = nil
local previewNameTag = nil
local previewHealthBarOutline = nil
local previewHealthBarFill = nil
local previewHealthText = nil
local previewDistText = nil
local previewSkeletonLines = {}
local previewLosLine = nil
local emptyHintLabel = nil

local chipRefreshers = {}
local appearanceConnection = nil
local descendantConnection = nil
local descendantRemovingConnection = nil
local toolAddedConnection = nil
local toolRemovedConnection = nil
local wsChildConnection = nil
local camChildConnection = nil

local allStyles = {"Full", "Corners", "3D Box", "Brackets", "Tech Hex", "Top-Bottom"}
local colorOptions = {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}
local tracerOrigins = {"Bottom", "Top", "Center", "Mouse"}

local espColorMapping = {
    ["Team Color"] = Color3.fromRGB(80, 160, 255),
    ["Red"] = Color3.fromRGB(220, 40, 40),
    ["Green"] = Color3.fromRGB(55, 200, 80),
    ["Blue"] = Color3.fromRGB(40, 120, 220),
    ["Yellow"] = Color3.fromRGB(220, 175, 45),
    ["Cyan"] = Color3.fromRGB(45, 200, 220),
    ["White"] = Color3.fromRGB(255, 255, 255)
}

local StudioTheme = {
    windowBg     = Color3.fromRGB(37, 37, 38),
    headerBg     = Color3.fromRGB(45, 45, 48),
    panelBg      = Color3.fromRGB(42, 42, 45),
    insetBg      = Color3.fromRGB(26, 26, 28),
    border       = Color3.fromRGB(20, 20, 22),
    borderSubtle = Color3.fromRGB(55, 55, 58),
    text         = Color3.fromRGB(225, 225, 228),
    textMuted    = Color3.fromRGB(160, 160, 165),
    blue         = Color3.fromRGB(0, 122, 204),
    btnBg        = Color3.fromRGB(50, 50, 54),
    btnHover     = Color3.fromRGB(65, 65, 70),
}

local function getGuiParent()
    local success, core = pcall(function()
        return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui
    end)
    if success and core then return core end
    return localPlayer:WaitForChild("PlayerGui")
end

local function makeModelArchivable(model)
    if not model then return end
    pcall(function() model.Archivable = true end)
    for _, desc in ipairs(model:GetDescendants()) do
        pcall(function() desc.Archivable = true end)
    end
end

local function sanitizeClone(char)
    if not char then return nil end
    makeModelArchivable(char)
    
    previewPartMap = {}
    previewBoneMap = {}
    previewMotorMap = {}
    previewTrackedParts = {}
    previewTrackedBones = {}
    previewTrackedMotors = {}
    previewTrackedDirty = true
    lastPreviewScanTime = 0
    
    local id = 0
    for _, desc in ipairs(char:GetDescendants()) do
        id = id + 1
        desc:SetAttribute("WasorPreviewId", id)
    end
    
    local clone = char:Clone()
    if not clone then
        for _, desc in ipairs(char:GetDescendants()) do
            desc:SetAttribute("WasorPreviewId", nil)
        end
        return nil
    end
    clone.Name = "ESPPreviewAvatar"
    
    local cloneMap = {}
    for _, desc in ipairs(clone:GetDescendants()) do
        local cid = desc:GetAttribute("WasorPreviewId")
        if cid then
            cloneMap[cid] = desc
        end
        if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("Sound") or desc:IsA("BillboardGui") or desc:IsA("Highlight") then
            pcall(function() desc:Destroy() end)
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.CastShadow = false
        end
    end
    
    for _, desc in ipairs(char:GetDescendants()) do
        local cid = desc:GetAttribute("WasorPreviewId")
        if cid and cloneMap[cid] then
            local clonedObj = cloneMap[cid]
            if desc:IsA("BasePart") then
                previewPartMap[desc] = clonedObj
            elseif desc:IsA("Bone") then
                previewBoneMap[desc] = clonedObj
            elseif desc:IsA("Motor6D") then
                previewMotorMap[desc] = clonedObj
            end
        end
        desc:SetAttribute("WasorPreviewId", nil)
    end
    
    local hrp = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso") or clone.PrimaryPart
    if hrp then
        clone.PrimaryPart = hrp
        hrp.CFrame = CFrame.new(0, 0, 0)
    end
    
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        hum.RequiresNeck = false
        local anim = hum:FindFirstChildOfClass("Animator")
        if anim then pcall(function() anim:Destroy() end) end
    end
    
    return clone
end

local function setupPreviewModel()
    if previewCharClone then
        pcall(function() previewCharClone:Destroy() end)
        previewCharClone = nil
    end
    if previewWorld then
        pcall(function()
            for _, child in ipairs(previewWorld:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
    previewPartMap = {}
    previewBoneMap = {}
    previewMotorMap = {}
    previewTrackedParts = {}
    previewTrackedBones = {}
    previewTrackedMotors = {}
    previewTrackedDirty = true
    lastPreviewScanTime = 0
    if not previewWorld then return end
    
    local char = localPlayer.Character
    if char then
        previewCharClone = sanitizeClone(char)
        if previewCharClone then
            previewCharClone.Parent = previewWorld
            local hrp = previewCharClone:FindFirstChild("HumanoidRootPart") or previewCharClone.PrimaryPart
            if hrp then
                previewCharClone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
            end
        end
    end
end

local function connectPreviewCharListeners(char)
    if appearanceConnection then appearanceConnection:Disconnect(); appearanceConnection = nil end
    if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
    if descendantRemovingConnection then descendantRemovingConnection:Disconnect(); descendantRemovingConnection = nil end
    if toolAddedConnection then toolAddedConnection:Disconnect(); toolAddedConnection = nil end
    if toolRemovedConnection then toolRemovedConnection:Disconnect(); toolRemovedConnection = nil end
    if wsChildConnection then wsChildConnection:Disconnect(); wsChildConnection = nil end
    if camChildConnection then camChildConnection:Disconnect(); camChildConnection = nil end
    if not char then return end
    
    appearanceConnection = localPlayer.CharacterAppearanceLoaded:Connect(function()
        task.wait(0.2)
        previewTrackedDirty = true
        if previewFrame and previewFrame.Visible then
            setupPreviewModel()
        end
    end)
    
    descendantConnection = char.DescendantAdded:Connect(function(desc)
        pcall(function() desc.Archivable = true end)
        previewTrackedDirty = true
        if desc:IsA("Humanoid") then
            task.delay(0.1, function()
                if previewFrame and previewFrame.Visible then
                    setupPreviewModel()
                end
            end)
        end
    end)
    
    descendantRemovingConnection = char.DescendantRemoving:Connect(function(desc)
        previewTrackedDirty = true
        if desc:IsA("BasePart") then
            local clonePart = previewPartMap[desc]
            if clonePart then
                previewPartMap[desc] = nil
                pcall(function() clonePart:Destroy() end)
            end
        elseif desc:IsA("Accessory") or desc:IsA("Tool") or desc:IsA("Model") or desc:IsA("Folder") then
            for _, d in ipairs(desc:GetDescendants()) do
                if d:IsA("BasePart") then
                    local cp = previewPartMap[d]
                    if cp then
                        previewPartMap[d] = nil
                        pcall(function() cp:Destroy() end)
                    end
                elseif d:IsA("Bone") then
                    previewBoneMap[d] = nil
                elseif d:IsA("Motor6D") then
                    previewMotorMap[d] = nil
                end
            end
            if previewCharClone then
                local cloneCont = previewCharClone:FindFirstChild(desc.Name)
                if cloneCont then
                    pcall(function() cloneCont:Destroy() end)
                end
            end
        elseif desc:IsA("Bone") then
            previewBoneMap[desc] = nil
        elseif desc:IsA("Motor6D") then
            previewMotorMap[desc] = nil
        end
    end)
    
    toolAddedConnection = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            previewTrackedDirty = true
            pcall(function()
                child.Archivable = true
                for _, d in ipairs(child:GetDescendants()) do
                    d.Archivable = true
                end
            end)
        end
    end)
    
    toolRemovedConnection = char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            previewTrackedDirty = true
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("BasePart") then
                    local cp = previewPartMap[d]
                    if cp then
                        previewPartMap[d] = nil
                        pcall(function() cp:Destroy() end)
                    end
                end
            end
            if previewCharClone then
                local cloneTool = previewCharClone:FindFirstChild(child.Name)
                if cloneTool then
                    pcall(function() cloneTool:Destroy() end)
                end
            end
        end
    end)
    
    pcall(function()
        wsChildConnection = Workspace.ChildAdded:Connect(function()
            previewTrackedDirty = true
        end)
    end)
    pcall(function()
        if Workspace.CurrentCamera then
            camChildConnection = Workspace.CurrentCamera.ChildAdded:Connect(function()
                previewTrackedDirty = true
            end)
        end
    end)
end

local function getAllRealCharacterParts(realChar)
    local parts = {}
    local seen = {}
    
    if not realChar or not realChar.Parent then return parts end
    
    -- 1. All BaseParts inside realChar
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("BasePart") and not seen[desc] then
            seen[desc] = true
            table.insert(parts, desc)
        end
    end
    
    -- 2. Traverse connected parts for all parts found in realChar
    -- Using GetConnectedParts(true) gets parts connected via Welds, Motor6Ds, Snaps, WeldConstraints
    local i = 1
    while i <= #parts do
        local currentPart = parts[i]
        pcall(function()
            local connected = currentPart:GetConnectedParts(true)
            for _, p in ipairs(connected) do
                if p:IsA("BasePart") and not seen[p] and not p.Anchored and not p:IsA("Terrain") and p.Name ~= "Baseplate" then
                    seen[p] = true
                    table.insert(parts, p)
                end
            end
        end)
        i = i + 1
    end
    
    -- 3. Any welds or joints inside realChar pointing to external parts
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
            local p0, p1 = desc.Part0, desc.Part1
            if p0 and p0:IsA("BasePart") and not seen[p0] and not p0.Anchored and not p0:IsA("Terrain") and p0.Name ~= "Baseplate" then
                seen[p0] = true
                table.insert(parts, p0)
            end
            if p1 and p1:IsA("BasePart") and not seen[p1] and not p1.Anchored and not p1:IsA("Terrain") and p1.Name ~= "Baseplate" then
                seen[p1] = true
                table.insert(parts, p1)
            end
        end
    end
    
    -- 4. Check Workspace, Camera, and Player for external morph models/folders
    local charName = realChar.Name:lower()
    local playerName = localPlayer.Name:lower()
    local playerDisplay = localPlayer.DisplayName:lower()
    local hrp = realChar:FindFirstChild("HumanoidRootPart") or realChar:FindFirstChild("Torso") or realChar.PrimaryPart
    
    local function checkContainer(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if (child:IsA("Model") or child:IsA("Folder")) and child ~= realChar then
                if not Players:GetPlayerFromCharacter(child) then
                    local cName = child.Name:lower()
                    local isMatch = cName:find(charName, 1, true) 
                        or cName:find(playerName, 1, true) 
                        or cName:find(playerDisplay, 1, true)
                        or cName:find("morph", 1, true)
                        or cName:find("custom", 1, true)
                        or cName:find("breast", 1, true)
                        or cName:find("boob", 1, true)
                        or cName:find("hip", 1, true)
                        or cName:find("thigh", 1, true)
                        or cName:find("paw", 1, true)
                        or cName:find("tail", 1, true)
                        or cName:find("rig", 1, true)
                        or cName:find("avatar", 1, true)
                    
                    if isMatch then
                        for _, p in ipairs(child:GetDescendants()) do
                            if p:IsA("BasePart") and not seen[p] and not p.Anchored and not p:IsA("Terrain") and p.Name ~= "Baseplate" then
                                local nearPlayer = true
                                if hrp and p.Position then
                                    if (p.Position - hrp.Position).Magnitude > 50 then
                                        nearPlayer = false
                                    end
                                end
                                if nearPlayer then
                                    seen[p] = true
                                    table.insert(parts, p)
                                end
                            end
                        end
                    end
                end
            elseif child:IsA("BasePart") and child ~= realChar and not seen[child] and not child.Anchored and not child:IsA("Terrain") and child.Name ~= "Baseplate" then
                local cName = child.Name:lower()
                local isMatch = cName:find(charName, 1, true) 
                    or cName:find(playerName, 1, true) 
                    or cName:find(playerDisplay, 1, true)
                    or cName:find("morph", 1, true)
                    or cName:find("custom", 1, true)
                    or cName:find("breast", 1, true)
                    or cName:find("boob", 1, true)
                    or cName:find("hip", 1, true)
                    or cName:find("thigh", 1, true)
                    or cName:find("paw", 1, true)
                    or cName:find("tail", 1, true)
                    or cName:find("rig", 1, true)
                if isMatch then
                    local nearPlayer = true
                    if hrp and child.Position then
                        if (child.Position - hrp.Position).Magnitude > 50 then
                            nearPlayer = false
                        end
                    end
                    if nearPlayer then
                        seen[child] = true
                        table.insert(parts, child)
                    end
                end
            end
        end
    end
    
    pcall(function() checkContainer(Workspace) end)
    pcall(function() checkContainer(Workspace.CurrentCamera) end)
    pcall(function() checkContainer(localPlayer) end)
    
    return parts
end

local function getOrCreateMatchingPartInClone(realPart, cloneChar)
    if not realPart or not cloneChar then return nil end
    local existing = previewPartMap[realPart]
    if existing and existing.Parent ~= nil then
        return existing
    end
    
    pcall(function()
        realPart.Archivable = true
        for _, desc in ipairs(realPart:GetDescendants()) do
            desc.Archivable = true
        end
    end)
    
    local clonePart = nil
    pcall(function()
        clonePart = realPart:Clone()
    end)
    
    if not clonePart then
        pcall(function()
            if realPart:IsA("MeshPart") then
                clonePart = Instance.new("Part")
                local sm = Instance.new("SpecialMesh")
                sm.MeshType = Enum.MeshType.FileMesh
                sm.MeshId = realPart.MeshId
                sm.TextureId = realPart.TextureID
                pcall(function()
                    if realPart.MeshSize.X > 0 and realPart.MeshSize.Y > 0 and realPart.MeshSize.Z > 0 then
                        sm.Scale = realPart.Size / realPart.MeshSize
                    end
                end)
                sm.Parent = clonePart
            else
                clonePart = Instance.new("Part")
            end
            clonePart.Name = realPart.Name
            clonePart.Size = realPart.Size
            clonePart.Color = realPart.Color
            clonePart.Material = realPart.Material
            clonePart.Reflectance = realPart.Reflectance
            
            for _, child in ipairs(realPart:GetChildren()) do
                if child:IsA("SpecialMesh") then
                    pcall(function()
                        child.Archivable = true
                        local sm = child:Clone()
                        if not sm then
                            sm = Instance.new("SpecialMesh")
                            sm.MeshType = child.MeshType
                            sm.MeshId = child.MeshId
                            sm.TextureId = child.TextureId
                            sm.Scale = child.Scale
                            sm.Offset = child.Offset
                            sm.VertexColor = child.VertexColor
                        end
                        if sm then sm.Parent = clonePart end
                    end)
                elseif child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") or child:IsA("Bone") then
                    pcall(function()
                        child.Archivable = true
                        local clonedChild = child:Clone()
                        if clonedChild then clonedChild.Parent = clonePart end
                    end)
                end
            end
        end)
    end
    
    if not clonePart then
        return nil
    end
    
    clonePart.Anchored = true
    clonePart.CanCollide = false
    clonePart.CanTouch = false
    clonePart.CanQuery = false
    clonePart.CastShadow = false
    
    for _, desc in ipairs(clonePart:GetDescendants()) do
        if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("Sound") or desc:IsA("BillboardGui") or desc:IsA("Highlight") then
            pcall(function() desc:Destroy() end)
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.CastShadow = false
            local realChild = realPart:FindFirstChild(desc.Name, true)
            if realChild and realChild:IsA("BasePart") then
                previewPartMap[realChild] = desc
            end
        elseif desc:IsA("Bone") then
            local realBone = realPart:FindFirstChild(desc.Name, true)
            if realBone and realBone:IsA("Bone") then
                previewBoneMap[realBone] = desc
            end
        elseif desc:IsA("Motor6D") then
            local realMotor = realPart:FindFirstChild(desc.Name, true)
            if realMotor and realMotor:IsA("Motor6D") then
                previewMotorMap[realMotor] = desc
            end
        end
    end
    
    local parent = realPart.Parent
    if parent == localPlayer.Character then
        clonePart.Parent = cloneChar
    elseif parent and parent:IsA("Accessory") then
        local cloneAcc = cloneChar:FindFirstChild(parent.Name)
        if not cloneAcc or not cloneAcc:IsA("Accessory") then
            cloneAcc = Instance.new("Accessory")
            cloneAcc.Name = parent.Name
            cloneAcc.Parent = cloneChar
        end
        clonePart.Parent = cloneAcc
    elseif parent and parent:IsA("Tool") then
        local cloneTool = cloneChar:FindFirstChild(parent.Name)
        if not cloneTool or not cloneTool:IsA("Tool") then
            cloneTool = Instance.new("Tool")
            cloneTool.Name = parent.Name
            cloneTool.Parent = cloneChar
        end
        clonePart.Parent = cloneTool
    elseif parent and parent:IsA("Model") and parent ~= localPlayer.Character then
        local cloneModel = cloneChar:FindFirstChild(parent.Name)
        if not cloneModel or not cloneModel:IsA("Model") then
            cloneModel = Instance.new("Model")
            cloneModel.Name = parent.Name
            cloneModel.Parent = cloneChar
        end
        clonePart.Parent = cloneModel
    elseif parent and parent:IsA("Folder") then
        local cloneFolder = cloneChar:FindFirstChild(parent.Name)
        if not cloneFolder or not cloneFolder:IsA("Folder") then
            cloneFolder = Instance.new("Folder")
            cloneFolder.Name = parent.Name
            cloneFolder.Parent = cloneChar
        end
        clonePart.Parent = cloneFolder
    else
        clonePart.Parent = cloneChar
    end
    
    previewPartMap[realPart] = clonePart
    return clonePart
end

local function syncClothingAndColors(realChar, cloneChar)
    if not realChar or not cloneChar then return end
    
    -- 1. Shirt
    local realShirt = realChar:FindFirstChildOfClass("Shirt")
    local cloneShirt = cloneChar:FindFirstChildOfClass("Shirt")
    if realShirt then
        if not cloneShirt then
            pcall(function()
                realShirt.Archivable = true
                local s = realShirt:Clone()
                if s then s.Parent = cloneChar end
            end)
        elseif cloneShirt.ShirtTemplate ~= realShirt.ShirtTemplate then
            cloneShirt.ShirtTemplate = realShirt.ShirtTemplate
        end
    elseif cloneShirt then
        pcall(function() cloneShirt:Destroy() end)
    end
    
    -- 2. Pants
    local realPants = realChar:FindFirstChildOfClass("Pants")
    local clonePants = cloneChar:FindFirstChildOfClass("Pants")
    if realPants then
        if not clonePants then
            pcall(function()
                realPants.Archivable = true
                local p = realPants:Clone()
                if p then p.Parent = cloneChar end
            end)
        elseif clonePants.PantsTemplate ~= realPants.PantsTemplate then
            clonePants.PantsTemplate = realPants.PantsTemplate
        end
    elseif clonePants then
        pcall(function() clonePants:Destroy() end)
    end
    
    -- 3. ShirtGraphic (T-Shirt)
    local realGraphic = realChar:FindFirstChildOfClass("ShirtGraphic")
    local cloneGraphic = cloneChar:FindFirstChildOfClass("ShirtGraphic")
    if realGraphic then
        if not cloneGraphic then
            pcall(function()
                realGraphic.Archivable = true
                local g = realGraphic:Clone()
                if g then g.Parent = cloneChar end
            end)
        elseif cloneGraphic.Graphic ~= realGraphic.Graphic then
            cloneGraphic.Graphic = realGraphic.Graphic
        end
    elseif cloneGraphic then
        pcall(function() cloneGraphic:Destroy() end)
    end
    
    -- 4. BodyColors
    local realBC = realChar:FindFirstChildOfClass("BodyColors")
    local cloneBC = cloneChar:FindFirstChildOfClass("BodyColors")
    if realBC then
        if not cloneBC then
            pcall(function()
                realBC.Archivable = true
                local b = realBC:Clone()
                if b then b.Parent = cloneChar end
            end)
        else
            if cloneBC.HeadColor3 ~= realBC.HeadColor3 then cloneBC.HeadColor3 = realBC.HeadColor3 end
            if cloneBC.TorsoColor3 ~= realBC.TorsoColor3 then cloneBC.TorsoColor3 = realBC.TorsoColor3 end
            if cloneBC.LeftArmColor3 ~= realBC.LeftArmColor3 then cloneBC.LeftArmColor3 = realBC.LeftArmColor3 end
            if cloneBC.RightArmColor3 ~= realBC.RightArmColor3 then cloneBC.RightArmColor3 = realBC.RightArmColor3 end
            if cloneBC.LeftLegColor3 ~= realBC.LeftLegColor3 then cloneBC.LeftLegColor3 = realBC.LeftLegColor3 end
            if cloneBC.RightLegColor3 ~= realBC.RightLegColor3 then cloneBC.RightLegColor3 = realBC.RightLegColor3 end
        end
    elseif cloneBC then
        pcall(function() cloneBC:Destroy() end)
    end
end

local faceControlProperties = {
    "ChinRaiser", "ChinRaiserUpper", "Corrugator", "EyesLookDown", "EyesLookLeft",
    "EyesLookRight", "EyesLookUp", "FlatPucker", "Frown", "JawDrop", "JawLeft",
    "JawRight", "LeftBlink", "LeftCheekPuff", "LeftCheekRaiser", "LeftDimpler",
    "LeftEyeClosed", "LeftEyeUpperLidRaiser", "LeftInnerBrowRaiser", "LeftLipCornerDown",
    "LeftLipCornerPuller", "LeftLipStretcher", "LeftLowerLipDepressor", "LeftNoseWrinkler",
    "LeftOuterBrowRaiser", "LeftUpperLipRaiser", "LipPresser", "LipsTogether",
    "LowerLipSuck", "MouthLeft", "MouthRight", "Pucker", "RightBlink", "RightCheekPuff",
    "RightCheekRaiser", "RightDimpler", "RightEyeClosed", "RightEyeUpperLidRaiser",
    "RightInnerBrowRaiser", "RightLipCornerDown", "RightLipCornerPuller", "RightLipStretcher",
    "RightLowerLipDepressor", "RightNoseWrinkler", "RightOuterBrowRaiser", "RightUpperLipRaiser",
    "TongueDown", "TongueOut", "TongueUp", "UpperLipSuck"
}

local function refreshPreviewTrackedInstances(realChar, cloneChar)
    if not realChar or not cloneChar then return end
    
    -- 0. Prune stale or destroyed parts from previewPartMap
    for realPart, clonePart in pairs(previewPartMap) do
        if not realPart or not realPart.Parent or not realPart:IsDescendantOf(game) then
            previewPartMap[realPart] = nil
            if clonePart and clonePart.Parent then
                pcall(function() clonePart:Destroy() end)
            end
        end
    end
    
    -- Prune empty accessories, tools, or folders in cloneChar
    for _, child in ipairs(cloneChar:GetChildren()) do
        if (child:IsA("Accessory") or child:IsA("Tool") or child:IsA("Folder")) and #child:GetChildren() == 0 then
            pcall(function() child:Destroy() end)
        end
    end
    
    local allParts = getAllRealCharacterParts(realChar)
    previewTrackedParts = {}
    
    for _, realDesc in ipairs(allParts) do
        if realDesc:IsA("BasePart") then
            local cloneDesc = previewPartMap[realDesc] or getOrCreateMatchingPartInClone(realDesc, cloneChar)
            if cloneDesc and cloneDesc:IsA("BasePart") then
                local realMesh = realDesc:FindFirstChildOfClass("SpecialMesh")
                local cloneMesh = cloneDesc:FindFirstChildOfClass("SpecialMesh")
                if realMesh and not cloneMesh then
                    pcall(function()
                        realMesh.Archivable = true
                        local newMesh = realMesh:Clone()
                        if not newMesh then
                            newMesh = Instance.new("SpecialMesh")
                            newMesh.MeshType = realMesh.MeshType
                            newMesh.MeshId = realMesh.MeshId
                            newMesh.TextureId = realMesh.TextureId
                            newMesh.Scale = realMesh.Scale
                            newMesh.Offset = realMesh.Offset
                            newMesh.VertexColor = realMesh.VertexColor
                        end
                        if newMesh then newMesh.Parent = cloneDesc; cloneMesh = newMesh end
                    end)
                end
                
                -- SurfaceAppearance synchronization
                local realSA = realDesc:FindFirstChildOfClass("SurfaceAppearance")
                local cloneSA = cloneDesc:FindFirstChildOfClass("SurfaceAppearance")
                if realSA and not cloneSA then
                    pcall(function()
                        realSA.Archivable = true
                        local newSA = realSA:Clone()
                        if newSA then newSA.Parent = cloneDesc end
                    end)
                elseif not realSA and cloneSA then
                    pcall(function() cloneSA:Destroy() end)
                end
                
                -- Body decals and textures
                for _, d in ipairs(realDesc:GetChildren()) do
                    if (d:IsA("Decal") or d:IsA("Texture")) and d.Name ~= "face" then
                        local cd = cloneDesc:FindFirstChild(d.Name)
                        if not cd or cd.ClassName ~= d.ClassName then
                            pcall(function()
                                d.Archivable = true
                                local newD = d:Clone()
                                if newD then newD.Parent = cloneDesc end
                            end)
                        end
                    end
                end
                
                table.insert(previewTrackedParts, {
                    real = realDesc,
                    clone = cloneDesc,
                    isHRP = (realDesc.Name == "HumanoidRootPart"),
                    hasMesh = (realMesh ~= nil or cloneMesh ~= nil or realDesc:IsA("MeshPart") or cloneDesc:IsA("MeshPart") or realDesc:FindFirstChildOfClass("SpecialMesh") ~= nil),
                    isMeshPart = realDesc:IsA("MeshPart") and cloneDesc:IsA("MeshPart")
                })
            end
        end
    end
    
    -- Cache Bones once without FindFirstChild(..., true) inside the render loop
    previewTrackedBones = {}
    local seenBones = {}
    local function addTrackedBone(b)
        if b and b:IsA("Bone") and not seenBones[b] then
            seenBones[b] = true
            local cloneBone = previewBoneMap[b] or cloneChar:FindFirstChild(b.Name, true)
            if cloneBone and cloneBone:IsA("Bone") then
                previewBoneMap[b] = cloneBone
                table.insert(previewTrackedBones, { real = b, clone = cloneBone })
            end
        end
    end
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("Bone") then addTrackedBone(desc) end
    end
    for _, item in ipairs(previewTrackedParts) do
        for _, desc in ipairs(item.real:GetDescendants()) do
            if desc:IsA("Bone") then addTrackedBone(desc) end
        end
    end
    
    -- Cache Motors once
    previewTrackedMotors = {}
    local seenMotors = {}
    local function addTrackedMotor(m)
        if m and m:IsA("Motor6D") and not seenMotors[m] then
            seenMotors[m] = true
            local cloneMotor = previewMotorMap[m] or cloneChar:FindFirstChild(m.Name, true)
            if cloneMotor and cloneMotor:IsA("Motor6D") then
                previewMotorMap[m] = cloneMotor
                table.insert(previewTrackedMotors, { real = m, clone = cloneMotor })
            end
        end
    end
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("Motor6D") then addTrackedMotor(desc) end
    end
    for _, item in ipairs(previewTrackedParts) do
        for _, desc in ipairs(item.real:GetDescendants()) do
            if desc:IsA("Motor6D") then addTrackedMotor(desc) end
        end
    end
    
    -- CharacterMesh synchronization
    for _, realCM in ipairs(realChar:GetChildren()) do
        if realCM:IsA("CharacterMesh") then
            local cloneCM = cloneChar:FindFirstChild(realCM.Name)
            if not cloneCM or not cloneCM:IsA("CharacterMesh") then
                pcall(function()
                    realCM.Archivable = true
                    local newCM = realCM:Clone()
                    if newCM then newCM.Parent = cloneChar end
                end)
            else
                if cloneCM.MeshId ~= realCM.MeshId then cloneCM.MeshId = realCM.MeshId end
                if cloneCM.OverlayTextureId ~= realCM.OverlayTextureId then cloneCM.OverlayTextureId = realCM.OverlayTextureId end
                if cloneCM.BaseTextureId ~= realCM.BaseTextureId then cloneCM.BaseTextureId = realCM.BaseTextureId end
                if cloneCM.BodyPart ~= realCM.BodyPart then cloneCM.BodyPart = realCM.BodyPart end
            end
        end
    end
    for _, cloneCM in ipairs(cloneChar:GetChildren()) do
        if cloneCM:IsA("CharacterMesh") then
            if not realChar:FindFirstChild(cloneCM.Name) then
                pcall(function() cloneCM:Destroy() end)
            end
        end
    end
    
    previewTrackedDirty = false
end

local function syncPreviewPose(realChar, cloneChar)
    local realHRP = realChar:FindFirstChild("HumanoidRootPart") or realChar:FindFirstChild("Torso") or realChar.PrimaryPart
    if not realHRP or not cloneChar then return end
    
    local realRootCF = realHRP.CFrame
    local now = os.clock()
    
    -- Refresh tracked instances only when hierarchy changes or throttled check (1.0s)
    if previewTrackedDirty or (now - lastPreviewScanTime > 1.0) then
        refreshPreviewTrackedInstances(realChar, cloneChar)
        lastPreviewScanTime = now
    end
    
    -- 1. Synchronize all BaseParts (FAST: directly from cached table, zero FindFirstChild / GetDescendants)
    for i = 1, #previewTrackedParts do
        local item = previewTrackedParts[i]
        local realDesc, cloneDesc = item.real, item.clone
        if realDesc.Parent and cloneDesc.Parent then
            local relCF = realRootCF:ToObjectSpace(realDesc.CFrame)
            cloneDesc.CFrame = relCF
            
            local targetTransparency = realDesc.Transparency
            if item.isHRP or realDesc.Name == "HumanoidRootPart" or (realDesc.Name:lower():find("root") and targetTransparency >= 0.95) then
                targetTransparency = 1
            end
            
            if cloneDesc.Transparency ~= targetTransparency then cloneDesc.Transparency = targetTransparency end
            if cloneDesc.Color ~= realDesc.Color then cloneDesc.Color = realDesc.Color end
            if cloneDesc.Material ~= realDesc.Material then cloneDesc.Material = realDesc.Material end
            if cloneDesc.Reflectance ~= realDesc.Reflectance then cloneDesc.Reflectance = realDesc.Reflectance end
            if cloneDesc.Size ~= realDesc.Size then cloneDesc.Size = realDesc.Size end
            
            if cloneDesc:IsA("MeshPart") and realDesc:IsA("MeshPart") then
                if cloneDesc.TextureID ~= realDesc.TextureID then
                    cloneDesc.TextureID = realDesc.TextureID
                end
            else
                local sm = cloneDesc:FindFirstChildOfClass("SpecialMesh")
                if sm then
                    local realSM = realDesc:FindFirstChildOfClass("SpecialMesh")
                    if realSM then
                        if sm.TextureId ~= realSM.TextureId then sm.TextureId = realSM.TextureId end
                        if sm.MeshId ~= realSM.MeshId then sm.MeshId = realSM.MeshId end
                        if sm.Scale ~= realSM.Scale then sm.Scale = realSM.Scale end
                        if sm.Offset ~= realSM.Offset then sm.Offset = realSM.Offset end
                    elseif realDesc:IsA("MeshPart") then
                        if sm.TextureId ~= realDesc.TextureID then sm.TextureId = realDesc.TextureID end
                        if sm.MeshId ~= realDesc.MeshId then sm.MeshId = realDesc.MeshId end
                    end
                end
            end
        end
    end
    
    -- 2. Synchronize Skinned Mesh Bones (FAST: direct array iteration!)
    for i = 1, #previewTrackedBones do
        local b = previewTrackedBones[i]
        b.clone.Transform = b.real.Transform
    end
    
    -- 3. Synchronize Motor6D Keyframe Transforms (FAST: direct array iteration!)
    for i = 1, #previewTrackedMotors do
        local m = previewTrackedMotors[i]
        m.clone.Transform = m.real.Transform
    end
    
    -- 4. Synchronize Facial Expressions & Face Decals
    local realHead = realChar:FindFirstChild("Head")
    local cloneHead = cloneChar:FindFirstChild("Head")
    if realHead and cloneHead then
        local realFC = realHead:FindFirstChildOfClass("FaceControls")
        local cloneFC = cloneHead:FindFirstChildOfClass("FaceControls")
        if realFC and cloneFC then
            for _, prop in ipairs(faceControlProperties) do
                pcall(function()
                    cloneFC[prop] = realFC[prop]
                end)
            end
        end
        
        local realFace = realHead:FindFirstChild("face") or realHead:FindFirstChildOfClass("Decal")
        local cloneFace = cloneHead:FindFirstChild("face") or cloneHead:FindFirstChildOfClass("Decal")
        
        if realFace and cloneFace then
            if cloneFace.Texture ~= realFace.Texture then cloneFace.Texture = realFace.Texture end
            if cloneFace.Transparency ~= realFace.Transparency then cloneFace.Transparency = realFace.Transparency end
            if cloneFace.Color3 ~= realFace.Color3 then cloneFace.Color3 = realFace.Color3 end
        elseif cloneFace and not realFace then
            cloneFace.Transparency = 1
        end
        
        if realFC or realHead:FindFirstChildOfClass("SurfaceAppearance") then
            if not realFace or realFace.Transparency >= 0.9 or realFace.Texture == "" then
                if cloneFace then cloneFace.Transparency = 1 end
            end
        end
    end
    
    -- 5. Synchronize Clothing & Body Colors live
    syncClothingAndColors(realChar, cloneChar)
end

-- Mathematically exact 3D perspective projection for ViewportFrames
local function worldToViewportPoint(cam, worldPos, vpSize)
    if not cam or not worldPos or not vpSize or vpSize.X <= 0 or vpSize.Y <= 0 then
        return Vector2.zero, false
    end
    
    local pCam = cam.CFrame:PointToObjectSpace(worldPos)
    if pCam.Z >= -0.05 then
        return Vector2.zero, false
    end
    
    local fovRad = math.rad(cam.FieldOfView or 50)
    local aspect = vpSize.X / vpSize.Y
    local halfHeight = math.tan(fovRad / 2) * -pCam.Z
    local halfWidth = halfHeight * aspect
    
    if halfHeight <= 0 or halfWidth <= 0 then
        return Vector2.zero, false
    end
    
    local normX = pCam.X / halfWidth
    local normY = pCam.Y / halfHeight
    
    local screenX = (normX * 0.5 + 0.5) * vpSize.X
    local screenY = (-normY * 0.5 + 0.5) * vpSize.Y
    
    return Vector2.new(screenX, screenY), true
end

local function createLineFrame(parent, color, thickness)
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.ZIndex = 10
    line.Parent = parent
    return line
end

local function drawUILine(lineFrame, p1, p2, color, thickness)
    if not lineFrame or not p1 or not p2 then return end
    local dist = (p2 - p1).Magnitude
    if dist < 0.5 then
        lineFrame.Visible = false
        return
    end
    local center = (p1 + p2) / 2
    local angle = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
    
    lineFrame.Size = UDim2.new(0, dist, 0, thickness or 1.5)
    lineFrame.Position = UDim2.new(0, center.X, 0, center.Y)
    lineFrame.Rotation = angle
    if color then lineFrame.BackgroundColor3 = color end
    lineFrame.Visible = true
end

-- Two-way module synchronizer between preview chips and WASOR main menu
local function toggleFeatureSync(modName, configKey)
    local newVal = not S[configKey]
    if ESPSync then
        ESPSync:Set(configKey, newVal, "ESPPreviewHUD")
    else
        S[configKey] = newVal
        saveConfig()
    end
    if UI.moduleButtons and UI.moduleButtons[modName] then
        pcall(function()
            UI.moduleButtons[modName].SetActive(newVal)
        end)
    end
end

local function initESPPreviewUI()
    if previewInitialized and previewFrame and previewFrame.Parent then return end
    previewInitialized = true
    
    local existingGui = getGuiParent():FindFirstChild("WASOR_ESPPreviewGui")
    if existingGui then
        pcall(function() existingGui:Destroy() end)
    end
    if previewFrame and previewFrame.Parent then
        pcall(function() previewFrame:Destroy() end)
        previewFrame = nil
    end
    
    local parentGui = Instance.new("ScreenGui")
    parentGui.Name = "WASOR_ESPPreviewGui"
    parentGui.ResetOnSpawn = false
    parentGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentGui.Parent = getGuiParent()
    
    -- Main Preview Window
    previewFrame = Instance.new("Frame")
    previewFrame.Name = "ESPPreviewWindow"
    previewFrame.Size = UDim2.new(0, 300, 0, 390)
    previewFrame.Position = UDim2.new(0.5, -150, 0.5, -195)
    previewFrame.BackgroundColor3 = StudioTheme.windowBg
    previewFrame.BorderSizePixel = 1
    previewFrame.BorderColor3 = StudioTheme.border
    previewFrame.ClipsDescendants = true
    previewFrame.Visible = false
    previewFrame.Parent = parentGui
    
    -- Header Bar
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = StudioTheme.headerBg
    header.BorderSizePixel = 1
    header.BorderColor3 = StudioTheme.border
    header.Parent = previewFrame
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = StudioTheme.text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "ESP Live Visual Preview"
    titleLbl.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 1, 0)
    closeBtn.Position = UDim2.new(1, -24, 0, 0)
    closeBtn.BackgroundColor3 = StudioTheme.headerBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = StudioTheme.textMuted
    closeBtn.Text = "X"
    closeBtn.Parent = header
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 60); closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = StudioTheme.headerBg; closeBtn.TextColor3 = StudioTheme.textMuted end)
    closeBtn.MouseButton1Click:Connect(function()
        previewFrame.Visible = false
        S.ESPPreviewActive = false
        saveConfig()
    end)
    
    -- Draggable Window
    local dragging, dragStart, startPos = false, Vector3.zero, UDim2.new()
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = previewFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            previewFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Viewport Frame Container
    local vpContainer = Instance.new("Frame")
    vpContainer.Size = UDim2.new(1, -12, 0, 245)
    vpContainer.Position = UDim2.new(0, 6, 0, 28)
    vpContainer.BackgroundColor3 = StudioTheme.insetBg
    vpContainer.BorderSizePixel = 1
    vpContainer.BorderColor3 = StudioTheme.border
    vpContainer.ClipsDescendants = true
    vpContainer.Parent = previewFrame
    
    viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.ClipsDescendants = true
    viewport.LightColor = Color3.fromRGB(240, 240, 240)
    viewport.Ambient = Color3.fromRGB(180, 180, 180)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.Parent = vpContainer
    
    previewWorld = Instance.new("WorldModel")
    previewWorld.Parent = viewport
    
    previewCamera = Instance.new("Camera")
    previewCamera.FieldOfView = 50
    viewport.CurrentCamera = previewCamera
    previewCamera.Parent = viewport
    
    -- ESP Overlay Container (inside vpContainer)
    espContainer = Instance.new("Frame")
    espContainer.Size = UDim2.new(1, 0, 1, 0)
    espContainer.BackgroundTransparency = 1
    espContainer.ZIndex = 5
    espContainer.Parent = vpContainer
    
    -- Empty State Hint Label (shown if all ESP modules are off)
    emptyHintLabel = Instance.new("TextLabel")
    emptyHintLabel.Size = UDim2.new(1, -20, 0, 28)
    emptyHintLabel.Position = UDim2.new(0, 10, 1, -34)
    emptyHintLabel.BackgroundTransparency = 0.4
    emptyHintLabel.BackgroundColor3 = StudioTheme.windowBg
    emptyHintLabel.BorderSizePixel = 1
    emptyHintLabel.BorderColor3 = StudioTheme.border
    emptyHintLabel.Font = Enum.Font.SourceSansSemibold
    emptyHintLabel.TextSize = 10
    emptyHintLabel.TextColor3 = StudioTheme.textMuted
    emptyHintLabel.Text = "💡 Click chips below or Render menu to enable ESP elements"
    emptyHintLabel.Visible = false
    emptyHintLabel.ZIndex = 7
    emptyHintLabel.Parent = espContainer
    
    -- ESP Overlay: Box Outline & Fill with exact GUI transparency
    previewBoxFill = Instance.new("Frame")
    previewBoxFill.BorderSizePixel = 0
    previewBoxFill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    previewBoxFill.BackgroundTransparency = S.ESPTransparency or 0.8
    previewBoxFill.Visible = false
    previewBoxFill.ZIndex = 6
    previewBoxFill.Parent = espContainer
    
    previewBoxOutline = Instance.new("UIStroke")
    previewBoxOutline.Color = Color3.fromRGB(220, 40, 40)
    previewBoxOutline.Thickness = 1.5
    previewBoxOutline.Parent = previewBoxFill
    
    -- Corner & Bracket lines (8 lines)
    for i = 1, 8 do
        previewCorners[i] = createLineFrame(espContainer, Color3.fromRGB(220, 40, 40), 1.5)
    end
    
    -- 3D Wireframe lines (12 lines)
    for i = 1, 12 do
        previewLines3D[i] = createLineFrame(espContainer, Color3.fromRGB(220, 40, 40), 1.5)
    end
    
    -- Skeleton lines (up to 20 lines)
    for i = 1, 20 do
        previewSkeletonLines[i] = createLineFrame(espContainer, Color3.fromRGB(220, 40, 40), 1.5)
    end
    
    -- Tracer Line
    previewTracer = createLineFrame(espContainer, Color3.fromRGB(220, 40, 40), 1.5)
    
    -- Line of Sight Line
    previewLosLine = createLineFrame(espContainer, Color3.fromRGB(220, 40, 40), 1.5)
    
    -- Health Bar
    previewHealthBarOutline = Instance.new("Frame")
    previewHealthBarOutline.Size = UDim2.new(0, 3, 0, 100)
    previewHealthBarOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    previewHealthBarOutline.BorderSizePixel = 0
    previewHealthBarOutline.Visible = false
    previewHealthBarOutline.ZIndex = 8
    previewHealthBarOutline.Parent = espContainer
    
    previewHealthBarFill = Instance.new("Frame")
    previewHealthBarFill.Size = UDim2.new(1, 0, 1, 0)
    previewHealthBarFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    previewHealthBarFill.BorderSizePixel = 0
    previewHealthBarFill.ZIndex = 9
    previewHealthBarFill.Parent = previewHealthBarOutline
    
    -- Name Tag
    previewNameTag = Instance.new("TextLabel")
    previewNameTag.Size = UDim2.new(0, 120, 0, 14)
    previewNameTag.AnchorPoint = Vector2.new(0.5, 1)
    previewNameTag.BackgroundTransparency = 1
    previewNameTag.Font = Enum.Font.SourceSansBold
    previewNameTag.TextSize = 11
    previewNameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    previewNameTag.Text = localPlayer.DisplayName or localPlayer.Name
    previewNameTag.Visible = false
    previewNameTag.ZIndex = 10
    previewNameTag.Parent = espContainer
    
    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = Color3.fromRGB(0, 0, 0)
    nameStroke.Thickness = 1
    nameStroke.Parent = previewNameTag
    
    -- Health Text
    previewHealthText = Instance.new("TextLabel")
    previewHealthText.Size = UDim2.new(0, 80, 0, 12)
    previewHealthText.AnchorPoint = Vector2.new(0.5, 0)
    previewHealthText.BackgroundTransparency = 1
    previewHealthText.Font = Enum.Font.SourceSansSemibold
    previewHealthText.TextSize = 10
    previewHealthText.TextColor3 = Color3.fromRGB(50, 220, 50)
    previewHealthText.Text = "100 HP"
    previewHealthText.Visible = false
    previewHealthText.ZIndex = 10
    previewHealthText.Parent = espContainer
    
    local hpStroke = Instance.new("UIStroke")
    hpStroke.Color = Color3.fromRGB(0, 0, 0)
    hpStroke.Thickness = 1
    hpStroke.Parent = previewHealthText
    
    -- Distance Text
    previewDistText = Instance.new("TextLabel")
    previewDistText.Size = UDim2.new(0, 80, 0, 12)
    previewDistText.AnchorPoint = Vector2.new(0.5, 0)
    previewDistText.BackgroundTransparency = 1
    previewDistText.Font = Enum.Font.SourceSans
    previewDistText.TextSize = 10
    previewDistText.TextColor3 = Color3.fromRGB(200, 200, 200)
    previewDistText.Text = "25 studs"
    previewDistText.Visible = false
    previewDistText.ZIndex = 10
    previewDistText.Parent = espContainer
    
    local distStroke = Instance.new("UIStroke")
    distStroke.Color = Color3.fromRGB(0, 0, 0)
    distStroke.Thickness = 1
    distStroke.Parent = previewDistText
    
    -- Interactive Viewport Dragging (Rotate preview)
    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingOrbit = true
            dragStartPos = input.Position
            startOrbitAngle = orbitAngle
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingOrbit = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingOrbit and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            orbitAngle = startOrbitAngle + (delta.X * 0.8)
        end
    end)
    
    -- Bottom Controls Bar
    local controlsBar = Instance.new("Frame")
    controlsBar.Size = UDim2.new(1, -12, 0, 106)
    controlsBar.Position = UDim2.new(0, 6, 1, -112)
    controlsBar.BackgroundColor3 = StudioTheme.panelBg
    controlsBar.BorderSizePixel = 1
    controlsBar.BorderColor3 = StudioTheme.border
    controlsBar.Parent = previewFrame
    
    local function makeControlBtn(text, xPos, yPos, width, height, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, width, 0, height or 22)
        b.Position = UDim2.new(0, xPos, 0, yPos)
        b.BackgroundColor3 = StudioTheme.btnBg
        b.BorderSizePixel = 1
        b.BorderColor3 = StudioTheme.border
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 11
        b.TextColor3 = StudioTheme.text
        b.Text = text
        b.Parent = controlsBar
        
        b.MouseEnter:Connect(function() b.BackgroundColor3 = StudioTheme.btnHover end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = StudioTheme.btnBg end)
        b.MouseButton1Click:Connect(callback)
        return b
    end
    
    -- Row 1: Camera Controls
    makeControlBtn("Front", 4, 3, 64, 22, function() orbitAngle = 180; autoSpin = false end)
    makeControlBtn("Back", 72, 3, 64, 22, function() orbitAngle = 0; autoSpin = false end)
    makeControlBtn("Spin 360°", 140, 3, 72, 22, function() autoSpin = not autoSpin end)
    makeControlBtn("Reset", 216, 3, 66, 22, function() orbitAngle = 180; viewDistance = 7.5; autoSpin = false end)
    
    -- Row 2: Style Cycler
    local styleLabel = Instance.new("TextLabel")
    hudStyleLabel = styleLabel
    styleLabel.Size = UDim2.new(0, 130, 0, 22)
    styleLabel.Position = UDim2.new(0, 6, 0, 28)
    styleLabel.BackgroundTransparency = 1
    styleLabel.Font = Enum.Font.SourceSansBold
    styleLabel.TextSize = 11
    styleLabel.TextColor3 = StudioTheme.text
    styleLabel.TextXAlignment = Enum.TextXAlignment.Left
    styleLabel.Text = "Style: " .. (S.ESPBoxStyle or "Full")
    styleLabel.Parent = controlsBar
    
    makeControlBtn("Next Style ►", 188, 28, 94, 22, function()
        local cur = table.find(allStyles, S.ESPBoxStyle or "Full") or 1
        local nxt = (cur % #allStyles) + 1
        local newStyle = allStyles[nxt]
        if ESPSync then
            ESPSync:Set("ESPBoxStyle", newStyle, "ESPPreviewHUD")
        else
            S.ESPBoxStyle = newStyle
            saveConfig()
        end
        styleLabel.Text = "Style: " .. newStyle
    end)
    
    -- Row 3: Two-Way Synchronized Toggle Chips
    chipRefreshers = {}
    local function makeChip(name, modName, configKey, xPos, width)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width, 0, 20)
        btn.Position = UDim2.new(0, xPos, 0, 53)
        btn.BorderSizePixel = 1
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 10
        btn.Text = name
        btn.Parent = controlsBar
        
        local function refreshChip()
            local active = (S[configKey] == true)
            btn.BackgroundColor3 = active and StudioTheme.blue or StudioTheme.btnBg
            btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted
            btn.BorderColor3 = active and Color3.fromRGB(40, 160, 255) or StudioTheme.border
        end
        refreshChip()
        table.insert(chipRefreshers, refreshChip)
        
        btn.MouseButton1Click:Connect(function()
            toggleFeatureSync(modName, configKey)
            refreshChip()
        end)
        return btn
    end
    
    makeChip("Box", "ESP Box Outlines", "ESPBoxes", 4, 36)
    makeChip("Skel", "Skeleton ESP", "SkeletonESP", 43, 36)
    makeChip("Tracer", "ESP Tracer Lines", "ESPTracers", 82, 42)
    makeChip("Health", "Show Health Text", "ESPHealth", 127, 42)
    makeChip("Name", "Show Player Names", "ESPNames", 172, 38)
    makeChip("Dist", "Show Distance Text", "ESPDistances", 213, 34)
    makeChip("LoS", "Line of Sight", "LineOfSight", 250, 30)
    
    -- Row 4: Color Quick Cycler
    local colorLabel = Instance.new("TextLabel")
    hudColorLabel = colorLabel
    colorLabel.Size = UDim2.new(0, 130, 0, 20)
    colorLabel.Position = UDim2.new(0, 6, 0, 78)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Font = Enum.Font.SourceSansSemibold
    colorLabel.TextSize = 11
    colorLabel.TextColor3 = StudioTheme.textMuted
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Text = "Color: " .. (S.ESPColor or "Team Color")
    colorLabel.Parent = controlsBar
    
    makeControlBtn("Next Color ►", 188, 78, 94, 20, function()
        local cur = table.find(colorOptions, S.ESPColor or "Team Color") or 1
        local nxt = (cur % #colorOptions) + 1
        local newColor = colorOptions[nxt]
        if ESPSync then
            ESPSync:Set("ESPColor", newColor, "ESPPreviewHUD")
        else
            S.ESPColor = newColor
            saveConfig()
        end
        colorLabel.Text = "Color: " .. newColor
    end)
    
    setupPreviewModel()
    if localPlayer.Character then
        connectPreviewCharListeners(localPlayer.Character)
    end
end

local bonesR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}
local bonesR15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function updatePreviewRender()
    if not previewFrame or not previewFrame.Visible or not previewWorld then return end
    
    local realChar = localPlayer.Character
    if not realChar then return end
    
    if not previewCharClone or not previewCharClone.Parent then
        setupPreviewModel()
        return
    end
    
    syncPreviewPose(realChar, previewCharClone)
    
    if autoSpin then
        orbitAngle = (orbitAngle + 1.2) % 360
    end
    
    local rad = math.rad(orbitAngle)
    local camPos = Vector3.new(math.sin(rad) * viewDistance, viewHeight, math.cos(rad) * viewDistance)
    previewCamera.CFrame = CFrame.new(camPos, Vector3.new(0, viewHeight, 0))
    
    local char = previewCharClone
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
    if not hrp then return end
    
    local teamCol = Color3.fromRGB(80, 160, 255)
    local espCol = espColorMapping[S.ESPColor] or teamCol
    local vpSize = viewport.AbsoluteSize
    if vpSize.X <= 0 or vpSize.Y <= 0 then return end
    
    -- Real-time synchronization of chip visuals with active configs
    if chipRefreshers then
        for _, refreshFn in ipairs(chipRefreshers) do
            refreshFn()
        end
    end
    
    -- Active module states (fully synced with all WASOR Render modules)
    local showBoxes = (S.ESPBoxes == true)
    local showSkeleton = (S.SkeletonESP == true)
    local showTracers = (S.ESPTracers == true)
    local showHealth = (S.ESPHealth == true)
    local showNames = (S.ESPNames == true)
    local showDistance = (S.ESPDistances == true)
    local showLoS = (S.LineOfSight == true)
    
    local anyFeatureActive = showBoxes or showSkeleton or showTracers or showHealth or showNames or showDistance or showLoS
    if emptyHintLabel then
        emptyHintLabel.Visible = not anyFeatureActive
    end
    
    -- Calculate 2D bounding box from model bounding box (FAST: 8 corner projections instead of 800)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyVisible = false
    
    local modelCF, modelSize = char:GetBoundingBox()
    local hw, hh, hd = modelSize.X / 2, modelSize.Y / 2, modelSize.Z / 2
    local corners = {
        modelCF * Vector3.new(-hw, hh, -hd), modelCF * Vector3.new(hw, hh, -hd),
        modelCF * Vector3.new(hw, -hh, -hd), modelCF * Vector3.new(-hw, -hh, -hd),
        modelCF * Vector3.new(-hw, hh, hd),  modelCF * Vector3.new(hw, hh, hd),
        modelCF * Vector3.new(hw, -hh, hd),  modelCF * Vector3.new(-hw, -hh, hd)
    }
    for _, pt in ipairs(corners) do
        local sp, onS = worldToViewportPoint(previewCamera, pt, vpSize)
        if onS then
            anyVisible = true
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
        end
    end
    
    -- Fallback bounding box around character center if parts are streaming
    if not anyVisible or minX >= maxX or minY >= maxY then
        local fhw, fhh, fhd = 1.6, 2.6, 1.0
        local fcorners = {
            Vector3.new(-fhw, fhh, -fhd), Vector3.new(fhw, fhh, -fhd),
            Vector3.new(fhw, -fhh, -fhd), Vector3.new(-fhw, -fhh, -fhd),
            Vector3.new(-fhw, fhh, fhd),  Vector3.new(fhw, fhh, fhd),
            Vector3.new(fhw, -fhh, fhd),  Vector3.new(-fhw, -fhh, fhd)
        }
        minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, pt in ipairs(fcorners) do
            local sp, onS = worldToViewportPoint(previewCamera, pt, vpSize)
            if onS then
                minX = math.min(minX, sp.X)
                minY = math.min(minY, sp.Y)
                maxX = math.max(maxX, sp.X)
                maxY = math.max(maxY, sp.Y)
            end
        end
    end
    
    local boxW = maxX - minX
    local boxH = maxY - minY
    local topLeft = Vector2.new(minX, minY)
    local bottomRight = Vector2.new(maxX, maxY)
    
    local boxStyle = S.ESPBoxStyle or "Full"
    local isBrackets = (boxStyle == "Bracket" or boxStyle == "Brackets")
    local isTechHex = (boxStyle == "Tech Hex" or boxStyle == "Diamond")
    local showFull = showBoxes and boxStyle == "Full"
    local showCorners = showBoxes and boxStyle == "Corners"
    local show3D = showBoxes and boxStyle == "3D Box"
    local showBracket = showBoxes and isBrackets
    local showTechHex = showBoxes and isTechHex
    local showTopBottom = showBoxes and boxStyle == "Top-Bottom"
    
    -- Box Outline & Fill with exact GUI transparency
    previewBoxFill.Size = UDim2.new(0, boxW, 0, boxH)
    previewBoxFill.Position = UDim2.new(0, minX, 0, minY)
    previewBoxFill.BackgroundColor3 = espCol
    previewBoxFill.BackgroundTransparency = math.clamp(S.ESPTransparency or 0.8, 0, 1)
    previewBoxFill.Visible = showBoxes and (S.ESPTransparency < 0.99) and (showFull or showCorners or showBracket or showTechHex or showTopBottom)
    
    previewBoxOutline.Color = espCol
    previewBoxOutline.Thickness = 1.5
    previewBoxOutline.Transparency = (showBoxes and showFull) and 0 or 1
    
    -- 1. Precision CS2 Corner Box (Corners)
    if showBoxes and showCorners then
        local len = math.clamp(math.min(boxW, boxH) * 0.22, 6, 18)
        local c = previewCorners
        local tr = Vector2.new(bottomRight.X, topLeft.Y)
        local bl = Vector2.new(topLeft.X, bottomRight.Y)
        local br = bottomRight
        -- Top-Left
        drawUILine(c[1], topLeft, topLeft + Vector2.new(len, 0), espCol, 1.5)
        drawUILine(c[2], topLeft, topLeft + Vector2.new(0, len), espCol, 1.5)
        -- Top-Right
        drawUILine(c[3], tr, tr - Vector2.new(len, 0), espCol, 1.5)
        drawUILine(c[4], tr, tr + Vector2.new(0, len), espCol, 1.5)
        -- Bottom-Left
        drawUILine(c[5], bl, bl + Vector2.new(len, 0), espCol, 1.5)
        drawUILine(c[6], bl, bl - Vector2.new(0, len), espCol, 1.5)
        -- Bottom-Right
        drawUILine(c[7], br, br - Vector2.new(len, 0), espCol, 1.5)
        drawUILine(c[8], br, br - Vector2.new(0, len), espCol, 1.5)
    -- 2. Tactical Military Brackets [ ]
    elseif showBoxes and showBracket then
        local capLen = math.clamp(boxW * 0.18, 4, 14)
        local c = previewCorners
        local tr = Vector2.new(bottomRight.X, topLeft.Y)
        local bl = Vector2.new(topLeft.X, bottomRight.Y)
        local br = bottomRight
        -- Left Bracket [
        drawUILine(c[1], topLeft, bl, espCol, 1.5)
        drawUILine(c[2], topLeft, topLeft + Vector2.new(capLen, 0), espCol, 1.5)
        drawUILine(c[3], bl, bl + Vector2.new(capLen, 0), espCol, 1.5)
        -- Right Bracket ]
        drawUILine(c[4], tr, br, espCol, 1.5)
        drawUILine(c[5], tr, tr - Vector2.new(capLen, 0), espCol, 1.5)
        drawUILine(c[6], br, br - Vector2.new(capLen, 0), espCol, 1.5)
        c[7].Visible = false; c[8].Visible = false
    -- 3. 8-Sided Futuristic Chamfered Cyber Box (Tech Hex)
    elseif showBoxes and showTechHex then
        local chamfer = math.clamp(math.min(boxW, boxH) * 0.16, 4, 14)
        local c = previewCorners
        local tr = Vector2.new(bottomRight.X, topLeft.Y)
        local bl = Vector2.new(topLeft.X, bottomRight.Y)
        local br = bottomRight
        drawUILine(c[1], topLeft + Vector2.new(chamfer, 0), tr - Vector2.new(chamfer, 0), espCol, 1.5)
        drawUILine(c[2], tr - Vector2.new(chamfer, 0), tr + Vector2.new(0, chamfer), espCol, 1.5)
        drawUILine(c[3], tr + Vector2.new(0, chamfer), br - Vector2.new(0, chamfer), espCol, 1.5)
        drawUILine(c[4], br - Vector2.new(0, chamfer), br - Vector2.new(chamfer, 0), espCol, 1.5)
        drawUILine(c[5], br - Vector2.new(chamfer, 0), bl + Vector2.new(chamfer, 0), espCol, 1.5)
        drawUILine(c[6], bl + Vector2.new(chamfer, 0), bl - Vector2.new(0, chamfer), espCol, 1.5)
        drawUILine(c[7], bl - Vector2.new(0, chamfer), topLeft + Vector2.new(0, chamfer), espCol, 1.5)
        drawUILine(c[8], topLeft + Vector2.new(0, chamfer), topLeft + Vector2.new(chamfer, 0), espCol, 1.5)
    -- 4. Clean Horizon Bars (Top-Bottom)
    elseif showBoxes and showTopBottom then
        local tickLen = math.clamp(boxH * 0.12, 3, 10)
        local c = previewCorners
        local tr = Vector2.new(bottomRight.X, topLeft.Y)
        local bl = Vector2.new(topLeft.X, bottomRight.Y)
        local br = bottomRight
        -- Top Horizon Bar
        drawUILine(c[1], topLeft, tr, espCol, 1.5)
        drawUILine(c[2], topLeft, topLeft + Vector2.new(0, tickLen), espCol, 1.5)
        drawUILine(c[3], tr, tr + Vector2.new(0, tickLen), espCol, 1.5)
        -- Bottom Horizon Bar
        drawUILine(c[4], bl, br, espCol, 1.5)
        drawUILine(c[5], bl, bl - Vector2.new(0, tickLen), espCol, 1.5)
        drawUILine(c[6], br, br - Vector2.new(0, tickLen), espCol, 1.5)
        c[7].Visible = false; c[8].Visible = false
    else
        for _, c in ipairs(previewCorners) do c.Visible = false end
    end
    
    -- 5. True 3D Wireframe Bounding Box (3D Box)
    if showBoxes and show3D then
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
        local cf = rootPart and rootPart.CFrame or CFrame.new(0, 0, 0)
        local hw, hh, hd = 1.6, 2.6, 1.0
        local v3D = {
            cf * Vector3.new(-hw, hh, -hd),  cf * Vector3.new(hw, hh, -hd),
            cf * Vector3.new(hw, -hh, -hd), cf * Vector3.new(-hw, -hh, -hd),
            cf * Vector3.new(-hw, hh, hd),   cf * Vector3.new(hw, hh, hd),
            cf * Vector3.new(hw, -hh, hd),  cf * Vector3.new(-hw, -hh, hd)
        }
        local sPoints = {}
        local ok3D = true
        for i = 1, 8 do
            local sp, onS = worldToViewportPoint(previewCamera, v3D[i], vpSize)
            if not onS then ok3D = false break end
            sPoints[i] = sp
        end
        if ok3D then
            local edges = {
                {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Top Ring
                {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Bottom Ring
                {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Vertical Pillars
            }
            for idx, edge in ipairs(edges) do
                drawUILine(previewLines3D[idx], sPoints[edge[1]], sPoints[edge[2]], espCol, 1.5)
            end
        else
            for _, l in ipairs(previewLines3D) do l.Visible = false end
        end
    else
        for _, l in ipairs(previewLines3D) do l.Visible = false end
    end
    
    -- 6. Tracer Line
    if showTracers then
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
        local rootPos = rootPart and rootPart.Position or Vector3.new(0, 0, 0)
        local rootSP, onS = worldToViewportPoint(previewCamera, rootPos, vpSize)
        if onS then
            local originX, originY = vpSize.X / 2, vpSize.Y
            if S.TracerOrigin == "Center" then
                originY = vpSize.Y / 2
            elseif S.TracerOrigin == "Top" then
                originY = 0
            end
            drawUILine(previewTracer, Vector2.new(originX, originY), rootSP, espCol, 1.5)
        else
            previewTracer.Visible = false
        end
    else
        previewTracer.Visible = false
    end
    
    -- 7. Skeleton Bones (CS2 Joint Hierarchy)
    if showSkeleton then
        local isR15 = char:FindFirstChild("UpperTorso") ~= nil
        local bones = isR15 and bonesR15 or bonesR6
        for i, bone in ipairs(bones) do
            local part1 = char:FindFirstChild(bone[1])
            local part2 = char:FindFirstChild(bone[2])
            if part1 and part2 then
                local sp1, on1 = worldToViewportPoint(previewCamera, part1.Position, vpSize)
                local sp2, on2 = worldToViewportPoint(previewCamera, part2.Position, vpSize)
                if on1 and on2 then
                    drawUILine(previewSkeletonLines[i], sp1, sp2, espCol, 1.5)
                else
                    previewSkeletonLines[i].Visible = false
                end
            else
                previewSkeletonLines[i].Visible = false
            end
        end
        for i = #bones + 1, #previewSkeletonLines do
            previewSkeletonLines[i].Visible = false
        end
    else
        for _, l in ipairs(previewSkeletonLines) do l.Visible = false end
    end
    
    -- 8. Line of Sight (View Angle Vector)
    if showLoS then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if head then
            local startPos = head.Position
            local endPos = startPos + (head.CFrame.LookVector * 4)
            local sp1, on1 = worldToViewportPoint(previewCamera, startPos, vpSize)
            local sp2, on2 = worldToViewportPoint(previewCamera, endPos, vpSize)
            if on1 and on2 then
                drawUILine(previewLosLine, sp1, sp2, espCol, 1.5)
            else
                previewLosLine.Visible = false
            end
        else
            previewLosLine.Visible = false
        end
    else
        previewLosLine.Visible = false
    end
    
    -- 9. Pro Health Bar
    if showHealth then
        previewHealthBarOutline.Position = UDim2.new(0, minX - 6, 0, minY)
        previewHealthBarOutline.Size = UDim2.new(0, 3, 0, boxH)
        previewHealthBarOutline.Visible = true
        previewHealthBarFill.Size = UDim2.new(1, 0, 1, 0)
    else
        previewHealthBarOutline.Visible = false
    end
    
    -- 10. DisplayName Tag
    if showNames then
        previewNameTag.Position = UDim2.new(0, minX + boxW / 2, 0, minY - 4)
        previewNameTag.Text = localPlayer.DisplayName or localPlayer.Name
        previewNameTag.Visible = true
    else
        previewNameTag.Visible = false
    end
    
    -- 11. Health Text & Distance Text
    if showHealth then
        previewHealthText.Position = UDim2.new(0, minX + boxW / 2, 0, maxY + 2)
        previewHealthText.Visible = true
    else
        previewHealthText.Visible = false
    end
    
    if showDistance then
        local yOffset = showHealth and 14 or 2
        previewDistText.Position = UDim2.new(0, minX + boxW / 2, 0, maxY + yOffset)
        previewDistText.Visible = true
    else
        previewDistText.Visible = false
    end
end

local function toggleESPPreview(v)
    S.ESPPreviewActive = v
    saveConfig()
    if v then
        initESPPreviewUI()
        setupPreviewModel()
        if previewFrame then previewFrame.Visible = true end
        pcall(function()
            RunService:UnbindFromRenderStep("VoidESPPreviewUpdate")
        end)
        RunService:BindToRenderStep("VoidESPPreviewUpdate", Enum.RenderPriority.Camera.Value + 2, updatePreviewRender)
    else
        if previewFrame then previewFrame.Visible = false end
        pcall(function()
            RunService:UnbindFromRenderStep("VoidESPPreviewUpdate")
        end)
    end
end

VH.openESPPreview = function()
    toggleESPPreview(true)
end

-- Respawn listener to re-clone local avatar
if localPlayer then
    localPlayer.CharacterAdded:Connect(function(newChar)
        connectPreviewCharListeners(newChar)
        if S.ESPPreviewActive and previewFrame and previewFrame.Visible then
            task.wait(0.5)
            setupPreviewModel()
        end
    end)
end

registerModule("Render", "ESP Preview", 440, 50, true, S.ESPPreviewActive, function(v)
    if ESPSync then
        ESPSync:Set("ESPPreviewActive", v, "ESPPreview")
    else
        S.ESPPreviewActive = v
        saveConfig()
    end
    toggleESPPreview(v)
end, function(drawer)
    addButtonOption(drawer, "Open Floating Preview Window", function()
        toggleESPPreview(true)
    end)
    previewBoxStyleDropdown = addDropdownOption(drawer, "Preview Box Style", allStyles, table.find(allStyles, S.ESPBoxStyle) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("ESPBoxStyle", opt, "ESPPreviewDrawer")
        else
            S.ESPBoxStyle = opt
            saveConfig()
        end
        if hudStyleLabel then hudStyleLabel.Text = "Style: " .. opt end
    end)
    previewColorDropdown = addDropdownOption(drawer, "Preview ESP Color", colorOptions, table.find(colorOptions, S.ESPColor) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("ESPColor", opt, "ESPPreviewDrawer")
        else
            S.ESPColor = opt
            saveConfig()
        end
        if hudColorLabel then hudColorLabel.Text = "Color: " .. opt end
    end)
    previewTracerOriginDropdown = addDropdownOption(drawer, "Tracer Origin", tracerOrigins, table.find(tracerOrigins, S.TracerOrigin) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("TracerOrigin", opt, "ESPPreviewDrawer")
        else
            S.TracerOrigin = opt
            saveConfig()
        end
    end)
    previewTransparencySlider = addSliderOption(drawer, "Box Transparency (%)", 0, 100, (S.ESPTransparency or 0.8) * 100, function(v)
        if ESPSync then
            ESPSync:Set("ESPTransparency", v / 100, "ESPPreviewDrawer")
        else
            S.ESPTransparency = v / 100
            saveConfig()
        end
        if previewBoxFill then previewBoxFill.BackgroundTransparency = v / 100 end
    end)
    addToggleOption(drawer, "Auto 360 Spin", autoSpin, function(v)
        autoSpin = v
    end)
    addKeybindOption(drawer, "Preview Toggle Key", S.ESPPreviewKey or Enum.KeyCode.Unknown, function(k)
        S.ESPPreviewKey = k
        saveConfig()
    end)
end, false)

if ESPSync then
    ESPSync:Register("ESPBoxStyle", function(val, source)
        if source ~= "ESPPreviewDrawer" and previewBoxStyleDropdown and previewBoxStyleDropdown.Set then
            previewBoxStyleDropdown.Set(val or "Full")
        end
        if hudStyleLabel then
            hudStyleLabel.Text = "Style: " .. (val or "Full")
        end
    end)
    
    ESPSync:Register("ESPColor", function(val, source)
        if source ~= "ESPPreviewDrawer" and previewColorDropdown and previewColorDropdown.Set then
            previewColorDropdown.Set(val or "Team Color")
        end
        if hudColorLabel then
            hudColorLabel.Text = "Color: " .. (val or "Team Color")
        end
    end)
    
    ESPSync:Register("TracerOrigin", function(val, source)
        if source ~= "ESPPreviewDrawer" and previewTracerOriginDropdown and previewTracerOriginDropdown.Set then
            previewTracerOriginDropdown.Set(val or "Bottom")
        end
    end)
    
    ESPSync:Register("ESPTransparency", function(val, source)
        if source ~= "ESPPreviewDrawer" and previewTransparencySlider and previewTransparencySlider.Set then
            previewTransparencySlider.Set(math.round((val or 0.8) * 100))
        end
        if previewBoxFill then
            previewBoxFill.BackgroundTransparency = val or 0.8
        end
    end)
    
    local function syncChip(val, source)
        if chipRefreshers then
            for _, ref in ipairs(chipRefreshers) do
                pcall(ref)
            end
        end
    end
    ESPSync:Register("ESPBoxes", syncChip)
    ESPSync:Register("SkeletonESP", syncChip)
    ESPSync:Register("ESPTracers", syncChip)
    ESPSync:Register("ESPHealth", syncChip)
    ESPSync:Register("ESPNames", syncChip)
    ESPSync:Register("ESPDistances", syncChip)
    ESPSync:Register("LineOfSight", syncChip)
    
    ESPSync:Register("ESPPreviewActive", function(val, source)
        if source ~= "ESPPreview" and UI.moduleButtons and UI.moduleButtons["ESP Preview"] and UI.moduleButtons["ESP Preview"].SetActive then
            UI.moduleButtons["ESP Preview"].SetActive(val)
        end
    end)
end
