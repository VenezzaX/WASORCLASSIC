local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Show Health Text", 440, 50, true, S.ESPHealth, function(v)
    if ESPSync then
        ESPSync:Set("ESPHealth", v, "ShowHealthTextModule")
    else
        S.ESPHealth = v
        saveConfig()
    end
end)

if ESPSync then
    ESPSync:Register("ESPHealth", function(val, source)
        if source ~= "ShowHealthTextModule" and UI.moduleButtons and UI.moduleButtons["Show Health Text"] and UI.moduleButtons["Show Health Text"].SetActive then
            UI.moduleButtons["Show Health Text"].SetActive(val)
        end
    end)
end
