local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHum = Utils.getHum
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "WalkSpeed", 300, 50, true, S.ForceWalkSpeed, function(v) S.ForceWalkSpeed = v; local hum = getHum(); if hum then hum.WalkSpeed = v and S.WalkSpeed or (State.gameDefaultSpeed or hum.WalkSpeed or 16) end; saveConfig() end, function(drawer)
    if State.updateGameDefaults then State.updateGameDefaults() end
    local hum = getHum()
    local baseSpeed = math.floor(State.gameDefaultSpeed or (hum and hum.WalkSpeed) or 16)
    local minSpeed = 1
    local maxSpeed = math.max(250, baseSpeed + 200)

    if not S.ForceWalkSpeed or not S.WalkSpeed then
        S.WalkSpeed = baseSpeed
    end

    local speedSlider = addSliderOption(drawer, "WalkSpeed Speed", minSpeed, maxSpeed, S.WalkSpeed or baseSpeed, function(v) S.WalkSpeed = v; saveConfig(); local hum = getHum(); if hum and S.ForceWalkSpeed then hum.WalkSpeed = v end end, baseSpeed)

    State.onGameSpeedChanged = function(newSpeed)
        if not S.ForceWalkSpeed then
            local nSpeed = math.floor(newSpeed)
            if speedSlider and speedSlider.SetDefaultDot then
                speedSlider.SetDefaultDot(nSpeed)
            end
            if speedSlider and speedSlider.Set then
                speedSlider.Set(nSpeed)
            end
        end
    end

    addToggleOption(drawer, "Always Enforce WalkSpeed", S.ForceWalkSpeed, function(v) S.ForceWalkSpeed = v; saveConfig(); local hum = getHum(); if hum then hum.WalkSpeed = v and S.WalkSpeed or (State.gameDefaultSpeed or hum.WalkSpeed or 16) end end)
end, false)
