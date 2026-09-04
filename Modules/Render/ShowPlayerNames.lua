local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Show Player Names", 440, 50, true, S.ESPNames, function(v)
    if ESPSync then
        ESPSync:Set("ESPNames", v, "ShowPlayerNamesModule")
    else
        S.ESPNames = v
        saveConfig()
    end
end)

if ESPSync then
    ESPSync:Register("ESPNames", function(val, source)
        if source ~= "ShowPlayerNamesModule" and UI.moduleButtons and UI.moduleButtons["Show Player Names"] and UI.moduleButtons["Show Player Names"].SetActive then
            UI.moduleButtons["Show Player Names"].SetActive(val)
        end
    end)
end
