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

local Wallpapers = {
    "https://i.pinimg.com/1200x/97/e4/f7/97e4f7952175029a8a606ebbc279b169.jpg",
    "https://i.pinimg.com/1200x/e1/95/97/e195971a0e803c0501e1617d4a644bfd.jpg",
    "https://i.pinimg.com/736x/43/6f/d7/436fd71cea52fa6423442a0ea809c960.jpg",
    "https://i.pinimg.com/736x/8b/30/4b/8b304b04d4cc2f398aa29e4687331bb0.jpg",
    "https://i.pinimg.com/1200x/72/20/2c/72202c9a1510560d0b79b168662c2a5f.jpg",
    "https://i.pinimg.com/736x/a3/71/5c/a3715cfcf007a932d9d1944c30d21b57.jpg",
    "https://i.pinimg.com/1200x/e8/ca/70/e8ca70cc4cc7132799c9d69936705507.jpg",
    "https://i.pinimg.com/736x/c3/25/21/c3252117e76c482e708f8b15cd7284af.jpg",
    "https://i.pinimg.com/1200x/91/9e/01/919e0112d159fb574650d937eee6ed72.jpg",
    "https://i.pinimg.com/1200x/54/09/0c/54090c9c283f5c88f6aff0a7ea5d157c.jpg",
    "https://i.pinimg.com/736x/79/a0/4e/79a04e89d83970afaa524574858a7f71.jpg",
    "https://i.pinimg.com/1200x/b1/10/99/b11099a740518d4a62329925f7de746e.jpg",
    "https://i.pinimg.com/1200x/66/7c/98/667c9833dc1af0f62fba85f03fb1b4db.jpg",
    "https://i.pinimg.com/1200x/fd/ca/88/fdca880e184501f6d81cc921c194429a.jpg",
    "https://i.pinimg.com/736x/5e/08/9c/5e089c57eecac254f7c38db3a06866da.jpg",
    "https://i.pinimg.com/736x/2f/a6/e3/2fa6e31d0ab6f3c4dd7ef7d38da1567b.jpg",
    "https://i.pinimg.com/736x/38/a1/79/38a179e084924541a37184547b42f255.jpg",
    "https://i.pinimg.com/736x/0b/a7/6a/0ba76ac5e70edf6868ef4c0b6c908e77.jpg",
    "https://i.pinimg.com/736x/09/d6/c3/09d6c3bbef9df6c12585b78f3db8369f.jpg",
    "https://i.pinimg.com/736x/00/5f/0e/005f0e599757b20d1b2272f3425372d2.jpg",
    "https://i.pinimg.com/736x/f5/40/66/f540661fff65ea19ea159536d80e73fb.jpg",
    "https://i.pinimg.com/1200x/7b/4d/48/7b4d48d372320cc67b6a88d6712efb50.jpg",
    "https://i.pinimg.com/1200x/e6/6d/f0/e66df06af7f73694cf196c07757ce814.jpg",
    "https://i.pinimg.com/736x/34/bf/fa/34bffa64c7815e353a9190b714aa8edf.jpg"
}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function getSafeContainer()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if get_hidden_gui then
        local ok, hg = pcall(get_hidden_gui)
        if ok and hg then return hg end
    end
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenContainer = getSafeContainer()

for _, child in ipairs(ScreenContainer:GetChildren()) do
    if child.Name == "WASOR_Minimal_LoadingScreen" then
        pcall(function() child:Destroy() end)
    end
end

local entropy = os.time() + math.floor(os.clock() * 1000000) + math.floor(tick() * 1000)
math.randomseed(entropy)
local rng = Random.new(entropy)
for _ = 1, math.random(3, 7) do rng:NextNumber() end

local chosenIndex = rng:NextInteger(1, #Wallpapers)
local chosenUrl = Wallpapers[chosenIndex]

local function loadWallpaper(url)
    local hasFs = (writefile and readfile and isfile)
    local customAssetFn = getcustomasset or getsynasset or (syn and syn.cache_replace)
    if not customAssetFn then return nil end

    local folder = "WASOR_Assets"
    if makefolder and isfolder and not isfolder(folder) then
        pcall(makefolder, folder)
    end

    local imageHash = url:match("([^/]+)%.jpg$") or tostring(math.random(1000, 9999))
    local localPath = string.format("%s/wp_%s.jpg", folder, imageHash)

    if hasFs and isfile(localPath) then
        local ok, asset = pcall(customAssetFn, localPath)
        if ok and asset then return asset end
    end

    local data = nil
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local ok, res = pcall(req, {
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = "Mozilla/5.0" }
        })
        if ok and res and type(res) == "table" then
            local body = res.Body or res.body or res.Data or res.data
            if type(body) == "string" and #body > 0 then data = body end
        end
    end

    if not data then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" and #res > 0 then data = res end
    end

    if data and hasFs then
        pcall(writefile, localPath, data)
        local ok, asset = pcall(customAssetFn, localPath)
        if ok and asset then return asset end
    end

    return nil
end

local wallpaperAsset = loadWallpaper(chosenUrl)

local LoadingScreenGui = Instance.new("ScreenGui")
LoadingScreenGui.Name = "WASOR_Minimal_LoadingScreen"
LoadingScreenGui.ResetOnSpawn = false
LoadingScreenGui.IgnoreGuiInset = true
LoadingScreenGui.DisplayOrder = 2147483647
LoadingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

pcall(function() LoadingScreenGui.ScreenInsets = Enum.ScreenInsets.None end)
pcall(function() LoadingScreenGui.ClipToDeviceSafeArea = false end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 2147483640
MainFrame.Parent = LoadingScreenGui

local BgImage = Instance.new("ImageLabel")
BgImage.Name = "BgImage"
BgImage.Size = UDim2.new(1, 0, 1, 0)
BgImage.Position = UDim2.new(0, 0, 0, 0)
BgImage.BackgroundTransparency = 1
BgImage.ScaleType = Enum.ScaleType.Crop
BgImage.ImageTransparency = 1
BgImage.ZIndex = 2147483641

if wallpaperAsset then
    BgImage.Image = wallpaperAsset
else
    BgImage.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
    BgImage.BackgroundTransparency = 0
end
BgImage.Parent = MainFrame

local RightContainer = Instance.new("Frame")
RightContainer.Name = "RightContainer"
RightContainer.AnchorPoint = Vector2.new(1, 1)
RightContainer.Position = UDim2.new(1, -44, 1, -40)
RightContainer.Size = UDim2.new(0, 360, 0, 110)
RightContainer.BackgroundTransparency = 1
RightContainer.ZIndex = 2147483644
RightContainer.Parent = MainFrame

local SizeConstraint = Instance.new("UISizeConstraint")
SizeConstraint.MaxSize = Vector2.new(420, 120)
SizeConstraint.MinSize = Vector2.new(260, 95)
SizeConstraint.Parent = RightContainer

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "W - A - S - O - R"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 24
TitleLabel.TextXAlignment = Enum.TextXAlignment.Right
TitleLabel.ZIndex = 2147483645
TitleLabel.Parent = RightContainer

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(0, 0, 0)
TitleStroke.Thickness = 1.8
TitleStroke.Transparency = 0.3
TitleStroke.Parent = TitleLabel

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.Size = UDim2.new(1, 0, 0, 18)
SubtitleLabel.Position = UDim2.new(0, 0, 0, 32)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.Text = "We Are Skidding On Roblox"
SubtitleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
SubtitleLabel.TextSize = 13
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
SubtitleLabel.ZIndex = 2147483645
SubtitleLabel.Parent = RightContainer

local SubtitleStroke = Instance.new("UIStroke")
SubtitleStroke.Color = Color3.fromRGB(0, 0, 0)
SubtitleStroke.Thickness = 1.4
SubtitleStroke.Transparency = 0.4
SubtitleStroke.Parent = SubtitleLabel

local StatusRow = Instance.new("Frame")
StatusRow.Name = "StatusRow"
StatusRow.Size = UDim2.new(1, 0, 0, 16)
StatusRow.Position = UDim2.new(0, 0, 0, 60)
StatusRow.BackgroundTransparency = 1
StatusRow.ZIndex = 2147483645
StatusRow.Parent = RightContainer

local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(0.8, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Gotham
StatusText.Text = "Initializing WASOR..."
StatusText.TextColor3 = Color3.fromRGB(210, 210, 225)
StatusText.TextSize = 11
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.ZIndex = 2147483646
StatusText.Parent = StatusRow

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(0, 0, 0)
StatusStroke.Thickness = 1.2
StatusStroke.Transparency = 0.5
StatusStroke.Parent = StatusText

local PercentText = Instance.new("TextLabel")
PercentText.Name = "PercentText"
PercentText.Size = UDim2.new(0.2, 0, 1, 0)
PercentText.Position = UDim2.new(0.8, 0, 0, 0)
PercentText.BackgroundTransparency = 1
PercentText.Font = Enum.Font.GothamBold
PercentText.Text = "0%"
PercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
PercentText.TextSize = 12
PercentText.TextXAlignment = Enum.TextXAlignment.Right
PercentText.ZIndex = 2147483646
PercentText.Parent = StatusRow

local PercentStroke = Instance.new("UIStroke")
PercentStroke.Color = Color3.fromRGB(0, 0, 0)
PercentStroke.Thickness = 1.2
PercentStroke.Transparency = 0.5
PercentStroke.Parent = PercentText

local BarTrack = Instance.new("Frame")
BarTrack.Name = "BarTrack"
BarTrack.Size = UDim2.new(1, 0, 0, 3)
BarTrack.Position = UDim2.new(0, 0, 0, 84)
BarTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarTrack.BackgroundTransparency = 0.8
BarTrack.BorderSizePixel = 0
BarTrack.ZIndex = 2147483645
BarTrack.Parent = RightContainer

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent = BarTrack

local BarFill = Instance.new("Frame")
BarFill.Name = "BarFill"
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarFill.BackgroundTransparency = 0
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 2147483646
BarFill.Parent = BarTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = BarFill

local BarTip = Instance.new("Frame")
BarTip.Name = "BarTip"
BarTip.AnchorPoint = Vector2.new(1, 0.5)
BarTip.Size = UDim2.new(0, 8, 2.5, 0)
BarTip.Position = UDim2.new(1, 0, 0.5, 0)
BarTip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarTip.BackgroundTransparency = 0.25
BarTip.BorderSizePixel = 0
BarTip.ZIndex = 2147483647
BarTip.Parent = BarFill

local TipCorner = Instance.new("UICorner")
TipCorner.CornerRadius = UDim.new(1, 0)
TipCorner.Parent = BarTip

LoadingScreenGui.Parent = ScreenContainer

TweenService:Create(BgImage, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    ImageTransparency = 0
}):Play()

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
    "Modules/Render/SkyboxChanger",

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

local totalModules = #CoreModules + #Modules + 2
local currentLoaded = 0

local function updateLoaderProgress(name)
    currentLoaded = currentLoaded + 1
    local alpha = math.clamp(currentLoaded / totalModules, 0, 1)
    if BarFill then
        TweenService:Create(BarFill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(alpha, 0, 1, 0)
        }):Play()
    end
    if StatusText then
        StatusText.Text = name or "Loading..."
    end
    if PercentText then
        PercentText.Text = math.floor(alpha * 100) .. "%"
    end
end

local initSuccess, initErr = pcall(function()
    for _, modulePath in ipairs(CoreModules) do
        updateLoaderProgress(modulePath)
        runFile(modulePath)
    end

    if _G.VoidHub and _G.VoidHub.UI and _G.VoidHub.UI.InitializeUI then
        updateLoaderProgress("Core/UI")
        _G.VoidHub.UI.InitializeUI()
    end

    for _, modulePath in ipairs(Modules) do
        updateLoaderProgress(modulePath)
        runFile(modulePath)
    end

    updateLoaderProgress("Core/Runtime")
    runFile("Core/Runtime")
end)

if BarFill then BarFill.Size = UDim2.new(1, 0, 1, 0) end
if PercentText then PercentText.Text = "100%" end
if StatusText then StatusText.Text = "Ready!" end
task.wait(0.5)

if BgImage then
    local fadeBg = TweenService:Create(BgImage, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { 
        ImageTransparency = 1 
    })
    fadeBg:Play()

    for _, desc in ipairs(RightContainer:GetDescendants()) do
        if desc:IsA("TextLabel") then
            TweenService:Create(desc, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        elseif desc:IsA("UIStroke") then
            TweenService:Create(desc, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
        elseif desc:IsA("Frame") then
            TweenService:Create(desc, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        end
    end

    fadeBg.Completed:Wait()
    if LoadingScreenGui then LoadingScreenGui:Destroy() end
end

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
