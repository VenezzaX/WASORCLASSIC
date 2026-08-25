local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP

local getHRP = Utils.getHRP
local notify = Utils.notify
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption
local addButtonOption = UI.addButtonOption
local addInfoRowOption = UI.addInfoRowOption
local addCustomFrameOption = UI.addCustomFrameOption

local saveConfig = VH.Config.saveConfig

local teleportToHRP = Utils.teleportToHRP
local spectatePlayer = Utils.spectatePlayer
local resetCameraToSelf = Utils.resetCameraToSelf
local enableFreecam = Utils.enableFreecam
local disableFreecam = Utils.disableFreecam

local spectateStatsLabels = State.spectateStatsLabels

local currentSpectateTarget = nil
local isFreecam = false 

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

registerModule("Player", "Spectate & Freecam", 160, 50, false, false, nil, function(drawer)
    local rName = addInfoRowOption(drawer, "Viewing Target Name", currentSpectateTarget and currentSpectateTarget.DisplayName or "--")
    local rHp = addInfoRowOption(drawer, "Target Health", "--")
    local rTeam = addInfoRowOption(drawer, "Target Team", "--")
    spectateStatsLabels.name = rName.Label
    spectateStatsLabels.hp = rHp.Label
    spectateStatsLabels.team = rTeam.Label
    
    addToggleOption(drawer, "Auto Follow Player", S.FollowActive, function(v) S.FollowActive = v; S.FollowTarget = currentSpectateTarget; saveConfig() end)
    
    addButtonOption(drawer, "Teleport to Nearest Player", function()
        local myHRP = getHRP()
        if not myHRP then notify("Self root part not found!", StudioTheme.red); return end
        local nearest, shortestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
                if root then local dist = (root.Position - myHRP.Position).Magnitude; if dist < shortestDist then shortestDist = dist; nearest = p end end
            end
        end
        if nearest then
            local targetHRP = nearest.Character:FindFirstChild("HumanoidRootPart") or nearest.Character:FindFirstChild("Torso") or nearest.Character.PrimaryPart
            if teleportToHRP(targetHRP) then notify("Teleported to nearest: " .. nearest.DisplayName .. string.format(" (%.1f studs)", shortestDist), StudioTheme.green) end
        else notify("No other players found nearby", StudioTheme.red) end
    end)
    
    addButtonOption(drawer, "Teleport to Random Player", function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
                if root then table.insert(list, p) end
            end
        end
        if #list > 0 then
            local chosen = list[math.random(1, #list)]
            local targetHRP = chosen.Character:FindFirstChild("HumanoidRootPart") or chosen.Character:FindFirstChild("Torso") or chosen.Character.PrimaryPart
            if teleportToHRP(targetHRP) then notify("Teleported to random: " .. chosen.DisplayName, StudioTheme.green) end
        else notify("No alternative player found to teleport to", StudioTheme.red) end
    end)
    
    addSliderOption(drawer, "Freecam Speed", 10, 300, S.FreecamSpeed, function(v) S.FreecamSpeed = v; saveConfig() end)
    
    addToggleOption(drawer, "Freecam Active Mode", isFreecam, function(v) 
        isFreecam = v 
        if v then enableFreecam() else disableFreecam() end 
    end)
    
    local listContainer = addCustomFrameOption(drawer, 130)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -8, 0, 20)
    box.Position = UDim2.new(0, 4, 0, 2)
    box.BackgroundColor3 = StudioTheme.insetBg
    box.BorderSizePixel = 1
    box.BorderColor3 = StudioTheme.border
    box.Font = Enum.Font.SourceSans
    box.TextSize = 11
    box.TextColor3 = StudioTheme.text
    box.PlaceholderText = "Filter player list..."
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = listContainer

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -26)
    scroll.Position = UDim2.new(0, 4, 0, 24)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = listContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll
    
    local function renderPlayers()
        for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        local filter = box.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local formatted = p.DisplayName .. " (@" .. p.Name .. ")"
                if filter == "" or formatted:lower():find(filter) then
                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, -2, 0, 24)
                    card.BackgroundColor3 = StudioTheme.panelBg
                    card.BorderSizePixel = 1
                    card.BorderColor3 = StudioTheme.border
                    card.Parent = scroll

                    local nameL = Instance.new("TextLabel")
                    nameL.Size = UDim2.new(1, -78, 1, 0)
                    nameL.Position = UDim2.new(0, 6, 0, 0)
                    nameL.BackgroundTransparency = 1
                    nameL.Font = Enum.Font.SourceSansBold
                    nameL.TextSize = 11
                    nameL.TextColor3 = StudioTheme.text
                    nameL.TextXAlignment = Enum.TextXAlignment.Left
                    nameL.Text = p.DisplayName
                    nameL.Parent = card
                    
                    local tp = Instance.new("TextButton")
                    tp.Size = UDim2.new(0, 30, 0, 16)
                    tp.Position = UDim2.new(1, -76, 0.5, -8)
                    tp.BackgroundColor3 = StudioTheme.green
                    tp.BorderSizePixel = 1
                    tp.BorderColor3 = StudioTheme.border
                    tp.Font = Enum.Font.SourceSansBold
                    tp.TextSize = 10
                    tp.TextColor3 = Color3.fromRGB(255, 255, 255)
                    tp.Text = "TP"
                    tp.Parent = card
                    tp.MouseButton1Click:Connect(function()
                        local targetHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and teleportToHRP(targetHRP) then notify("Teleported to " .. p.DisplayName, StudioTheme.green) else notify("Target not loaded", StudioTheme.red) end
                    end)
                    
                    local isViewing = (currentSpectateTarget == p)
                    local view = Instance.new("TextButton")
                    view.Size = UDim2.new(0, 42, 0, 16)
                    view.Position = UDim2.new(1, -44, 0.5, -8)
                    view.BackgroundColor3 = isViewing and StudioTheme.red or StudioTheme.btnBg
                    view.BorderSizePixel = 1
                    view.BorderColor3 = StudioTheme.border
                    view.Font = Enum.Font.SourceSansBold
                    view.TextSize = 10
                    view.TextColor3 = Color3.fromRGB(255, 255, 255)
                    view.Text = isViewing and "UNVIEW" or "VIEW"
                    view.Parent = card
                    
                    view.MouseButton1Click:Connect(function() 
                        if currentSpectateTarget == p then 
                            spectatePlayer(nil) 
                            currentSpectateTarget = nil
                        else 
                            spectatePlayer(p) 
                            currentSpectateTarget = p
                        end
                        renderPlayers() 
                    end)
                end
            end
        end
    end
    
    box:GetPropertyChangedSignal("Text"):Connect(renderPlayers)
    
    local addedCon = Players.PlayerAdded:Connect(renderPlayers)
    local removedCon = Players.PlayerRemoving:Connect(function(p) 
        if currentSpectateTarget == p then 
            spectatePlayer(nil) 
            currentSpectateTarget = nil
        end
        renderPlayers() 
    end)
    
    table.insert(S.Connections, addedCon)
    table.insert(S.Connections, removedCon)
    renderPlayers()
end, true, 220, 300)
