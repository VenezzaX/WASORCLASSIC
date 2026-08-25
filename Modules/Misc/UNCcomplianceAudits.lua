local VH = _G.VoidHub
local Utils = VH.Utils
local UI = VH.UI

local registerModule = UI.registerModule

local addButtonOption = UI.addButtonOption

local runExternalScript = Utils.runExternalScript
local teleportToPlace = Utils.teleportToPlace

registerModule("Misc", "Map and Executor tests", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Run UNC Test Compliance Suite", function() runExternalScript("UNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Unc.lua") end)
    addButtonOption(drawer, "Run Executor Vuln Test", function() runExternalScript("Vulnerability Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/VulnerabilityTest.lua") end)
    addButtonOption(drawer, "Run Workspace Instance Dumper", function() runExternalScript("Workspace Dumper", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/WorkspaceDumper.lua") end)
    addButtonOption(drawer, "Run SUNC Exploit Tester", function() runExternalScript("SUNC Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/Sunc.lua", 90441122676618) end)
    addButtonOption(drawer, "Run Myriad Executor Test", function() runExternalScript("Myriad Test", "https://raw.githubusercontent.com/VenezzaX/Usefulthings/refs/heads/main/MyriadTest.lua", 79035306837882) end)
    addButtonOption(drawer, "Teleport to SUNC Test Game", function() teleportToPlace(90441122676618) end)
    addButtonOption(drawer, "Teleport to Myriad Test Game", function() teleportToPlace(79035306837882) end)
end, true, 200, 180)
