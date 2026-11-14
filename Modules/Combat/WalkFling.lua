local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Walk Fling", 20, 50, true, S.WalkFling, function(v)
    S.WalkFling = v
    if v then
        S.FlingActive = false
        S.FlingAllActive = false
        S.FlingTarget = nil
        local modPlayer = moduleButtons and moduleButtons["Fling Player"]
        if modPlayer and modPlayer.SetActive then modPlayer.SetActive(false) end
        local modAll = moduleButtons and moduleButtons["Fling All"]
        if modAll and modAll.SetActive then modAll.SetActive(false) end
        local hum = getHum()
        if hum then
            if not State.walkFlingPreviousSpeed and hum.WalkSpeed ~= (S.WalkFlingSpeed or 32) then
                State.walkFlingPreviousSpeed = hum.WalkSpeed
            end
            if S.WalkFlingSpeed then
                hum.WalkSpeed = S.WalkFlingSpeed
            end
        end
    else
        task.spawn(function()
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            local hum = getHum()
            if hum then
                local restoreSpeed = State.walkFlingPreviousSpeed or (S.ForceWalkSpeed and S.WalkSpeed) or State.gameDefaultSpeed or 16
                hum.WalkSpeed = restoreSpeed
                State.walkFlingPreviousSpeed = nil
            end
        end)
    end
    saveConfig()
end, function(drawer)
    addKeybindOption(drawer, "Walk Fling Bind", S.WalkFlingKey or Enum.KeyCode.Unknown, function(k)
        S.WalkFlingKey = k
        saveConfig()
    end)
    addSliderOption(drawer, "WalkFling Speed", 16, 250, S.WalkFlingSpeed or 32, function(v)
        S.WalkFlingSpeed = v
        if S.WalkFling then
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end
        saveConfig()
    end, 32)
    addToggleOption(drawer, "Fling Noclip", S.FlingNoclip ~= false, function(v)
        S.FlingNoclip = v
        saveConfig()
    end)
end, false)
