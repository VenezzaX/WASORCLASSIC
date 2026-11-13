local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleMapXray = Utils.toggleMapXray
local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("Render", "Map X-Ray", 440, 50, true, S.MapXray, function(v)
    toggleMapXray(v)
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "X-Ray Transparency (%)", 1, 100, S.MapXrayTransparency or 50, function(v)
        S.MapXrayTransparency = v
        if S.MapXray and Utils.updateMapXrayTransparency then
            Utils.updateMapXrayTransparency(v)
        end
        saveConfig()
    end, 50)
end, false)
