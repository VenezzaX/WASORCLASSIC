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

registerModule("Player", "Spectate & Freecam", 160, 50, false, false, nil, function(drawer)
    local rName = addInfoRowOption(drawer, "Viewing Target Name", currentSpectateTarget and currentSpectateTarget.DisplayName or "--")
    local rHp = addInfoRowOption(drawer, "Target Health", "--"); local rTeam = addInfoRowOption(drawer, "Target Team", "--")
    spectateStatsLabels.name = rName.Label; spectateStatsLabels.hp = rHp.Label; spectateStatsLabels.team = rTeam.Label

    addToggleOption(drawer, "Auto Follow Player", S.FollowActive, function(v) S.FollowActive = v; S.FollowTarget = currentSpectateTarget; saveConfig() end)

    addButtonOption(drawer, "Teleport to Nearest Player", function()
        local myHRP = getHRP(); if not myHRP then notify("Self root part not found!", Color3.fromRGB(218, 38, 38)); return end
        local nearest, shortestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart
                if root then local dist = (root.Position - myHRP.Position).Magnitude; if dist < shortestDist then shortestDist = dist; nearest = p end end
            end
        end
        if nearest then
            local targetHRP = nearest.Character:FindFirstChild("HumanoidRootPart") or nearest.Character:FindFirstChild("Torso") or nearest.Character.PrimaryPart
            if teleportToHRP(targetHRP) then notify("Teleported to nearest: " .. nearest.DisplayName .. string.format(" (%.1f studs)", shortestDist), Color3.fromRGB(50, 195, 75)) end
        else notify("No other players found nearby", Color3.fromRGB(218, 38, 38)) end
    end)

    addButtonOption(drawer, "Teleport to Random Player", function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character.PrimaryPart; if root then table.insert(list, p) end end
        end
        if #list > 0 then
            local chosen = list[math.random(1, #list)]; local targetHRP = chosen.Character:FindFirstChild("HumanoidRootPart") or chosen.Character:FindFirstChild("Torso") or chosen.Character.PrimaryPart
            if teleportToHRP(targetHRP) then notify("Teleported to random: " .. chosen.DisplayName, Color3.fromRGB(50, 195, 75)) end
        else notify("No alternative player found to teleport to", Color3.fromRGB(218, 38, 38)) end
    end)

    addSliderOption(drawer, "Freecam Speed", 10, 300, S.FreecamSpeed, function(v) S.FreecamSpeed = v; saveConfig() end)

    addToggleOption(drawer, "Freecam Active Mode", isFreecam, function(v)
        isFreecam = v
        if v then enableFreecam() else disableFreecam() end
    end)

    local listContainer = addCustomFrameOption(drawer, 100)
    local box = Instance.new("TextBox"); box.Size = UDim2.new(1, -8, 0, 14); box.Position = UDim2.new(0, 4, 0, 0); box.BackgroundColor3 = Color3.fromRGB(30, 30, 30); box.BorderSizePixel = 0; box.Font = Enum.Font.Gotham; box.TextSize = 7; box.TextColor3 = Color3.fromRGB(240, 240, 240); box.PlaceholderText = "Filter player list..."; box.Text = ""; box.ClearTextOnFocus = false; box.Parent = listContainer
    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -8, 1, -16); scroll.Position = UDim2.new(0, 4, 0, 16); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 1; scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = listContainer
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 2); layout.Parent = scroll

    local function renderPlayers()
        for _, child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        local filter = box.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local formatted = p.DisplayName .. " (@" .. p.Name .. ")"
                if filter == "" or formatted:lower():find(filter) then
                    local card = Instance.new("Frame"); card.Size = UDim2.new(1, -2, 0, 16); card.BackgroundColor3 = Color3.fromRGB(25, 25, 25); card.BorderSizePixel = 0; card.Parent = scroll
                    local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(0.5, 0, 1, 0); nameL.Position = UDim2.new(0, 2, 0, 0); nameL.BackgroundTransparency = 1; nameL.Font = Enum.Font.GothamMedium; nameL.TextSize = 7; nameL.TextColor3 = Color3.fromRGB(220, 220, 220); nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.Text = p.DisplayName; nameL.Parent = card

                    local tp = Instance.new("TextButton"); tp.Size = UDim2.new(0, 20, 0, 12); tp.Position = UDim2.new(1, -44, 0.5, -6); tp.BackgroundColor3 = Color3.fromRGB(46, 204, 113); tp.BorderSizePixel = 0; tp.Font = Enum.Font.GothamBold; tp.TextSize = 6; tp.TextColor3 = Color3.fromRGB(255, 255, 255); tp.Text = "TP"; tp.Parent = card
                    tp.MouseButton1Click:Connect(function() local targetHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if targetHRP and teleportToHRP(targetHRP) then notify("Teleported to " .. p.DisplayName, Color3.fromRGB(50, 195, 75)) else notify("Target not loaded", Color3.fromRGB(218, 38, 38)) end end)

                    local view = Instance.new("TextButton"); view.Size = UDim2.new(0, 22, 0, 12); view.Position = UDim2.new(1, -22, 0.5, -6); local isViewing = (currentSpectateTarget == p); view.BackgroundColor3 = isViewing and Color3.fromRGB(218, 38, 38) or Color3.fromRGB(40, 40, 40); view.BorderSizePixel = 0; view.Font = Enum.Font.GothamBold; view.TextSize = 6; view.TextColor3 = Color3.fromRGB(255, 255, 255); view.Text = isViewing and "UNVIEW" or "VIEW"; view.Parent = card

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

    local addedCon = Players.PlayerAdded:Connect(renderPlayers);
    local removedCon = Players.PlayerRemoving:Connect(function(p)
        if currentSpectateTarget == p then
            spectatePlayer(nil)
            currentSpectateTarget = nil
        end
        renderPlayers()
    end)

    table.insert(S.Connections, addedCon); table.insert(S.Connections, removedCon); renderPlayers()
end, true, 200, 280)
