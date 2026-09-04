if _G.WASOR_Loading then return end
_G.WASOR_Loading = true

if _G.VoidHub and type(_G.VoidHub) == "table" and _G.VoidHub.Cleanup and _G.VoidHub.Cleanup.cleanupAll then
    pcall(_G.VoidHub.Cleanup.cleanupAll)
end

pcall(function()
    if delfile and isfile and isfile("autoexec/WASOR.lua") then
        delfile("autoexec/WASOR.lua")
    end
end)

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

local GITHUB_USERNAME = "VenezzaX"
local GITHUB_REPO = "WASORCLASSIC"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USERNAME, GITHUB_REPO, GITHUB_BRANCH)

local CoreModules = {
    "Core/Services",
    "Core/State",
    "Core/Utils",
    "Core/Config",
    "Core/Logger",
    "Core/Cleanup",
    "Core/UI"
}

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
    "Modules/Render/ESPPreview",
    "Modules/Render/PaperDollHUD",
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

local hasFileSystem = (writefile and readfile and isfile and makefolder and isfolder)

local function writeCrashLog(context, err, stack)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local crashMsg = string.format("==================== CRASH LOG [%s] ====================\nContext: %s\nError: %s\nTraceback:\n%s\n=================================================================\n\n", timestamp, tostring(context), tostring(err), tostring(stack or "N/A"))
    warn(string.format("[WASOR CRASH] [%s] Error: %s\nTraceback:\n%s", tostring(context), tostring(err), tostring(stack or "")))
    pcall(function()
        if writefile then
            local filename = "WASOR_crash.log"
            if isfile and isfile(filename) then
                if appendfile then
                    appendfile(filename, crashMsg)
                else
                    local cur = readfile(filename)
                    writefile(filename, cur .. crashMsg)
                end
            else
                writefile(filename, crashMsg)
            end
        end
    end)
end

local function httpRequest(url)
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    if reqFn then
        local ok, res = pcall(reqFn, {
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache"
            }
        })
        if ok and res and type(res) == "table" then
            local body = res.Body or res.body or res.data or res.Data
            local status = res.StatusCode or res.status_code or res.Status or res.status or 200
            if (status == 200 or status == "OK") and type(body) == "string" and #body > 0 then
                return body
            end
        end
    end
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" and #res > 0 then
        return res
    end
    return nil
end

local function getLatestCommitSHA()
    local apiUrl = string.format("https://api.github.com/repos/%s/%s/commits/%s", GITHUB_USERNAME, GITHUB_REPO, GITHUB_BRANCH)
    local response = httpRequest(apiUrl)
    if response then
        local sha = response:match('"sha"%s*:%s*"([^"]+)"')
        return sha
    end
    return nil
end

local forceUpdate = (_G.WASOR_FORCE_UPDATE == true or _G.WASOR_NO_CACHE == true)
local cachedSHA = nil
local latestSHA = nil
local useCache = false

if hasFileSystem then
    if not isfolder("WASOR_Classic_Cache") then
        pcall(makefolder, "WASOR_Classic_Cache")
    end
    if forceUpdate then
        pcall(delfile, "WASOR_Classic_Cache/commit_sha.txt")
    elseif isfile("WASOR_Classic_Cache/commit_sha.txt") then
        local success, val = pcall(readfile, "WASOR_Classic_Cache/commit_sha.txt")
        if success then cachedSHA = val end
    end
    if not forceUpdate then
        latestSHA = getLatestCommitSHA()
        if latestSHA and cachedSHA and latestSHA == cachedSHA then
            useCache = true
        end
    end
end

local downloadFailed = false

local function runFile(path)
    local content = nil
    local cachePath = "WASOR_Classic_Cache/" .. path .. ".lua"
    
    if useCache and hasFileSystem and isfile(cachePath) then
        local success, cachedCode = pcall(readfile, cachePath)
        if success and cachedCode and #cachedCode > 0 then
            content = cachedCode
        end
    end
    
    if not content then
        local url
        if latestSHA then
            url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s.lua", GITHUB_USERNAME, GITHUB_REPO, latestSHA, path)
        else
            url = BASE_URL .. path .. ".lua?t=" .. tostring(os.time())
        end
        local result = httpRequest(url)
        if not result and latestSHA then
            result = httpRequest(BASE_URL .. path .. ".lua")
        end
        
        if result and #result > 0 then
            content = result
            if hasFileSystem then
                local folderPath = cachePath:match("(.+)/[^/]+$")
                if folderPath and not isfolder(folderPath) then
                    pcall(makefolder, folderPath)
                end
                pcall(writefile, cachePath, result)
            end
        else
            downloadFailed = true
            if hasFileSystem and isfile(cachePath) then
                local success, cachedCode = pcall(readfile, cachePath)
                if success and cachedCode and #cachedCode > 0 then
                    content = cachedCode
                end
            end
        end
    end
    
    if content then
        local func, err = loadstring(content, path)
        if func then
            local errTrace = nil
            local runSuccess, runErr = xpcall(func, function(e)
                errTrace = debug.traceback(tostring(e), 2)
                return e
            end)
            if not runSuccess then
                writeCrashLog("Runtime Error in " .. path, runErr, errTrace)
            end
        else
            writeCrashLog("Parse Error in " .. path, err, debug.traceback())
        end
    else
        writeCrashLog("Download Failed", "Failed to retrieve " .. path, debug.traceback())
    end
end

local initSuccess, initErr = pcall(function()
    for _, modulePath in ipairs(CoreModules) do
        runFile(modulePath)
    end

    if _G.VoidHub and _G.VoidHub.UI and _G.VoidHub.UI.InitializeUI then
        _G.VoidHub.UI.InitializeUI()
    end

    for _, modulePath in ipairs(Modules) do
        runFile(modulePath)
    end

    runFile("Core/Runtime")
end)

_G.WASOR_Loading = false
_G.WASOR_Loaded = true

if not initSuccess then
    writeCrashLog("Loader Initialization", initErr, debug.traceback())
else
    print("[WASOR] Loader: FileBuild (GitHub)")
end

if not useCache and hasFileSystem and latestSHA and not downloadFailed then
    pcall(writefile, "WASOR_Classic_Cache/commit_sha.txt", latestSHA)
end
