local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addDropdownOption = UI.addDropdownOption
local saveConfig = VH.Config.saveConfig

local MODES = {
    "Normal",
    "Transparent",
    "No Image",
    "Fully Hidden"
}

local function saveLoadingMode(mode)
    S.LoadingScreenMode = mode
    pcall(function()
        if writefile then
            if makefolder and not isfolder("WASOR_Cache") then
                pcall(makefolder, "WASOR_Cache")
            end
            writefile("WASOR_Cache/loading_mode.txt", mode)
        end
    end)
    saveConfig()
end

local isHidden = (S.LoadingScreenMode == "Fully Hidden" or S.HideLoadingScreen == true)

registerModule("Misc", "Hide Loading Screen", 720, 50, true, isHidden, function(v)
    if v then
        saveLoadingMode("Fully Hidden")
        notify("Loading Screen: Fully Hidden (Silent Load on next inject)", Color3.fromRGB(50, 195, 75))
    else
        saveLoadingMode("Normal")
        notify("Loading Screen: Normal (Wallpaper)", Color3.fromRGB(218, 170, 42))
    end
end, function(drawer)
    if addDropdownOption then
        local currentIdx = 1
        for i, m in ipairs(MODES) do
            if m == (S.LoadingScreenMode or "Normal") then
                currentIdx = i
                break
            end
        end

        addDropdownOption(drawer, "Loading Screen Style", MODES, currentIdx, function(idx, opt)
            saveLoadingMode(opt)
            local mod = UI.moduleButtons and UI.moduleButtons["Hide Loading Screen"]
            if mod then
                mod.SetActive(opt == "Fully Hidden")
            end
            notify("Loading style set to: " .. opt, Color3.fromRGB(50, 195, 75))
        end)
    end

    addToggleOption(drawer, "Transparent (See-Through Game)", S.LoadingScreenMode == "Transparent", function(v)
        if v then
            saveLoadingMode("Transparent")
            notify("Loading Screen: Transparent", Color3.fromRGB(50, 195, 75))
        else
            saveLoadingMode("Normal")
        end
    end)

    addToggleOption(drawer, "No Image (Fast Bandwidth Saver)", S.LoadingScreenMode == "No Image", function(v)
        if v then
            saveLoadingMode("No Image")
            notify("Loading Screen: No Image (Fast)", Color3.fromRGB(50, 195, 75))
        else
            saveLoadingMode("Normal")
        end
    end)

    addToggleOption(drawer, "Fully Hidden (100% Silent)", S.LoadingScreenMode == "Fully Hidden", function(v)
        if v then
            saveLoadingMode("Fully Hidden")
            notify("Loading Screen: Fully Hidden", Color3.fromRGB(50, 195, 75))
        else
            saveLoadingMode("Normal")
        end
    end)
end, false)
