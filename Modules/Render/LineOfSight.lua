local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Line of Sight", 440, 50, true, S.LineOfSight, function(v)
    S.LineOfSight = v
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Team Check", S.LineOfSightTeamCheck, function(v)
        S.LineOfSightTeamCheck = v
        saveConfig()
    end)
    addToggleOption(drawer, "Friend Check", S.LineOfSightFriendCheck, function(v)
        S.LineOfSightFriendCheck = v
        saveConfig()
    end)
    addSliderOption(drawer, "Line Length (studs)", 10, 100, S.LineOfSightLength or 30, function(v)
        S.LineOfSightLength = v
        saveConfig()
    end)
end, false)
