--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick

local PlayersService = game:GetService("Players")
local CoreGuiService = game:GetService("CoreGui")

local sharedMobileGui

local function ensureMobileUI()
	if sharedMobileGui and sharedMobileGui.Parent then
		return sharedMobileGui
	end

	local parent

	if gethui then
		parent = gethui()
	else
		local localPlayer = PlayersService.LocalPlayer or PlayersService.PlayerAdded:Wait()
		local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
		parent = playerGui or CoreGuiService
	end

	if parent:FindFirstChild("ExunysMobileAimbotUI") then
		sharedMobileGui = parent:FindFirstChild("ExunysMobileAimbotUI")
		return sharedMobileGui
	end

	sharedMobileGui = Instance.new("ScreenGui")
	sharedMobileGui.Name = "ExunysMobileAimbotUI"
	sharedMobileGui.ResetOnSpawn = false
	sharedMobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	sharedMobileGui.IgnoreGuiInset = true
	sharedMobileGui.DisplayOrder = 99999

	if syn and syn.protect_gui then
		pcall(syn.protect_gui, sharedMobileGui)
	end

	sharedMobileGui.Parent = parent

	return sharedMobileGui
end

local function createFallbackCircle(nameSuffix, zIndex)
	local guiParent = ensureMobileUI()

	local frame = Instance.new("Frame")
	frame.Name = "FOVCircle_" .. nameSuffix
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(0, 0)
	frame.Size = UDim2.fromOffset(0, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.ZIndex = zIndex or 200
	frame.Parent = guiParent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0
	stroke.Parent = frame

	local state = {
		Visible = false,
		Position = Vector2.new(0, 0),
		Radius = 0,
		Thickness = 1,
		Transparency = 1,
		Color = Color3.fromRGB(255, 255, 255),
		Filled = false
	}

	local function applyState(key)
		if key == "Visible" then
			frame.Visible = state.Visible
		elseif key == "Position" then
			frame.Position = UDim2.fromOffset(state.Position.X, state.Position.Y)
		elseif key == "Radius" then
			local size = math.max(0, state.Radius * 2)
			frame.Size = UDim2.fromOffset(size, size)
		elseif key == "Thickness" then
			stroke.Thickness = math.max(1, state.Thickness)
		elseif key == "Transparency" then
			local alpha = math.clamp(state.Transparency, 0, 1)
			stroke.Transparency = 1 - alpha
			if state.Filled then
				frame.BackgroundTransparency = 1 - alpha
			else
				frame.BackgroundTransparency = 1
			end
		elseif key == "Color" then
			stroke.Color = state.Color
			if state.Filled then
				frame.BackgroundColor3 = state.Color
			end
		elseif key == "Filled" then
			if state.Filled then
				frame.BackgroundColor3 = state.Color
				frame.BackgroundTransparency = 1 - math.clamp(state.Transparency, 0, 1)
			else
				frame.BackgroundTransparency = 1
			end
		end
	end

	local proxy = {}

	local metatable = {
		__index = function(_, key)
			if key == "Remove" then
				return function()
					frame:Destroy()
				end
			elseif key == "__FRAME" then
				return frame
			elseif key == "__STROKE" then
				return stroke
			elseif key == "__STATE" then
				return state
			end

			return state[key]
		end,

		__newindex = function(_, key, value)
			state[key] = value
			applyState(key)
		end
	}

	return setmetatable(proxy, metatable)
end

local circleCounter = 0

local Drawingnew

if Drawing and Drawing.new then
	Drawingnew = Drawing.new
else
	Drawingnew = function(objectType)
		circleCounter += 1
		if objectType == "Circle" then
			return createFallbackCircle(tostring(circleCounter), 200 + circleCounter)
		end

		-- Fallback dummy object for unsupported Drawing types
		return setmetatable({}, {
			__index = function()
				return function() end
			end,
			__newindex = function() end
		})
	end
end

local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	-- Auxillary functions - if the executor doesn't support "getrawmetatable".

	__index = function(self, Index)
		return self[Index]
	end,

	__newindex = function(self, Index, Value)
		self[Index] = Value
	end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local GetService = __index(game, "GetService")

--// Services

local RunService = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService = GetService(game, "TweenService")
local Players = GetService(game, "Players")

--// Service Methods

local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")

--// Variables

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

--[[
local Degrade = false

do
	xpcall(function()
		local TemporaryDrawing = Drawingnew("Line")
		getrenderproperty = getupvalue(getmetatable(TemporaryDrawing).__index, 4)
		setrenderproperty = getupvalue(getmetatable(TemporaryDrawing).__newindex, 4)
		TemporaryDrawing.Remove(TemporaryDrawing)
	end, function()
		Degrade, getrenderproperty, setrenderproperty = true, function(Object, Key)
			return Object[Key]
		end, function(Object, Key, Value)
			Object[Key] = Value
		end
	end)

	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end
]]

--// Checking for multiple processes

if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
	ExunysDeveloperAimbot:Exit()
end

--// Environment

getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1 -- Bigger = Slower
	},

	Settings = {
		Enabled = true,

		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,

		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		Sensitivity2 = 3.5, -- mousemoverel Sensitivity

		LockMode = 1, -- 1 = CFrame; 2 = mousemoverel
		LockPart = "Head", -- Body part to lock on

		TriggerKey = nil,
		Toggle = true
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,

		Radius = 90,
		NumSides = 60,

		Thickness = 1,
		Transparency = 1,
		Filled = false,

		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().ExunysDeveloperAimbot

local ActivationButton

local function ensureActivationButton()
	local ui = ensureMobileUI()
	local button = ui:FindFirstChild("AimbotAimButton")

	if not button then
		button = Instance.new("TextButton")
		button.Name = "AimbotAimButton"
		button.AnchorPoint = Vector2.new(1, 1)
		button.Position = UDim2.new(1, -36, 1, -110)
		button.Size = UDim2.fromOffset(72, 72)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = "🎯"
		button.Font = Enum.Font.GothamBold
		button.TextSize = 28
		button.TextColor3 = Color3.new(1, 1, 1)
		button.ZIndex = 205
		button.Parent = ui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.25
		stroke.Parent = button

		if not button:FindFirstChild("Shadow") then
			local shadow = Instance.new("ImageLabel")
			shadow.Name = "Shadow"
			shadow.AnchorPoint = Vector2.new(0.5, 0.5)
			shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
			shadow.Size = UDim2.fromOffset(92, 92)
			shadow.BackgroundTransparency = 1
			shadow.Image = "rbxassetid://6015897843"
			shadow.ImageTransparency = 0.7
			shadow.ScaleType = Enum.ScaleType.Slice
			shadow.SliceCenter = Rect.new(100, 100, 100, 100)
			shadow.ZIndex = button.ZIndex - 1
			shadow.Parent = button
		end
	end

	ActivationButton = button
	return button
end

local function updateActivationButtonState()
	if not ActivationButton or not ActivationButton.Parent then
		return
	end

	if not Environment.Settings.Enabled then
		ActivationButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		ActivationButton.Text = "🚫"
		return
	end

	if Running then
		ActivationButton.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
		ActivationButton.Text = "🔒"
	else
		ActivationButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		ActivationButton.Text = "🎯"
	end
end

ensureActivationButton()
updateActivationButtonState()
Environment.ActivationButton = ActivationButton
Environment.MobileUI = sharedMobileGui

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Core Functions

local FixUsername = function(String)
	local Result

	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")

		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			Result = Name
		end
	end

	return Result
end

local GetRainbowColor = function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed

	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end

local ConvertVector = function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local CancelLock = function()
	Environment.Locked = nil

	local FOVCircle = Environment.FOVCircle--Degrade and Environment.FOVCircle or Environment.FOVCircle.__OBJECT

	setrenderproperty(FOVCircle, "Color", Environment.FOVSettings.Color)
	if OriginalSensitivity then
		__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	end

	if Animation then
		Animation:Cancel()
	end

	updateActivationButtonState()
end

local GetClosestPlayer = function()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
				local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					continue
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))

					for _, Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = Value
					end

					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
						continue
					end
				end

				local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance, Environment.Locked = Distance, Value
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end

local Load = function()
	Running = false
	updateActivationButtonState()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings, FOVCircle, FOVCircleOutline, FOVSettings, Offset = Environment.Settings, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.FOVSettings
	local lastEnabledState = Settings.Enabled

	--[[
	if not Degrade then
		FOVCircle, FOVCircleOutline = FOVCircle.__OBJECT, FOVCircleOutline.__OBJECT
	end
	]]

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()
		pcall(function()
			local OffsetToMoveDirection, LockPart = Settings.OffsetToMoveDirection, Settings.LockPart

			if Settings.Enabled ~= lastEnabledState then
				lastEnabledState = Settings.Enabled
				if not Settings.Enabled then
					Running = false
					CancelLock()
				else
					updateActivationButtonState()
				end
			else
				if not Settings.Enabled and Running then
					Running = false
					CancelLock()
				end
			end

			if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				-- Skip custom settings that aren't valid Circle properties
				if Index == "Color" or Index == "Enabled" or Index == "RainbowColor" or Index == "RainbowOutlineColor" or Index == "LockedColor" or Index == "OutlineColor" then
					continue
				end

				if pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end

			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)

			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()

			-- Safely calculate offset with nil checks
			if OffsetToMoveDirection and Environment.Locked then
				local Character = __index(Environment.Locked, "Character")
				local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
				Offset = Humanoid and __index(Humanoid, "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero
			else
				Offset = Vector3zero
			end

			if Environment.Locked then
				-- Validate that the locked character and part still exist
				local Character = __index(Environment.Locked, "Character")
				if not Character then
					CancelLock()
					return
				end
				
				local TargetPart = FindFirstChild(Character, LockPart)
				if not TargetPart then
					CancelLock()
					return
				end
				
				local LockedPosition_Vector3 = __index(TargetPart, "Position")
				if not LockedPosition_Vector3 then
					CancelLock()
					return
				end
				
				local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3 + Offset)

				if Environment.Settings.LockMode == 2 then
					if mousemoverel then
						mousemoverel((LockedPosition.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2, (LockedPosition.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2)
					end
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset))
					end

					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end

				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
			end
		end
		end)
	end)

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), function(Input)
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle

		if Typing then
			return
		end

		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			if Toggle then
				Running = not Running
				updateActivationButtonState()

				if not Running then
					CancelLock()
				end
			else
				Running = true
				updateActivationButtonState()
			end
		end
	end)

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle

		if Toggle or Typing then
			return
		end

		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = false
			CancelLock()
		end
	end)

	local button = ensureActivationButton()
	updateActivationButtonState()

	if ServiceConnections.ButtonConnection then
		ServiceConnections.ButtonConnection:Disconnect()
	end

	ServiceConnections.ButtonConnection = button.Activated:Connect(function()
		if not Settings.Enabled then
			Running = false
			updateActivationButtonState()
			return
		end

		Running = not Running
		if not Running then
			CancelLock()
		else
			updateActivationButtonState()
		end
	end)
end

--// Typing Check

ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

--// Functions

function Environment.Exit(self) -- METHOD | ExunysDeveloperAimbot:Exit(<void>)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")

	for Index, _ in next, ServiceConnections do
		Disconnect(ServiceConnections[Index])
	end

	if ServiceConnections.ButtonConnection then
		ServiceConnections.ButtonConnection:Disconnect()
		ServiceConnections.ButtonConnection = nil
	end

	Running = false
	updateActivationButtonState()
	CancelLock()

	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil

	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()

	if ActivationButton and ActivationButton.Parent then
		ActivationButton:Destroy()
	end

	ActivationButton = nil
	Environment.ActivationButton = nil

	if sharedMobileGui and sharedMobileGui.Parent then
		sharedMobileGui:Destroy()
	end

	sharedMobileGui = nil

	for index in next, ServiceConnections do
		ServiceConnections[index] = nil
	end

	getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart() -- ExunysDeveloperAimbot.Restart(<void>)
	for Index, _ in next, ServiceConnections do
		Disconnect(ServiceConnections[Index])
	end

	Load()
end

function Environment.Blacklist(self, Username) -- METHOD | ExunysDeveloperAimbot:Blacklist(<string> Player Name)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #2 \"Username\" <string>.")

	Username = FixUsername(Username)

	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: User "..Username.." couldn't be found.")

	self.Blacklisted[#self.Blacklisted + 1] = Username
end

function Environment.Whitelist(self, Username) -- METHOD | ExunysDeveloperAimbot:Whitelist(<string> Player Name)
	assert(self, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #2 \"Username\" <string>.")

	Username = FixUsername(Username)

	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." couldn't be found.")

	local Index = tablefind(self.Blacklisted, Username)

	assert(Index, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." is not blacklisted.")

	tableremove(self.Blacklisted, Index)
end

function Environment.GetClosestPlayer() -- ExunysDeveloperAimbot.GetClosestPlayer(<void>)
	GetClosestPlayer()
	local Value = Environment.Locked
	CancelLock()

	return Value
end

Environment.Load = Load -- ExunysDeveloperAimbot.Load()

setmetatable(Environment, {__call = Load})

return Environment
