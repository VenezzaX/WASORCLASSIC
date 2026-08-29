if _G.VoidHub and type(_G.VoidHub) == "table" and _G.VoidHub.Cleanup and _G.VoidHub.Cleanup.cleanupAll then
    pcall(_G.VoidHub.Cleanup.cleanupAll)
end

pcall(function()
    local RunService = game:GetService("RunService")
    RunService:UnbindFromRenderStep("VoidESPUpdate")
    RunService:UnbindFromRenderStep("VoidAimbotUpdate")
    RunService:UnbindFromRenderStep("VoidFlyUpdate")
    RunService:UnbindFromRenderStep("VoidFreecamUpdate")
end)

pcall(function()
    if _G.WASOR_ScreenGui and _G.WASOR_ScreenGui.Parent then
        pcall(function() _G.WASOR_ScreenGui:Destroy() end)
        _G.WASOR_ScreenGui = nil
    end
    local containers = {}
    if gethui then pcall(function() table.insert(containers, gethui()) end) end
    if get_hidden_gui then pcall(function() table.insert(containers, get_hidden_gui()) end) end
    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        if CoreGui then table.insert(containers, CoreGui) end
    end)
    pcall(function()
        local Players = game:GetService("Players")
        if Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") then
            table.insert(containers, Players.LocalPlayer.PlayerGui)
        end
    end)
    for _, parent in ipairs(containers) do
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == "MeteorRobloxGUI" or child.Name == "DiscordNetworkHub" or child.Name == "MinimapGui" or child.Name == "VoidCustomNametag" or child.Name == "EulaFrame" or child:FindFirstChild("MainUIContainer") or child:FindFirstChild("StudioTopRibbon") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
end)

_G.VoidHub = {}
local VH = _G.VoidHub

local CoreModules = {
    "Core/Services",
    "Core/State",
    "Core/Utils",
    "Core/Config",
    "Core/Logger",
    "Core/Cleanup",
    "Core/UI"
}

local function logInitCrash(context, err, stack)
    if VH.Logger and VH.Logger.logCrash then
        VH.Logger.logCrash(context, err, stack)
    else
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local crashMsg = string.format("==================== CRASH LOG [%s] ====================\nContext: %s\nError: %s\nTraceback:\n%s\n=================================================================\n\n", timestamp, tostring(context), tostring(err), tostring(stack or "N/A"))
        warn(string.format("[WASOR CRASH] [%s] Error: %s\nTraceback:\n%s", tostring(context), tostring(err), tostring(stack or "")))
        pcall(function()
            if writefile then
                local filename = "WASOR_crash.log"
                if isfile and isfile(filename) then
                    if appendfile then appendfile(filename, crashMsg)
                    else writefile(filename, readfile(filename) .. crashMsg) end
                else writefile(filename, crashMsg) end
            end
        end)
    end
end

local function runFile(path)
    if readfile and isfile and loadstring then
        local fullPath = "WASOR/" .. path .. ".lua"
        if isfile(fullPath) then
            local code = readfile(fullPath)
            local func, parseErr = loadstring(code, fullPath)
            if func then
                local errTrace = nil
                local success, execErr = xpcall(func, function(e)
                    errTrace = debug.traceback(tostring(e), 2)
                    return e
                end)
                if not success then
                    logInitCrash("Executing " .. fullPath, execErr, errTrace)
                end
            else
                logInitCrash("Parsing " .. fullPath, parseErr, debug.traceback())
            end
        else
            warn("[WASOR Loader] File not found: " .. fullPath)
        end
    else
        local target = script
        for segment in path:gmatch("[^/]+") do
            target = target:FindFirstChild(segment)
            if not target then break end
        end
        if target and target:IsA("ModuleScript") then
            return require(target)
        end
    end
end

local Modules = {
    "Modules/Combat/GodMode",
    "Modules/Combat/AutoplayBot",
    "Modules/Combat/KillAura",
    "Modules/Combat/SilentAim",
    "Modules/Combat/NoRecoil",
    "Modules/Combat/AutoClicker",
    "Modules/Combat/Aimbot",
    "Modules/Combat/Aimlock",
    "Modules/Combat/Triggerbot",
    "Modules/Combat/FlingPlayer",
    "Modules/Combat/FlingAll",
    "Modules/Combat/WalkFling",

    "Modules/Player/ResetCharacter",
    "Modules/Player/InstantRespawn",
    "Modules/Player/NametagCustomizer",
    "Modules/Player/UINameSpoof",
    "Modules/Player/CustomIdleAnimation",
    "Modules/Player/ForceShiftLock",
    "Modules/Player/UnlockMaxZoom",
    "Modules/Player/GiveBTools",
    "Modules/Player/ClickDelete",
    "Modules/Player/ClickTeleport",
    "Modules/Player/AntiAFK",
    "Modules/Player/AutoRejoin",
    "Modules/Player/SpectateFreecam",

    "Modules/Movement/SpeedModification",
    "Modules/Movement/SprintSpeedBoost",
    "Modules/Movement/JumpHackStrength",
    "Modules/Movement/Climb",
    "Modules/Movement/WallRun",
    "Modules/Movement/FlyMode",
    "Modules/Movement/FlyBypass",
    "Modules/Movement/InfiniteJump",
    "Modules/Movement/AutoBunnyhop",
    "Modules/Movement/AutoWalktoMouse",
    "Modules/Movement/AirWalkPlatform",
    "Modules/Movement/NoClipPasses",
    "Modules/Movement/BlinkTeleport",
    "Modules/Movement/GhostStateMode",
    "Modules/Movement/FloatMode",
    "Modules/Movement/WaterWalk",
    "Modules/Movement/TallAnimations",
    "Modules/Movement/PlayerSpin",
    "Modules/Movement/UltraInstinct",
    "Modules/Movement/GravityModifier",
    "Modules/Movement/AntiAnchor",
    "Modules/Movement/AntiSit",
    "Modules/Movement/HeadSit",
    "Modules/Movement/AirSwim",

    "Modules/Render/ESPBoxOutlines",
    "Modules/Render/ESPTracerLines",
    "Modules/Render/ShowPlayerNames",
    "Modules/Render/ShowHealthText",
    "Modules/Render/ShowDistanceText",
    "Modules/Render/DistanceBasedESP",
    "Modules/Render/SkeletonESP",
    "Modules/Render/Chams",
    "Modules/Render/SkipTeammates",
    "Modules/Render/LineOfSight",
    "Modules/Render/NetworkUserTags",
    "Modules/Render/MapXRay",
    "Modules/Render/ClearVision",
    "Modules/Render/No3DRendering",
    "Modules/Render/LagReducer",
    "Modules/Render/FullBrightMode",
    "Modules/Render/TimeofDayCycle",
    "Modules/Render/FieldofView",
    "Modules/Render/OutOfViewIndicators",
    "Modules/Render/Minimap",

    "Modules/World/InstantPrompts",
    "Modules/World/FireAllPrompts",
    "Modules/World/FireCDDetectors",
    "Modules/World/AutoTriggerPrompts",
    "Modules/World/ToolMagnet",
    "Modules/World/AutoJumpEdges",
    "Modules/World/AntiFlingSystem",
    "Modules/World/SaveCurrentLocation",
    "Modules/World/WarptoSavedLocation",
    "Modules/World/DestroyKillbricks",
    "Modules/World/DestroySeats",
    "Modules/World/AntiVoidNet",
    "Modules/World/FireTouchinterests",

    "Modules/Misc/ServerControls",
    "Modules/Misc/FavoritesManager",
    "Modules/Misc/OnlineFriends",
    "Modules/Misc/ChatLogger",
    "Modules/Misc/ExternalScriptsHub",
    "Modules/Misc/UNCcomplianceAudits",
    "Modules/Misc/ConsoleLogViewer",
    "Modules/Misc/SettingsKeybinds",
    "Modules/Misc/NetworkChatHub",
    "Modules/Misc/SaveGame"
}

local success, err = pcall(function()
    for _, modulePath in ipairs(CoreModules) do
        runFile(modulePath)
    end

    if VH.UI and VH.UI.InitializeUI then
        VH.UI.InitializeUI()
    end

    for _, modulePath in ipairs(Modules) do
        runFile(modulePath)
    end

    runFile("Core/Runtime")
end)

if not success then
    warn("[WASOR Loader] Initialization error: " .. tostring(err))
else
    print("[WASOR] Loader: FileBuild")
end
