local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Workspace = Services.Workspace
local RunService = Services.RunService
local SoundService = Services.SoundService
local ContentProvider = Services.ContentProvider or game:GetService("ContentProvider")
local LP = Services.LP

local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addTextboxOption = UI.addTextboxOption
local addButtonOption = UI.addButtonOption
local saveConfig = VH.Config.saveConfig
local notify = Utils.notify

local SOUND_PRESETS = {
    "rbxassetid://73292002268424",
    "rbxassetid://134815520229822",
    "rbxassetid://129182852280519",
    "rbxassetid://91846437771243",
    "rbxassetid://5681537373",
    "rbxassetid://139606044239187"
}

local PRESET_NAMES = {
    "Subaru Respawn (Default)",
    "Re:Zero Sound Effect 1",
    "Re:Zero Sound Effect 2",
    "Re:Zero Respawn SFX",
    "Re:Zero Classic SFX",
    "Re:Zero Dark Breath"
}

local RAY_CAST_DISTANCE = 100
local SPAWN_HEIGHT_OFFSET = 3.5

local returnSound = nil
local lastValidCFrame = nil
local charConn = nil
local heartbeatConn = nil
local diedConn = nil

local function resolveSoundId()
    if S.ReturnByDeathCustomId and S.ReturnByDeathCustomId ~= "" then
        local raw = tostring(S.ReturnByDeathCustomId):gsub("%s+", "")
        if raw:match("^rbxassetid://") or raw:match("^http") then
            return raw
        elseif tonumber(raw) then
            return "rbxassetid://" .. raw
        elseif isfile and getcustomasset and isfile(raw) then
            return getcustomasset(raw)
        end
    end
    local idx = S.ReturnByDeathPresetIdx or 1
    return SOUND_PRESETS[idx] or SOUND_PRESETS[1]
end

local function getTargetAudioContainer()
    return Workspace.CurrentCamera or SoundService
end

local function getReturnSound()
    local container = getTargetAudioContainer()
    if returnSound and returnSound.Parent then
        if container and returnSound.Parent ~= container then
            pcall(function() returnSound.Parent = container end)
        end
        return returnSound
    end

    local sound = Instance.new("Sound")
    sound.Name = "ReturnByDeathSound"
    sound.SoundId = resolveSoundId()
    sound.Volume = S.ReturnByDeathVolume or 2
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMaxDistance = 100000
    sound.Looped = false
    sound.Parent = container

    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({ sound }, function(contentId, fetchStatus)
                if fetchStatus == Enum.AssetFetchStatus.Failure then
                    for _, altId in ipairs(SOUND_PRESETS) do
                        if altId ~= sound.SoundId then
                            sound.SoundId = altId
                            break
                        end
                    end
                end
            end)
        end)
    end)

    task.spawn(function()
        task.wait(2.5)
        if sound and not sound.IsLoaded then
            for _, altId in ipairs(SOUND_PRESETS) do
                if altId ~= sound.SoundId then
                    sound.SoundId = altId
                    pcall(function() ContentProvider:PreloadAsync({ sound }) end)
                    break
                end
            end
        end
    end)

    returnSound = sound
    return sound
end

local function playReturnSound()
    if S.ReturnByDeathSound == false then return end

    local expectedId = resolveSoundId()
    local s = getReturnSound()
    if not s then return end

    pcall(function()
        if s.SoundId ~= expectedId then
            s.SoundId = expectedId
        end
    end)

    pcall(function()
        s.Volume = S.ReturnByDeathVolume or 2
    end)

    pcall(function()
        if s.IsLoaded and s.TimeLength > 0 then
            s.TimePosition = 0
        end
    end)

    pcall(function()
        SoundService:PlayLocalSound(s)
    end)
    pcall(function()
        s:Play()
    end)

    pcall(function()
        if not s.IsLoaded then
            local con
            con = s.Loaded:Connect(function()
                if con then con:Disconnect() con = nil end
                pcall(function()
                    SoundService:PlayLocalSound(s)
                    s:Play()
                end)
            end)
            task.delay(4, function()
                if con then con:Disconnect() con = nil end
            end)
        end
    end)
end

local function getGroundCFrame(character, rootPart)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { character }
    raycastParams.IgnoreWater = true

    local rayResult = Workspace:Raycast(
        rootPart.Position,
        Vector3.new(0, -RAY_CAST_DISTANCE, 0),
        raycastParams
    )

    if rayResult then
        local groundPosition = rayResult.Position + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
        local rotation = rootPart.CFrame - rootPart.Position
        return CFrame.new(groundPosition) * rotation
    end

    return nil
end

local function bindCharacter(character)
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if diedConn then
        diedConn:Disconnect()
        diedConn = nil
    end

    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if not rootPart or not humanoid then return end

    if S.ReturnByDeath and lastValidCFrame then
        task.wait(0.1)
        if character.Parent and rootPart.Parent then
            character:PivotTo(lastValidCFrame)
            playReturnSound()
        end
    end

    local lastGroundedCFrame = nil

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not S.ReturnByDeath then return end
        if humanoid.Health > 0 and rootPart.Parent then
            if humanoid.FloorMaterial ~= Enum.Material.Air and humanoid.FloorMaterial ~= Enum.Material.Water then
                lastGroundedCFrame = rootPart.CFrame
            end
        end
    end)

    diedConn = humanoid.Died:Connect(function()
        if heartbeatConn then
            heartbeatConn:Disconnect()
            heartbeatConn = nil
        end

        if not S.ReturnByDeath or not rootPart.Parent then return end

        local directGround = getGroundCFrame(character, rootPart)

        if directGround then
            lastValidCFrame = directGround
        elseif lastGroundedCFrame then
            lastValidCFrame = lastGroundedCFrame
        else
            lastValidCFrame = rootPart.CFrame
        end
    end)
end

local function startAbility()
    getReturnSound()
    if not charConn then
        charConn = LP.CharacterAdded:Connect(function(char)
            bindCharacter(char)
        end)
    end
    if LP.Character then
        task.spawn(bindCharacter, LP.Character)
    end
end

local function stopAbility()
    if charConn then
        charConn:Disconnect()
        charConn = nil
    end
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if diedConn then
        diedConn:Disconnect()
        diedConn = nil
    end
    lastValidCFrame = nil
end

registerModule("Player", "Return by Death", 160, 50, true, S.ReturnByDeath, function(v)
    S.ReturnByDeath = v
    if v then
        startAbility()
    else
        stopAbility()
    end
    saveConfig()
end, function(drawer)
    if addToggleOption then
        addToggleOption(drawer, "Play Ability Sound Cue", S.ReturnByDeathSound ~= false, function(v)
            S.ReturnByDeathSound = v
            saveConfig()
        end)
    end

    if addButtonOption then
        addButtonOption(drawer, "Test Play Sound Now", function()
            playReturnSound()
            if notify then
                notify("Playing Return by Death audio cue...", Color3.fromRGB(141, 47, 196))
            end
        end)
    end

    if addSliderOption then
        addSliderOption(drawer, "Audio Volume", 1, 5, S.ReturnByDeathVolume or 2, function(v)
            S.ReturnByDeathVolume = v
            if returnSound then
                returnSound.Volume = v
            end
            saveConfig()
        end)
    end

    if addDropdownOption then
        addDropdownOption(drawer, "Audio Preset", PRESET_NAMES, S.ReturnByDeathPresetIdx or 1, function(idx)
            S.ReturnByDeathPresetIdx = idx
            if returnSound then
                returnSound.SoundId = SOUND_PRESETS[idx] or SOUND_PRESETS[1]
                pcall(function() ContentProvider:PreloadAsync({ returnSound }) end)
            end
            saveConfig()
        end)
    end

    if addTextboxOption then
        addTextboxOption(drawer, "Custom Sound ID", S.ReturnByDeathCustomId or "", function(txt)
            S.ReturnByDeathCustomId = txt
            if returnSound then
                returnSound.SoundId = resolveSoundId()
                pcall(function() ContentProvider:PreloadAsync({ returnSound }) end)
            end
            saveConfig()
        end)
    end
end, false)

if S.ReturnByDeath then
    startAbility()
end
