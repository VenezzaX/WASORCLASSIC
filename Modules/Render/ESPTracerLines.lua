local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addDropdownOption = UI.addDropdownOption

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

local tracerOriginOptions = {"Bottom", "Center", "Top"}
local tracerDropdownObj = nil

registerModule("Render", "ESP Tracer Lines", 440, 50, true, S.ESPTracers, function(v)
    if ESPSync then
        ESPSync:Set("ESPTracers", v, "ESPTracerLines")
    else
        S.ESPTracers = v
        saveConfig()
    end
end, function(drawer)
    tracerDropdownObj = addDropdownOption(drawer, "ESP Tracer Origin", tracerOriginOptions, table.find(tracerOriginOptions, S.TracerOrigin) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("TracerOrigin", opt, "ESPTracerLines")
        else
            S.TracerOrigin = opt
            saveConfig()
        end
    end)
end, false)

if ESPSync then
    ESPSync:Register("TracerOrigin", function(val, source)
        if source ~= "ESPTracerLines" and tracerDropdownObj and tracerDropdownObj.Set then
            tracerDropdownObj.Set(val or "Bottom")
        end
    end)
    
    ESPSync:Register("ESPTracers", function(val, source)
        if source ~= "ESPTracerLines" and UI.moduleButtons and UI.moduleButtons["ESP Tracer Lines"] and UI.moduleButtons["ESP Tracer Lines"].SetActive then
            UI.moduleButtons["ESP Tracer Lines"].SetActive(val)
        end
    end)
end
