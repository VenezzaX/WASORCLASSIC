local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace

local notify = Utils.notify
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addKeybindOption = UI.addKeybindOption
local addButtonOption = UI.addButtonOption
local saveConfig = VH.Config.saveConfig

local localPlayer = Services.LP or Players.LocalPlayer or Players.PlayerAdded:Wait()

local screenGui = nil
local viewportFrame = nil
local viewportCamera = nil
local worldModel = nil

local trackedRigs = {}
local playerConnections = {}
local characterGeneration = {}
local inputConnections = {}
local lifecycleConnections = {}
local renderStepBound = false

local AMBIENT_PRESETS = {
    ["Natural"] = Color3.fromRGB(150, 150, 150),
    ["Bright"] = Color3.fromRGB(220, 220, 220),
    ["Night Vision"] = Color3.fromRGB(60, 220, 110),
    ["High Contrast"] = Color3.fromRGB(80, 80, 80),
    ["Neon Violet"] = Color3.fromRGB(180, 90, 255),
    ["Thermal Amber"] = Color3.fromRGB(255, 160, 40)
}

local LIGHT_PRESETS = {
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Warm Sunlight"] = Color3.fromRGB(255, 240, 200),
    ["Cyan Cyber"] = Color3.fromRGB(100, 240, 255),
    ["Crimson Red"] = Color3.fromRGB(255, 90, 90)
}

local function getSafeContainer()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if get_hidden_gui then
        local ok, hg = pcall(get_hidden_gui)
        if ok and hg then return hg end
    end
    local ok, coreGui = pcall(function() return Services.CoreGui end)
    if ok and coreGui then return coreGui end
    return (Services.LP and Services.LP:FindFirstChild("PlayerGui")) or localPlayer:WaitForChild("PlayerGui")
end

-- Sanitize instances: Anchor every single physical part so accessories never fall, droop, or detach
local function sanitizeInstance(instance)
    if not instance then return end
    if instance:IsA("BasePart") then
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
        instance.CastShadow = false
        instance.Anchored = true
    end

    for _, inst in ipairs(instance:GetDescendants()) do
        if inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("Sound") or inst:IsA("TouchTransmitter") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            pcall(function() inst:Destroy() end)
        elseif inst:IsA("BasePart") then
            inst.CanCollide = false
            inst.CanTouch = false
            inst.CanQuery = false
            inst.CastShadow = false
            inst.Anchored = true
        end
    end
end

-- Sync classic clothing and BodyColors directly
local function syncClothing(origChar, clnModel)
    if not origChar or not clnModel then return end

    local clothingClasses = { "Shirt", "Pants", "ShirtGraphic", "BodyColors" }
    for _, className in ipairs(clothingClasses) do
        local origItem = origChar:FindFirstChildOfClass(className)
        local clnItem = clnModel:FindFirstChildOfClass(className)

        if origItem then
            if not clnItem then
                origItem.Archivable = true
                local ok, copy = pcall(function() return origItem:Clone() end)
                if ok and copy then
                    copy.Parent = clnModel
                end
            else
                if className == "Shirt" and clnItem.ShirtTemplate ~= origItem.ShirtTemplate then
                    clnItem.ShirtTemplate = origItem.ShirtTemplate
                elseif className == "Pants" and clnItem.PantsTemplate ~= origItem.PantsTemplate then
                    clnItem.PantsTemplate = origItem.PantsTemplate
                elseif className == "ShirtGraphic" and clnItem.Graphic ~= origItem.Graphic then
                    clnItem.Graphic = origItem.Graphic
                elseif className == "BodyColors" then
                    for _, prop in ipairs({ "HeadColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3", "TorsoColor3" }) do
                        pcall(function()
                            clnItem[prop] = origItem[prop]
                        end)
                    end
                end
            end
        elseif clnItem then
            pcall(function() clnItem:Destroy() end)
        end
    end
end

-- Resolve matching instance by relative path
local function getMatchingCloneInstance(origDescendant, origChar, clnModel)
    local path = {}
    local cur = origDescendant
    while cur and cur ~= origChar do
        table.insert(path, 1, cur.Name)
        cur = cur.Parent
    end

    local target = clnModel
    for _, name in ipairs(path) do
        target = target:FindFirstChild(name)
        if not target then return nil end
    end
    return target
end

-- Rebuild complete part-to-part synchronization map
local function rebuildSyncMap(data)
    local syncList = {}
    local origChar = data.OrigCharacter
    local clnModel = data.CloneModel
    if not origChar or not clnModel then return end

    syncClothing(origChar, clnModel)

    -- Remove any accessories or tools in the clone that no longer exist in the character
    for _, clnChild in ipairs(clnModel:GetChildren()) do
        if clnChild:IsA("Accessory") or clnChild:IsA("Tool") then
            if not origChar:FindFirstChild(clnChild.Name) then
                pcall(function() clnChild:Destroy() end)
            end
        end
    end

    -- Map all BaseParts directly by hierarchical tree path
    for _, origDesc in ipairs(origChar:GetDescendants()) do
        if origDesc:IsA("BasePart") then
            local clnPart = getMatchingCloneInstance(origDesc, origChar, clnModel)
            if clnPart and clnPart:IsA("BasePart") then
                table.insert(syncList, { orig = origDesc, cln = clnPart })
            end
        end
    end

    data.SyncList = syncList
end

local function cleanupCharacter(player)
    local data = trackedRigs[player]
    if not data then return end

    if data.Connections then
        for _, conn in ipairs(data.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(data.Connections)
    end
    if data.SyncList then
        table.clear(data.SyncList)
    end

    if data.CloneModel and data.CloneModel.Parent then
        pcall(function() data.CloneModel:Destroy() end)
    end

    trackedRigs[player] = nil
end

local function cleanupPlayer(player)
    characterGeneration[player] = nil
    cleanupCharacter(player)

    local conns = playerConnections[player]
    if conns then
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
        playerConnections[player] = nil
    end
end

local function setupCharacter(player, character)
    local currentGen = (characterGeneration[player] or 0) + 1
    characterGeneration[player] = currentGen

    cleanupCharacter(player)

    if not player:IsDescendantOf(Players) or player.Character ~= character then
        return
    end

    task.spawn(function()
        local origRoot = character:WaitForChild("HumanoidRootPart", 5) or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        local origHumanoid = character:WaitForChild("Humanoid", 5)
        if not origRoot or not origHumanoid then return end
        if characterGeneration[player] ~= currentGen then return end
        if not worldModel or not worldModel.Parent then return end

        character.Archivable = true
        for _, d in ipairs(character:GetDescendants()) do
            d.Archivable = true
        end

        local ok, clone = pcall(function() return character:Clone() end)
        if not ok or not clone then return end

        local clnRoot = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso") or clone:FindFirstChild("UpperTorso")
        local clnHumanoid = clone:FindFirstChildOfClass("Humanoid")
        if not clnRoot or not clnHumanoid then
            clone:Destroy()
            return
        end

        sanitizeInstance(clone)

        clnHumanoid.RequiresNeck = false
        clnHumanoid.BreakJointsOnDeath = false
        clnHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        pcall(function() clnHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
        clnHumanoid.PlatformStand = true
        clnHumanoid.AutoRotate = false

        local clnAnimator = clnHumanoid:FindFirstChildOfClass("Animator")
        if not clnAnimator then
            Instance.new("Animator", clnHumanoid)
        end

        clone.Parent = worldModel

        local data = {
            CloneModel = clone,
            OrigCharacter = character,
            OrigHumanoid = origHumanoid,
            OrigRoot = origRoot,
            SyncList = {},
            Connections = {},
        }

        rebuildSyncMap(data)

        -- Wipe instantly on death
        local diedConn = origHumanoid.Died:Connect(function()
            cleanupCharacter(player)
        end)
        table.insert(data.Connections, diedConn)

        -- Wipe instantly on teleport / despawn
        local ancestryConn = character.AncestryChanged:Connect(function(_, parent)
            if not parent or not character:IsDescendantOf(Workspace) then
                cleanupCharacter(player)
            end
        end)
        table.insert(data.Connections, ancestryConn)

        -- Re-clone added tools and accessories
        local descAddedConn = character.DescendantAdded:Connect(function(desc)
            if desc:IsA("Accessory") or desc:IsA("Tool") or desc:IsA("Shirt") or desc:IsA("Pants") or desc:IsA("ShirtGraphic") or desc:IsA("BodyColors") or desc:IsA("SurfaceAppearance") or desc:IsA("FaceControls") then
                task.defer(function()
                    if characterGeneration[player] ~= currentGen or not data.CloneModel or not data.CloneModel.Parent then return end

                    local existing = data.CloneModel:FindFirstChild(desc.Name)
                    if existing then
                        pcall(function() existing:Destroy() end)
                    end

                    desc.Archivable = true
                    local okC, clnItem = pcall(function() return desc:Clone() end)
                    if okC and clnItem then
                        sanitizeInstance(clnItem)
                        clnItem.Parent = data.CloneModel
                        rebuildSyncMap(data)
                    end
                end)
            elseif desc:IsA("BasePart") then
                task.defer(function()
                    if characterGeneration[player] == currentGen and data.CloneModel and data.CloneModel.Parent then
                        rebuildSyncMap(data)
                    end
                end)
            end
        end)
        table.insert(data.Connections, descAddedConn)

        local descRemovingConn = character.DescendantRemoving:Connect(function(desc)
            if desc:IsA("Accessory") or desc:IsA("Tool") or desc:IsA("Shirt") or desc:IsA("Pants") or desc:IsA("BasePart") then
                task.defer(function()
                    if characterGeneration[player] ~= currentGen or not data.CloneModel or not data.CloneModel.Parent then return end
                    local target = data.CloneModel:FindFirstChild(desc.Name)
                    if target then
                        pcall(function() target:Destroy() end)
                    end
                    rebuildSyncMap(data)
                end)
            end
        end)
        table.insert(data.Connections, descRemovingConn)

        local appearanceConn = player.CharacterAppearanceLoaded:Connect(function(loadedChar)
            if loadedChar == character and characterGeneration[player] == currentGen then
                task.wait(0.2)
                if characterGeneration[player] == currentGen then
                    setupCharacter(player, loadedChar)
                end
            end
        end)
        table.insert(data.Connections, appearanceConn)

        trackedRigs[player] = data
    end)
end

local function trackPlayer(player)
    if player == localPlayer then return end

    playerConnections[player] = {}

    local charAddedConn = player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
    table.insert(playerConnections[player], charAddedConn)

    local charRemovingConn = player.CharacterRemoving:Connect(function()
        cleanupCharacter(player)
    end)
    table.insert(playerConnections[player], charRemovingConn)

    if player.Character and player.Character:IsDescendantOf(Workspace) then
        setupCharacter(player, player.Character)
    end
end

local function updateViewportLighting()
    if not viewportFrame then return end
    local amb = AMBIENT_PRESETS[S.ViewportESPAmbient] or AMBIENT_PRESETS["Natural"]
    viewportFrame.Ambient = amb

    local lt = LIGHT_PRESETS[S.ViewportESPLightColor] or LIGHT_PRESETS["White"]
    viewportFrame.LightColor = lt

    local opacity = S.ViewportESPOpacity or 100
    viewportFrame.ImageTransparency = math.clamp((100 - opacity) / 100, 0, 1)
end

local function onRenderStep()
    if not S.ViewportESP or not State.uiRunning or not viewportFrame or not viewportCamera then
        return
    end

    local currentCamera = Workspace.CurrentCamera or Services.Camera
    if not currentCamera then return end

    viewportCamera.CFrame = currentCamera.CFrame
    viewportCamera.FieldOfView = currentCamera.FieldOfView

    local camLook = currentCamera.CFrame.LookVector
    local camRight = currentCamera.CFrame.RightVector
    local camUp = currentCamera.CFrame.UpVector
    viewportFrame.LightDirection = (camLook * 0.7 + camRight * 0.4 - camUp * 0.6).Unit

    local activeCloneModels = {}
    local skipTeammates = S.ViewportESPSkipTeam or S.SkipTeammates
    local myTeam = localPlayer.Team

    for player, data in pairs(trackedRigs) do
        local origChar = data.OrigCharacter
        local origHum = data.OrigHumanoid
        local clnModel = data.CloneModel

        local isTeammate = skipTeammates and (myTeam and player.Team and myTeam == player.Team)

        if not isTeammate
            and player:IsDescendantOf(Players)
            and origChar 
            and origChar.Parent 
            and origChar:IsDescendantOf(Workspace) 
            and origHum 
            and origHum.Health > 0 
            and clnModel 
            and clnModel.Parent then
            
            activeCloneModels[clnModel] = true

            local syncList = data.SyncList
            if syncList then
                for i = 1, #syncList do
                    local pair = syncList[i]
                    if pair.orig and pair.orig.Parent and pair.cln and pair.cln.Parent then
                        pair.cln.CFrame = pair.orig.CFrame
                    end
                end
            end
        else
            if not isTeammate then
                cleanupCharacter(player)
            end
        end
    end

    -- Destroy any orphan models that lost their player association
    if worldModel then
        for _, model in ipairs(worldModel:GetChildren()) do
            if not activeCloneModels[model] then
                pcall(function() model:Destroy() end)
            end
        end
    end
end

local function stopViewportESP()
    if renderStepBound then
        pcall(function() RunService:UnbindFromRenderStep("TranscendingFluidSync") end)
        renderStepBound = false
    end

    for _, c in ipairs(lifecycleConnections) do
        pcall(function() c:Disconnect() end)
    end
    lifecycleConnections = {}

    for player in pairs(trackedRigs) do
        cleanupCharacter(player)
    end
    trackedRigs = {}

    for player in pairs(playerConnections) do
        cleanupPlayer(player)
    end
    playerConnections = {}
    characterGeneration = {}

    if worldModel and worldModel.Parent then
        pcall(function() worldModel:ClearAllChildren() end)
        pcall(function() worldModel:Destroy() end)
    end
    worldModel = nil

    if viewportCamera and viewportCamera.Parent then
        pcall(function() viewportCamera:Destroy() end)
    end
    viewportCamera = nil

    if viewportFrame and viewportFrame.Parent then
        pcall(function() viewportFrame:Destroy() end)
    end
    viewportFrame = nil

    if screenGui and screenGui.Parent then
        pcall(function() screenGui:Destroy() end)
    end
    screenGui = nil
end

local function startViewportESP()
    stopViewportESP()

    local safeContainer = getSafeContainer()

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TranscendingViewportGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10
    screenGui.Parent = safeContainer

    viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Size = UDim2.fromScale(1, 1)
    viewportFrame.Position = UDim2.fromScale(0, 0)
    viewportFrame.BackgroundTransparency = 1
    viewportFrame.BorderSizePixel = 0
    viewportFrame.Parent = screenGui

    viewportCamera = Instance.new("Camera")
    viewportFrame.CurrentCamera = viewportCamera
    viewportCamera.Parent = viewportFrame

    worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewportFrame

    updateViewportLighting()

    for _, player in ipairs(Players:GetPlayers()) do
        trackPlayer(player)
    end

    local pAddedConn = Players.PlayerAdded:Connect(trackPlayer)
    table.insert(lifecycleConnections, pAddedConn)

    local pRemovingConn = Players.PlayerRemoving:Connect(cleanupPlayer)
    table.insert(lifecycleConnections, pRemovingConn)

    RunService:BindToRenderStep("TranscendingFluidSync", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
    renderStepBound = true

    notify("Viewport ESP enabled (Syncing rigs)", Color3.fromRGB(50, 195, 75))
end

-- Keybind listener (defaults to KeyCode.P)
local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local triggerKey = S.ViewportESPKey or Enum.KeyCode.P
    if triggerKey ~= Enum.KeyCode.Unknown and input.KeyCode == triggerKey then
        local newState = not S.ViewportESP
        S.ViewportESP = newState
        if newState then
            startViewportESP()
        else
            stopViewportESP()
            notify("Viewport ESP disabled", Color3.fromRGB(218, 170, 42))
        end
        saveConfig()
        if UI.moduleButtons and UI.moduleButtons["Viewport ESP"] and UI.moduleButtons["Viewport ESP"].SetActive then
            pcall(function() UI.moduleButtons["Viewport ESP"].SetActive(newState) end)
        end
    end
end)
table.insert(inputConnections, inputConn)

registerModule("Render", "Viewport ESP", 440, 50, true, S.ViewportESP, function(v)
    S.ViewportESP = v
    if v then
        startViewportESP()
    else
        stopViewportESP()
        notify("Viewport ESP disabled", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    if addKeybindOption then
        addKeybindOption(drawer, "Toggle Keybind", S.ViewportESPKey or Enum.KeyCode.P, function(k)
            S.ViewportESPKey = k
            saveConfig()
            notify("Viewport ESP keybind set to: " .. k.Name, Color3.fromRGB(50, 195, 75))
        end)
    end

    if addToggleOption then
        addToggleOption(drawer, "Skip Teammates", S.ViewportESPSkipTeam or false, function(v)
            S.ViewportESPSkipTeam = v
            saveConfig()
        end)
    end

    if addDropdownOption then
        local ambientKeys = {"Natural", "Bright", "Night Vision", "High Contrast", "Neon Violet", "Thermal Amber"}
        addDropdownOption(drawer, "Ambient Lighting", ambientKeys, table.find(ambientKeys, S.ViewportESPAmbient) or 1, function(idx, opt)
            S.ViewportESPAmbient = opt
            updateViewportLighting()
            saveConfig()
        end)

        local lightKeys = {"White", "Warm Sunlight", "Cyan Cyber", "Crimson Red"}
        addDropdownOption(drawer, "Light Tint", lightKeys, table.find(lightKeys, S.ViewportESPLightColor) or 1, function(idx, opt)
            S.ViewportESPLightColor = opt
            updateViewportLighting()
            saveConfig()
        end)
    end

    if addSliderOption then
        addSliderOption(drawer, "ESP Opacity (%)", 10, 100, S.ViewportESPOpacity or 100, function(val)
            S.ViewportESPOpacity = val
            updateViewportLighting()
            saveConfig()
        end)
    end

    if addButtonOption then
        addButtonOption(drawer, "Re-sync All Rigs", function()
            if S.ViewportESP then
                startViewportESP()
                notify("Re-synced Viewport ESP rigs", Color3.fromRGB(50, 195, 75))
            end
        end)
    end
end, false)

VH.startViewportESP = startViewportESP
VH.stopViewportESP = stopViewportESP
State.stopViewportESP = stopViewportESP
