local VH = _G.VoidHub
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addButtonOption = UI.addButtonOption
local addInfoRowOption = UI.addInfoRowOption

local runExternalScript = Utils.runExternalScript

local StudioTheme = UI.StudioTheme or {
    green = Color3.fromRGB(76, 175, 80),
    yellow = Color3.fromRGB(220, 170, 50),
    red = Color3.fromRGB(215, 60, 60)
}

local function loadCompatibleOrRemote(name, fileName, fallbackUrl)
    local loaded = false
    if isfile and readfile and loadstring then
        local candidates = {
            "CompatibleScripts/" .. fileName,
            "WASOR/CompatibleScripts/" .. fileName,
            "WASORCLASSIC/CompatibleScripts/" .. fileName,
            fileName
        }
        for _, path in ipairs(candidates) do
            if isfile(path) then
                local code = readfile(path)
                if code and #code > 50 then
                    local fn, parseErr = loadstring(code, path)
                    if fn then
                        task.spawn(fn)
                        loaded = true
                        notify("Loaded " .. name .. " (Themed)!", StudioTheme.green)
                        break
                    else
                        warn("[WASOR Fun] Error parsing " .. path .. ": " .. tostring(parseErr))
                    end
                end
            end
        end
    end
    if not loaded then
        runExternalScript(name, fallbackUrl)
    end
end

registerModule("Misc", "Fun", 720, 50, false, false, nil, function(drawer)
    addInfoRowOption(drawer, "Fun & Vanity", "Themed Scripts")

    addButtonOption(drawer, "Load FE Emotes", function()
        loadCompatibleOrRemote("FE Emotes", "FeEmotes.lua", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua")
    end)

    addButtonOption(drawer, "Load AnimPicker", function()
        loadCompatibleOrRemote("AnimPicker", "AnimationPicker.lua", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/AnimationPicker.lua")
    end)

    addButtonOption(drawer, "Load Gamepass Bypass", function()
        loadCompatibleOrRemote("Gamepass Bypass", "gamepassbypass.lua", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/gamepassbypass.lua")
    end)

    addButtonOption(drawer, "Load Coordinate UI", function()
        loadCompatibleOrRemote("Coordinate UI", "CoordinateUI.lua", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/CoordinateUI.lua")
    end)

    addButtonOption(drawer, "Load Outfit Copier", function()
        loadCompatibleOrRemote("Outfit Copier", "OutfitCopier.lua", "https://raw.githubusercontent.com/MizunoSync/CAGOutfitIDManager/refs/heads/main/pib.lua")
    end)
end, true, 300, 200)
