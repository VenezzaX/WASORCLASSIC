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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

local hudScreenGui = nil
local hudFrame = nil
local viewport = nil
local worldModel = nil
local dollCamera = nil
local dollCharClone = nil
local dollInitialized = false
local viewToggleBtn = nil

local isDraggingHUD = false
local dragStartPos = Vector2.zero
local frameStartPos = UDim2.new()

local animTime = 0
local currentFadeAlpha = 1.0
local isMoving = false

local appearanceConnection = nil
local descendantConnection = nil
local descendantRemovingConnection = nil
local toolAddedConnection = nil
local toolRemovedConnection = nil
local wsChildConnection = nil
local camChildConnection = nil

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

local dollPartMap = {}
local dollBoneMap = {}
local dollMotorMap = {}

local dollTrackedParts = {}
local dollTrackedBones = {}
local dollTrackedMotors = {}
local dollTrackedDirty = true
local lastDollScanTime = 0

local function sanitizeCharacterForDoll(char)
    if not char then return nil end
    makeModelArchivable(char)
    
    dollPartMap = {}
    dollBoneMap = {}
    dollMotorMap = {}
    dollTrackedParts = {}
    dollTrackedBones = {}
    dollTrackedMotors = {}
    dollTrackedDirty = true
    lastDollScanTime = 0
    
    local id = 0
    for _, desc in ipairs(char:GetDescendants()) do
        id = id + 1
        desc:SetAttribute("WasorDollId", id)
    end
    
    local clone = char:Clone()
    if not clone then
        for _, desc in ipairs(char:GetDescendants()) do
            desc:SetAttribute("WasorDollId", nil)
        end
        return nil
    end
    clone.Name = "PaperDollAvatar"
    
    local cloneMap = {}
    for _, desc in ipairs(clone:GetDescendants()) do
        local cid = desc:GetAttribute("WasorDollId")
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
        local cid = desc:GetAttribute("WasorDollId")
        if cid and cloneMap[cid] then
            local clonedObj = cloneMap[cid]
            if desc:IsA("BasePart") then
                dollPartMap[desc] = clonedObj
            elseif desc:IsA("Bone") then
                dollBoneMap[desc] = clonedObj
            elseif desc:IsA("Motor6D") then
                dollMotorMap[desc] = clonedObj
            end
        end
        desc:SetAttribute("WasorDollId", nil)
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

local function setupDollModel()
    if dollCharClone then
        pcall(function() dollCharClone:Destroy() end)
        dollCharClone = nil
    end
    if worldModel then
        pcall(function()
            for _, child in ipairs(worldModel:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
    dollPartMap = {}
    dollBoneMap = {}
    dollMotorMap = {}
    dollTrackedParts = {}
    dollTrackedBones = {}
    dollTrackedMotors = {}
    dollTrackedDirty = true
    lastDollScanTime = 0
    if not worldModel then return end
    
    local char = localPlayer.Character
    if char then
        dollCharClone = sanitizeCharacterForDoll(char)
        if dollCharClone then
            dollCharClone.Parent = worldModel
            local hrp = dollCharClone:FindFirstChild("HumanoidRootPart") or dollCharClone.PrimaryPart
            if hrp then
                dollCharClone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
            end
        end
    end
end

local function connectCharListeners(char)
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
        dollTrackedDirty = true
        if S.PaperDollActive and hudFrame and hudFrame.Visible then
            setupDollModel()
        end
    end)
    
    -- Ensure incoming clientside instances are archivable so :Clone() always succeeds
    descendantConnection = char.DescendantAdded:Connect(function(desc)
        pcall(function() desc.Archivable = true end)
        dollTrackedDirty = true
        if desc:IsA("Humanoid") then
            task.delay(0.1, function()
                if S.PaperDollActive and hudFrame and hudFrame.Visible then
                    setupDollModel()
                end
            end)
        end
    end)
    
    -- Clean up removed parts immediately to prevent ghost meshes
    descendantRemovingConnection = char.DescendantRemoving:Connect(function(desc)
        dollTrackedDirty = true
        if desc:IsA("BasePart") then
            local clonePart = dollPartMap[desc]
            if clonePart then
                dollPartMap[desc] = nil
                pcall(function() clonePart:Destroy() end)
            end
        elseif desc:IsA("Accessory") or desc:IsA("Tool") or desc:IsA("Model") or desc:IsA("Folder") then
            for _, d in ipairs(desc:GetDescendants()) do
                if d:IsA("BasePart") then
                    local cp = dollPartMap[d]
                    if cp then
                        dollPartMap[d] = nil
                        pcall(function() cp:Destroy() end)
                    end
                elseif d:IsA("Bone") then
                    dollBoneMap[d] = nil
                elseif d:IsA("Motor6D") then
                    dollMotorMap[d] = nil
                end
            end
            if dollCharClone then
                local cloneCont = dollCharClone:FindFirstChild(desc.Name)
                if cloneCont then
                    pcall(function() cloneCont:Destroy() end)
                end
            end
        elseif desc:IsA("Bone") then
            dollBoneMap[desc] = nil
        elseif desc:IsA("Motor6D") then
            dollMotorMap[desc] = nil
        end
    end)
    
    toolAddedConnection = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            dollTrackedDirty = true
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
            dollTrackedDirty = true
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("BasePart") then
                    local cp = dollPartMap[d]
                    if cp then
                        dollPartMap[d] = nil
                        pcall(function() cp:Destroy() end)
                    end
                end
            end
            if dollCharClone then
                local cloneTool = dollCharClone:FindFirstChild(child.Name)
                if cloneTool then
                    pcall(function() cloneTool:Destroy() end)
                end
            end
        end
    end)
    
    pcall(function()
        wsChildConnection = Workspace.ChildAdded:Connect(function()
            dollTrackedDirty = true
        end)
    end)
    pcall(function()
        if Workspace.CurrentCamera then
            camChildConnection = Workspace.CurrentCamera.ChildAdded:Connect(function()
                dollTrackedDirty = true
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
    local existing = dollPartMap[realPart]
    if existing and existing.Parent ~= nil then
        return existing
    end
    
    -- Ensure realPart and all descendants are archivable so :Clone() succeeds
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
    
    -- Fallback: If :Clone() failed, construct part manually so custom meshes never fail!
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
    
    -- Sanitize cloned part and child objects
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
                dollPartMap[realChild] = desc
            end
        elseif desc:IsA("Bone") then
            local realBone = realPart:FindFirstChild(desc.Name, true)
            if realBone and realBone:IsA("Bone") then
                dollBoneMap[realBone] = desc
            end
        elseif desc:IsA("Motor6D") then
            local realMotor = realPart:FindFirstChild(desc.Name, true)
            if realMotor and realMotor:IsA("Motor6D") then
                dollMotorMap[realMotor] = desc
            end
        end
    end
    
    -- Resolve matching container hierarchy in cloneChar
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
    
    dollPartMap[realPart] = clonePart
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

local function refreshDollTrackedInstances(realChar, cloneChar)
    if not realChar or not cloneChar then return end
    
    -- 0. Prune stale or destroyed parts from dollPartMap
    for realPart, clonePart in pairs(dollPartMap) do
        if not realPart or not realPart.Parent or not realPart:IsDescendantOf(game) then
            dollPartMap[realPart] = nil
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
    dollTrackedParts = {}
    
    for _, realDesc in ipairs(allParts) do
        if realDesc:IsA("BasePart") then
            local cloneDesc = dollPartMap[realDesc] or getOrCreateMatchingPartInClone(realDesc, cloneChar)
            if cloneDesc and cloneDesc:IsA("BasePart") then
                local nameLower = realDesc.Name:lower()
                local isHeadOrHair = (nameLower:find("hair") ~= nil) or (nameLower:find("head") ~= nil) or (nameLower:find("face") ~= nil) or (nameLower:find("hat") ~= nil)
                if realDesc.Parent and realDesc.Parent:IsA("Accessory") then
                    local accName = realDesc.Parent.Name:lower()
                    if accName:find("hair") or accName:find("head") or accName:find("face") or accName:find("hat") then
                        isHeadOrHair = true
                    end
                end
                
                local isBackPhysicsItem = (not isHeadOrHair) and (
                    nameLower:find("cape") ~= nil or 
                    nameLower:find("tail") ~= nil or 
                    nameLower:find("wing") ~= nil
                )
                
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
                
                table.insert(dollTrackedParts, {
                    real = realDesc,
                    clone = cloneDesc,
                    isBackPhysics = isBackPhysicsItem,
                    isHRP = (realDesc.Name == "HumanoidRootPart"),
                    hasMesh = (realMesh ~= nil or cloneMesh ~= nil or realDesc:IsA("MeshPart") or cloneDesc:IsA("MeshPart") or realDesc:FindFirstChildOfClass("SpecialMesh") ~= nil),
                    isMeshPart = realDesc:IsA("MeshPart") and cloneDesc:IsA("MeshPart")
                })
            end
        end
    end
    
    -- Cache Bones once without FindFirstChild(..., true) inside the render loop
    dollTrackedBones = {}
    local seenBones = {}
    local function addTrackedBone(b)
        if b and b:IsA("Bone") and not seenBones[b] then
            seenBones[b] = true
            local cloneBone = dollBoneMap[b] or cloneChar:FindFirstChild(b.Name, true)
            if cloneBone and cloneBone:IsA("Bone") then
                dollBoneMap[b] = cloneBone
                table.insert(dollTrackedBones, { real = b, clone = cloneBone })
            end
        end
    end
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("Bone") then addTrackedBone(desc) end
    end
    for _, item in ipairs(dollTrackedParts) do
        for _, desc in ipairs(item.real:GetDescendants()) do
            if desc:IsA("Bone") then addTrackedBone(desc) end
        end
    end
    
    -- Cache Motors once
    dollTrackedMotors = {}
    local seenMotors = {}
    local function addTrackedMotor(m)
        if m and m:IsA("Motor6D") and not seenMotors[m] then
            seenMotors[m] = true
            local cloneMotor = dollMotorMap[m] or cloneChar:FindFirstChild(m.Name, true)
            if cloneMotor and cloneMotor:IsA("Motor6D") then
                dollMotorMap[m] = cloneMotor
                table.insert(dollTrackedMotors, { real = m, clone = cloneMotor })
            end
        end
    end
    for _, desc in ipairs(realChar:GetDescendants()) do
        if desc:IsA("Motor6D") then addTrackedMotor(desc) end
    end
    for _, item in ipairs(dollTrackedParts) do
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
    
    dollTrackedDirty = false
end

local function syncDollPose(realChar, cloneChar, baseOffsetCF, velocitySwayCF)
    local realHRP = realChar:FindFirstChild("HumanoidRootPart") or realChar:FindFirstChild("Torso") or realChar.PrimaryPart
    if not realHRP or not cloneChar then return end
    baseOffsetCF = baseOffsetCF or CFrame.identity
    velocitySwayCF = velocitySwayCF or CFrame.identity
    
    local realRootCF = realHRP.CFrame
    local now = os.clock()
    
    -- Refresh tracked instances only when hierarchy changes or throttled check (1.0s)
    if dollTrackedDirty or (now - lastDollScanTime > 1.0) then
        refreshDollTrackedInstances(realChar, cloneChar)
        lastDollScanTime = now
    end
    
    -- 1. Synchronize all BaseParts (FAST: directly from cached table, zero FindFirstChild / GetDescendants)
    for i = 1, #dollTrackedParts do
        local item = dollTrackedParts[i]
        local realDesc, cloneDesc = item.real, item.clone
        if realDesc.Parent and cloneDesc.Parent then
            local relCF = realRootCF:ToObjectSpace(realDesc.CFrame)
            if item.isBackPhysics then
                cloneDesc.CFrame = baseOffsetCF * relCF * velocitySwayCF
            else
                cloneDesc.CFrame = baseOffsetCF * relCF
            end
            
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
    for i = 1, #dollTrackedBones do
        local b = dollTrackedBones[i]
        b.clone.Transform = b.real.Transform
    end
    
    -- 3. Synchronize Motor6D Keyframe Transforms (FAST: direct array iteration!)
    for i = 1, #dollTrackedMotors do
        local m = dollTrackedMotors[i]
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

local viewModes = {"Front", "Back", "Follow Camera", "Follow Movement", "Spin 360"}

local function initPaperDollHUD()
    if dollInitialized and hudFrame and hudFrame.Parent then return end
    dollInitialized = true
    
    local existingGui = getGuiParent():FindFirstChild("WASOR_PaperDollHUD")
    if existingGui then
        pcall(function() existingGui:Destroy() end)
    end
    if hudFrame and hudFrame.Parent then
        pcall(function() hudFrame:Destroy() end)
        hudFrame = nil
    end
    
    local parentGui = Instance.new("ScreenGui")
    parentGui.Name = "WASOR_PaperDollHUD"
    parentGui.ResetOnSpawn = false
    parentGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentGui.Parent = getGuiParent()
    hudScreenGui = parentGui
    
    local baseW, baseH = 120, 160
    local scale = S.PaperDollScale or 1.0
    
    -- Frameless Floating Container (No Background)
    hudFrame = Instance.new("Frame")
    hudFrame.Name = "PaperDollContainer"
    hudFrame.Size = UDim2.new(0, math.round(baseW * scale), 0, math.round(baseH * scale))
    hudFrame.Position = UDim2.new(0, S.PaperDollX or 20, 0, S.PaperDollY or 60)
    hudFrame.BackgroundTransparency = 1
    hudFrame.BorderSizePixel = 0
    hudFrame.ClipsDescendants = false
    hudFrame.Visible = false
    hudFrame.Parent = hudScreenGui
    
    -- Viewport Frame for Player Model
    viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.BackgroundTransparency = 1
    viewport.BorderSizePixel = 0
    viewport.ClipsDescendants = false
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.Ambient = Color3.fromRGB(200, 200, 200)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.Parent = hudFrame
    
    worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport
    
    dollCamera = Instance.new("Camera")
    dollCamera.FieldOfView = 42
    viewport.CurrentCamera = dollCamera
    dollCamera.Parent = worldModel
    
    -- Sleek, Translucent Quick-View Switch Button
    viewToggleBtn = Instance.new("TextButton")
    viewToggleBtn.Name = "ViewToggleBtn"
    viewToggleBtn.Size = UDim2.new(0, 68, 0, 18)
    viewToggleBtn.Position = UDim2.new(0.5, -34, 1, -20)
    viewToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
    viewToggleBtn.BackgroundTransparency = 0.4
    viewToggleBtn.BorderSizePixel = 1
    viewToggleBtn.BorderColor3 = Color3.fromRGB(55, 55, 60)
    viewToggleBtn.Font = Enum.Font.SourceSansBold
    viewToggleBtn.TextSize = 10
    viewToggleBtn.TextColor3 = Color3.fromRGB(230, 230, 245)
    viewToggleBtn.Text = "⟲ " .. (S.PaperDollViewMode or "Front")
    viewToggleBtn.ZIndex = 15
    viewToggleBtn.Parent = hudFrame
    
    viewToggleBtn.MouseEnter:Connect(function()
        viewToggleBtn.BackgroundTransparency = 0.15
        viewToggleBtn.BorderColor3 = Color3.fromRGB(0, 122, 204)
    end)
    viewToggleBtn.MouseLeave:Connect(function()
        viewToggleBtn.BackgroundTransparency = 0.4
        viewToggleBtn.BorderColor3 = Color3.fromRGB(55, 55, 60)
    end)
    
    viewToggleBtn.MouseButton1Click:Connect(function()
        local cur = table.find(viewModes, S.PaperDollViewMode or "Front") or 1
        local nxt = (cur % #viewModes) + 1
        S.PaperDollViewMode = viewModes[nxt]
        viewToggleBtn.Text = "⟲ " .. S.PaperDollViewMode
        saveConfig()
    end)
    
    -- Dragging Handler for HUD positioning
    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingHUD = true
            dragStartPos = input.Position
            frameStartPos = hudFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDraggingHUD = false
                    S.PaperDollX = hudFrame.Position.X.Offset
                    S.PaperDollY = hudFrame.Position.Y.Offset
                    saveConfig()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingHUD and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            hudFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
        end
    end)
    
    setupDollModel()
    if localPlayer.Character then
        connectCharListeners(localPlayer.Character)
    end
end

local spinYaw = 0

local function updateDollStep(dt)
    if not hudFrame or not hudFrame.Visible or not worldModel then return end
    
    local realChar = localPlayer.Character
    if not realChar then return end
    
    local realHRP = realChar:FindFirstChild("HumanoidRootPart") or realChar:FindFirstChild("Torso") or realChar.PrimaryPart
    local realHum = realChar and realChar:FindFirstChildOfClass("Humanoid")
    if not realHRP then return end
    
    if not dollCharClone or not dollCharClone.Parent then
        setupDollModel()
        return
    end
    
    local currentVelocity = realHRP.AssemblyLinearVelocity
    local speed = currentVelocity.Magnitude
    local state = realHum and realHum:GetState()
    local isSneaking = (state == Enum.HumanoidStateType.Running) and (realHum.WalkSpeed < 12)
    local isJumping = (state == Enum.HumanoidStateType.Jumping)
    local isFalling = (state == Enum.HumanoidStateType.Freefall)
    local isSwimming = (state == Enum.HumanoidStateType.Swimming)
    
    isMoving = (speed > 1.5) or isJumping or isFalling or isSwimming
    
    -- Fade in/out if "Only on Movement" is enabled
    if S.PaperDollOnlyMoving then
        local targetAlpha = isMoving and 1.0 or 0.0
        currentFadeAlpha = currentFadeAlpha + (targetAlpha - currentFadeAlpha) * math.clamp(dt * 8, 0, 1)
        viewport.ImageTransparency = 1 - currentFadeAlpha
        if viewToggleBtn then
            viewToggleBtn.Visible = (currentFadeAlpha > 0.1)
        end
        if currentFadeAlpha < 0.05 then
            viewport.Visible = false
        else
            viewport.Visible = true
        end
    else
        viewport.ImageTransparency = 0
        viewport.Visible = true
        if viewToggleBtn then viewToggleBtn.Visible = true end
    end
    
    if isMoving then
        animTime = animTime + dt * (math.clamp(speed, 6, 25) / 10)
    else
        animTime = animTime + dt * 0.8
    end
    
    -- Subtle walking bob and tilt
    local bobOffset = 0
    local baseTilt = CFrame.identity
    if isMoving then
        bobOffset = math.abs(math.sin(animTime * 8)) * 0.08
    else
        bobOffset = math.sin(animTime * 2) * 0.03
    end
    
    if isSwimming then
        baseTilt = CFrame.Angles(math.rad(-60), 0, 0)
    elseif isSneaking then
        bobOffset = bobOffset - 0.2
        baseTilt = CFrame.Angles(math.rad(10), 0, 0)
    end
    
    local baseOffsetCF = CFrame.new(0, bobOffset, 0) * baseTilt
    
    -- Dynamic Physical Inertia & Mesh Physics (Capes, Hair, Tails, Wings sway with velocity)
    local localVel = realHRP.CFrame:VectorToObjectSpace(currentVelocity)
    local pitchSway = math.clamp(-localVel.Z * 0.015, -math.rad(25), math.rad(25))
    local rollSway = math.clamp(-localVel.X * 0.015, -math.rad(15), math.rad(15))
    local velocitySwayCF = CFrame.Angles(pitchSway, 0, rollSway)
    
    -- Sync 100% of character parts, meshes, bones, motors, and dynamic physics in real-time
    syncDollPose(realChar, dollCharClone, baseOffsetCF, velocitySwayCF)
    
    -- Camera Orbit & View Mode (Correct Front/Back Orientations)
    local mode = S.PaperDollViewMode or "Front"
    local yawAngle = math.pi
    
    if mode == "Front" then
        yawAngle = math.pi -- Camera in front of avatar (looking at face & chest)
    elseif mode == "Back" then
        yawAngle = 0 -- Camera behind avatar (looking at back of head & spine)
    elseif mode == "Spin 360" then
        spinYaw = (spinYaw + dt * 1.5) % (math.pi * 2)
        yawAngle = spinYaw
    elseif mode == "Follow Camera" then
        local cam = Workspace.CurrentCamera
        if cam and realHRP then
            local _, camYaw, _ = cam.CFrame:ToOrientation()
            local _, hrpYaw, _ = realHRP.CFrame:ToOrientation()
            yawAngle = (camYaw - hrpYaw)
        end
    elseif mode == "Follow Movement" then
        if realHRP and speed > 0.5 then
            local moveDir = realHRP.AssemblyLinearVelocity.Unit
            yawAngle = math.atan2(-moveDir.X, -moveDir.Z)
        else
            yawAngle = math.pi
        end
    end
    
    local dist = 7.2
    local camHeight = 0.0
    local camX = math.sin(yawAngle) * dist
    local camZ = math.cos(yawAngle) * dist
    dollCamera.CFrame = CFrame.new(Vector3.new(camX, camHeight, camZ), Vector3.new(0, 0.0, 0))
end

local function togglePaperDollHUD(v)
    S.PaperDollActive = v
    saveConfig()
    if v then
        initPaperDollHUD()
        setupDollModel()
        if hudFrame then hudFrame.Visible = true end
        pcall(function()
            RunService:BindToRenderStep("VoidPaperDollUpdate", Enum.RenderPriority.Camera.Value + 1, updateDollStep)
        end)
    else
        if hudFrame then hudFrame.Visible = false end
        pcall(function()
            RunService:UnbindFromRenderStep("VoidPaperDollUpdate")
        end)
    end
end

if localPlayer then
    localPlayer.CharacterAdded:Connect(function(newChar)
        connectCharListeners(newChar)
        if S.PaperDollActive and hudFrame and hudFrame.Visible then
            task.wait(0.5)
            setupDollModel()
        end
    end)
end

local viewModeOptions = {"Front", "Back", "Follow Camera", "Follow Movement", "Spin 360"}

registerModule("Render", "Paper DollView", 440, 50, true, S.PaperDollActive, function(v)
    togglePaperDollHUD(v)
end, function(drawer)
    addDropdownOption(drawer, "Doll View Mode", viewModeOptions, table.find(viewModeOptions, S.PaperDollViewMode or "Front") or 1, function(_, opt)
        S.PaperDollViewMode = opt
        if viewToggleBtn then viewToggleBtn.Text = "⟲ " .. opt end
        saveConfig()
    end)
    addToggleOption(drawer, "Only on Movement (MCPE)", S.PaperDollOnlyMoving, function(v)
        S.PaperDollOnlyMoving = v
        saveConfig()
    end)
    addSliderOption(drawer, "Doll HUD Scale (%)", 50, 200, math.round((S.PaperDollScale or 1.0) * 100), function(v)
        S.PaperDollScale = v / 100
        if hudFrame then
            hudFrame.Size = UDim2.new(0, math.round(120 * S.PaperDollScale), 0, math.round(160 * S.PaperDollScale))
        end
        saveConfig()
    end)
    addButtonOption(drawer, "Toggle Front / Back View", function()
        if S.PaperDollViewMode == "Front" then
            S.PaperDollViewMode = "Back"
        else
            S.PaperDollViewMode = "Front"
        end
        if viewToggleBtn then viewToggleBtn.Text = "⟲ " .. S.PaperDollViewMode end
        saveConfig()
    end)
    addButtonOption(drawer, "Reset HUD Position (Top-Left)", function()
        S.PaperDollX = 20
        S.PaperDollY = 60
        if hudFrame then
            hudFrame.Position = UDim2.new(0, 20, 0, 60)
        end
        saveConfig()
    end)
    addKeybindOption(drawer, "Paper Doll Keybind", S.PaperDollKey or Enum.KeyCode.Unknown, function(k)
        S.PaperDollKey = k
        saveConfig()
    end)
end, false)

-- Alias for backwards compatibility
if UI.moduleButtons and UI.moduleButtons["Paper DollView"] then
    UI.moduleButtons["Minecraft Paper Doll"] = UI.moduleButtons["Paper DollView"]
end
