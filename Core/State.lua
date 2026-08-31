local VH = _G.VoidHub
local State = {}

State.playerCards = {}
State.consoleLogs = {}
State.consoleLogsMap = {}
State.currentSpectateTarget = nil
State.spectateIndex = 1
State.uiVisible = true
State.isFreecam = false

State.freecamConnection = nil
State.freecamInputConn = nil
State.freecamInputBeganConn = nil
State.freecamInputEndedConn = nil
State.freecamBasePos = nil

State.originalAmbient = VH.Services.Lighting.Ambient
State.originalOutdoor = VH.Services.Lighting.OutdoorAmbient
State.originalClockTime = VH.Services.Lighting.ClockTime
State.uiRunning = true
State.teleportQueued = false
State.networkTagsLoopActive = false
State.wasClimbing = false
State.wasWallRunning = false

State.gameDefaultSpeed = nil
State.gameDefaultJumpPower = nil
State.gameDefaultUseJumpPower = nil

State.currentThemeColor = Color3.fromRGB(0, 122, 204)
State.currentThemeGradientColor = Color3.fromRGB(0, 90, 160)
State.networkTagsRunning = false
State.networkTagsPool = {}

State.animPresets = {
    "rbxassetid://507766666", "rbxassetid://3136051937", "rbxassetid://5554218935",
    "rbxassetid://4930450881", "rbxassetid://215384514", "rbxassetid://507768238"
}

State.visRaycastParams = RaycastParams.new()
State.visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
State.visRaycastParams.IgnoreWater = true

State.S = {
    WalkSpeed = 16, JumpPower = 50, InfJump = false, BHop = false, BHopAutoStrafe = false,
    AirWalk = false, NoClip = false, Fly = false, FlySpeed = 60, BlinkDistance = 25,
    BlinkDirection = "Camera Look", BlinkKey = Enum.KeyCode.Unknown,
    GhostMode = false, GhostCFrame = nil, GhostDummy = nil,
    ESPBoxes = false, ESPTracers = false, ESPNames = false, ESPHealth = false, ESPDistances = false,
    ESPTeamCheck = false, ESPIgnoreFriends = false, ESPTransparency = 0.8, ESPDistanceColor = false, SkeletonESP = false, Chams = false, ChamsColor = "Team Color", ESPBoxStyle = "Full",
    LineOfSight = false, LineOfSightTeamCheck = false, LineOfSightFriendCheck = false, LineOfSightLength = 30,
    UltraInstinct = false, UltraInstinctRadius = 12, UltraInstinctAntiClip = false, UltraInstinctSolidGround = false, UltraInstinctTeamCheck = false,
    OverheadInfo = false, OverheadTeamCheck = false, OverheadMaxDistance = 300,
    AimbotActive = false, AimbotTeamCheck = false, AimbotIgnoreFriends = false, AimbotFOV = 120, AimbotSmooth = 5, AimbotPart = "Head",
    AimbotVisibility = false, AimbotShowFOV = false, SilentAim = false, NoRecoil = false, TouchAura = false,
    AimlockActive = false, AimlockSmooth = 1.5,
    FlingTarget = nil, FlingActive = false, FlingAllActive = false, WalkFling = false,
    FollowTarget = nil, FollowActive = false,
    InstantPrompts = false, AntiVoid = false, AntiVoidY = -500,
    ToastEnabled = true, ToastChatEnabled = false, AutoReinject = true,
    AutoplayBot = false, AutoplayShoot = true, AutoplayReload = true, AutoplayRange = 150, AutoplayReloadInterval = 10, AutoplayTargetMode = "Closest", AutoplayTeamCheck = true, AutoplayFriendCheck = true, AutoplayPartRandomizer = "Head",
    Float = false, WaterWalk = false, TallAnim = false, Spin = false, SpinSpeed = 15,
    GravityEnabled = false, CustomGravity = 196.2, ForceWalkSpeed = false, ForceJumpPower = false,
    AntiAFK = false, GhostTeleportToEnd = false,
    GodMode = false, KillAura = false, KillAuraRange = 15, AutoClicker = false, AutoClickerDelay = 2, AutoClickerInterval = 0.1, AutoInteract = false,
    AutoInteractRadius = 15, ToolMagnet = false, AutoJump = false, SavedWaypointCF = nil, AntiFling = false,
    Climb = false, ClimbSpeed = 25, WallRun = false, FlyBypass = false, InstantRespawn = false,
    PathfindingWalk = false, CustomIdleAnim = false, CustomIdleID = "rbxassetid://507766666",
    JoinLeaveToasts = true, ServerAgeHUD = false,
    HideNametags = false, CustomNametag = false, CustomNametagText = "WeAreSkidding",
    RandomizeUIText = false, CustomUIText = "", UISpoofObjects = {}, SpoofConn = nil,
    SessionSpoofName = "Guest_" .. math.random(1000, 9999),
    MapXray = false, ClearVision = false, FullBright = false, TimeCycle = false, TimeCycleSpeed = 1,
    TimeOfDay = 14, CameraMaxZoom = 128, ViewModelFOV = 70,
    ClickDelete = false, CameraFOV = 70, ForceShiftLock = false, ESPColor = "Red", AntiAnchor = false,
    No3DRender = false, No3DRenderDisableCover = false, No3DRenderCustomCover = "", FPSCap = 144, ClickTeleport = false, SprintEnabled = false, SprintSpeed = 35,
    HeadSitActive = false, HeadSitTargetPlayer = nil, AirSwim = false, UIFont = "SourceSansSemibold", UIScale = 1.0,
    AntiSit = false, GraphicsReducer = false, AutoRejoin = false, NetworkChat = true, NetworkTags = true, ShowNetworkUsersHUD = true, ShowNetworkHeadTags = true, FreecamSpeed = 40, TracerOrigin = "Bottom",
    LagReducePotatoMode = true, LagReduceShadows = true, LagReduceDecals = true, LagReduceParticles = true, LagReduceEffects = true,
    FloatBody = nil, WaterPlat = nil, WaterRaycastParams = nil, TallWalkTrack = nil, TallIdleTrack = nil,
    CustomIdleTrack = nil, TallRunningConn = nil, GodModeConn = nil,
    OriginalPartTransparencies = {}, OriginalLightingEffects = {}, OriginalFogEnd = nil,
    Connections = {}, ChatConnections = {}, ESPPool = {}, OverheadPool = {}, AirWalkPlat = nil,
    LastSafePosition = CFrame.new(0, 50, 0), ChatHistory = {}, FavoriteMaps = {},
    FlyKey = Enum.KeyCode.Unknown, NoClipKey = Enum.KeyCode.Unknown, BHopKey = Enum.KeyCode.Unknown,
    InfJumpKey = Enum.KeyCode.Unknown, GhostKey = Enum.KeyCode.Unknown, BlinkKey = Enum.KeyCode.Unknown,
    JumpStrengthKey = Enum.KeyCode.Unknown,
    ThemeColor = "Studio Classic", ThemeGradientStyle = "Linear Gradient", ThemeGradientAngle = "Horizontal (0°)", CustomThemeHex = "#007ACC", GalaxyBgStyle = "Deep Space (Black)", GalaxyCustomBgHex = "#080810", TextAnimationStyle = "Static", HUDWatermark = true, HUDCoords = true, HUDArrayList = true, HUDArrayListOutside = true,
    MacroKey = Enum.KeyCode.Unknown, MacroText = "WeAreSkidding On Top!", UIToggleKey = Enum.KeyCode.RightControl,
    AimbotHoldMode = "M2", AimbotHoldKey = Enum.KeyCode.Unknown, HUDArrayListX = 10, HUDArrayListY = 70,
    TriggerbotActive = false, TriggerbotTeamCheck = true, TriggerbotIgnoreFriends = false, TriggerbotDelay = 0.05,
    PanicKey = Enum.KeyCode.End, UserIDGrabKey = Enum.KeyCode.K,
    EulaAccepted = false,
    currentOptionsModule = "",
    OutOfViewIndicators = false, OutOfViewIndicatorRadius = 200, OutOfViewTeamCheck = false, OutOfViewMaxDistance = 300, OutOfViewSize = 10,
    MinimapActive = false, MinimapKey = Enum.KeyCode.Unknown,
    AutoplayBotKey = Enum.KeyCode.Unknown,
    FirePromptsFilter = "", FirePromptsDistance = 500,
    FireCDFilter = "", FireCDDistance = 500,
    FireTouchinterestsActive = false, FireTouchFilter = "", FireTouchDistance = 100
}

State.serverStatsLabels = { region = nil, ping = nil, players = nil, age = nil }
State.rowRegion = { SetValue = function(self, val) if State.serverStatsLabels.region then State.serverStatsLabels.region.Text = tostring(val) end end }
State.rowPing = { SetValue = function(self, val) if State.serverStatsLabels.ping then State.serverStatsLabels.ping.Text = tostring(val) end end }
State.rowPlayers = { SetValue = function(self, val) if State.serverStatsLabels.players then State.serverStatsLabels.players.Text = tostring(val) end end }
State.rowAge = { SetValue = function(self, val) if State.serverStatsLabels.age then State.serverStatsLabels.age.Text = tostring(val) end end }

State.spectateStatsLabels = { name = nil, hp = nil, team = nil }
State.specNameRow = { 
    SetValue = function(self, val) if State.spectateStatsLabels.name then State.spectateStatsLabels.name.Text = tostring(val) end end, 
    SetColor = function(self, col) if State.spectateStatsLabels.name then State.spectateStatsLabels.name.TextColor3 = col end end 
}
State.specHpRow = { SetValue = function(self, val) if State.spectateStatsLabels.hp then State.spectateStatsLabels.hp.Text = tostring(val) end end }
State.specTeamRow = { SetValue = function(self, val) if State.spectateStatsLabels.team then State.spectateStatsLabels.team.Text = tostring(val) end end }

State.rowHomeFPS = { SetValue = function() end }
State.rowHomePing = { SetValue = function() end }
State.rowHomeRegion = { SetValue = function() end }

State.activeChatFeed = nil
State.rowHomeChatFeed = { AddEntry = function(self, text, color) if State.activeChatFeed then State.activeChatFeed:AddEntry(text, color) end end }
State.activeConsoleFeed = nil
State.rowConsoleFeed = {
    Clear = function(self) if State.activeConsoleFeed then State.activeConsoleFeed:Clear() end end,
    AddEntry = function(self, text, color) if State.activeConsoleFeed then State.activeConsoleFeed:AddEntry(text, color) end end
}

State.fpsCount, State.lastFpsTick, State.lastPingTick, State.pingVal = 0, tick(), tick(), 0
State.flingAllTarget, State.flingAllTime = nil, 0
State.lastCameraYaw = nil
State.lastAirVelocity = nil

State.updateGameDefaults = function(targetHum)
    pcall(function()
        local char = VH.Services.LP and VH.Services.LP.Character
        local hum = targetHum or (char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")))
        if hum then
            local S = State.S
            local isSpeedModified = S and (S.ForceWalkSpeed or S.TallAnim or S.SprintEnabled or S.BHop)
            local isJumpModified = S and (S.ForceJumpPower or S.TallAnim)

            if not isSpeedModified then
                State.gameDefaultSpeed = hum.WalkSpeed
                if S and (not S.WalkSpeed or S.WalkSpeed < hum.WalkSpeed) then
                    S.WalkSpeed = hum.WalkSpeed
                end
            end
            if not isJumpModified then
                State.gameDefaultJumpPower = hum.JumpPower
                State.gameDefaultUseJumpPower = hum.UseJumpPower
                if S and (not S.JumpPower or S.JumpPower < hum.JumpPower) then
                    S.JumpPower = hum.JumpPower
                end
            end
        end
    end)
end

pcall(function()
    if VH.Services.LP then
        local function bindHum(char)
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
            if hum then
                State.updateGameDefaults(hum)
                pcall(function()
                    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                        local S = State.S
                        local isSpeedModified = S and (S.ForceWalkSpeed or S.TallAnim or S.SprintEnabled or S.BHop)
                        if not isSpeedModified then
                            State.gameDefaultSpeed = hum.WalkSpeed
                            if State.S then
                                State.S.WalkSpeed = hum.WalkSpeed
                            end
                            if State.onGameSpeedChanged then
                                pcall(State.onGameSpeedChanged, hum.WalkSpeed)
                            end
                        end
                    end)
                    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                        local S = State.S
                        local isJumpModified = S and (S.ForceJumpPower or S.TallAnim)
                        if not isJumpModified then
                            State.gameDefaultJumpPower = hum.JumpPower
                            State.gameDefaultUseJumpPower = hum.UseJumpPower
                            if State.S then
                                State.S.JumpPower = hum.JumpPower
                            end
                            if State.onGameJumpChanged then
                                pcall(State.onGameJumpChanged, hum.JumpPower)
                            end
                        end
                    end)
                end)
            end
        end

        if VH.Services.LP.Character then
            bindHum(VH.Services.LP.Character)
        end
        VH.Services.LP.CharacterAdded:Connect(bindHum)
    end
end)

VH.State = State
return State

