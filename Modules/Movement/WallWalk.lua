local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addKeybindOption = UI.addKeybindOption
local saveConfig = VH.Config.saveConfig

local Players = Services.Players or game:GetService("Players")
local RunService = Services.RunService or game:GetService("RunService")
local UserInputService = Services.UserInputService or game:GetService("UserInputService")
local TweenService = Services.TweenService or game:GetService("TweenService")
local GuiService = Services.GuiService or game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local VRService = game:GetService("VRService")
local Workspace = Services.Workspace or game:GetService("Workspace")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local LocalPlayer = Services.LP or Players.LocalPlayer
while not LocalPlayer do
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

if VH.WallWalkCleanup then
    pcall(VH.WallWalkCleanup)
elseif getgenv and getgenv()._WallWalkCleanup then
    pcall(getgenv()._WallWalkCleanup)
elseif _G._WallWalkCleanup then
    pcall(_G._WallWalkCleanup)
end

local function _CameraUI()
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

	local TOAST_OPEN_SIZE = UDim2.new(0, 326, 0, 58)
	local TOAST_CLOSED_SIZE = UDim2.new(0, 80, 0, 58)
	local TOAST_BACKGROUND_COLOR = Color3.fromRGB(32, 32, 32)
	local TOAST_BACKGROUND_TRANS = 0.4
	local TOAST_FOREGROUND_COLOR = Color3.fromRGB(200, 200, 200)
	local TOAST_FOREGROUND_TRANS = 0

	local function create(className)
		return function(props)
			local inst = Instance.new(className)
			local parent = props.Parent
			props.Parent = nil
			for name, val in pairs(props) do
				if type(name) == "string" then
					inst[name] = val
				else
					val.Parent = inst
				end
			end
			inst.Parent = parent
			return inst
		end
	end

	local initialized = false
	local uiRoot, toast, toastIcon, toastUpperText, toastLowerText

	local function initializeUI()
		if initialized then return end
		local old = PlayerGui:FindFirstChild("RbxCameraUI")
		if old then old:Destroy() end

		uiRoot = create("ScreenGui"){
			Name = "RbxCameraUI",
			AutoLocalize = false,
			Enabled = true,
			DisplayOrder = -1,
			IgnoreGuiInset = false,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

			create("ImageLabel"){
				Name = "Toast",
				Visible = false,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0, 8),
				Size = TOAST_CLOSED_SIZE,
				Image = "rbxasset://textures/ui/Camera/CameraToast9Slice.png",
				ImageColor3 = TOAST_BACKGROUND_COLOR,
				ImageRectSize = Vector2.new(6, 6),
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(3, 3, 3, 3),
				ClipsDescendants = true,

				create("Frame"){
					Name = "IconBuffer",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 80, 1, 0),

					create("ImageLabel"){
						Name = "Icon",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(0, 48, 0, 48),
						ZIndex = 2,
						Image = "rbxasset://textures/ui/Camera/CameraToastIcon.png",
						ImageColor3 = TOAST_FOREGROUND_COLOR,
						ImageTransparency = 1,
					}
				},

				create("Frame"){
					Name = "TextBuffer",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 80, 0, 0),
					Size = UDim2.new(1, -80, 1, 0),
					ClipsDescendants = true,

					create("TextLabel"){
						Name = "Upper",
						AnchorPoint = Vector2.new(0, 1),
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(1, 0, 0, 19),
						Font = Enum.Font.GothamSemibold,
						Text = "Camera control enabled",
						TextColor3 = TOAST_FOREGROUND_COLOR,
						TextTransparency = 1,
						TextSize = 19,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},

					create("TextLabel"){
						Name = "Lower",
						AnchorPoint = Vector2.new(0, 0),
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0.5, 3),
						Size = UDim2.new(1, 0, 0, 15),
						Font = Enum.Font.Gotham,
						Text = "Right mouse button to toggle",
						TextColor3 = TOAST_FOREGROUND_COLOR,
						TextTransparency = 1,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					},
				},
			},

			Parent = PlayerGui,
		}

		toast = uiRoot.Toast
		toastIcon = toast.IconBuffer.Icon
		toastUpperText = toast.TextBuffer.Upper
		toastLowerText = toast.TextBuffer.Lower
		initialized = true
	end

	local CameraUI = {}
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	function CameraUI.setCameraModeToastOpen(open)
		if not initialized then return end
		TweenService:Create(toast, tweenInfo, {
			Size = open and TOAST_OPEN_SIZE or TOAST_CLOSED_SIZE,
			ImageTransparency = open and TOAST_BACKGROUND_TRANS or 1,
		}):Play()
		TweenService:Create(toastIcon, tweenInfo, {
			ImageTransparency = open and TOAST_FOREGROUND_TRANS or 1,
		}):Play()
		TweenService:Create(toastUpperText, tweenInfo, {
			TextTransparency = open and TOAST_FOREGROUND_TRANS or 1,
		}):Play()
		TweenService:Create(toastLowerText, tweenInfo, {
			TextTransparency = open and TOAST_FOREGROUND_TRANS or 1,
		}):Play()
	end

	function CameraUI.setCameraModeToastEnabled(enabled)
		if not enabled and not initialized then
			return
		end
		if not initialized then
			initializeUI()
		end
		toast.Visible = enabled
		if not enabled then
			CameraUI.setCameraModeToastOpen(false)
		end
	end

	return CameraUI
end

local SharedCameraInput
local function _CameraInput()
	if SharedCameraInput then return SharedCameraInput end

	local MB_TAP_LENGTH = 0.3
	local rmbDownBindable = Instance.new("BindableEvent")
	local rmbUpBindable = Instance.new("BindableEvent")

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
			rmbDownBindable:Fire()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			rmbUpBindable:Fire()
		end
	end)

	local holdPan = false
	local togglePan = false
	local lastRmbDown = 0
	local cameraToggleInputEnabled = false
	local rmbDownConnection, rmbUpConnection

	local CameraInput = {}
	function CameraInput.getHoldPan() return holdPan end
	function CameraInput.getTogglePan() return togglePan end
	function CameraInput.getPanning() return togglePan or holdPan end
	function CameraInput.setTogglePan(value) togglePan = value end

	function CameraInput.enableCameraToggleInput()
		if cameraToggleInputEnabled then return end
		cameraToggleInputEnabled = true
		holdPan = false
		togglePan = false

		if rmbDownConnection then rmbDownConnection:Disconnect() end
		if rmbUpConnection then rmbUpConnection:Disconnect() end

		rmbDownConnection = rmbDownBindable.Event:Connect(function()
			holdPan = true
			lastRmbDown = tick()
		end)

		rmbUpConnection = rmbUpBindable.Event:Connect(function()
			holdPan = false
			if tick() - lastRmbDown < MB_TAP_LENGTH and (togglePan or UserInputService:GetMouseDelta().Magnitude < 2) then
				togglePan = not togglePan
			end
		end)
	end

	function CameraInput.disableCameraToggleInput()
		if not cameraToggleInputEnabled then return end
		cameraToggleInputEnabled = false
		if rmbDownConnection then rmbDownConnection:Disconnect() rmbDownConnection = nil end
		if rmbUpConnection then rmbUpConnection:Disconnect() rmbUpConnection = nil end
	end

	SharedCameraInput = CameraInput
	return CameraInput
end

local SharedCameraUtils
local function _CameraUtils()
	if SharedCameraUtils then return SharedCameraUtils end

	local CameraUtils = {}
	local FFlagUserCameraToggle do
		local success, result = pcall(function()
			return UserSettings():IsUserFeatureEnabled("UserCameraToggle")
		end)
		FFlagUserCameraToggle = success and result
	end

	local function round(num)
		return math.floor(num + 0.5)
	end

	local Spring = {}
	Spring.__index = Spring

	function Spring.new(freq, pos)
		return setmetatable({
			freq = freq,
			goal = pos,
			pos = pos,
			vel = 0,
		}, Spring)
	end

	function Spring:step(dt)
		local f = self.freq * 2 * math.pi
		local g = self.goal
		local p0 = self.pos
		local v0 = self.vel

		local offset = p0 - g
		local decay = math.exp(-f * dt)

		local p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
		local v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay

		self.pos = p1
		self.vel = v1
		return p1
	end

	CameraUtils.Spring = Spring

	function CameraUtils.map(x, inMin, inMax, outMin, outMax)
		return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
	end

	function CameraUtils.Round(num, places)
		local decimalPivot = 10 ^ places
		return math.floor(num * decimalPivot + 0.5) / decimalPivot
	end

	function CameraUtils.IsFinite(val)
		return val == val and val ~= math.huge and val ~= -math.huge
	end

	function CameraUtils.IsFiniteVector3(vec3)
		return CameraUtils.IsFinite(vec3.X) and CameraUtils.IsFinite(vec3.Y) and CameraUtils.IsFinite(vec3.Z)
	end

	function CameraUtils.GetAngleBetweenXZVectors(v1, v2)
		return math.atan2(v2.X * v1.Z - v2.Z * v1.X, v2.X * v1.X + v2.Z * v1.Z)
	end

	function CameraUtils.RotateVectorByAngleAndRound(camLook, rotateAngle, roundAmount)
		if camLook.Magnitude > 0 then
			camLook = camLook.Unit
			local currAngle = math.atan2(camLook.Z, camLook.X)
			local newAngle = round((currAngle + rotateAngle) / roundAmount) * roundAmount
			return newAngle - currAngle
		end
		return 0
	end

	local k = 0.35
	local lowerK = 0.8
	local function SCurveTranform(t)
		t = math.clamp(t, -1, 1)
		if t >= 0 then
			return (k * t) / (k - t + 1)
		end
		return -((lowerK * -t) / (lowerK + t + 1))
	end

	local DEADZONE = 0.1
	local function toSCurveSpace(t)
		return (1 + DEADZONE) * (2 * math.abs(t) - 1) - DEADZONE
	end
	local function fromSCurveSpace(t)
		return t / 2 + 0.5
	end

	function CameraUtils.GamepadLinearToCurve(thumbstickPosition)
		local function onAxis(axisValue)
			local sign = axisValue < 0 and -1 or 1
			local point = fromSCurveSpace(SCurveTranform(toSCurveSpace(math.abs(axisValue)))) * sign
			return math.clamp(point, -1, 1)
		end
		return Vector2.new(onAxis(thumbstickPosition.X), onAxis(thumbstickPosition.Y))
	end

	function CameraUtils.ConvertCameraModeEnumToStandard(enumValue)
		if enumValue == Enum.TouchCameraMovementMode.Default then
			return Enum.ComputerCameraMovementMode.Follow
		end
		if enumValue == Enum.ComputerCameraMovementMode.Default then
			return Enum.ComputerCameraMovementMode.Classic
		end
		if enumValue == Enum.TouchCameraMovementMode.Classic or
			enumValue == Enum.DevTouchCameraMovementMode.Classic or
			enumValue == Enum.DevComputerCameraMovementMode.Classic or
			enumValue == Enum.ComputerCameraMovementMode.Classic then
			return Enum.ComputerCameraMovementMode.Classic
		end
		if enumValue == Enum.TouchCameraMovementMode.Follow or
			enumValue == Enum.DevTouchCameraMovementMode.Follow or
			enumValue == Enum.DevComputerCameraMovementMode.Follow or
			enumValue == Enum.ComputerCameraMovementMode.Follow then
			return Enum.ComputerCameraMovementMode.Follow
		end
		if enumValue == Enum.TouchCameraMovementMode.Orbital or
			enumValue == Enum.DevTouchCameraMovementMode.Orbital or
			enumValue == Enum.DevComputerCameraMovementMode.Orbital or
			enumValue == Enum.ComputerCameraMovementMode.Orbital then
			return Enum.ComputerCameraMovementMode.Orbital
		end
		if FFlagUserCameraToggle then
			if enumValue == Enum.ComputerCameraMovementMode.CameraToggle or
				enumValue == Enum.DevComputerCameraMovementMode.CameraToggle then
				return Enum.ComputerCameraMovementMode.CameraToggle
			end
		end
		if enumValue == Enum.DevTouchCameraMovementMode.UserChoice or
			enumValue == Enum.DevComputerCameraMovementMode.UserChoice then
			return Enum.DevComputerCameraMovementMode.UserChoice
		end
		return Enum.ComputerCameraMovementMode.Classic
	end

	SharedCameraUtils = CameraUtils
	return CameraUtils
end

local function _CameraToggleStateController()
	local Mouse = LocalPlayer:GetMouse()
	local Input = _CameraInput()
	local CameraUI = _CameraUI()

	local lastTogglePan = false
	local lastTogglePanChange = tick()
	local CROSS_MOUSE_ICON = "rbxasset://textures/Cursors/CrossMouseIcon.png"
	local lockStateDirty = false
	local wasTogglePanOnTheLastTimeYouWentIntoFirstPerson = false
	local lastFirstPerson = false

	CameraUI.setCameraModeToastEnabled(false)

	return function(isFirstPerson, isMouseLocked, wallWalkActive)
		local togglePan = Input.getTogglePan()
		local toastTimeout = 3

		if isFirstPerson and togglePan ~= lastTogglePan then
			lockStateDirty = true
		end

		if lastTogglePan ~= togglePan or tick() - lastTogglePanChange > toastTimeout then
			local doShow = togglePan and tick() - lastTogglePanChange < toastTimeout
			CameraUI.setCameraModeToastOpen(doShow)
			if togglePan then
				lockStateDirty = false
			end
			lastTogglePanChange = tick()
			lastTogglePan = togglePan
		end

		if isFirstPerson ~= lastFirstPerson then
			if isFirstPerson then
				wasTogglePanOnTheLastTimeYouWentIntoFirstPerson = Input.getTogglePan()
				Input.setTogglePan(true)
			elseif not lockStateDirty then
				Input.setTogglePan(wasTogglePanOnTheLastTimeYouWentIntoFirstPerson)
			end
		end

		if isMouseLocked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserGameSettings.RotationType = wallWalkActive and Enum.RotationType.MovementRelative or Enum.RotationType.CameraRelative
		elseif isFirstPerson then
			UserGameSettings.RotationType = wallWalkActive and Enum.RotationType.MovementRelative or Enum.RotationType.CameraRelative
			if Input.getTogglePan() then
				Mouse.Icon = CROSS_MOUSE_ICON
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			else
				Mouse.Icon = ""
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
		elseif Input.getTogglePan() then
			Mouse.Icon = CROSS_MOUSE_ICON
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserGameSettings.RotationType = Enum.RotationType.MovementRelative
		elseif Input.getHoldPan() then
			Mouse.Icon = ""
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			UserGameSettings.RotationType = Enum.RotationType.MovementRelative
		else
			Mouse.Icon = ""
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserGameSettings.RotationType = Enum.RotationType.MovementRelative
		end

		lastFirstPerson = isFirstPerson
	end
end

local function _Popper()
	local camera = Workspace.CurrentCamera
	local min = math.min
	local tan = math.tan
	local rad = math.rad
	local inf = math.huge
	local ray = Ray.new

	local function getTotalTransparency(part)
		return 1 - (1 - part.Transparency) * (1 - part.LocalTransparencyModifier)
	end

	local function eraseFromEnd(t, toSize)
		for i = #t, toSize + 1, -1 do
			t[i] = nil
		end
	end

	local nearPlaneZ, projX, projY = 0.1, 1, 1
	local fovConn, viewConn, nearConn

	local function bindCameraSignals(cam)
		if fovConn then fovConn:Disconnect() end
		if viewConn then viewConn:Disconnect() end
		if nearConn then nearConn:Disconnect() end
		if not cam then return end

		local function updateProjection()
			local fov = rad(cam.FieldOfView)
			local view = cam.ViewportSize
			local ar = view.Y > 0 and (view.X / view.Y) or 1.77
			projY = 2 * tan(fov / 2)
			projX = ar * projY
		end

		fovConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(updateProjection)
		viewConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateProjection)
		updateProjection()

		nearPlaneZ = cam.NearPlaneZ
		nearConn = cam:GetPropertyChangedSignal("NearPlaneZ"):Connect(function()
			nearPlaneZ = cam.NearPlaneZ
		end)
	end

	bindCameraSignals(camera)

	local blacklist = {} do
		local charMap = {}
		local function refreshIgnoreList()
			local n = 1
			blacklist = {}
			for _, character in pairs(charMap) do
				blacklist[n] = character
				n = n + 1
			end
		end

		local function playerAdded(player)
			local function characterAdded(character)
				charMap[player] = character
				refreshIgnoreList()
			end
			local function characterRemoving()
				charMap[player] = nil
				refreshIgnoreList()
			end
			player.CharacterAdded:Connect(characterAdded)
			player.CharacterRemoving:Connect(characterRemoving)
			if player.Character then
				characterAdded(player.Character)
			end
		end

		Players.PlayerAdded:Connect(playerAdded)
		Players.PlayerRemoving:Connect(function(player)
			charMap[player] = nil
			refreshIgnoreList()
		end)
		for _, player in ipairs(Players:GetPlayers()) do
			playerAdded(player)
		end
		refreshIgnoreList()
	end

	local subjectRoot, subjectPart
	local subjectConn

	local function bindSubject(cam)
		if subjectConn then subjectConn:Disconnect() end
		if not cam then return end
		local function updateSub()
			local subject = cam.CameraSubject
			if subject and subject:IsA("Humanoid") then
				subjectPart = subject.RootPart
			elseif subject and subject:IsA("BasePart") then
				subjectPart = subject
			else
				subjectPart = nil
			end
		end
		subjectConn = cam:GetPropertyChangedSignal("CameraSubject"):Connect(updateSub)
		updateSub()
	end

	bindSubject(camera)
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera
		bindCameraSignals(camera)
		bindSubject(camera)
	end)

	local function canOcclude(part)
		return
			getTotalTransparency(part) < 0.25 and
			part.CanCollide and
			subjectRoot ~= (part:GetRootPart() or part) and
			not part:IsA("TrussPart")
	end

	local SCAN_SAMPLE_OFFSETS = {
		Vector2.new( 0.4, 0.0),
		Vector2.new(-0.4, 0.0),
		Vector2.new( 0.0,-0.4),
		Vector2.new( 0.0, 0.4),
		Vector2.new( 0.0, 0.2),
	}

	local function getCollisionPoint(origin, dir)
		local originalSize = #blacklist
		repeat
			local hitPart, hitPoint = Workspace:FindPartOnRayWithIgnoreList(
				ray(origin, dir), blacklist, false, true
			)
			if hitPart then
				if hitPart.CanCollide then
					eraseFromEnd(blacklist, originalSize)
					return hitPoint, true
				end
				blacklist[#blacklist + 1] = hitPart
			end
		until not hitPart

		eraseFromEnd(blacklist, originalSize)
		return origin + dir, false
	end

	local function queryPoint(origin, unitDir, dist, lastPos)
		local originalSize = #blacklist
		dist = dist + nearPlaneZ
		local target = origin + unitDir * dist

		local softLimit = inf
		local hardLimit = inf
		local movingOrigin = origin

		repeat
			local entryPart, entryPos = Workspace:FindPartOnRayWithIgnoreList(ray(movingOrigin, target - movingOrigin), blacklist, false, true)
			if entryPart then
				if canOcclude(entryPart) then
					local wl = {entryPart}
					local exitPart = Workspace:FindPartOnRayWithWhitelist(ray(target, entryPos - target), wl, true)
					local lim = (entryPos - origin).Magnitude

					if exitPart then
						local promote = false
						if lastPos then
							promote =
								Workspace:FindPartOnRayWithWhitelist(ray(lastPos, target - lastPos), wl, true) or
								Workspace:FindPartOnRayWithWhitelist(ray(target, lastPos - target), wl, true)
						end
						if promote then
							hardLimit = lim
						elseif dist < softLimit then
							softLimit = lim
						end
					else
						hardLimit = lim
					end
				end

				blacklist[#blacklist + 1] = entryPart
				movingOrigin = entryPos - unitDir * 1e-3
			end
		until hardLimit < inf or not entryPart

		eraseFromEnd(blacklist, originalSize)
		return softLimit - nearPlaneZ, hardLimit - nearPlaneZ
	end

	local function queryViewport(focus, dist)
		local fP = focus.Position
		local fX = focus.RightVector
		local fY = focus.UpVector
		local fZ = -focus.LookVector
		local viewport = camera.ViewportSize

		local hardBoxLimit = inf
		local softBoxLimit = inf

		for viewX = 0, 1 do
			local worldX = fX * ((viewX - 0.5) * projX)
			for viewY = 0, 1 do
				local worldY = fY * ((viewY - 0.5) * projY)
				local origin = fP + nearPlaneZ * (worldX + worldY)
				local lastPos = camera:ViewportPointToRay(viewport.X * viewX, viewport.Y * viewY).Origin
				local softPointLimit, hardPointLimit = queryPoint(origin, fZ, dist, lastPos)

				if hardPointLimit < hardBoxLimit then hardBoxLimit = hardPointLimit end
				if softPointLimit < softBoxLimit then softBoxLimit = softPointLimit end
			end
		end

		return softBoxLimit, hardBoxLimit
	end

	local function testPromotion(focus, dist, focusExtrapolation)
		local fP = focus.Position
		local fX = focus.RightVector
		local fY = focus.UpVector
		local fZ = -focus.LookVector

		local SAMPLE_DT = 0.0625
		local SAMPLE_MAX_T = 1.25
		local maxDist = (getCollisionPoint(fP, focusExtrapolation.posVelocity * SAMPLE_MAX_T) - fP).Magnitude
		local combinedSpeed = focusExtrapolation.posVelocity.Magnitude

		if combinedSpeed > 1e-3 then
			for dt = 0, min(SAMPLE_MAX_T, focusExtrapolation.rotVelocity.Magnitude + maxDist / combinedSpeed), SAMPLE_DT do
				local cfDt = focusExtrapolation.extrapolate(dt)
				if queryPoint(cfDt.Position, -cfDt.LookVector, dist) >= dist then
					return false
				end
			end
		end

		for _, offset in ipairs(SCAN_SAMPLE_OFFSETS) do
			local pos = getCollisionPoint(fP, fX * offset.X + fY * offset.Y)
			local dir = fP + fZ * dist - pos
			if dir.Magnitude > 1e-4 and queryPoint(pos, dir.Unit, dist) == inf then
				return false
			end
		end

		return true
	end

	return function(focus, targetDist, focusExtrapolation)
		if not camera then return targetDist end
		subjectRoot = subjectPart and subjectPart:GetRootPart() or subjectPart

		local dist = targetDist
		local soft, hard = queryViewport(focus, targetDist)
		if hard < dist then dist = hard end
		if soft < dist and testPromotion(focus, targetDist, focusExtrapolation) then
			dist = soft
		end

		subjectRoot = nil
		return math.max(0.5, dist)
	end
end

local SharedZoomController
local function _ZoomController()
	if SharedZoomController then return SharedZoomController end

	local ZOOM_STIFFNESS = 5.2
	local ZOOM_DEFAULT = 12.5
	local ZOOM_ACCELERATION = 0.0375
	local MIN_FOCUS_DIST = 0.5
	local DIST_OPAQUE = 1

	local Popper = _Popper()
	local clamp = math.clamp
	local exp = math.exp
	local min = math.min
	local max = math.max
	local pi = math.pi

	local cameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance
	local cameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance

	local function updateBounds()
		cameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance
		cameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance
	end
	LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(updateBounds)
	LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(updateBounds)

	local ConstrainedSpring = {}
	ConstrainedSpring.__index = ConstrainedSpring

	function ConstrainedSpring.new(freq, x, minValue, maxValue)
		x = clamp(x, minValue, maxValue)
		return setmetatable({
			freq = freq,
			x = x,
			v = 0,
			minValue = minValue,
			maxValue = maxValue,
			goal = x,
		}, ConstrainedSpring)
	end

	function ConstrainedSpring:Step(dt)
		local freq = self.freq * 2 * pi
		local x = self.x
		local v = self.v
		local minValue = self.minValue
		local maxValue = self.maxValue
		local goal = self.goal

		local offset = goal - x
		local step = freq * dt
		local decay = exp(-step)

		local x1 = goal + (v * dt - offset * (step + 1)) * decay
		local v1 = ((offset * freq - v) * step + v) * decay

		if x1 < minValue then
			x1 = minValue
			v1 = 0
		elseif x1 > maxValue then
			x1 = maxValue
			v1 = 0
		end

		self.x = x1
		self.v = v1
		return x1
	end

	local zoomSpring = ConstrainedSpring.new(ZOOM_STIFFNESS, ZOOM_DEFAULT, MIN_FOCUS_DIST, cameraMaxZoomDistance)
	local zoomDelta = 0

	local function stepTargetZoom(z, dz, zoomMin, zoomMax)
		z = clamp(z + dz * (1 + z * ZOOM_ACCELERATION), zoomMin, zoomMax)
		if z < DIST_OPAQUE then
			z = dz <= 0 and zoomMin or DIST_OPAQUE
		end
		return z
	end

	local Zoom = {}
	function Zoom.Update(renderDt, focus, extrapolation)
		local poppedZoom = math.huge
		if zoomSpring.goal > DIST_OPAQUE then
			local maxPossibleZoom = max(
				zoomSpring.x,
				stepTargetZoom(zoomSpring.goal, zoomDelta, cameraMinZoomDistance, cameraMaxZoomDistance)
			)
			poppedZoom = Popper(
				focus * CFrame.new(0, 0, MIN_FOCUS_DIST),
				maxPossibleZoom - MIN_FOCUS_DIST,
				extrapolation
			) + MIN_FOCUS_DIST
		end

		zoomSpring.minValue = MIN_FOCUS_DIST
		zoomSpring.maxValue = min(cameraMaxZoomDistance, poppedZoom)
		return zoomSpring:Step(renderDt)
	end

	function Zoom.SetZoomParameters(targetZoom, newZoomDelta)
		zoomSpring.goal = targetZoom
		zoomDelta = newZoomDelta
	end

	SharedZoomController = Zoom
	return Zoom
end

local function _BaseCamera()
	local UNIT_Z = Vector3.new(0, 0, 1)
	local X1_Y0_Z1 = Vector3.new(1, 0, 1)
	local THUMBSTICK_DEADZONE = 0.2
	local DEFAULT_DISTANCE = 12.5
	local PORTRAIT_DEFAULT_DISTANCE = 25
	local FIRST_PERSON_DISTANCE_THRESHOLD = 1.0
	local CAMERA_ACTION_PRIORITY = Enum.ContextActionPriority.Default.Value

	local MIN_Y = math.rad(-84)
	local MAX_Y = math.rad(84)

	local VR_ANGLE = math.rad(15)
	local ZERO_VECTOR2 = Vector2.new(0, 0)
	local ZERO_VECTOR3 = Vector3.new(0, 0, 0)

	local TOUCH_SENSITIVTY = Vector2.new(0.00945 * math.pi, 0.003375 * math.pi)
	local MOUSE_SENSITIVITY = Vector2.new(0.002 * math.pi, 0.0015 * math.pi)

	local SEAT_OFFSET = Vector3.new(0, 5, 0)
	local VR_SEAT_OFFSET = Vector3.new(0, 4, 0)
	local HEAD_OFFSET = Vector3.new(0, 1.5, 0)
	local R15_HEAD_OFFSET = Vector3.new(0, 1.5, 0)
	local R15_HEAD_OFFSET_NO_SCALING = Vector3.new(0, 2, 0)
	local HUMANOID_ROOT_PART_SIZE = Vector3.new(2, 2, 1)

	local GAMEPAD_ZOOM_STEP_1 = 0
	local GAMEPAD_ZOOM_STEP_2 = 10
	local GAMEPAD_ZOOM_STEP_3 = 20
	local PAN_SENSITIVITY = 20
	local ZOOM_SENSITIVITY_CURVATURE = 0.5

	local abs = math.abs

	local FFlagUserCameraToggle do
		local success, result = pcall(function() return UserSettings():IsUserFeatureEnabled("UserCameraToggle") end)
		FFlagUserCameraToggle = success and result
	end
	local FFlagUserDontAdjustSensitvityForPortrait do
		local success, result = pcall(function() return UserSettings():IsUserFeatureEnabled("UserDontAdjustSensitvityForPortrait") end)
		FFlagUserDontAdjustSensitvityForPortrait = success and result
	end
	local FFlagUserFixZoomInZoomOutDiscrepancy do
		local success, result = pcall(function() return UserSettings():IsUserFeatureEnabled("UserFixZoomInZoomOutDiscrepancy") end)
		FFlagUserFixZoomInZoomOutDiscrepancy = success and result
	end

	local Util = _CameraUtils()
	local ZoomController = _ZoomController()
	local CameraToggleStateController = _CameraToggleStateController()
	local CameraInput = _CameraInput()
	local CameraUI = _CameraUI()

	local BaseCamera = {}
	BaseCamera.__index = BaseCamera
	BaseCamera.UpCFrame = CFrame.new()

	function BaseCamera.new()
		local self = setmetatable({}, BaseCamera)
		self.FIRST_PERSON_DISTANCE_THRESHOLD = FIRST_PERSON_DISTANCE_THRESHOLD
		self.cameraType = nil
		self.cameraMovementMode = nil
		self.lastCameraTransform = nil
		self.rotateInput = ZERO_VECTOR2
		self.userPanningCamera = false
		self.lastUserPanCamera = tick()
		self.humanoidRootPart = nil
		self.humanoidCache = {}
		self.lastSubject = nil
		self.lastSubjectPosition = Vector3.new(0, 5, 0)
		self.defaultSubjectDistance = math.clamp(DEFAULT_DISTANCE, LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance)
		self.currentSubjectDistance = math.clamp(DEFAULT_DISTANCE, LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance)
		self.inFirstPerson = false
		self.inMouseLockedMode = false
		self.wallWalkActive = START_ENABLED
		self.portraitMode = false
		self.isSmallTouchScreen = false
		self.resetCameraAngle = false
		self.enabled = false
		self.panEnabled = true
		self.keyPanEnabled = true
		self.distanceChangeEnabled = true
		self.boundContextActions = {}
		self.activeGamepad = nil
		self.gamepadPanningCamera = ZERO_VECTOR2
		self.lastThumbstickRotate = nil
		self.numOfSeconds = 0.7
		self.currentSpeed = 0
		self.maxSpeed = 6
		self.vrMaxSpeed = 4
		self.lastThumbstickPos = ZERO_VECTOR2
		self.ySensitivity = 0.65
		self.lastVelocity = nil
		self.currentZoomSpeed = 1.0
		self.isDynamicThumbstickEnabled = false
		self.fingerTouches = {}
		self.dynamicTouchInput = nil
		self.numUnsunkTouches = 0
		self.inputStartPositions = {}
		self.inputStartTimes = {}
		self.startingDiff = nil
		self.pinchBeginZoom = nil
		self.userPanningTheCamera = false
		self.mouseLockOffset = Vector3.new(1.75, 0, 0)
		self.UpCFrame = CFrame.new()

		if LocalPlayer.Character then
			self:OnCharacterAdded(LocalPlayer.Character)
		end
		LocalPlayer.CharacterAdded:Connect(function(char)
			self:OnCharacterAdded(char)
		end)

		self.cameraChangedConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			self:OnCurrentCameraChanged()
		end)
		self:OnCurrentCameraChanged()

		LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(function() self:OnPlayerCameraPropertyChange() end)
		LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function() self:OnPlayerCameraPropertyChange() end)
		LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function() self:OnPlayerCameraPropertyChange() end)
		LocalPlayer:GetPropertyChangedSignal("DevTouchMovementMode"):Connect(function() self:OnDevTouchMovementModeChanged() end)
		self:OnDevTouchMovementModeChanged()

		UserGameSettings:GetPropertyChangedSignal("TouchMovementMode"):Connect(function() self:OnGameSettingsTouchMovementModeChanged() end)
		self:OnGameSettingsTouchMovementModeChanged()

		UserGameSettings:SetCameraYInvertVisible()
		UserGameSettings:SetGamepadCameraSensitivityVisible()

		self.hasGameLoaded = game:IsLoaded()
		if not self.hasGameLoaded then
			self.gameLoadedConn = game.Loaded:Connect(function()
				self.hasGameLoaded = true
				self.gameLoadedConn:Disconnect()
				self.gameLoadedConn = nil
			end)
		end

		self:OnPlayerCameraPropertyChange()
		return self
	end

	function BaseCamera:UpdateUpCFrame(cf)
		self.UpCFrame = cf
	end

	function BaseCamera:SetWallWalkActive(active)
		self.wallWalkActive = active
		self:UpdateMouseBehavior()
	end

	function BaseCamera:GetModuleName()
		return "BaseCamera"
	end

	function BaseCamera:OnCharacterAdded(char)
		self.resetCameraAngle = false
		self.humanoidRootPart = nil
		if UserInputService.TouchEnabled then
			self.PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Tool") then self.isAToolEquipped = true end
			end
			char.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then self.isAToolEquipped = true end
			end)
			char.ChildRemoved:Connect(function(child)
				if child:IsA("Tool") then self.isAToolEquipped = false end
			end)
		end
	end

	function BaseCamera:GetHumanoidRootPart()
		if not self.humanoidRootPart and LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				self.humanoidRootPart = humanoid.RootPart
			end
		end
		return self.humanoidRootPart
	end

	function BaseCamera:GetSubjectPosition()
		local result = self.lastSubjectPosition
		local camera = Workspace.CurrentCamera
		local cameraSubject = camera and camera.CameraSubject

		if cameraSubject then
			if cameraSubject:IsA("Humanoid") then
				local humanoid = cameraSubject
				local humanoidIsDead = humanoid:GetState() == Enum.HumanoidStateType.Dead

				if VRService.VREnabled and humanoidIsDead and humanoid == self.lastSubject then
					result = self.lastSubjectPosition
				else
					local bodyPartToFollow = humanoid.RootPart
					if humanoidIsDead and humanoid.Parent and humanoid.Parent:IsA("Model") then
						bodyPartToFollow = humanoid.Parent:FindFirstChild("Head") or bodyPartToFollow
					end

					if bodyPartToFollow and bodyPartToFollow:IsA("BasePart") then
						local heightOffset
						if humanoid.RigType == Enum.HumanoidRigType.R15 then
							if humanoid.AutomaticScalingEnabled then
								heightOffset = R15_HEAD_OFFSET
								if bodyPartToFollow == humanoid.RootPart then
									local rootPartSizeOffset = (humanoid.RootPart.Size.Y / 2) - (HUMANOID_ROOT_PART_SIZE.Y / 2)
									heightOffset = heightOffset + Vector3.new(0, rootPartSizeOffset, 0)
								end
							else
								heightOffset = R15_HEAD_OFFSET_NO_SCALING
							end
						else
							heightOffset = HEAD_OFFSET
						end

						if humanoidIsDead then
							heightOffset = ZERO_VECTOR3
						end

						result = bodyPartToFollow.Position + bodyPartToFollow.CFrame:VectorToWorldSpace(heightOffset + humanoid.CameraOffset)
					end
				end
			elseif cameraSubject:IsA("VehicleSeat") then
				local offset = VRService.VREnabled and VR_SEAT_OFFSET or SEAT_OFFSET
				result = cameraSubject.Position + cameraSubject.CFrame:VectorToWorldSpace(offset)
			elseif cameraSubject:IsA("SkateboardPlatform") then
				result = cameraSubject.Position + SEAT_OFFSET
			elseif cameraSubject:IsA("BasePart") then
				result = cameraSubject.Position
			elseif cameraSubject:IsA("Model") then
				if cameraSubject.PrimaryPart then
					result = cameraSubject:GetPrimaryPartCFrame().Position
				else
					result = cameraSubject:GetModelCFrame().Position
				end
			end
		else
			return self.lastSubjectPosition
		end

		self.lastSubject = cameraSubject
		self.lastSubjectPosition = result
		return result
	end

	function BaseCamera:UpdateDefaultSubjectDistance()
		if self.portraitMode then
			self.defaultSubjectDistance = math.clamp(PORTRAIT_DEFAULT_DISTANCE, LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance)
		else
			self.defaultSubjectDistance = math.clamp(DEFAULT_DISTANCE, LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance)
		end
	end

	function BaseCamera:OnViewportSizeChanged()
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local size = camera.ViewportSize
		self.portraitMode = size.X < size.Y
		self.isSmallTouchScreen = UserInputService.TouchEnabled and (size.Y < 500 or size.X < 700)
		self:UpdateDefaultSubjectDistance()
	end

	function BaseCamera:OnCurrentCameraChanged()
		if UserInputService.TouchEnabled then
			if self.viewportSizeChangedConn then
				self.viewportSizeChangedConn:Disconnect()
				self.viewportSizeChangedConn = nil
			end
			local newCamera = Workspace.CurrentCamera
			if newCamera then
				self:OnViewportSizeChanged()
				self.viewportSizeChangedConn = newCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					self:OnViewportSizeChanged()
				end)
			end
		end
	end

	function BaseCamera:OnDynamicThumbstickEnabled()
		if UserInputService.TouchEnabled then
			self.isDynamicThumbstickEnabled = true
		end
	end

	function BaseCamera:OnDynamicThumbstickDisabled()
		self.isDynamicThumbstickEnabled = false
	end

	function BaseCamera:OnGameSettingsTouchMovementModeChanged()
		if LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice then
			if (UserGameSettings.TouchMovementMode == Enum.TouchMovementMode.DynamicThumbstick
				or UserGameSettings.TouchMovementMode == Enum.TouchMovementMode.Default) then
				self:OnDynamicThumbstickEnabled()
			else
				self:OnDynamicThumbstickDisabled()
			end
		end
	end

	function BaseCamera:OnDevTouchMovementModeChanged()
		if LocalPlayer.DevTouchMovementMode.Name == "DynamicThumbstick" then
			self:OnDynamicThumbstickEnabled()
		else
			self:OnGameSettingsTouchMovementModeChanged()
		end
	end

	function BaseCamera:OnPlayerCameraPropertyChange()
		self:SetCameraToSubjectDistance(self.currentSubjectDistance)
	end

	function BaseCamera:GetCameraHeight()
		if VRService.VREnabled and not self.inFirstPerson then
			return math.sin(VR_ANGLE) * self.currentSubjectDistance
		end
		return 0
	end

	function BaseCamera:InputTranslationToCameraAngleChange(translationVector, sensitivity)
		if not FFlagUserDontAdjustSensitvityForPortrait then
			local camera = Workspace.CurrentCamera
			if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 and (camera.ViewportSize.Y > camera.ViewportSize.X) then
				return translationVector * Vector2.new(sensitivity.Y, sensitivity.X)
			end
		end
		return translationVector * sensitivity
	end

	function BaseCamera:Enable(enable)
		if self.enabled ~= enable then
			self.enabled = enable
			if self.enabled then
				self:ConnectInputEvents()
				self:BindContextActions()
				if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
					self.currentSubjectDistance = 0.5
					if not self.inFirstPerson then
						self:EnterFirstPerson()
					end
				end
			else
				self:DisconnectInputEvents()
				self:UnbindContextActions()
				self:Cleanup()
			end
		end
	end

	function BaseCamera:GetEnabled() return self.enabled end

	function BaseCamera:OnInputBegan(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchBegan(input, processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:OnMouse2Down(input, processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self:OnMouse3Down(input, processed)
		end
	end

	function BaseCamera:OnInputChanged(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchChanged(input, processed)
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			self:OnMouseMoved(input, processed)
		end
	end

	function BaseCamera:OnInputEnded(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self:OnTouchEnded(input, processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:OnMouse2Up(input, processed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self:OnMouse3Up(input, processed)
		end
	end

	function BaseCamera:OnPointerAction(wheel, pan, pinch, processed)
		if processed then return end
		if pan.Magnitude > 0 then
			local inversionVector = Vector2.new(1, UserGameSettings:GetCameraYInvertValue())
			local rotateDelta = self:InputTranslationToCameraAngleChange(PAN_SENSITIVITY * pan, MOUSE_SENSITIVITY) * inversionVector
			self.rotateInput = self.rotateInput + rotateDelta
		end

		local zoom = self.currentSubjectDistance
		local zoomDelta = -(wheel + pinch)
		if abs(zoomDelta) > 0 then
			local newZoom
			if self.inFirstPerson and zoomDelta > 0 then
				newZoom = FIRST_PERSON_DISTANCE_THRESHOLD
			else
				if FFlagUserFixZoomInZoomOutDiscrepancy then
					if zoomDelta > 0 then
						newZoom = zoom + zoomDelta * (1 + zoom * ZOOM_SENSITIVITY_CURVATURE)
					else
						newZoom = (zoom + zoomDelta) / (1 - zoomDelta * ZOOM_SENSITIVITY_CURVATURE)
					end
				else
					newZoom = zoom + zoomDelta * (1 + zoom * ZOOM_SENSITIVITY_CURVATURE)
				end
			end
			self:SetCameraToSubjectDistance(newZoom)
		end
	end

	function BaseCamera:ConnectInputEvents()
		self.pointerActionConn = UserInputService.PointerAction:Connect(function(wheel, pan, pinch, processed)
			self:OnPointerAction(wheel, pan, pinch, processed)
		end)
		self.inputBeganConn = UserInputService.InputBegan:Connect(function(input, processed) self:OnInputBegan(input, processed) end)
		self.inputChangedConn = UserInputService.InputChanged:Connect(function(input, processed) self:OnInputChanged(input, processed) end)
		self.inputEndedConn = UserInputService.InputEnded:Connect(function(input, processed) self:OnInputEnded(input, processed) end)
		self.menuOpenedConn = GuiService.MenuOpened:Connect(function() self:ResetInputStates() end)
		self.gamepadConnectedConn = UserInputService.GamepadDisconnected:Connect(function(gamepadEnum)
			if self.activeGamepad ~= gamepadEnum then return end
			self.activeGamepad = nil
			self:AssignActivateGamepad()
		end)
		self.gamepadDisconnectedConn = UserInputService.GamepadConnected:Connect(function()
			if self.activeGamepad == nil then
				self:AssignActivateGamepad()
			end
		end)
		self:AssignActivateGamepad()
		self:UpdateMouseBehavior()
	end

	function BaseCamera:BindContextActions()
		self:BindGamepadInputActions()
		self:BindKeyboardInputActions()
	end

	function BaseCamera:AssignActivateGamepad()
		local connectedGamepads = UserInputService:GetConnectedGamepads()
		if #connectedGamepads > 0 then
			for i = 1, #connectedGamepads do
				if self.activeGamepad == nil or connectedGamepads[i].Value < self.activeGamepad.Value then
					self.activeGamepad = connectedGamepads[i]
				end
			end
		end
		if self.activeGamepad == nil then
			self.activeGamepad = Enum.UserInputType.Gamepad1
		end
	end

	function BaseCamera:DisconnectInputEvents()
		if self.inputBeganConn then self.inputBeganConn:Disconnect() self.inputBeganConn = nil end
		if self.inputChangedConn then self.inputChangedConn:Disconnect() self.inputChangedConn = nil end
		if self.inputEndedConn then self.inputEndedConn:Disconnect() self.inputEndedConn = nil end
	end

	function BaseCamera:UnbindContextActions()
		for i = 1, #self.boundContextActions do
			ContextActionService:UnbindAction(self.boundContextActions[i])
		end
		self.boundContextActions = {}
	end

	function BaseCamera:Cleanup()
		if self.pointerActionConn then self.pointerActionConn:Disconnect() self.pointerActionConn = nil end
		if self.menuOpenedConn then self.menuOpenedConn:Disconnect() self.menuOpenedConn = nil end
		if self.gamepadConnectedConn then self.gamepadConnectedConn:Disconnect() self.gamepadConnectedConn = nil end
		if self.gamepadDisconnectedConn then self.gamepadDisconnectedConn:Disconnect() self.gamepadDisconnectedConn = nil end
		if self.viewportSizeChangedConn then self.viewportSizeChangedConn:Disconnect() self.viewportSizeChangedConn = nil end

		self.turningLeft = false
		self.turningRight = false
		self.lastCameraTransform = nil
		self.lastSubjectCFrame = nil
		self.userPanningTheCamera = false
		self.rotateInput = ZERO_VECTOR2
		self.gamepadPanningCamera = ZERO_VECTOR2
		self.startPos = nil
		self.lastPos = nil
		self.panBeginLook = nil
		self.isRightMouseDown = false
		self.isMiddleMouseDown = false
		self.fingerTouches = {}
		self.dynamicTouchInput = nil
		self.numUnsunkTouches = 0
		self.startingDiff = nil
		self.pinchBeginZoom = nil

		if not self.inMouseLockedMode and not self.inFirstPerson then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	function BaseCamera:ResetInputStates()
		self.isRightMouseDown = false
		self.isMiddleMouseDown = false
		self:OnMousePanButtonReleased()
		if UserInputService.TouchEnabled then
			self.fingerTouches = {}
			self.dynamicTouchInput = nil
			self.panBeginLook = nil
			self.startPos = nil
			self.lastPos = nil
			self.userPanningTheCamera = false
			self.startingDiff = nil
			self.pinchBeginZoom = nil
			self.numUnsunkTouches = 0
		end
	end

	function BaseCamera:GetGamepadPan(name, state, input)
		if input.UserInputType == self.activeGamepad and input.KeyCode == Enum.KeyCode.Thumbstick2 then
			if state == Enum.UserInputState.Cancel then
				self.gamepadPanningCamera = ZERO_VECTOR2
				return Enum.ContextActionResult.Sink
			end
			local inputVector = Vector2.new(input.Position.X, -input.Position.Y)
			if inputVector.Magnitude > THUMBSTICK_DEADZONE then
				self.gamepadPanningCamera = inputVector
			else
				self.gamepadPanningCamera = ZERO_VECTOR2
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	function BaseCamera:DoKeyboardPanTurn(name, state, input)
		if not self.hasGameLoaded and VRService.VREnabled then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Cancel then
			self.turningLeft = false
			self.turningRight = false
			return Enum.ContextActionResult.Sink
		end
		if self.panBeginLook == nil and self.keyPanEnabled then
			if input.KeyCode == Enum.KeyCode.Left then
				self.turningLeft = state == Enum.UserInputState.Begin
			elseif input.KeyCode == Enum.KeyCode.Right then
				self.turningRight = state == Enum.UserInputState.Begin
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	function BaseCamera:DoGamepadZoom(name, state, input)
		if input.UserInputType == self.activeGamepad then
			if input.KeyCode == Enum.KeyCode.ButtonR3 and state == Enum.UserInputState.Begin and self.distanceChangeEnabled then
				local dist = self:GetCameraToSubjectDistance()
				if dist > (GAMEPAD_ZOOM_STEP_2 + GAMEPAD_ZOOM_STEP_3) / 2 then
					self:SetCameraToSubjectDistance(GAMEPAD_ZOOM_STEP_2)
				elseif dist > (GAMEPAD_ZOOM_STEP_1 + GAMEPAD_ZOOM_STEP_2) / 2 then
					self:SetCameraToSubjectDistance(GAMEPAD_ZOOM_STEP_1)
				else
					self:SetCameraToSubjectDistance(GAMEPAD_ZOOM_STEP_3)
				end
			elseif input.KeyCode == Enum.KeyCode.DPadLeft then
				self.dpadLeftDown = (state == Enum.UserInputState.Begin)
			elseif input.KeyCode == Enum.KeyCode.DPadRight then
				self.dpadRightDown = (state == Enum.UserInputState.Begin)
			end
			if self.dpadLeftDown then
				self.currentZoomSpeed = 1.04
			elseif self.dpadRightDown then
				self.currentZoomSpeed = 0.96
			else
				self.currentZoomSpeed = 1.00
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	function BaseCamera:DoKeyboardZoom(name, state, input)
		if (not self.hasGameLoaded and VRService.VREnabled) or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if self.distanceChangeEnabled and LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then
			if input.KeyCode == Enum.KeyCode.I then
				self:SetCameraToSubjectDistance(self.currentSubjectDistance - 5)
			elseif input.KeyCode == Enum.KeyCode.O then
				self:SetCameraToSubjectDistance(self.currentSubjectDistance + 5)
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	function BaseCamera:BindAction(actionName, actionFunc, createTouchButton, ...)
		table.insert(self.boundContextActions, actionName)
		ContextActionService:BindActionAtPriority(actionName, actionFunc, createTouchButton, CAMERA_ACTION_PRIORITY, ...)
	end

	function BaseCamera:BindGamepadInputActions()
		self:BindAction("BaseCameraGamepadPan", function(n, s, i) return self:GetGamepadPan(n, s, i) end, false, Enum.KeyCode.Thumbstick2)
		self:BindAction("BaseCameraGamepadZoom", function(n, s, i) return self:DoGamepadZoom(n, s, i) end, false, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.ButtonR3)
	end

	function BaseCamera:BindKeyboardInputActions()
		self:BindAction("BaseCameraKeyboardPanArrowKeys", function(n, s, i) return self:DoKeyboardPanTurn(n, s, i) end, false, Enum.KeyCode.Left, Enum.KeyCode.Right)
		self:BindAction("BaseCameraKeyboardZoom", function(n, s, i) return self:DoKeyboardZoom(n, s, i) end, false, Enum.KeyCode.I, Enum.KeyCode.O)
	end

	local function isInDynamicThumbstickArea(input)
		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
		local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
		local thumbstickFrame = touchFrame and touchFrame:FindFirstChild("DynamicThumbstickFrame")
		if not thumbstickFrame then return false end

		local topLeft = thumbstickFrame.AbsolutePosition
		local bottomRight = topLeft + thumbstickFrame.AbsoluteSize
		return input.Position.X >= topLeft.X and input.Position.Y >= topLeft.Y
			and input.Position.X <= bottomRight.X and input.Position.Y <= bottomRight.Y
	end

	function BaseCamera:OnTouchBegan(input, processed)
		if self.isDynamicThumbstickEnabled and not processed then
			if self.dynamicTouchInput == nil and isInDynamicThumbstickArea(input) then
				self.dynamicTouchInput = input
				return
			end
			self.fingerTouches[input] = processed
			self.inputStartPositions[input] = input.Position
			self.inputStartTimes[input] = tick()
			self.numUnsunkTouches = self.numUnsunkTouches + 1
		end
	end

	function BaseCamera:OnTouchChanged(input, processed)
		if self.fingerTouches[input] == nil then
			if self.isDynamicThumbstickEnabled then return end
			self.fingerTouches[input] = processed
			if not processed then
				self.numUnsunkTouches = self.numUnsunkTouches + 1
			end
		end

		if self.numUnsunkTouches == 1 and self.fingerTouches[input] == false then
			self.panBeginLook = self.panBeginLook or self:GetCameraLookVector()
			self.startPos = self.startPos or input.Position
			self.lastPos = self.lastPos or self.startPos
			self.userPanningTheCamera = true

			local delta = input.Position - self.lastPos
			delta = Vector2.new(delta.X, delta.Y * UserGameSettings:GetCameraYInvertValue())
			if self.panEnabled then
				local desiredXYVector = self:InputTranslationToCameraAngleChange(delta, TOUCH_SENSITIVTY)
				self.rotateInput = self.rotateInput + desiredXYVector
			end
			self.lastPos = input.Position
		else
			self.panBeginLook = nil
			self.startPos = nil
			self.lastPos = nil
			self.userPanningTheCamera = false
		end

		if self.numUnsunkTouches == 2 then
			local unsunkTouches = {}
			for touch, wasSunk in pairs(self.fingerTouches) do
				if not wasSunk then table.insert(unsunkTouches, touch) end
			end
			if #unsunkTouches == 2 then
				local difference = (unsunkTouches[1].Position - unsunkTouches[2].Position).Magnitude
				if self.startingDiff and self.pinchBeginZoom then
					local scale = difference / math.max(0.01, self.startingDiff)
					local clampedScale = math.clamp(scale, 0.1, 10)
					if self.distanceChangeEnabled then
						self:SetCameraToSubjectDistance(self.pinchBeginZoom / clampedScale)
					end
				else
					self.startingDiff = difference
					self.pinchBeginZoom = self:GetCameraToSubjectDistance()
				end
			end
		else
			self.startingDiff = nil
			self.pinchBeginZoom = nil
		end
	end

	function BaseCamera:OnTouchEnded(input)
		if input == self.dynamicTouchInput then
			self.dynamicTouchInput = nil
			return
		end
		if self.fingerTouches[input] == false then
			if self.numUnsunkTouches == 1 then
				self.panBeginLook = nil
				self.startPos = nil
				self.lastPos = nil
				self.userPanningTheCamera = false
			elseif self.numUnsunkTouches == 2 then
				self.startingDiff = nil
				self.pinchBeginZoom = nil
			end
			self.numUnsunkTouches = math.max(0, self.numUnsunkTouches - 1)
		end
		self.fingerTouches[input] = nil
		self.inputStartPositions[input] = nil
		self.inputStartTimes[input] = nil
	end

	function BaseCamera:OnMouse2Down(input, processed)
		if processed then return end
		self.isRightMouseDown = true
		self:OnMousePanButtonPressed(input, processed)
	end

	function BaseCamera:OnMouse2Up(input, processed)
		self.isRightMouseDown = false
		self:OnMousePanButtonReleased(input, processed)
	end

	function BaseCamera:OnMouse3Down(input, processed)
		if processed then return end
		self.isMiddleMouseDown = true
		self:OnMousePanButtonPressed(input, processed)
	end

	function BaseCamera:OnMouse3Up(input, processed)
		self.isMiddleMouseDown = false
		self:OnMousePanButtonReleased(input, processed)
	end

	function BaseCamera:OnMouseMoved(input)
		if not self.hasGameLoaded and VRService.VREnabled then return end
		local inputDelta = Vector2.new(input.Delta.X, input.Delta.Y * UserGameSettings:GetCameraYInvertValue())
		local isInputPanning = FFlagUserCameraToggle and CameraInput.getPanning()
		local isBeginLook = self.startPos and self.lastPos and self.panBeginLook
		local isPanning = isBeginLook or self.inFirstPerson or self.inMouseLockedMode or isInputPanning

		if self.panEnabled and isPanning then
			local desiredXYVector = self:InputTranslationToCameraAngleChange(inputDelta, MOUSE_SENSITIVITY)
			self.rotateInput = self.rotateInput + desiredXYVector
		end

		if self.startPos and self.lastPos and self.panBeginLook then
			self.lastPos = self.lastPos + input.Delta
		end
	end

	function BaseCamera:OnMousePanButtonPressed(input, processed)
		if processed then return end
		self:UpdateMouseBehavior()
		self.panBeginLook = self.panBeginLook or self:GetCameraLookVector()
		self.startPos = self.startPos or input.Position
		self.lastPos = self.lastPos or self.startPos
		self.userPanningTheCamera = true
	end

	function BaseCamera:OnMousePanButtonReleased()
		self:UpdateMouseBehavior()
		if not (self.isRightMouseDown or self.isMiddleMouseDown) then
			self.panBeginLook = nil
			self.startPos = nil
			self.lastPos = nil
			self.userPanningTheCamera = false
		end
	end

	function BaseCamera:UpdateMouseBehavior()
		if not self.wallWalkActive then return end
		if FFlagUserCameraToggle and self.isCameraToggle and not self.inMouseLockedMode then
			CameraUI.setCameraModeToastEnabled(true)
			CameraInput.enableCameraToggleInput()
			CameraToggleStateController(self.inFirstPerson, self.inMouseLockedMode, self.wallWalkActive)
		else
			if FFlagUserCameraToggle then
				CameraUI.setCameraModeToastEnabled(false)
				CameraInput.disableCameraToggleInput()
			end
			if self.inMouseLockedMode then
				UserGameSettings.RotationType = self.wallWalkActive and Enum.RotationType.MovementRelative or Enum.RotationType.CameraRelative
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			elseif self.inFirstPerson then
				UserGameSettings.RotationType = self.wallWalkActive and Enum.RotationType.MovementRelative or Enum.RotationType.CameraRelative
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			else
				UserGameSettings.RotationType = Enum.RotationType.MovementRelative
				if self.isRightMouseDown or self.isMiddleMouseDown then
					UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
				else
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				end
			end
		end
	end

	function BaseCamera:UpdateForDistancePropertyChange()
		self:SetCameraToSubjectDistance(self.currentSubjectDistance)
	end

	function BaseCamera:SetCameraToSubjectDistance(desiredSubjectDistance)
		local lastSubjectDistance = self.currentSubjectDistance
		if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
			self.currentSubjectDistance = 0.5
			if not self.inFirstPerson then self:EnterFirstPerson() end
		else
			local newSubjectDistance = math.clamp(desiredSubjectDistance, LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance)
			if newSubjectDistance < FIRST_PERSON_DISTANCE_THRESHOLD then
				self.currentSubjectDistance = 0.5
				if not self.inFirstPerson then self:EnterFirstPerson() end
			else
				self.currentSubjectDistance = newSubjectDistance
				if self.inFirstPerson then self:LeaveFirstPerson() end
			end
		end
		ZoomController.SetZoomParameters(self.currentSubjectDistance, math.sign(desiredSubjectDistance - lastSubjectDistance))
		return self.currentSubjectDistance
	end

	function BaseCamera:SetCameraType(cameraType) self.cameraType = cameraType end
	function BaseCamera:GetCameraType() return self.cameraType end
	function BaseCamera:SetCameraMovementMode(cameraMovementMode) self.cameraMovementMode = cameraMovementMode end
	function BaseCamera:GetCameraMovementMode() return self.cameraMovementMode end

	function BaseCamera:SetIsMouseLocked(mouseLocked)
		self.inMouseLockedMode = mouseLocked
		self:UpdateMouseBehavior()
	end
	function BaseCamera:GetIsMouseLocked() return self.inMouseLockedMode end
	function BaseCamera:SetMouseLockOffset(offsetVector) self.mouseLockOffset = offsetVector end
	function BaseCamera:GetMouseLockOffset() return self.mouseLockOffset end
	function BaseCamera:InFirstPerson() return self.inFirstPerson end
	function BaseCamera:IsInFirstPerson() return self.inFirstPerson end
	function BaseCamera:EnterFirstPerson() end
	function BaseCamera:LeaveFirstPerson() end
	function BaseCamera:GetCameraToSubjectDistance() return self.currentSubjectDistance end

	function BaseCamera:GetCameraLookVector()
		return Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or UNIT_Z
	end

	function BaseCamera:CalculateNewLookCFrame(suppliedLookVector, rotateDelta)
		local rot = rotateDelta or self.rotateInput
		local currLookVector = suppliedLookVector or self:GetCameraLookVector()
		currLookVector = self.UpCFrame:VectorToObjectSpace(currLookVector)
		if currLookVector.Magnitude > 1e-5 then
			currLookVector = currLookVector.Unit
		else
			currLookVector = Vector3.new(0, 0, -1)
		end

		local currPitchAngle = math.asin(math.clamp(currLookVector.Y, -0.9999, 0.9999))
		local yTheta = math.clamp(rot.Y, -MAX_Y + currPitchAngle, -MIN_Y + currPitchAngle)
		local constrainedRotateInput = Vector2.new(rot.X, yTheta)
		local startCFrame = CFrame.new(ZERO_VECTOR3, currLookVector)
		return CFrame.Angles(0, -constrainedRotateInput.X, 0) * startCFrame * CFrame.Angles(-constrainedRotateInput.Y, 0, 0)
	end

	function BaseCamera:CalculateNewLookVector(suppliedLookVector, rotateDelta)
		return self:CalculateNewLookCFrame(suppliedLookVector, rotateDelta).LookVector
	end

	function BaseCamera:CalculateNewLookVectorVR()
		local subjectPosition = self:GetSubjectPosition()
		local vecToSubject = (subjectPosition - Workspace.CurrentCamera.CFrame.Position)
		local currLookVector = (vecToSubject * X1_Y0_Z1).Unit
		local vrRotateInput = Vector2.new(self.rotateInput.X, 0)
		local startCFrame = CFrame.new(ZERO_VECTOR3, currLookVector)
		local yawRotatedVector = (CFrame.Angles(0, -vrRotateInput.X, 0) * startCFrame * CFrame.Angles(-vrRotateInput.Y, 0, 0)).LookVector
		return (yawRotatedVector * X1_Y0_Z1).Unit
	end

	function BaseCamera:GetHumanoid()
		local character = LocalPlayer and LocalPlayer.Character
		if character then
			local resultHumanoid = self.humanoidCache[LocalPlayer]
			if resultHumanoid and resultHumanoid.Parent == character then
				return resultHumanoid
			else
				self.humanoidCache[LocalPlayer] = nil
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then self.humanoidCache[LocalPlayer] = humanoid end
				return humanoid
			end
		end
		return nil
	end

	function BaseCamera:UpdateGamepad()
		local gamepadPan = self.gamepadPanningCamera
		if gamepadPan and (self.hasGameLoaded or not VRService.VREnabled) then
			gamepadPan = Util.GamepadLinearToCurve(gamepadPan)
			local currentTime = tick()
			if gamepadPan.X ~= 0 or gamepadPan.Y ~= 0 then
				self.userPanningTheCamera = true
			elseif gamepadPan == ZERO_VECTOR2 then
				self.lastThumbstickRotate = nil
				if self.lastThumbstickPos == ZERO_VECTOR2 then
					self.currentSpeed = 0
				end
			end

			local finalConstant = 0
			if self.lastThumbstickRotate then
				if VRService.VREnabled then
					self.currentSpeed = self.vrMaxSpeed
				else
					local elapsedTime = (currentTime - self.lastThumbstickRotate) * 10
					self.currentSpeed = math.min(self.maxSpeed, self.currentSpeed + (self.maxSpeed * ((elapsedTime * elapsedTime) / self.numOfSeconds)))
					if self.lastVelocity and (currentTime - self.lastThumbstickRotate) > 0 then
						local velocity = (gamepadPan - self.lastThumbstickPos) / (currentTime - self.lastThumbstickRotate)
						local velocityDeltaMag = (velocity - self.lastVelocity).Magnitude
						if velocityDeltaMag > 12 then
							self.currentSpeed = math.min(self.maxSpeed, self.currentSpeed * (20 / velocityDeltaMag))
						end
					end
				end
				finalConstant = UserGameSettings.GamepadCameraSensitivity * self.currentSpeed
				if (currentTime - self.lastThumbstickRotate) > 0 then
					self.lastVelocity = (gamepadPan - self.lastThumbstickPos) / (currentTime - self.lastThumbstickRotate)
				end
			end

			self.lastThumbstickPos = gamepadPan
			self.lastThumbstickRotate = currentTime
			return Vector2.new(gamepadPan.X * finalConstant, gamepadPan.Y * finalConstant * self.ySensitivity * UserGameSettings:GetCameraYInvertValue())
		end
		return ZERO_VECTOR2
	end

	function BaseCamera:ApplyVRTransform() end
	function BaseCamera:ShouldUseVRRotation() return false end
	function BaseCamera:GetVRRotationInput() return ZERO_VECTOR2 end
	function BaseCamera:OnNewCameraSubject() end
	function BaseCamera:GetVRFocus(subjectPosition) return CFrame.new(subjectPosition) end

	return BaseCamera
end

local function _ClassicCamera()
	local ZERO_VECTOR2 = Vector2.new(0, 0)
	local tweenAcceleration = math.rad(220)
	local tweenSpeed = math.rad(0)
	local tweenMaxSpeed = math.rad(250)
	local TIME_BEFORE_AUTO_ROTATE = 2.0
	local INITIAL_CAMERA_ANGLE = CFrame.fromOrientation(math.rad(-15), 0, 0)

	local FFlagUserCameraToggle do
		local success, result = pcall(function() return UserSettings():IsUserFeatureEnabled("UserCameraToggle") end)
		FFlagUserCameraToggle = success and result
	end

	local CameraInput = _CameraInput()
	local Util = _CameraUtils()
	local BaseCamera = _BaseCamera()
	local ClassicCamera = setmetatable({}, BaseCamera)
	ClassicCamera.__index = ClassicCamera

	function ClassicCamera.new()
		local self = setmetatable(BaseCamera.new(), ClassicCamera)
		self.isFollowCamera = false
		self.isCameraToggle = false
		self.lastUpdate = tick()
		self.cameraToggleSpring = Util.Spring.new(5, 0)
		return self
	end

	function ClassicCamera:GetCameraToggleOffset(dt)
		if self.isCameraToggle and not self.inMouseLockedMode then
			local zoom = self.currentSubjectDistance
			if CameraInput.getTogglePan() then
				self.cameraToggleSpring.goal = math.clamp(Util.map(zoom, 0.5, self.FIRST_PERSON_DISTANCE_THRESHOLD, 0, 1), 0, 1)
			else
				self.cameraToggleSpring.goal = 0
			end
			local distanceOffset = math.clamp(Util.map(zoom, 0.5, 64, 0, 1), 0, 1) + 1
			return Vector3.new(0, self.cameraToggleSpring:step(dt) * distanceOffset, 0)
		end
		return Vector3.new()
	end

	function ClassicCamera:SetCameraMovementMode(cameraMovementMode)
		BaseCamera.SetCameraMovementMode(self, cameraMovementMode)
		self.isFollowCamera = cameraMovementMode == Enum.ComputerCameraMovementMode.Follow
		self.isCameraToggle = cameraMovementMode == Enum.ComputerCameraMovementMode.CameraToggle
	end

	function ClassicCamera:Update()
		local now = tick()
		local timeDelta = now - self.lastUpdate
		local safeDt = math.clamp(timeDelta, 1 / 240, 0.1)
		local camera = Workspace.CurrentCamera
		local newCameraCFrame = camera.CFrame
		local newCameraFocus = camera.Focus

		local overrideCameraLookVector = nil
		if self.resetCameraAngle then
			local rootPart = self:GetHumanoidRootPart()
			overrideCameraLookVector = rootPart and (rootPart.CFrame * INITIAL_CAMERA_ANGLE).LookVector or INITIAL_CAMERA_ANGLE.LookVector
			self.resetCameraAngle = false
		end

		local humanoid = self:GetHumanoid()
		local cameraSubject = camera.CameraSubject
		local isInVehicle = cameraSubject and cameraSubject:IsA("VehicleSeat")
		local isOnASkateboard = cameraSubject and cameraSubject:IsA("SkateboardPlatform")
		local isClimbing = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Climbing

		if self.lastUpdate == nil or timeDelta > 1 then
			self.lastCameraTransform = nil
		end

		if self.lastUpdate then
			local gamepadRotation = self:UpdateGamepad()
			if gamepadRotation ~= ZERO_VECTOR2 then
				self.rotateInput = self.rotateInput + (gamepadRotation * safeDt)
			end
			local angle = 0
			if not (isInVehicle or isOnASkateboard) then
				angle = angle + (self.turningLeft and -120 or 0) + (self.turningRight and 120 or 0)
			end
			if angle ~= 0 then
				self.rotateInput = self.rotateInput + Vector2.new(math.rad(angle * safeDt), 0)
			end
		end

		local cameraHeight = self:GetCameraHeight()
		if self.userPanningTheCamera then
			tweenSpeed = 0
			self.lastUserPanCamera = tick()
		end

		local userRecentlyPannedCamera = now - self.lastUserPanCamera < TIME_BEFORE_AUTO_ROTATE
		local subjectPosition = self:GetSubjectPosition()

		if subjectPosition and LocalPlayer and camera then
			local zoom = math.max(0.5, self:GetCameraToSubjectDistance())

			if not self:GetIsMouseLocked() and not self:IsInFirstPerson() then
				if not self.userPanningTheCamera and self.lastCameraTransform then
					local torso = humanoid and (humanoid.Parent:FindFirstChild("Torso") or humanoid.Parent:FindFirstChild("UpperTorso"))
					if (isInVehicle or isOnASkateboard or (self.isFollowCamera and isClimbing)) and self.lastUpdate and humanoid and torso then
						if not userRecentlyPannedCamera then
							local forwardVector = isOnASkateboard and cameraSubject.CFrame.LookVector or torso.CFrame.LookVector
							tweenSpeed = math.clamp(tweenSpeed + tweenAcceleration * timeDelta, 0, tweenMaxSpeed)
							local percent = math.clamp(tweenSpeed * timeDelta, 0, 1)
							local y = Util.GetAngleBetweenXZVectors(forwardVector, self:GetCameraLookVector())
							if Util.IsFinite(y) and math.abs(y) > 0.0001 then
								self.rotateInput = self.rotateInput + Vector2.new(y * percent, 0)
							end
						end
					elseif self.isFollowCamera and (not userRecentlyPannedCamera and not VRService.VREnabled) then
						local lastVec = -(self.lastCameraTransform.Position - subjectPosition)
						local y = Util.GetAngleBetweenXZVectors(lastVec, self:GetCameraLookVector())
						if Util.IsFinite(y) and math.abs(y) > 0.0001 and math.abs(y) > 0.4 * timeDelta then
							self.rotateInput = self.rotateInput + Vector2.new(y, 0)
						end
					end
				end
			end

			local rotDamping = (self:GetIsMouseLocked() or self:IsInFirstPerson()) and 45 or 28
			local rotAlpha = 1 - math.exp(-rotDamping * safeDt)
			local appliedRotate = self.rotateInput * rotAlpha
			self.rotateInput = self.rotateInput - appliedRotate
			if self.rotateInput.Magnitude < 1e-5 then
				self.rotateInput = ZERO_VECTOR2
			end

			local newLookVector = self:CalculateNewLookVector(overrideCameraLookVector, appliedRotate)
			newCameraFocus = CFrame.new(subjectPosition)
			newCameraCFrame = CFrame.new(newCameraFocus.Position - (zoom * newLookVector), newCameraFocus.Position) + Vector3.new(0, cameraHeight, 0)

			if FFlagUserCameraToggle then
				local toggleOffset = self:GetCameraToggleOffset(timeDelta)
				newCameraFocus = newCameraFocus + toggleOffset
				newCameraCFrame = newCameraCFrame + toggleOffset
			end

			self.lastCameraTransform = newCameraCFrame
			self.lastCameraFocus = newCameraFocus
			if (isInVehicle or isOnASkateboard) and cameraSubject and cameraSubject:IsA("BasePart") then
				self.lastSubjectCFrame = cameraSubject.CFrame
			else
				self.lastSubjectCFrame = nil
			end
		end

		self.lastUpdate = now
		return newCameraCFrame, newCameraFocus
	end

	function ClassicCamera:EnterFirstPerson()
		self.inFirstPerson = true
		self:UpdateMouseBehavior()
	end

	function ClassicCamera:LeaveFirstPerson()
		self.inFirstPerson = false
		self:UpdateMouseBehavior()
	end

	return ClassicCamera
end

local function _TransparencyController()
	local MAX_TWEEN_RATE = 2.8
	local Util = _CameraUtils()

	local TransparencyController = {}
	TransparencyController.__index = TransparencyController

	function TransparencyController.new()
		local self = setmetatable({}, TransparencyController)
		self.lastUpdate = tick()
		self.transparencyDirty = false
		self.enabled = false
		self.lastTransparency = nil
		self.cachedParts = {}
		return self
	end

	function TransparencyController:HasToolAncestor(object)
		if object.Parent == nil then return false end
		return object.Parent:IsA("Tool") or self:HasToolAncestor(object.Parent)
	end

	function TransparencyController:IsValidPartToModify(part)
		if part:IsA("BasePart") or part:IsA("Decal") then
			return not self:HasToolAncestor(part)
		end
		return false
	end

	function TransparencyController:CachePartsRecursive(object)
		if not object then return end
		if self:IsValidPartToModify(object) then
			self.cachedParts[object] = true
			self.transparencyDirty = true
		end
		for _, child in ipairs(object:GetChildren()) do
			self:CachePartsRecursive(child)
		end
	end

	function TransparencyController:TeardownTransparency()
		for child in pairs(self.cachedParts) do
			if child and child.Parent then
				child.LocalTransparencyModifier = 0
			end
		end
		self.cachedParts = {}
		self.transparencyDirty = true
		self.lastTransparency = nil
		if self.descendantAddedConn then self.descendantAddedConn:Disconnect() self.descendantAddedConn = nil end
		if self.descendantRemovingConn then self.descendantRemovingConn:Disconnect() self.descendantRemovingConn = nil end
	end

	function TransparencyController:SetupTransparency(character)
		self:TeardownTransparency()
		self.descendantAddedConn = character.DescendantAdded:Connect(function(object)
			if self:IsValidPartToModify(object) then
				self.cachedParts[object] = true
				self.transparencyDirty = true
			end
		end)
		self.descendantRemovingConn = character.DescendantRemoving:Connect(function(object)
			if self.cachedParts[object] then
				self.cachedParts[object] = nil
				if object and object.Parent then
					object.LocalTransparencyModifier = 0
				end
			end
		end)
		self:CachePartsRecursive(character)
	end

	function TransparencyController:Enable(enable)
		if self.enabled ~= enable then
			self.enabled = enable
			self:Update()
		end
	end

	function TransparencyController:SetSubject(subject)
		local character = nil
		if subject and subject:IsA("Humanoid") then
			character = subject.Parent
		elseif subject and subject:IsA("VehicleSeat") and subject.Occupant then
			character = subject.Occupant.Parent
		end
		if character then
			self:SetupTransparency(character)
		else
			self:TeardownTransparency()
		end
	end

	function TransparencyController:Update()
		local now = tick()
		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			local transparency = 0
			if self.enabled then
				local distance = (currentCamera.Focus.Position - currentCamera.CFrame.Position).Magnitude
				transparency = (distance < 2) and (1.0 - (distance - 0.5) / 1.5) or 0
				if transparency < 0.5 then transparency = 0 end

				if self.lastTransparency then
					local deltaTransparency = transparency - self.lastTransparency
					if transparency < 1 and self.lastTransparency < 0.95 then
						local maxDelta = MAX_TWEEN_RATE * (now - self.lastUpdate)
						deltaTransparency = math.clamp(deltaTransparency, -maxDelta, maxDelta)
					end
					transparency = self.lastTransparency + deltaTransparency
				else
					self.transparencyDirty = true
				end
				transparency = math.clamp(Util.Round(transparency, 2), 0, 1)
			end

			if self.transparencyDirty or self.lastTransparency ~= transparency then
				for child in pairs(self.cachedParts) do
					if child and child.Parent then
						child.LocalTransparencyModifier = transparency
					end
				end
				self.transparencyDirty = false
				self.lastTransparency = transparency
			end
		end
		self.lastUpdate = now
	end

	return TransparencyController
end

local function _MouseLockController()
	local MouseLockController = {}
	MouseLockController.__index = MouseLockController

	function MouseLockController.new()
		local self = setmetatable({}, MouseLockController)
		self.mouseLockToggledEvent = Instance.new("BindableEvent")
		return self
	end

	function MouseLockController:GetIsMouseLocked()
		local locked = false
		pcall(function()
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or UserGameSettings.RotationType == Enum.RotationType.CameraRelative then
				locked = true
			end
		end)
		return locked
	end

	function MouseLockController:GetBindableToggleEvent()
		return self.mouseLockToggledEvent.Event
	end

	function MouseLockController:GetMouseLockOffset()
		return Vector3.new(1.75, 0, 0)
	end

	function MouseLockController:UpdateMouseLockAvailability()
	end

	function MouseLockController:OnMouseLockToggled()
	end

	function MouseLockController:EnableMouseLock(enable)
	end

	function MouseLockController:Destroy()
	end

	return MouseLockController
end

local function _Poppercam()
	local ZoomController = _ZoomController()

	local TransformExtrapolator = {}
	TransformExtrapolator.__index = TransformExtrapolator
	local CF_IDENTITY = CFrame.new()

	local function cframeToAxis(cframe)
		local axis, angle = cframe:ToAxisAngle()
		return axis * angle
	end

	local function axisToCFrame(axis)
		local angle = axis.Magnitude
		if angle > 1e-5 then
			return CFrame.fromAxisAngle(axis, angle)
		end
		return CF_IDENTITY
	end

	local function extractRotation(cf)
		local _, _, _, xx, yx, zx, xy, yy, zy, xz, yz, zz = cf:GetComponents()
		return CFrame.new(0, 0, 0, xx, yx, zx, xy, yy, zy, xz, yz, zz)
	end

	function TransformExtrapolator.new()
		return setmetatable({ lastCFrame = nil }, TransformExtrapolator)
	end

	function TransformExtrapolator:Step(dt, currentCFrame)
		dt = math.max(dt, 1 / 240)
		local lastCFrame = self.lastCFrame or currentCFrame
		self.lastCFrame = currentCFrame

		local currentPos = currentCFrame.Position
		local currentRot = extractRotation(currentCFrame)
		local lastPos = lastCFrame.Position
		local lastRot = extractRotation(lastCFrame)

		local dp = (currentPos - lastPos) / dt
		local dr = cframeToAxis(currentRot * lastRot:Inverse()) / dt

		return {
			extrapolate = function(t)
				return axisToCFrame(dr * t) * currentRot + (dp * t + currentPos)
			end,
			posVelocity = dp,
			rotVelocity = dr,
		}
	end

	function TransformExtrapolator:Reset()
		self.lastCFrame = nil
	end

	local Poppercam = {}
	Poppercam.__index = Poppercam

	function Poppercam.new()
		return setmetatable({ focusExtrapolator = TransformExtrapolator.new() }, Poppercam)
	end

	function Poppercam:GetOcclusionMode() return Enum.DevCameraOcclusionMode.Zoom end
	function Poppercam:Enable() self.focusExtrapolator:Reset() end

	function Poppercam:Update(renderDt, desiredCameraCFrame, desiredCameraFocus)
		local rotatedFocus = desiredCameraFocus * (desiredCameraCFrame - desiredCameraCFrame.Position)
		local extrapolation = self.focusExtrapolator:Step(renderDt, rotatedFocus)
		local zoom = ZoomController.Update(renderDt, rotatedFocus, extrapolation)
		return rotatedFocus * CFrame.new(0, 0, zoom), desiredCameraFocus
	end

	return Poppercam
end

local function _CameraModule()
	local CameraModule = {}
	CameraModule.__index = CameraModule

	local FFlagUserCameraToggle do
		local success, result = pcall(function() return UserSettings():IsUserFeatureEnabled("UserCameraToggle") end)
		FFlagUserCameraToggle = success and result
	end

	local CameraUtils = _CameraUtils()
	local ClassicCamera = _ClassicCamera()
	local Poppercam = _Poppercam()
	local TransparencyController = _TransparencyController()
	local MouseLockController = _MouseLockController()

	local instantiatedCameraControllers = {}
	local instantiatedOcclusionModules = {}

	do
		local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
		pcall(function()
			PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Default)
			PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Follow)
			PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Classic)
			PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Default)
			PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Follow)
			PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Classic)
			if FFlagUserCameraToggle then
				PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.CameraToggle)
			end
		end)
	end

	CameraModule.FFlagUserCameraToggle = FFlagUserCameraToggle
	local IDENTITYCF = CFrame.new()
	local UNIT_Y = Vector3.new(0, 1, 0)
	local lastUpCFrame = IDENTITYCF

	function CameraModule.new()
		local self = setmetatable({}, CameraModule)
		self.activeCameraController = nil
		self.activeOcclusionModule = nil
		self.activeTransparencyController = TransparencyController.new()
		self.activeTransparencyController:Enable(true)

		self.UpVector = UNIT_Y
		self.UpCFrame = IDENTITYCF
		self.smoothedFocusPos = nil
		self.wallWalkActive = START_ENABLED

		if not UserInputService.TouchEnabled then
			self.activeMouseLockController = MouseLockController.new()
			local toggleEvent = self.activeMouseLockController:GetBindableToggleEvent()
			if toggleEvent then
				toggleEvent:Connect(function()
					self:OnMouseLockToggled()
				end)
			end
		end

		self.lastInputType = UserInputService:GetLastInputType()
		UserInputService.LastInputTypeChanged:Connect(function(newType)
			self.lastInputType = newType
		end)

		self:ActivateCameraController(self:GetCameraControlChoice())
		self:ActivateOcclusionModule()
		self:OnCurrentCameraChanged()

		self.cameraBound = false
		function self:BindCamera()
			if self.cameraBound then return end
			self.cameraBound = true
			RunService:BindToRenderStep("WallWalkCameraRenderUpdate", Enum.RenderPriority.Camera.Value, function(dt)
				self:Update(dt)
			end)
		end

		function self:UnbindCamera()
			if not self.cameraBound then return end
			self.cameraBound = false
			pcall(function() RunService:UnbindFromRenderStep("WallWalkCameraRenderUpdate") end)
		end

		for _, prop in ipairs({"CameraMinZoomDistance", "CameraMaxZoomDistance", "CameraMode", "DevComputerCameraMode", "DevTouchCameraMode"}) do
			LocalPlayer:GetPropertyChangedSignal(prop):Connect(function()
				self:OnLocalPlayerCameraPropertyChanged(prop)
			end)
		end

		UserGameSettings:GetPropertyChangedSignal("ComputerCameraMovementMode"):Connect(function()
			local mode = self:GetCameraMovementModeFromSettings()
			self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(mode))
		end)

		Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			self:OnCurrentCameraChanged()
		end)

		return self
	end

	function CameraModule:SetWallWalkActive(active)
		self.wallWalkActive = (active == true)
		if self.activeCameraController and self.activeCameraController.SetWallWalkActive then
			self.activeCameraController:SetWallWalkActive(self.wallWalkActive)
		end
		if self.wallWalkActive then
			self:BindCamera()
		else
			self:UnbindCamera()
		end
	end

	function CameraModule:GetUpVector(oldUpVector)
		return UNIT_Y
	end

	local function getRotationBetween(u, v, axis)
		local dot, uxv = u:Dot(v), u:Cross(v)
		if dot < -0.99999 then
			local safeAxis = axis.Magnitude > 1e-4 and axis.Unit or Vector3.new(1, 0, 0)
			return CFrame.fromAxisAngle(safeAxis, math.pi)
		end
		return CFrame.new(0, 0, 0, uxv.X, uxv.Y, uxv.Z, 1 + dot)
	end

	function CameraModule:CalculateUpCFrame(dt)
		dt = math.clamp(dt or (1 / 60), 1 / 240, 0.1)
		local oldUpVector = self.UpVector
		local targetUpVector = self:GetUpVector(oldUpVector)

		if targetUpVector == UNIT_Y and (1 - oldUpVector:Dot(UNIT_Y)) < 1e-5 then
			self.UpVector = UNIT_Y
			self.UpCFrame = IDENTITYCF
			lastUpCFrame = IDENTITYCF
			return
		end

		local refRight = self.UpCFrame.RightVector
		if math.abs(refRight:Dot(oldUpVector)) > 0.95 then
			refRight = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.RightVector or Vector3.new(1, 0, 0)
		end

		local transitionCF = getRotationBetween(oldUpVector, targetUpVector, refRight)

		local angleDiff = math.acos(math.clamp(oldUpVector:Dot(targetUpVector), -1, 1))
		local adaptiveSpeed = 12.5 - 4.0 * (angleDiff / math.pi)
		local alpha = 1 - math.exp(-adaptiveSpeed * dt)

		local vecSlerpCF = IDENTITYCF:Lerp(transitionCF, alpha)
		local nextUp = (vecSlerpCF * oldUpVector).Unit
		local rotatedCF = vecSlerpCF * self.UpCFrame

		local rawRight = rotatedCF.RightVector
		local orthoRight = rawRight - rawRight:Dot(nextUp) * nextUp
		if orthoRight.Magnitude < 1e-4 then
			orthoRight = refRight - refRight:Dot(nextUp) * nextUp
		end
		orthoRight = orthoRight.Unit
		local orthoBack = orthoRight:Cross(nextUp).Unit

		self.UpVector = nextUp
		self.UpCFrame = CFrame.fromMatrix(Vector3.zero, orthoRight, nextUp, orthoBack)
		lastUpCFrame = self.UpCFrame
	end

	function CameraModule:GetCameraMovementModeFromSettings()
		if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
			return Enum.ComputerCameraMovementMode.Classic
		end
		local devMode, userMode
		if UserInputService.TouchEnabled then
			devMode = CameraUtils.ConvertCameraModeEnumToStandard(LocalPlayer.DevTouchCameraMode)
			userMode = CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.TouchCameraMovementMode)
		else
			devMode = CameraUtils.ConvertCameraModeEnumToStandard(LocalPlayer.DevComputerCameraMode)
			userMode = CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.ComputerCameraMovementMode)
		end
		return devMode == Enum.DevComputerCameraMovementMode.UserChoice and userMode or devMode
	end

	function CameraModule:ActivateOcclusionModule()
		if not self.activeOcclusionModule then
			self.activeOcclusionModule = instantiatedOcclusionModules[Poppercam] or Poppercam.new()
			instantiatedOcclusionModules[Poppercam] = self.activeOcclusionModule
			self.activeOcclusionModule:Enable(true)
		end
	end

	function CameraModule:ActivateCameraController(cameraMovementMode, legacyCameraType)
		if legacyCameraType == Enum.CameraType.Scriptable then
			if self.activeCameraController then
				self.activeCameraController:Enable(false)
				self.activeCameraController = nil
			end
			return
		elseif legacyCameraType == Enum.CameraType.Custom then
			cameraMovementMode = self:GetCameraMovementModeFromSettings()
		elseif legacyCameraType == Enum.CameraType.Follow then
			cameraMovementMode = Enum.ComputerCameraMovementMode.Follow
		elseif legacyCameraType ~= nil then
			cameraMovementMode = Enum.ComputerCameraMovementMode.Classic
		end

		local newCameraController = instantiatedCameraControllers[ClassicCamera]
		if not newCameraController then
			newCameraController = ClassicCamera.new()
			instantiatedCameraControllers[ClassicCamera] = newCameraController
		end

		if self.activeCameraController ~= newCameraController then
			if self.activeCameraController then
				self.activeCameraController:Enable(false)
			end
			self.activeCameraController = newCameraController
			self.activeCameraController:Enable(true)
		elseif not self.activeCameraController:GetEnabled() then
			self.activeCameraController:Enable(true)
		end

		self.activeCameraController:SetWallWalkActive(self.wallWalkActive)
		if self.activeMouseLockController then
			self.activeCameraController:SetIsMouseLocked(self.activeMouseLockController:GetIsMouseLocked())
			self.activeCameraController:SetMouseLockOffset(self.activeMouseLockController:GetMouseLockOffset())
		end

		if cameraMovementMode ~= nil then
			self.activeCameraController:SetCameraMovementMode(cameraMovementMode)
		end
	end

	function CameraModule:OnCameraSubjectChanged()
		local currentCamera = Workspace.CurrentCamera
		self.smoothedFocusPos = nil
		if self.activeTransparencyController and currentCamera then
			self.activeTransparencyController:SetSubject(currentCamera.CameraSubject)
		end
	end

	function CameraModule:OnCameraTypeChanged(newCameraType)
		if newCameraType == Enum.CameraType.Scriptable and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		self:ActivateCameraController(nil, newCameraType)
	end

	function CameraModule:OnCurrentCameraChanged()
		local currentCamera = Workspace.CurrentCamera
		if not currentCamera then return end
		if self.cameraSubjectChangedConn then self.cameraSubjectChangedConn:Disconnect() end
		if self.cameraTypeChangedConn then self.cameraTypeChangedConn:Disconnect() end

		self.cameraSubjectChangedConn = currentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
			self:OnCameraSubjectChanged()
		end)
		self.cameraTypeChangedConn = currentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
			self:OnCameraTypeChanged(currentCamera.CameraType)
		end)

		self:OnCameraSubjectChanged()
		self:OnCameraTypeChanged(currentCamera.CameraType)
	end

	function CameraModule:OnLocalPlayerCameraPropertyChanged(propertyName)
		if propertyName == "CameraMode" then
			if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
				self:ActivateCameraController(Enum.ComputerCameraMovementMode.Classic)
				if self.activeCameraController then
					self.activeCameraController:UpdateForDistancePropertyChange()
				end
			else
				local mode = self:GetCameraMovementModeFromSettings()
				self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(mode))
			end
		elseif propertyName == "DevComputerCameraMode" or propertyName == "DevTouchCameraMode" then
			local mode = self:GetCameraMovementModeFromSettings()
			self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(mode))
		elseif propertyName == "CameraMinZoomDistance" or propertyName == "CameraMaxZoomDistance" then
			if self.activeCameraController then
				self.activeCameraController:UpdateForDistancePropertyChange()
			end
		end
	end

	function CameraModule:GetCameraControlChoice()
		if self.lastInputType == Enum.UserInputType.Touch or UserInputService.TouchEnabled then
			if LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice then
				return CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.TouchCameraMovementMode)
			else
				return CameraUtils.ConvertCameraModeEnumToStandard(LocalPlayer.DevTouchCameraMode)
			end
		else
			if LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice then
				return CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.ComputerCameraMovementMode)
			else
				return CameraUtils.ConvertCameraModeEnumToStandard(LocalPlayer.DevComputerCameraMode)
			end
		end
	end

	function CameraModule:OnMouseLockToggled()
		if self.activeMouseLockController and self.activeCameraController then
			local mouseLocked = self.activeMouseLockController:GetIsMouseLocked()
			local mouseLockOffset = self.activeMouseLockController:GetMouseLockOffset()
			self.activeCameraController:SetIsMouseLocked(mouseLocked)
			self.activeCameraController:SetMouseLockOffset(mouseLockOffset)
		end
	end

	function CameraModule:Update(dt)
		if not self.wallWalkActive then return end
		if self.activeCameraController and Workspace.CurrentCamera then
			local safeDt = math.clamp(dt or (1 / 60), 1 / 240, 0.1)
			local isMouseLocked = self.activeMouseLockController and self.activeMouseLockController:GetIsMouseLocked() or false
			if self.activeCameraController:GetIsMouseLocked() ~= isMouseLocked then
				self.activeCameraController:SetIsMouseLocked(isMouseLocked)
			end
			self.activeCameraController:UpdateMouseBehavior()

			if isMouseLocked then
				local mouse = LocalPlayer:GetMouse()
				if mouse and mouse.Icon == "" then
					mouse.Icon = "rbxasset://textures/MouseLockedCursor.png"
				end
			end

			local newCameraCFrame, newCameraFocus = self.activeCameraController:Update(dt)

			local rawFocusPos = newCameraFocus.Position
			if not self.smoothedFocusPos or (rawFocusPos - self.smoothedFocusPos).Magnitude > 14 then
				self.smoothedFocusPos = rawFocusPos
			else
				local focusSpeed = self.activeCameraController:InFirstPerson() and 60 or 32
				local focusAlpha = 1 - math.exp(-focusSpeed * safeDt)
				self.smoothedFocusPos = self.smoothedFocusPos:Lerp(rawFocusPos, focusAlpha)
			end

			local offset = newCameraFocus:ToObjectSpace(newCameraCFrame)
			newCameraFocus = CFrame.new(self.smoothedFocusPos)

			self:CalculateUpCFrame(safeDt)
			self.activeCameraController:UpdateUpCFrame(self.UpCFrame)

			local camRotation = self.UpCFrame * offset
			local baseCameraCFrame = newCameraFocus * camRotation

			if isMouseLocked and not self.activeCameraController:InFirstPerson() then
				local lockOffset = self.activeMouseLockController:GetMouseLockOffset()
				local worldShiftOffset = baseCameraCFrame:VectorToWorldSpace(lockOffset)
				newCameraFocus = newCameraFocus + worldShiftOffset
				newCameraCFrame = baseCameraCFrame + worldShiftOffset
			else
				newCameraCFrame = baseCameraCFrame
			end

			if self.activeCameraController.lastCameraTransform then
				self.activeCameraController.lastCameraTransform = newCameraCFrame
				self.activeCameraController.lastCameraFocus = newCameraFocus
			end

			if self.activeOcclusionModule then
				newCameraCFrame, newCameraFocus = self.activeOcclusionModule:Update(dt, newCameraCFrame, newCameraFocus)
			end

			Workspace.CurrentCamera.CFrame = newCameraCFrame
			Workspace.CurrentCamera.Focus = newCameraFocus

			if self.activeTransparencyController then
				self.activeTransparencyController:Update()
			end
		end
	end

	function CameraModule:IsFirstPerson()
		return self.activeCameraController and self.activeCameraController:InFirstPerson() or false
	end

	function CameraModule:IsMouseLocked()
		return self.activeMouseLockController and self.activeMouseLockController:GetIsMouseLocked() or false
	end

	function CameraModule:IsCamRelative()
		return self:IsMouseLocked() or self:IsFirstPerson()
	end

	function CameraModule:Destroy()
		if self.activeMouseLockController then
			self.activeMouseLockController:Destroy()
		end
	end

	function CameraUtils.GetAngleBetweenXZVectors(v1, v2)
		v1 = lastUpCFrame:VectorToObjectSpace(v1)
		v2 = lastUpCFrame:VectorToObjectSpace(v2)
		return math.atan2(v2.X * v1.Z - v2.Z * v1.X, v2.X * v1.X + v2.Z * v1.Z)
	end

	return CameraModule.new()
end

local function _BaseCharacterController()
	local BaseCharacterController = {}
	BaseCharacterController.__index = BaseCharacterController
	function BaseCharacterController.new()
		return setmetatable({
			enabled = false,
			moveVector = Vector3.zero,
			moveVectorIsCameraRelative = true,
			isJumping = false,
		}, BaseCharacterController)
	end
	function BaseCharacterController:OnRenderStepped() end
	function BaseCharacterController:GetMoveVector() return self.moveVector end
	function BaseCharacterController:IsMoveVectorCameraRelative() return self.moveVectorIsCameraRelative end
	function BaseCharacterController:GetIsJumping() return self.isJumping end
	return BaseCharacterController
end

local function _Keyboard()
	local BaseCharacterController = _BaseCharacterController()
	local Keyboard = setmetatable({}, BaseCharacterController)
	Keyboard.__index = Keyboard

	function Keyboard.new(priority)
		local self = setmetatable(BaseCharacterController.new(), Keyboard)
		self.CONTROL_ACTION_PRIORITY = priority
		self.forwardValue, self.backwardValue, self.leftValue, self.rightValue = 0, 0, 0, 0
		self.jumpEnabled = true
		return self
	end

	function Keyboard:UpdateMovement(inputState)
		if inputState == Enum.UserInputState.Cancel then
			self.moveVector = Vector3.zero
		else
			self.moveVector = Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
		end
	end

	function Keyboard:UpdateJump()
		self.isJumping = self.jumpRequested
	end

	function Keyboard:Enable(enable)
		if not UserInputService.KeyboardEnabled then return false end
		if enable == self.enabled then return true end

		self.forwardValue, self.backwardValue, self.leftValue, self.rightValue = 0, 0, 0, 0
		self.moveVector = Vector3.zero
		self.jumpRequested = false
		self:UpdateJump()

		if enable then
			ContextActionService:BindActionAtPriority("WallWalkMoveForward", function(_, state)
				self.forwardValue = (state == Enum.UserInputState.Begin) and -1 or 0
				self:UpdateMovement(state)
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterForward)

			ContextActionService:BindActionAtPriority("WallWalkMoveBackward", function(_, state)
				self.backwardValue = (state == Enum.UserInputState.Begin) and 1 or 0
				self:UpdateMovement(state)
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterBackward)

			ContextActionService:BindActionAtPriority("WallWalkMoveLeft", function(_, state)
				self.leftValue = (state == Enum.UserInputState.Begin) and -1 or 0
				self:UpdateMovement(state)
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterLeft)

			ContextActionService:BindActionAtPriority("WallWalkMoveRight", function(_, state)
				self.rightValue = (state == Enum.UserInputState.Begin) and 1 or 0
				self:UpdateMovement(state)
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterRight)

			ContextActionService:BindActionAtPriority("WallWalkJump", function(_, state)
				self.jumpRequested = self.jumpEnabled and (state == Enum.UserInputState.Begin)
				self:UpdateJump()
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterJump)

			local function resetKeys()
				self.moveVector = Vector3.zero
				self.forwardValue, self.backwardValue, self.leftValue, self.rightValue = 0, 0, 0, 0
				self.jumpRequested = false
				self:UpdateJump()
			end
			self.textFocusReleasedConn = UserInputService.TextBoxFocusReleased:Connect(resetKeys)
			self.textFocusGainedConn = UserInputService.TextBoxFocused:Connect(function()
				self.jumpRequested = false
				self:UpdateJump()
			end)
			self.windowFocusConn = UserInputService.WindowFocused:Connect(resetKeys)
		else
			ContextActionService:UnbindAction("WallWalkMoveForward")
			ContextActionService:UnbindAction("WallWalkMoveBackward")
			ContextActionService:UnbindAction("WallWalkMoveLeft")
			ContextActionService:UnbindAction("WallWalkMoveRight")
			ContextActionService:UnbindAction("WallWalkJump")
			if self.textFocusReleasedConn then self.textFocusReleasedConn:Disconnect() end
			if self.textFocusGainedConn then self.textFocusGainedConn:Disconnect() end
			if self.windowFocusConn then self.windowFocusConn:Disconnect() end
		end

		self.enabled = enable
		return true
	end

	return Keyboard
end

local function _Gamepad()
	local BaseCharacterController = _BaseCharacterController()
	local Gamepad = setmetatable({}, BaseCharacterController)
	Gamepad.__index = Gamepad
	local NONE = Enum.UserInputType.None

	function Gamepad.new(priority)
		local self = setmetatable(BaseCharacterController.new(), Gamepad)
		self.CONTROL_ACTION_PRIORITY = priority
		self.activeGamepad = NONE
		return self
	end

	function Gamepad:GetHighestPriorityGamepad()
		local best = NONE
		for _, gp in pairs(UserInputService:GetConnectedGamepads()) do
			if gp.Value < best.Value then best = gp end
		end
		return best
	end

	function Gamepad:Enable(enable)
		if not UserInputService.GamepadEnabled then return false end
		if enable == self.enabled then return true end
		self.moveVector = Vector3.zero
		self.isJumping = false

		if enable then
			self.activeGamepad = self:GetHighestPriorityGamepad()
			if self.activeGamepad == NONE then return false end

			ContextActionService:BindActionAtPriority("WallWalkGamepadJump", function(_, state)
				self.isJumping = (state == Enum.UserInputState.Begin)
				return Enum.ContextActionResult.Sink
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.KeyCode.ButtonA)

			ContextActionService:BindActionAtPriority("WallWalkGamepadMove", function(_, state, input)
				if state == Enum.UserInputState.Cancel then
					self.moveVector = Vector3.zero
					return Enum.ContextActionResult.Sink
				end
				if input.KeyCode == Enum.KeyCode.Thumbstick1 then
					if input.Position.Magnitude > 0.2 then
						self.moveVector = Vector3.new(input.Position.X, 0, -input.Position.Y)
					else
						self.moveVector = Vector3.zero
					end
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
			end, false, self.CONTROL_ACTION_PRIORITY, Enum.KeyCode.Thumbstick1)
		else
			ContextActionService:UnbindAction("WallWalkGamepadJump")
			ContextActionService:UnbindAction("WallWalkGamepadMove")
			self.activeGamepad = NONE
		end

		self.enabled = enable
		return true
	end

	return Gamepad
end

local function _ControlModule()
	local ControlModule = {}
	ControlModule.__index = ControlModule
	local Keyboard = _Keyboard()
	local Gamepad = _Gamepad()
	local PRIORITY = Enum.ContextActionPriority.Default.Value

	function ControlModule.new()
		local self = setmetatable({}, ControlModule)
		self.controllers = {}
		self.activeController = nil
		self.moveFunction = LocalPlayer.Move
		self.humanoid = nil

		local function onChar(char)
			self.humanoid = char:WaitForChild("Humanoid")
		end
		if LocalPlayer.Character then task.spawn(onChar, LocalPlayer.Character) end
		LocalPlayer.CharacterAdded:Connect(onChar)
		LocalPlayer.CharacterRemoving:Connect(function() self.humanoid = nil end)

		local function updateInputType(inputType)
			local target = Keyboard
			if inputType == Enum.UserInputType.Gamepad1 or inputType == Enum.UserInputType.Gamepad2 then
				target = Gamepad
			end
			if not self.controllers[target] then
				self.controllers[target] = target.new(PRIORITY)
			end
			if self.activeController ~= self.controllers[target] then
				if self.activeController then self.activeController:Enable(false) end
				self.activeController = self.controllers[target]
				self.activeController:Enable(true)
			end
		end

		updateInputType(UserInputService:GetLastInputType())
		UserInputService.LastInputTypeChanged:Connect(updateInputType)

		self.controlBound = false
		function self:BindControl()
			if self.controlBound then return end
			self.controlBound = true
			RunService:BindToRenderStep("WallWalkControlStep", Enum.RenderPriority.Input.Value, function(dt)
				self:OnRenderStepped(dt)
			end)
		end

		function self:UnbindControl()
			if not self.controlBound then return end
			self.controlBound = false
			pcall(function() RunService:UnbindFromRenderStep("WallWalkControlStep") end)
		end

		function self:SetWallWalkActive(active)
			self.wallWalkActive = (active == true)
			if self.wallWalkActive then
				self:BindControl()
			else
				self:UnbindControl()
			end
		end

		return self
	end

	function ControlModule:GetMoveVector()
		return self.activeController and self.activeController:GetMoveVector() or Vector3.zero
	end

	function ControlModule:IsJumping()
		return self.activeController and self.activeController:GetIsJumping() or false
	end

	local function calculateRawMoveVector(humanoid, cameraRelativeMoveVector)
		local camera = Workspace.CurrentCamera
		if not camera then return cameraRelativeMoveVector end
		if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			return camera.CFrame:VectorToWorldSpace(cameraRelativeMoveVector)
		end

		local c, s
		local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = camera.CFrame:GetComponents()
		if R12 < 1 and R12 > -1 then
			c = R22
			s = R02
		else
			c = R00
			s = -R01 * math.sign(R12)
		end
		local norm = math.sqrt(c * c + s * s)
		if norm < 1e-5 then return Vector3.zero end
		return Vector3.new(
			(c * cameraRelativeMoveVector.X + s * cameraRelativeMoveVector.Z) / norm,
			0,
			(c * cameraRelativeMoveVector.Z - s * cameraRelativeMoveVector.X) / norm
		)
	end

	function ControlModule:OnRenderStepped(dt)
		if not self.wallWalkActive then return end
		if self.activeController and self.activeController.enabled and self.humanoid then
			self.activeController:OnRenderStepped(dt)
			local moveVector = self.activeController:GetMoveVector()
			if self.activeController:IsMoveVectorCameraRelative() then
				moveVector = calculateRawMoveVector(self.humanoid, moveVector)
			end
			self.moveFunction(LocalPlayer, moveVector, false)
			if self.activeController:GetIsJumping() then
				self.humanoid.Jump = true
			end
		end
	end

	return ControlModule.new()
end

local function _CreateSoundsSystem()
	pcall(function()
		local char = LocalPlayer and LocalPlayer.Character
		if char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("Sound") and string.sub(d.Name, 1, 3) == "WW_" then
					d:Destroy()
				end
			end
		end
	end)
	local SetState = Instance.new("BindableEvent")
	return SetState
end

local StateTracker = {}
StateTracker.__index = StateTracker

function StateTracker.new(humanoid, soundState)
	local self = setmetatable({}, StateTracker)
	self.Humanoid = humanoid
	self.HRP = humanoid.RootPart
	self.Speed = 0
	self.State = "onRunning"
	self.Jumped = false
	self.JumpTick = tick()
	self.SoundState = soundState
	self._ChangedEvent = Instance.new("BindableEvent")
	self.Changed = self._ChangedEvent.Event
	return self
end

function StateTracker:Destroy()
	self._ChangedEvent:Destroy()
end

function StateTracker:RequestedJump()
	self.Jumped = true
	self.JumpTick = tick()
end

local STATEMAP = {
	onRunning = Enum.HumanoidStateType.Running,
	onJumping = Enum.HumanoidStateType.Jumping,
	onFreeFall = Enum.HumanoidStateType.Freefall,
}

function StateTracker:OnStep(gravityUp, grounded, isMoving)
	if not self.HRP then return end
	local cVelocity = self.HRP.AssemblyLinearVelocity
	local gVelocity = cVelocity:Dot(gravityUp)
	local oldState, oldSpeed = self.State, self.Speed
	local newState
	local newSpeed = cVelocity.Magnitude

	if not grounded then
		if gVelocity > 0 and self.Jumped then
			newState = "onJumping"
		else
			if gVelocity <= 0 then self.Jumped = false end
			newState = "onFreeFall"
		end
	else
		if self.Jumped and (tick() - self.JumpTick > 0.15) then
			self.Jumped = false
		end
		newSpeed = (cVelocity - gVelocity * gravityUp).Magnitude
		newState = "onRunning"
	end

	newSpeed = isMoving and newSpeed or 0
	if oldState ~= newState or (newState == "onRunning" and math.abs(oldSpeed - newSpeed) > 0.1) then
		self.State = newState
		self.Speed = newSpeed
		self.SoundState:Fire(STATEMAP[newState])
		self._ChangedEvent:Fire(self.State, self.Speed)
	end
end

local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new(character, humanoid)
	local self = setmetatable({}, AnimationHandler)
	self.Character = character
	self.Humanoid = humanoid
	self.Animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	self.Active = false
	self.CurrentTrack = nil
	self.CurrentName = ""
	self.Tracks = {}

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local animIds = isR15 and {
		idle = "rbxassetid://507766388",
		walk = "rbxassetid://507777826",
		run  = "rbxassetid://507767714",
		jump = "rbxassetid://507765000",
		fall = "rbxassetid://507767968",
	} or {
		idle = "rbxassetid://180435571",
		walk = "rbxassetid://180426354",
		run  = "rbxassetid://180426354",
		jump = "rbxassetid://125750702",
		fall = "rbxassetid://180436148",
	}

	for name, id in pairs(animIds) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return self.Animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = (name == "idle" or name == "walk" or name == "run" or name == "fall")
			self.Tracks[name] = track
		end
	end

	return self
end

function AnimationHandler:PlayTrack(name, fadeTime, speed)
	if not self.Active then return end
	local track = self.Tracks[name]
	if not track then return end

	if self.CurrentTrack ~= track then
		if self.CurrentTrack then
			self.CurrentTrack:Stop(fadeTime or 0.15)
		end
		self.CurrentTrack = track
		self.CurrentName = name
		track:Play(fadeTime or 0.15)
	end
	if speed then
		track:AdjustSpeed(speed)
	end
end

function AnimationHandler:SetEnabled(enabled)
	self.Active = enabled
	local animateScript = self.Character:FindFirstChild("Animate")

	if enabled then
		if animateScript and animateScript:IsA("LocalScript") then
			animateScript.Disabled = true
		end
		for _, playingTrack in ipairs(self.Animator:GetPlayingAnimationTracks()) do
			playingTrack:Stop(0.1)
		end
		self:PlayTrack("idle", 0.1, 1)
	else
		if self.CurrentTrack then
			self.CurrentTrack:Stop(0.1)
			self.CurrentTrack = nil
			self.CurrentName = ""
		end
		for _, track in pairs(self.Tracks) do
			if track.IsPlaying then
				track:Stop(0.1)
			end
		end
		if animateScript and animateScript:IsA("LocalScript") then
			animateScript.Disabled = false
		end
	end
end

function AnimationHandler:Run(stateName, speed)
	if not self.Active then return end
	if stateName == "onRunning" then
		if speed and speed > 0.5 then
			local baseSpeed = (self.Humanoid.RigType == Enum.HumanoidRigType.R15) and 16 or 14.5
			local animToUse = (speed > 13 and self.Tracks.run) and "run" or "walk"
			self:PlayTrack(animToUse, 0.15, math.clamp(speed / baseSpeed, 0.4, 2.5))
		else
			self:PlayTrack("idle", 0.15, 1)
		end
	elseif stateName == "onJumping" then
		self:PlayTrack("jump", 0.1, 1)
	elseif stateName == "onFreeFall" then
		self:PlayTrack("fall", 0.2, 1)
	end
end

function AnimationHandler:Destroy()
	self:SetEnabled(false)
	for _, track in pairs(self.Tracks) do
		track:Destroy()
	end
	self.Tracks = {}
end

local CachedModelObjects = nil
local function getOriginalModelObjects()
	if CachedModelObjects ~= nil then
		return CachedModelObjects or nil
	end
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://17267177523")
	end)
	if ok and objs and objs[1] then
		local model = objs[1]
		local s = model:FindFirstChild("Sphere")
		local f = model:FindFirstChild("Floor")
		local v = model:FindFirstChild("VectorForce")
		local g = model:FindFirstChild("BodyGyro")
		if s and f and v and g then
			CachedModelObjects = { Sphere = s, Floor = f, VectorForce = v, BodyGyro = g }
			return CachedModelObjects
		end
	end
	CachedModelObjects = false
	return nil
end

local function initPhysicsObjects(character, hrp, humanoid)
	local isR15 = (humanoid.RigType == Enum.HumanoidRigType.R15)
	local height = isR15 and (humanoid.HipHeight + 0.05) or 2
	local rootAttachment = isR15 and hrp:WaitForChild("RootRigAttachment") or hrp:WaitForChild("RootAttachment")

	local orig = getOriginalModelObjects()
	if orig then
		local sphere = orig.Sphere:Clone()
		sphere.Parent = character

		local floor = orig.Floor:Clone()
		floor.Parent = character

		local weld = Instance.new("Weld")
		weld.C0 = CFrame.new(0, -height, 0.1)
		weld.Part0 = hrp
		weld.Part1 = sphere
		weld.Parent = sphere

		local weld2 = Instance.new("Weld")
		weld2.C0 = CFrame.new(0, -(height + 1.5), 0)
		weld2.Part0 = hrp
		weld2.Part1 = floor
		weld2.Parent = floor

		local gyro = orig.BodyGyro:Clone()
		gyro.CFrame = hrp.CFrame
		gyro.Parent = hrp

		local vForce = orig.VectorForce:Clone()
		vForce.Attachment0 = rootAttachment
		vForce.Parent = hrp

		return sphere, gyro, vForce, floor
	end

	local sphere = Instance.new("Part")
	sphere.Name = "Sphere"
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(2, 2, 2)
	sphere.Transparency = 1
	sphere.CanCollide = true
	sphere.Massless = true
	sphere.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 100, 100)
	sphere.Parent = character

	local weld = Instance.new("Weld")
	weld.C0 = CFrame.new(0, -height, 0.1)
	weld.Part0 = hrp
	weld.Part1 = sphere
	weld.Parent = sphere

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(1.5, 1, 1.5)
	floor.Transparency = 1
	floor.CanCollide = false
	floor.Massless = true
	floor.Parent = character

	local weld2 = Instance.new("Weld")
	weld2.C0 = CFrame.new(0, -(height + 1.5), 0)
	weld2.Part0 = hrp
	weld2.Part1 = floor
	weld2.Parent = floor

	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	gyro.P = 25000
	gyro.D = 1000
	gyro.CFrame = hrp.CFrame
	gyro.Parent = hrp

	local vForce = Instance.new("VectorForce")
	vForce.Attachment0 = rootAttachment
	vForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vForce.ApplyAtCenterOfMass = true
	vForce.Force = Vector3.zero
	vForce.Parent = hrp

	return sphere, gyro, vForce, floor
end

local ExecutedPlayerModule = {
	cameras = _CameraModule(),
	controls = _ControlModule(),
}
local ExecutedSounds = _CreateSoundsSystem()

local GravityController = {}
GravityController.__index = GravityController

local ZERO = Vector3.new(0, 0, 0)
local UNIT_Y = Vector3.new(0, 1, 0)
local IDENTITYCF = CFrame.new()
local JUMPMODIFIER = 1.2
local TRANSITION = 0.15
local WALKF = 200 / 3

local function getRotationBetween(u, v, axis)
	local dot, uxv = u:Dot(v), u:Cross(v)
	if dot < -0.99999 then
		local safeAxis = axis.Magnitude > 1e-4 and axis.Unit or Vector3.new(1, 0, 0)
		return CFrame.fromAxisAngle(safeAxis, math.pi)
	end
	return CFrame.new(0, 0, 0, uxv.X, uxv.Y, uxv.Z, 1 + dot)
end

local function lookAtSafe(pos, forward, up)
	if forward.Magnitude < 1e-4 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end
	local r = forward:Cross(up)
	if r.Magnitude < 1e-4 then
		r = Vector3.new(1, 0, 0)
	else
		r = r.Unit
	end
	local u = r:Cross(forward).Unit
	return CFrame.fromMatrix(pos, r, u)
end

local function getMass(array)
	local mass = 0
	for _, part in next, array do
		if part:IsA("BasePart") then
			mass = mass + part:GetMass()
		end
	end
	return math.max(mass, 1)
end

function GravityController.new(player, initialEnabled)
	local self = setmetatable({}, GravityController)
	self.Controls = ExecutedPlayerModule.controls
	self.Camera = ExecutedPlayerModule.cameras

	self.Player = player
	self.Character = player.Character
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.HRP = self.Character:WaitForChild("HumanoidRootPart")

	self.Enabled = false
	self.Destroyed = false
	self.GravityUp = UNIT_Y
	self.LastPart = Workspace.Terrain
	self.LastPartCFrame = IDENTITYCF

	self.AnimationHandler = AnimationHandler.new(self.Character, self.Humanoid)
	self.StateTracker = StateTracker.new(self.Humanoid, ExecutedSounds)
	self.StateTracker.Changed:Connect(function(name, speed)
		self.AnimationHandler:Run(name, speed)
	end)

	local collider, gyro, vForce, floor = initPhysicsObjects(self.Character, self.HRP, self.Humanoid)
	floor.Touched:Connect(function() end)
	collider.Touched:Connect(function() end)

	self.Collider = collider
	self.Gyro = gyro
	self.DefaultGyroMaxTorque = gyro.MaxTorque
	self.VForce = vForce
	self.Floor = floor

	self.CharacterMass = getMass(self.Character:GetDescendants())
	self.AncestryCon = self.Character.AncestryChanged:Connect(function()
		if self.Character and self.Character.Parent then
			self.CharacterMass = getMass(self.Character:GetDescendants())
		end
	end)

	function self.Camera.GetUpVector()
		if self.Destroyed or not self.Enabled then
			return UNIT_Y
		end
		return self.GravityUp
	end

	self.JumpCon = RunService.RenderStepped:Connect(function()
		if self.Enabled and self.Controls:IsJumping() then
			self:OnJumpRequest()
		end
	end)

	self.DeathCon = self.Humanoid.Died:Connect(function()
		self:Destroy()
	end)

	self.SeatCon = self.Humanoid.Seated:Connect(function(active)
		if active and self.Enabled then
			self:SetEnabled(false)
		end
	end)

	self.HeartCon = RunService.Heartbeat:Connect(function(dt)
		if self.Enabled then
			self:OnHeartbeatStep(dt)
		end
	end)

	RunService:BindToRenderStep("WallWalkGravityStep", Enum.RenderPriority.Input.Value + 1, function(dt)
		if self.Enabled then
			self:OnGravityStep(dt)
		end
	end)

	self:SetEnabled(initialEnabled ~= false)
	return self
end

function GravityController:SetEnabled(state)
	if self.Destroyed or self.Enabled == state then return end
	self.Enabled = state
	self.Camera:SetWallWalkActive(state)

	if state then
		self.GravityUp = UNIT_Y
		self.LastPart = Workspace.Terrain
		self.CharacterMass = getMass(self.Character:GetDescendants())

		if self.Collider then self.Collider.CanCollide = true end
		if self.Gyro then
			self.Gyro.MaxTorque = self.DefaultGyroMaxTorque
			self.Gyro.CFrame = self.HRP.CFrame
		end
		if self.VForce then
			self.VForce.Force = ZERO
			self.VForce.Enabled = true
		end

		self.Humanoid.AutoRotate = false
		self.Humanoid.PlatformStand = true
		self.AnimationHandler:SetEnabled(true)
	else
		self.GravityUp = UNIT_Y
		self.LastPart = nil

		if self.VForce then
			self.VForce.Force = ZERO
			self.VForce.Enabled = false
		end
		if self.Gyro then
			self.Gyro.MaxTorque = ZERO
		end
		if self.Collider then
			self.Collider.CanCollide = false
		end

		self.AnimationHandler:SetEnabled(false)
		self.Humanoid.PlatformStand = false
		self.Humanoid.AutoRotate = true

		if self.HRP and self.HRP.Parent and (self.GravityUp - UNIT_Y).Magnitude > 0.05 then
			local look = self.HRP.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			if flatLook.Magnitude < 1e-3 then
				local camLook = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0, 0, -1)
				flatLook = Vector3.new(camLook.X, 0, camLook.Z)
			end
			if flatLook.Magnitude < 1e-3 then
				flatLook = Vector3.new(0, 0, -1)
			end
			self.HRP.CFrame = CFrame.lookAt(self.HRP.Position, self.HRP.Position + flatLook.Unit, UNIT_Y)
			self.HRP.AssemblyAngularVelocity = ZERO
		end

		if self.Character then
			for _, desc in ipairs(self.Character:GetDescendants()) do
				if desc:IsA("BasePart") or desc:IsA("Decal") then
					desc.LocalTransparencyModifier = 0
				end
			end
		end

		if self.Humanoid and self.Humanoid.Health > 0 then
			self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
end

function GravityController:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	self:SetEnabled(false)

	if self.JumpCon then self.JumpCon:Disconnect(); self.JumpCon = nil end
	if self.DeathCon then self.DeathCon:Disconnect(); self.DeathCon = nil end
	if self.SeatCon then self.SeatCon:Disconnect(); self.SeatCon = nil end
	if self.HeartCon then self.HeartCon:Disconnect(); self.HeartCon = nil end
	if self.AncestryCon then self.AncestryCon:Disconnect(); self.AncestryCon = nil end

	pcall(function() RunService:UnbindFromRenderStep("WallWalkGravityStep") end)

	if self.Collider then pcall(function() self.Collider:Destroy() end); self.Collider = nil end
	if self.Floor then pcall(function() self.Floor:Destroy() end); self.Floor = nil end
	if self.VForce then pcall(function() self.VForce:Destroy() end); self.VForce = nil end
	if self.Gyro then pcall(function() self.Gyro:Destroy() end); self.Gyro = nil end
	if self.StateTracker then pcall(function() self.StateTracker:Destroy() end); self.StateTracker = nil end
	if self.AnimationHandler then pcall(function() self.AnimationHandler:Destroy() end); self.AnimationHandler = nil end

	if self.Humanoid and self.Humanoid.Parent then
		self.Humanoid.PlatformStand = false
		self.Humanoid.AutoRotate = true
		if self.Humanoid.Health > 0 then
			self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
end

function GravityController:GetRaycastParams()
	local ignoreList = {}
	for i, player in next, Players:GetPlayers() do
		if player.Character then
			ignoreList[#ignoreList + 1] = player.Character
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.RespectCanCollide = true
	return params
end

function GravityController:IsGrounded(isJumpCheck)
	if not self.Floor or not self.Collider then return false end
	if not isJumpCheck then
		local parts = self.Floor:GetTouchingParts()
		for _, part in next, parts do
			if part.CanCollide and not part:IsDescendantOf(self.Character) then
				return true
			end
		end
	else
		if self.StateTracker.Jumped then
			return false
		end

		local valid = {}
		local parts = self.Collider:GetTouchingParts()
		for _, part in next, parts do
			if part.CanCollide and not part:IsDescendantOf(self.Character) then
				table.insert(valid, part)
			end
		end

		if #valid > 0 then
			local max = math.cos(self.Humanoid.MaxSlopeAngle)
			local ray = Ray.new(self.Collider.Position, -10 * self.GravityUp)
			local hit, _, normal = Workspace:FindPartOnRayWithWhitelist(ray, valid, true)
			if hit and max <= self.GravityUp:Dot(normal) then
				return true
			end
		end
	end
	return false
end

function GravityController:OnJumpRequest()
	if not self.StateTracker.Jumped and self:IsGrounded(true) then
		local hrpVel = self.HRP.AssemblyLinearVelocity
		self.HRP.AssemblyLinearVelocity = hrpVel + self.GravityUp * self.Humanoid.JumpPower * JUMPMODIFIER
		self.StateTracker:RequestedJump()
	end
end

function GravityController:OnHeartbeatStep()
	if not self.Collider or not self.HRP then return end
	local res = Workspace:Raycast(self.Collider.Position, -1.1 * self.GravityUp, self:GetRaycastParams())
	local hit = res and res.Instance or nil
	local lastPart = self.LastPart

	if hit and lastPart and lastPart == hit then
		local offset = self.LastPartCFrame:ToObjectSpace(self.HRP.CFrame)
		self.HRP.CFrame = hit.CFrame:ToWorldSpace(offset)
	end

	self.LastPart = hit
	self.LastPartCFrame = hit and hit.CFrame or IDENTITYCF
end

local PI2 = math.pi * 2
local LOWER_RADIUS_OFFSET = 3
local NUM_DOWN_RAYS = 24
local ODD_DOWN_RAY_START_RADIUS = 3
local EVEN_DOWN_RAY_START_RADIUS = 2
local ODD_DOWN_RAY_END_RADIUS = 1.66666
local EVEN_DOWN_RAY_END_RADIUS = 1

local NUM_FEELER_RAYS = 9
local FEELER_LENGTH = 2
local FEELER_START_OFFSET = 2
local FEELER_RADIUS = 3.5
local FEELER_APEX_OFFSET = 1
local FEELER_WEIGHTING = 8

function GravityController:GetGravityUp(oldGravityUp)
	local rayParams = self:GetRaycastParams()
	local hrpCF = self.HRP.CFrame
	local isR15 = (self.Humanoid.RigType == Enum.HumanoidRigType.R15)

	local origin = isR15 and hrpCF.Position or (hrpCF.Position + 0.35 * oldGravityUp)
	local crossVec = math.abs(hrpCF.LookVector:Dot(oldGravityUp)) < 0.999
		and hrpCF.LookVector:Cross(oldGravityUp)
		or hrpCF.RightVector:Cross(oldGravityUp)
	local radialVector = crossVec.Magnitude > 1e-4 and crossVec.Unit or Vector3.new(1, 0, 0)

	local centerRayLength = 25
	local centerRes = Workspace:Raycast(origin, -centerRayLength * oldGravityUp, rayParams)

	local downHitCount = 0
	local centerRayHitCount = 0
	local mainDownNormal = ZERO
	if centerRes then
		mainDownNormal = centerRes.Normal
		centerRayHitCount = 0
	end

	local downRaySum = ZERO
	for i = 1, NUM_DOWN_RAYS do
		local dtheta = PI2 * ((i - 1) / NUM_DOWN_RAYS)
		local angleWeight = 0.25 + 0.75 * math.abs(math.cos(dtheta))
		local isEvenRay = (i % 2 == 0)
		local startRadius = isEvenRay and EVEN_DOWN_RAY_START_RADIUS or ODD_DOWN_RAY_START_RADIUS
		local endRadius = isEvenRay and EVEN_DOWN_RAY_END_RADIUS or ODD_DOWN_RAY_END_RADIUS

		local offset = CFrame.fromAxisAngle(oldGravityUp, dtheta) * radialVector
		local dir = (LOWER_RADIUS_OFFSET * -oldGravityUp + (endRadius - startRadius) * offset)
		local res = Workspace:Raycast(origin + startRadius * offset, centerRayLength * dir.Unit, rayParams)
		if res then
			downRaySum = downRaySum + angleWeight * res.Normal
			downHitCount = downHitCount + 1
		end
	end

	local feelerHitCount = 0
	local feelerNormalSum = ZERO
	for i = 1, NUM_FEELER_RAYS do
		local dtheta = PI2 * ((i - 1) / NUM_FEELER_RAYS)
		local angleWeight = 0.25 + 0.75 * math.abs(math.cos(dtheta))
		local offset = CFrame.fromAxisAngle(oldGravityUp, dtheta) * radialVector
		local dir = (FEELER_RADIUS * offset + LOWER_RADIUS_OFFSET * -oldGravityUp).Unit
		local feelerOrigin = origin - FEELER_APEX_OFFSET * -oldGravityUp + FEELER_START_OFFSET * dir

		local res = Workspace:Raycast(feelerOrigin, FEELER_LENGTH * dir, rayParams)
		if res then
			feelerNormalSum = feelerNormalSum + FEELER_WEIGHTING * angleWeight * res.Normal
			feelerHitCount = feelerHitCount + 1
		end
	end

	if (centerRayHitCount + downHitCount + feelerHitCount) > 0 then
		local normalSum = mainDownNormal + downRaySum + feelerNormalSum
		if normalSum.Magnitude > 1e-4 then
			return normalSum.Unit
		end
	end

	return oldGravityUp
end

function GravityController:OnGravityStep(dt)
	if not self.HRP or not self.HRP.Parent then return end
	local safeDt = math.clamp(dt, 1 / 240, 0.1)

	local oldGravity = self.GravityUp
	local rawNewGravity = self:GetGravityUp(oldGravity)

	local camCF = Workspace.CurrentCamera.CFrame
	local rotation = getRotationBetween(oldGravity, rawNewGravity, camCF.RightVector)
	rotation = IDENTITYCF:Lerp(rotation, TRANSITION)

	local upVec = (rotation * oldGravity).Unit
	self.GravityUp = upVec

	local fDot = camCF.LookVector:Dot(upVec)
	local projLook = camCF.LookVector - fDot * upVec
	local signDot = fDot >= 0 and 1 or -1
	local rawUpProj = -signDot * (camCF.UpVector - camCF.UpVector:Dot(upVec) * upVec)

	local blend = math.clamp((math.abs(fDot) - 0.7) / 0.28, 0, 1)
	blend = blend * blend * (3 - 2 * blend)

	local dirLook = projLook.Magnitude > 1e-4 and projLook.Unit or Vector3.zero
	local dirUp = rawUpProj.Magnitude > 1e-4 and rawUpProj.Unit or dirLook
	local blendedForward = dirLook:Lerp(dirUp, blend)
	if blendedForward.Magnitude < 1e-4 then
		blendedForward = dirUp.Magnitude > 1e-4 and dirUp or camCF.RightVector:Cross(upVec)
	end

	local camForward = blendedForward.Unit
	local left = upVec:Cross(camForward).Unit
	local forward = -left:Cross(upVec).Unit

	local move = self.Controls:GetMoveVector()
	local worldMove = forward * move.Z - left * move.X
	if worldMove.Magnitude > 1 then
		worldMove = worldMove.Unit
	end
	local isInputMoving = worldMove.Magnitude > 0.01

	local hrpCFLook = self.HRP.CFrame.LookVector
	local charF = hrpCFLook:Dot(forward) * forward + hrpCFLook:Dot(left) * left
	if charF.Magnitude < 1e-4 then
		charF = forward
	else
		charF = charF.Unit
	end
	local charR = charF:Cross(upVec).Unit
	local newCharCF = CFrame.fromMatrix(ZERO, charR, upVec, -charF)

	local newCharRotation = IDENTITYCF
	if isInputMoving then
		newCharRotation = IDENTITYCF:Lerp(getRotationBetween(charF, worldMove, upVec), 0.7)
	end

	local g = Workspace.Gravity
	local gForce = g * self.CharacterMass * (UNIT_Y - upVec)

	local cVelocity = self.HRP.AssemblyLinearVelocity
	local tVelocity = self.Humanoid.WalkSpeed * worldMove
	local gVelocity = cVelocity:Dot(upVec) * upVec
	local hVelocity = cVelocity - gVelocity

	if hVelocity:Dot(hVelocity) < 1 then
		hVelocity = ZERO
	end

	local dVelocity = tVelocity - hVelocity
	local walkForceM = math.min(10000, WALKF * self.CharacterMass * dVelocity.Magnitude / (safeDt * 60))
	local walkForce = walkForceM > 0.001 and (dVelocity.Unit * walkForceM) or ZERO

	local charRotation = newCharRotation * newCharCF

	if self.Camera:IsCamRelative() then
		local lv = camCF.LookVector
		local hlv = lv - upVec:Dot(lv) * upVec
		if hlv.Magnitude < 0.05 then
			local fallbackDir = -math.sign(upVec:Dot(lv)) * camCF.UpVector
			hlv = fallbackDir - upVec:Dot(fallbackDir) * upVec
		end
		if hlv.Magnitude > 1e-3 then
			charRotation = lookAtSafe(ZERO, hlv.Unit, upVec)
		end
	end

	self.StateTracker:OnStep(upVec, self:IsGrounded(false), isInputMoving)

	self.VForce.Force = walkForce + gForce
	self.Gyro.CFrame = charRotation
end

local wallWalkEnabled = false
S.WallWalk = false
local activeController = nil

local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
local oldGui = PlayerGui:FindFirstChild("WallWalkToggleUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WallWalkToggleUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = (S.WallWalkShowButton == true)
screenGui.Parent = PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 12)
toggleButton.Size = UDim2.new(0, 165, 0, 36)
toggleButton.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
toggleButton.BackgroundTransparency = 0.15
toggleButton.BorderSizePixel = 0
toggleButton.AutoButtonColor = false
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.TextSize = 13
toggleButton.TextColor3 = Color3.fromRGB(235, 238, 250)
toggleButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleButton

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = toggleButton

local function updateUI()
    local keyName = (S.WallWalkKey and S.WallWalkKey ~= Enum.KeyCode.Unknown) and S.WallWalkKey.Name or "V"
    if wallWalkEnabled then
        toggleButton.Text = "Wall Walk: ON  [" .. keyName .. "]"
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(247, 118, 172) }):Play()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 26, 44) }):Play()
    else
        toggleButton.Text = "Wall Walk: OFF [" .. keyName .. "]"
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(90, 96, 120) }):Play()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(22, 24, 34) }):Play()
    end
end

local function attachToCharacter(character)
    if activeController then
        activeController:Destroy()
        activeController = nil
    end
    if not wallWalkEnabled then return end
    character:WaitForChild("HumanoidRootPart", 10)
    character:WaitForChild("Humanoid", 10)
    if not character.Parent then return end
    activeController = GravityController.new(LocalPlayer, true)
end

local function setWallWalkEnabled(state)
    wallWalkEnabled = (state == true)
    S.WallWalk = wallWalkEnabled
    updateUI()
    if ExecutedPlayerModule and ExecutedPlayerModule.cameras and ExecutedPlayerModule.cameras.SetWallWalkActive then
        ExecutedPlayerModule.cameras:SetWallWalkActive(wallWalkEnabled)
    end
    if ExecutedPlayerModule and ExecutedPlayerModule.controls and ExecutedPlayerModule.controls.SetWallWalkActive then
        ExecutedPlayerModule.controls:SetWallWalkActive(wallWalkEnabled)
    end
    if wallWalkEnabled then
        if not activeController and LocalPlayer.Character then
            attachToCharacter(LocalPlayer.Character)
        elseif activeController and not activeController.Destroyed then
            activeController:SetEnabled(true)
        end
    else
        if activeController then
            activeController:Destroy()
            activeController = nil
        end
        pcall(function() RunService:UnbindFromRenderStep("WallWalkGravityStep") end)
        pcall(function() RunService:UnbindFromRenderStep("WallWalkCameraRenderUpdate") end)
        pcall(function() RunService:UnbindFromRenderStep("WallWalkControlStep") end)
    end
end

local function toggleWallWalk()
    local newState = not wallWalkEnabled
    if UI.moduleButtons and UI.moduleButtons["Wall Walk"] and UI.moduleButtons["Wall Walk"].SetActive then
        UI.moduleButtons["Wall Walk"].SetActive(newState)
    else
        setWallWalkEnabled(newState)
        saveConfig()
    end
end

toggleButton.MouseButton1Click:Connect(toggleWallWalk)

local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local currentKey = S.WallWalkKey or Enum.KeyCode.V
        if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
            toggleWallWalk()
        end
    end
end)

local charAddedConn = LocalPlayer.CharacterAdded:Connect(attachToCharacter)
if LocalPlayer.Character and wallWalkEnabled then
    task.spawn(attachToCharacter, LocalPlayer.Character)
end

if ExecutedPlayerModule and ExecutedPlayerModule.cameras and ExecutedPlayerModule.cameras.SetWallWalkActive then
    ExecutedPlayerModule.cameras:SetWallWalkActive(false)
end
if ExecutedPlayerModule and ExecutedPlayerModule.controls and ExecutedPlayerModule.controls.SetWallWalkActive then
    ExecutedPlayerModule.controls:SetWallWalkActive(false)
end

updateUI()

local function cleanupAll()
    if inputConn then inputConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end
    if activeController then activeController:Destroy(); activeController = nil end
    if ExecutedPlayerModule and ExecutedPlayerModule.cameras then
        pcall(function() ExecutedPlayerModule.cameras:Destroy() end)
    end
    pcall(function() RunService:UnbindFromRenderStep("WallWalkCameraRenderUpdate") end)
    pcall(function() RunService:UnbindFromRenderStep("WallWalkControlStep") end)
    pcall(function() RunService:UnbindFromRenderStep("WallWalkGravityStep") end)
    if wallWalkEnabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserGameSettings.RotationType = Enum.RotationType.MovementRelative
    end
    if screenGui then screenGui:Destroy() end
    pcall(function()
        local char = LocalPlayer and LocalPlayer.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("Sound") and string.sub(d.Name, 1, 3) == "WW_" then
                    d:Destroy()
                end
            end
        end
    end)
end

VH.WallWalkCleanup = cleanupAll
if getgenv then
    getgenv()._WallWalkCleanup = cleanupAll
else
    _G._WallWalkCleanup = cleanupAll
end

registerModule("Movement", "Wall Walk", 300, 50, true, S.WallWalk, function(v)
    setWallWalkEnabled(v)
    saveConfig()
end, function(drawer)
    addKeybindOption(drawer, "Wall Walk Key", S.WallWalkKey or Enum.KeyCode.V, function(k)
        S.WallWalkKey = k
        updateUI()
        saveConfig()
    end)
    addToggleOption(drawer, "Show Screen Button", S.WallWalkShowButton or false, function(v)
        S.WallWalkShowButton = v
        if screenGui then screenGui.Enabled = v end
        saveConfig()
    end)
end, false)
