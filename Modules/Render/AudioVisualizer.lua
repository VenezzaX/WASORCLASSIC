local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local RunService = Services.RunService
local SoundService = Services.SoundService
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace

local notify = Utils.notify
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addButtonOption = UI.addButtonOption
local saveConfig = VH.Config.saveConfig

local localPlayer = Services.LP or Players.LocalPlayer or Players.PlayerAdded:Wait()

local MODE = S.AudioVisualizerMode or 1
local MAX_MODES = 3
local COLOR_THEME = S.AudioVisualizerThemeIdx or 1
local SENSITIVITY = S.AudioVisualizerSensitivity or 1.0

local GAME_BAR_COUNT = 64
local GAME_RADIUS = 115
local GAME_BAR_WIDTH = 3
local GAME_BASE_LEN = 6
local GAME_MAX_ADD_LEN = 90
local GAME_LERP_ALPHA = 0.22
local GAME_ROT_SPEED = 18

local VOICE_BAR_COUNT = 32
local VOICE_RADIUS = 46
local VOICE_BAR_WIDTH = 3
local VOICE_BASE_LEN = 5
local VOICE_MAX_ADD_LEN = 48
local VOICE_LERP_ALPHA = 0.32
local VOICE_ROT_SPEED = -26

local THEMES = {
    {
        GameLow = Color3.fromRGB(80, 110, 255),
        GameHigh = Color3.fromRGB(240, 60, 170),
        VoiceLow = Color3.fromRGB(0, 255, 180),
        VoiceHigh = Color3.fromRGB(255, 180, 50),
        Core = Color3.fromRGB(120, 140, 255)
    },
    {
        GameLow = Color3.fromRGB(255, 80, 40),
        GameHigh = Color3.fromRGB(255, 210, 0),
        VoiceLow = Color3.fromRGB(255, 40, 100),
        VoiceHigh = Color3.fromRGB(255, 140, 200),
        Core = Color3.fromRGB(255, 100, 50)
    },
    {
        GameLow = Color3.fromRGB(140, 140, 150),
        GameHigh = Color3.fromRGB(245, 245, 250),
        VoiceLow = Color3.fromRGB(90, 90, 100),
        VoiceHigh = Color3.fromRGB(200, 200, 210),
        Core = Color3.fromRGB(200, 200, 210)
    }
}

local screenGui = nil
local rootFrame = nil
local gameContainer = nil
local voiceContainer = nil
local coreDot = nil
local dragHandle = nil

local gameBars = {}
local gameStates = {}
local voiceBars = {}
local voiceStates = {}

local trackedGameSounds = {}
local trackedVoiceSounds = {}

local renderConn = nil
local descendantConns = {}
local inputConns = {}
local isDragging = false
local dragStartMouse = Vector2.zero
local dragStartPos = UDim2.new()
local isM1Down = false
local isM2Down = false

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
    return localPlayer:WaitForChild("PlayerGui")
end

local function isVoiceSound(sound)
    local nameLower = string.lower(sound.Name)
    if string.find(nameLower, "voice") or string.find(nameLower, "audioemitter") or string.find(nameLower, "speech") then
        return true
    end
    if sound:GetAttribute("Voice") == true or sound:GetAttribute("IsVoice") == true then
        return true
    end
    local parent = sound.Parent
    if parent and (parent.Name == "Head" or parent:FindFirstChildOfClass("Humanoid")) then
        return true
    end
    return false
end

local function registerSound(sound)
    if not sound:IsA("Sound") then return end

    local targetTable = isVoiceSound(sound) and trackedVoiceSounds or trackedGameSounds

    if not table.find(targetTable, sound) then
        table.insert(targetTable, sound)
        local ancConn
        ancConn = sound.AncestryChanged:Connect(function(_, parent)
            if not parent then
                local idx = table.find(targetTable, sound)
                if idx then
                    table.remove(targetTable, idx)
                end
                ancConn:Disconnect()
            end
        end)
        table.insert(descendantConns, ancConn)
    end
end

local function getHighestLoudness(soundList)
    local maxLoudness = 0
    for i = #soundList, 1, -1 do
        local snd = soundList[i]
        if snd.Parent and snd.IsPlaying and snd.Volume > 0 then
            local loud = snd.PlaybackLoudness
            if loud > maxLoudness then
                maxLoudness = loud
            end
        end
    end
    return maxLoudness
end

local function buildBars(parent, count, width, baseLen)
    local bars = table.create(count)
    local states = table.create(count, baseLen)

    for i = 1, count do
        local bar = Instance.new("Frame")
        bar.Name = string.format("Bar_%02d", i)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        bar.BackgroundTransparency = 0.08
        bar.Size = UDim2.fromOffset(width, baseLen)
        bar.ZIndex = 10

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = bar

        bar.Parent = parent
        bars[i] = bar
    end

    return bars, states
end

local function applyLayout()
    if not gameBars or #gameBars == 0 or not voiceBars or #voiceBars == 0 then return end
    local linearGameWidth = 360
    local linearVoiceWidth = 240

    for i = 1, GAME_BAR_COUNT do
        local bar = gameBars[i]
        if bar then
            if MODE == 1 then
                local deg = (360 / GAME_BAR_COUNT) * (i - 1)
                local rad = math.rad(deg)
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(math.sin(rad) * GAME_RADIUS, -math.cos(rad) * GAME_RADIUS)
                bar.Rotation = deg
            elseif MODE == 2 then
                local step = linearGameWidth / GAME_BAR_COUNT
                local x = -linearGameWidth / 2 + (i - 0.5) * step
                bar.AnchorPoint = Vector2.new(0.5, 0.5)
                bar.Position = UDim2.fromOffset(x, 28)
                bar.Rotation = 0
            elseif MODE == 3 then
                local deg = (180 / (GAME_BAR_COUNT - 1)) * (i - 1) - 90
                local rad = math.rad(deg)
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(math.sin(rad) * GAME_RADIUS, -math.cos(rad) * GAME_RADIUS)
                bar.Rotation = deg
            end
        end
    end

    for i = 1, VOICE_BAR_COUNT do
        local bar = voiceBars[i]
        if bar then
            if MODE == 1 then
                local deg = (360 / VOICE_BAR_COUNT) * (i - 1)
                local rad = math.rad(deg)
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(math.sin(rad) * VOICE_RADIUS, -math.cos(rad) * VOICE_RADIUS)
                bar.Rotation = deg
            elseif MODE == 2 then
                local step = linearVoiceWidth / VOICE_BAR_COUNT
                local x = -linearVoiceWidth / 2 + (i - 0.5) * step
                bar.AnchorPoint = Vector2.new(0.5, 0.5)
                bar.Position = UDim2.fromOffset(x, -28)
                bar.Rotation = 0
            elseif MODE == 3 then
                local deg = (180 / (VOICE_BAR_COUNT - 1)) * (i - 1) - 90
                local rad = math.rad(deg)
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(math.sin(rad) * VOICE_RADIUS, -math.cos(rad) * VOICE_RADIUS)
                bar.Rotation = deg
            end
        end
    end
end

local function stopVisualizer()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    for _, c in ipairs(descendantConns) do
        pcall(function() c:Disconnect() end)
    end
    descendantConns = {}

    for _, c in ipairs(inputConns) do
        pcall(function() c:Disconnect() end)
    end
    inputConns = {}

    trackedGameSounds = {}
    trackedVoiceSounds = {}
    gameBars = {}
    gameStates = {}
    voiceBars = {}
    voiceStates = {}

    if rootFrame and rootFrame.Parent then
        pcall(function() rootFrame:Destroy() end)
    end
    rootFrame = nil

    if screenGui and screenGui.Parent then
        pcall(function() screenGui:Destroy() end)
    end
    screenGui = nil
end

local function startVisualizer()
    stopVisualizer()

    local safeContainer = getSafeContainer()

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MinimalVisualizerGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10
    screenGui.Parent = safeContainer

    rootFrame = Instance.new("Frame")
    rootFrame.Name = "VisualizerRoot"
    rootFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    rootFrame.Position = UDim2.fromScale(0.5, 0.5)
    rootFrame.Size = UDim2.fromOffset(0, 0)
    rootFrame.BackgroundTransparency = 1
    rootFrame.BorderSizePixel = 0
    rootFrame.Parent = screenGui

    gameContainer = Instance.new("Frame")
    gameContainer.Name = "GameVisualizerCenter"
    gameContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    gameContainer.Position = UDim2.fromScale(0.5, 0.5)
    gameContainer.Size = UDim2.fromOffset(0, 0)
    gameContainer.BackgroundTransparency = 1
    gameContainer.BorderSizePixel = 0
    gameContainer.Parent = rootFrame

    voiceContainer = Instance.new("Frame")
    voiceContainer.Name = "VoiceVisualizerCenter"
    voiceContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    voiceContainer.Position = UDim2.fromScale(0.5, 0.5)
    voiceContainer.Size = UDim2.fromOffset(0, 0)
    voiceContainer.BackgroundTransparency = 1
    voiceContainer.BorderSizePixel = 0
    voiceContainer.Parent = rootFrame

    local theme = THEMES[COLOR_THEME] or THEMES[1]

    coreDot = Instance.new("Frame")
    coreDot.Name = "CoreDot"
    coreDot.AnchorPoint = Vector2.new(0.5, 0.5)
    coreDot.Position = UDim2.fromScale(0.5, 0.5)
    coreDot.Size = UDim2.fromOffset(10, 10)
    coreDot.BackgroundColor3 = theme.Core
    coreDot.BackgroundTransparency = 0.2
    coreDot.BorderSizePixel = 0
    coreDot.ZIndex = 5
    coreDot.Parent = rootFrame

    local coreCorner = Instance.new("UICorner")
    coreCorner.CornerRadius = UDim.new(1, 0)
    coreCorner.Parent = coreDot

    dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    dragHandle.Position = UDim2.fromScale(0.5, 0.5)
    dragHandle.Size = UDim2.fromOffset(VOICE_RADIUS * 2, VOICE_RADIUS * 2)
    dragHandle.BackgroundTransparency = 1
    dragHandle.BorderSizePixel = 0
    dragHandle.Text = ""
    dragHandle.AutoButtonColor = false
    dragHandle.ZIndex = 20
    dragHandle.Parent = rootFrame

    local dragConn = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
            dragStartPos = rootFrame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)
    table.insert(inputConns, dragConn)

    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
            rootFrame.Position = UDim2.new(
                dragStartPos.X.Scale,
                dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale,
                dragStartPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(inputConns, moveConn)

    gameBars, gameStates = buildBars(gameContainer, GAME_BAR_COUNT, GAME_BAR_WIDTH, GAME_BASE_LEN)
    voiceBars, voiceStates = buildBars(voiceContainer, VOICE_BAR_COUNT, VOICE_BAR_WIDTH, VOICE_BASE_LEN)

    applyLayout()

    local inBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isM1Down = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isM2Down = true
        end
    end)
    table.insert(inputConns, inBegan)

    local inEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isM1Down = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isM2Down = false
        end
    end)
    table.insert(inputConns, inEnded)

    local ptrAction = UserInputService.PointerAction:Connect(function(wheel, _, _, gameProcessed)
        if wheel ~= 0 and isM1Down and isM2Down then
            if wheel > 0 then
                MODE = (MODE % MAX_MODES) + 1
            else
                MODE = ((MODE - 2 + MAX_MODES) % MAX_MODES) + 1
            end
            S.AudioVisualizerMode = MODE
            saveConfig()
            applyLayout()
        end
    end)
    table.insert(inputConns, ptrAction)

    for _, root in ipairs({ Workspace, SoundService, localPlayer:FindFirstChild("PlayerGui") or localPlayer }) do
        for _, desc in ipairs(root:GetDescendants()) do
            registerSound(desc)
        end
        local descConn = root.DescendantAdded:Connect(registerSound)
        table.insert(descendantConns, descConn)
    end

    local currentRotGame = 0
    local currentRotVoice = 0

    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not S.AudioVisualizer or not State.uiRunning then
            stopVisualizer()
            return
        end

        local rawGame = getHighestLoudness(trackedGameSounds)
        local rawVoice = getHighestLoudness(trackedVoiceSounds)

        local normGame = math.clamp((rawGame / 700) * SENSITIVITY, 0, 1.3)
        local normVoice = math.clamp((rawVoice / 550) * SENSITIVITY, 0, 1.3)

        local curTheme = THEMES[COLOR_THEME] or THEMES[1]

        if MODE == 1 then
            currentRotGame = (currentRotGame + GAME_ROT_SPEED * dt) % 360
            currentRotVoice = (currentRotVoice + VOICE_ROT_SPEED * dt) % 360
            gameContainer.Rotation = currentRotGame
            voiceContainer.Rotation = currentRotVoice
        else
            gameContainer.Rotation = 0
            voiceContainer.Rotation = 0
        end

        local combinedEnergy = math.clamp((normGame * 0.6) + (normVoice * 0.8), 0, 1.4)
        local coreScale = 10 + (combinedEnergy * 14)
        coreDot.Size = UDim2.fromOffset(coreScale, coreScale)
        coreDot.BackgroundColor3 = curTheme.Core
        coreDot.BackgroundTransparency = math.clamp(0.4 - (combinedEnergy * 0.3), 0.05, 0.6)

        local clock = os.clock() * 6.5

        local hasGameSound = rawGame > 5
        for i = 1, GAME_BAR_COUNT do
            local progress = i / GAME_BAR_COUNT
            local wave = math.sin(progress * math.pi * 4 + clock) * 0.09
            local mult = math.clamp(normGame + (hasGameSound and wave or 0), 0, 1.4)
            local target = GAME_BASE_LEN + (mult * GAME_MAX_ADD_LEN)

            gameStates[i] = gameStates[i] + (target - gameStates[i]) * GAME_LERP_ALPHA
            gameBars[i].Size = UDim2.fromOffset(GAME_BAR_WIDTH, gameStates[i])
            gameBars[i].BackgroundColor3 = curTheme.GameLow:Lerp(curTheme.GameHigh, math.clamp(mult, 0, 1))
        end

        local hasVoiceSound = rawVoice > 5
        for i = 1, VOICE_BAR_COUNT do
            local progress = i / VOICE_BAR_COUNT
            local wave = math.sin(progress * math.pi * 3 - clock * 1.1) * 0.12
            local mult = math.clamp(normVoice + (hasVoiceSound and wave or 0), 0, 1.4)
            local target = VOICE_BASE_LEN + (mult * VOICE_MAX_ADD_LEN)

            voiceStates[i] = voiceStates[i] + (target - voiceStates[i]) * VOICE_LERP_ALPHA
            voiceBars[i].Size = UDim2.fromOffset(VOICE_BAR_WIDTH, voiceStates[i])
            voiceBars[i].BackgroundColor3 = curTheme.VoiceLow:Lerp(curTheme.VoiceHigh, math.clamp(mult, 0, 1))
        end
    end)

    notify("Audio Visualizer enabled (Drag center dot to move)", Color3.fromRGB(50, 195, 75))
end

registerModule("Render", "Audio Visualizer", 440, 50, true, S.AudioVisualizer, function(v)
    S.AudioVisualizer = v
    if v then
        startVisualizer()
    else
        stopVisualizer()
        notify("Audio Visualizer disabled", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    if addDropdownOption then
        local modeNames = {
            "Mode 1: Circular (Rotating Dual Rings)",
            "Mode 2: Linear (Horizontal Spectrum)",
            "Mode 3: Radial Arc (180° Half-Circle)"
        }
        addDropdownOption(drawer, "Visualizer Layout", modeNames, MODE, function(idx, opt)
            MODE = idx
            S.AudioVisualizerMode = idx
            saveConfig()
            applyLayout()
        end)

        local themeNames = {
            "Theme 1: Cyber Neon (Blue / Pink / Teal)",
            "Theme 2: Solar Flare (Orange / Gold / Amber)",
            "Theme 3: Monochrome (Silver / Platinum)"
        }
        addDropdownOption(drawer, "Color Palette", themeNames, COLOR_THEME, function(idx, opt)
            COLOR_THEME = idx
            S.AudioVisualizerThemeIdx = idx
            saveConfig()
        end)
    end

    if addSliderOption then
        addSliderOption(drawer, "Sensitivity", 2, 30, math.floor(SENSITIVITY * 10), function(val)
            SENSITIVITY = val / 10
            S.AudioVisualizerSensitivity = SENSITIVITY
            saveConfig()
        end)
    end

    if addButtonOption then
        addButtonOption(drawer, "Reset Center Position", function()
            if rootFrame then
                rootFrame.Position = UDim2.fromScale(0.5, 0.5)
                notify("Visualizer centered", Color3.fromRGB(50, 195, 75))
            end
        end)
    end
end, false)
