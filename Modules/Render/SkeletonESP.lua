local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

registerModule("Render", "Skeleton ESP", 440, 50, true, S.SkeletonESP, function(v)
    if ESPSync then
        ESPSync:Set("SkeletonESP", v, "SkeletonESPModule")
    else
        S.SkeletonESP = v
        saveConfig()
    end
end)

if ESPSync then
    ESPSync:Register("SkeletonESP", function(val, source)
        if source ~= "SkeletonESPModule" and UI.moduleButtons and UI.moduleButtons["Skeleton ESP"] and UI.moduleButtons["Skeleton ESP"].SetActive then
            UI.moduleButtons["Skeleton ESP"].SetActive(val)
        end
    end)
end
