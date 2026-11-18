local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local HttpService = Services.HttpService
local robloxGet = Utils.robloxGet
local TeleportService = Services.TeleportService

local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule

local addTextboxOption = UI.addTextboxOption
local addButtonOption = UI.addButtonOption
local addCustomFrameOption = UI.addCustomFrameOption

local saveFavorites = VH.Config.saveFavorites
local loadFavorites = VH.Config.loadFavorites

local StudioTheme = UI.StudioTheme or {
    windowBg = Color3.fromRGB(37, 37, 38),
    headerBg = Color3.fromRGB(45, 45, 48),
    panelBg = Color3.fromRGB(42, 42, 45),
    insetBg = Color3.fromRGB(26, 26, 28),
    border = Color3.fromRGB(20, 20, 22),
    text = Color3.fromRGB(225, 225, 228),
    textMuted = Color3.fromRGB(160, 160, 165),
    textDim = Color3.fromRGB(115, 115, 120),
    green = Color3.fromRGB(76, 175, 80),
    yellow = Color3.fromRGB(220, 170, 50),
    red = Color3.fromRGB(215, 60, 60),
    btnBg = Color3.fromRGB(50, 50, 54),
}

local activeScroll = nil
local currentFilter = ""

local function rebuildFavorites(scroll, filter)
    if not scroll then return end
    currentFilter = filter or currentFilter or ""
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local filterLower = currentFilter:lower()

    for idx, map in ipairs(S.FavoriteMaps or {}) do
        local matches = true
        if filterLower ~= "" then
            matches = (map.name or ""):lower():find(filterLower, 1, true) or tostring(map.id):find(filterLower, 1, true)
        end
        if matches then
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -2, 0, 32)
            card.BackgroundColor3 = StudioTheme.panelBg
            card.BorderSizePixel = 1
            card.BorderColor3 = StudioTheme.border
            card.Parent = scroll

            local nameL = Instance.new("TextLabel")
            nameL.Text = map.name or ("Place: " .. tostring(map.id))
            nameL.Font = Enum.Font.SourceSansBold
            nameL.TextSize = 12
            nameL.TextColor3 = StudioTheme.text
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 6, 0, 1)
            nameL.Size = UDim2.new(1, -85, 0, 15)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.Parent = card

            local detailsL = Instance.new("TextLabel")
            detailsL.Text = string.format("ID: %s • %s", tostring(map.id), map.lastPlayed or "Never")
            detailsL.Font = Enum.Font.SourceSans
            detailsL.TextSize = 10
            detailsL.TextColor3 = StudioTheme.textMuted
            detailsL.BackgroundTransparency = 1
            detailsL.Position = UDim2.new(0, 6, 0, 16)
            detailsL.Size = UDim2.new(1, -85, 0, 13)
            detailsL.TextXAlignment = Enum.TextXAlignment.Left
            detailsL.TextTruncate = Enum.TextTruncate.AtEnd
            detailsL.Parent = card

            local jb = Instance.new("TextButton")
            jb.Text = "JOIN"
            jb.Font = Enum.Font.SourceSansBold
            jb.TextSize = 11
            jb.TextColor3 = Color3.fromRGB(255, 255, 255)
            jb.BackgroundColor3 = StudioTheme.green
            jb.Size = UDim2.new(0, 44, 0, 20)
            jb.Position = UDim2.new(1, -74, 0.5, -10)
            jb.BorderSizePixel = 1
            jb.BorderColor3 = StudioTheme.border
            jb.Parent = card
            jb.MouseButton1Click:Connect(function()
                notify("Joining favorite: " .. (map.name or tostring(map.id)), StudioTheme.yellow)
                map.lastPlayed = os.date("%Y-%m-%d %H:%M")
                saveFavorites()
                rebuildFavorites(scroll, currentFilter)
                task.delay(0.3, function() TeleportService:Teleport(map.id, LP) end)
            end)

            local rb = Instance.new("TextButton")
            rb.Text = "X"
            rb.Font = Enum.Font.SourceSansBold
            rb.TextSize = 11
            rb.TextColor3 = StudioTheme.red
            rb.BackgroundColor3 = StudioTheme.btnBg
            rb.Size = UDim2.new(0, 22, 0, 20)
            rb.Position = UDim2.new(1, -26, 0.5, -10)
            rb.BorderSizePixel = 1
            rb.BorderColor3 = StudioTheme.border
            rb.Parent = card
            rb.MouseButton1Click:Connect(function()
                table.remove(S.FavoriteMaps, idx)
                saveFavorites()
                rebuildFavorites(scroll, currentFilter)
                notify("Experience removed from favorites", StudioTheme.red)
            end)
        end
    end
end

local function addFavoriteById(pid)
    S.FavoriteMaps = S.FavoriteMaps or {}
    for _, item in ipairs(S.FavoriteMaps) do
        if item.id == pid then
            notify("Already in favorites!", StudioTheme.yellow)
            return
        end
    end
    notify("Resolving Place ID info (" .. tostring(pid) .. ")...", StudioTheme.yellow)
    task.spawn(function()
        local gameName = "Place: " .. pid
        local universeId = nil
        pcall(function()
            local res = HttpService:JSONDecode(robloxGet(("https://apis.roblox.com/universes/v1/places/%d/universe"):format(pid)))
            if res and res.universeId then
                universeId = res.universeId
                local resDetails = HttpService:JSONDecode(robloxGet(("https://games.roblox.com/v1/games?universeIds=%d"):format(universeId)))
                if resDetails and resDetails.data and resDetails.data[1] then
                    gameName = resDetails.data[1].name
                end
            end
        end)
        table.insert(S.FavoriteMaps, {
            id = pid,
            universeId = universeId,
            iconUrl = nil,
            name = gameName,
            lastPlayed = "Added: " .. os.date("%m-%d %H:%M")
        })
        saveFavorites()
        if activeScroll then
            rebuildFavorites(activeScroll, currentFilter)
        end
        notify("Saved: " .. gameName, StudioTheme.green)
    end)
end

registerModule("Misc", "Favorite games", 720, 50, false, false, nil, function(drawer)
    if loadFavorites then pcall(loadFavorites) end

    addTextboxOption(drawer, "Save Place ID to Favorites", "Place ID...", function(txt)
        local pid = tonumber(txt:match("%d+"))
        if not pid then notify("Enter a valid place ID", StudioTheme.red); return end
        addFavoriteById(pid)
    end)

    addButtonOption(drawer, "Add Current Game to Favorites", function()
        local curId = game.PlaceId
        if curId and curId > 0 then
            addFavoriteById(curId)
        else
            notify("Current Place ID not available", StudioTheme.red)
        end
    end)

    addButtonOption(drawer, "Refresh Favorites List", function()
        if loadFavorites then pcall(loadFavorites) end
        if activeScroll then rebuildFavorites(activeScroll, currentFilter) end
        notify("Favorites refreshed", StudioTheme.green)
    end)

    local frame = addCustomFrameOption(drawer, 185)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 24)
    box.Position = UDim2.new(0, 4, 0, 2)
    box.BackgroundColor3 = StudioTheme.insetBg
    box.BorderSizePixel = 1
    box.BorderColor3 = StudioTheme.border
    box.Font = Enum.Font.SourceSans
    box.TextSize = 12
    box.TextColor3 = StudioTheme.text
    box.PlaceholderText = "Search favorites by name or ID..."
    box.PlaceholderColor3 = StudioTheme.textDim
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = frame
    local boxPad = Instance.new("UIPadding", box)
    boxPad.PaddingLeft = UDim.new(0, 6)
    boxPad.PaddingRight = UDim.new(0, 6)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -30)
    scroll.Position = UDim2.new(0, 4, 0, 28)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    activeScroll = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = scroll

    box:GetPropertyChangedSignal("Text"):Connect(function()
        rebuildFavorites(scroll, box.Text)
    end)

    rebuildFavorites(scroll)
end, true, 340, 380)
