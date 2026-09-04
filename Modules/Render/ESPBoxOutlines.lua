local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addSliderOption = UI.addSliderOption
local addDropdownOption = UI.addDropdownOption
local addButtonOption = UI.addButtonOption

local saveConfig = VH.Config.saveConfig
local ESPSync = VH.ESPSync

local boxStyles = {"Full", "Corners", "3D Box", "Brackets", "Tech Hex", "Top-Bottom"}
local colorOptions = {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}

local transparencySliderObj = nil
local colorDropdownObj = nil
local boxStyleDropdownObj = nil

registerModule("Render", "ESP Box Outlines", 440, 50, true, S.ESPBoxes, function(v)
    if ESPSync then
        ESPSync:Set("ESPBoxes", v, "ESPBoxOutlines")
    else
        S.ESPBoxes = v
        saveConfig()
    end
end, function(drawer)
    transparencySliderObj = addSliderOption(drawer, "Box Transparency (%)", 0, 100, (S.ESPTransparency or 0.8) * 100, function(v)
        if ESPSync then
            ESPSync:Set("ESPTransparency", v / 100, "ESPBoxOutlines")
        else
            S.ESPTransparency = v / 100
            saveConfig()
        end
    end)
    colorDropdownObj = addDropdownOption(drawer, "ESP Scheme Color", colorOptions, table.find(colorOptions, S.ESPColor) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("ESPColor", opt, "ESPBoxOutlines")
        else
            S.ESPColor = opt
            saveConfig()
        end
    end)
    boxStyleDropdownObj = addDropdownOption(drawer, "ESP Box Style", boxStyles, table.find(boxStyles, S.ESPBoxStyle) or 1, function(_, opt)
        if ESPSync then
            ESPSync:Set("ESPBoxStyle", opt, "ESPBoxOutlines")
        else
            S.ESPBoxStyle = opt
            saveConfig()
        end
    end)
    if addButtonOption then
        addButtonOption(drawer, "Open ESP Preview", function()
            if VH.openESPPreview then
                pcall(VH.openESPPreview)
            elseif UI.moduleButtons["ESP Preview"] and UI.moduleButtons["ESP Preview"].SetActive then
                UI.moduleButtons["ESP Preview"].SetActive(true)
            end
        end)
    end
end, false)

if ESPSync then
    ESPSync:Register("ESPTransparency", function(val, source)
        if source ~= "ESPBoxOutlines" and transparencySliderObj and transparencySliderObj.Set then
            transparencySliderObj.Set(math.round((val or 0.8) * 100))
        end
    end)
    
    ESPSync:Register("ESPColor", function(val, source)
        if source ~= "ESPBoxOutlines" and colorDropdownObj and colorDropdownObj.Set then
            colorDropdownObj.Set(val or "Team Color")
        end
    end)
    
    ESPSync:Register("ESPBoxStyle", function(val, source)
        if source ~= "ESPBoxOutlines" and boxStyleDropdownObj and boxStyleDropdownObj.Set then
            boxStyleDropdownObj.Set(val or "Full")
        end
    end)
    
    ESPSync:Register("ESPBoxes", function(val, source)
        if source ~= "ESPBoxOutlines" and UI.moduleButtons and UI.moduleButtons["ESP Box Outlines"] and UI.moduleButtons["ESP Box Outlines"].SetActive then
            UI.moduleButtons["ESP Box Outlines"].SetActive(val)
        end
    end)
end
