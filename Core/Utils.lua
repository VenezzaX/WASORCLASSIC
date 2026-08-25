local VH = _G.VoidHub
local Utils = {}

local Services = VH.Services
local State = VH.State


Utils.getChar = function() return Services.LP.Character end
Utils.getHRP = function() local c = Utils.getChar(); return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart) end
Utils.getHum = function() local c = Utils.getChar(); return c and c:FindFirstChildOfClass("Humanoid") end


Utils.notify = function(msg, color)
    if VH.UI and VH.UI.showToast then
        VH.UI.showToast(msg, color)
    else
        print("[WASOR] Notification:", tostring(msg))
    end
end


Utils.updateLocalNametag = function()
    local char = Services.LP.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    local bill = head:FindFirstChild("VoidCustomNametag")
    local S = State.S
    
    if S.CustomNametag then
        if not bill then
            bill = Instance.new("BillboardGui"); bill.Name = "VoidCustomNametag"; bill.Size = UDim2.new(0, 200, 0, 50)
            bill.StudsOffset = Vector3.new(0, 2.5, 0); bill.AlwaysOnTop = true; bill.Parent = head
            local lbl = Instance.new("TextLabel"); lbl.Name = "TextLabel"; lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0); lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = State.currentThemeColor
            lbl.TextSize = 24; lbl.TextStrokeTransparency = 0.5; lbl.Text = S.CustomNametagText or "WeAreSkidding"; lbl.Parent = bill
            lbl:GetPropertyChangedSignal("Text"):Connect(function()
                if S.CustomNametag and lbl.Text ~= S.CustomNametagText then lbl.Text = S.CustomNametagText or "WeAreSkidding" end
            end)
            bill.AncestryChanged:Connect(function(_, parent)
                if not parent and S.CustomNametag and char and char.Parent then
                    task.wait(0.1); if S.CustomNametag and head and head.Parent then bill.Parent = head end
                end
            end)
        else
            local lbl = bill:FindFirstChild("TextLabel")
            if lbl then 
                if lbl.Text ~= S.CustomNametagText then lbl.Text = S.CustomNametagText or "WeAreSkidding" end
                if lbl.TextColor3 ~= State.currentThemeColor then lbl.TextColor3 = State.currentThemeColor end
            end
        end
    else
        if bill then bill:Destroy() end
    end
end


Utils.processUISpoofText = function(obj)
    if not obj or not obj:IsA("Instance") then return end
    local S = State.S
    local txt = obj.Text
    if not txt or type(txt) ~= "string" or txt == "" then return end

    local newName = (S.CustomUIText and S.CustomUIText ~= "") and S.CustomUIText or S.SessionSpoofName or State.SessionSpoofName or "Guest_1337"
    local username = Services.LP.Name
    local displayName = Services.LP.DisplayName

    local result = txt

    local function replaceCaseInsensitive(str, target, replacement)
        if not target or target == "" then return str end
        local lowerStr = str:lower()
        local lowerTarget = target:lower()
        local searchStart = 1
        local buffer = ""
        local lastEnd = 1

        while true do
            local s, e = lowerStr:find(lowerTarget, searchStart, true)
            if not s then break end
            buffer = buffer .. str:sub(lastEnd, s - 1) .. replacement
            lastEnd = e + 1
            searchStart = e + 1
        end

        if lastEnd == 1 then
            return str
        else
            return buffer .. str:sub(lastEnd)
        end
    end

    if displayName and displayName ~= "" then
        result = replaceCaseInsensitive(result, displayName, newName)
    end
    if username and username ~= "" then
        result = replaceCaseInsensitive(result, username, newName)
    end

    if result ~= txt then
        obj.Text = result
    end
end


Utils.applyTallAnimations = function(char)
    local S = State.S
    local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
    if S.TallWalkTrack then S.TallWalkTrack:Stop() end; if S.TallIdleTrack then S.TallIdleTrack:Stop() end
    if S.TallRunningConn then S.TallRunningConn:Disconnect() end
    
    hum.WalkSpeed = 34; hum.UseJumpPower = true; hum.JumpPower = 75; hum.JumpHeight = 7.2
    local walkAnim = Instance.new("Animation"); walkAnim.AnimationId = "rbxassetid://128769966446762"
    S.TallWalkTrack = hum:LoadAnimation(walkAnim); S.TallWalkTrack.Looped = true
    local idleAnim = Instance.new("Animation"); idleAnim.AnimationId = "rbxassetid://87574253549013"
    S.TallIdleTrack = hum:LoadAnimation(idleAnim); S.TallIdleTrack.Looped = true
    
    S.TallRunningConn = hum.Running:Connect(function(speedVal)
        if speedVal > 0 then
            if S.TallIdleTrack then S.TallIdleTrack:Stop() end
            if S.TallWalkTrack and not S.TallWalkTrack.IsPlaying then S.TallWalkTrack:Play() end
        else
            if S.TallWalkTrack then S.TallWalkTrack:Stop() end
            if S.TallIdleTrack and not S.TallIdleTrack.IsPlaying then S.TallIdleTrack:Play() end
        end
    end)
    S.TallIdleTrack:Play()
end

Utils.revertTallAnimations = function(char)
    local S = State.S
    if not char then return end; local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if S.TallWalkTrack then S.TallWalkTrack:Stop() S.TallWalkTrack = nil end
    if S.TallIdleTrack then S.TallIdleTrack:Stop() S.TallIdleTrack = nil end
    if S.TallRunningConn then S.TallRunningConn:Disconnect() S.TallRunningConn = nil end
    local resetSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or State.gameDefaultSpeed or 16
    local resetJump = (S.ForceJumpPower and S.JumpPower) or State.gameDefaultJumpPower or 50
    local resetUseJump = S.ForceJumpPower and true or ((State.gameDefaultUseJumpPower ~= nil) and State.gameDefaultUseJumpPower or true)

    hum.WalkSpeed = resetSpeed
    hum.JumpPower = resetJump
    hum.UseJumpPower = resetUseJump
end

Utils.applyCustomIdle = function(char)
    local S = State.S
    if not char then return end; local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if S.CustomIdleTrack then S.CustomIdleTrack:Stop() S.CustomIdleTrack = nil end
    
    if S.CustomIdleAnim then
        local animId = S.CustomIdleID
        if not animId or animId == "" then animId = State.animPresets[math.random(1, #State.animPresets)]; S.CustomIdleID = animId end
        local anim = Instance.new("Animation"); anim.AnimationId = animId
        local success, track = pcall(function() return hum:LoadAnimation(anim) end)
        if success and track then
            S.CustomIdleTrack = track; S.CustomIdleTrack.Looped = true
            S.CustomIdleTrack.Priority = Enum.AnimationPriority.Idle; S.CustomIdleTrack:Play()
        else
            Utils.notify("Failed to load animation. Fallback applied.", Color3.fromRGB(218, 38, 38))
            S.CustomIdleID = "rbxassetid://507766666"
            local fallbackAnim = Instance.new("Animation"); fallbackAnim.AnimationId = S.CustomIdleID
            local fbSuccess, fbTrack = pcall(function() return hum:LoadAnimation(fallbackAnim) end)
            if fbSuccess and fbTrack then S.CustomIdleTrack = fbTrack; S.CustomIdleTrack.Looped = true; S.CustomIdleTrack.Priority = Enum.AnimationPriority.Idle; S.CustomIdleTrack:Play() end
        end
    end
end


Utils.applyGodMode = function(character)
    local S = State.S
    if not character then return end; local humanoid = character:WaitForChild("Humanoid", 3)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        if S.GodModeConn then S.GodModeConn:Disconnect() end
        S.GodModeConn = Services.RunService.Heartbeat:Connect(function()
            if humanoid and humanoid.Parent and humanoid.Health > 0 then humanoid.MaxHealth = math.huge; humanoid.Health = math.huge end
        end)
    end
end

Utils.disableGodMode = function()
    local S = State.S
    if S.GodModeConn then S.GodModeConn:Disconnect(); S.GodModeConn = nil end
    local char = Services.LP.Character; local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true); humanoid.MaxHealth = 100; humanoid.Health = 100 end
end


Utils.toggleFloat = function(v)
    local S = State.S
    S.Float = v; local char = Services.LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if v and hrp then
        if not S.FloatBody then
            S.FloatBody = Instance.new("BodyVelocity"); S.FloatBody.Name = "VoidFloatBody"
            S.FloatBody.Velocity = Vector3.new(0, 0, 0); S.FloatBody.MaxForce = Vector3.new(0, math.huge, 0); S.FloatBody.Parent = hrp
        end
    else
        if S.FloatBody then S.FloatBody:Destroy(); S.FloatBody = nil end
    end
end

Utils.toggleWaterWalk = function(v)
    local S = State.S
    S.WaterWalk = v
    if not v and S.WaterPlat then pcall(function() S.WaterPlat:Destroy() end); S.WaterPlat = nil end
end


Utils.toggleMapXray = function(v)
    local S = State.S
    S.MapXray = v
    if v then
        for _, part in ipairs(Services.Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Parent:FindFirstChildOfClass("Humanoid") and part.Name ~= "Terrain" then
                S.OriginalPartTransparencies[part] = part.Transparency; part.Transparency = 0.5
            end
        end
    else
        for part, trans in pairs(S.OriginalPartTransparencies) do
            if part and part.Parent then part.Transparency = trans end
        end
        S.OriginalPartTransparencies = {}
    end
end

Utils.toggleClearVision = function(v)
    local S = State.S
    S.ClearVision = v
    if v then
        if S.OriginalFogEnd == nil then S.OriginalFogEnd = Services.Lighting.FogEnd end
        Services.Lighting.FogEnd = 100000
        for _, descendant in ipairs(Services.Lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("DepthOfFieldEffect") or descendant:IsA("Atmosphere") or descendant:IsA("ColorCorrectionEffect") then
                pcall(function()
                    if S.OriginalLightingEffects[descendant] == nil then S.OriginalLightingEffects[descendant] = descendant.Enabled end
                    descendant.Enabled = false
                end)
            end
        end
    else
        if S.OriginalFogEnd ~= nil then Services.Lighting.FogEnd = S.OriginalFogEnd; S.OriginalFogEnd = nil end
        for descendant, originalEnabled in pairs(S.OriginalLightingEffects) do
            pcall(function() if descendant and descendant.Parent then descendant.Enabled = originalEnabled end end)
        end
        S.OriginalLightingEffects = {}
    end
end

Utils.isMouseOverHubUI = function()
    local UI = VH.UI
    local State = VH.State
    local Services = VH.Services
    if not State or not State.uiVisible then
        return false
    end
    if not UI or not UI.GetScreenGui then
        return false
    end
    local gui = UI.GetScreenGui()
    if not gui then
        return false
    end
    local UserInputService = Services.UserInputService
    if not UserInputService then
        return false
    end
    local mousePos = UserInputService:GetMouseLocation()
    local objects = {}
    pcall(function()
        objects = UserInputService:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
    end)
    for _, obj in ipairs(objects) do
        if obj:IsDescendantOf(gui) then
            return true
        end
    end
    return false
end

Utils.toggleGraphicsReducer = function(v)
    local S = State.S
    S.GraphicsReducer = v
    if v then
        pcall(function()
            for _, descendant in ipairs(Services.Workspace:GetDescendants()) do
                if descendant:IsA("BasePart") and S.LagReducePotatoMode then
                    descendant.Material = Enum.Material.SmoothPlastic
                elseif (descendant:IsA("Decal") or descendant:IsA("Texture")) and S.LagReduceDecals then
                    descendant.Transparency = 1
                elseif (descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles")) and S.LagReduceParticles then
                    descendant.Enabled = false
                end
            end
            if S.LagReduceShadows then
                Services.Lighting.GlobalShadows = false
            end
            if S.LagReduceEffects then
                for _, effect in ipairs(Services.Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                        effect.Enabled = false
                    end
                end
            end
        end)
    else
        pcall(function()
            Services.Lighting.GlobalShadows = true
            for _, descendant in ipairs(Services.Workspace:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Material = Enum.Material.Plastic
                elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                    descendant.Transparency = 0
                elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
                    descendant.Enabled = true
                end
            end
            for _, effect in ipairs(Services.Lighting:GetChildren()) do
                if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                    effect.Enabled = true
                end
            end
        end)
    end
end


local queue_on_teleport = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport) or queue_to_teleport or (fluxus and fluxus.queue_on_teleport)

Utils.setupAutoRejoin = function()
    local S = State.S
    if State.rejoinHooked then return end; State.rejoinHooked = true
    pcall(function()
        local conn = Services.GuiService.ErrorMessageChanged:Connect(function()
            local errMsg = ""
            pcall(function() errMsg = Services.GuiService:GetErrorMessage() end)
            if errMsg:lower():find("teleport") and not errMsg:lower():find("disconnected") then
                Utils.notify("[WASOR 3.2] Teleport message: " .. errMsg .. " (UI preserved)", Color3.fromRGB(218, 170, 42))
                return
            end
            pcall(function()
                if VH.Cleanup and VH.Cleanup.cleanupAll then
                    VH.Cleanup.cleanupAll()
                end
            end)
            if S.AutoRejoin then
                task.spawn(function()
                    task.wait(5)
                    pcall(function() Services.TeleportService:Teleport(game.PlaceId, Services.LP) end)
                end)
            end
        end)
        table.insert(S.Connections, conn)
    end)
    pcall(function()
        local tpFailConn = Services.TeleportService.TeleportInitFailed:Connect(function(_, result, err)
            Utils.notify("[WASOR 3.2] Teleport Failed: " .. tostring(err or result) .. " (UI preserved)", Color3.fromRGB(218, 38, 38))
        end)
        table.insert(S.Connections, tpFailConn)
    end)
end

Utils.setupAutoReinject = function()
    local S = State.S
    local code = [[ 
        repeat task.wait() until game:IsLoaded() 
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/MizunoSync/WASOR/main/github_loader.lua"))() 
        end)
        if not success then
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/MizunoSync/WASOR/main/WASOR_bundled.lua"))() 
            end)
        end
    ]]
    
    local qot = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport)
    if S.AutoReinject then
        if qot then 
            pcall(qot, code) 
        end
        if writefile then 
            pcall(writefile, "autoexec/WASOR.lua", code) 
        end
    else
        if writefile and isfile and isfile("autoexec/WASOR.lua") then
            pcall(delfile, "autoexec/WASOR.lua")
        end
    end
end

Utils.teleportToPlace = function(placeId)
    local S = State.S
    Utils.notify("Teleporting to Place " .. placeId .. "...", Color3.fromRGB(218, 170, 42)); Utils.setupAutoReinject()
    pcall(function() Services.TeleportService:Teleport(placeId, Services.LP) end)
end

Utils.robloxGet = function(url)
    local proxies = { "roproxy.com", "roproxy.link", "setup.roproxy.com" }
    if url:find("roblox%.com") then
        for _, proxy in ipairs(proxies) do
            local cleanUrl = url:gsub("roblox%.com", proxy)
            local ok, res = pcall(function() return game:HttpGet(cleanUrl) end)
            if ok and res and type(res) == "string" and res ~= "" then
                local low = res:lower()
                if not low:find("access denied") and not low:find("too many requests") then return res end
            end
        end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    return nil
end

local friendshipCache = {}
Utils.checkFriendship = function(userId)
    if friendshipCache[userId] ~= nil then return friendshipCache[userId] end
    local isFr = false; pcall(function() isFr = Services.LP:IsFriendsWith(userId) end)
    friendshipCache[userId] = isFr; return isFr
end

Utils.teleportToHRP = function(targetHRP)
    local myChar = Services.LP.Character; local myHRP = Utils.getHRP(); local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHRP and targetHRP then
        if myHum then myHum.Sit = false end
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0); myHRP.AssemblyLinearVelocity = Vector3.zero; return true
    end
    return false
end


Utils.spectatePlayer = function(target)
    State.currentSpectateTarget = target
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then Services.Camera.CameraType = Enum.CameraType.Watch; Services.Camera.CameraSubject = hum; return end
    end
    Services.Camera.CameraType = Enum.CameraType.Custom
    local myChar = Services.LP.Character; local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then Services.Camera.CameraSubject = myHum end
    State.currentSpectateTarget = nil
end

Utils.resetCameraToSelf = function() Utils.spectatePlayer(nil) end

Utils.enableFreecam = function()
    local S = State.S
    if State.isFreecam then return end; State.isFreecam = true
    local char = Services.LP.Character; local hrp = Utils.getHRP()
    if hrp then hrp.Anchored = true end
    Services.Camera.CameraType = Enum.CameraType.Scriptable; State.freecamBasePos = Services.Camera.CFrame
    local moveVector = Vector3.zero
    
    State.freecamInputBeganConn = Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end; local key = input.KeyCode
        if key == Enum.KeyCode.W then moveVector = moveVector + Vector3.new(0, 0, -1)
        elseif key == Enum.KeyCode.S then moveVector = moveVector + Vector3.new(0, 0, 1)
        elseif key == Enum.KeyCode.A then moveVector = moveVector + Vector3.new(-1, 0, 0)
        elseif key == Enum.KeyCode.D then moveVector = moveVector + Vector3.new(1, 0, 0)
        elseif key == Enum.KeyCode.Space then moveVector = moveVector + Vector3.new(0, 1, 0)
        elseif key == Enum.KeyCode.LeftShift then moveVector = moveVector + Vector3.new(0, -1, 0) end
    end)
    
    State.freecamInputEndedConn = Services.UserInputService.InputEnded:Connect(function(input)
        local key = input.KeyCode
        if key == Enum.KeyCode.W then moveVector = moveVector - Vector3.new(0, 0, -1)
        elseif key == Enum.KeyCode.S then moveVector = moveVector - Vector3.new(0, 0, 1)
        elseif key == Enum.KeyCode.A then moveVector = moveVector - Vector3.new(-1, 0, 0)
        elseif key == Enum.KeyCode.D then moveVector = moveVector - Vector3.new(1, 0, 0)
        elseif key == Enum.KeyCode.Space then moveVector = moveVector - Vector3.new(0, 1, 0)
        elseif key == Enum.KeyCode.LeftShift then moveVector = moveVector - Vector3.new(0, -1, 0) end
    end)
    
    State.freecamConnection = Services.RunService.RenderStepped:Connect(function(dt)
        if Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
        local cameraRot = Services.Camera.CFrame - Services.Camera.CFrame.Position
        local moveDir = cameraRot * moveVector
        if moveDir.Magnitude > 0 then State.freecamBasePos = State.freecamBasePos + moveDir.Unit * ((S.FreecamSpeed or 40) * dt) end
        Services.Camera.CFrame = CFrame.new(State.freecamBasePos.Position) * cameraRot
    end)
end

Utils.disableFreecam = function()
    if not State.isFreecam then return end; State.isFreecam = false
    if State.freecamConnection then State.freecamConnection:Disconnect(); State.freecamConnection = nil end
    if State.freecamInputBeganConn then State.freecamInputBeganConn:Disconnect(); State.freecamInputBeganConn = nil end
    if State.freecamInputEndedConn then State.freecamInputEndedConn:Disconnect(); State.freecamInputEndedConn = nil end
    Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default; Services.Camera.CameraType = Enum.CameraType.Custom
    local char = Services.LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then Services.Camera.CameraSubject = hum end
    local hrp = Utils.getHRP(); if hrp then hrp.Anchored = false end
end

Utils.serverHop = function(sortOrder)
    local S = State.S
    Utils.notify("Fetching servers list...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local placeId = game.PlaceId
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100", tostring(placeId), sortOrder or "Asc")
        local res = Utils.robloxGet(url)
        if res then
            local data = Services.HttpService:JSONDecode(res)
            if data and data.data then
                local possibleServers = {}
                for _, srv in ipairs(data.data) do
                    if srv.id ~= game.JobId and srv.playing and srv.playing < srv.maxPlayers then table.insert(possibleServers, srv) end
                end
                if #possibleServers > 0 then
                    local chosen = possibleServers[math.random(1, #possibleServers)]
                    Utils.notify("Found server! Teleporting...", Color3.fromRGB(50, 195, 75)); Utils.setupAutoReinject(); task.wait(0.5)
                    Services.TeleportService:TeleportToPlaceInstance(placeId, chosen.id, Services.LP)
                else Utils.notify("No suitable server found!", Color3.fromRGB(218, 38, 38)) end
            else Utils.notify("No server data in list!", Color3.fromRGB(218, 38, 38)) end
        else Utils.notify("Failed to query Roblox servers proxy!", Color3.fromRGB(218, 38, 38)) end
    end)
end

Utils.teleportToRandom = function() Utils.serverHop("Asc") end
Utils.teleportToLowestPop = function() Utils.serverHop("Asc") end
Utils.teleportToHighestPop = function() Utils.serverHop("Desc") end

Utils.runExternalScript = function(name, url, optionalPlaceId)
    if optionalPlaceId and game.PlaceId ~= optionalPlaceId then Utils.notify("This script requires PlaceId " .. tostring(optionalPlaceId), Color3.fromRGB(218, 38, 38)); return end
    Utils.notify("Loading script: " .. name .. "...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
        if ok then Utils.notify("Loaded " .. name .. " successfully!", Color3.fromRGB(50, 195, 75))
        else Utils.notify("Failed to load " .. name .. ": " .. tostring(err), Color3.fromRGB(218, 38, 38)) end
    end)
end


Utils.createOverhead = function(p) end
Utils.refreshOverheads = function() end


Utils.updateFlyVelocity = function()
    local S = State.S
    local hrp = Utils.getHRP(); if not hrp then return end
    local bv = hrp:FindFirstChild("VoidFlyBV"); local bg = hrp:FindFirstChild("VoidFlyBG")
    if not bv or not bg then return end
    pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
    local dir = Vector3.zero; local cf = Services.Camera.CFrame; local fwd = cf.LookVector
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + fwd end
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - fwd end
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
    bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * S.FlySpeed) or Vector3.zero; bg.CFrame = cf
end

Utils.flyOn = function()
    local char = Utils.getChar(); local hrp = Utils.getHRP(); local hum = Utils.getHum()
    if not char or not hrp or not hum then return end
    hum.PlatformStand = true
    pcall(function() if hrp:FindFirstChild("VoidFlyBV") then hrp.VoidFlyBV:Destroy() end; if hrp:FindFirstChild("VoidFlyBG") then hrp.VoidFlyBG:Destroy() end end)
    local bv = Instance.new("BodyVelocity"); bv.Name = "VoidFlyBV"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero; bv.Parent = hrp
    local bg = Instance.new("BodyGyro"); bg.Name = "VoidFlyBG"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.D = 100; bg.Parent = hrp
end

Utils.flyOff = function()
    local char = Utils.getChar(); local hrp = Utils.getHRP(); local hum = Utils.getHum()
    if hum then hum.PlatformStand = false end
    if hrp then pcall(function() if hrp:FindFirstChild("VoidFlyBV") then hrp.VoidFlyBV:Destroy() end; if hrp:FindFirstChild("VoidFlyBG") then hrp.VoidFlyBG:Destroy() end end) end
end


Utils.enableGhostMode = function()
    local S = State.S
    local myChar = Services.LP.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP then return end

    S.GhostParkedCFrame = myHRP.CFrame

    pcall(function()
        myChar.Archivable = true
        local clone = myChar:Clone()
        clone.Name = "GhostParkedBody"
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            elseif obj:IsA("BodyMover") or obj:IsA("Constraint") or obj:IsA("Attachment") then
                pcall(function() obj:Destroy() end)
            elseif obj:IsA("BasePart") then
                obj.Anchored = true
                pcall(function() obj.CanCollide = false end)
                pcall(function() obj.CanTouch = false end)
                pcall(function() obj.CanQuery = false end)
                obj.Transparency = 0.4
            elseif obj:IsA("Humanoid") then
                obj.PlatformStand = true
                pcall(function() obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
                pcall(function() obj.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end)
            end
        end
        clone.Parent = Services.Workspace
        S.GhostDummy = clone
    end)

    State.ghostOriginalTransparencies = {}
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            State.ghostOriginalTransparencies[part] = part.Transparency
            part.Transparency = 0.6
        elseif part:IsA("Decal") then
            State.ghostOriginalTransparencies[part] = part.Transparency
            part.Transparency = 0.6
        end
    end

    S.Fly = true
    Utils.flyOn()
    S.NoClip = true

    Utils.notify("Ghost Mode ON: Body parked, fly freely!", Color3.fromRGB(218, 170, 42))
end

Utils.disableGhostMode = function()
    local S = State.S
    local myChar = Services.LP.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)

    local ghostEndCF = myHRP and myHRP.CFrame

    if S.GhostDummy then
        pcall(function() S.GhostDummy:Destroy() end)
        S.GhostDummy = nil
    end

    if myHRP and (ghostEndCF or S.GhostParkedCFrame) then
        myHRP.CFrame = ghostEndCF or S.GhostParkedCFrame
        S.GhostParkedCFrame = nil
    end

    S.Fly = false
    Utils.flyOff()
    S.NoClip = false

    if myChar then
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if State.ghostOriginalTransparencies and State.ghostOriginalTransparencies[part] then
                    part.Transparency = State.ghostOriginalTransparencies[part]
                else
                    part.Transparency = 0
                end
            elseif part:IsA("Decal") then
                if State.ghostOriginalTransparencies and State.ghostOriginalTransparencies[part] then
                    part.Transparency = State.ghostOriginalTransparencies[part]
                else
                    part.Transparency = 0
                end
            end
        end
        State.ghostOriginalTransparencies = nil
    end

    Utils.notify("Ghost Mode OFF: Teleported to ghost location!", Color3.fromRGB(50, 195, 75))
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        if State.ghostOriginalDisplayNameType then
            myHum.DisplayDistanceType = State.ghostOriginalDisplayNameType
        else
            myHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        end
        State.ghostOriginalDisplayNameType = nil
    end
    S.Fly = false; Utils.flyOff(); S.NoClip = false
end


local visRaycastParams = RaycastParams.new()
visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
visRaycastParams.IgnoreWater = true

Utils.isPartVisible = function(part, char)
    if not part then return false end
    local origin = Services.Camera.CFrame.Position; local destination = part.Position; local direction = destination - origin
    if direction.Magnitude == 0 then return true end
    visRaycastParams.FilterDescendantsInstances = {Services.LP.Character, char}
    local result = Services.Workspace:Raycast(origin, direction, visRaycastParams); return result == nil
end

Utils.getAimbotTargetPart = function(char)
    local S = State.S
    if S.AimbotPart == "Head" then return char:FindFirstChild("Head")
    elseif S.AimbotPart == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif S.AimbotPart == "Random" then
        local parts = {}; local head = char:FindFirstChild("Head"); local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if head then table.insert(parts, head) end; if torso then table.insert(parts, torso) end
        if #parts > 0 then return parts[math.random(1, #parts)] end
    end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

Utils.getAimbotTarget = function()
    local S = State.S
    local bestTarget = nil; local closestDist = S.AimbotFOV; local center = Vector2.new(Services.Camera.ViewportSize.X / 2, Services.Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p == Services.LP then continue end
        if S.AimbotTeamCheck and p.Team == Services.LP.Team then continue end
        if S.AimbotIgnoreFriends and Utils.checkFriendship(p.UserId) then continue end
        local char = p.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then continue end
        local part = Utils.getAimbotTargetPart(char); if not part then continue end
        if S.AimbotVisibility and not Utils.isPartVisible(part, char) then continue end
        local sp, onScreen = Services.Camera:WorldToViewportPoint(part.Position); if not onScreen then continue end
        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < closestDist then closestDist = dist; bestTarget = part end
    end
    return bestTarget
end

Utils.getBoundingBox = function(char)
    local hrp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"); if not hrp then return nil end
    local hrPos = hrp.Position
    local topSp, topOnScreen = Services.Camera:WorldToViewportPoint(hrPos + Vector3.new(0, 3, 0))
    if topSp.Z <= 0 then return nil end
    local botSp = Services.Camera:WorldToViewportPoint(hrPos - Vector3.new(0, 3.5, 0))
    local height = math.abs(topSp.Y - botSp.Y); local width = height * 0.6
    return { Vector2.new(topSp.X - width/2, topSp.Y), Vector2.new(topSp.X + width/2, botSp.Y) }
end

Utils.toggleNo3DRenderCover = function(enable)
    local S = State.S
    local CoreGui = Services.CoreGui or Services.LP:WaitForChild("PlayerGui")

    if not enable then
        pcall(function() Services.RunService:Set3dRenderingEnabled(true) end)
        if State.no3DCoverGui then
            pcall(function() State.no3DCoverGui:Destroy() end)
            State.no3DCoverGui = nil
        end
        return
    end

    pcall(function() Services.RunService:Set3dRenderingEnabled(false) end)

    if State.no3DCoverGui then
        pcall(function() State.no3DCoverGui:Destroy() end)
        State.no3DCoverGui = nil
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VoidNo3DCoverGui"
    gui.DisplayOrder = -100
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "BlackBackground"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.Position = UDim2.new(0, 0, 0, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = gui

    if not S.No3DRenderDisableCover then
        local rawAssetId = (S.No3DRenderCustomCover and S.No3DRenderCustomCover ~= "") and S.No3DRenderCustomCover or "6723684726"
        local assetId = rawAssetId:match("%d+") or "6723684726"
        local imgLabel = Instance.new("ImageLabel")
        imgLabel.Name = "CoverImage"
        imgLabel.Size = UDim2.new(1, 0, 1, 0)
        imgLabel.Position = UDim2.new(0, 0, 0, 0)
        imgLabel.BackgroundTransparency = 1
        imgLabel.Image = "rbxassetid://" .. assetId
        imgLabel.ScaleType = Enum.ScaleType.Fit
        imgLabel.Parent = bgFrame
    end

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 1, -40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 13
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    statusLabel.Text = "3D Rendering Paused (No 3D Rendering)"
    statusLabel.Parent = bgFrame

    pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)

    State.no3DCoverGui = gui
end

VH.Utils = Utils
return Utils
