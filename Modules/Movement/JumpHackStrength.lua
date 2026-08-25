local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHum = Utils.getHum
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Jump Force", 300, 50, true, S.ForceJumpPower, function(v) S.ForceJumpPower = v; local hum = getHum(); if hum then if v then hum.UseJumpPower = true; hum.JumpPower = S.JumpPower else hum.UseJumpPower = (State.gameDefaultUseJumpPower ~= nil) and State.gameDefaultUseJumpPower or hum.UseJumpPower; hum.JumpPower = State.gameDefaultJumpPower or hum.JumpPower or 50 end end; saveConfig() end, function(drawer)
    if State.updateGameDefaults then State.updateGameDefaults() end
    local hum = getHum()
    local baseJump = math.floor(State.gameDefaultJumpPower or (hum and hum.JumpPower) or 50)
    local minJump = 1
    local maxJump = math.max(350, baseJump + 300)

    if not S.ForceJumpPower or not S.JumpPower then
        S.JumpPower = baseJump
    end

    local jumpSlider = addSliderOption(drawer, "JumpPower Strength", minJump, maxJump, S.JumpPower or baseJump, function(v) S.JumpPower = v; saveConfig(); local hum = getHum(); if hum and S.ForceJumpPower then hum.UseJumpPower = true; hum.JumpPower = v end end, baseJump)

    State.onGameJumpChanged = function(newJump)
        if not S.ForceJumpPower then
            local nJump = math.floor(newJump)
            if jumpSlider and jumpSlider.SetDefaultDot then
                jumpSlider.SetDefaultDot(nJump)
            end
            if jumpSlider and jumpSlider.Set then
                jumpSlider.Set(nJump)
            end
        end
    end

    addToggleOption(drawer, "Always Enforce JumpPower", S.ForceJumpPower, function(v) S.ForceJumpPower = v; saveConfig(); local hum = getHum(); if hum then if v then hum.UseJumpPower = true; hum.JumpPower = S.JumpPower else hum.UseJumpPower = (State.gameDefaultUseJumpPower ~= nil) and State.gameDefaultUseJumpPower or hum.UseJumpPower; hum.JumpPower = State.gameDefaultJumpPower or hum.JumpPower or 50 end end end)
    addKeybindOption(drawer, "Jump Strength Bind", S.JumpStrengthKey, function(k) S.JumpStrengthKey = k; saveConfig() end)
end, false)
