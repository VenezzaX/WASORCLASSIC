local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local notify = Utils.notify
local registerModule = UI.registerModule

local addTextboxOption = UI.addTextboxOption
local saveConfig = VH.Config.saveConfig

local headSitConn = nil

local function stopHeadSit()
    if headSitConn then
        headSitConn:Disconnect()
        headSitConn = nil
    end
    local hum = getHum()
    if hum then
        hum.Sit = false
    end
end

registerModule("Movement", "Head Sit", 300, 50, true, S.HeadSitActive, function(v)
    S.HeadSitActive = v
    stopHeadSit()

    if v then
        local targetPlayer = S.HeadSitTargetPlayer
        if not targetPlayer then
            notify("Select a target player in drawer options first!", Color3.fromRGB(218, 170, 42))
            S.HeadSitActive = false
            local mod = UI.moduleButtons["Head Sit"]
            if mod then mod.SetActive(false) end
            return
        end

        local hum = getHum()
        if hum then hum.Sit = true end

        headSitConn = Services.RunService.Heartbeat:Connect(function()
            if not S.HeadSitActive or not State.uiRunning then
                stopHeadSit()
                return
            end

            local myHRP = getHRP()
            local myHum = getHum()
            local tChar = targetPlayer and targetPlayer.Character
            local tHRP = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Head") or tChar:FindFirstChild("Torso"))

            if myHRP and myHum and tHRP and targetPlayer:IsDescendantOf(Players) then
                myHum.Sit = true
                myHRP.CFrame = tHRP.CFrame * CFrame.Angles(0, 0, 0) * CFrame.new(0, 1.6, 0.4)
            else
                stopHeadSit()
                S.HeadSitActive = false
                local mod = UI.moduleButtons["Head Sit"]
                if mod then mod.SetActive(false) end
                notify("Target player left or dead! Head Sit ended.", Color3.fromRGB(218, 38, 38))
            end
        end)

        notify("Head Sitting on " .. targetPlayer.DisplayName .. "!", Color3.fromRGB(50, 195, 75))
    else
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
        else
            S.HeadSitTargetPlayer = nil
            notify("Player not found: " .. txt, Color3.fromRGB(218, 38, 38))
        end
    end)
end, false)
