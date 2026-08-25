local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Skip Teammates", 440, 50, true, S.ESPTeamCheck, function(v) S.ESPTeamCheck = v; saveConfig() end, function(drawer)
    addToggleOption(drawer, "Ignore Friends Check", S.ESPIgnoreFriends, function(v) S.ESPIgnoreFriends = v; saveConfig() end)
end, false)
