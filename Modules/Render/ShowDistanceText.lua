local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Show Distance Text", 440, 50, true, S.ESPDistances, function(v)
    if ESPSync then
        ESPSync:Set("ESPDistances", v, "ShowDistanceTextModule")
    else
        S.ESPDistances = v
        saveConfig()
    end
end)

if ESPSync then
    ESPSync:Register("ESPDistances", function(val, source)
        if source ~= "ShowDistanceTextModule" and UI.moduleButtons and UI.moduleButtons["Show Distance Text"] and UI.moduleButtons["Show Distance Text"].SetActive then
            UI.moduleButtons["Show Distance Text"].SetActive(val)
        end
    end)
end
