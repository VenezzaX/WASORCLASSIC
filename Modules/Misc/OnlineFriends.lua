local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local TeleportService = Services.TeleportService

local notify = Utils.notify
local registerModule = UI.registerModule
local addCustomFrameOption = UI.addCustomFrameOption

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

local function findWindowFrame(obj)
    local curr = obj
    while curr do if curr:IsA("Frame") and curr:GetAttribute("BaseWidth") then return curr end; curr = curr.Parent end
    return nil
end

local function rebuildFriends(scroll)
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
    local scale = 1.0; local winFrame = findWindowFrame(scroll)
    if winFrame then local baseW = winFrame:GetAttribute("BaseWidth") or winFrame.Size.X.Offset; if baseW > 0 then scale = winFrame.Size.X.Offset / baseW end end
    task.spawn(function()
        local ok, onlineFriends = pcall(function() return LP:GetFriendsOnline(200) end)
        if not ok or not onlineFriends then
            local empty = Instance.new("TextLabel")
            empty.Text = "Failed to query friends."
            empty.Font = Enum.Font.SourceSans
            empty.TextSize = math.clamp(math.round(11 * scale), 9, 24)
            empty.Size = UDim2.new(1, 0, 0, 18 * scale)
            empty.TextColor3 = StudioTheme.textMuted
            empty.BackgroundTransparency = 1
            empty.Parent = scroll
            return
        end
        for _, item in ipairs(onlineFriends) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -2, 0, 28 * scale)
            card.BackgroundColor3 = StudioTheme.panelBg
            card.BorderSizePixel = 1
            card.BorderColor3 = StudioTheme.border
            card.Parent = scroll

            local nameL = Instance.new("TextLabel")
            nameL.Text = item.DisplayName or item.UserName
            nameL.Font = Enum.Font.SourceSansBold
            nameL.TextSize = math.clamp(math.round(11 * scale), 9, 24)
            nameL.TextColor3 = StudioTheme.text
            nameL.BackgroundTransparency = 1
            nameL.Position = UDim2.new(0, 6, 0, 2 * scale)
            nameL.Size = UDim2.new(1, -50 * scale, 0, 12 * scale)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = card

            local isInGame = false
            local statusText = "Online"
            local statusColor = StudioTheme.green
            if item.LocationType == 1 or item.LocationType == 4 or item.LocationType == 5 or (item.GameId and item.GameId ~= "") then
                if item.PlaceId and item.PlaceId > 0 then
                    isInGame = true
                    statusText = "Play: " .. (item.LastLocation or "In-game")
                end
            elseif item.LocationType == 3 then
                statusText = "Studio"
                statusColor = StudioTheme.yellow
            end

            local detL = Instance.new("TextLabel")
            detL.Text = statusText
            detL.Font = Enum.Font.SourceSans
            detL.TextSize = math.clamp(math.round(10 * scale), 8, 24)
            detL.TextColor3 = statusColor
            detL.BackgroundTransparency = 1
            detL.Position = UDim2.new(0, 6, 0, 14 * scale)
            detL.Size = UDim2.new(1, -50 * scale, 0, 12 * scale)
            detL.TextXAlignment = Enum.TextXAlignment.Left
            detL.Parent = card

            if isInGame then
                local join = Instance.new("TextButton")
                join.Size = UDim2.new(0, 36 * scale, 0, 16 * scale)
                join.Position = UDim2.new(1, -40 * scale, 0.5, -8 * scale)
                join.BackgroundColor3 = StudioTheme.green
                join.BorderSizePixel = 1
                join.BorderColor3 = StudioTheme.border
                join.Font = Enum.Font.SourceSansBold
                join.TextSize = math.clamp(math.round(10 * scale), 8, 24)
                join.TextColor3 = Color3.fromRGB(255, 255, 255)
                join.Text = "JOIN"
                join.Parent = card
                join.MouseButton1Click:Connect(function()
                    if item.GameId and item.GameId ~= "" then
                        notify("Connecting to friend...", StudioTheme.green)
                        pcall(function() TeleportService:TeleportToPlaceInstance(item.PlaceId, item.GameId, LP) end)
                    else
                        notify("Warping to friend...", StudioTheme.green)
                        pcall(function() TeleportService:Teleport(item.PlaceId, LP) end)
                    end
                end)
            end
        end
    end)
end

registerModule("Misc", "Online Friends", 720, 50, false, false, nil, function(drawer)
    local frame = addCustomFrameOption(drawer, 120)
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, -8, 0, 20)
    refreshBtn.Position = UDim2.new(0, 4, 0, 2)
    refreshBtn.BackgroundColor3 = StudioTheme.btnBg
    refreshBtn.BorderSizePixel = 1
    refreshBtn.BorderColor3 = StudioTheme.border
    refreshBtn.Font = Enum.Font.SourceSansBold
    refreshBtn.TextSize = 11
    refreshBtn.TextColor3 = StudioTheme.text
    refreshBtn.Text = "Refresh Online Friends"
    refreshBtn.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -26)
    scroll.Position = UDim2.new(0, 4, 0, 24)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
    refreshBtn.MouseButton1Click:Connect(function() rebuildFriends(scroll) end)
    rebuildFriends(scroll)
end, true, 220, 220)
