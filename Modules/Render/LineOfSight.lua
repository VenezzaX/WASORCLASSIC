local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Line of Sight", 440, 50, true, S.LineOfSight, function(v)
    if ESPSync then
        ESPSync:Set("LineOfSight", v, "LineOfSightModule")
    else
        S.LineOfSight = v
        saveConfig()
    end
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

if ESPSync then
    ESPSync:Register("LineOfSight", function(val, source)
        if source ~= "LineOfSightModule" and UI.moduleButtons and UI.moduleButtons["Line of Sight"] and UI.moduleButtons["Line of Sight"].SetActive then
            UI.moduleButtons["Line of Sight"].SetActive(val)
        end
    end)
end
