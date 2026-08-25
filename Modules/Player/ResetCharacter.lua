local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getChar = Utils.getChar
local getHum = Utils.getHum
local notify = Utils.notify
local registerModule = UI.registerModule

registerModule("Player", "Reset Character", 160, 50, false, false, function()
    if game.PlaceId == 286090429 then
        notify("Use the normal reset feature because of Arsenal CR we can't reset using our methods", Color3.fromRGB(218, 38, 38))
        return
    end

    local char = getChar()
    local hum = getHum()

    local hasGodMode = S.GodMode or S.GodModeConn or (hum and hum.MaxHealth > 99999)
    if hasGodMode then
        pcall(function() Utils.disableGodMode() end)
    end

    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            hum.Health = 0
        end)
    end

    if char then
        local head = char:FindFirstChild("Head")
        if head then pcall(function() head:Destroy() end) end
        local neck = char:FindFirstChild("Neck", true)
        if neck then pcall(function() neck:Destroy() end) end
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso")
        if torso then pcall(function() torso:Destroy() end) end
        pcall(function() char:BreakJoints() end)
    end

    notify("Character reset!", Color3.fromRGB(218, 38, 38))
end)
