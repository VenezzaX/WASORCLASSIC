local VH = _G.VoidHub
local UI = {}

local Services = VH.Services
local State = VH.State

UI.tabButtons = {}
UI.windows = {}
UI.moduleButtons = {}
UI.floatingWindows = {}

local StudioTheme = {
    windowBg       = Color3.fromRGB(37, 37, 38),
    headerBg       = Color3.fromRGB(45, 45, 48),
    headerHover    = Color3.fromRGB(55, 55, 60),
    panelBg        = Color3.fromRGB(42, 42, 45),
    panelAlt       = Color3.fromRGB(32, 32, 34),
    insetBg        = Color3.fromRGB(26, 26, 28),
    categoryBg     = Color3.fromRGB(50, 50, 54),
    border         = Color3.fromRGB(20, 20, 22),
    borderSubtle   = Color3.fromRGB(55, 55, 58),
    text           = Color3.fromRGB(225, 225, 228),
    textMuted      = Color3.fromRGB(160, 160, 165),
    textDim        = Color3.fromRGB(115, 115, 120),
    blue           = Color3.fromRGB(0, 122, 204),
    blueHover      = Color3.fromRGB(28, 140, 224),
    green          = Color3.fromRGB(76, 175, 80),
    greenHover     = Color3.fromRGB(92, 195, 96),
    red            = Color3.fromRGB(215, 60, 60),
    redHover       = Color3.fromRGB(235, 75, 75),
    yellow         = Color3.fromRGB(220, 170, 50),
    btnBg          = Color3.fromRGB(50, 50, 54),
    btnHover       = Color3.fromRGB(65, 65, 70),
}

UI.themeColors = {
    ["Studio Classic"] = StudioTheme.blue
}

local activeTab = "Modules"
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

local function getGuiContainers()
    local containers = {}
    pcall(function()
        if gethui then
            local h = gethui()
            if h and not table.find(containers, h) then table.insert(containers, h) end
        end
        if get_hidden_gui then
            local hg = get_hidden_gui()
            if hg and not table.find(containers, hg) then table.insert(containers, hg) end
        end
        if Services.CoreGui and not table.find(containers, Services.CoreGui) then
            table.insert(containers, Services.CoreGui)
        end
        if Services.LP then
            local pg = Services.LP:FindFirstChild("PlayerGui")
            if pg and not table.find(containers, pg) then table.insert(containers, pg) end
        end
    end)
    return containers
end

local function getGuiParent()
    local success, core = pcall(function()
        return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or game:GetService("CoreGui")
    end)
    if success and core then
        return core
    end
    return Services.LP:WaitForChild("PlayerGui")
end

local function setButtonState(btn, bg, fg)
    if btn and btn.Parent then
        btn.BackgroundColor3 = bg
        if fg then btn.TextColor3 = fg end
    end
end

local function addDesktopHover(btn, normalBg, hoverBg, normalFg, hoverFg)
    btn.MouseEnter:Connect(function()
        setButtonState(btn, hoverBg, hoverFg or StudioTheme.text)
    end)
    btn.MouseLeave:Connect(function()
        setButtonState(btn, normalBg, normalFg or StudioTheme.text)
    end)
end

local function makeStudioButton(parent, text, w, h, bg, fg, font, textSize)
    local b = Instance.new("TextButton")
    b.Size = typeof(w) == "UDim2" and w or UDim2.new(0, w, 0, h or 22)
    b.BackgroundColor3 = bg or StudioTheme.btnBg
    b.Text = text or ""
    b.TextColor3 = fg or StudioTheme.text
    b.TextSize = textSize or 12
    b.Font = font or Enum.Font.SourceSansSemibold
    b.AutoButtonColor = false
    b.BorderSizePixel = 1
    b.BorderColor3 = StudioTheme.border
    b.ClipsDescendants = true
    b.Parent = parent

    local defaultBg = bg or StudioTheme.btnBg
    local hoverBg = (bg == StudioTheme.blue and StudioTheme.blueHover)
        or (bg == StudioTheme.red and StudioTheme.redHover)
        or (bg == StudioTheme.green and StudioTheme.greenHover)
        or StudioTheme.btnHover
    addDesktopHover(b, defaultBg, hoverBg, fg or StudioTheme.text, fg or StudioTheme.text)

    return b
end

local function makeStudioTextBox(parent, text, width, height, placeholder, fontCode)
    local box = Instance.new("TextBox")
    box.Size = typeof(width) == "UDim2" and width or UDim2.new(0, width or 70, 0, height or 20)
    box.BackgroundColor3 = StudioTheme.insetBg
    box.Text = text or ""
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = StudioTheme.textDim
    box.TextColor3 = StudioTheme.text
    box.TextSize = 12
    box.Font = fontCode and Enum.Font.Code or Enum.Font.SourceSans
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 1
    box.BorderColor3 = StudioTheme.border
    box.Parent = parent
    return box
end

UI.showToast = function(message, color)
    local S = State.S
    if not S.ToastEnabled then return end
    if not toastContainer then return end
    
    local toastColor = color or StudioTheme.blue
    
    local existing = nil
    for _, t in ipairs(activeToasts) do
        if t.message == message then
            existing = t
            break
        end
    end
    
    if existing then
        existing.count = existing.count + 1
        existing.label.Text = message .. " (x" .. existing.count .. ")"
        existing.createdTime = tick()
        
        if existing.tween then
            existing.tween:Cancel()
        end
        existing.progressBar.Size = UDim2.new(1, -2, 0, 2)
        
        local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Linear)
        existing.tween = Services.TweenService:Create(existing.progressBar, tweenInfo, {Size = UDim2.new(0, 0, 0, 2)})
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
            pcall(function() existing.frame:Destroy() end)
        end)
        return
    end
    
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 36)
    toast.BackgroundColor3 = StudioTheme.windowBg
    toast.BorderSizePixel = 1
    toast.BorderColor3 = StudioTheme.border
    toast.ClipsDescendants = true
    toast.Parent = toastContainer
    toast:SetAttribute("CreatedTime", tick())
    
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 3, 1, 0)
    stripe.Position = UDim2.new(0, 0, 0, 0)
    stripe.BackgroundColor3 = toastColor
    stripe.BorderSizePixel = 0
    stripe.Parent = toast
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, -4)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSansSemibold
    lbl.TextSize = 12
    lbl.TextColor3 = StudioTheme.text
    lbl.Text = message
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, -2, 0, 2)
    progressBar.Position = UDim2.new(0, 1, 1, -3)
    progressBar.BackgroundColor3 = toastColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = toast
    
    local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Linear)
    local pTween = Services.TweenService:Create(progressBar, tweenInfo, {Size = UDim2.new(0, 0, 0, 2)})
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
        pcall(function() toast:Destroy() end)
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
    for _, child in ipairs(hudArrayListFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    local S = State.S
    local isVisible = S.HUDArrayList
    if not State.uiVisible then isVisible = S.HUDArrayList and S.HUDArrayListOutside end
    if not isVisible then
        hudArrayListFrame.Visible = false
        return
    end
    
    local activeMods = {}
    for modName, item in pairs(UI.moduleButtons) do
        if item.IsActive and item.IsActive() then
            table.insert(activeMods, modName)
        end
    end
    table.sort(activeMods, function(a, b) return #a > #b end)
    
    if #activeMods == 0 then
        hudArrayListFrame.Visible = false
    else
        hudArrayListFrame.Visible = isVisible
        for _, modName in ipairs(activeMods) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundColor3 = StudioTheme.windowBg
            row.BorderSizePixel = 1
            row.BorderColor3 = StudioTheme.border
            row.Parent = hudArrayListFrame

            local stripe = Instance.new("Frame")
            stripe.Size = UDim2.new(0, 3, 1, 0)
            stripe.BackgroundColor3 = StudioTheme.blue
            stripe.BorderSizePixel = 0
            stripe.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -8, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = 12
            lbl.TextColor3 = StudioTheme.blue
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = modName
            lbl.Parent = row
        end
    end
end

UI.applyUIFont = function() end

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

UI.applyThemeColor = function()
    State.currentThemeColor = StudioTheme.blue
    State.currentThemeGradientColor = StudioTheme.blue
end

UI.updateMenuBlur = function()
    if not menuBlur then return end
    if not State.uiVisible then
        Services.TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 0}):Play()
        task.delay(0.25, function() if not State.uiVisible then menuBlur.Enabled = false end end)
        return
    end
    if activeTab == "Settings" then
        menuBlur.Enabled = true
        Services.TweenService:Create(menuBlur, TweenInfo.new(0.25), {Size = 14}):Play()
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

local function makeDraggable(frame, handle, onDragEnd)
    local dragging = false
    local dragStart = Vector3.zero
    local startPos = UDim2.new()
    
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
            local scaleFactor = getScale()
            
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

local function makeResizable(frame, handle)
    local resizing = false
    local resizeStart = Vector3.zero
    local startSize = UDim2.new()
    
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
            local scaleFactor = getScale()
            
            if moveConn then moveConn:Disconnect(); moveConn = nil end
            if endConn then endConn:Disconnect(); endConn = nil end
            
            moveConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
                if resizing and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - resizeStart
                    local dx = delta.X / scaleFactor
                    local dy = delta.Y / scaleFactor
                    local newWidth = math.max(160, startSize.X.Offset + dx)
                    local newHeight = math.max(60, startSize.Y.Offset + dy)
                    frame.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end)
            
            endConn = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    resizing = false
                    if moveConn then moveConn:Disconnect(); moveConn = nil end
                    if endConn then endConn:Disconnect(); endConn = nil end
                end
            end)
        end
    end)
end

local function adjustWindowSizeToContent(winFrame, contentFrame)
    if winFrame == settingsPanel then return end
    local totalContentHeight, count = 0, 0
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "resizeHandle" then
            local baseH = child:GetAttribute("BaseSize") and child:GetAttribute("BaseSize").Y.Offset or child.Size.Y.Offset
            totalContentHeight = totalContentHeight + baseH
            count = count + 1
        end
    end
    local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
    local paddingVal = listLayout and listLayout.Padding.Offset or 4
    local uiPadding = contentFrame:FindFirstChildOfClass("UIPadding")
    local padT = uiPadding and uiPadding.PaddingTop.Offset or 6
    local padB = uiPadding and uiPadding.PaddingBottom.Offset or 6
    local contentHeight = padT + padB + totalContentHeight + math.max(0, count - 1) * paddingVal
    local finalHeight = math.clamp(24 + contentHeight, 50, 420)
    local width = winFrame.Size.X.Offset
    winFrame.Size = UDim2.new(0, width, 0, finalHeight)
    winFrame:SetAttribute("BaseWidth", width)
    winFrame:SetAttribute("BaseHeight", finalHeight)
end

UI.addToggleOption = function(parent, name, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -54, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 12
    label.TextColor3 = StudioTheme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local btn = makeStudioButton(row, defaultVal and "ON" or "OFF", 42, 18, defaultVal and StudioTheme.green or StudioTheme.btnBg, defaultVal and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted, Enum.Font.SourceSansBold, 11)
    btn.Position = UDim2.new(1, -48, 0.5, -9)
    
    local active = defaultVal
    local function updateToggle()
        btn.Text = active and "ON" or "OFF"
        setButtonState(btn, active and StudioTheme.green or StudioTheme.btnBg, active and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted)
    end
    
    btn.Activated:Connect(function()
        active = not active
        updateToggle()
        if callback then callback(active) end
    end)
    
    return { Set = function(val) active = val; updateToggle() end }
end

UI.addSliderOption = function(parent, name, min, max, defaultVal, callback, defaultDotVal)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.68, -4, 0, 16)
    label.Position = UDim2.new(0, 6, 0, 3)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 12
    label.TextColor3 = StudioTheme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.32, -8, 0, 16)
    valLabel.Position = UDim2.new(0.68, 0, 0, 3)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.Code
    valLabel.TextSize = 11
    valLabel.TextColor3 = StudioTheme.text
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = formatVal(defaultVal)
    valLabel.Parent = row
    
    local slideBg = Instance.new("Frame")
    slideBg.Size = UDim2.new(1, -12, 0, 8)
    slideBg.Position = UDim2.new(0, 6, 0, 22)
    slideBg.BackgroundColor3 = StudioTheme.insetBg
    slideBg.BorderSizePixel = 1
    slideBg.BorderColor3 = StudioTheme.border
    slideBg.Parent = row
    
    local startPct = math.clamp((defaultVal - min) / (max - min), 0, 1)
    local slideFill = Instance.new("Frame")
    slideFill.Size = UDim2.new(startPct, 0, 1, 0)
    slideFill.BackgroundColor3 = StudioTheme.blue
    slideFill.BorderSizePixel = 0
    slideFill.Parent = slideBg
    
    local dotMarker = nil
    if defaultDotVal and defaultDotVal >= min and defaultDotVal <= max then
        local dotPct = math.clamp((defaultDotVal - min) / (max - min), 0, 1)
        dotMarker = Instance.new("Frame")
        dotMarker.Name = "DefaultDotMarker"
        dotMarker.Size = UDim2.new(0, 4, 1, 2)
        dotMarker.Position = UDim2.new(dotPct, -2, 0, -1)
        dotMarker.BackgroundColor3 = StudioTheme.yellow
        dotMarker.BorderSizePixel = 0
        dotMarker.ZIndex = 4
        dotMarker.Parent = slideBg
    end

    local slideBtn = Instance.new("TextButton")
    slideBtn.Size = UDim2.new(1, 0, 1, 0)
    slideBtn.BackgroundTransparency = 1
    slideBtn.Text = ""
    slideBtn.Parent = slideBg
    
    local function updateSlider(input)
        local sizeX = slideBg.AbsoluteSize.X
        if sizeX <= 0 then sizeX = 140 end
        local posX = input.Position.X - slideBg.AbsolutePosition.X
        local pct = math.clamp(posX / sizeX, 0, 1)
        slideFill.Size = UDim2.new(pct, 0, 1, 0)
        local val = math.floor(min + (max - min) * pct + 0.5)
        valLabel.Text = tostring(val)
        if callback then callback(val) end
    end
    
    local dragging = false
    slideBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    slideBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    local moveCon = Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    table.insert(State.S.Connections, moveCon)
    
    return {
        Set = function(val)
            local pct = math.clamp((val - min) / (max - min), 0, 1)
            slideFill.Size = UDim2.new(pct, 0, 1, 0)
            valLabel.Text = formatVal(val)
        end,
        SetDefaultDot = function(dotVal)
            if dotVal and slideBg then
                local dotPct = math.clamp((dotVal - min) / (max - min), 0, 1)
                if not dotMarker then
                    dotMarker = Instance.new("Frame")
                    dotMarker.Name = "DefaultDotMarker"
                    dotMarker.Size = UDim2.new(0, 4, 1, 2)
                    dotMarker.BackgroundColor3 = StudioTheme.yellow
                    dotMarker.BorderSizePixel = 0
                    dotMarker.ZIndex = 4
                    dotMarker.Parent = slideBg
                end
                dotMarker.Position = UDim2.new(dotPct, -2, 0, -1)
            end
        end
    }
end

UI.addDropdownOption = function(parent, name, optionsList, defaultValIndex, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, 14)
    label.Position = UDim2.new(0, 6, 0, 3)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextColor3 = StudioTheme.textMuted
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local dropBtn = makeStudioButton(row, "  " .. (optionsList[defaultValIndex] or "(none)") .. "  v", UDim2.new(1, -12, 0, 18), 18, StudioTheme.btnBg, StudioTheme.text, Enum.Font.SourceSansSemibold, 11)
    dropBtn.Position = UDim2.new(0, 6, 0, 18)
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    
    local open = false
    local listContainer = nil
    
    local function toggleDropdown()
        open = not open
        if open then
            listContainer = Instance.new("Frame")
            listContainer.Size = UDim2.new(1, 0, 0, #optionsList * 20)
            listContainer.Position = UDim2.new(0, 0, 1, 1)
            listContainer.BackgroundColor3 = StudioTheme.windowBg
            listContainer.BorderSizePixel = 1
            listContainer.BorderColor3 = StudioTheme.border
            listContainer.ZIndex = 30
            listContainer.Parent = dropBtn
            
            local layout = Instance.new("UIListLayout")
            layout.Parent = listContainer
            
            for i, opt in ipairs(optionsList) do
                local itemBtn = makeStudioButton(listContainer, "  " .. opt, UDim2.new(1, 0, 0, 20), 20, StudioTheme.windowBg, StudioTheme.text, Enum.Font.SourceSans, 11)
                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                itemBtn.ZIndex = 31
                itemBtn.Activated:Connect(function()
                    dropBtn.Text = "  " .. opt .. "  v"
                    if callback then callback(i, opt) end
                    toggleDropdown()
                end)
            end
            row.Size = UDim2.new(1, 0, 0, 40 + #optionsList * 20)
        else
            if listContainer then
                listContainer:Destroy()
                listContainer = nil
            end
            row.Size = UDim2.new(1, 0, 0, 40)
        end
    end
    dropBtn.Activated:Connect(toggleDropdown)
    
    return {
        Set = function(valText) dropBtn.Text = "  " .. valText .. "  v" end,
        SetOptions = function(newList)
            optionsList = newList
            if open then toggleDropdown(); toggleDropdown() end
        end
    }
end

local keybindRegistry = {}
UI.addKeybindOption = function(parent, name, defaultKey, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 12
    label.TextColor3 = StudioTheme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local keyName = (defaultKey and defaultKey ~= Enum.KeyCode.Unknown) and defaultKey.Name or "[ None ]"
    local bindBtn = makeStudioButton(row, keyName, 80, 18, StudioTheme.btnBg, StudioTheme.text, Enum.Font.Code, 11)
    bindBtn.Position = UDim2.new(1, -84, 0.5, -9)
    
    local currentKey = defaultKey
    local listening = false
    
    local optObj = {
        GetKey = function() return currentKey end,
        SetKey = function(key)
            currentKey = key
            bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[ None ]"
        end,
        Set = function(key)
            currentKey = key
            bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[ None ]"
        end,
        Callback = callback
    }
    keybindRegistry[name] = optObj
    
    bindBtn.Activated:Connect(function()
        listening = true
        bindBtn.Text = "[ ... ]"
        bindBtn.TextColor3 = StudioTheme.yellow
    end)
    
    local con = Services.UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.Escape then
                    listening = false
                    bindBtn.Text = (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "[ None ]"
                    bindBtn.TextColor3 = StudioTheme.text
                    return
                elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
                    listening = false
                    currentKey = Enum.KeyCode.Unknown
                    bindBtn.Text = "[ None ]"
                    bindBtn.TextColor3 = StudioTheme.text
                    if callback then callback(Enum.KeyCode.Unknown) end
                    return
                end
                if Services.UserInputService:GetFocusedTextBox() then return end
                listening = false
                currentKey = key
                bindBtn.Text = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "[ None ]"
                bindBtn.TextColor3 = StudioTheme.text
                if key ~= Enum.KeyCode.Unknown then
                    for otherName, otherBind in pairs(keybindRegistry) do
                        if otherName ~= name and otherBind.GetKey() == key then
                            otherBind.SetKey(Enum.KeyCode.Unknown)
                            if otherBind.Callback then otherBind.Callback(Enum.KeyCode.Unknown) end
                        end
                    end
                end
                if callback then callback(key) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                task.wait(0.05)
                if listening then
                    listening = false
                    bindBtn.Text = (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "[ None ]"
                    bindBtn.TextColor3 = StudioTheme.text
                end
            end
        end
    end)
    table.insert(State.S.Connections, con)
    return optObj
end

UI.addTextboxOption = function(parent, name, placeholder, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, 14)
    label.Position = UDim2.new(0, 6, 0, 3)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextColor3 = StudioTheme.textMuted
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local box = makeStudioTextBox(row, "", UDim2.new(1, -12, 0, 18), 18, placeholder, false)
    box.Position = UDim2.new(0, 6, 0, 18)
    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
    
    return { Set = function(valText) box.Text = valText end }
end

UI.addButtonOption = function(parent, name, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local btn = makeStudioButton(row, name, UDim2.new(1, -12, 0, 20), 20, StudioTheme.btnBg, StudioTheme.text, Enum.Font.SourceSansSemibold, 12)
    btn.Position = UDim2.new(0, 6, 0.5, -10)
    btn.Activated:Connect(function()
        if callback then callback() end
    end)
end

UI.addSectionHeader = function(parent, title)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundColor3 = StudioTheme.categoryBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -12, 1, 0)
    text.Position = UDim2.new(0, 6, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.SourceSansBold
    text.TextSize = 11
    text.TextColor3 = StudioTheme.text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = "v " .. title
    text.Parent = row
end

UI.addInfoRowOption = function(parent, name, initialValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundColor3 = StudioTheme.panelBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, -6, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextColor3 = StudioTheme.textMuted
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = row
    
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.45, -6, 1, 0)
    valLabel.Position = UDim2.new(0.55, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.Code
    valLabel.TextSize = 11
    valLabel.TextColor3 = StudioTheme.text
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = tostring(initialValue or "")
    valLabel.Parent = row
    
    return {
        Label = valLabel,
        SetValue = function(self, val) valLabel.Text = tostring(val) end,
        SetColor = function(self, color) valLabel.TextColor3 = color end
    }
end

UI.addCustomFrameOption = function(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundColor3 = StudioTheme.insetBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    return row
end

UI.addScrollFeedOption = function(parent, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, height)
    row.Position = UDim2.new(0, 2, 0, 0)
    row.BackgroundColor3 = StudioTheme.insetBg
    row.BorderSizePixel = 1
    row.BorderColor3 = StudioTheme.border
    row.Parent = parent
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = StudioTheme.borderSubtle
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = row
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 1)
    layout.Parent = scroll
    
    local entriesMap, entryCount = {}, 0
    return {
        Clear = function()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end
            entriesMap = {}
            entryCount = 0
        end,
        AddEntry = function(self, text, color, count)
            local initialCount = count or 1
            local existing = entriesMap[text]
            if existing then
                existing.count = existing.count + initialCount
                existing.label.Text = string.format("%s (x%d)", text, existing.count)
                return
            end
            entryCount = entryCount + 1
            local currentOrder = entryCount
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 15)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code
            label.TextSize = 11
            label.TextColor3 = color or StudioTheme.textMuted
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = currentOrder
            local displayText = text
            if initialCount > 1 then displayText = string.format("%s (x%d)", text, initialCount) end
            label.Text = displayText
            label.TextWrapped = true
            label.Parent = scroll
            entriesMap[text] = { label = label, count = initialCount }
            task.defer(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end)
        end
    }
end

local catPositions = { ["Combat"] = 20, ["Player"] = 235, ["Movement"] = 450, ["Render"] = 665, ["World"] = 880, ["Misc"] = 1095, ["Search"] = 1310 }
UI.getOrCreateWindow = function(catName, defaultX, defaultY)
    if UI.windows[catName] then return UI.windows[catName] end
    local x = catPositions[catName] or defaultX or 20
    local y = defaultY or 75
    if not defaultY or defaultY == 50 then y = 75 end
    
    local win = Instance.new("Frame")
    win.Name = "StudioWindow_" .. catName
    win.Size = UDim2.new(0, 210, 0, 24)
    win.AutomaticSize = Enum.AutomaticSize.Y
    win.Position = UDim2.new(0, x, 0, y)
    win.BackgroundColor3 = StudioTheme.windowBg
    win.BorderSizePixel = 1
    win.BorderColor3 = StudioTheme.border
    win.ClipsDescendants = true
    win.Parent = mainUIContainer
    
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = StudioTheme.headerBg
    header.BorderSizePixel = 1
    header.BorderColor3 = StudioTheme.border
    header.AutoButtonColor = false
    header.Text = ""
    header.ZIndex = 2
    header.Parent = win
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -28, 1, 0)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = StudioTheme.text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = catName
    titleLbl.ZIndex = 3
    titleLbl.Parent = header
    
    local collapseBtn = Instance.new("TextLabel")
    collapseBtn.Size = UDim2.new(0, 20, 1, 0)
    collapseBtn.Position = UDim2.new(1, -22, 0, 0)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Font = Enum.Font.SourceSansBold
    collapseBtn.TextSize = 11
    collapseBtn.TextColor3 = StudioTheme.textMuted
    collapseBtn.Text = "v"
    collapseBtn.ZIndex = 3
    collapseBtn.Parent = header
    
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.Position = UDim2.new(0, 0, 0, 24)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Parent = win
    
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 2)
    listPadding.PaddingBottom = UDim.new(0, 2)
    listPadding.PaddingLeft = UDim.new(0, 2)
    listPadding.PaddingRight = UDim.new(0, 2)
    listPadding.Parent = list
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = list
    
    makeDraggable(win, header)
    local collapsed = false
    local function toggleCollapse()
        collapsed = not collapsed
        list.Visible = not collapsed
        if collapsed then
            win.AutomaticSize = Enum.AutomaticSize.None
            win.Size = UDim2.new(0, 210, 0, 24)
            collapseBtn.Text = "^"
        else
            win.AutomaticSize = Enum.AutomaticSize.Y
            win.Size = UDim2.new(0, 210, 0, 24)
            collapseBtn.Text = "v"
        end
        if UI.windows[catName] then UI.windows[catName].Collapsed = collapsed end
    end
    header.Activated:Connect(toggleCollapse)
    
    UI.windows[catName] = {
        Frame = win,
        Header = header,
        TitleLabel = titleLbl,
        List = list,
        Layout = listLayout,
        Collapsed = false
    }
    return UI.windows[catName]
end

UI.createFloatingWindow = function(title, width, height, defaultX, defaultY)
    local winWidth = math.max(width or 210, 210)
    local winHeight = math.max(height or 220, 180)
    
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, winWidth, 0, winHeight)
    win.Position = UDim2.new(0, defaultX, 0, defaultY)
    win.BackgroundColor3 = StudioTheme.windowBg
    win.BorderSizePixel = 1
    win.BorderColor3 = StudioTheme.border
    win.ClipsDescendants = true
    win.Visible = false
    win.ZIndex = 15
    win.Parent = mainUIContainer
    
    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = StudioTheme.headerBg
    header.BorderSizePixel = 1
    header.BorderColor3 = StudioTheme.border
    header.AutoButtonColor = false
    header.Text = ""
    header.ZIndex = 16
    header.Parent = win
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -48, 1, 0)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = StudioTheme.text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title
    titleLbl.ZIndex = 17
    titleLbl.Parent = header
    
    local collapsed = false
    local baseHeight = winHeight
    
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 22, 1, 0)
    collapseBtn.Position = UDim2.new(1, -46, 0, 0)
    collapseBtn.BackgroundColor3 = StudioTheme.headerBg
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Font = Enum.Font.SourceSansBold
    collapseBtn.TextSize = 12
    collapseBtn.TextColor3 = StudioTheme.textMuted
    collapseBtn.Text = "-"
    collapseBtn.ZIndex = 17
    collapseBtn.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 1, 0)
    closeBtn.Position = UDim2.new(1, -24, 0, 0)
    closeBtn.BackgroundColor3 = StudioTheme.headerBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = StudioTheme.textMuted
    closeBtn.Text = "X"
    closeBtn.ZIndex = 17
    closeBtn.Parent = header
    
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = StudioTheme.red; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = StudioTheme.headerBg; closeBtn.TextColor3 = StudioTheme.textMuted end)
    closeBtn.Activated:Connect(function()
        win.Visible = false
        win:SetAttribute("UserOpen", false)
    end)
    
    local content = Instance.new("ScrollingFrame")
    content.Name = "content"
    content.Size = UDim2.new(1, 0, 1, -24)
    content.Position = UDim2.new(0, 0, 0, 24)
    content.BackgroundColor3 = StudioTheme.insetBg
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = StudioTheme.borderSubtle
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ZIndex = 16
    content.Parent = win
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.Parent = content
    
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "resizeHandle"
    resizeHandle.Size = UDim2.new(0, 8, 0, 8)
    resizeHandle.Position = UDim2.new(1, -8, 1, -8)
    resizeHandle.BackgroundColor3 = StudioTheme.borderSubtle
    resizeHandle.BorderSizePixel = 0
    resizeHandle.ZIndex = 20
    resizeHandle.Parent = win
    makeResizable(win, resizeHandle)
    
    collapseBtn.Activated:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        resizeHandle.Visible = not collapsed
        if collapsed then
            baseHeight = win.Size.Y.Offset
            win.Size = UDim2.new(0, win.Size.X.Offset, 0, 24)
            collapseBtn.Text = "+"
        else
            win.Size = UDim2.new(0, win.Size.X.Offset, 0, baseHeight)
            collapseBtn.Text = "-"
        end
    end)
    
    makeDraggable(win, header)
    table.insert(UI.floatingWindows, win)
    win:SetAttribute("BaseWidth", winWidth)
    win:SetAttribute("BaseHeight", winHeight)
    
    return win, content
end

UI.registerModule = function(catName, name, defaultX, defaultY, isToggle, defaultState, callback, populateOptionsFunc, useSeparateWindow, winWidth, winHeight)
    local win = UI.getOrCreateWindow(catName, defaultX, defaultY)
    
    local container = Instance.new("Frame")
    container.Name = "Mod_" .. name
    container.Size = UDim2.new(1, 0, 0, 24)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = StudioTheme.panelBg
    container.BorderSizePixel = 1
    container.BorderColor3 = StudioTheme.border
    container.ClipsDescendants = true
    container.Parent = win.List
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.BackgroundColor3 = StudioTheme.panelBg
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = container
    
    local active = defaultState
    
    local statusStripe = Instance.new("Frame")
    statusStripe.Size = UDim2.new(0, 3, 1, 0)
    statusStripe.Position = UDim2.new(0, 0, 0, 0)
    statusStripe.BackgroundColor3 = (isToggle and active) and StudioTheme.green or StudioTheme.borderSubtle
    statusStripe.BorderSizePixel = 0
    statusStripe.Parent = btn
    
    local modTextLabel = Instance.new("TextLabel")
    modTextLabel.Name = "ModTextLabel"
    modTextLabel.Size = UDim2.new(1, -34, 1, 0)
    modTextLabel.Position = UDim2.new(0, 8, 0, 0)
    modTextLabel.BackgroundTransparency = 1
    modTextLabel.Font = Enum.Font.SourceSansSemibold
    modTextLabel.TextSize = 12
    modTextLabel.TextColor3 = (isToggle and active) and StudioTheme.text or StudioTheme.textMuted
    modTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    modTextLabel.Text = name
    modTextLabel.Parent = btn
    
    local function updateVisuals()
        local isAct = isToggle and active
        statusStripe.BackgroundColor3 = isAct and StudioTheme.green or StudioTheme.borderSubtle
        modTextLabel.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted
        task.defer(UI.updateHUDArrayList)
    end
    
    local drawer = nil
    local floatingWin = nil
    local gear = nil
    
    local function updateBg()
        local isOpened = (useSeparateWindow and floatingWin and floatingWin.Visible) or (drawer and drawer.Visible)
        if isOpened then
            btn.BackgroundColor3 = StudioTheme.categoryBg
            container.BackgroundColor3 = StudioTheme.insetBg
        else
            btn.BackgroundColor3 = StudioTheme.panelBg
            container.BackgroundColor3 = StudioTheme.panelBg
        end
    end
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = StudioTheme.btnHover
    end)
    btn.MouseLeave:Connect(function()
        updateBg()
    end)
    
    local function toggleMenu()
        if useSeparateWindow then
            if not floatingWin then
                local w = winWidth or 210
                local h = winHeight or 220
                floatingWin, drawer = UI.createFloatingWindow(name .. " Settings", w, h, win.Frame.Position.X.Offset + 215, win.Frame.Position.Y.Offset)
                if populateOptionsFunc then populateOptionsFunc(drawer) end
                adjustWindowSizeToContent(floatingWin, drawer)
            end
            floatingWin.Visible = not floatingWin.Visible
            floatingWin:SetAttribute("UserOpen", floatingWin.Visible)
            updateBg()
        else
            if not drawer then
                drawer = Instance.new("Frame")
                drawer.Name = "drawer"
                drawer.Size = UDim2.new(1, 0, 0, 0)
                drawer.Position = UDim2.new(0, 0, 0, 24)
                drawer.AutomaticSize = Enum.AutomaticSize.Y
                drawer.BackgroundColor3 = StudioTheme.insetBg
                drawer.BorderSizePixel = 1
                drawer.BorderColor3 = StudioTheme.border
                drawer.Visible = false
                drawer.Parent = container
                
                local layout = Instance.new("UIListLayout")
                layout.Padding = UDim.new(0, 2)
                layout.Parent = drawer
                
                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 4)
                pad.PaddingBottom = UDim.new(0, 4)
                pad.PaddingLeft = UDim.new(0, 4)
                pad.PaddingRight = UDim.new(0, 4)
                pad.Parent = drawer
                
                if populateOptionsFunc then populateOptionsFunc(drawer) end
            end
            drawer.Visible = not drawer.Visible
            updateBg()
        end
    end
    
    if populateOptionsFunc then
        gear = Instance.new("TextButton")
        gear.Size = UDim2.new(0, 22, 0, 18)
        gear.Position = UDim2.new(1, -24, 0.5, -9)
        gear.BackgroundColor3 = StudioTheme.btnBg
        gear.BorderSizePixel = 1
        gear.BorderColor3 = StudioTheme.border
        gear.Font = Enum.Font.SourceSansBold
        gear.TextSize = 11
        gear.TextColor3 = StudioTheme.textMuted
        gear.Text = "//"
        gear.Parent = btn
        
        gear.MouseEnter:Connect(function() gear.BackgroundColor3 = StudioTheme.blue; gear.TextColor3 = Color3.fromRGB(255, 255, 255) end)
        gear.MouseLeave:Connect(function() gear.BackgroundColor3 = StudioTheme.btnBg; gear.TextColor3 = StudioTheme.textMuted end)
        gear.Activated:Connect(toggleMenu)
    end
    
    btn.Activated:Connect(function()
        if isToggle then
            active = not active
            updateVisuals()
            if callback then callback(active) end
        else
            if callback then callback() end
        end
    end)
    
    local itemObj = {
        Button = btn,
        TextLabel = modTextLabel,
        SetActive = function(val)
            if isToggle and active ~= val then
                active = val
                updateVisuals()
                if callback then callback(val) end
            elseif not isToggle then
                if callback then callback() end
            end
        end,
        IsActive = function() return isToggle and active end,
        ToggleMenu = toggleMenu
    }
    UI.moduleButtons[name] = itemObj
    return itemObj
end

local function selectTab(tabName)
    activeTab = tabName
    for name, btn in pairs(UI.tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = StudioTheme.blue
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = StudioTheme.btnBg
            btn.TextColor3 = StudioTheme.textMuted
        end
    end
    UI.updateMenuBlur()
    if tabName == "Modules" then
        if settingsPanel then settingsPanel.Visible = false end
        local query = (searchBox and searchBox.Text or ""):lower()
        for _, win in pairs(UI.windows) do
            local hasVisibleModule = false
            for _, child in ipairs(win.List:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1, 4) == "Mod_" then
                    local modName = child.Name:sub(5)
                    local matches = (query == "") or (modName:lower():find(query, 1, true) ~= nil)
                    child.Visible = matches
                    if matches then hasVisibleModule = true end
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
        if settingsPanel then
            settingsPanel.Visible = true
            adjustWindowSizeToContent(settingsPanel, settingsContent)
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
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, width, 0, height)
    win.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    win.BackgroundColor3 = StudioTheme.windowBg
    win.BorderSizePixel = 1
    win.BorderColor3 = StudioTheme.border
    win.ClipsDescendants = true
    win.Visible = false
    win.Parent = mainUIContainer
    
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = StudioTheme.headerBg
    header.BorderSizePixel = 1
    header.BorderColor3 = StudioTheme.border
    header.Parent = win
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -32, 1, 0)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = StudioTheme.text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title
    titleLbl.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 1, 0)
    closeBtn.Position = UDim2.new(1, -24, 0, 0)
    closeBtn.BackgroundColor3 = StudioTheme.headerBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = StudioTheme.textMuted
    closeBtn.Text = "X"
    closeBtn.Parent = header
    
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = StudioTheme.red; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = StudioTheme.headerBg; closeBtn.TextColor3 = StudioTheme.textMuted end)
    closeBtn.Activated:Connect(function()
        win.Visible = false
        selectTab("Modules")
    end)
    
    local content = Instance.new("ScrollingFrame")
    content.Name = "content"
    content.Size = UDim2.new(1, 0, 1, -24)
    content.Position = UDim2.new(0, 0, 0, 24)
    content.BackgroundColor3 = StudioTheme.insetBg
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = StudioTheme.borderSubtle
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = win
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = content
    
    makeDraggable(win, header)
    return win, content
end

UI.InitializeUI = function()
    local S = State.S
    
    pcall(function()
        if _G.WASOR_ScreenGui and _G.WASOR_ScreenGui.Parent then
            pcall(function() _G.WASOR_ScreenGui:Destroy() end)
            _G.WASOR_ScreenGui = nil
        end
        local containers = getGuiContainers()
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

    UI.tabButtons = {}
    UI.windows = {}
    UI.moduleButtons = {}
    UI.floatingWindows = {}
    activeToasts = {}

    local targetParent = getGuiParent()
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MeteorRobloxGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.Parent = targetParent
    _G.WASOR_ScreenGui = screenGui
    
    mainUIContainer = Instance.new("Frame")
    mainUIContainer.Name = "MainUIContainer"
    mainUIContainer.Size = UDim2.new(1, 0, 1, 0)
    mainUIContainer.BackgroundTransparency = 1
    mainUIContainer.BorderSizePixel = 0
    mainUIContainer.Visible = true
    mainUIContainer.Parent = screenGui
    
    task.spawn(startToastCleanupWatcher)
    
    menuBlur = Services.Lighting:FindFirstChild("WeAreSkiddingBlur")
    if not menuBlur then
        menuBlur = Instance.new("BlurEffect")
        menuBlur.Name = "WeAreSkiddingBlur"
        menuBlur.Size = 0
        menuBlur.Enabled = false
        menuBlur.Parent = Services.Lighting
    end
    
    hudArrayListFrame = Instance.new("Frame")
    hudArrayListFrame.Size = UDim2.new(0, 150, 0, 0)
    hudArrayListFrame.AutomaticSize = Enum.AutomaticSize.Y
    hudArrayListFrame.Position = UDim2.new(0, S.HUDArrayListX or 10, 0, S.HUDArrayListY or 70)
    hudArrayListFrame.BackgroundColor3 = StudioTheme.windowBg
    hudArrayListFrame.BorderSizePixel = 1
    hudArrayListFrame.BorderColor3 = StudioTheme.border
    hudArrayListFrame.Visible = false
    hudArrayListFrame.Parent = screenGui
    
    local arrayLayout = Instance.new("UIListLayout")
    arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    arrayLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    arrayLayout.Padding = UDim.new(0, 2)
    arrayLayout.Parent = hudArrayListFrame
    
    local hudPadding = Instance.new("UIPadding")
    hudPadding.PaddingTop = UDim.new(0, 4)
    hudPadding.PaddingBottom = UDim.new(0, 4)
    hudPadding.PaddingLeft = UDim.new(0, 4)
    hudPadding.PaddingRight = UDim.new(0, 4)
    hudPadding.Parent = hudArrayListFrame
    
    makeDraggable(hudArrayListFrame, hudArrayListFrame, function(pos)
        S.HUDArrayListX = pos.X.Offset
        S.HUDArrayListY = pos.Y.Offset
        VH.Config.saveConfig()
    end)
    
    task.spawn(function()
        while State.uiRunning do
            task.wait(0.25)
            pcall(UI.updateHUDArrayList)
        end
    end)
    
    topBar = Instance.new("Frame")
    topBar.Name = "StudioTopRibbon"
    topBar.Size = UDim2.new(1, 0, 0, 28)
    topBar.BackgroundColor3 = StudioTheme.headerBg
    topBar.BorderSizePixel = 1
    topBar.BorderColor3 = StudioTheme.border
    topBar.Parent = mainUIContainer
    
    local function getExecutorName()
        if identifyexecutor then local ok, name = pcall(identifyexecutor); if ok and name then return name end end
        if syn then return "Synapse" end; if krnl then return "Krnl" end; if fluxus then return "Fluxus" end
        return "Executor"
    end
    local executorName = getExecutorName()
    
    local topTitle = Instance.new("TextLabel")
    topTitle.Size = UDim2.new(0, 300, 1, 0)
    topTitle.Position = UDim2.new(0, 10, 0, 0)
    topTitle.BackgroundTransparency = 1
    topTitle.Font = Enum.Font.SourceSansBold
    topTitle.TextSize = 12
    topTitle.TextColor3 = StudioTheme.text
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.Text = "WASOR 3.2 (" .. executorName .. ")"
    topTitle.Parent = topBar
    
    navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(0, 380, 1, 0)
    navBar.Position = UDim2.new(0.5, -190, 0, 0)
    navBar.BackgroundTransparency = 1
    navBar.Parent = topBar
    
    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    navLayout.Padding = UDim.new(0, 6)
    navLayout.Parent = navBar
    
    local tabs = {"Modules", "Settings"}
    for _, tabName in ipairs(tabs) do
        local btn = makeStudioButton(navBar, tabName, 80, 22, (tabName == activeTab) and StudioTheme.blue or StudioTheme.btnBg, (tabName == activeTab) and Color3.fromRGB(255, 255, 255) or StudioTheme.textMuted)
        btn.Activated:Connect(function() selectTab(tabName) end)
        UI.tabButtons[tabName] = btn
    end
    
    searchBox = makeStudioTextBox(navBar, "", 130, 22, "Search modules...", false)
    
    local function filterModules(query)
        query = query:lower()
        for _, win in pairs(UI.windows) do
            local hasVisibleModule = false
            for _, child in ipairs(win.List:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1, 4) == "Mod_" then
                    local modName = child.Name:sub(5)
                    local matches = (query == "") or (modName:lower():find(query, 1, true) ~= nil)
                    child.Visible = matches
                    if matches then hasVisibleModule = true end
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
    
    local reloadBtn = makeStudioButton(topBar, "Reload", 58, 22, StudioTheme.btnBg, StudioTheme.text)
    reloadBtn.Position = UDim2.new(1, -66, 0, 3)
    reloadBtn.Activated:Connect(function()
        pcall(function()
            UI.showToast("Reloading WASOR...", StudioTheme.blue)
            task.wait(0.2)
            pcall(function()
                if delfile then
                    delfile("WASOR_cache/commit_sha.txt")
                    delfile("WASOR_cache/Core/UI.lua")
                end
            end)
            VH.Cleanup.cleanupAll()
            task.wait(0.1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenezzaX/WASORCLASSIC/refs/heads/main/github_loader.lua"))()
        end)
    end)
    
    local hudTextLabel = Instance.new("TextLabel")
    hudTextLabel.Size = UDim2.new(0, 150, 1, 0)
    hudTextLabel.Position = UDim2.new(1, -224, 0, 0)
    hudTextLabel.BackgroundTransparency = 1
    hudTextLabel.Font = Enum.Font.Code
    hudTextLabel.TextSize = 11
    hudTextLabel.TextColor3 = StudioTheme.textMuted
    hudTextLabel.TextXAlignment = Enum.TextXAlignment.Right
    hudTextLabel.Text = "FPS: -- | PING: --"
    hudTextLabel.Parent = topBar
    UI.HUDLabel = hudTextLabel
    
    toastContainer = Instance.new("Frame")
    toastContainer.Size = UDim2.new(0, 280, 0, 320)
    toastContainer.Position = UDim2.new(1, -290, 1, -330)
    toastContainer.BackgroundTransparency = 1
    toastContainer.BorderSizePixel = 0
    toastContainer.Parent = screenGui
    
    local toastLayout = Instance.new("UIListLayout")
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 4)
    toastLayout.Parent = toastContainer
    
    local networkUsersHUD = Instance.new("Frame")
    networkUsersHUD.Name = "NetworkUsersHUD"
    networkUsersHUD.Size = UDim2.new(0, 200, 0, 0)
    networkUsersHUD.Position = UDim2.new(0, 10, 1, -10)
    networkUsersHUD.AnchorPoint = Vector2.new(0, 1)
    networkUsersHUD.BackgroundColor3 = StudioTheme.windowBg
    networkUsersHUD.BorderSizePixel = 1
    networkUsersHUD.BorderColor3 = StudioTheme.border
    networkUsersHUD.AutomaticSize = Enum.AutomaticSize.Y
    networkUsersHUD.Visible = S.NetworkTags and S.ShowNetworkUsersHUD
    networkUsersHUD.Parent = screenGui
    
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
    netHeader.Size = UDim2.new(1, 0, 0, 16)
    netHeader.BackgroundTransparency = 1
    netHeader.Font = Enum.Font.SourceSansBold
    netHeader.TextSize = 12
    netHeader.TextColor3 = StudioTheme.blue
    netHeader.TextXAlignment = Enum.TextXAlignment.Left
    netHeader.Text = "Network Users (0)"
    netHeader.Parent = networkUsersHUD
    
    UI.networkUsersHUD = networkUsersHUD
    UI.netHeader = netHeader
    
    hudWatermark = Instance.new("TextLabel")
    hudWatermark.Size = UDim2.new(0, 200, 0, 16)
    hudWatermark.Position = UDim2.new(0, 10, 0, 32)
    hudWatermark.BackgroundTransparency = 1
    hudWatermark.Font = Enum.Font.SourceSansBold
    hudWatermark.TextSize = 12
    hudWatermark.TextColor3 = StudioTheme.blue
    hudWatermark.TextXAlignment = Enum.TextXAlignment.Left
    hudWatermark.Text = "WASOR 3.2"
    hudWatermark.Visible = S.HUDWatermark
    hudWatermark.Parent = screenGui
    
    hudCoords = Instance.new("TextLabel")
    hudCoords.Size = UDim2.new(0, 250, 0, 14)
    hudCoords.Position = UDim2.new(0, 10, 0, 48)
    hudCoords.BackgroundTransparency = 1
    hudCoords.Font = Enum.Font.Code
    hudCoords.TextSize = 10
    hudCoords.TextColor3 = StudioTheme.text
    hudCoords.TextXAlignment = Enum.TextXAlignment.Left
    hudCoords.Text = "XYZ: 0.0, 0.0, 0.0"
    hudCoords.Visible = S.HUDCoords
    hudCoords.Parent = screenGui
    
    hudServerAge = Instance.new("TextLabel")
    hudServerAge.Size = UDim2.new(0, 250, 0, 14)
    hudServerAge.Position = UDim2.new(0, 10, 0, 62)
    hudServerAge.BackgroundTransparency = 1
    hudServerAge.Font = Enum.Font.Code
    hudServerAge.TextSize = 10
    hudServerAge.TextColor3 = StudioTheme.textMuted
    hudServerAge.TextXAlignment = Enum.TextXAlignment.Left
    hudServerAge.Text = "AGE: 0m 0s"
    hudServerAge.Visible = S.HUDServerAge
    hudServerAge.Parent = screenGui
    
    settingsPanel, settingsContent = createPanel("Client Settings - Preferences", 540, 360)
    settingsContent.Visible = false
    
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, -24)
    sidebar.Position = UDim2.new(0, 0, 0, 24)
    sidebar.BackgroundColor3 = StudioTheme.panelAlt
    sidebar.BorderSizePixel = 1
    sidebar.BorderColor3 = StudioTheme.border
    sidebar.Parent = settingsPanel
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 2)
    sidebarLayout.Parent = sidebar
    
    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 4)
    sidebarPadding.PaddingLeft = UDim.new(0, 4)
    sidebarPadding.PaddingRight = UDim.new(0, 4)
    sidebarPadding.Parent = sidebar
    
    local mainContent = Instance.new("Frame")
    mainContent.Size = UDim2.new(1, -140, 1, -24)
    mainContent.Position = UDim2.new(0, 140, 0, 24)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = settingsPanel
    
    local function createTabPage()
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundColor3 = StudioTheme.insetBg
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = StudioTheme.borderSubtle
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = mainContent
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = page
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 6)
        padding.PaddingBottom = UDim.new(0, 6)
        padding.PaddingLeft = UDim.new(0, 6)
        padding.PaddingRight = UDim.new(0, 6)
        padding.Parent = page
        
        return page
    end
    
    local pageInterface = createTabPage()
    local pageHUD = createTabPage()
    local pageInput = createTabPage()
    local pageConfig = createTabPage()
    
    local tabPages = {
        ["Interface Settings"] = pageInterface,
        ["HUD Settings"] = pageHUD,
        ["Input & Macros"] = pageInput,
        ["System & Config"] = pageConfig
    }
    
    local function selectSettingsTab(tabName)
        for name, page in pairs(tabPages) do
            page.Visible = (name == tabName)
        end
        for _, btn in ipairs(sidebar:GetChildren()) do
            if btn:IsA("TextButton") then
                if btn.Text == "  " .. tabName then
                    setButtonState(btn, StudioTheme.blue, Color3.fromRGB(255, 255, 255))
                else
                    setButtonState(btn, StudioTheme.btnBg, StudioTheme.textMuted)
                end
            end
        end
    end
    
    local function createSidebarButton(tabName)
        local btn = makeStudioButton(sidebar, "  " .. tabName, UDim2.new(1, 0, 0, 24), 24, StudioTheme.btnBg, StudioTheme.textMuted, Enum.Font.SourceSansSemibold, 11)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Activated:Connect(function()
            selectSettingsTab(tabName)
        end)
        return btn
    end
    
    createSidebarButton("Interface Settings")
    createSidebarButton("HUD Settings")
    createSidebarButton("Input & Macros")
    createSidebarButton("System & Config")
    
    selectSettingsTab("Interface Settings")
    
    UI.addSectionHeader(pageInterface, "Interface Display & Scaling")
    UI.addSliderOption(pageInterface, "UI Scale Sizing (%)", 70, 150, math.round((S.UIScale or 1.0) * 100), function(v)
        local scale = v / 100
        UI.applyUIScale(scale)
        VH.Config.saveConfig()
    end)
    
    UI.addKeybindOption(pageInterface, "Menu Toggle Keybind", S.UIToggleKey or Enum.KeyCode.RightControl, function(k) S.UIToggleKey = k; VH.Config.saveConfig(); VH.Utils.notify("UI Toggle Keybind set to: " .. k.Name, StudioTheme.green) end)
    UI.addToggleOption(pageInterface, "Show Notification Toasts", S.ToastEnabled, function(v) S.ToastEnabled = v; VH.Config.saveConfig() end)
    
    UI.addSectionHeader(pageHUD, "Heads Up Display (HUD)")
    UI.addToggleOption(pageHUD, "Display Client Watermark", S.HUDWatermark, function(v) S.HUDWatermark = v; hudWatermark.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Player Coordinates", S.HUDCoords, function(v) S.HUDCoords = v; hudCoords.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Server Age HUD", S.ServerAgeHUD, function(v) S.ServerAgeHUD = v; hudServerAge.Visible = v; VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display Active ArrayList", S.HUDArrayList, function(v) S.HUDArrayList = v; UI.updateHUDArrayList(); VH.Config.saveConfig() end)
    UI.addToggleOption(pageHUD, "Display active mods when outside of the main UI", S.HUDArrayListOutside, function(v) S.HUDArrayListOutside = v; UI.updateHUDArrayList(); VH.Config.saveConfig() end)
    
    UI.addSectionHeader(pageInput, "Target Locker & Friends")
    UI.addTextboxOption(pageInput, "Specify Target / Friend", "Username", function(txt) if txt == "" then return end; VH.Utils.notify("Target lock set to: " .. txt, StudioTheme.green) end)
    UI.addButtonOption(pageInput, "Clear Current Friends Lists", function() VH.Utils.notify("Friends lists reset", StudioTheme.red) end)
    
    UI.addSectionHeader(pageInput, "Macros & Bindings")
    UI.addTextboxOption(pageInput, "Configure Macro Text", "Say something...", function(txt) S.MacroText = txt; VH.Config.saveConfig(); VH.Utils.notify("Macro text configured!", StudioTheme.green) end)
    UI.addKeybindOption(pageInput, "Trigger Macro Key", S.MacroKey or Enum.KeyCode.H, function(k) S.MacroKey = k; VH.Config.saveConfig(); VH.Utils.notify("Macro trigger set to: " .. k.Name, StudioTheme.green) end)
    UI.addKeybindOption(pageInput, "Panic Button (Disable All)", S.PanicKey or Enum.KeyCode.End, function(k) S.PanicKey = k; VH.Config.saveConfig(); VH.Utils.notify("Panic Key set to: " .. k.Name, StudioTheme.red) end)
    UI.addKeybindOption(pageInput, "Grab User ID (Hover Player)", S.UserIDGrabKey or Enum.KeyCode.K, function(k) S.UserIDGrabKey = k; VH.Config.saveConfig(); VH.Utils.notify("UserID Grab set to: " .. k.Name, StudioTheme.green) end)
    
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
    UI.addTextboxOption(pageConfig, "Configuration Name", "utility_hub_config", function(txt) end)
    UI.addButtonOption(pageConfig, "Save Current Settings", function() VH.Config.saveConfig(); VH.Utils.notify("Configuration saved successfully!", StudioTheme.green) end)
    UI.addButtonOption(pageConfig, "Load Stored Settings", function() VH.Config.loadConfig(); VH.Utils.notify("Configuration loaded successfully!", StudioTheme.green) end)
    UI.addButtonOption(pageConfig, "Reset Settings to Default", function()
        UI:ResetAllToggles()
        S.WalkSpeed = 16; S.JumpPower = 50; S.InfJump = false; S.BHop = false; S.AirWalk = false; S.NoClip = false; S.Fly = false; S.FlySpeed = 60; S.ESPBoxes = false; S.ESPTracers = false; S.ESPNames = false; S.ESPHealth = false; S.ESPDistances = false; S.ESPTeamCheck = false; S.ESPIgnoreFriends = false; S.LineOfSight = false; S.LineOfSightTeamCheck = false; S.LineOfSightFriendCheck = false; S.LineOfSightLength = 30; S.UltraInstinct = false; S.UltraInstinctRadius = 12; S.UltraInstinctTeamCheck = false; S.AimbotActive = false; S.AimbotIgnoreFriends = false; S.TriggerbotIgnoreFriends = false; S.AntiAFK = false; S.AutoRejoin = false; S.NetworkChat = true; S.NetworkTags = true; ShowNetworkUsersHUD = true; S.ShowNetworkHeadTags = true; S.GravityEnabled = false; S.CustomGravity = 196.2
        if UI.moduleButtons["Network Chat Hub"] then UI.moduleButtons["Network Chat Hub"].SetActive(true) end
        if UI.moduleButtons["Network User Tags"] then UI.moduleButtons["Network User Tags"].SetActive(true) end
        VH.Config.saveConfig(); VH.Utils.notify("All settings reset to default!", StudioTheme.red)
    end)
    UI.addButtonOption(pageConfig, "Destruct Client GUI Completely", function() VH.Cleanup.cleanupAll() end)
    
    catPositions = { ["Combat"] = 20, ["Player"] = 235, ["Movement"] = 450, ["Render"] = 665, ["World"] = 880, ["Misc"] = 1095, ["Search"] = 1310 }
    
    selectTab("Modules")
    UI.applyUIScale(S.UIScale or 1.0)
    
    UI.hudWatermark = hudWatermark
    UI.hudCoords = hudCoords
    UI.hudServerAge = hudServerAge
    UI.hudArrayListFrame = hudArrayListFrame
    
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
                UI.showToast("Welcome to WASOR 3.2!", StudioTheme.blue)
                task.wait(2.2)
                UI.showToast("Toggle UI with [Right Control]", StudioTheme.blue)
                task.wait(2.2)
                UI.showToast("Configure settings in the Settings tab", StudioTheme.blue)
                task.wait(2.2)
                UI.showToast("Press [End] to Panic (disable all)", StudioTheme.red)
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
        eulaFrame.Size = UDim2.new(0, 380, 0, 250)
        eulaFrame.Position = UDim2.new(0.5, -190, 0.5, -125)
        eulaFrame.BackgroundColor3 = StudioTheme.windowBg
        eulaFrame.BorderSizePixel = 1
        eulaFrame.BorderColor3 = StudioTheme.border
        eulaFrame.Parent = screenGui

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 24)
        header.BackgroundColor3 = StudioTheme.headerBg
        header.BorderSizePixel = 1
        header.BorderColor3 = StudioTheme.border
        header.Parent = eulaFrame

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -12, 1, 0)
        titleLbl.Position = UDim2.new(0, 8, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.SourceSansBold
        titleLbl.TextSize = 12
        titleLbl.TextColor3 = StudioTheme.text
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Text = "WASOR - Security Agreement"
        titleLbl.Parent = header

        local textLbl = Instance.new("TextLabel")
        textLbl.Size = UDim2.new(1, -16, 0, 140)
        textLbl.Position = UDim2.new(0, 8, 0, 32)
        textLbl.BackgroundTransparency = 1
        textLbl.Font = Enum.Font.SourceSans
        textLbl.TextSize = 12
        textLbl.TextColor3 = StudioTheme.text
        textLbl.TextXAlignment = Enum.TextXAlignment.Left
        textLbl.TextYAlignment = Enum.TextYAlignment.Top
        textLbl.TextWrapped = true
        textLbl.Text = "This script is designed for utility and testing. Features may trigger server anticheats in games with strict heuristics.\n\nBy agreeing, you acknowledge client network telemetry may connect for version synchronization. The script is open-source and un-obfuscated."
        textLbl.Parent = eulaFrame

        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Size = UDim2.new(1, -16, 0, 26)
        buttonsFrame.Position = UDim2.new(0, 8, 1, -34)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.Parent = eulaFrame

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

        local agreeBtn = makeStudioButton(buttonsFrame, "Agree", UDim2.new(0.48, 0, 1, 0), 26, StudioTheme.green, Color3.fromRGB(255, 255, 255))
        agreeBtn.Position = UDim2.new(0, 0, 0, 0)
        agreeBtn.Activated:Connect(agreeCallback)

        local declineBtn = makeStudioButton(buttonsFrame, "Decline", UDim2.new(0.48, 0, 1, 0), 26, StudioTheme.btnBg, StudioTheme.red)
        declineBtn.Position = UDim2.new(0.52, 0, 0, 0)
        declineBtn.Activated:Connect(declineCallback)
        
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
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 11
        lbl.TextColor3 = is_admin and StudioTheme.yellow or StudioTheme.text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = string.format("%s [%s]", dispName, executor)
        lbl.Parent = UI.networkUsersHUD
    end
    
    UI.netHeader.Text = string.format("Network Users (%d)", userCount)
    
    if userCount == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 11
        lbl.TextColor3 = StudioTheme.textDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "No other users found"
        lbl.Parent = UI.networkUsersHUD
    end
end

UI.GetScreenGui = function() return screenGui end
UI.GetMainContainer = function() return mainUIContainer end

VH.UI = UI
return UI
