local VH = _G.VoidHub
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addButtonOption = UI.addButtonOption

local runExternalScript = Utils.runExternalScript

registerModule("Misc", "ScriptHub", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Load FE Emotes", function() runExternalScript("FE Emotes", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/FeEmotes.lua") end)
    addButtonOption(drawer, "Load AnimPicker", function() runExternalScript("AnimPicker", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/AnimationPicker.lua") end)
    addButtonOption(drawer, "Load Gamepass Bypass", function() runExternalScript("Gamepass Bypass", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/gamepassbypass.lua") end)
    addButtonOption(drawer, "Load Coordinate UI", function() runExternalScript("Coordinate UI", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/CoordinateUI.lua") end)
    addButtonOption(drawer, "Load Vex Explorer", function() runExternalScript("Vex", "https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua") end)
    addButtonOption(drawer, "Load Dex++ Explorer", function() runExternalScript("Dex++", "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua") end)
    addButtonOption(drawer, "Load Dex Explorer (Injected)", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end); notify("Dex Explorer loaded successfully!", Color3.fromRGB(50, 195, 75)) end)
    addButtonOption(drawer, "Load Cobalt UI Wrapper", function() pcall(function() loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))() end); notify("Cobalt UI loaded successfully!", Color3.fromRGB(50, 195, 75)) end)
    addButtonOption(drawer, "Load Infinite Yield Admin", function() pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source', true))() end); notify("Infinite Yield loaded successfully!", Color3.fromRGB(50, 195, 75)) end)
    addButtonOption(drawer, "Load SimpleSpy V3 (Remote)", function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))() end); notify("SimpleSpy V3 loaded successfully!", Color3.fromRGB(50, 195, 75)) end)
    addButtonOption(drawer, "Load Hydroxide", function() runExternalScript("Hydroxide", "https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/init.lua") end)
    addButtonOption(drawer, "Outfit Copier", function() runExternalScript("Outfit Copier", "https://raw.githubusercontent.com/MizunoSync/CAGOutfitIDManager/refs/heads/main/pib.lua") end)
end, true, 200, 260)
