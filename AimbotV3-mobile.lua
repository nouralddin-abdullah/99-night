--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick

-- Simplified Mobile Drawing API - More stable
local function CreateMobileDrawing(drawingType)
	if drawingType == "Circle" then
		local circleObject = {
			_screenGui = nil,
			_frame = nil,
			_stroke = nil,
			_visible = false,
			_radius = 90,
			_thickness = 1,
			_transparency = 1,
			_filled = false,
			_color = Color3.fromRGB(255, 255, 255),
			_position = Vector2.new(0, 0),
			_initialized = false
		}
		
		local function InitializeGUI()
			if circleObject._initialized then return end
			
			pcall(function()
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "MobileFOVCircle_" .. math.random(1000, 9999)
				screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				screenGui.DisplayOrder = 999999
				screenGui.IgnoreGuiInset = true
				screenGui.ResetOnSpawn = false
				
				if gethui then
					screenGui.Parent = gethui()
				elseif syn and syn.protect_gui then
					syn.protect_gui(screenGui)
					screenGui.Parent = game:GetService("CoreGui")
				else
					screenGui.Parent = game:GetService("CoreGui")
				end
				
				local frame = Instance.new("Frame")
				frame.Name = "Circle"
				frame.Size = UDim2.fromOffset(180, 180)
				frame.Position = UDim2.fromOffset(0, 0)
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.BackgroundTransparency = 1
				frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				frame.BorderSizePixel = 0
				frame.Parent = screenGui
				
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = frame
				
				local stroke = Instance.new("UIStroke")
				stroke.Thickness = 1
				stroke.Color = Color3.fromRGB(255, 255, 255)
				stroke.Transparency = 0
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Parent = frame
				
				circleObject._screenGui = screenGui
				circleObject._frame = frame
				circleObject._stroke = stroke
				circleObject._initialized = true
			end)
		end
		
		return setmetatable(circleObject, {
			__index = function(self, key)
				if key == "Visible" then
					return self._visible
				elseif key == "Radius" or key == "Thickness" or key == "Transparency" or key == "Filled" or key == "Color" or key == "Position" or key == "NumSides" then
					return self["_" .. string.lower(key)] or 60
				elseif key == "Remove" then
					return function()
						pcall(function()
							if self._screenGui then
								self._screenGui:Destroy()
							end
						end)
					end
				end
			end,
			__newindex = function(self, key, value)
				pcall(function()
					if key == "Visible" then
						self._visible = value
						if value and not self._initialized then
							InitializeGUI()
						end
						if self._screenGui then
							self._screenGui.Enabled = value
						end
					elseif key == "Radius" then
						self._radius = value
						if self._frame then
							self._frame.Size = UDim2.fromOffset(value * 2, value * 2)
						end
					elseif key == "Thickness" then
						self._thickness = value
						if self._stroke then
							self._stroke.Thickness = value
						end
					elseif key == "Transparency" then
						self._transparency = value
						if self._stroke then
							self._stroke.Transparency = 1 - value
						end
					elseif key == "Color" then
						self._color = value
						if self._stroke then
							self._stroke.Color = value
						end
					elseif key == "Position" then
						self._position = value
						if self._frame then
							self._frame.Position = UDim2.fromOffset(value.X, value.Y)
						end
					elseif key == "Filled" or key == "NumSides" then
						-- Ignore these for mobile
					end
				end)
			end
		})
	end
	
	return setmetatable({}, {
		__index = function() return function() end end,
		__newindex = function() end
	})
end

-- Use native Drawing API if available, otherwise use mobile fallback
local Drawingnew = Drawing and Drawing.new or CreateMobileDrawing

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

-- Mobile Detection
local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MobileTargetButton = nil

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

		Sensitivity = 0.15, -- Animation length (in seconds) before fully locking onto target - Increased for smoother mobile
		Sensitivity2 = 3.5, -- mousemoverel Sensitivity

		LockMode = 1, -- 1 = CFrame; 2 = mousemoverel
		LockPart = "Head", -- Body part to lock on

		TriggerKey = isMobileDevice and Enum.UserInputType.Touch or Enum.UserInputType.MouseButton2,
		Toggle = isMobileDevice -- Force toggle mode on mobile
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
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)

	if Animation then
		Animation:Cancel()
	end
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

local CreateMobileTargetButton = function()
	if not isMobileDevice then return end
	
	-- Create mobile target button
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileAimbotButton"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999998
	screenGui.ResetOnSpawn = false
	
	pcall(function()
		if gethui then
			screenGui.Parent = gethui()
		elseif syn and syn.protect_gui then
			syn.protect_gui(screenGui)
			screenGui.Parent = game:GetService("CoreGui")
		else
			screenGui.Parent = game:GetService("CoreGui")
		end
	end)
	
	-- Create circular button
	local button = Instance.new("TextButton")
	button.Name = "TargetButton"
	button.Size = UDim2.fromOffset(65, 65)
	button.Position = UDim2.new(1, -85, 0.5, -32.5)
	button.AnchorPoint = Vector2.new(0, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.Text = "🎯"
	button.TextSize = 32
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 100, 100)
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	
	-- Status indicator
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, 0, 0, 15)
	statusLabel.Position = UDim2.new(0, 0, 1, 5)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "OFF"
	statusLabel.TextSize = 10
	statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = button
	
	-- Make draggable
	local dragging = false
	local dragInput, dragStart, startPos
	
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = button.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
	-- Toggle aimbot on tap
	button.MouseButton1Click:Connect(function()
		Running = not Running
		
		if Running then
			button.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			stroke.Color = Color3.fromRGB(100, 255, 100)
			statusLabel.Text = "ON"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			button.Text = "🔒"
		else
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			stroke.Color = Color3.fromRGB(255, 100, 100)
			statusLabel.Text = "OFF"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			button.Text = "🎯"
			CancelLock()
		end
	end)
	
	-- Pulse animation when locked
	task.spawn(function()
		while screenGui.Parent do
			if Environment.Locked then
				for i = 0.3, 0.7, 0.05 do
					if button and button.Parent then
						button.BackgroundTransparency = i
						task.wait(0.05)
					end
				end
				for i = 0.7, 0.3, -0.05 do
					if button and button.Parent then
						button.BackgroundTransparency = i
						task.wait(0.05)
					end
				end
			else
				task.wait(0.1)
			end
		end
	end)
	
	MobileTargetButton = screenGui
	return screenGui
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings, FOVCircle, FOVCircleOutline, FOVSettings, Offset = Environment.Settings, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.FOVSettings
	
	-- Create mobile button if on mobile device
	if isMobileDevice then
		CreateMobileTargetButton()
	end

	--[[
	if not Degrade then
		FOVCircle, FOVCircleOutline = FOVCircle.__OBJECT, FOVCircleOutline.__OBJECT
	end
	]]

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()
		pcall(function()
			local OffsetToMoveDirection, LockPart = Settings.OffsetToMoveDirection, Settings.LockPart

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
					-- Improved smoothing for mobile
					if Settings.Sensitivity > 0 then
						-- Use Exponential easing for smoother mobile experience
						local tweenInfo = TweenInfonew(
							Settings.Sensitivity,
							Enum.EasingStyle.Exponential,
							Enum.EasingDirection.Out
						)
						Animation = TweenService:Create(Camera, tweenInfo, {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset)})
						Animation:Play()
					else
						-- Lerp for instant lock with slight smoothing
						local currentCFrame = Camera.CFrame
						local targetCFrame = CFramenew(currentCFrame.Position, LockedPosition_Vector3 + Offset)
						__newindex(Camera, "CFrame", currentCFrame:Lerp(targetCFrame, 0.5))
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

		-- Support both keyboard keys and mouse/touch input
		local isKeyboardTrigger = Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey
		local isInputTypeTrigger = Input.UserInputType == TriggerKey
		
		-- For mobile: Skip if using the mobile button (it handles toggle itself)
		if isMobileDevice and MobileTargetButton then
			return
		end
		
		if isKeyboardTrigger or isInputTypeTrigger then
			if Toggle then
				Running = not Running

				if not Running then
					CancelLock()
				end
			else
				Running = true
			end
		end
	end)

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle

		if Toggle or Typing then
			return
		end

		-- Support both keyboard keys and mouse/touch input
		local isKeyboardTrigger = Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey
		local isInputTypeTrigger = Input.UserInputType == TriggerKey
		
		-- For mobile: Skip if using the mobile button
		if isMobileDevice and MobileTargetButton then
			return
		end
		
		if isKeyboardTrigger or isInputTypeTrigger then
			Running = false
			CancelLock()
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

	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil

	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	
	-- Clean up mobile button
	if MobileTargetButton then
		MobileTargetButton:Destroy()
		MobileTargetButton = nil
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
