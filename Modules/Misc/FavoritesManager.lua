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
local addCustomFrameOption = UI.addCustomFrameOption
local saveFavorites = VH.Config.saveFavorites

local StudioTheme = {
    panelBg = Color3.fromRGB(42, 42, 45),
    insetBg = Color3.fromRGB(26, 26, 28),
    border = Color3.fromRGB(20, 20, 22),
    text = Color3.fromRGB(225, 225, 228),
    textMuted = Color3.fromRGB(160, 160, 165),
    green = Color3.fromRGB(76, 175, 80),
    yellow = Color3.fromRGB(220, 170, 50),
    red = Color3.fromRGB(215, 60, 60),
    btnBg = Color3.fromRGB(50, 50, 54),
}

local function rebuildFavorites(scroll, filter)
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for idx, map in ipairs(S.FavoriteMaps) do
        local matches = true
        if filter and filter ~= "" then matches = map.name:lower():find(filter:lower()) or tostring(map.id):find(filter) end
        if matches then
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -2, 0, 28)
            card.BackgroundColor3 = StudioTheme.panelBg
            card.BorderSizePixel = 1
            card.BorderColor3 = StudioTheme.border
            card.Parent = scroll

            local nameL = Instance.new("TextLabel")
            nameL.Text = map.name
            nameL.Font = Enum.Font.SourceSansBold
            nameL.TextSize = 11
            nameL.TextColor3 = StudioTheme.text
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 6, 0, 2)
            nameL.Size = UDim2.new(1, -66, 0, 12)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card

            local detailsL = Instance.new("TextLabel")
            detailsL.Text = "Last: " .. (map.lastPlayed or "Never")
            detailsL.Font = Enum.Font.SourceSans
            detailsL.TextSize = 10
            detailsL.TextColor3 = StudioTheme.textMuted
            detailsL.BackgroundTransparency = 1
            detailsL.Position = UDim2.new(0, 6, 0, 14)
            detailsL.Size = UDim2.new(1, -66, 0, 12)
            detailsL.TextXAlignment = Enum.TextXAlignment.Left
            detailsL.Parent = card

            local jb = Instance.new("TextButton")
            jb.Text = "JOIN"
            jb.Font = Enum.Font.SourceSansBold
            jb.TextSize = 10
            jb.TextColor3 = Color3.fromRGB(255, 255, 255)
            jb.BackgroundColor3 = StudioTheme.green
            jb.BorderSizePixel = 1
            jb.BorderColor3 = StudioTheme.border
            jb.Size = UDim2.new(0, 36, 0, 16)
            jb.Position = UDim2.new(1, -58, 0.5, -8)
            jb.Parent = card
            jb.MouseButton1Click:Connect(function()
                notify("Joining fav: " .. map.name, StudioTheme.yellow)
                map.lastPlayed = os.date("%Y-%m-%d %H:%M")
                saveFavorites()
                rebuildFavorites(scroll, filter)
                task.delay(0.3, function() TeleportService:Teleport(map.id, LP) end)
            end)

            local rb = Instance.new("TextButton")
            rb.Text = "X"
            rb.Font = Enum.Font.SourceSansBold
            rb.TextSize = 11
            rb.TextColor3 = Color3.fromRGB(255, 255, 255)
            rb.BackgroundColor3 = StudioTheme.red
            rb.BorderSizePixel = 1
            rb.BorderColor3 = StudioTheme.border
            rb.Size = UDim2.new(0, 18, 0, 16)
            rb.Position = UDim2.new(1, -20, 0.5, -8)
            rb.Parent = card
            rb.MouseButton1Click:Connect(function()
                table.remove(S.FavoriteMaps, idx)
                saveFavorites()
                rebuildFavorites(scroll, filter)
                notify("Experience removed from list", StudioTheme.red)
            end)
        end
    end
end

registerModule("Misc", "Favorite games", 720, 50, false, false, nil, function(drawer)
    addTextboxOption(drawer, "Save Place ID to Favorites", "Place ID", function(txt)
        local pid = tonumber(txt:match("%d+"))
        if not pid then notify("Enter a valid place ID", StudioTheme.red); return end
        for _, item in ipairs(S.FavoriteMaps) do if item.id == pid then notify("Already in favorites!", StudioTheme.yellow); return end end
        notify("Resolving Place ID info...", StudioTheme.yellow)
        task.spawn(function()
            local gameName = "Place: " .. pid
            local universeId = nil
            pcall(function()
                local res = HttpService:JSONDecode(robloxGet(("https://apis.roblox.com/universes/v1/places/%d/universe"):format(pid)))
                if res and res.universeId then
                    universeId = res.universeId
                    local resDetails = HttpService:JSONDecode(robloxGet(("https://games.roblox.com/v1/games?universeIds=%d"):format(universeId)))
                    if resDetails and resDetails.data and resDetails.data[1] then gameName = resDetails.data[1].name end
                end
            end)
            table.insert(S.FavoriteMaps, { id = pid, universeId = universeId, iconUrl = nil, name = gameName, lastPlayed = "Added: " .. os.date("%m-%d %H:%M") })
            saveFavorites()
            notify("Saved: " .. gameName, StudioTheme.green)
        end)
    end)
    local frame = addCustomFrameOption(drawer, 100)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -4)
    scroll.Position = UDim2.new(0, 4, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
    rebuildFavorites(scroll)
end, true, 220, 220)
