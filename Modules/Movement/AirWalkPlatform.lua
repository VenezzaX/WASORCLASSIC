local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Air Walk Platform", 300, 50, true, S.AirWalk, function(v)
    S.AirWalk = v
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "Vertical Speed", 1, 50, S.AirWalkVerticalSpeed or 10, function(v)
        S.AirWalkVerticalSpeed = v
        saveConfig()
    end, 10)
end, false)
