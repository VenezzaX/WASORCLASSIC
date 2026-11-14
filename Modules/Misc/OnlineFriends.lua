local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local TeleportService = Services.TeleportService
local themeHeaders = UI.themeHeaders

local notify = Utils.notify
local registerModule = UI.registerModule

local addCustomFrameOption = UI.addCustomFrameOption

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
        if not ok or not onlineFriends then local empty = Instance.new("TextLabel"); empty.Text = "Failed to query friends."; empty.Font = Enum.Font.Gotham; empty.TextSize = math.clamp(math.round(8 * scale), 7, 24); empty.Size = UDim2.new(1, 0, 0, 14 * scale); empty.TextColor3 = Color3.fromRGB(120, 120, 120); empty.BackgroundTransparency = 1; empty.Parent = scroll; return end
        for _, item in ipairs(onlineFriends) do
            local card = Instance.new("Frame"); card.Size = UDim2.new(1, -2, 0, 24 * scale); card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); card.BorderSizePixel = 0; card.Parent = scroll
            local nameL = Instance.new("TextLabel"); nameL.Text = item.DisplayName or item.UserName; nameL.Font = Enum.Font.GothamBold; nameL.TextSize = math.clamp(math.round(7 * scale), 7, 24); nameL.TextColor3 = Color3.fromRGB(230, 230, 230); nameL.BackgroundTransparency = 1; nameL.Position = UDim2.new(0, 2, 0, 1 * scale); nameL.Size = UDim2.new(0, 120 * scale, 0, 10 * scale); nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.Parent = card
            local isInGame = false; local statusText = " Online"; local statusColor = Color3.fromRGB(50, 195, 75)
            if item.LocationType == 1 or item.LocationType == 4 or item.LocationType == 5 or (item.GameId and item.GameId ~= "") then if item.PlaceId and item.PlaceId > 0 then isInGame = true; statusText = " Play: " .. (item.LastLocation or "In-game") end elseif item.LocationType == 3 then statusText = " Studio"; statusColor = Color3.fromRGB(218, 170, 42) end
            local detL = Instance.new("TextLabel"); detL.Text = statusText; detL.Font = Enum.Font.Gotham; detL.TextSize = math.clamp(math.round(6 * scale), 7, 24); detL.TextColor3 = statusColor; detL.BackgroundTransparency = 1; detL.Position = UDim2.new(0, 2, 0, 11 * scale); detL.Size = UDim2.new(0, 150 * scale, 0, 10 * scale); detL.TextXAlignment = Enum.TextXAlignment.Left; detL.Parent = card
            if isInGame then
                local join = Instance.new("TextButton"); join.Size = UDim2.new(0, 26 * scale, 0, 12 * scale); join.Position = UDim2.new(1, -28 * scale, 0.5, -6 * scale); join.BackgroundColor3 = Color3.fromRGB(50, 195, 75); join.BorderSizePixel = 0; join.Font = Enum.Font.GothamBold; join.TextSize = math.clamp(math.round(7 * scale), 7, 24); join.TextColor3 = Color3.fromRGB(255, 255, 255); join.Text = "JOIN"; join.Parent = card
                join.MouseButton1Click:Connect(function() if item.GameId and item.GameId ~= "" then notify("Connecting to friend...", Color3.fromRGB(50, 195, 75)); pcall(function() TeleportService:TeleportToPlaceInstance(item.PlaceId, item.GameId, LP) end) else notify("Warping to friend...", Color3.fromRGB(50, 195, 75)); pcall(function() TeleportService:Teleport(item.PlaceId, LP) end) end end)
            end
        end
    end)
end

registerModule("Misc", "Online Friends", 720, 50, false, false, nil, function(drawer)
    local frame = addCustomFrameOption(drawer, 100)
    local refreshBtn = Instance.new("TextButton"); refreshBtn.Size = UDim2.new(1, -8, 0, 14); refreshBtn.Position = UDim2.new(0, 4, 0, 0); refreshBtn.BackgroundColor3 = State.currentThemeColor; refreshBtn.BorderSizePixel = 0; refreshBtn.Font = Enum.Font.GothamBold; refreshBtn.TextSize = 8; refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255); refreshBtn.Text = "Refresh Online Friends"; refreshBtn.Parent = frame; table.insert(themeHeaders, refreshBtn)
    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -8, 1, -16); scroll.Position = UDim2.new(0, 4, 0, 16); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 1; scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = frame
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = scroll
    refreshBtn.MouseButton1Click:Connect(function() rebuildFriends(scroll) end); rebuildFriends(scroll)
end, true, 200, 200)
