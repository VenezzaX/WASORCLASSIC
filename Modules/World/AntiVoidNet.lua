local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local addButtonOption = UI.addButtonOption
local saveConfig = VH.Config.saveConfig

registerModule("World", "Anti Void", 580, 50, true, S.AntiVoid, function(v)
    S.AntiVoid = v
    saveConfig()
end, function(drawer)
    local slider = addSliderOption(drawer, "Anti-Void Height Y", -2000, 200, S.AntiVoidY or -500, function(v)
        S.AntiVoidY = v
        saveConfig()
    end, -500)
    addButtonOption(drawer, "Reset to Normal Default (-500)", function()
        S.AntiVoidY = -500
        if slider and slider.Set then
            slider.Set(-500)
        end
        saveConfig()
    end)
end, false)
