local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP
local RunService = Services.RunService

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local notify = Utils.notify
local registerModule = UI.registerModule
local addTextboxOption = UI.addTextboxOption
local addSliderOption = UI.addSliderOption
local addToggleOption = UI.addToggleOption
local saveConfig = VH.Config.saveConfig

local headSitSteppedConn = nil
local headSitRenderConn = nil

local function setLocalCharCollisions(enable)
    local char = Utils.getChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if not enable then
                part.CanCollide = false
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            else
                local isTorsoOrHead = (part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head")
                part.CanCollide = isTorsoOrHead
            end
        end
    end
end

local function stopHeadSit()
    if headSitSteppedConn then
        headSitSteppedConn:Disconnect()
        headSitSteppedConn = nil
    end
    if headSitRenderConn then
        headSitRenderConn:Disconnect()
        headSitRenderConn = nil
    end

    setLocalCharCollisions(true)

    local hum = getHum()
    local hrp = getHRP()
    if hum then
        pcall(function()
            hum.Sit = false
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        end)
    end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function startHeadSit()
    stopHeadSit()

    local targetPlayer = S.HeadSitTargetPlayer
    if not targetPlayer then
        notify("Select a target player in drawer options first!", Color3.fromRGB(218, 170, 42))
        S.HeadSitActive = false
        local mod = UI.moduleButtons["Head Sit"]
        if mod then mod.SetActive(false) end
        return
    end

    local myHum = getHum()
    if myHum then
        pcall(function()
            myHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            myHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            myHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            myHum.Sit = true
        end)
    end

    -- Pre-simulation collision nullifier (Prevents physics solver from flinging upon part contact)
    headSitSteppedConn = RunService.Stepped:Connect(function()
        if not S.HeadSitActive or not State.uiRunning then
            stopHeadSit()
            return
        end

        local myChar = Utils.getChar()
        if myChar then
            for _, part in ipairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)

    -- Post-simulation position lock
    headSitRenderConn = RunService.RenderStepped:Connect(function()
        if not S.HeadSitActive or not State.uiRunning then
            stopHeadSit()
            return
        end

        local myHRP = getHRP()
        local curHum = getHum()
        local tChar = targetPlayer and targetPlayer.Character
        local tHead = tChar and (tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

        if myHRP and curHum and tHead and tHum and tHum.Health > 0 and targetPlayer:IsDescendantOf(Players) then
            curHum.Sit = true
            local height = 1.75 + (S.HeadSitHeightOffset or 0)
            myHRP.CFrame = tHead.CFrame * CFrame.new(0, height, 0.25)
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
        else
            stopHeadSit()
            S.HeadSitActive = false
            local mod = UI.moduleButtons["Head Sit"]
            if mod then mod.SetActive(false) end
            notify("Target lost or dead! Head Sit ended.", Color3.fromRGB(218, 38, 38))
        end
    end)

    notify("Sitting on " .. targetPlayer.DisplayName .. " (Anti-Fling Active)", Color3.fromRGB(50, 195, 75))
end

registerModule("Movement", "Head Sit", 300, 50, true, S.HeadSitActive, function(v)
    S.HeadSitActive = v
    if v then
        startHeadSit()
    else
        stopHeadSit()
        notify("Head Sit disabled", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    addTextboxOption(drawer, "Target Player (Username/Display)", "Type player name...", function(txt)
        if txt == "" then
            S.HeadSitTargetPlayer = nil
            notify("Head Sit target cleared", Color3.fromRGB(218, 170, 42))
            return
        end
        local found = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and (p.Name:lower():find(txt:lower()) or p.DisplayName:lower():find(txt:lower())) then
                found = p
                break
            end
        end
        if found then
            S.HeadSitTargetPlayer = found
            notify("Head Sit target set to: " .. found.DisplayName, Color3.fromRGB(50, 195, 75))
            if S.HeadSitActive then
                startHeadSit()
            end
        else
            S.HeadSitTargetPlayer = nil
            notify("Player not found: " .. txt, Color3.fromRGB(218, 38, 38))
        end
    end)

    if addSliderOption then
        addSliderOption(drawer, "Height Offset", -1, 3, math.floor((S.HeadSitHeightOffset or 0) + 0.5), function(val)
            S.HeadSitHeightOffset = val * 0.5
            saveConfig()
        end)
    end
end, false)
