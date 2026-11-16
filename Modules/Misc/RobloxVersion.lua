local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local Utils = VH.Utils
local UI = VH.UI

local S = State.S
local LP = Services.LP or game:GetService("Players").LocalPlayer
local notify = Utils.notify
local registerModule = UI.registerModule
local addButtonOption = UI.addButtonOption
local addInfoRowOption = UI.addInfoRowOption
local saveConfig = VH.Config and VH.Config.saveConfig

local HttpService = Services.HttpService or game:GetService("HttpService")
local UserInputService = Services.UserInputService or game:GetService("UserInputService")

local httpRequest = request
    or http_request
    or (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)

local function makeGet(url)
    if httpRequest then
        local ok, res = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "WEAO-3PService",
                    ["Accept"] = "application/json"
                }
            })
        end)
        if ok and type(res) == "table" and res.Body then
            return res.Body
        end
    end
    if game and game.HttpGet then
        local ok, body = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and type(body) == "string" then
            return body
        end
    end
    return nil
end

local cachedData = {
    current = nil,
    future = nil,
    past = nil,
    clientVersion = (version and version()) or "Unknown",
    placeVersion = tostring(game.PlaceVersion or 0),
    isFetching = false
}

local function fetchEndpoint(endpoint)
    local body = makeGet("https://weao.xyz/api/versions/" .. endpoint)
    if body and type(body) == "string" then
        local decodeOk, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if decodeOk and type(decoded) == "table" then
            return decoded
        end
    end
    return nil
end

local function formatWindowsLine(label, data)
    if not data or not data.Windows then
        return string.format("%-7s : Unavailable", label)
    end
    return string.format(
        "%-7s : %s (%s)",
        label,
        tostring(data.Windows),
        tostring(data.WindowsDate or "Unknown date")
    )
end

local function formatVersionShort(data)
    if not data or not data.Windows then
        return "Unavailable"
    end
    local hash = tostring(data.Windows)
    local date = tostring(data.WindowsDate or "")
    if date ~= "" then
        return hash .. " (" .. date .. ")"
    end
    return hash
end

local function getSafeContainer()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if get_hidden_gui then
        local ok, hg = pcall(get_hidden_gui)
        if ok and hg then return hg end
    end
    local ok, coreGui = pcall(function() return Services.CoreGui end)
    if ok and coreGui then return coreGui end
    return LP:WaitForChild("PlayerGui")
end

local overlayGui = nil
local textLabel = nil
local drawerRows = {}

local function generateDisplayText()
    if cachedData.isFetching and not cachedData.current then
        return table.concat({
            "=== ROBLOX WINDOWS VERSIONS ===",
            "Fetching Windows versions..."
        }, "\n")
    end
    return table.concat({
        "=== ROBLOX WINDOWS VERSIONS ===",
        formatWindowsLine("Current", cachedData.current),
        formatWindowsLine("Future", cachedData.future),
        formatWindowsLine("Past", cachedData.past)
    }, "\n")
end

local function updateAllDisplays()
    local text = generateDisplayText()
    if textLabel and textLabel.Parent then
        textLabel.Text = text
    end

    local curStr = formatVersionShort(cachedData.current)
    local futStr = formatVersionShort(cachedData.future)
    local pstStr = formatVersionShort(cachedData.past)

    if drawerRows["WEAO Current"] then drawerRows["WEAO Current"].Text = curStr end
    if drawerRows["WEAO Future"] then drawerRows["WEAO Future"].Text = futStr end
    if drawerRows["WEAO Past"] then drawerRows["WEAO Past"].Text = pstStr end
end

local function refreshVersions(force)
    if cachedData.isFetching then return end
    cachedData.isFetching = true

    if textLabel and not cachedData.current then
        textLabel.Text = table.concat({
            "=== ROBLOX WINDOWS VERSIONS ===",
            "Fetching Windows versions..."
        }, "\n")
    end

    task.spawn(function()
        local cur = fetchEndpoint("current")
        if cur then cachedData.current = cur end
        task.wait(0.35)

        local fut = fetchEndpoint("future")
        if fut then cachedData.future = fut end
        task.wait(0.35)

        local pst = fetchEndpoint("past")
        if pst then cachedData.past = pst end

        cachedData.isFetching = false
        updateAllDisplays()

        if force then
            notify("Roblox versions refreshed!", Color3.fromRGB(50, 195, 75))
        end
    end)
end

local function createOverlay()
    if overlayGui and overlayGui.Parent then
        return overlayGui
    end

    local parent = getSafeContainer()
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "WASOR_RobloxVersionOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    overlayGui.Parent = parent

    textLabel = Instance.new("TextLabel")
    textLabel.Name = "VersionTextOverlay"
    textLabel.AnchorPoint = Vector2.new(0, 1)

    local scX = (S and S.RobloxVersionScaleX) or 0
    local ofX = (S and S.RobloxVersionOffsetX) or 18
    local scY = (S and S.RobloxVersionScaleY) or 1
    local ofY = (S and S.RobloxVersionOffsetY) or -18

    textLabel.Position = UDim2.new(scX, ofX, scY, ofY)
    textLabel.Size = UDim2.new(0, 750, 0, 120)
    textLabel.BackgroundTransparency = 1
    textLabel.BorderSizePixel = 0
    textLabel.Font = Enum.Font.Code
    textLabel.TextSize = 15
    textLabel.TextColor3 = Color3.fromRGB(230, 236, 255)
    textLabel.TextStrokeColor3 = Color3.fromRGB(10, 12, 18)
    textLabel.TextStrokeTransparency = 0.2
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    textLabel.Active = true
    textLabel.Text = generateDisplayText()
    textLabel.Parent = overlayGui

    local isDragging = false
    local dragStartMouse = Vector2.zero
    local dragStartPos = UDim2.new()

    textLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
            dragStartPos = textLabel.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
            textLabel.Position = UDim2.new(
                dragStartPos.X.Scale,
                dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale,
                dragStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                if S then
                    S.RobloxVersionScaleX = textLabel.Position.X.Scale
                    S.RobloxVersionOffsetX = textLabel.Position.X.Offset
                    S.RobloxVersionScaleY = textLabel.Position.Y.Scale
                    S.RobloxVersionOffsetY = textLabel.Position.Y.Offset
                    if saveConfig then pcall(saveConfig) end
                end
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            if overlayGui then
                overlayGui.Enabled = not overlayGui.Enabled
                S.RobloxVersion = overlayGui.Enabled
                if saveConfig then pcall(saveConfig) end
                if UI.updateAllModuleVisuals then pcall(UI.updateAllModuleVisuals) end
            end
        end
    end)

    return overlayGui
end

registerModule("Misc", "Roblox Version", 720, 50, true, S.RobloxVersion or false, function(enabled)
    S.RobloxVersion = enabled
    if saveConfig then pcall(saveConfig) end
    if enabled then
        local gui = createOverlay()
        if gui then gui.Enabled = true end
        refreshVersions(false)
        notify("Roblox Version Monitor displayed", Color3.fromRGB(50, 195, 75))
    else
        if overlayGui then
            overlayGui.Enabled = false
        end
        notify("Roblox Version Monitor hidden", Color3.fromRGB(218, 170, 42))
    end
end, function(drawer)
    addButtonOption(drawer, "Refresh Version Data", function()
        refreshVersions(true)
    end)

    addButtonOption(drawer, "Toggle Overlay", function()
        local gui = createOverlay()
        gui.Enabled = not gui.Enabled
        S.RobloxVersion = gui.Enabled
        if saveConfig then pcall(saveConfig) end
        if UI.updateAllModuleVisuals then pcall(UI.updateAllModuleVisuals) end
        if gui.Enabled then
            refreshVersions(false)
            notify("Roblox Version Monitor displayed", Color3.fromRGB(50, 195, 75))
        else
            notify("Roblox Version Monitor hidden", Color3.fromRGB(218, 170, 42))
        end
    end)

    addButtonOption(drawer, "Reset Text Position (Bottom-Left)", function()
        if textLabel then
            textLabel.Position = UDim2.new(0, 18, 1, -18)
        end
        if S then
            S.RobloxVersionScaleX = 0
            S.RobloxVersionOffsetX = 18
            S.RobloxVersionScaleY = 1
            S.RobloxVersionOffsetY = -18
            if saveConfig then pcall(saveConfig) end
        end
        notify("Overlay position reset to bottom-left", Color3.fromRGB(80, 160, 255))
    end)

    addButtonOption(drawer, "Copy All Version Info", function()
        local setclip = setclipboard or writeclipboard or toclipboard or print
        local curStr = formatVersionShort(cachedData.current)
        local futStr = formatVersionShort(cachedData.future)
        local pstStr = formatVersionShort(cachedData.past)
        local report = string.format("Roblox Client: %s\nPlace Version: %s\nWEAO Current: %s\nWEAO Future: %s\nWEAO Past: %s",
            cachedData.clientVersion,
            cachedData.placeVersion,
            curStr,
            futStr,
            pstStr
        )
        pcall(function() setclip(report) end)
        notify("Version info copied to clipboard!", Color3.fromRGB(50, 195, 75))
    end)

    addInfoRowOption(drawer, "Client Version", cachedData.clientVersion)
    addInfoRowOption(drawer, "Place Version", cachedData.placeVersion)
    drawerRows["WEAO Current"] = addInfoRowOption(drawer, "WEAO Current", formatVersionShort(cachedData.current))
    drawerRows["WEAO Future"] = addInfoRowOption(drawer, "WEAO Future", formatVersionShort(cachedData.future))
    drawerRows["WEAO Past"] = addInfoRowOption(drawer, "WEAO Past", formatVersionShort(cachedData.past))
end)