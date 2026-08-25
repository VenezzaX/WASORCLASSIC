local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule
local addTextboxOption = UI.addTextboxOption
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("World", "Fire touchinterests", 580, 50, true, S.FireTouchinterestsActive, function(v)
    S.FireTouchinterestsActive = v
    saveConfig()
end, function(drawer)
    local tb = addTextboxOption(drawer, "Name Filter", "coin/checkpoint/etc", function(txt) S.FireTouchFilter = txt; saveConfig() end)
    tb.Set(S.FireTouchFilter or "")
    addSliderOption(drawer, "Max Distance (studs)", 5, 1000, S.FireTouchDistance or 100, function(v) S.FireTouchDistance = v; saveConfig() end)
end, false)
