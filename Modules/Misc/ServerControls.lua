local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local Utils = VH.Utils
local UI = VH.UI

local setupAutoReinject = Utils.setupAutoReinject
local TeleportService = Services.TeleportService

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

local addButtonOption = UI.addButtonOption
local addInfoRowOption = UI.addInfoRowOption

local teleportToRandom = Utils.teleportToRandom
local teleportToLowestPop = Utils.teleportToLowestPop
local teleportToHighestPop = Utils.teleportToHighestPop

local serverStatsLabels = State.serverStatsLabels

registerModule("Misc", "Server Options", 720, 50, false, false, nil, function(drawer)
    addButtonOption(drawer, "Rejoin Instance", function() notify("Rejoining server instance...", Color3.fromRGB(218, 170, 42)); setupAutoReinject(); task.delay(0.5, function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end)
    addButtonOption(drawer, "Standard Server Hop", teleportToRandom)
    addButtonOption(drawer, "Join Random Server", teleportToRandom)
    addButtonOption(drawer, "Join Lowest Population", teleportToLowestPop)
    addButtonOption(drawer, "Join Highest Population", teleportToHighestPop)
    addButtonOption(drawer, "Copy Server JobId", function() local setclip = setclipboard or writeclipboard or toclipboard or print; pcall(function() setclip(game.JobId) end); notify("Server JobId copied to clipboard!", Color3.fromRGB(50, 195, 75)) end)
    local rRegion = addInfoRowOption(drawer, "Region Location", "Loading..."); local rPing = addInfoRowOption(drawer, "Connection Ping", "--"); local rPlayers = addInfoRowOption(drawer, "Player Count Status", "--"); local rAge = addInfoRowOption(drawer, "Instance Uptime Age", "--")
    serverStatsLabels.region = rRegion.Label; serverStatsLabels.ping = rPing.Label; serverStatsLabels.players = rPlayers.Label; serverStatsLabels.age = rAge.Label
end, true, 200, 240)
