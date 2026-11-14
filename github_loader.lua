local function checkDeltaCompatibility()
    local function isDeltaExecutor()
        local getExec = identifyexecutor or getexecutorname
        if type(getExec) == "function" then
            local success, execName = pcall(getExec)
            if success and type(execName) == "string" then
                if string.find(string.lower(execName), "delta", 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function loadDeltaKeyboard()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/MobileKeyboard/refs/heads/main/Keyboard.lua'), true))()
        end)
        if not ok then
            warn("[Delta Loader] Failed to load MobileKeyboard: " .. tostring(err))
        end
    end

    if not isDeltaExecutor() then
        return
    end

    task.spawn(function()
        local promptFile = "WASOR_Cache/delta_kb_prompt.txt"
        local savedChoice = nil

        pcall(function()
            if isfile and readfile and isfile(promptFile) then
                local content = readfile(promptFile)
                if content == "yes" or content == "no" then
                    savedChoice = content
                end
            end
        end)

        if savedChoice == "yes" then
            loadDeltaKeyboard()
            return
        elseif savedChoice == "no" then
            return
        end

        local parentGui = nil
        if gethui then
            pcall(function() parentGui = gethui() end)
        end
        if not parentGui and get_hidden_gui then
            pcall(function() parentGui = get_hidden_gui() end)
        end
        if not parentGui then
            pcall(function() parentGui = game:GetService("CoreGui") end)
        end
        if not parentGui then
            local lp = game:GetService("Players").LocalPlayer or game:GetService("Players").PlayerAdded:Wait()
            parentGui = lp:WaitForChild("PlayerGui")
        end

        local oldPrompt = parentGui:FindFirstChild("WASOR_DeltaKeyboardPrompt")
        if oldPrompt then
            pcall(function() oldPrompt:Destroy() end)
        end

        local PromptGui = Instance.new("ScreenGui")
        PromptGui.Name = "WASOR_DeltaKeyboardPrompt"
        PromptGui.ResetOnSpawn = false
        PromptGui.IgnoreGuiInset = true
        PromptGui.DisplayOrder = 2147483647
        PromptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local Card = Instance.new("Frame")
        Card.Name = "PromptCard"
        Card.AnchorPoint = Vector2.new(0.5, 0.5)
        Card.Position = UDim2.new(0.5, 0, 0.5, 0)
        Card.Size = UDim2.new(0, 360, 0, 205)
        Card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        Card.BackgroundTransparency = 0.05
        Card.BorderSizePixel = 0
        Card.Parent = PromptGui

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 10)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = Color3.fromRGB(130, 95, 255)
        CardStroke.Thickness = 1.4
        CardStroke.Transparency = 0.2
        CardStroke.Parent = Card

        local Header = Instance.new("TextLabel")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, -32, 0, 24)
        Header.Position = UDim2.new(0, 16, 0, 14)
        Header.BackgroundTransparency = 1
        Header.Font = Enum.Font.GothamBold
        Header.Text = "WASOR  •  Delta Compatibility"
        Header.TextColor3 = Color3.fromRGB(240, 240, 250)
        Header.TextSize = 14
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.Parent = Card

        local Message = Instance.new("TextLabel")
        Message.Name = "Message"
        Message.Size = UDim2.new(1, -32, 0, 42)
        Message.Position = UDim2.new(0, 16, 0, 42)
        Message.BackgroundTransparency = 1
        Message.Font = Enum.Font.GothamMedium
        Message.Text = "This code hasn't been made for delta but you can try using the Delta keyboard"
        Message.TextColor3 = Color3.fromRGB(215, 215, 230)
        Message.TextSize = 13
        Message.TextWrapped = true
        Message.TextXAlignment = Enum.TextXAlignment.Left
        Message.TextYAlignment = Enum.TextYAlignment.Top
        Message.Parent = Card

        local WarningLabel = Instance.new("TextLabel")
        WarningLabel.Name = "WarningLabel"
        WarningLabel.Size = UDim2.new(1, -32, 0, 30)
        WarningLabel.Position = UDim2.new(0, 16, 0, 86)
        WarningLabel.BackgroundTransparency = 1
        WarningLabel.Font = Enum.Font.Gotham
        WarningLabel.Text = "Experimental feature — hiding this prompt forever is not recommended."
        WarningLabel.TextColor3 = Color3.fromRGB(255, 185, 95)
        WarningLabel.TextSize = 11
        WarningLabel.TextWrapped = true
        WarningLabel.TextXAlignment = Enum.TextXAlignment.Left
        WarningLabel.TextYAlignment = Enum.TextYAlignment.Top
        WarningLabel.Parent = Card

        local hideForever = false

        local CheckRow = Instance.new("TextButton")
        CheckRow.Name = "HideForeverToggle"
        CheckRow.Size = UDim2.new(1, -32, 0, 22)
        CheckRow.Position = UDim2.new(0, 16, 0, 122)
        CheckRow.BackgroundTransparency = 1
        CheckRow.Text = ""
        CheckRow.AutoButtonColor = false
        CheckRow.Parent = Card

        local CheckBox = Instance.new("Frame")
        CheckBox.Name = "CheckBox"
        CheckBox.Size = UDim2.new(0, 16, 0, 16)
        CheckBox.Position = UDim2.new(0, 0, 0.5, -8)
        CheckBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        CheckBox.BorderSizePixel = 0
        CheckBox.Parent = CheckRow

        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 4)
        BoxCorner.Parent = CheckBox

        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Color3.fromRGB(130, 95, 255)
        BoxStroke.Thickness = 1.2
        BoxStroke.Parent = CheckBox

        local CheckMark = Instance.new("TextLabel")
        CheckMark.Name = "CheckMark"
        CheckMark.Size = UDim2.new(1, 0, 1, 0)
        CheckMark.BackgroundTransparency = 1
        CheckMark.Font = Enum.Font.GothamBold
        CheckMark.Text = "✓"
        CheckMark.TextColor3 = Color3.fromRGB(255, 255, 255)
        CheckMark.TextSize = 12
        CheckMark.Visible = false
        CheckMark.Parent = CheckBox

        local CheckText = Instance.new("TextLabel")
        CheckText.Name = "CheckText"
        CheckText.Size = UDim2.new(1, -24, 1, 0)
        CheckText.Position = UDim2.new(0, 24, 0, 0)
        CheckText.BackgroundTransparency = 1
        CheckText.Font = Enum.Font.Gotham
        CheckText.Text = "Hide forever (Not recommended)"
        CheckText.TextColor3 = Color3.fromRGB(185, 185, 205)
        CheckText.TextSize = 12
        CheckText.TextXAlignment = Enum.TextXAlignment.Left
        CheckText.Parent = CheckRow

        CheckRow.MouseButton1Click:Connect(function()
            hideForever = not hideForever
            CheckMark.Visible = hideForever
            CheckBox.BackgroundColor3 = hideForever and Color3.fromRGB(130, 95, 255) or Color3.fromRGB(28, 28, 38)
        end)

        local YesBtn = Instance.new("TextButton")
        YesBtn.Name = "YesButton"
        YesBtn.Size = UDim2.new(0.5, -20, 0, 34)
        YesBtn.Position = UDim2.new(0, 16, 1, -46)
        YesBtn.BackgroundColor3 = Color3.fromRGB(130, 95, 255)
        YesBtn.BorderSizePixel = 0
        YesBtn.Font = Enum.Font.GothamBold
        YesBtn.Text = "Yes"
        YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        YesBtn.TextSize = 13
        YesBtn.Parent = Card

        local YesCorner = Instance.new("UICorner")
        YesCorner.CornerRadius = UDim.new(0, 7)
        YesCorner.Parent = YesBtn

        local NoBtn = Instance.new("TextButton")
        NoBtn.Name = "NoButton"
        NoBtn.Size = UDim2.new(0.5, -20, 0, 34)
        NoBtn.Position = UDim2.new(0.5, 4, 1, -46)
        NoBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
        NoBtn.BorderSizePixel = 0
        NoBtn.Font = Enum.Font.GothamBold
        NoBtn.Text = "No"
        NoBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
        NoBtn.TextSize = 13
        NoBtn.Parent = Card

        local NoCorner = Instance.new("UICorner")
        NoCorner.CornerRadius = UDim.new(0, 7)
        NoCorner.Parent = NoBtn

        local function finishPrompt(accepted)
            if hideForever then
                pcall(function()
                    if makefolder and isfolder and not isfolder("WASOR_Cache") then
                        makefolder("WASOR_Cache")
                    end
                    if writefile then
                        writefile(promptFile, accepted and "yes" or "no")
                    end
                end)
            end
            pcall(function()
                PromptGui:Destroy()
            end)
            if accepted then
                loadDeltaKeyboard()
            end
        end

        YesBtn.MouseButton1Click:Connect(function()
            finishPrompt(true)
        end)

        NoBtn.MouseButton1Click:Connect(function()
            finishPrompt(false)
        end)

        PromptGui.Parent = parentGui
    end)
end

checkDeltaCompatibility()

if _G.WASOR_Reloading then return end
if _G.VoidHub or _G.WASOR_Loaded or _G.WASOR_Loading then
    _G.WASOR_Reloading = true
    pcall(function()
        if _G.VoidHub and type(_G.VoidHub) == "table" and _G.VoidHub.Cleanup and _G.VoidHub.Cleanup.cleanupAll then
            _G.VoidHub.Cleanup.cleanupAll()
        end
    end)
    _G.VoidHub = nil
    _G.WASOR_Loading = nil
    _G.WASOR_Loaded = nil
    _G.WASOR_Reloading = nil
    print("[WASOR 4.5] Existing instance detected. Cleaned up and reloading...")
end
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
    pcall(function() RunService:UnbindFromRenderStep("WallWalkCameraRenderUpdate") end)
    pcall(function() RunService:UnbindFromRenderStep("WallWalkControlStep") end)
    pcall(function() RunService:UnbindFromRenderStep("WallWalkGravityStep") end)
end)

pcall(function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CanCollide = false end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Sound") and string.sub(d.Name, 1, 3) == "WW_" then
                pcall(function() d:Destroy() end)
            end
        end
    end
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
                if child.Name == "MeteorRobloxGUI" or child.Name == "WallWalkToggleUI" or child.Name == "DiscordNetworkHub" or child.Name == "MinimapGui" or child.Name == "VoidCustomNametag" or child.Name == "EulaFrame" or child.Name == "WASOR_PaperDollHUD" or child.Name == "WASOR_ESPPreviewGui" or child.Name == "MinimalVisualizerGui" or child.Name == "VoidNo3DCoverGui" or child.Name == "TranscendingViewportGui" or child:FindFirstChild("MainUIContainer") or child:FindFirstChild("StudioTopRibbon") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
end)

_G.VoidHub = {}

local Wallpapers = {
    "https://i.pinimg.com/736x/3d/60/f1/3d60f1d1d3d16d222b0e9944cc26c631.jpg",
    "https://i.pinimg.com/1200x/28/e2/57/28e257b746182ca3b70ce04f2785a35f.jpg",
    "https://i.pinimg.com/736x/7f/17/d8/7f17d86c487a8a1072122d3a084d7e6f.jpg",
    "https://i.pinimg.com/1200x/3a/b9/fe/3ab9febe374d7adde7f69464df9129c8.jpg",
    "https://i.pinimg.com/736x/e6/29/a7/e629a7903924beb41bd1586255502667.jpg",
    "https://i.pinimg.com/736x/a4/50/8b/a4508bab44e95df8b5bf7a6bab405d77.jpg",
    "https://i.pinimg.com/736x/30/50/4c/30504cd470176b3b369b80aa52750de3.jpg",
    "https://i.pinimg.com/736x/f8/dc/d4/f8dcd4d0bf9c7f4452052d319c913b2a.jpg",
    "https://i.pinimg.com/1200x/3e/1d/84/3e1d84ed48093d0960d50afc8165004e.jpg",
    "https://i.pinimg.com/736x/d5/4e/d3/d54ed3a47092eedef1e80791f7b202ea.jpg",
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

local loadingScreenMode = "Normal"
pcall(function()
    if readfile and isfile then
        if isfile("WASOR_Cache/loading_mode.txt") then
            local mode = readfile("WASOR_Cache/loading_mode.txt")
            if mode and #mode > 0 then loadingScreenMode = mode end
        elseif isfile("utility_hub_config.json") then
            local HttpService = game:GetService("HttpService")
            local cfg = HttpService:JSONDecode(readfile("utility_hub_config.json"))
            if cfg and cfg.LoadingScreenMode then
                loadingScreenMode = cfg.LoadingScreenMode
            end
        end
    end
end)

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

local LoadingScreenGui = nil
local MainFrame = nil
local BgImage = nil
local RightContainer = nil
local BarFill = nil
local StatusText = nil
local PercentText = nil

if loadingScreenMode ~= "Fully Hidden" then
    local wallpaperAsset = nil
    if loadingScreenMode == "Normal" then
        local entropy = os.time() + math.floor(os.clock() * 1000000) + math.floor(tick() * 1000)
        math.randomseed(entropy)
        local rng = Random.new(entropy)
        for _ = 1, math.random(3, 7) do rng:NextNumber() end
        local chosenIndex = rng:NextInteger(1, #Wallpapers)
        local chosenUrl = Wallpapers[chosenIndex]
        wallpaperAsset = loadWallpaper(chosenUrl)
    end

    LoadingScreenGui = Instance.new("ScreenGui")
    LoadingScreenGui.Name = "WASOR_Minimal_LoadingScreen"
    LoadingScreenGui.ResetOnSpawn = false
    LoadingScreenGui.IgnoreGuiInset = true
    LoadingScreenGui.DisplayOrder = 2147483647
    LoadingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    pcall(function() LoadingScreenGui.ScreenInsets = Enum.ScreenInsets.None end)
    pcall(function() LoadingScreenGui.ClipToDeviceSafeArea = false end)

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.Position = UDim2.new(0, 0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 2147483640

    if loadingScreenMode == "Transparent" then
        MainFrame.BackgroundTransparency = 1
        MainFrame.Active = false
    elseif loadingScreenMode == "No Image" then
        MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 16)
        MainFrame.BackgroundTransparency = 0
        MainFrame.Active = true
    else
        MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        MainFrame.BackgroundTransparency = 0
        MainFrame.Active = true
    end
    MainFrame.Parent = LoadingScreenGui

    if loadingScreenMode == "Normal" then
        BgImage = Instance.new("ImageLabel")
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
    end

    RightContainer = Instance.new("Frame")
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

    StatusText = Instance.new("TextLabel")
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

    PercentText = Instance.new("TextLabel")
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

    BarFill = Instance.new("Frame")
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

    if BgImage then
        TweenService:Create(BgImage, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 0
        }):Play()
    end
end

local GITHUB_USERNAME = "MizunoSync"
local GITHUB_REPO = "WASOR"
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
    "Modules/Player/HatDrop",
    "Modules/Player/ReturnByDeath",

    "Modules/Movement/SpeedModification",
    "Modules/Movement/SprintSpeedBoost",
    "Modules/Movement/JumpHackStrength",
    "Modules/Movement/Climb",
    "Modules/Movement/WallRun",
    "Modules/Movement/WallWalk",
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
    "Modules/Render/AudioVisualizer",
    "Modules/Render/ViewportESP",

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
    "Modules/Misc/HideLoadingScreen",
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
    local patchUrl = string.format("https://github.com/%s/%s/commit/%s.patch", GITHUB_USERNAME, GITHUB_REPO, GITHUB_BRANCH)
    local patchRes = httpRequest(patchUrl)
    if patchRes and type(patchRes) == "string" then
        local sha = patchRes:match("From%s+(%w+)")
        if sha and #sha == 40 then
            return sha
        end
    end

    local atomUrl = string.format("https://github.com/%s/%s/commits/%s.atom", GITHUB_USERNAME, GITHUB_REPO, GITHUB_BRANCH)
    local atomRes = httpRequest(atomUrl)
    if atomRes and type(atomRes) == "string" then
        local sha = atomRes:match("Commit/(%w+)")
        if sha and #sha == 40 then
            return sha
        end
    end

    local apiUrl = string.format("https://api.github.com/repos/%s/%s/commits/%s", GITHUB_USERNAME, GITHUB_REPO, GITHUB_BRANCH)
    local response = httpRequest(apiUrl)
    if response and type(response) == "string" then
        local sha = response:match('"sha"%s*:%s*"([^"]+)"')
        if sha and #sha == 40 then
            return sha
        end
    end

    return nil
end

local forceUpdate = (_G.WASOR_FORCE_UPDATE == true or _G.WASOR_NO_CACHE == true)
local cachedSHA = nil
local latestSHA = nil
local useCache = false

if hasFileSystem then
    if not isfolder("WASOR_Cache") then
        pcall(makefolder, "WASOR_Cache")
    end
    if forceUpdate then
        pcall(delfile, "WASOR_Cache/commit_sha.txt")
    elseif isfile("WASOR_Cache/commit_sha.txt") then
        local success, val = pcall(readfile, "WASOR_Cache/commit_sha.txt")
        if success and val and type(val) == "string" and #val >= 7 then
            cachedSHA = val:gsub("%s+", "")
        end
    end
    if not forceUpdate then
        latestSHA = getLatestCommitSHA()
        if latestSHA and type(latestSHA) == "string" then
            latestSHA = latestSHA:gsub("%s+", "")
        end
        if latestSHA and cachedSHA and latestSHA == cachedSHA then
            useCache = true
        elseif not latestSHA and cachedSHA then
            useCache = true
        end
    end
end

local downloadFailed = false

local function runFile(path)
    local content = nil
    local cachePath = "WASOR_Cache/" .. path .. ".lua"

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
        local c = _G.VoidHub.UI.GetMainContainer and _G.VoidHub.UI.GetMainContainer()
        if c then c.Visible = false end
    end

    for _, modulePath in ipairs(Modules) do
        updateLoaderProgress(modulePath)
        runFile(modulePath)
    end

    updateLoaderProgress("Core/Runtime")
    runFile("Core/Runtime")

    local c = _G.VoidHub and _G.VoidHub.UI and _G.VoidHub.UI.GetMainContainer and _G.VoidHub.UI.GetMainContainer()
    if c and _G.VoidHub.State and _G.VoidHub.State.uiVisible ~= false then
        if _G.VoidHub.State.S and _G.VoidHub.State.S.EulaAccepted == true then
            c.Visible = true
        end
    end
end)

if BarFill then BarFill.Size = UDim2.new(1, 0, 1, 0) end
if PercentText then PercentText.Text = "100%" end
if StatusText then StatusText.Text = "Ready!" end

if LoadingScreenGui and LoadingScreenGui.Parent then
    task.wait(0.3)
    local fadeBg = nil
    if BgImage and BgImage.Parent then
        fadeBg = TweenService:Create(BgImage, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        })
        fadeBg:Play()
    end

    if RightContainer and RightContainer.Parent then
        for _, desc in ipairs(RightContainer:GetDescendants()) do
            if desc:IsA("TextLabel") then
                TweenService:Create(desc, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
            elseif desc:IsA("UIStroke") then
                TweenService:Create(desc, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
            elseif desc:IsA("Frame") then
                TweenService:Create(desc, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
            end
        end
    end

    if MainFrame and MainFrame.BackgroundTransparency < 1 then
        TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    end

    if fadeBg then
        fadeBg.Completed:Wait()
    else
        task.wait(0.35)
    end
    pcall(function() LoadingScreenGui:Destroy() end)
    LoadingScreenGui = nil
end

_G.WASOR_Loading = false
_G.WASOR_Loaded = true

if not initSuccess then
    writeCrashLog("Loader Initialization", initErr, debug.traceback())
else
    print("[WASOR] Loader: FileBuild (GitHub)")
end

if not useCache and hasFileSystem and latestSHA and not downloadFailed then
    pcall(writefile, "WASOR_Cache/commit_sha.txt", latestSHA)
end
