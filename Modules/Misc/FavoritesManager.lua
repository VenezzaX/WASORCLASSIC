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

local activeScroll = nil

local function rebuildFavorites(scroll, filter)
    if not scroll then return end
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for idx, map in ipairs(S.FavoriteMaps or {}) do
        local matches = true
        if filter and filter ~= "" then matches = map.name:lower():find(filter:lower()) or tostring(map.id):find(filter) end
        if matches then
            local card = Instance.new("Frame"); card.Size = UDim2.new(1, -2, 0, 24); card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); card.BorderSizePixel = 0; card.Parent = scroll
            local nameL = Instance.new("TextLabel"); nameL.Text = map.name; nameL.Font = Enum.Font.GothamBold; nameL.TextSize = 7; nameL.TextColor3 = Color3.fromRGB(230, 230, 230); nameL.BackgroundTransparency = 1; nameL.Position = UDim2.new(0, 2, 0, 1); nameL.Size = UDim2.new(0.5, 0, 0, 10); nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.Parent = card
            local detailsL = Instance.new("TextLabel"); detailsL.Text = "Last: " .. (map.lastPlayed or "Never"); detailsL.Font = Enum.Font.Gotham; detailsL.TextSize = 6; detailsL.TextColor3 = Color3.fromRGB(120, 120, 120); detailsL.BackgroundTransparency = 1; detailsL.Position = UDim2.new(0, 2, 0, 11); detailsL.Size = UDim2.new(0.5, 0, 0, 10); detailsL.TextXAlignment = Enum.TextXAlignment.Left; detailsL.Parent = card
            local jb = Instance.new("TextButton"); jb.Text = "JOIN"; jb.Font = Enum.Font.GothamBold; jb.TextSize = 7; jb.TextColor3 = Color3.fromRGB(255, 255, 255); jb.BackgroundColor3 = Color3.fromRGB(218, 38, 38); jb.Size = UDim2.new(0, 26, 0, 12); jb.Position = UDim2.new(1, -44, 0.5, -6); jb.Parent = card
            jb.MouseButton1Click:Connect(function() notify("Joining fav: " .. map.name, Color3.fromRGB(218, 170, 42)); map.lastPlayed = os.date("%Y-%m-%d %H:%M"); saveFavorites(); rebuildFavorites(scroll, filter); task.delay(0.3, function() TeleportService:Teleport(map.id, LP) end) end)
            local rb = Instance.new("TextButton"); rb.Text = "X"; rb.Font = Enum.Font.GothamBold; rb.TextSize = 8; rb.TextColor3 = Color3.fromRGB(218, 38, 38); rb.BackgroundColor3 = Color3.fromRGB(22, 22, 22); rb.Size = UDim2.new(0, 14, 0, 12); rb.Position = UDim2.new(1, -16, 0.5, -6); rb.Parent = card
            rb.MouseButton1Click:Connect(function() table.remove(S.FavoriteMaps, idx); saveFavorites(); rebuildFavorites(scroll, filter); notify("Experience removed from list", Color3.fromRGB(218, 38, 38)) end)
        end
    end
end

local function addFavoriteById(pid)
    S.FavoriteMaps = S.FavoriteMaps or {}
    for _, item in ipairs(S.FavoriteMaps) do
        if item.id == pid then
            notify("Already in favorites!", Color3.fromRGB(218, 170, 42))
            return
        end
    end
    notify("Resolving Place ID info (" .. tostring(pid) .. ")...", Color3.fromRGB(218, 170, 42))
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
            rebuildFavorites(activeScroll)
        end
        notify("Saved to Favorites: " .. gameName, Color3.fromRGB(50, 195, 75))
    end)
end

registerModule("Misc", "Favorite games", 720, 50, false, false, nil, function(drawer)
    if loadFavorites then pcall(loadFavorites) end

    addTextboxOption(drawer, "Save Place ID to Favorites", "Place ID", function(txt)
        local pid = tonumber(txt:match("%d+"))
        if not pid then notify("Enter a valid place ID", Color3.fromRGB(218, 38, 38)); return end
        addFavoriteById(pid)
    end)

    addButtonOption(drawer, "Add Current Game to Favorites", function()
        local curId = game.PlaceId
        if curId and curId > 0 then
            addFavoriteById(curId)
        else
            notify("Current Place ID not available", Color3.fromRGB(218, 38, 38))
        end
    end)

    addButtonOption(drawer, "Refresh Favorites List", function()
        if loadFavorites then pcall(loadFavorites) end
        if activeScroll then rebuildFavorites(activeScroll) end
        notify("Favorites refreshed", Color3.fromRGB(50, 195, 75))
    end)

    local frame = addCustomFrameOption(drawer, 80)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, 0)
    scroll.Position = UDim2.new(0, 4, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    activeScroll = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    rebuildFavorites(scroll)
end, true, 200, 200)
