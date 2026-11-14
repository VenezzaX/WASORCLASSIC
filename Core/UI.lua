local VH = _G.VoidHub
local UI = {}

local Services = VH.Services
local State = VH.State

UI.tabButtons = {}
UI.windows = {}
UI.moduleButtons = {}
UI.floatingWindows = {}
UI.moduleCategories = {}
UI.moduleContainers = {}
UI.moduleLabels = {}
UI.moduleButtonsRaw = {}
UI.moduleGears = {}
UI.themeColors = {
    ["Purple"] = Color3.fromRGB(141, 47, 196), ["Red"] = Color3.fromRGB(218, 38, 38),
    ["Green"] = Color3.fromRGB(46, 204, 113), ["Blue"] = Color3.fromRGB(41, 128, 185),
    ["Yellow"] = Color3.fromRGB(241, 196, 15), ["Cyan"] = Color3.fromRGB(26, 188, 156),
    ["Pink"] = Color3.fromRGB(232, 44, 154), ["Orange"] = Color3.fromRGB(230, 126, 34),
    ["Sunset"] = Color3.fromRGB(255, 90, 0), ["Emerald"] = Color3.fromRGB(10, 180, 100),
    ["Midnight"] = Color3.fromRGB(60, 40, 180), ["Gold Rush"] = Color3.fromRGB(255, 215, 0),
    ["Galaxy"] = Color3.fromRGB(128, 90, 245), ["Custom"] = Color3.fromRGB(141, 47, 196),
    ["Rainbow"] = Color3.fromRGB(141, 47, 196)
}

UI.themeGradients = {
    ["Purple"] = {Color3.fromRGB(141, 47, 196), Color3.fromRGB(75, 0, 130)},
    ["Red"] = {Color3.fromRGB(218, 38, 38), Color3.fromRGB(255, 99, 71)},
    ["Green"] = {Color3.fromRGB(46, 204, 113), Color3.fromRGB(26, 188, 156)},
    ["Blue"] = {Color3.fromRGB(41, 128, 185), Color3.fromRGB(0, 191, 255)},
    ["Yellow"] = {Color3.fromRGB(241, 196, 15), Color3.fromRGB(243, 156, 18)},
    ["Cyan"] = {Color3.fromRGB(26, 188, 156), Color3.fromRGB(52, 152, 219)},
    ["Pink"] = {Color3.fromRGB(232, 44, 154), Color3.fromRGB(155, 89, 182)},
    ["Orange"] = {Color3.fromRGB(230, 126, 34), Color3.fromRGB(211, 84, 0)},
    ["Sunset"] = {Color3.fromRGB(255, 90, 0), Color3.fromRGB(130, 0, 180)},
    ["Emerald"] = {Color3.fromRGB(10, 180, 100), Color3.fromRGB(140, 240, 80)},
    ["Midnight"] = {Color3.fromRGB(60, 40, 180), Color3.fromRGB(180, 60, 255)},
    ["Gold Rush"] = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(184, 115, 51)},
    ["Galaxy"] = {Color3.fromRGB(130, 80, 255), Color3.fromRGB(0, 210, 255)},
    ["Custom"] = {Color3.fromRGB(141, 47, 196), Color3.fromRGB(75, 0, 130)},
    ["Rainbow"] = {Color3.fromRGB(141, 47, 196), Color3.fromRGB(0, 255, 255)}
}

local themeHeaders, themeTexts, themeFills, themeToggles, themeGradientsList = {}, {}, {}, {}, {}
local themeLeftCornerFills, themeRightCornerFills = {}, {}
local patchedModules = {
    ["god mode"] = true,
    ["no recoil"] = true,
    ["silent aim"] = true,
    ["instant respawn"] = true
}

local activeTab = "Modules"
local chatPanel = nil
local chatContent = nil
local bindsPanel = nil
local bindsContent = nil
local menuBlur = nil
local screenGui = nil
local mainUIContainer = nil
local topBar = nil
local hudWatermark = nil
local hudCoords = nil
local hudServerAge = nil
local hudArrayListFrame = nil
local toastContainer = nil
local activeToasts = {}
local navBar = nil

local settingsPanel = nil
local settingsContent = nil
local searchBox = nil

UI.isModuleDisabled = function(name)
    if not name then return false end
    if UI.moduleCategories and UI.moduleCategories[name] == "Misc" then return false end
    return (State.S.DisabledModules and State.S.DisabledModules[name] == true)
end

UI.updateModuleVisual = function(name)
    local container = UI.moduleContainers and UI.moduleContainers[name]
    local btn = UI.moduleButtonsRaw and UI.moduleButtonsRaw[name]
    local label = UI.moduleLabels and UI.moduleLabels[name]
    local gear = UI.moduleGears and UI.moduleGears[name]
    local itemObj = UI.moduleButtons and UI.moduleButtons[name]
    if not container or not btn or not label then return end

    local cat = UI.moduleCategories and UI.moduleCategories[name]
    if cat == "Misc" then
        container.Visible = true
        return
    end

    local isDisabled = UI.isModuleDisabled(name)
    local isSelectMode = (State.S.ModuleDisableMode == true)
    local style = State.S.DisabledModuleStyle or "Greyish"

    if isDisabled then
        if style == "Invisible" and not isSelectMode then
            container.Visible = false
        else
            container.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
            btn.BackgroundTransparency = 0.2
            label.TextColor3 = Color3.fromRGB(100, 100, 105)
            label.Text = (isSelectMode and "[DISABLED] " or "") .. name
            btn.TextColor3 = label.TextColor3
            if gear then gear.Visible = false end
        end
    else
        container.Visible = true
        local isAct = itemObj and itemObj.IsActive and itemObj.IsActive()
        local c = Color3.fromRGB(200, 200, 200)
        if patchedModules[name:lower()] then
            c = Color3.fromRGB(255, 60, 60)
        elseif isAct then
            c = Color3.fromRGB(100, 240, 100)
        end
        label.TextColor3 = c
        btn.TextColor3 = c
        label.Text = (isSelectMode and "[ACTIVE] " or "") .. name
        if gear then gear.Visible = true end
    end
end

UI.updateAllModuleVisuals = function()
    for name, _ in pairs(UI.moduleButtons) do
        pcall(function() UI.updateModuleVisual(name) end)
    end
    if UI.refreshDisabledModulesList then
        pcall(UI.refreshDisabledModulesList)
    end
end

UI.setModuleDisabled = function(name, disabled)
    if not name then return false end
    if UI.moduleCategories and UI.moduleCategories[name] == "Misc" then
        UI.showToast("Cannot disable modules in the Misc tab!", Color3.fromRGB(218, 38, 38))
        return false
    end
    State.S.DisabledModules = State.S.DisabledModules or {}
    if disabled then
        State.S.DisabledModules[name] = true
        local item = UI.moduleButtons[name]
        if item and item.IsActive and item.IsActive() then
            item.SetActive(false)
        end
    else
        State.S.DisabledModules[name] = nil
    end
    UI.updateModuleVisual(name)
    VH.Config.saveConfig()
    if UI.refreshDisabledModulesList then
        pcall(UI.refreshDisabledModulesList)
    end
    return true
end

UI.revertAllDisabled = function()
    State.S.DisabledModules = {}
    UI.updateAllModuleVisuals()
    VH.Config.saveConfig()
    UI.showToast("All disabled modules have been reverted!", Color3.fromRGB(46, 204, 113))
end

UI.showToast = function(message, color)
    local S = State.S
    if not S.ToastEnabled then return end
    if not toastContainer then return end

    local toastColor = color or State.currentThemeColor

    local existing = nil
    for _, t in ipairs(activeToasts) do
        if t.message == message then
            existing = t
            break
        end
    end

    if existing then
        existing.count = existing.count + 1
        existing.label.Text = message .. " <font color='#ffffff'><b>(x" .. existing.count .. ")</b></font>"
        existing.createdTime = tick()

        if existing.tween then
            existing.tween:Cancel()
        end
        existing.progressBar.Size = UDim2.new(1, 0, 0, 2.5)

        local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Linear)
        existing.tween = Services.TweenService:Create(existing.progressBar, tweenInfo, {Size = UDim2.new(0, 0, 0, 2.5)})
        existing.tween:Play()

        if existing.destroyThread then
            task.cancel(existing.destroyThread)
        end

        existing.destroyThread = task.delay(3.5, function()
            for i, t in ipairs(activeToasts) do
                if t == existing then
                    table.remove(activeToasts, i)
                    break
                end
            end

            local t1 = Services.TweenService:Create(existing.frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)})
            local t2 = Services.TweenService:Create(existing.label, TweenInfo.new(0.2), {TextTransparency = 1})
            local stroke = existing.frame:FindFirstChildOfClass("UIStroke")
            local t3 = stroke and Services.TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1})
            local t4 = Services.TweenService:Create(existing.progressBar, TweenInfo.new(0.2), {BackgroundTransparency = 1})

            t1:Play(); t2:Play(); t4:Play()
            if t3 then t3:Play() end

            t1.Completed:Connect(function()
                pcall(function() existing.frame:Destroy() end)
            end)
            task.delay(0.3, function()
                pcall(function() existing.frame:Destroy() end)
            end)
        end)

        return
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 36)
    toast.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    toast.BackgroundTransparency = 0.05
    toast.BorderSizePixel = 0
    toast.ClipsDescendants = true
    toast.Parent = toastContainer
    toast:SetAttribute("CreatedTime", tick())

    pcall(function()
        if Services.Debris then Services.Debris:AddItem(toast, 4.2) end
    end)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = toastColor
    stroke.Thickness = 1
    stroke.Parent = toast

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, -6)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Text = message
    lbl.RichText = true
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2.5)
    progressBar.Position = UDim2.new(0, 0, 1, -2.5)
    progressBar.BackgroundColor3 = toastColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = toast

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = progressBar

    toast.Size = UDim2.new(1, 0, 0, 0)
    lbl.TextTransparency = 1
    stroke.Transparency = 1

    Services.TweenService:Create(toast, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 36)}):Play()
    Services.TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    Services.TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()

    local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Linear)
    local pTween = Services.TweenService:Create(progressBar, tweenInfo, {Size = UDim2.new(0, 0, 0, 2.5)})
    pTween:Play()

    local toastData = {
        message = message,
        count = 1,
        frame = toast,
        label = lbl,
        progressBar = progressBar,
        tween = pTween,
        color = toastColor,
        createdTime = tick()
    }
    table.insert(activeToasts, toastData)

    toastData.destroyThread = task.delay(3.5, function()
        for i, t in ipairs(activeToasts) do
            if t == toastData then
                table.remove(activeToasts, i)
                break
            end
        end

        local t1 = Services.TweenService:Create(toast, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)})
        local t2 = Services.TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1})
        local t3 = Services.TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1})
        local t4 = Services.TweenService:Create(progressBar, TweenInfo.new(0.2), {BackgroundTransparency = 1})

        t1:Play(); t2:Play(); t3:Play(); t4:Play()
        t1.Completed:Connect(function()
            pcall(function() toast:Destroy() end)
        end)
        task.delay(0.3, function()
            pcall(function() toast:Destroy() end)
        end)
    end)
end

local toastWatcherActive = false
local function startToastCleanupWatcher()
    if toastWatcherActive then return end
    toastWatcherActive = true
    task.spawn(function()
        while State.uiRunning do
            task.wait(2)
            if toastContainer then
                local now = tick()
                for i = #activeToasts, 1, -1 do
                    local t = activeToasts[i]
                    if not t.frame or not t.frame.Parent or (t.createdTime and (now - t.createdTime > 4.5)) then
                        if t.frame and t.frame.Parent then
                            pcall(function() t.frame:Destroy() end)
                        end
                        table.remove(activeToasts, i)
                    end
                end
                for _, child in ipairs(toastContainer:GetChildren()) do
                    if child:IsA("Frame") then
                        local age = child:GetAttribute("CreatedTime")
                        if age and (now - age > 4.5) then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end
        toastWatcherActive = false
    end)
end

UI.updateHUDArrayList = function()
    if not hudArrayListFrame then return end
    for _, child in ipairs(hudArrayListFrame:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    local S = State.S
    local isVisible = S.HUDArrayList
    if not State.uiVisible then isVisible = S.HUDArrayList and S.HUDArrayListOutside end
    if not isVisible then hudArrayListFrame.Visible = false return end

    local activeMods = {}
    for modName, item in pairs(UI.moduleButtons) do if item.IsActive and item.IsActive() then table.insert(activeMods, modName) end end
    table.sort(activeMods, function(a, b) return #a > #b end)

    if #activeMods == 0 then hudArrayListFrame.Visible = false
    else
        hudArrayListFrame.Visible = isVisible
        for _, modName in ipairs(activeMods) do
            local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 14); lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 9; lbl.TextColor3 = State.currentThemeColor
            lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = "  " .. modName; lbl.Parent = hudArrayListFrame
            local accent = Instance.new("Frame"); accent.Size = UDim2.new(0, 2, 1, 0); accent.Position = UDim2.new(0, 0, 0, 0)
            accent.BackgroundColor3 = State.currentThemeColor; accent.BorderSizePixel = 0; accent.Parent = lbl
        end
    end
end

local function protectUIFonts(gui)
    local function lockFont(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local targetFont = Enum.Font[State.S.UIFont or "Gotham"] or Enum.Font.Gotham
            pcall(function() obj.Font = targetFont end)
            obj:GetPropertyChangedSignal("Font"):Connect(function()
                local fontNow = Enum.Font[State.S.UIFont or "Gotham"] or Enum.Font.Gotham
                if obj.Font ~= fontNow then
                    pcall(function() obj.Font = fontNow end)
                end
            end)
        end
    end
    for _, desc in ipairs(gui:GetDescendants()) do lockFont(desc) end
    gui.DescendantAdded:Connect(lockFont)
end

UI.applyUIFont = function(fontName)
    local S = State.S
    S.UIFont = fontName or "Gotham"
    local enumFont = Enum.Font[S.UIFont] or Enum.Font.Gotham
    if not screenGui then return end
    for _, desc in ipairs(screenGui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            pcall(function() desc.Font = enumFont end)
        end
    end
end

UI.applyUIScale = function(scaleFactor)
    local S = State.S
    scaleFactor = scaleFactor or S.UIScale or 1.0
    S.UIScale = scaleFactor
    if not screenGui then return end
    local uiScale = screenGui:FindFirstChildOfClass("UIScale") or screenGui:FindFirstChild("VoidUIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Name = "VoidUIScale"
        uiScale.Parent = screenGui
    end
    uiScale.Scale = scaleFactor
end

UI.updateMenuBlur = function()
    if not menuBlur then return end
    if not State.uiVisible then
        Services.TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 0}):Play()
        task.delay(0.25, function() if not State.uiVisible then menuBlur.Enabled = false end end)
        return
    end
        if activeTab == "Settings" then
        menuBlur.Enabled = true; Services.TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 16}):Play()
    else
        Services.TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 0}):Play()
        task.delay(0.25, function() if activeTab == "Modules" or not State.uiVisible then menuBlur.Enabled = false end end)
    end
end

local function formatVal(val)
    if typeof(val) ~= "number" then return tostring(val) end
    if val == math.floor(val) then return tostring(math.floor(val)) end
    return string.format("%.2f", val)
end

local function getGradientAngle(angleStr)
    if angleStr == "Horizontal (0°)" then return 0
    elseif angleStr == "Diagonal (45°)" then return 45
    elseif angleStr == "Vertical (90°)" then return 90
    elseif angleStr == "Reverse Diagonal (135°)" then return 135
    end
    return 0
end

UI.getGradientSequence = function(col1, col2, style)
    col1 = col1 or State.currentThemeColor
    col2 = col2 or State.currentThemeGradientColor or col1
    style = style or State.S.ThemeGradientStyle or "Linear Gradient"

    if style == "Solid Color" then
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, col1),
            ColorSequenceKeypoint.new(1, col1)
        })
    elseif style == "Glow Accent" then
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, col1),
            ColorSequenceKeypoint.new(0.5, col2),
            ColorSequenceKeypoint.new(1, col1)
        })
    elseif style == "Rainbow Animated" then
        local t = tick() * 0.2
        local h1 = t % 1
        local h2 = (t + 0.33) % 1
        local h3 = (t + 0.66) % 1
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, 0.85, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(h2, 0.85, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h3, 0.85, 1))
        })
    else
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, col1),
            ColorSequenceKeypoint.new(1, col2)
        })
    end
end

UI.updateSingleGradient = function(grad)
    if not grad or not grad.Parent then return end
    pcall(function()
        grad.Rotation = getGradientAngle(State.S.ThemeGradientAngle)
        grad.Color = UI.getGradientSequence(State.currentThemeColor, State.currentThemeGradientColor, State.S.ThemeGradientStyle)
    end)
end

UI.updateAllGradients = function()
    for i = #themeGradientsList, 1, -1 do
        local grad = themeGradientsList[i]
        if grad and grad.Parent then
            UI.updateSingleGradient(grad)
        else
            table.remove(themeGradientsList, i)
        end
    end
end

local function addHeaderGradient(obj)
    if not obj then return end
    local grad = obj:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Parent = obj
    end
    if not table.find(themeGradientsList, grad) then
        table.insert(themeGradientsList, grad)
    end
    UI.updateSingleGradient(grad)
    return grad
end

UI.parseHexColor = function(hexStr)
    if not hexStr or typeof(hexStr) ~= "string" then return nil end
    hexStr = hexStr:gsub("#", ""):gsub("%s+", "")
    if #hexStr == 6 then
        local r = tonumber(hexStr:sub(1, 2), 16)
        local g = tonumber(hexStr:sub(3, 4), 16)
        local b = tonumber(hexStr:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    local ok, col = pcall(function() return Color3.fromHex(hexStr) end)
    if ok and col then return col end
    return nil
end

local function getGalaxyBgColor()
    local S = State.S
    local style = S.GalaxyBgStyle or "Deep Space (Black)"
    if style == "Dark Purple Nebula" then
        return Color3.fromRGB(24, 8, 40)
    elseif style == "Midnight Blue" then
        return Color3.fromRGB(6, 14, 35)
    elseif style == "Cosmic Crimson" then
        return Color3.fromRGB(35, 6, 18)
    elseif style == "Custom Hex" then
        return UI.parseHexColor(S.GalaxyCustomBgHex) or Color3.fromRGB(0, 0, 0)
    else
        return Color3.fromRGB(0, 0, 0)
    end
end

local galaxyContainers = {}
local galaxyStars = {}
local galaxyActive = false

local function initGalaxyBackground()
    galaxyContainers = {}
    galaxyStars = {}

    local starColors = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(220, 240, 255),
        Color3.fromRGB(200, 160, 255),
        Color3.fromRGB(160, 230, 255),
        Color3.fromRGB(255, 220, 180)
    }

    local targets = {}
    if topBar then table.insert(targets, topBar) end
    for _, headerObj in ipairs(themeHeaders) do
        if headerObj and headerObj.Parent and headerObj.Size.Y.Offset >= 20 then
            if not table.find(targets, headerObj) then
                table.insert(targets, headerObj)
            end
        end
    end

    local bgCol = getGalaxyBgColor()
    for _, parentObj in ipairs(targets) do
        local c = parentObj:FindFirstChild("GalaxyStarContainer")
        if not c then
            c = Instance.new("Frame")
            c.Name = "GalaxyStarContainer"
            c.Size = UDim2.new(1, 0, 1, 0)
            c.BackgroundColor3 = bgCol
            c.BackgroundTransparency = 0
            c.BorderSizePixel = 0
            c.ClipsDescendants = true
            c.ZIndex = 1
            c.Parent = parentObj
        else
            c.ZIndex = 1
            c.BackgroundColor3 = bgCol
            c.BackgroundTransparency = 0
            c.Visible = true
            for _, ch in ipairs(c:GetChildren()) do
                if ch:IsA("Frame") and ch.Name == "Star" then
                    ch:Destroy()
                end
            end
        end
        local parentCorner = parentObj:FindFirstChildOfClass("UICorner")
        if parentCorner and not c:FindFirstChildOfClass("UICorner") then
            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = parentCorner.CornerRadius
            cCorner.Parent = c
        end
        local owner = parentObj.Parent or parentObj
        for _, child in ipairs(owner:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.Name ~= "GalaxyStarContainer" and child.Name ~= "HeaderVisual" then
                    child.ZIndex = 5
                end
            end
        end
        for _, child in ipairs(parentObj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.Name ~= "GalaxyStarContainer" and child.Name ~= "HeaderVisual" then
                    child.ZIndex = 5
                end
            end
        end
        table.insert(galaxyContainers, c)

        for i = 1, 6 do
            local sz = math.random(1, 2)
            local star = Instance.new("Frame")
            star.Name = "Star"
            star.Size = UDim2.new(0, sz, 0, sz)
            local startX = math.random()
            local startY = math.random()
            star.Position = UDim2.new(startX, 0, startY, 0)
            star.BackgroundColor3 = starColors[math.random(1, #starColors)]
            star.BorderSizePixel = 0
            star.BackgroundTransparency = 0.2 + math.random() * 0.5

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = star
            star.Parent = c

            table.insert(galaxyStars, {
                frame = star,
                x = startX,
                y = startY,
                speed = 0.005 + math.random() * 0.012,
                drift = (math.random() - 0.5) * 0.005,
                twinkleSpeed = 2 + math.random() * 3,
                seed = math.random() * 10
            })
        end
    end
end

local function setGalaxyContainersVisible(vis)
    local bgCol = getGalaxyBgColor()
    for _, c in ipairs(galaxyContainers) do
        if c and c.Parent then
            c.Visible = vis
            if vis then
                c.BackgroundColor3 = bgCol
                c.BackgroundTransparency = 0
            end
        end
    end
end

local function startGalaxyCycle()
    if galaxyActive then return end
    galaxyActive = true
    task.spawn(function()
        initGalaxyBackground()
        setGalaxyContainersVisible(true)
        while State.S.ThemeColor == "Galaxy" and State.uiRunning do
            task.wait(0.04)
            setGalaxyContainersVisible(State.uiVisible)
            local now = tick()
            for _, s in ipairs(galaxyStars) do
                if s.frame and s.frame.Parent then
                    s.y = (s.y - s.speed)
                    if s.y < 0 then s.y = 1; s.x = math.random() end
                    s.x = (s.x + s.drift) % 1
                    local alpha = 0.2 + 0.5 * math.abs(math.sin(now * s.twinkleSpeed + s.seed))
                    pcall(function()
                        s.frame.Position = UDim2.new(s.x, 0, s.y, 0)
                        s.frame.BackgroundTransparency = alpha
                    end)
                end
            end
        end
        setGalaxyContainersVisible(false)
        galaxyActive = false
    end)
end

local textAnimActive = false
local function startTextAnimationLoop()
    if textAnimActive then return end
    textAnimActive = true
    task.spawn(function()
        while State.uiRunning do
            task.wait(0.04)
            local style = State.S.TextAnimationStyle or "Static"
            if style ~= "Static" and State.uiVisible then
                local now = tick()
                local idx = 0
                for catName, winData in pairs(UI.windows) do
                    idx = idx + 1
                    local label = winData.TitleLabel
                    if label then
                        if style == "Jumping Gummy" then
                            local bounce = math.abs(math.sin(now * 6 + idx * 0.5)) * 3.5
                            label.Position = UDim2.new(0, 8, 0, -bounce)
                        elseif style == "Wave" then
                            local wave = math.sin(now * 4 + idx * 0.5) * 3
                            label.Position = UDim2.new(0, 8 + wave, 0, 0)
                        elseif style == "Pulse" then
                            local pulse = 0.75 + 0.25 * math.sin(now * 6)
                            label.TextTransparency = 1 - pulse
                        end
                    end
                end
            else
                for catName, winData in pairs(UI.windows) do
                    local label = winData.TitleLabel
                    if label then
                        label.Position = UDim2.new(0, 8, 0, 0)
                        label.TextTransparency = 0
                    end
                end
            end
        end
        textAnimActive = false
    end)
end

local rainbowActive = false
local function startRainbowCycle()
    if rainbowActive then return end
    rainbowActive = true
    task.spawn(function()
        local hue = 0
        while (State.S.ThemeColor == "Rainbow" or State.S.ThemeGradientStyle == "Rainbow Animated") and State.uiRunning do
            task.wait(0.03)
            hue = (hue + 1) % 360
            local col1 = Color3.fromHSV(hue / 360, 0.8, 0.9)
            local col2 = Color3.fromHSV(((hue + 120) % 360) / 360, 0.8, 0.9)
            State.currentThemeColor = col1
            State.currentThemeGradientColor = col2
            for _, obj in ipairs(themeHeaders) do pcall(function() obj.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end) end
            for _, obj in ipairs(themeTexts) do pcall(function() obj.TextColor3 = Color3.fromRGB(245, 245, 245) end) end
            for _, obj in ipairs(themeFills) do pcall(function() obj.BackgroundColor3 = col1 end) end
            for _, obj in ipairs(themeLeftCornerFills) do pcall(function() obj.BackgroundColor3 = col1 end) end
            for _, obj in ipairs(themeRightCornerFills) do pcall(function() obj.BackgroundColor3 = col2 end) end
            for _, updateFunc in ipairs(themeToggles) do pcall(updateFunc) end
            for name, btn in pairs(UI.tabButtons) do if name == activeTab then btn.TextColor3 = Color3.fromRGB(255, 255, 255) end end
            if hudWatermark then hudWatermark.TextColor3 = col1 end
            UI.updateAllGradients()
        end
        rainbowActive = false
    end)
end

UI.applyThemeColor = function(colorName)
    local S = State.S
    if colorName then S.ThemeColor = colorName end
    colorName = S.ThemeColor or "Galaxy"

    local col1, col2
    if colorName == "Custom" then
        col1 = UI.parseHexColor(S.CustomThemeHex) or Color3.fromRGB(141, 47, 196)
        col2 = Color3.fromRGB(math.clamp(math.round(col1.R * 255 * 0.6), 0, 255), math.clamp(math.round(col1.G * 255 * 0.6), 0, 255), math.clamp(math.round(col1.B * 255 * 0.6), 0, 255))
        UI.themeColors["Custom"] = col1
        UI.themeGradients["Custom"] = {col1, col2}
    else
        col1 = UI.themeColors[colorName] or UI.themeColors["Galaxy"] or UI.themeColors["Purple"]
        local pair = UI.themeGradients[colorName] or UI.themeGradients["Galaxy"] or UI.themeGradients["Purple"]
        col2 = pair and pair[2] or col1
    end

    State.currentThemeColor = col1
    State.currentThemeGradientColor = col2

    if colorName == "Galaxy" then
        initGalaxyBackground()
        local bgCol = getGalaxyBgColor()
        for _, c in ipairs(galaxyContainers) do
            if c and c.Parent then c.BackgroundColor3 = bgCol; c.BackgroundTransparency = 0 end
        end
        for _, obj in ipairs(themeHeaders) do pcall(function() obj.BackgroundColor3 = bgCol end) end
        for _, obj in ipairs(themeLeftCornerFills) do pcall(function() obj.BackgroundColor3 = bgCol end) end
        for _, obj in ipairs(themeRightCornerFills) do pcall(function() obj.BackgroundColor3 = bgCol end) end
        setGalaxyContainersVisible(true)
        task.spawn(startGalaxyCycle)
    else
        for _, obj in ipairs(themeHeaders) do pcall(function() obj.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end) end
        local rightCol = (S.ThemeGradientStyle == "Solid Color" or S.ThemeGradientStyle == "Glow Accent") and col1 or col2
        for _, obj in ipairs(themeLeftCornerFills) do pcall(function() obj.BackgroundColor3 = col1 end) end
        for _, obj in ipairs(themeRightCornerFills) do pcall(function() obj.BackgroundColor3 = rightCol end) end
        setGalaxyContainersVisible(false)
    end

    if colorName == "Rainbow" or S.ThemeGradientStyle == "Rainbow Animated" then
        task.spawn(startRainbowCycle)
    end

    for _, obj in ipairs(themeTexts) do pcall(function() obj.TextColor3 = Color3.fromRGB(245, 245, 245) end) end
    for _, obj in ipairs(themeFills) do pcall(function() obj.BackgroundColor3 = col1 end) end
    for _, updateFunc in ipairs(themeToggles) do pcall(updateFunc) end
    for name, btn in pairs(UI.tabButtons) do
        if name == activeTab then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.TextColor3 = Color3.fromRGB(210, 210, 210)
        end
    end
    if hudWatermark then hudWatermark.TextColor3 = col1 end

    UI.updateAllGradients()

    task.defer(UI.updateHUDArrayList); task.defer(VH.Utils.updateLocalNametag)
end

local function makeDraggable(frame, handle, onDragEnd)
    local dragging = false
    local dragStart = Vector3.zero
    local startPos = UDim2.new()
    local scaleFactor = 1

    local function getScale()
        if State.S and State.S.UIScale then
            return State.S.UIScale
        end
        local uiScale = screenGui and (screenGui:FindFirstChildOfClass("UIScale") or screenGui:FindFirstChild("VoidUIScale"))
        return (uiScale and uiScale.Scale > 0) and uiScale.Scale or 1
    end

    local dragConn = nil
    local endConn = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            scaleFactor = getScale()

            if dragConn then dragConn:Disconnect(); dragConn = nil end
            if endConn then endConn:Disconnect(); endConn = nil end

            dragConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
                if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - dragStart
                    local dx = delta.X / scaleFactor
                    local dy = delta.Y / scaleFactor
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
                end
            end)

            endConn = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    if dragConn then dragConn:Disconnect(); dragConn = nil end
                    if endConn then endConn:Disconnect(); endConn = nil end
                    if onDragEnd then onDragEnd(frame.Position) end
                end
            end)
        end
    end)
end

local function formatVal(val)
    if type(val) == "number" then
        local str = string.format("%.2f", val):gsub("%.00$", "")
        if str:find("%.") then str = str:gsub("0+$", "") end
        return str
    end
    return tostring(val)
end

local function makeResizable(frame, handle)
    local resizing = false
    local resizeStart = Vector3.zero
    local startSize = UDim2.new()
    local scaleFactor = 1

    local function getScale()
        if State.S and State.S.UIScale then
            return State.S.UIScale
        end
        local uiScale = screenGui and (screenGui:FindFirstChildOfClass("UIScale") or screenGui:FindFirstChild("VoidUIScale"))
        return (uiScale and uiScale.Scale > 0) and uiScale.Scale or 1
    end

    local moveConn = nil
    local endConn = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = frame.Size
            scaleFactor = getScale()

            if moveConn then moveConn:Disconnect(); moveConn = nil end
            if endConn then endConn:Disconnect(); endConn = nil end

            moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
                if resizing and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - resizeStart
                    local dx = delta.X / scaleFactor
                    local dy = delta.Y / scaleFactor
                    local minW = frame:GetAttribute("MinResizeW") or 140
                    local minH = frame:GetAttribute("MinResizeH") or 60
                    local newWidth = math.max(minW, startSize.X.Offset + dx)
                    local newHeight = math.max(minH, startSize.Y.Offset + dy)
                    frame.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end)

            endConn = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    resizing = false
                    frame:SetAttribute("UserResized", true)
                    if moveConn then moveConn:Disconnect(); moveConn = nil end
                    if endConn then endConn:Disconnect(); endConn = nil end
                end
            end)
        end
    end)
end

local function findWindowFrame(obj)
    local curr = obj
    while curr do if curr:IsA("Frame") and curr:GetAttribute("BaseWidth") then return curr end; curr = curr.Parent end
    return nil
end

local function scaleGuiObject(obj, scale)
    if not obj:IsA("GuiObject") then return end
    if obj:IsA("UIListLayout") or obj:IsA("UIPadding") or obj:IsA("UIStroke") or obj:IsA("UIGridLayout") then return end
    if obj.Name == "resizeHandle" then return end
    local baseSize = obj:GetAttribute("BaseSize") or obj.Size
    if not obj:GetAttribute("BaseSize") then obj:SetAttribute("BaseSize", baseSize) end
    local basePos = obj:GetAttribute("BasePos") or obj.Position
    if not obj:GetAttribute("BasePos") then obj:SetAttribute("BasePos", basePos) end
    obj.Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset * scale, baseSize.Y.Scale, baseSize.Y.Offset * scale)
    obj.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset * scale, basePos.Y.Scale, basePos.Y.Offset * scale)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local baseTextSize = obj:GetAttribute("BaseTextSize") or obj.TextSize
        if not obj:GetAttribute("BaseTextSize") then obj:SetAttribute("BaseTextSize", baseTextSize) end
        obj.TextSize = math.clamp(math.round(baseTextSize * scale), 7, 24)
    end
end

local function autoScaleContent(winFrame, scale)
    local contentFrame = winFrame:FindFirstChild("content") or winFrame:FindFirstChildOfClass("ScrollingFrame")
    if contentFrame then
        local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
        if listLayout then
            local basePadding = listLayout:GetAttribute("BasePadding") or listLayout.Padding.Offset
            if not listLayout:GetAttribute("BasePadding") then listLayout:SetAttribute("BasePadding", basePadding) end
            listLayout.Padding = UDim.new(0, basePadding * scale)
        end
        local uiPadding = contentFrame:FindFirstChildOfClass("UIPadding")
        if uiPadding then
            local basePadT = uiPadding:GetAttribute("BasePadTop") or uiPadding.PaddingTop.Offset
            local basePadB = uiPadding:GetAttribute("BasePadBottom") or uiPadding.PaddingBottom.Offset
            local basePadL = uiPadding:GetAttribute("BasePadLeft") or uiPadding.PaddingLeft.Offset
            local basePadR = uiPadding:GetAttribute("BasePadRight") or uiPadding.PaddingRight.Offset
            if not uiPadding:GetAttribute("BasePadTop") then
                uiPadding:SetAttribute("BasePadTop", basePadT); uiPadding:SetAttribute("BasePadBottom", basePadB)
                uiPadding:SetAttribute("BasePadLeft", basePadL); uiPadding:SetAttribute("BasePadRight", basePadR)
            end
            uiPadding.PaddingTop = UDim.new(0, basePadT * scale); uiPadding.PaddingBottom = UDim.new(0, basePadB * scale)
            uiPadding.PaddingLeft = UDim.new(0, basePadL * scale); uiPadding.PaddingRight = UDim.new(0, basePadR * scale)
        end
    end
    for _, child in ipairs(winFrame:GetDescendants()) do scaleGuiObject(child, scale) end
end

local function adjustWindowSizeToContent(winFrame, contentFrame)
    if winFrame == settingsPanel or winFrame == chatPanel or winFrame:GetAttribute("UserResized") == true then return end
    local totalContentHeight, count = 0, 0
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "resizeHandle" then
            local baseH = child:GetAttribute("BaseSize") and child:GetAttribute("BaseSize").Y.Offset or child.Size.Y.Offset
            totalContentHeight = totalContentHeight + baseH; count = count + 1
        end
    end
    local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
    local paddingVal = listLayout and listLayout.Padding.Offset or 4
    local uiPadding = contentFrame:FindFirstChildOfClass("UIPadding")
    local padT = uiPadding and uiPadding.PaddingTop.Offset or 6
    local padB = uiPadding and uiPadding.PaddingBottom.Offset or 6
    local contentHeight = padT + padB + totalContentHeight + math.max(0, count - 1) * paddingVal
    local finalHeight = math.clamp(22 + contentHeight, 50, 300)
    local width = winFrame.Size.X.Offset
    winFrame.Size = UDim2.new(0, width, 0, finalHeight)
    winFrame:SetAttribute("BaseWidth", width); winFrame:SetAttribute("BaseHeight", finalHeight)
end

UI.addToggleOption = function(parent, name, defaultVal, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 18); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -34, 1, 0); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 26, 0, 14); btn.Position = UDim2.new(1, -30, 0.5, -7)
    btn.BackgroundColor3 = defaultVal and State.currentThemeColor or Color3.fromRGB(55, 55, 55); btn.BorderSizePixel = 0; btn.Text = ""; btn.Parent = row
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 7); btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke"); btnStroke.Thickness = 1; btnStroke.Color = defaultVal and State.currentThemeColor or Color3.fromRGB(80, 80, 80); btnStroke.Parent = btn
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = defaultVal and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.BorderSizePixel = 0; knob.Parent = btn
    local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(0, 5); knobCorner.Parent = knob
    local active = defaultVal

    local function updateToggle(animate)
        local targetPos = active and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        local targetCol = active and State.currentThemeColor or Color3.fromRGB(55, 55, 55)
        local targetStrokeCol = active and State.currentThemeColor or Color3.fromRGB(80, 80, 80)
        if animate then
            Services.TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            Services.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = targetCol}):Play()
            Services.TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = targetStrokeCol}):Play()
        else knob.Position = targetPos; btn.BackgroundColor3 = targetCol; btnStroke.Color = targetStrokeCol end
    end
    table.insert(themeToggles, function() updateToggle(false) end)
    btn.MouseButton1Click:Connect(function() active = not active; updateToggle(true); callback(active) end)
    return { Set = function(val) active = val; updateToggle(false) end }
end

UI.addSliderOption = function(parent, name, min, max, defaultVal, callback, defaultDotVal)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.65, 0, 0, 12); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local valLabel = Instance.new("TextLabel"); valLabel.Size = UDim2.new(0.35, 0, 0, 12); valLabel.Position = UDim2.new(0.65, -4, 0, 0)
    valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 10; valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right; valLabel.Text = formatVal(defaultVal); valLabel.Parent = row
    local slideBg = Instance.new("Frame"); slideBg.Size = UDim2.new(1, -8, 0, 5); slideBg.Position = UDim2.new(0, 4, 0, 15)
    slideBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50); slideBg.BorderSizePixel = 0; slideBg.Parent = row
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 2.5); bgCorner.Parent = slideBg
    local slideFill = Instance.new("Frame"); local startPct = math.clamp((defaultVal - min) / (max - min), 0, 1)
    slideFill.Size = UDim2.new(startPct, 0, 1, 0); slideFill.BackgroundColor3 = State.currentThemeColor; slideFill.BorderSizePixel = 0; slideFill.Parent = slideBg; table.insert(themeFills, slideFill)
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0, 2.5); fillCorner.Parent = slideFill
    local slideKnob = Instance.new("Frame"); slideKnob.Size = UDim2.new(0, 10, 0, 10); slideKnob.Position = UDim2.new(1, -5, 0.5, -5)
    slideKnob.BackgroundColor3 = Color3.fromRGB(240, 240, 240); slideKnob.BorderSizePixel = 0; slideKnob.Parent = slideFill
    local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(0, 5); knobCorner.Parent = slideKnob

    local dotMarker = nil
    if defaultDotVal and defaultDotVal >= min and defaultDotVal <= max then
        local dotPct = math.clamp((defaultDotVal - min) / (max - min), 0, 1)
        dotMarker = Instance.new("Frame")
        dotMarker.Name = "DefaultDotMarker"
        dotMarker.Size = UDim2.new(0, 7, 0, 7)
        dotMarker.AnchorPoint = Vector2.new(0.5, 0.5)
        dotMarker.Position = UDim2.new(dotPct, 0, 0.5, 0)
        dotMarker.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        dotMarker.BorderSizePixel = 0
        dotMarker.ZIndex = 4
        dotMarker.Parent = slideBg
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dotMarker
    end

    local slideBtn = Instance.new("TextButton"); slideBtn.Size = UDim2.new(1, 0, 1, 0); slideBtn.BackgroundTransparency = 1; slideBtn.Text = ""; slideBtn.Parent = slideBg

    local function updateSlider(input)
        local sizeX = slideBg.AbsoluteSize.X; if sizeX <= 0 then sizeX = 112 end
        local posX = input.Position.X - slideBg.AbsolutePosition.X; local pct = math.clamp(posX / sizeX, 0, 1)
        slideFill.Size = UDim2.new(pct, 0, 1, 0); local val = math.floor(min + (max - min) * pct + 0.5)
        valLabel.Text = tostring(val); callback(val)
    end
    local dragging = false
    slideBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; updateSlider(input) end end)
    slideBtn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    local moveCon = Services.UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end end)
    table.insert(State.S.Connections, moveCon)
    return {
        Set = function(val) local pct = math.clamp((val - min) / (max - min), 0, 1); slideFill.Size = UDim2.new(pct, 0, 1, 0); valLabel.Text = formatVal(val) end,
        SetDefaultDot = function(dotVal)
            if dotVal and slideBg then
                local dotPct = math.clamp((dotVal - min) / (max - min), 0, 1)
                if not dotMarker then
                    dotMarker = Instance.new("Frame")
                    dotMarker.Name = "DefaultDotMarker"
                    dotMarker.Size = UDim2.new(0, 7, 0, 7)
                    dotMarker.AnchorPoint = Vector2.new(0.5, 0.5)
                    dotMarker.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                    dotMarker.BorderSizePixel = 0
                    dotMarker.ZIndex = 4
                    dotMarker.Parent = slideBg
                    local dotCorner = Instance.new("UICorner")
                    dotCorner.CornerRadius = UDim.new(1, 0)
                    dotCorner.Parent = dotMarker
                end
                dotMarker.Position = UDim2.new(dotPct, 0, 0.5, 0)
            end
        end
    }
end

UI.addDropdownOption = function(parent, name, optionsList, defaultValIndex, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 12); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local dropBtn = Instance.new("TextButton"); dropBtn.Size = UDim2.new(1, -8, 0, 16); dropBtn.Position = UDim2.new(0, 4, 0, 14)
    dropBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38); dropBtn.BorderSizePixel = 0; dropBtn.Font = Enum.Font.GothamBold; dropBtn.TextSize = 9
    dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255); dropBtn.Text = optionsList[defaultValIndex] or "(none)"; dropBtn.Parent = row
    local dropCorner = Instance.new("UICorner"); dropCorner.CornerRadius = UDim.new(0, 4); dropCorner.Parent = dropBtn
    local stroke = Instance.new("UIStroke"); stroke.Color = State.currentThemeColor; stroke.Thickness = 1; stroke.Parent = dropBtn
    table.insert(themeToggles, function() stroke.Color = State.currentThemeColor end)

    dropBtn.MouseEnter:Connect(function() dropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55) end)
    dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38) end)
    local open = false; local listContainer = nil

    local function toggleDropdown()
        open = not open; local scale = 1.0; local winFrame = findWindowFrame(row)
        if winFrame then local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset; if baseW > 0 then scale = winFrame.Size.X.Offset / baseW end end
        if open then
            listContainer = Instance.new("Frame"); listContainer.Size = UDim2.new(1, 0, 0, #optionsList * 16 * scale)
            listContainer:SetAttribute("BaseSize", UDim2.new(1, 0, 0, #optionsList * 16)); listContainer:SetAttribute("BasePos", UDim2.new(0, 0, 1, 2))
            listContainer.Position = UDim2.new(0, 0, 1, 2); listContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 28); listContainer.BorderSizePixel = 0; listContainer.ZIndex = 25; listContainer.Parent = dropBtn
            local listCorner = Instance.new("UICorner"); listCorner.CornerRadius = UDim.new(0, 4); listCorner.Parent = listContainer
            local listStroke = Instance.new("UIStroke"); listStroke.Color = State.currentThemeColor; listStroke.Thickness = 1; listStroke.Parent = listContainer
            local layout = Instance.new("UIListLayout"); layout.Parent = listContainer
            for i, opt in ipairs(optionsList) do
                local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 16 * scale); btn:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 16))
                btn:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0)); btn:SetAttribute("BaseTextSize", 8); btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
                btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamMedium; btn.TextSize = math.clamp(math.round(8 * scale), 8, 24)
                btn.TextColor3 = Color3.fromRGB(240, 240, 240); btn.Text = opt; btn.ZIndex = 25; btn.Parent = listContainer
                local itemCorner = Instance.new("UICorner"); itemCorner.CornerRadius = UDim.new(0, 3); itemCorner.Parent = btn
                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); btn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28); btn.TextColor3 = Color3.fromRGB(240, 240, 240) end)
                btn.MouseButton1Click:Connect(function() dropBtn.Text = opt; callback(i, opt); toggleDropdown() end)
            end
            row.Size = UDim2.new(1, 0, 0, (32 + #optionsList * 16) * scale); row:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 32 + #optionsList * 16))
        else
            if listContainer then listContainer:Destroy(); listContainer = nil end
            row.Size = UDim2.new(1, 0, 0, 32 * scale); row:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 32))
        end
    end
    dropBtn.MouseButton1Click:Connect(toggleDropdown)
    return { Set = function(valText) dropBtn.Text = valText end, SetOptions = function(newList) optionsList = newList; if open then toggleDropdown(); toggleDropdown() end end }
end

local keybindRegistry = {}
UI.addKeybindOption = function(parent, name, defaultKey, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 20); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -65, 1, 0); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local bindBtn = Instance.new("TextButton"); bindBtn.Size = UDim2.new(0, 55, 0, 16); bindBtn.Position = UDim2.new(1, -59, 0.5, -8)
    bindBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38); bindBtn.BorderSizePixel = 0; bindBtn.Font = Enum.Font.GothamBold; bindBtn.TextSize = 9
    bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255); bindBtn.Text = (defaultKey and defaultKey ~= Enum.KeyCode.Unknown) and defaultKey.Name or "[none]"; bindBtn.Parent = row
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 4); btnCorner.Parent = bindBtn
    local stroke = Instance.new("UIStroke"); stroke.Color = State.currentThemeColor; stroke.Thickness = 1; stroke.Parent = bindBtn
    table.insert(themeToggles, function() stroke.Color = State.currentThemeColor end)
    bindBtn.MouseEnter:Connect(function() bindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55) end)
    bindBtn.MouseLeave:Connect(function() bindBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38) end)
    local currentKey = defaultKey; local listening = false

    local optObj = {
        GetKey = function() return currentKey end,
        SetKey = function(key) currentKey = key; bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[none]" end,
        Set = function(key) currentKey = key; bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[none]" end,
        Callback = callback
    }
    keybindRegistry[name] = optObj
    bindBtn.MouseButton1Click:Connect(function() listening = true; bindBtn.Text = "..."; bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)

    local con = Services.UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.Escape then listening = false; bindBtn.Text = (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "[none]"; bindBtn.TextColor3 = State.currentThemeColor; return
                elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then listening = false; currentKey = Enum.KeyCode.Unknown; bindBtn.Text = "[none]"; bindBtn.TextColor3 = State.currentThemeColor; callback(Enum.KeyCode.Unknown); return end
                if Services.UserInputService:GetFocusedTextBox() then return end
                listening = false; currentKey = key; bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[none]"; bindBtn.TextColor3 = State.currentThemeColor
                if key ~= Enum.KeyCode.Unknown then
                    local isBound, boundTo = false, nil
                    for otherName, otherBind in pairs(keybindRegistry) do
                        if otherName ~= name and otherBind.GetKey and otherBind.GetKey() == key then
                            isBound, boundTo = true, otherName
                            break
                        end
                    end
                    if not isBound and State.S.ModuleBinds then
                        for modName, bKey in pairs(State.S.ModuleBinds) do
                            if modName ~= name and bKey == key.Name then
                                isBound, boundTo = true, modName
                                break
                            end
                        end
                    end
                    if isBound then
                        listening = false
                        bindBtn.Text = (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "[none]"
                        bindBtn.TextColor3 = State.currentThemeColor
                        UI.showToast("Key [" .. key.Name .. "] already bound to: " .. tostring(boundTo) .. "! Choose another key or unbind.", Color3.fromRGB(240, 70, 70))
                        return
                    end
                end
                listening = false
                currentKey = key
                bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[none]"
                bindBtn.TextColor3 = State.currentThemeColor
                callback(key)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                task.wait(0.05)
                if listening then listening = false; bindBtn.Text = (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "[none]"; bindBtn.TextColor3 = State.currentThemeColor end
            end
        end
    end)
    table.insert(State.S.Connections, con)
    return optObj
end

UI.addTextboxOption = function(parent, name, placeholder, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 12); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local box = Instance.new("TextBox"); box.Size = UDim2.new(1, -8, 0, 14); box.Position = UDim2.new(0, 4, 0, 12)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30); box.BorderSizePixel = 0; box.Font = Enum.Font.Gotham; box.TextSize = 9
    box.TextColor3 = Color3.fromRGB(255, 255, 255); box.PlaceholderText = placeholder; box.Text = ""; box.ClearTextOnFocus = false; box.Parent = row
    local boxCorner = Instance.new("UICorner"); boxCorner.CornerRadius = UDim.new(0, 4); boxCorner.Parent = box
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(50, 50, 50); stroke.Parent = box
    box.FocusLost:Connect(function() callback(box.Text) end)
    return { Set = function(valText) box.Text = valText end }
end

UI.addButtonOption = function(parent, name, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 22); row.BackgroundTransparency = 1; row.Parent = parent
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -8, 0, 18); btn.Position = UDim2.new(0, 4, 0.5, -9)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38); btn.BorderSizePixel = 0; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Text = name; btn.Parent = row
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 4); btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke"); btnStroke.Color = State.currentThemeColor; btnStroke.Thickness = 1; btnStroke.Parent = btn
    table.insert(themeToggles, function() btnStroke.Color = State.currentThemeColor end)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38) end)
    btn.MouseButton1Click:Connect(callback)
    return { Button = btn, SetText = function(str) btn.Text = str end }
end

UI.addSectionHeader = function(parent, title)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 22); row.BackgroundTransparency = 1; row.Parent = parent
    local text = Instance.new("TextLabel"); text.Size = UDim2.new(1, -8, 1, 0); text.Position = UDim2.new(0, 4, 0, 0)
    text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamBold; text.TextSize = 10; text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextXAlignment = Enum.TextXAlignment.Left; text.Text = "── " .. title:upper() .. " ──"; text.Parent = row
end

UI.addInfoRowOption = function(parent, name, initialValue)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 16); row.BackgroundTransparency = 1; row.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.5, 0, 1, 0); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name; label.Parent = row
    local valLabel = Instance.new("TextLabel"); valLabel.Size = UDim2.new(0.5, -8, 1, 0); valLabel.Position = UDim2.new(0.5, 4, 0, 0)
    valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 10; valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right; valLabel.Text = initialValue; valLabel.Parent = row
    return { Label = valLabel, SetValue = function(self, val) valLabel.Text = tostring(val) end, SetColor = function(self, color) valLabel.TextColor3 = color end }
end

UI.addCustomFrameOption = function(parent, height)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, height); row.BackgroundColor3 = Color3.fromRGB(20, 20, 20); row.BackgroundTransparency = 1; row.BorderSizePixel = 0; row.Parent = parent
    return row
end

UI.addScrollFeedOption = function(parent, height)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -8, 0, height); row.Position = UDim2.new(0, 4, 0, 0)
    row.BackgroundColor3 = Color3.fromRGB(15, 15, 15); row.BorderSizePixel = 0; row.Parent = parent
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(30, 30, 30); stroke.Parent = row
    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -4, 1, -4); scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = row
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 1); layout.Parent = scroll
    local entriesMap, entryCount = {}, 0
    return {
        Clear = function() for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end; entriesMap = {}; entryCount = 0 end,
        AddEntry = function(self, text, color, count)
            local initialCount = count or 1; local existing = entriesMap[text]
            if existing then existing.count = existing.count + initialCount; existing.label.Text = string.format("%s (x%d)", text, existing.count); return end
            entryCount = entryCount + 1; local currentOrder = entryCount; local scale = 1.0
            local winFrame = findWindowFrame(row)
            if winFrame then local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset; if baseW > 0 then scale = winFrame.Size.X.Offset / baseW end end
            local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 12 * scale); label:SetAttribute("BaseSize", UDim2.new(1, 0, 0, 12))
            label:SetAttribute("BasePos", UDim2.new(0, 0, 0, 0)); label:SetAttribute("BaseTextSize", 7); label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code; label.TextSize = math.clamp(math.round(7 * scale), 7, 24); label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
            label.TextXAlignment = Enum.TextXAlignment.Left; label.LayoutOrder = currentOrder
            local displayText = text; if initialCount > 1 then displayText = string.format("%s (x%d)", text, initialCount) end
            label.Text = displayText; label.TextWrapped = true; label.Parent = scroll
            entriesMap[text] = { label = label, count = initialCount }
            task.defer(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end)
        end
    }
end

local catPositions = { ["Combat"] = 20, ["Player"] = 210, ["Movement"] = 400, ["Render"] = 590, ["World"] = 780, ["Misc"] = 970, ["Search"] = 1160 }
UI.getOrCreateWindow = function(catName, defaultX, defaultY)
    if UI.windows[catName] then return UI.windows[catName] end
    local x = catPositions[catName] or defaultX or 20; local y = defaultY or 75
    if not defaultY or defaultY == 50 then y = 75 end
    local win = Instance.new("Frame"); win.Size = UDim2.new(0, 180, 0, 22); win.AutomaticSize = Enum.AutomaticSize.Y
    win.Position = UDim2.new(0, x, 0, y); win.BackgroundColor3 = Color3.fromRGB(20, 20, 20); win.BorderSizePixel = 0
    win.ClipsDescendants = true; win.Parent = mainUIContainer
    local winCorner = Instance.new("UICorner"); winCorner.CornerRadius = UDim.new(0, 6); winCorner.Parent = win

    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.AutoButtonColor = false
    header.Text = ""
    header.ClipsDescendants = true
    header.ZIndex = 2
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)
    local headerCorner = Instance.new("UICorner"); headerCorner.CornerRadius = UDim.new(0, 6); headerCorner.Parent = header

    local fillL = Instance.new("Frame")
    fillL.Name = "FillL"
    fillL.Size = UDim2.new(0, 6, 0, 6)
    fillL.Position = UDim2.new(0, 0, 1, -6)
    fillL.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or State.currentThemeColor
    fillL.BorderSizePixel = 0
    fillL.ZIndex = 1
    fillL.Parent = header
    table.insert(themeLeftCornerFills, fillL)

    local rightFillCol = (State.S.ThemeGradientStyle == "Solid Color" or State.S.ThemeGradientStyle == "Glow Accent") and State.currentThemeColor or State.currentThemeGradientColor
    local fillR = Instance.new("Frame")
    fillR.Name = "FillR"
    fillR.Size = UDim2.new(0, 6, 0, 6)
    fillR.Position = UDim2.new(1, -6, 1, -6)
    fillR.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or rightFillCol
    fillR.BorderSizePixel = 0
    fillR.ZIndex = 1
    fillR.Parent = header
    table.insert(themeRightCornerFills, fillR)

    local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(1, -30, 1, 0); titleLbl.Position = UDim2.new(0, 8, 0, 0); titleLbl.ZIndex = 5
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 10; titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = catName; titleLbl.Parent = header
    local collapseBtn = Instance.new("TextLabel"); collapseBtn.Size = UDim2.new(0, 22, 0, 22); collapseBtn.Position = UDim2.new(1, -22, 0, 0); collapseBtn.ZIndex = 5
    collapseBtn.BackgroundTransparency = 1; collapseBtn.Font = Enum.Font.GothamBold; collapseBtn.TextSize = 9
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); collapseBtn.Text = "▼"; collapseBtn.Parent = header

    local list = Instance.new("Frame"); list.Size = UDim2.new(1, 0, 0, 0); list.AutomaticSize = Enum.AutomaticSize.Y
    list.Position = UDim2.new(0, 0, 0, 22); list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.Parent = win
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 0); listPadding.PaddingBottom = UDim.new(0, 4)
    listPadding.PaddingLeft = UDim.new(0, 0); listPadding.PaddingRight = UDim.new(0, 0)
    listPadding.Parent = list
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 1); listLayout.Parent = list
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(35, 35, 40); stroke.Thickness = 1; stroke.Parent = win

    makeDraggable(win, header); local collapsed = false
    local function toggleCollapse()
        collapsed = not collapsed
        list.Visible = not collapsed
        fillL.Visible = not collapsed
        fillR.Visible = not collapsed
        if collapsed then
            win.AutomaticSize = Enum.AutomaticSize.None
            win.Size = UDim2.new(0, 180, 0, 22)
        else
            win.AutomaticSize = Enum.AutomaticSize.Y
            win.Size = UDim2.new(0, 180, 0, 22)
        end
        collapseBtn.Text = collapsed and "▲" or "▼"
        if UI.windows[catName] then UI.windows[catName].Collapsed = collapsed end
    end
    header.MouseButton1Click:Connect(toggleCollapse)
    UI.windows[catName] = { Frame = win, Header = header, TitleLabel = titleLbl, List = list, Layout = listLayout, FillL = fillL, FillR = fillR, Collapsed = false }; return UI.windows[catName]
end

UI.createFloatingWindow = function(title, width, height, defaultX, defaultY)
    local win = Instance.new("Frame"); win.Size = UDim2.new(0, width, 0, height); win.Position = UDim2.new(0, defaultX, 0, defaultY)
    win.BackgroundColor3 = Color3.fromRGB(20, 20, 20); win.BorderSizePixel = 0; win.ClipsDescendants = true; win.Visible = false
    win.ZIndex = 5; win.Parent = mainUIContainer
    local winCorner = Instance.new("UICorner"); winCorner.CornerRadius = UDim.new(0, 6); winCorner.Parent = win

    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.AutoButtonColor = false
    header.Text = ""
    header.ClipsDescendants = true
    header.ZIndex = 2
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)
    local headerCorner = Instance.new("UICorner"); headerCorner.CornerRadius = UDim.new(0, 6); headerCorner.Parent = header

    local fillL = Instance.new("Frame")
    fillL.Name = "FillL"
    fillL.Size = UDim2.new(0, 6, 0, 6)
    fillL.Position = UDim2.new(0, 0, 1, -6)
    fillL.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or State.currentThemeColor
    fillL.BorderSizePixel = 0
    fillL.ZIndex = 1
    fillL.Parent = header
    table.insert(themeLeftCornerFills, fillL)

    local rightFillCol = (State.S.ThemeGradientStyle == "Solid Color" or State.S.ThemeGradientStyle == "Glow Accent") and State.currentThemeColor or State.currentThemeGradientColor
    local fillR = Instance.new("Frame")
    fillR.Name = "FillR"
    fillR.Size = UDim2.new(0, 6, 0, 6)
    fillR.Position = UDim2.new(1, -6, 1, -6)
    fillR.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or rightFillCol
    fillR.BorderSizePixel = 0
    fillR.ZIndex = 1
    fillR.Parent = header
    table.insert(themeRightCornerFills, fillR)

    local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(1, -48, 1, 0); titleLbl.Position = UDim2.new(0, 8, 0, 0); titleLbl.ZIndex = 5
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 10; titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = title; titleLbl.Parent = header
    local collapsed = false; local baseHeight = height
    local collapseBtn = Instance.new("TextButton"); collapseBtn.Size = UDim2.new(0, 22, 0, 22); collapseBtn.Position = UDim2.new(1, -44, 0, 0); collapseBtn.ZIndex = 5
    collapseBtn.BackgroundTransparency = 1; collapseBtn.AutoButtonColor = false; collapseBtn.Font = Enum.Font.GothamBold; collapseBtn.TextSize = 10
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); collapseBtn.Text = "-"; collapseBtn.Parent = header
    local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0, 22, 0, 22); closeBtn.Position = UDim2.new(1, -22, 0, 0); closeBtn.ZIndex = 5
    closeBtn.BackgroundTransparency = 1; closeBtn.AutoButtonColor = false; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 10
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.Text = "X"; closeBtn.Parent = header
    closeBtn.MouseButton1Click:Connect(function() win.Visible = false; win:SetAttribute("UserOpen", false) end)

    if State.S.ThemeColor == "Galaxy" then
        initGalaxyBackground()
    else
        local grad1 = header:FindFirstChildOfClass("UIGradient")
        if grad1 then UI.updateSingleGradient(grad1) end
    end
    local content = Instance.new("ScrollingFrame"); content.Name = "content"; content.Size = UDim2.new(1, 0, 1, -22)
    content.Position = UDim2.new(0, 0, 0, 22); content.BackgroundColor3 = Color3.fromRGB(20, 20, 20); content.BackgroundTransparency = 1
    content.BorderSizePixel = 0; content.ScrollBarThickness = 2; content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.Parent = win
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 4); listLayout.Parent = content
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 4); padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4); padding.PaddingRight = UDim.new(0, 4); padding.Parent = content
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(35, 35, 40); stroke.Thickness = 1.2; stroke.Parent = win
    local resizeHandle = Instance.new("Frame"); resizeHandle.Name = "resizeHandle"; resizeHandle.Size = UDim2.new(0, 6, 0, 6)
    resizeHandle.Position = UDim2.new(1, -6, 1, -6); resizeHandle.BackgroundColor3 = State.currentThemeColor; resizeHandle.BackgroundTransparency = 0.3
    resizeHandle.BorderSizePixel = 0; resizeHandle.ZIndex = 10; resizeHandle.Parent = win; table.insert(themeFills, resizeHandle)
    makeResizable(win, resizeHandle)
    collapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        fillL.Visible = not collapsed
        fillR.Visible = not collapsed
        resizeHandle.Visible = not collapsed
        if collapsed then baseHeight = win.Size.Y.Offset; win.Size = UDim2.new(0, win.Size.X.Offset, 0, 22); collapseBtn.Text = "+"
        else win.Size = UDim2.new(0, win.Size.X.Offset, 0, baseHeight); collapseBtn.Text = "-" end
    end)
    makeDraggable(win, header); table.insert(UI.floatingWindows, win)
    win:SetAttribute("BaseWidth", width); win:SetAttribute("BaseHeight", height); local isScaling = false
    win:GetPropertyChangedSignal("Size"):Connect(function()
        if collapsed or isScaling then return end; isScaling = true
        local currentWidth = win.Size.X.Offset; local baseWidth = win:GetAttribute("BaseWidth") or width
        if baseWidth > 0 then
            local scale = currentWidth / baseWidth; autoScaleContent(win, scale)
            local totalContentHeight, count = 0, 0
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "resizeHandle" then totalContentHeight = totalContentHeight + child.Size.Y.Offset; count = count + 1 end
            end
            local lL = content:FindFirstChildOfClass("UIListLayout"); local pV = lL and lL.Padding.Offset or (4 * scale)
            local uP = content:FindFirstChildOfClass("UIPadding"); local pT = uP and uP.PaddingTop.Offset or (4 * scale)
            local pB = uP and uP.PaddingBottom.Offset or (4 * scale)
            local contentHeight = pT + pB + totalContentHeight + math.max(0, count - 1) * pV + 2 * scale
            local finalHeight = math.clamp((22 * scale) + contentHeight, 50 * scale, 400 * scale)
            win.Size = UDim2.new(0, currentWidth, 0, finalHeight)
        end
        isScaling = false
    end)
    return win, content
end

UI.registerModule = function(catName, name, defaultX, defaultY, isToggle, defaultState, callback, populateOptionsFunc, useSeparateWindow, winWidth, winHeight)
    local win = UI.getOrCreateWindow(catName, defaultX, defaultY)
    local container = Instance.new("Frame"); container.Name = "Mod_" .. name; container.Size = UDim2.new(1, 0, 0, 20)
    container.AutomaticSize = Enum.AutomaticSize.Y; container.BackgroundColor3 = Color3.fromRGB(24, 24, 28); container.BackgroundTransparency = 1; container.BorderSizePixel = 0; container.Parent = win.List
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.5; btn.BorderSizePixel = 0; btn.Text = ""; btn.Parent = container
    local inactiveColor = Color3.fromRGB(200, 200, 200)
    if name == "No Recoil" or name == "Silent Aim" or name == "Instant Respawn" then
        inactiveColor = Color3.fromRGB(255, 120, 120)
    elseif name == "God Mode" or name == "UI Name Spoof" then
        inactiveColor = Color3.fromRGB(255, 180, 100)
    end
    local modTextLabel = Instance.new("TextLabel"); modTextLabel.Name = "ModTextLabel"; modTextLabel.Size = UDim2.new(1, -20, 1, 0)
    modTextLabel.Position = UDim2.new(0, 6, 0, 0); modTextLabel.BackgroundTransparency = 1; modTextLabel.Font = Enum.Font.Gotham; modTextLabel.TextSize = 9
    modTextLabel.TextColor3 = (isToggle and defaultState) and Color3.fromRGB(100, 240, 100) or inactiveColor
    modTextLabel.TextXAlignment = Enum.TextXAlignment.Left; modTextLabel.Text = name; modTextLabel.ZIndex = 5; modTextLabel.Parent = btn
    btn.TextColor3 = modTextLabel.TextColor3

    UI.moduleCategories[name] = catName
    UI.moduleContainers[name] = container
    UI.moduleLabels[name] = modTextLabel
    UI.moduleButtonsRaw[name] = btn
    local active = defaultState

    local function updateColor()
        local currentInactiveColor = Color3.fromRGB(200, 200, 200)
        if patchedModules[name:lower()] then
            currentInactiveColor = Color3.fromRGB(255, 60, 60)
        elseif name == "UI Name Spoof" then
            currentInactiveColor = Color3.fromRGB(255, 180, 100)
        end
        local c = (isToggle and active) and ((patchedModules[name:lower()] and Color3.fromRGB(255, 60, 60)) or Color3.fromRGB(100, 240, 100)) or currentInactiveColor
        btn.TextColor3 = c
        modTextLabel.TextColor3 = c
        task.defer(UI.updateHUDArrayList)
    end

    local drawer = nil; local floatingWin = nil; local gear = nil
    local function updateBg()
        local isOpened = false
        if useSeparateWindow and floatingWin then isOpened = floatingWin.Visible elseif drawer then isOpened = drawer.Visible end
        if isOpened then
            btn.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
            btn.BackgroundTransparency = 0
            container.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            container.BackgroundTransparency = 0
            if not useSeparateWindow and drawer then
                drawer.BackgroundTransparency = 0
            end
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.BackgroundTransparency = 0.5
            container.BackgroundTransparency = 1
        end
    end

    btn.MouseEnter:Connect(function()
        local isOpened = (useSeparateWindow and floatingWin and floatingWin.Visible) or (drawer and drawer.Visible)
        if not isOpened then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.BackgroundTransparency = 0.3
        end
    end)
    btn.MouseLeave:Connect(function()
        updateBg()
    end)

    local function toggleMenu()
        if useSeparateWindow then
            if not floatingWin then
                local w = winWidth or 160; local h = winHeight or 180
                floatingWin, drawer = UI.createFloatingWindow(name .. " Options", w, h, win.Frame.Position.X.Offset + 190, win.Frame.Position.Y.Offset)
                if populateOptionsFunc then populateOptionsFunc(drawer) end
                adjustWindowSizeToContent(floatingWin, drawer)
            end
            floatingWin.Visible = not floatingWin.Visible; floatingWin:SetAttribute("UserOpen", floatingWin.Visible); updateBg()
        else
            if not drawer then
                drawer = Instance.new("Frame"); drawer.Name = "drawer"; drawer.Size = UDim2.new(1, 0, 0, 0)
                drawer.Position = UDim2.new(0, 0, 0, 20)
                drawer.AutomaticSize = Enum.AutomaticSize.Y; drawer.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                drawer.BackgroundTransparency = 0; drawer.BorderSizePixel = 0; drawer.Visible = false; drawer.Parent = container
                local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = drawer
                local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4); pad.PaddingRight = UDim.new(0, 4); pad.Parent = drawer
                local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(48, 48, 56); stroke.Thickness = 1; stroke.Parent = drawer
                if populateOptionsFunc then populateOptionsFunc(drawer) end
            end
            drawer.Visible = not drawer.Visible; updateBg()
        end
    end

    if populateOptionsFunc then
        gear = Instance.new("TextButton"); gear.Size = UDim2.new(0, 16, 0, 16); gear.Position = UDim2.new(1, -18, 0.5, -8)
        gear.BackgroundTransparency = 1; gear.Font = Enum.Font.GothamBold; gear.TextSize = 10; gear.TextColor3 = Color3.fromRGB(130, 130, 130)
        gear.Text = "*"; gear.Parent = btn
        gear.MouseButton1Click:Connect(toggleMenu)
        gear.MouseEnter:Connect(function() gear.TextColor3 = State.currentThemeColor end)
        gear.MouseLeave:Connect(function() gear.TextColor3 = Color3.fromRGB(130, 130, 130) end)
        UI.moduleGears[name] = gear
    end

    btn.MouseButton1Click:Connect(function()
        if State.S.ModuleDisableMode then
            if catName == "Misc" then
                UI.showToast("Cannot disable modules in the Misc tab!", Color3.fromRGB(218, 38, 38))
                return
            end
            local nowDisabled = not UI.isModuleDisabled(name)
            UI.setModuleDisabled(name, nowDisabled)
            UI.showToast((nowDisabled and "Disabled module: " or "Re-enabled module: ") .. name, nowDisabled and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(46, 204, 113))
            return
        end

        if UI.isModuleDisabled(name) then
            UI.showToast("'" .. name .. "' is disabled in Module Manager", Color3.fromRGB(160, 160, 165))
            return
        end

        if isToggle then active = not active; updateColor(); if callback then callback(active) end else if callback then callback() end end
    end)

    local itemObj = {
        Button = btn,
        TextLabel = modTextLabel,
        SetActive = function(val)
            if UI.isModuleDisabled(name) and val == true then return end
            if isToggle and active ~= val then
                active = val
                updateColor()
                if callback then callback(val) end
            elseif not isToggle then
                if callback then callback() end
            end
        end,
        IsActive = function() return isToggle and active end,
        ToggleMenu = toggleMenu
    }
    UI.moduleButtons[name] = itemObj
    task.defer(function()
        UI.updateModuleVisual(name)
    end)
    return itemObj
end

local function selectTab(tabName)
    activeTab = tabName
    for name, btn in pairs(UI.tabButtons) do
        if name == tabName then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.GothamBold
        else
            btn.TextColor3 = Color3.fromRGB(210, 210, 210); btn.Font = Enum.Font.Gotham
        end
    end
    UI.updateMenuBlur()
    if settingsPanel then settingsPanel.Visible = false end
    if bindsPanel then bindsPanel.Visible = false end
    if tabName == "Modules" then
        if chatPanel then
            if State.S.ChatHideOnModules ~= false then
                chatPanel.Visible = false
            else
                chatPanel.Visible = true
            end
        end
        local query = (searchBox and searchBox.Text or ""):lower()
        for _, win in pairs(UI.windows) do
            local hasVisibleModule = false
            for _, child in ipairs(win.List:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1, 4) == "Mod_" then
                    local modName = child.Name:sub(5)
                    local isDisabled = UI.isModuleDisabled(modName)
                    local isSelectMode = (State.S.ModuleDisableMode == true)
                    local style = State.S.DisabledModuleStyle or "Greyish"
                    local hiddenByDisable = (isDisabled and style == "Invisible" and not isSelectMode)
                    local matches = (query == "") or (modName:lower():find(query, 1, true) ~= nil)
                    child.Visible = matches and not hiddenByDisable
                    if child.Visible then
                        hasVisibleModule = true
                    end
                end
            end
            win.Frame.Visible = (query == "" or hasVisibleModule)
        end
        for _, win in ipairs(UI.floatingWindows) do
            if win:GetAttribute("UserOpen") == true then win.Visible = true end
        end
    elseif tabName == "Settings" then
        for _, win in pairs(UI.windows) do win.Frame.Visible = false end
        for _, win in ipairs(UI.floatingWindows) do win.Visible = false end
        if chatPanel then chatPanel.Visible = false end
        if settingsPanel then
            settingsPanel.Visible = true
            adjustWindowSizeToContent(settingsPanel, settingsContent)
        end
    elseif tabName == "(Chat)" or tabName == "Chat" then
        for _, win in pairs(UI.windows) do win.Frame.Visible = false end
        for _, win in ipairs(UI.floatingWindows) do win.Visible = false end
        if chatPanel then
            chatPanel.Visible = true
            if not chatPanel:GetAttribute("UserResized") then
                adjustWindowSizeToContent(chatPanel, chatContent)
            end
            if UI.refreshChatPanelUsers then pcall(UI.refreshChatPanelUsers) end
        end
    elseif tabName == "Binds" then
        for _, win in pairs(UI.windows) do win.Frame.Visible = false end
        for _, win in ipairs(UI.floatingWindows) do win.Visible = false end
        if chatPanel then chatPanel.Visible = false end
        if bindsPanel then
            bindsPanel.Visible = true
            adjustWindowSizeToContent(bindsPanel, bindsContent)
        end
    end
end

UI.ResetAllToggles = function(self)
    for name, item in pairs(UI.moduleButtons) do
        if item.IsActive and item.IsActive() then
            item.SetActive(false)
        end
    end
end

local function createPanel(title, width, height)
    local win = Instance.new("Frame"); win.Size = UDim2.new(0, width, 0, height); win.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    win.BackgroundColor3 = Color3.fromRGB(20, 20, 20); win.BorderSizePixel = 0; win.ClipsDescendants = true; win.Visible = false; win.Parent = mainUIContainer
    local winCorner = Instance.new("UICorner"); winCorner.CornerRadius = UDim.new(0, 6); winCorner.Parent = win

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.ClipsDescendants = true
    header.ZIndex = 2
    header.Parent = win
    table.insert(themeHeaders, header)
    addHeaderGradient(header)
    local headerCorner = Instance.new("UICorner"); headerCorner.CornerRadius = UDim.new(0, 6); headerCorner.Parent = header

    local fillL = Instance.new("Frame")
    fillL.Name = "FillL"
    fillL.Size = UDim2.new(0, 6, 0, 6)
    fillL.Position = UDim2.new(0, 0, 1, -6)
    fillL.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or State.currentThemeColor
    fillL.BorderSizePixel = 0
    fillL.ZIndex = 1
    fillL.Parent = header
    table.insert(themeLeftCornerFills, fillL)

    local rightFillCol = (State.S.ThemeGradientStyle == "Solid Color" or State.S.ThemeGradientStyle == "Glow Accent") and State.currentThemeColor or State.currentThemeGradientColor
    local fillR = Instance.new("Frame")
    fillR.Name = "FillR"
    fillR.Size = UDim2.new(0, 6, 0, 6)
    fillR.Position = UDim2.new(1, -6, 1, -6)
    fillR.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or rightFillCol
    fillR.BorderSizePixel = 0
    fillR.ZIndex = 1
    fillR.Parent = header
    table.insert(themeRightCornerFills, fillR)

    local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(1, -30, 1, 0); titleLbl.Position = UDim2.new(0, 10, 0, 0); titleLbl.ZIndex = 5
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 10; titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = title; titleLbl.Parent = header
    local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0, 22, 0, 22); closeBtn.Position = UDim2.new(1, -22, 0, 0); closeBtn.ZIndex = 5
    closeBtn.BackgroundTransparency = 1; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 10; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"; closeBtn.Parent = header; closeBtn.MouseButton1Click:Connect(function() win.Visible = false; selectTab("Modules") end)
    local content = Instance.new("ScrollingFrame"); content.Name = "content"; content.Size = UDim2.new(1, 0, 1, -22); content.Position = UDim2.new(0, 0, 0, 22)
    content.BackgroundColor3 = Color3.fromRGB(20, 20, 20); content.BackgroundTransparency = 1; content.BorderSizePixel = 0
    content.ScrollBarThickness = 2; content.CanvasSize = UDim2.new(0, 0, 0, 0); content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.Parent = win
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 4); listLayout.Parent = content
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 6); padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6); padding.PaddingRight = UDim.new(0, 6); padding.Parent = content
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(35, 35, 40); stroke.Thickness = 1.2; stroke.Parent = win
    local resizeHandle = Instance.new("Frame"); resizeHandle.Name = "resizeHandle"; resizeHandle.Size = UDim2.new(0, 8, 0, 8)
    resizeHandle.Position = UDim2.new(1, -8, 1, -8); resizeHandle.BackgroundColor3 = (State.S.ThemeColor == "Galaxy") and getGalaxyBgColor() or State.currentThemeColor
    resizeHandle.BackgroundTransparency = 0.3; resizeHandle.BorderSizePixel = 0; resizeHandle.ZIndex = 12; resizeHandle.Parent = win
    table.insert(themeFills, resizeHandle)
    makeResizable(win, resizeHandle)
    makeDraggable(win, header)
    return win, content
end

UI.InitializeUI = function()
    local S = State.S
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MeteorRobloxGUI"; screenGui.ResetOnSpawn = false; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screenGui.Parent = Services.CoreGui end)
    if not screenGui.Parent then pcall(function() screenGui.Parent = Services.LP:WaitForChild("PlayerGui") end) end
    protectUIFonts(screenGui)

    mainUIContainer = Instance.new("Frame")
    mainUIContainer.Name = "MainUIContainer"; mainUIContainer.Size = UDim2.new(1, 0, 1, 0)
    mainUIContainer.BackgroundTransparency = 1; mainUIContainer.BorderSizePixel = 0
    mainUIContainer.Visible = true; mainUIContainer.Parent = screenGui

    UI.applyThemeColor(S.ThemeColor or "Purple")
    task.spawn(startTextAnimationLoop)
    task.spawn(startToastCleanupWatcher)

    menuBlur = Services.Lighting:FindFirstChild("WeAreSkiddingBlur")
    if not menuBlur then menuBlur = Instance.new("BlurEffect"); menuBlur.Name = "WeAreSkiddingBlur"; menuBlur.Size = 0; menuBlur.Enabled = false; menuBlur.Parent = Services.Lighting end

    hudArrayListFrame = Instance.new("Frame")
    hudArrayListFrame.Size = UDim2.new(0, 120, 0, 0); hudArrayListFrame.AutomaticSize = Enum.AutomaticSize.Y
    hudArrayListFrame.Position = UDim2.new(0, S.HUDArrayListX or 10, 0, S.HUDArrayListY or 70)
    hudArrayListFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); hudArrayListFrame.BackgroundTransparency = 0.3; hudArrayListFrame.BorderSizePixel = 0
    hudArrayListFrame.Visible = false; hudArrayListFrame.Parent = screenGui

    local hudStroke = Instance.new("UIStroke"); hudStroke.Color = Color3.fromRGB(45, 45, 45); hudStroke.Thickness = 1; hudStroke.Parent = hudArrayListFrame
    local hudPadding = Instance.new("UIPadding"); hudPadding.PaddingTop = UDim.new(0, 4); hudPadding.PaddingBottom = UDim.new(0, 4)
    hudPadding.PaddingLeft = UDim.new(0, 4); hudPadding.PaddingRight = UDim.new(0, 4); hudPadding.Parent = hudArrayListFrame
    local arrayLayout = Instance.new("UIListLayout"); arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    arrayLayout.VerticalAlignment = Enum.VerticalAlignment.Top; arrayLayout.Padding = UDim.new(0, 2); arrayLayout.Parent = hudArrayListFrame

    makeDraggable(hudArrayListFrame, hudArrayListFrame, function(pos)
        S.HUDArrayListX = pos.X.Offset
        S.HUDArrayListY = pos.Y.Offset
        VH.Config.saveConfig()
    end)

    task.spawn(function() while State.uiRunning do task.wait(0.2); pcall(UI.updateHUDArrayList) end end)

    topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 24); topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15); topBar.BorderSizePixel = 0; topBar.Parent = mainUIContainer
    local topStroke = Instance.new("UIStroke"); topStroke.Color = Color3.fromRGB(30, 30, 30); topStroke.Thickness = 1; topStroke.Parent = topBar

    local function getExecutorName()
        if identifyexecutor then local ok, name = pcall(identifyexecutor); if ok and name then return name end end
        if syn then return "Synapse" end; if krnl then return "Krnl" end; if fluxus then return "Fluxus" end
        return "Unknown"
    end
    local executorName = getExecutorName()

    local topTitle = Instance.new("TextLabel")
    topTitle.Size = UDim2.new(0, 450, 1, 0); topTitle.Position = UDim2.new(0, 10, 0, 0); topTitle.BackgroundTransparency = 1
    topTitle.Font = Enum.Font.GothamBold; topTitle.TextSize = 11; topTitle.TextColor3 = Color3.fromRGB(255, 255, 255); topTitle.ZIndex = 5
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.Text = "<font color='#ffffff'>WeAreSkidding</font> <font color='#e0e0e0'>On Roblox v4.5</font> <font color='#aaaaaa'>(" .. executorName .. ")</font>"
    topTitle.RichText = true; topTitle.Parent = topBar

    local hudTextLabel = Instance.new("TextLabel")
    hudTextLabel.Size = UDim2.new(0, 300, 1, 0); hudTextLabel.Position = UDim2.new(1, -330, 0, 0); hudTextLabel.BackgroundTransparency = 1
    hudTextLabel.Font = Enum.Font.Code; hudTextLabel.TextSize = 10; hudTextLabel.TextColor3 = Color3.fromRGB(220, 220, 220); hudTextLabel.ZIndex = 5
    hudTextLabel.TextXAlignment = Enum.TextXAlignment.Right; hudTextLabel.Text = "FPS: -- | PING: --"; hudTextLabel.Parent = topBar
    UI.HUDLabel = hudTextLabel

    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Size = UDim2.new(0, 12, 0, 12)
    refreshBtn.Position = UDim2.new(1, -22, 0.5, -6)
    refreshBtn.BackgroundTransparency = 1
    refreshBtn.Image = "rbxassetid://114496992333593"
    refreshBtn.ImageColor3 = Color3.fromRGB(220, 220, 220)
    refreshBtn.ZIndex = 5
    refreshBtn.Parent = topBar

    refreshBtn.MouseEnter:Connect(function()
        refreshBtn.ImageColor3 = State.currentThemeColor
    end)
    refreshBtn.MouseLeave:Connect(function()
        refreshBtn.ImageColor3 = Color3.fromRGB(180, 180, 180)
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        pcall(function()
            UI.showToast("Refreshing UI...", State.currentThemeColor)
            task.wait(0.2)

            pcall(function()
                if delfile then
                    delfile("WASOR_Cache/commit_sha.txt")
                    delfile("WASOR_Cache/Core/UI.lua")
                    delfile("WASOR_cache/commit_sha.txt")
                    delfile("WASOR_cache/Core/UI.lua")
                end
            end)

            VH.Cleanup.cleanupAll()
            task.wait(0.1)

            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/MizunoSync/WASOR/refs/heads/main/github_loader.lua"))()
            end)

            if success then
                print("[WASOR Reload]: Successfully reloaded from GitHub")
            else
                warn("[WASOR Reload]: Failed to reload from GitHub: " .. tostring(err))
            end
        end)
    end)

    toastContainer = Instance.new("Frame")
    toastContainer.Size = UDim2.new(0, 260, 0, 300); toastContainer.Position = UDim2.new(1, -270, 1, -325)
    toastContainer.BackgroundTransparency = 1; toastContainer.BorderSizePixel = 0; toastContainer.Parent = screenGui
    local toastLayout = Instance.new("UIListLayout"); toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom; toastLayout.Padding = UDim.new(0, 6); toastLayout.Parent = toastContainer

    local networkUsersHUD = Instance.new("Frame")
    networkUsersHUD.Name = "NetworkUsersHUD"
    networkUsersHUD.Size = UDim2.new(0, 180, 0, 0)
    networkUsersHUD.Position = UDim2.new(0, 10, 1, -10)
    networkUsersHUD.AnchorPoint = Vector2.new(0, 1)
    networkUsersHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    networkUsersHUD.BackgroundTransparency = 0.85
    networkUsersHUD.BorderSizePixel = 0
    networkUsersHUD.Active = true
    networkUsersHUD.ZIndex = 10
    networkUsersHUD.AutomaticSize = Enum.AutomaticSize.Y
    networkUsersHUD.Visible = S.NetworkTags and S.ShowNetworkUsersHUD
    networkUsersHUD.Parent = screenGui

    local netCorner = Instance.new("UICorner")
    netCorner.CornerRadius = UDim.new(0, 4)
    netCorner.Parent = networkUsersHUD

    local netStroke = Instance.new("UIStroke")
    netStroke.Color = Color3.fromRGB(45, 45, 45)
    netStroke.Thickness = 1
    netStroke.Parent = networkUsersHUD

    local netPadding = Instance.new("UIPadding")
    netPadding.PaddingTop = UDim.new(0, 4)
    netPadding.PaddingBottom = UDim.new(0, 4)
    netPadding.PaddingLeft = UDim.new(0, 6)
    netPadding.PaddingRight = UDim.new(0, 6)
    netPadding.Parent = networkUsersHUD

    local netLayout = Instance.new("UIListLayout")
    netLayout.Padding = UDim.new(0, 2)
    netLayout.Parent = networkUsersHUD

    local netHeader = Instance.new("TextLabel")
    netHeader.Size = UDim2.new(1, 0, 0, 14)
    netHeader.BackgroundTransparency = 1
    netHeader.Font = Enum.Font.GothamBold
    netHeader.TextSize = 10
    netHeader.TextColor3 = State.currentThemeColor
    netHeader.TextXAlignment = Enum.TextXAlignment.Left
    netHeader.Text = "Network Users (0)"
    netHeader.Parent = networkUsersHUD
    table.insert(themeTexts, netHeader)

    UI.networkUsersHUD = networkUsersHUD
    UI.netHeader = netHeader

    hudWatermark = Instance.new("TextLabel")
    hudWatermark.Size = UDim2.new(0, 200, 0, 14); hudWatermark.Position = UDim2.new(0, 10, 0, 26); hudWatermark.BackgroundTransparency = 1
    hudWatermark.Font = Enum.Font.GothamBold; hudWatermark.TextSize = 10; hudWatermark.TextColor3 = State.currentThemeColor
    hudWatermark.TextXAlignment = Enum.TextXAlignment.Left; hudWatermark.Text = "WASOR 4.5"; hudWatermark.Visible = S.HUDWatermark; hudWatermark.Parent = screenGui
    table.insert(themeTexts, hudWatermark)

    hudCoords = Instance.new("TextLabel")
    hudCoords.Size = UDim2.new(0, 250, 0, 14); hudCoords.Position = UDim2.new(0, 10, 0, 40); hudCoords.BackgroundTransparency = 1
    hudCoords.Font = Enum.Font.Code; hudCoords.TextSize = 9; hudCoords.TextColor3 = Color3.fromRGB(220, 220, 220)
    hudCoords.TextXAlignment = Enum.TextXAlignment.Left; hudCoords.Text = "XYZ: 0.0, 0.0, 0.0"; hudCoords.Visible = S.HUDCoords; hudCoords.Parent = screenGui

    hudServerAge = Instance.new("TextLabel")
    hudServerAge.Size = UDim2.new(0, 250, 0, 14); hudServerAge.Position = UDim2.new(0, 10, 0, 54); hudServerAge.BackgroundTransparency = 1
    hudServerAge.Font = Enum.Font.Code; hudServerAge.TextSize = 9; hudServerAge.TextColor3 = Color3.fromRGB(200, 200, 200)
    hudServerAge.TextXAlignment = Enum.TextXAlignment.Left; hudServerAge.Text = "AGE: 0m 0s"; hudServerAge.Visible = S.HUDServerAge; hudServerAge.Parent = screenGui

    settingsPanel, settingsContent = createPanel("Client Settings", 460, 320)
    settingsContent.Visible = false

    chatPanel, chatContent = createPanel("(Chat) & Network Users", 480, 340)
    chatPanel:SetAttribute("MinResizeW", 280)
    chatPanel:SetAttribute("MinResizeH", 180)
    chatContent.Visible = true

    UI.addSectionHeader(chatContent, "Network Chat Hub")
    UI.addToggleOption(chatContent, "Hide Chat When Switching to Modules", S.ChatHideOnModules ~= false, function(v)
        S.ChatHideOnModules = v
        VH.Config.saveConfig()
    end)
    UI.addToggleOption(chatContent, "Enable Network Chat Hub", S.NetworkChat, function(v)
        S.NetworkChat = v
        VH.Config.saveConfig()
        if v then
            task.spawn(function()
                pcall(function()
                    loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua'), true))()
                end)
            end)
        else
            local oldChat = game:GetService("CoreGui"):FindFirstChild("DiscordNetworkHub")
            if oldChat then oldChat:Destroy() end
        end
    end)
    UI.addButtonOption(chatContent, "Launch / Reload External Chat Window", function()
        pcall(function()
            loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua'), true))()
        end)
        UI.showToast("Network Chat launched!", State.currentThemeColor)
    end)

    UI.addSectionHeader(chatContent, "Network Users in Server")
    UI.addToggleOption(chatContent, "Show Network Users List HUD", S.ShowNetworkUsersHUD, function(v)
        S.ShowNetworkUsersHUD = v
        if UI.networkUsersHUD then UI.networkUsersHUD.Visible = S.NetworkTags and v end
        VH.Config.saveConfig()
    end)
    UI.addToggleOption(chatContent, "Show Player Head Tags", S.ShowNetworkHeadTags, function(v)
        S.ShowNetworkHeadTags = v
        if not v then
            for username, bill in pairs(State.networkTagsPool) do
                pcall(function() bill:Destroy() end)
                State.networkTagsPool[username] = nil
            end
        end
        VH.Config.saveConfig()
    end)
    UI.addButtonOption(chatContent, "Force Refresh Network Users", function()
        if VH.runNetworkTagsSync then pcall(VH.runNetworkTagsSync) end
        if UI.refreshChatPanelUsers then pcall(UI.refreshChatPanelUsers) end
        UI.showToast("Network users refreshed!", State.currentThemeColor)
    end)

    local netListFrame = Instance.new("Frame")
    netListFrame.Size = UDim2.new(1, 0, 0, 140)
    netListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    netListFrame.BorderSizePixel = 0
    netListFrame.Parent = chatContent
    local netCorner = Instance.new("UICorner"); netCorner.CornerRadius = UDim.new(0, 4); netCorner.Parent = netListFrame
    local netStroke = Instance.new("UIStroke"); netStroke.Color = Color3.fromRGB(40, 40, 45); netStroke.Parent = netListFrame

    local netListScroll = Instance.new("ScrollingFrame")
    netListScroll.Size = UDim2.new(1, -8, 1, -8)
    netListScroll.Position = UDim2.new(0, 4, 0, 4)
    netListScroll.BackgroundTransparency = 1
    netListScroll.BorderSizePixel = 0
    netListScroll.ScrollBarThickness = 3
    netListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    netListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    netListScroll.Parent = netListFrame
    local netListLayout = Instance.new("UIListLayout"); netListLayout.Padding = UDim.new(0, 3); netListLayout.Parent = netListScroll

    local function refreshChatPanelUsers()
        for _, ch in ipairs(netListScroll:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        local count = 0
        if State.networkTagsPool then
            for uname, _ in pairs(State.networkTagsPool) do
                count = count + 1
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 10
                lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Text = "👤 @" .. uname .. " [Online Network User]"
                lbl.Parent = netListScroll
            end
        end
        if count == 0 then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 10
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = "No other network users detected currently in this server."
            lbl.Parent = netListScroll
        end
    end
    UI.refreshChatPanelUsers = refreshChatPanelUsers
    refreshChatPanelUsers()

    bindsPanel, bindsContent = createPanel("Keybind Manager", 520, 380)
    bindsContent.Visible = true

    UI.addSectionHeader(bindsContent, "Quick Config Actions")
    UI.addButtonOption(bindsContent, "Save All Keybinds & Settings", function()
        VH.Config.saveConfig()
        UI.showToast("All settings and binds saved!", Color3.fromRGB(50, 195, 75))
    end)

    UI.addSectionHeader(bindsContent, "System & Utility Keybinds")
    UI.addKeybindOption(bindsContent, "Menu Toggle Keybind", S.UIToggleKey or Enum.KeyCode.RightControl, function(k) S.UIToggleKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Panic Button (Disable All)", S.PanicKey or Enum.KeyCode.End, function(k) S.PanicKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Trigger Macro Key", S.MacroKey or Enum.KeyCode.H, function(k) S.MacroKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Grab User ID (Hover)", S.UserIDGrabKey or Enum.KeyCode.K, function(k) S.UserIDGrabKey = k; VH.Config.saveConfig() end)

    UI.addSectionHeader(bindsContent, "Movement Keybinds")
    UI.addKeybindOption(bindsContent, "Sprint Speed Boost", S.SprintKey or Enum.KeyCode.LeftShift, function(k) S.SprintKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Fly Mode Bind", S.FlyKey or Enum.KeyCode.Unknown, function(k) S.FlyKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "NoClip Bind", S.NoClipKey or Enum.KeyCode.Unknown, function(k) S.NoClipKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Infinite Jump Bind", S.InfJumpKey or Enum.KeyCode.Unknown, function(k) S.InfJumpKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Auto Bunnyhop Bind", S.BHopKey or Enum.KeyCode.Unknown, function(k) S.BHopKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Ghost Mode Bind", S.GhostKey or Enum.KeyCode.Unknown, function(k) S.GhostKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Blink Teleport Bind", S.BlinkKey or Enum.KeyCode.Unknown, function(k) S.BlinkKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Jump Power Bind", S.JumpStrengthKey or Enum.KeyCode.Unknown, function(k) S.JumpStrengthKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Wall Walk Bind", S.WallWalkKey or Enum.KeyCode.V, function(k) S.WallWalkKey = k; VH.Config.saveConfig() end)

    UI.addSectionHeader(bindsContent, "Combat Keybinds")
    UI.addKeybindOption(bindsContent, "Walk Fling Bind", S.WalkFlingKey or Enum.KeyCode.Unknown, function(k) S.WalkFlingKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Aimbot Hold Key", S.AimbotHoldKey or Enum.KeyCode.Unknown, function(k) S.AimbotHoldKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Auto Clicker Bind", S.AutoClickerKey or Enum.KeyCode.Unknown, function(k) S.AutoClickerKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Kill Aura Bind", S.KillAuraKey or Enum.KeyCode.Unknown, function(k) S.KillAuraKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Triggerbot Bind", S.TriggerbotKey or Enum.KeyCode.Unknown, function(k) S.TriggerbotKey = k; VH.Config.saveConfig() end)

    UI.addSectionHeader(bindsContent, "Render & World Keybinds")
    UI.addKeybindOption(bindsContent, "Viewport ESP Bind", S.ViewportESPKey or Enum.KeyCode.P, function(k) S.ViewportESPKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Minimap Bind", S.MinimapKey or Enum.KeyCode.Unknown, function(k) S.MinimapKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Click Teleport Bind", S.ClickTeleportKey or Enum.KeyCode.Unknown, function(k) S.ClickTeleportKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Click Delete Bind", S.ClickDeleteKey or Enum.KeyCode.Unknown, function(k) S.ClickDeleteKey = k; VH.Config.saveConfig() end)
    UI.addKeybindOption(bindsContent, "Freecam / Spectate Bind", S.FreecamKey or Enum.KeyCode.Unknown, function(k) S.FreecamKey = k; VH.Config.saveConfig() end)

    UI.addSectionHeader(bindsContent, "Dynamic Module Keybinds")
    S.ModuleBinds = S.ModuleBinds or {}
    for modName, _ in pairs(UI.moduleButtons) do
        local curBind = (S.ModuleBinds[modName] and Enum.KeyCode[S.ModuleBinds[modName]]) or Enum.KeyCode.Unknown
        UI.addKeybindOption(bindsContent, modName .. " Bind", curBind, function(k)
            if k == Enum.KeyCode.Unknown then
                S.ModuleBinds[modName] = nil
            else
                S.ModuleBinds[modName] = k.Name
            end
            VH.Config.saveConfig()
        end)
    end

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 130, 1, -22)
    sidebar.Position = UDim2.new(0, 0, 0, 22)
    sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = settingsPanel

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 8)
    sidebarPadding.PaddingRight = UDim.new(0, 8)
    sidebarPadding.Parent = sidebar

    local mainContent = Instance.new("Frame")
    mainContent.Size = UDim2.new(1, -130, 1, -22)
    mainContent.Position = UDim2.new(0, 130, 0, 22)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = settingsPanel

    local function createTabPage()
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        page.BackgroundTransparency = 0.15
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = mainContent

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = page

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.Parent = page

        return page
    end

    local pageProfiles = createTabPage()
    local pageUI = createTabPage()
    local pageHUD = createTabPage()
    local pageInput = createTabPage()
    local pageConfig = createTabPage()
    local pageModules = createTabPage()

    local currentSelectedSettingsTabName = "Profiles"
    local tabPages = {
        ["Profiles"] = pageProfiles,
        ["UI Customization"] = pageUI,
        ["HUD Settings"] = pageHUD,
        ["Input & Macros"] = pageInput,
        ["System & Config"] = pageConfig,
        ["Module Manager"] = pageModules
    }

    local function selectSettingsTab(tabName)
        currentSelectedSettingsTabName = tabName
        for name, page in pairs(tabPages) do
            page.Visible = (name == tabName)
        end
        for _, btn in ipairs(sidebar:GetChildren()) do
            if btn:IsA("TextButton") then
                if btn.Text == tabName then
                    btn.BackgroundColor3 = State.currentThemeColor
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    btn.TextColor3 = Color3.fromRGB(160, 160, 160)
                end
            end
        end
        if tabName == "Module Manager" and UI.refreshDisabledModulesList then
            pcall(UI.refreshDisabledModulesList)
        end
    end

    local function createSidebarButton(tabName)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = Color3.fromRGB(160, 160, 160)
        btn.Text = tabName
        btn.Parent = sidebar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn

        btn.MouseEnter:Connect(function()
            if currentSelectedSettingsTabName ~= tabName then
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                btn.TextColor3 = State.currentThemeColor
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentSelectedSettingsTabName ~= tabName then
                btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                btn.TextColor3 = Color3.fromRGB(160, 160, 160)
            end
        end)

        btn.MouseButton1Click:Connect(function()
            selectSettingsTab(tabName)
        end)

        return btn
    end

    createSidebarButton("Profiles")
    createSidebarButton("UI Customization")
    createSidebarButton("HUD Settings")
    createSidebarButton("Input & Macros")
    createSidebarButton("System & Config")

    table.insert(themeToggles, function()
        selectSettingsTab(currentSelectedSettingsTabName)
    end)

    selectSettingsTab("Profiles")

    UI.addSectionHeader(pageProfiles, "Configuration Profiles")
    UI.addButtonOption(pageProfiles, "Apply legit closet profile", function()
        UI:ResetAllToggles()
        S.WalkSpeed = 22; S.JumpPower = 55; S.ForceWalkSpeed = true; S.ESPBoxes = true; S.ESPTransparency = 0.9; S.AimbotActive = true; S.AimbotFOV = 40; S.AimbotSmooth = 15; S.ESPNames = true
        if UI.moduleButtons["WalkSpeed"] then UI.moduleButtons["WalkSpeed"].SetActive(true) end
        if UI.moduleButtons["ESP Box Outlines"] then UI.moduleButtons["ESP Box Outlines"].SetActive(true) end
        if UI.moduleButtons["Aimbot"] then UI.moduleButtons["Aimbot"].SetActive(true) end
        if UI.moduleButtons["Show Player Names"] then UI.moduleButtons["Show Player Names"].SetActive(true) end
        VH.Config.saveConfig(); VH.Utils.notify("Closet Legit profile applied!", Color3.fromRGB(46, 204, 113))
    end)
    UI.addButtonOption(pageProfiles, "Apply blatant flight profile", function()
        UI:ResetAllToggles()
        S.Fly = true; S.NoClip = true; S.InfJump = true; S.WalkSpeed = 65; S.JumpPower = 80; S.ForceWalkSpeed = true; S.ForceJumpPower = true; S.ESPBoxes = true; S.ESPHealth = true; S.ESPNames = true; S.ESPDistances = true
        if UI.moduleButtons["Fly Mode"] then UI.moduleButtons["Fly Mode"].SetActive(true) end
        if UI.moduleButtons["Noclip"] then UI.moduleButtons["Noclip"].SetActive(true) end
        if UI.moduleButtons["Infinite Jump"] then UI.moduleButtons["Infinite Jump"].SetActive(true) end
        if UI.moduleButtons["WalkSpeed"] then UI.moduleButtons["WalkSpeed"].SetActive(true) end
        if UI.moduleButtons["Jump Power"] then UI.moduleButtons["Jump Power"].SetActive(true) end
        if UI.moduleButtons["ESP Box Outlines"] then UI.moduleButtons["ESP Box Outlines"].SetActive(true) end
        if UI.moduleButtons["Show Player Names"] then UI.moduleButtons["Show Player Names"].SetActive(true) end
        if UI.moduleButtons["Show Health Text"] then UI.moduleButtons["Show Health Text"].SetActive(true) end
        VH.Config.saveConfig(); VH.Utils.notify("Blatant profile applied!", Color3.fromRGB(241, 196, 15))
    end)
    UI.addButtonOption(pageProfiles, "Apply rage combat profile", function()
        UI:ResetAllToggles()
        S.Fly = true; S.NoClip = true; S.KillAura = true; S.GodMode = true; S.AimbotActive = true; S.AimbotFOV = 600; S.AimbotSmooth = 1; S.InstantPrompts = true; S.AntiVoid = true
        if UI.moduleButtons["Fly Mode"] then UI.moduleButtons["Fly Mode"].SetActive(true) end
        if UI.moduleButtons["Noclip"] then UI.moduleButtons["Noclip"].SetActive(true) end
        if UI.moduleButtons["Kill Aura"] then UI.moduleButtons["Kill Aura"].SetActive(true) end
        if UI.moduleButtons["God Mode"] then UI.moduleButtons["God Mode"].SetActive(true) end
        if UI.moduleButtons["Aimbot"] then UI.moduleButtons["Aimbot"].SetActive(true) end
        if UI.moduleButtons["Instant Prompts"] then UI.moduleButtons["Instant Prompts"].SetActive(true) end
        if UI.moduleButtons["Anti Void"] then UI.moduleButtons["Anti Void"].SetActive(true) end
        VH.Config.saveConfig(); VH.Utils.notify("Rage profile applied!", Color3.fromRGB(218, 38, 38))
    end)

    UI.addSectionHeader(pageUI, "Active UI Theme & Galaxy Config")
    local allThemes = {"Galaxy", "Purple", "Red", "Green", "Blue", "Yellow", "Cyan", "Pink", "Orange", "Sunset", "Emerald", "Midnight", "Gold Rush", "Rainbow", "Custom"}
    UI.addDropdownOption(pageUI, "Select Active Theme", allThemes, table.find(allThemes, S.ThemeColor or "Galaxy") or 1, function(_, opt)
        UI.applyThemeColor(opt)
        VH.Config.saveConfig()
    end)

    local galaxyBgStyles = {"Deep Space (Black)", "Dark Purple Nebula", "Midnight Blue", "Cosmic Crimson", "Custom Hex"}
    UI.addDropdownOption(pageUI, "Galaxy Background Style", galaxyBgStyles, table.find(galaxyBgStyles, S.GalaxyBgStyle or "Deep Space (Black)") or 1, function(_, opt)
        S.GalaxyBgStyle = opt
        if S.ThemeColor == "Galaxy" then UI.applyThemeColor("Galaxy") end
        VH.Config.saveConfig()
    end)

    UI.addTextboxOption(pageUI, "Galaxy Custom Hex BG", S.GalaxyCustomBgHex or "#080810", function(hexText)
        local parsed = UI.parseHexColor(hexText)
        if parsed then
            S.GalaxyCustomBgHex = hexText
            S.GalaxyBgStyle = "Custom Hex"
            if S.ThemeColor == "Galaxy" then UI.applyThemeColor("Galaxy") end
            VH.Config.saveConfig()
            VH.Utils.notify("Galaxy background color updated!", Color3.fromRGB(50, 195, 75))
        end
    end)

    UI.addSectionHeader(pageUI, "Gradient & Angle Styling")
    local gradientStyles = {"Linear Gradient", "Glow Accent", "Solid Color", "Rainbow Animated"}
    UI.addDropdownOption(pageUI, "Theme Gradient Style", gradientStyles, table.find(gradientStyles, S.ThemeGradientStyle or "Linear Gradient") or 1, function(_, opt)
        S.ThemeGradientStyle = opt
        UI.applyThemeColor(S.ThemeColor)
        VH.Config.saveConfig()
    end)

    local gradientAngles = {"Horizontal (0°)", "Diagonal (45°)", "Vertical (90°)", "Reverse Diagonal (135°)"}
    UI.addDropdownOption(pageUI, "Theme Gradient Angle", gradientAngles, table.find(gradientAngles, S.ThemeGradientAngle or "Horizontal (0°)") or 1, function(_, opt)
        S.ThemeGradientAngle = opt
        UI.applyThemeColor(S.ThemeColor)
        VH.Config.saveConfig()
    end)

    UI.addSectionHeader(pageUI, "Custom Color Mode (Hex & RGB)")
    UI.addButtonOption(pageUI, "Enable Custom Color Mode", function()
        UI.applyThemeColor("Custom")
        VH.Config.saveConfig()
        VH.Utils.notify("Custom Theme Color mode active!", Color3.fromRGB(50, 195, 75))
    end)

    UI.addTextboxOption(pageUI, "Custom Hex Code (#RRGGBB)", S.CustomThemeHex or "#8D2FC4", function(hexText)
        local parsed = UI.parseHexColor(hexText)
        if parsed then
            S.CustomThemeHex = hexText
            if S.ThemeColor == "Custom" then
                UI.applyThemeColor("Custom")
                VH.Config.saveConfig()
                VH.Utils.notify("Custom Hex Theme Color applied!", Color3.fromRGB(50, 195, 75))
            else
                VH.Utils.notify("Custom Hex saved! Click 'Enable Custom Color Mode' to activate.", Color3.fromRGB(241, 196, 15))
            end
        else
            VH.Utils.notify("Invalid Hex code! Example format: #FF007F", Color3.fromRGB(218, 38, 38))
        end
    end)

    local initialCustomCol = UI.parseHexColor(S.CustomThemeHex) or Color3.fromRGB(141, 47, 196)
    UI.addSliderOption(pageUI, "Custom Red Channel (0-255)", 0, 255, math.round(initialCustomCol.R * 255), function(rVal)
        local cur = UI.parseHexColor(S.CustomThemeHex) or Color3.fromRGB(141, 47, 196)
        S.CustomThemeHex = string.format("#%02X%02X%02X", rVal, math.round(cur.G * 255), math.round(cur.B * 255))
        if S.ThemeColor == "Custom" then
            UI.applyThemeColor("Custom")
            VH.Config.saveConfig()
        end
    end)

    UI.addSliderOption(pageUI, "Custom Green Channel (0-255)", 0, 255, math.round(initialCustomCol.G * 255), function(gVal)
        local cur = UI.parseHexColor(S.CustomThemeHex) or Color3.fromRGB(141, 47, 196)
        S.CustomThemeHex = string.format("#%02X%02X%02X", math.round(cur.R * 255), gVal, math.round(cur.B * 255))
        if S.ThemeColor == "Custom" then
            UI.applyThemeColor("Custom")
            VH.Config.saveConfig()
        end
    end)

    UI.addSliderOption(pageUI, "Custom Blue Channel (0-255)", 0, 255, math.round(initialCustomCol.B * 255), function(bVal)
        local cur = UI.parseHexColor(S.CustomThemeHex) or Color3.fromRGB(141, 47, 196)
        S.CustomThemeHex = string.format("#%02X%02X%02X", math.round(cur.R * 255), math.round(cur.G * 255), bVal)
        if S.ThemeColor == "Custom" then
            UI.applyThemeColor("Custom")
            VH.Config.saveConfig()
        end
    end)

    UI.addSectionHeader(pageUI, "Text Animations & Font Sizing")
    local textAnimStyles = {"Static", "Jumping Gummy", "Wave", "Pulse"}
    UI.addDropdownOption(pageUI, "Module Text Animation", textAnimStyles, table.find(textAnimStyles, S.TextAnimationStyle or "Static") or 1, function(_, opt)
        S.TextAnimationStyle = opt
        VH.Config.saveConfig()
    end)

    local fontsList = {"Gotham", "GothamBold", "SourceSans", "SourceSansBold", "Roboto", "RobotoBold", "Ubuntu", "Arcade", "Code", "FredokaOne"}
    UI.addDropdownOption(pageUI, "Interface Font Style", fontsList, table.find(fontsList, S.UIFont or "Gotham") or 1, function(_, opt)
        UI.applyUIFont(opt)
        VH.Config.saveConfig()
        VH.Utils.notify("UI Font set to: " .. opt, Color3.fromRGB(50, 195, 75))
    end)

    UI.addSliderOption(pageUI, "UI Scale Sizing (%)", 70, 150, math.round((S.UIScale or 1.0) * 100), function(v)
        local scale = v / 100
        UI.applyUIScale(scale)
        VH.Config.saveConfig()
    end)

    UI.addKeybindOption(pageUI, "Menu Toggle Keybind", S.UIToggleKey or Enum.KeyCode.RightControl, function(k) S.UIToggleKey = k; VH.Config.saveConfig(); VH.Utils.notify("UI Toggle Keybind set to: " .. k.Name, Color3.fromRGB(50, 195, 75)) end)
    UI.addToggleOption(pageUI, "Show Toasts Enabled", S.ToastEnabled, function(v) S.ToastEnabled = v; VH.Config.saveConfig() end)

    UI.addSectionHeader(pageUI, "Visual Theme Reset")
    UI.addButtonOption(pageUI, "Reset Visual Theme Defaults", function()
        S.ThemeColor = "Galaxy"
        S.ThemeGradientStyle = "Linear Gradient"
        S.ThemeGradientAngle = "Horizontal (0°)"
        S.CustomThemeHex = "#8D2FC4"
        S.GalaxyBgStyle = "Deep Space (Black)"
        S.GalaxyCustomBgHex = "#080810"
        S.TextAnimationStyle = "Static"
        UI.applyThemeColor("Galaxy")
        VH.Config.saveConfig()
        VH.Utils.notify("Visual theme reset to Galaxy defaults!", Color3.fromRGB(218, 38, 38))
    end)

    UI.addSectionHeader(pageHUD, "Heads Up Display (HUD)")
    UI.addToggleOption(pageHUD, "Display Client Watermark", S.HUDWatermark, function(v) S.HUDWatermark = v; hudWatermark.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Player Coordinates", S.HUDCoords, function(v) S.HUDCoords = v; hudCoords.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Server Age HUD", S.ServerAgeHUD, function(v) S.ServerAgeHUD = v; hudServerAge.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Active ArrayList", S.HUDArrayList, function(v) S.HUDArrayList = v; UI.updateHUDArrayList(); VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display active mods when outside of the main UI", S.HUDArrayListOutside, function(v) S.HUDArrayListOutside = v; UI.updateHUDArrayList(); VH.Config.saveConfig() end)

    UI.addSectionHeader(pageInput, "Target Locker & Friends")
    UI.addTextboxOption(pageInput, "Specify Target / Friend", "Username", function(txt) if txt == "" then return end; VH.Utils.notify("Target lock set to: " .. txt, Color3.fromRGB(50, 195, 75)) end)
    UI.addButtonOption(pageInput, "Clear Current Friends Lists", function() VH.Utils.notify("Friends lists reset", Color3.fromRGB(218, 38, 38)) end)

    UI.addSectionHeader(pageInput, "Macros & Bindings")
    UI.addTextboxOption(pageInput, "Configure Macro Text", "Say something...", function(txt) S.MacroText = txt; VH.Config.saveConfig(); VH.Utils.notify("Macro text configured!", Color3.fromRGB(50, 195, 75)) end)
    UI.addKeybindOption(pageInput, "Trigger Macro Key", S.MacroKey or Enum.KeyCode.H, function(k) S.MacroKey = k; VH.Config.saveConfig(); VH.Utils.notify("Macro trigger set to: " .. k.Name, Color3.fromRGB(50, 195, 75)) end)
    UI.addKeybindOption(pageInput, "Panic Button (Disable All)", S.PanicKey or Enum.KeyCode.End, function(k) S.PanicKey = k; VH.Config.saveConfig(); VH.Utils.notify("Panic Key set to: " .. k.Name, Color3.fromRGB(218, 38, 38)) end)
    UI.addKeybindOption(pageInput, "Grab User ID (Hover Player)", S.UserIDGrabKey or Enum.KeyCode.K, function(k) S.UserIDGrabKey = k; VH.Config.saveConfig(); VH.Utils.notify("UserID Grab set to: " .. k.Name, Color3.fromRGB(50, 195, 75)) end)

    UI.addSectionHeader(pageConfig, "Executor Capabilities")
    local supportedFuncs = 0; local totalFuncs = 0
    local capsList = {
        {"setclipboard", setclipboard}, {"getgenv", getgenv}, {"Drawing.new", Drawing and Drawing.new},
        {"firetouchinterest", firetouchinterest}, {"fireclickdetector", fireclickdetector}, {"fireproximityprompt", fireproximityprompt},
        {"mouse1press", mouse1press}, {"getcustomasset", getcustomasset}, {"queue_on_teleport", queue_on_teleport or queueteleport}
    }
    for _, cap in ipairs(capsList) do totalFuncs = totalFuncs + 1; if cap[2] then supportedFuncs = supportedFuncs + 1 end end
    UI.addInfoRowOption(pageConfig, "Supported Functions", supportedFuncs .. " / " .. totalFuncs)
    UI.addInfoRowOption(pageConfig, "Executor Name", executorName)

    UI.addSectionHeader(pageConfig, "Saves & Client Controls")
    UI.addToggleOption(pageConfig, "Save Config Between Teleports", S.SaveConfigBetweenTeleports == true, function(v)
        S.SaveConfigBetweenTeleports = v
        VH.Config.saveConfig()
        UI.showToast(v and "Config will persist across teleports" or "Config will reset on teleport (Safest)", State.currentThemeColor)
    end)
    UI.addTextboxOption(pageConfig, "Configuration Name", "utility_hub_config", function(txt) end)
    UI.addButtonOption(pageConfig, "Save Current Settings", function() VH.Config.saveConfig(); VH.Utils.notify("Configuration saved successfully!", Color3.fromRGB(50, 195, 75)) end)
    UI.addButtonOption(pageConfig, "Load Stored Settings", function() VH.Config.loadConfig(); VH.Utils.notify("Configuration loaded successfully!", Color3.fromRGB(50, 195, 75)) end)
    UI.addButtonOption(pageConfig, "Reset Settings to Default", function()
        UI:ResetAllToggles()
        S.WalkSpeed = 16; S.JumpPower = 50; S.InfJump = false; S.BHop = false; S.AirWalk = false; S.NoClip = false; S.Fly = false; S.FlySpeed = 60; S.ESPBoxes = false; S.ESPTracers = false; S.ESPNames = false; S.ESPHealth = false; S.ESPDistances = false; S.ESPTeamCheck = false; S.ESPIgnoreFriends = false; S.LineOfSight = false; S.LineOfSightTeamCheck = false; S.LineOfSightFriendCheck = false; S.LineOfSightLength = 30; S.UltraInstinct = false; S.UltraInstinctRadius = 12; S.UltraInstinctTeamCheck = false; S.AimbotActive = false; S.AimbotIgnoreFriends = false; S.TriggerbotIgnoreFriends = false; S.AntiAFK = false; S.AutoRejoin = false; S.NetworkChat = true; S.NetworkTags = true; S.ShowNetworkUsersHUD = true; S.ShowNetworkHeadTags = true; S.GravityEnabled = false; S.CustomGravity = 196.2; S.ThemeColor = "Purple"
        if UI.moduleButtons["Network Chat Hub"] then UI.moduleButtons["Network Chat Hub"].SetActive(true) end
        if UI.moduleButtons["Network User Tags"] then UI.moduleButtons["Network User Tags"].SetActive(true) end
        UI.applyThemeColor("Purple"); VH.Config.saveConfig(); VH.Utils.notify("All settings reset to default!", Color3.fromRGB(218, 38, 38))
    end)
    UI.addButtonOption(pageConfig, "Destruct Client GUI Completely", function() VH.Cleanup.cleanupAll() end)

    UI.addSectionHeader(pageModules, "Module Disabler & Exclusion Mode")
    UI.addToggleOption(pageModules, "Enable Module Selection Mode", S.ModuleDisableMode, function(v)
        S.ModuleDisableMode = v
        if UI.updateDisableModeBtn then UI.updateDisableModeBtn() end
        UI.updateAllModuleVisuals()
        UI.showToast(v and "Module Selection Mode Enabled (Click non-Misc modules to disable)" or "Module Selection Mode Disabled", v and Color3.fromRGB(241, 196, 15) or State.currentThemeColor)
    end)

    local styleBtn = nil
    styleBtn = UI.addButtonOption(pageModules, "Disabled Style: " .. (S.DisabledModuleStyle or "Greyish") .. " (Click to Switch)", function()
        if S.DisabledModuleStyle == "Invisible" then
            S.DisabledModuleStyle = "Greyish"
        else
            S.DisabledModuleStyle = "Invisible"
        end
        if styleBtn and styleBtn.SetText then
            styleBtn.SetText("Disabled Style: " .. S.DisabledModuleStyle .. " (Click to Switch)")
        end
        VH.Config.saveConfig()
        UI.updateAllModuleVisuals()
        UI.showToast("Disabled modules style set to: " .. S.DisabledModuleStyle, State.currentThemeColor)
    end)

    UI.addButtonOption(pageModules, "Revert All Disabled Modules", function()
        UI.revertAllDisabled()
    end)

    UI.addSectionHeader(pageModules, "Disabled Modules List")

    local disabledListContainer = Instance.new("Frame")
    disabledListContainer.Name = "DisabledListContainer"
    disabledListContainer.Size = UDim2.new(1, 0, 0, 0)
    disabledListContainer.AutomaticSize = Enum.AutomaticSize.Y
    disabledListContainer.BackgroundTransparency = 1
    disabledListContainer.Parent = pageModules

    local dListLayout = Instance.new("UIListLayout")
    dListLayout.Padding = UDim.new(0, 2)
    dListLayout.Parent = disabledListContainer

    local function refreshDisabledList()
        for _, ch in ipairs(disabledListContainer:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        local sortedList = {}
        if S.DisabledModules then
            for modName, disabled in pairs(S.DisabledModules) do
                if disabled and (not UI.moduleCategories or UI.moduleCategories[modName] ~= "Misc") then
                    table.insert(sortedList, modName)
                end
            end
        end
        table.sort(sortedList)

        if #sortedList == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 22)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextSize = 10
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.Text = "No modules are currently disabled."
            emptyLabel.Parent = disabledListContainer
        else
            for _, modName in ipairs(sortedList) do
                local cat = (UI.moduleCategories and UI.moduleCategories[modName]) or "Module"
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
                row.BorderSizePixel = 0
                row.Parent = disabledListContainer

                local rCorner = Instance.new("UICorner")
                rCorner.CornerRadius = UDim.new(0, 4)
                rCorner.Parent = row

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -70, 1, 0)
                lbl.Position = UDim2.new(0, 6, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 10
                lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Text = "[" .. cat .. "] " .. modName
                lbl.Parent = row

                local revBtn = Instance.new("TextButton")
                revBtn.Size = UDim2.new(0, 58, 0, 16)
                revBtn.Position = UDim2.new(1, -62, 0.5, -8)
                revBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
                revBtn.BorderSizePixel = 0
                revBtn.Font = Enum.Font.GothamBold
                revBtn.TextSize = 9
                revBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                revBtn.Text = "Re-enable"
                revBtn.Parent = row

                local revCorner = Instance.new("UICorner")
                revCorner.CornerRadius = UDim.new(0, 3)
                revCorner.Parent = revBtn

                revBtn.Activated:Connect(function()
                    UI.setModuleDisabled(modName, false)
                    UI.showToast("Re-enabled: " .. modName, Color3.fromRGB(46, 204, 113))
                    refreshDisabledList()
                end)
            end
        end
    end
    UI.refreshDisabledModulesList = refreshDisabledList
    refreshDisabledList()

    navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(0, 600, 1, 0)
    navBar.Position = UDim2.new(0.5, -300, 0, 0)
    navBar.BackgroundTransparency = 1
    navBar.ZIndex = 5
    navBar.Parent = topBar

    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    navLayout.Padding = UDim.new(0, 16)
    navLayout.Parent = navBar

    navBar.Size = UDim2.new(0, 560, 1, 0)
    navBar.Position = UDim2.new(0.5, -280, 0, 0)

    local tabs = {"Modules", "Settings", "(Chat)", "Binds"}
    for _, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 68, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.TextColor3 = (tabName == activeTab) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 210, 210)
        if tabName == activeTab then btn.Font = Enum.Font.GothamBold end
        btn.Text = tabName
        btn.ZIndex = 5
        btn.Parent = navBar
        btn.MouseEnter:Connect(function() if activeTab ~= tabName then btn.TextColor3 = State.currentThemeColor end end)
        btn.MouseLeave:Connect(function() if activeTab ~= tabName then btn.TextColor3 = Color3.fromRGB(210, 210, 210) end end)
        btn.MouseButton1Click:Connect(function() selectTab(tabName) end)
        UI.tabButtons[tabName] = btn
    end

    local disableModeBtn = Instance.new("TextButton")
    disableModeBtn.Size = UDim2.new(0, 105, 0, 16)
    disableModeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    disableModeBtn.BorderSizePixel = 0
    disableModeBtn.Font = Enum.Font.Gotham
    disableModeBtn.TextSize = 9
    disableModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    disableModeBtn.Text = "Disable Mode: OFF"
    disableModeBtn.ZIndex = 5
    disableModeBtn.Parent = navBar

    local disCorner = Instance.new("UICorner")
    disCorner.CornerRadius = UDim.new(0, 4)
    disCorner.Parent = disableModeBtn

    local disStroke = Instance.new("UIStroke")
    disStroke.Color = Color3.fromRGB(45, 45, 45)
    disStroke.Thickness = 1
    disStroke.Parent = disableModeBtn

    local function updateDisableModeBtn()
        local on = (State.S.ModuleDisableMode == true)
        disableModeBtn.Text = on and "Disable Mode: ON" or "Disable Mode: OFF"
        disableModeBtn.BackgroundColor3 = on and Color3.fromRGB(180, 80, 30) or Color3.fromRGB(35, 35, 35)
        disableModeBtn.TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        disStroke.Color = on and Color3.fromRGB(220, 100, 40) or Color3.fromRGB(45, 45, 45)
    end
    disableModeBtn.Activated:Connect(function()
        State.S.ModuleDisableMode = not State.S.ModuleDisableMode
        updateDisableModeBtn()
        UI.updateAllModuleVisuals()
        if State.S.ModuleDisableMode then
            if not State.S.DisableModeWarningShown then
                State.S.DisableModeWarningShown = true
                VH.Config.saveConfig()
                UI.showToast("Disable Mode hides disabled modules by default! Revert by clicking Disable Mode, or in Settings enable Faded style.", Color3.fromRGB(241, 196, 15))
            else
                UI.showToast("Module Selection Mode Enabled (Click non-Misc modules to disable)", Color3.fromRGB(241, 196, 15))
            end
        else
            UI.showToast("Module Selection Mode Disabled", State.currentThemeColor)
        end
    end)
    UI.updateDisableModeBtn = updateDisableModeBtn
    updateDisableModeBtn()

    searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(0, 110, 0, 16)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 9
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    searchBox.PlaceholderText = "Search..."
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 5
    searchBox.Parent = navBar

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 4)
    searchCorner.Parent = searchBox

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = Color3.fromRGB(45, 45, 45)
    searchStroke.Thickness = 1
    searchStroke.Parent = searchBox

    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 6)
    searchPadding.PaddingRight = UDim.new(0, 6)
    searchPadding.Parent = searchBox

    searchBox.Focused:Connect(function()
        Services.TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = State.currentThemeColor}):Play()
    end)
    searchBox.FocusLost:Connect(function()
        Services.TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 45)}):Play()
    end)

    local function filterModules(query)
        query = query:lower()
        for _, win in pairs(UI.windows) do
            local hasVisibleModule = false
            for _, child in ipairs(win.List:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1, 4) == "Mod_" then
                    local modName = child.Name:sub(5)
                    local isDisabled = UI.isModuleDisabled(modName)
                    local isSelectMode = (State.S.ModuleDisableMode == true)
                    local style = State.S.DisabledModuleStyle or "Greyish"
                    local hiddenByDisable = (isDisabled and style == "Invisible" and not isSelectMode)
                    local matches = (query == "") or (modName:lower():find(query, 1, true) ~= nil)
                    child.Visible = matches and not hiddenByDisable
                    if child.Visible then
                        hasVisibleModule = true
                    end
                end
            end
            win.Frame.Visible = (activeTab == "Modules") and (query == "" or hasVisibleModule)
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if searchBox.Text ~= "" and activeTab ~= "Modules" then
            selectTab("Modules")
        end
        filterModules(searchBox.Text)
    end)

    catPositions = { ["Combat"] = 20, ["Player"] = 210, ["Movement"] = 400, ["Render"] = 590, ["World"] = 780, ["Misc"] = 970, ["Search"] = 1160 }

    selectTab("Modules")
    UI.applyThemeColor(S.ThemeColor or "Galaxy")
    UI.applyUIFont(S.UIFont or "Gotham")
    UI.applyUIScale(S.UIScale or 1.0)

    UI.hudWatermark = hudWatermark
    UI.hudCoords = hudCoords
    UI.hudServerAge = hudServerAge
    UI.hudArrayListFrame = hudArrayListFrame
    UI.themeToggles = themeToggles
    UI.themeHeaders = themeHeaders
    UI.themeFills = themeFills
    UI.themeTexts = themeTexts

    local function runWelcomeToasts()
        task.spawn(function()
            task.wait(1.5)
            local visited = false
            if isfile and readfile then
                visited = isfile("utility_hub_visited.txt")
            end
            if not visited then
                if writefile then
                    pcall(function() writefile("utility_hub_visited.txt", "true") end)
                end
                UI.showToast("Welcome to WASOR 4.5!", State.currentThemeColor)
                task.wait(2.2)
                UI.showToast("Toggle UI with [Right Control]", State.currentThemeColor)
                task.wait(2.2)
                UI.showToast("Configure settings in the Settings tab", State.currentThemeColor)
                task.wait(2.2)
                UI.showToast("Press [End] to Panic (disable all)", Color3.fromRGB(218, 38, 38))
            end
        end)
    end

    if S.EulaAccepted == true then
        runWelcomeToasts()
    else
        mainUIContainer.Visible = false
        hudWatermark.Visible = false
        hudCoords.Visible = false
        hudServerAge.Visible = false
        hudArrayListFrame.Visible = false

        local eulaFrame = Instance.new("Frame")
        eulaFrame.Name = "EulaFrame"
        eulaFrame.Size = UDim2.new(0, 360, 0, 240)
        eulaFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        eulaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        eulaFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        eulaFrame.BorderSizePixel = 0
        eulaFrame.Parent = screenGui

        local eulaCorner = Instance.new("UICorner")
        eulaCorner.CornerRadius = UDim.new(0, 6)
        eulaCorner.Parent = eulaFrame

        local eulaStroke = Instance.new("UIStroke")
        eulaStroke.Color = Color3.fromRGB(45, 45, 45)
        eulaStroke.Thickness = 1.2
        eulaStroke.Parent = eulaFrame

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 24)
        header.BackgroundColor3 = State.currentThemeColor
        header.BorderSizePixel = 0
        header.Parent = eulaFrame
        table.insert(themeHeaders, header)

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 6)
        headerCorner.Parent = header

        local headerHide = Instance.new("Frame")
        headerHide.Size = UDim2.new(1, 0, 0, 6)
        headerHide.Position = UDim2.new(0, 0, 1, -6)
        headerHide.BackgroundColor3 = State.currentThemeColor
        headerHide.BorderSizePixel = 0
        headerHide.Parent = header
        table.insert(themeFills, headerHide)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -20, 1, 0)
        titleLbl.Position = UDim2.new(0, 10, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 10
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Text = "WASOR - EULA"
        titleLbl.Parent = header

        local textLbl = Instance.new("TextLabel")
        textLbl.Size = UDim2.new(1, -24, 0, 130)
        textLbl.Position = UDim2.new(0, 12, 0, 36)
        textLbl.BackgroundTransparency = 1
        textLbl.Font = Enum.Font.GothamMedium
        textLbl.TextSize = 10
        textLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        textLbl.TextXAlignment = Enum.TextXAlignment.Left
        textLbl.TextYAlignment = Enum.TextYAlignment.Top
        textLbl.TextWrapped = true
        textLbl.RichText = true
        textLbl.Text = "This script may ban in games that have strict anti cheats towards unallowed services before injecting to a new game. saving it always after the use decision.\n\nBy agreeing to this you will be connected to a SUPABASE database whenever you use the script for client detection and more😨, If it seems to evasive you can fork the repository and remove it. This was mean't to be a friends-only project so this is why the evasive features so beware we have access to remote execution, The script is fully open source and not obfuscated."
        textLbl.Parent = eulaFrame

        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Size = UDim2.new(1, -24, 0, 32)
        buttonsFrame.Position = UDim2.new(0, 12, 1, -44)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.Parent = eulaFrame

        local function createButton(name, xPosition, bgColor, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.48, 0, 1, 0)
            btn.Position = xPosition
            btn.BackgroundColor3 = bgColor
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name
            btn.Parent = buttonsFrame

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Transparency = 0.85
            stroke.Parent = btn

            btn.MouseEnter:Connect(function()
                Services.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(math.clamp(bgColor.R*255 + 20, 0, 255), math.clamp(bgColor.G*255 + 20, 0, 255), math.clamp(bgColor.B*255 + 20, 0, 255))}):Play()
            end)
            btn.MouseLeave:Connect(function()
                Services.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgColor}):Play()
            end)

            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        local function agreeCallback()
            S.EulaAccepted = true
            VH.Config.saveConfig()
            eulaFrame:Destroy()
            mainUIContainer.Visible = true
            hudWatermark.Visible = S.HUDWatermark
            hudCoords.Visible = S.HUDCoords
            hudServerAge.Visible = S.ServerAgeHUD

            if VH.runNetworkTagsSync then
                pcall(VH.runNetworkTagsSync)
            end

            runWelcomeToasts()
        end

        local function declineCallback()
            S.EulaAccepted = false
            VH.Config.saveConfig()
            VH.Cleanup.cleanupAll()
        end

        createButton("Agree", UDim2.new(0, 0, 0, 0), Color3.fromRGB(46, 204, 113), agreeCallback)
        createButton("Decline", UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(218, 38, 38), declineCallback)

        makeDraggable(eulaFrame, header)
    end
end

UI.updateNetworkUsersHUD = function(activeInServer)
    if not UI.networkUsersHUD then return end
    for _, child in ipairs(UI.networkUsersHUD:GetChildren()) do
        if child:IsA("TextLabel") and child ~= UI.netHeader then
            child:Destroy()
        end
    end

    local userCount = 0
    for username, userData in pairs(activeInServer) do
        userCount = userCount + 1
        local p = Services.Players:FindFirstChild(username)
        local dispName = p and p.DisplayName or username
        local executor = userData.executor or "Unknown"
        local is_admin = userData.is_admin

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 9
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local roleColor = is_admin and "#ffeb3b" or "#9ba3af"
        local nameText = is_admin and " " .. dispName or dispName
        lbl.Text = string.format("%s <font color='%s'>[%s]</font>", nameText, roleColor, executor)
        lbl.RichText = true
        lbl.Parent = UI.networkUsersHUD
    end

    UI.netHeader.Text = string.format("Network Users (%d)", userCount)

    if userCount == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 9
        lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "No other users found"
        lbl.Parent = UI.networkUsersHUD
    end
end

UI.GetScreenGui = function() return screenGui end
UI.GetMainContainer = function() return mainUIContainer end

VH.UI = UI
return UI
