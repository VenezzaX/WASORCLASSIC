local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule
local addDropdownOption = UI.addDropdownOption
local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Show Player Names", 440, 50, true, S.ESPNames, function(v)
    if ESPSync then
        ESPSync:Set("ESPNames", v, "ShowPlayerNamesModule")
    else
        S.ESPNames = v
        saveConfig()
    end
end, function(drawer)
    local nameModes = {"Both (Display & User)", "Display Name Only", "Username Only"}
    local defaultIdx = 1
    if S.ESPNameFormat == "Display Name Only" then
        defaultIdx = 2
    elseif S.ESPNameFormat == "Username Only" then
        defaultIdx = 3
    end
    addDropdownOption(drawer, "Name Display Format", nameModes, defaultIdx, function(idx, opt)
        S.ESPNameFormat = opt
        saveConfig()
    end)
end, false)

if ESPSync then
    ESPSync:Register("ESPNames", function(val, source)
        if source ~= "ShowPlayerNamesModule" and UI.moduleButtons and UI.moduleButtons["Show Player Names"] and UI.moduleButtons["Show Player Names"].SetActive then
            UI.moduleButtons["Show Player Names"].SetActive(val)
        end
    end)
end
