local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local refreshOverheads = Utils.refreshOverheads

local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Heads-Up Overheads", 440, 50, true, S.OverheadInfo, function(v)
    S.OverheadInfo = v
    refreshOverheads()
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Team Check", S.OverheadTeamCheck, function(v)
        S.OverheadTeamCheck = v
        refreshOverheads()
        saveConfig()
    end)
    addSliderOption(drawer, "Max Distance (studs)", 50, 1000, S.OverheadMaxDistance or 300, function(v)
        S.OverheadMaxDistance = v
        refreshOverheads()
        saveConfig()
    end)
end, false)
