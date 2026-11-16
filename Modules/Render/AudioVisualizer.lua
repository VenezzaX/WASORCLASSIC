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

local GAME_BAR_COUNT = 48
local VOICE_BAR_COUNT = 24

local GAME_RADIUS = 100
local VOICE_RADIUS = 46
local GAME_BAR_WIDTH = 3
local VOICE_BAR_WIDTH = 3
local GAME_BASE_LEN = 6
local VOICE_BASE_LEN = 5
local GAME_MAX_ADD_LEN = 85
local VOICE_MAX_ADD_LEN = 45

local THEMES = {
    {
        Name = "Cyber Neon",
        Low = Color3.fromRGB(0, 240, 255),
        Mid = Color3.fromRGB(180, 50, 255),
        High = Color3.fromRGB(255, 60, 170),
        Peak = Color3.fromRGB(255, 255, 255),
        Voice = Color3.fromRGB(0, 255, 180),
        Core = Color3.fromRGB(120, 150, 255),
        DockBg = Color3.fromRGB(10, 12, 22)
    },
    {
        Name = "Solar Amber",
        Low = Color3.fromRGB(255, 80, 20),
        Mid = Color3.fromRGB(255, 160, 0),
        High = Color3.fromRGB(255, 230, 40),
        Peak = Color3.fromRGB(255, 255, 200),
        Voice = Color3.fromRGB(255, 45, 90),
        Core = Color3.fromRGB(255, 120, 30),
        DockBg = Color3.fromRGB(22, 12, 8)
    },
    {
        Name = "Synthwave Sunset",
        Low = Color3.fromRGB(130, 40, 240),
        Mid = Color3.fromRGB(245, 40, 145),
        High = Color3.fromRGB(255, 170, 85),
        Peak = Color3.fromRGB(255, 255, 255),
        Voice = Color3.fromRGB(255, 90, 180),
        Core = Color3.fromRGB(210, 60, 255),
        DockBg = Color3.fromRGB(16, 8, 24)
    },
    {
        Name = "Emerald Aurora",
        Low = Color3.fromRGB(0, 255, 170),
        Mid = Color3.fromRGB(25, 220, 100),
        High = Color3.fromRGB(180, 255, 20),
        Peak = Color3.fromRGB(230, 255, 230),
        Voice = Color3.fromRGB(0, 230, 255),
        Core = Color3.fromRGB(40, 255, 160),
        DockBg = Color3.fromRGB(8, 20, 14)
    },
    {
        Name = "Monochrome Platinum",
        Low = Color3.fromRGB(110, 120, 135),
        Mid = Color3.fromRGB(190, 200, 215),
        High = Color3.fromRGB(250, 252, 255),
        Peak = Color3.fromRGB(255, 255, 255),
        Voice = Color3.fromRGB(160, 170, 185),
        Core = Color3.fromRGB(220, 225, 235),
        DockBg = Color3.fromRGB(14, 15, 18)
    }
}

local screenGui = nil
local rootFrame = nil
local dockBackground = nil
local gameContainer = nil
local voiceContainer = nil
local coreDot = nil
local coreGlow = nil
local dragHandle = nil

local gameBars = {}
local gamePeaks = {}
local gameStates = {}
local gamePeakVals = {}
local gamePeakVels = {}

local voiceBars = {}
local voicePeaks = {}
local voiceStates = {}
local voicePeakVals = {}
local voicePeakVels = {}

local trackedGameSounds = {}
local trackedVoiceSounds = {}

local renderConn = nil
local descendantConns = {}
local inputConns = {}
local isDragging = false
local dragStartMouse = Vector2.zero
local dragStartPos = UDim2.new()

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
                if idx then table.remove(targetTable, idx) end
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
            if loud > maxLoudness then maxLoudness = loud end
        end
    end
    return maxLoudness
end

local function getThemeColor(theme, progress)
    progress = math.clamp(progress, 0, 1)
    if progress < 0.5 then
        return theme.Low:Lerp(theme.Mid, progress * 2)
    else
        return theme.Mid:Lerp(theme.High, (progress - 0.5) * 2)
    end
end

local function buildBars(parent, count, width, baseLen)
    local bars = table.create(count)
    local peaks = table.create(count)
    local states = table.create(count, baseLen)
    local peakVals = table.create(count, baseLen)
    local peakVels = table.create(count, 0)

    for i = 1, count do
        local bar = Instance.new("Frame")
        bar.Name = string.format("Bar_%02d", i)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Color3.new(1, 1, 1)
        bar.BackgroundTransparency = 0.12
        bar.Size = UDim2.fromOffset(width, baseLen)
        bar.ZIndex = 12

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = bar

        local peak = Instance.new("Frame")
        peak.Name = string.format("Peak_%02d", i)
        peak.BorderSizePixel = 0
        peak.BackgroundColor3 = Color3.new(1, 1, 1)
        peak.BackgroundTransparency = 0.05
        peak.Size = UDim2.fromOffset(width + 1, width + 1)
        peak.ZIndex = 14

        local peakCorner = Instance.new("UICorner")
        peakCorner.CornerRadius = UDim.new(1, 0)
        peakCorner.Parent = peak

        bar.Parent = parent
        peak.Parent = parent
        bars[i] = bar
        peaks[i] = peak
    end

    return bars, peaks, states, peakVals, peakVels
end

local function applyLayout()
    if not gameBars or #gameBars == 0 then return end
    local theme = THEMES[COLOR_THEME] or THEMES[1]

    if dockBackground then
        dockBackground.Visible = (MODE == 2)
        dockBackground.BackgroundColor3 = theme.DockBg
    end

    if coreDot then
        coreDot.Visible = (MODE == 1)
    end
    if coreGlow then
        coreGlow.Visible = (MODE == 1)
    end
    if voiceContainer then
        voiceContainer.Visible = (MODE == 1)
    end

    local linearWidth = 380
    local stepLinear = linearWidth / GAME_BAR_COUNT

    for i = 1, GAME_BAR_COUNT do
        local bar = gameBars[i]
        local peak = gamePeaks[i]
        if bar and peak then
            if MODE == 1 then
                local deg = (360 / GAME_BAR_COUNT) * (i - 1)
                local rad = math.rad(deg)
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(math.sin(rad) * GAME_RADIUS, -math.cos(rad) * GAME_RADIUS)
                bar.Rotation = deg
                peak.AnchorPoint = Vector2.new(0.5, 0.5)
                peak.Position = UDim2.fromOffset(math.sin(rad) * (GAME_RADIUS + gamePeakVals[i] + 4), -math.cos(rad) * (GAME_RADIUS + gamePeakVals[i] + 4))
                peak.Rotation = 0
                peak.Visible = true
            elseif MODE == 2 then
                local x = -linearWidth / 2 + (i - 0.5) * stepLinear
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.fromOffset(x, 18)
                bar.Rotation = 0
                peak.AnchorPoint = Vector2.new(0.5, 1)
                peak.Position = UDim2.fromOffset(x, 18 - gamePeakVals[i] - 3)
                peak.Rotation = 0
                peak.Visible = true
            elseif MODE == 3 then
                local x = -linearWidth / 2 + (i - 0.5) * stepLinear
                bar.AnchorPoint = Vector2.new(0.5, 0.5)
                bar.Position = UDim2.fromOffset(x, 0)
                bar.Rotation = 0
                peak.AnchorPoint = Vector2.new(0.5, 0.5)
                peak.Position = UDim2.fromOffset(x, -(gamePeakVals[i] / 2) - 4)
                peak.Rotation = 0
                peak.Visible = true
            end
        end
    end

    if voiceBars and #voiceBars > 0 then
        for i = 1, VOICE_BAR_COUNT do
            local bar = voiceBars[i]
            local peak = voicePeaks[i]
            if bar and peak then
                if MODE == 1 then
                    local deg = (360 / VOICE_BAR_COUNT) * (i - 1)
                    local rad = math.rad(deg)
                    bar.AnchorPoint = Vector2.new(0.5, 1)
                    bar.Position = UDim2.fromOffset(math.sin(rad) * VOICE_RADIUS, -math.cos(rad) * VOICE_RADIUS)
                    bar.Rotation = deg
                    peak.AnchorPoint = Vector2.new(0.5, 0.5)
                    peak.Position = UDim2.fromOffset(math.sin(rad) * (VOICE_RADIUS + voicePeakVals[i] + 3), -math.cos(rad) * (VOICE_RADIUS + voicePeakVals[i] + 3))
                    peak.Rotation = 0
                    peak.Visible = true
                else
                    bar.Visible = false
                    peak.Visible = false
                end
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
    gamePeaks = {}
    gameStates = {}
    gamePeakVals = {}
    gamePeakVels = {}
    voiceBars = {}
    voicePeaks = {}
    voiceStates = {}
    voicePeakVals = {}
    voicePeakVels = {}

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

    local theme = THEMES[COLOR_THEME] or THEMES[1]

    rootFrame = Instance.new("Frame")
    rootFrame.Name = "VisualizerRoot"
    rootFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    rootFrame.Position = (MODE == 2) and UDim2.new(0.5, 0, 1, -95) or UDim2.fromScale(0.5, 0.5)
    rootFrame.Size = UDim2.fromOffset(410, 80)
    rootFrame.BackgroundTransparency = 1
    rootFrame.BorderSizePixel = 0
    rootFrame.Parent = screenGui

    dockBackground = Instance.new("Frame")
    dockBackground.Name = "DockBackground"
    dockBackground.AnchorPoint = Vector2.new(0.5, 0.5)
    dockBackground.Position = UDim2.fromScale(0.5, 0.5)
    dockBackground.Size = UDim2.new(1, 0, 1, 0)
    dockBackground.BackgroundColor3 = theme.DockBg
    dockBackground.BackgroundTransparency = 0.35
    dockBackground.BorderSizePixel = 0
    dockBackground.ZIndex = 8
    dockBackground.Visible = (MODE == 2)
    dockBackground.Parent = rootFrame

    local dockCorner = Instance.new("UICorner")
    dockCorner.CornerRadius = UDim.new(0, 16)
    dockCorner.Parent = dockBackground

    local dockStroke = Instance.new("UIStroke")
    dockStroke.Thickness = 1.2
    dockStroke.Color = Color3.fromRGB(255, 255, 255)
    dockStroke.Transparency = 0.85
    dockStroke.Parent = dockBackground

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

    coreGlow = Instance.new("Frame")
    coreGlow.Name = "CoreGlow"
    coreGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    coreGlow.Position = UDim2.fromScale(0.5, 0.5)
    coreGlow.Size = UDim2.fromOffset(36, 36)
    coreGlow.BackgroundColor3 = theme.Core
    coreGlow.BackgroundTransparency = 0.82
    coreGlow.BorderSizePixel = 0
    coreGlow.ZIndex = 4
    coreGlow.Parent = rootFrame

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = coreGlow

    coreDot = Instance.new("Frame")
    coreDot.Name = "CoreDot"
    coreDot.AnchorPoint = Vector2.new(0.5, 0.5)
    coreDot.Position = UDim2.fromScale(0.5, 0.5)
    coreDot.Size = UDim2.fromOffset(14, 14)
    coreDot.BackgroundColor3 = theme.Core
    coreDot.BackgroundTransparency = 0.15
    coreDot.BorderSizePixel = 0
    coreDot.ZIndex = 6
    coreDot.Parent = rootFrame

    local coreCorner = Instance.new("UICorner")
    coreCorner.CornerRadius = UDim.new(1, 0)
    coreCorner.Parent = coreDot

    dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    dragHandle.Position = UDim2.fromScale(0.5, 0.5)
    dragHandle.Size = UDim2.new(1, 0, 1, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.BorderSizePixel = 0
    dragHandle.Text = ""
    dragHandle.AutoButtonColor = false
    dragHandle.ZIndex = 25
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

    gameBars, gamePeaks, gameStates, gamePeakVals, gamePeakVels = buildBars(gameContainer, GAME_BAR_COUNT, GAME_BAR_WIDTH, GAME_BASE_LEN)
    voiceBars, voicePeaks, voiceStates, voicePeakVals, voicePeakVels = buildBars(voiceContainer, VOICE_BAR_COUNT, VOICE_BAR_WIDTH, VOICE_BASE_LEN)

    applyLayout()

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

        dt = math.clamp(dt, 0.001, 0.05)

        local rawGame = getHighestLoudness(trackedGameSounds)
        local rawVoice = getHighestLoudness(trackedVoiceSounds)

        local normGame = math.clamp((rawGame / 650) * SENSITIVITY, 0, 1.4)
        local normVoice = math.clamp((rawVoice / 500) * SENSITIVITY, 0, 1.4)

        local curTheme = THEMES[COLOR_THEME] or THEMES[1]

        if MODE == 1 then
            currentRotGame = (currentRotGame + 16 * dt) % 360
            currentRotVoice = (currentRotVoice - 24 * dt) % 360
            gameContainer.Rotation = currentRotGame
            voiceContainer.Rotation = currentRotVoice
        else
            gameContainer.Rotation = 0
            voiceContainer.Rotation = 0
        end

        local combinedEnergy = math.clamp((normGame * 0.7) + (normVoice * 0.7), 0, 1.5)

        if coreDot and coreDot.Visible then
            local coreScale = 12 + (combinedEnergy * 14)
            coreDot.Size = UDim2.fromOffset(coreScale, coreScale)
            coreDot.BackgroundColor3 = curTheme.Core
            coreDot.BackgroundTransparency = math.clamp(0.35 - (combinedEnergy * 0.25), 0.05, 0.5)
        end

        if coreGlow and coreGlow.Visible then
            local glowScale = 30 + (combinedEnergy * 32)
            coreGlow.Size = UDim2.fromOffset(glowScale, glowScale)
            coreGlow.BackgroundColor3 = curTheme.Core
            coreGlow.BackgroundTransparency = math.clamp(0.85 - (combinedEnergy * 0.4), 0.3, 0.9)
        end

        local clock = os.clock() * 6.0
        local hasGameSound = rawGame > 4

        for i = 1, GAME_BAR_COUNT do
            local prog = (i - 1) / (GAME_BAR_COUNT - 1)
            local bassCurve = math.exp(-prog * 2.4)
            local midCurve = math.sin(prog * math.pi) * 0.75
            local trebleCurve = prog * 0.45

            local freqWeight = (bassCurve * 1.1) + (midCurve * 0.8) + (trebleCurve * 0.6)
            local waveA = math.sin(prog * math.pi * 3.5 + clock) * 0.12
            local waveB = math.cos(prog * math.pi * 5.0 - clock * 1.3) * 0.08
            local dynamicWobble = hasGameSound and (waveA + waveB) or 0

            local mult = math.clamp((normGame * freqWeight) + dynamicWobble, 0, 1.5)
            local targetLen = GAME_BASE_LEN + (mult * GAME_MAX_ADD_LEN)

            local currentLen = gameStates[i]
            local lerpAlpha = (targetLen > currentLen) and 0.42 or 0.16
            currentLen = currentLen + (targetLen - currentLen) * lerpAlpha
            gameStates[i] = currentLen

            if currentLen >= gamePeakVals[i] then
                gamePeakVals[i] = currentLen
                gamePeakVels[i] = 0
            else
                gamePeakVels[i] = gamePeakVels[i] + 360 * dt
                gamePeakVals[i] = math.max(currentLen, gamePeakVals[i] - gamePeakVels[i] * dt)
            end

            local barColor = getThemeColor(curTheme, prog)
            local bar = gameBars[i]
            local peak = gamePeaks[i]

            if bar then
                bar.BackgroundColor3 = barColor
                if MODE == 1 then
                    bar.Size = UDim2.fromOffset(GAME_BAR_WIDTH, currentLen)
                    if peak then
                        local deg = (360 / GAME_BAR_COUNT) * (i - 1)
                        local rad = math.rad(deg)
                        local peakDist = GAME_RADIUS + gamePeakVals[i] + 4
                        peak.Position = UDim2.fromOffset(math.sin(rad) * peakDist, -math.cos(rad) * peakDist)
                        peak.BackgroundColor3 = curTheme.Peak
                    end
                elseif MODE == 2 then
                    bar.Size = UDim2.fromOffset(GAME_BAR_WIDTH, currentLen)
                    if peak then
                        peak.Position = UDim2.fromOffset(bar.Position.X.Offset, 18 - gamePeakVals[i] - 3)
                        peak.BackgroundColor3 = curTheme.Peak
                    end
                elseif MODE == 3 then
                    bar.Size = UDim2.fromOffset(GAME_BAR_WIDTH, currentLen)
                    if peak then
                        peak.Position = UDim2.fromOffset(bar.Position.X.Offset, -(gamePeakVals[i] / 2) - 4)
                        peak.BackgroundColor3 = curTheme.Peak
                    end
                end
            end
        end

        local hasVoiceSound = rawVoice > 4
        if MODE == 1 and voiceBars and #voiceBars > 0 then
            for i = 1, VOICE_BAR_COUNT do
                local prog = (i - 1) / (VOICE_BAR_COUNT - 1)
                local vCurve = math.sin(prog * math.pi) * 0.9 + 0.3
                local vWave = math.sin(prog * math.pi * 3.0 - clock * 1.2) * 0.1
                local mult = math.clamp((normVoice * vCurve) + (hasVoiceSound and vWave or 0), 0, 1.4)
                local targetLen = VOICE_BASE_LEN + (mult * VOICE_MAX_ADD_LEN)

                local currentLen = voiceStates[i]
                local lerpAlpha = (targetLen > currentLen) and 0.45 or 0.18
                currentLen = currentLen + (targetLen - currentLen) * lerpAlpha
                voiceStates[i] = currentLen

                if currentLen >= voicePeakVals[i] then
                    voicePeakVals[i] = currentLen
                    voicePeakVels[i] = 0
                else
                    voicePeakVels[i] = voicePeakVels[i] + 320 * dt
                    voicePeakVals[i] = math.max(currentLen, voicePeakVals[i] - voicePeakVels[i] * dt)
                end

                local bar = voiceBars[i]
                local peak = voicePeaks[i]
                if bar then
                    bar.Visible = true
                    bar.Size = UDim2.fromOffset(VOICE_BAR_WIDTH, currentLen)
                    bar.BackgroundColor3 = curTheme.Voice
                    if peak then
                        peak.Visible = true
                        local deg = (360 / VOICE_BAR_COUNT) * (i - 1)
                        local rad = math.rad(deg)
                        local peakDist = VOICE_RADIUS + voicePeakVals[i] + 3
                        peak.Position = UDim2.fromOffset(math.sin(rad) * peakDist, -math.cos(rad) * peakDist)
                        peak.BackgroundColor3 = curTheme.Peak
                    end
                end
            end
        end
    end)

    notify("Audio Visualizer enabled (Drag to reposition)", Color3.fromRGB(50, 195, 75))
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
            "Mode 1: Cyber Halo (Radial Pulse)",
            "Mode 2: Modern HUD Dock (Bottom Spectrum)",
            "Mode 3: Mirrored Stereo Horizon (Dual Horizon)"
        }
        addDropdownOption(drawer, "Visualizer Layout", modeNames, MODE, function(idx, opt)
            MODE = idx
            S.AudioVisualizerMode = idx
            saveConfig()
            if rootFrame then
                if MODE == 2 then
                    rootFrame.Position = UDim2.new(0.5, 0, 1, -95)
                else
                    rootFrame.Position = UDim2.fromScale(0.5, 0.5)
                end
            end
            applyLayout()
        end)

        local themeNames = {
            "Theme 1: Cyber Neon (Cyan / Purple / Pink)",
            "Theme 2: Solar Amber (Fire Orange / Gold)",
            "Theme 3: Synthwave Sunset (Violet / Magenta / Coral)",
            "Theme 4: Emerald Aurora (Mint / Lime / Emerald)",
            "Theme 5: Monochrome Platinum (Silver / Pure White)"
        }
        addDropdownOption(drawer, "Color Palette", themeNames, COLOR_THEME, function(idx, opt)
            COLOR_THEME = idx
            S.AudioVisualizerThemeIdx = idx
            saveConfig()
            applyLayout()
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
                if MODE == 2 then
                    rootFrame.Position = UDim2.new(0.5, 0, 1, -95)
                else
                    rootFrame.Position = UDim2.fromScale(0.5, 0.5)
                end
                notify("Visualizer position reset", Color3.fromRGB(50, 195, 75))
            end
        end)
    end
end, false)
