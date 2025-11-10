--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick

-- Safe Drawing API
local Drawingnew = Drawing and Drawing.new or function() 
    return setmetatable({}, {
        __index = function() return function() end end,
        __newindex = function() end
    })
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

		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false
	},

	TriggerbotSettings = {
		Enabled = false,
		UseSpecificPart = true, -- If true, only shoots when SpecificPart is in crosshair. If false, shoots when any main part from DamageableParts is hit
		SpecificPart = "Head", -- Part to target (only used if UseSpecificPart is true)
		DamageableParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}, -- Parts to check when UseSpecificPart is false
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		MaxDistance = 500, -- Maximum distance to trigger shot
		FOVRadius = 1, -- Crosshair FOV radius in pixels (minimum 1)
		DelayBetweenShots = 0.1, -- Delay between automatic shots
		TriggerKey = nil -- Optional: Require holding a key to enable triggerbot (nil = always active when enabled)
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

local LastShotTime = 0
local TriggerbotCache = {
	LastCheck = 0,
	CheckInterval = 0.01, -- Check every ~10ms for better responsiveness
	LastResult = false
}

local CheckTriggerbotTarget = function()
	local TBSettings = Environment.TriggerbotSettings
	
	if not TBSettings.Enabled then
		return false
	end
	
	-- Throttle checks to reduce CPU usage
	local now = tick()
	if now - TriggerbotCache.LastCheck < TriggerbotCache.CheckInterval then
		return TriggerbotCache.LastResult
	end
	TriggerbotCache.LastCheck = now
	
	-- Check if triggerbot key is required and held
	if TBSettings.TriggerKey then
		local KeyHeld = false
		pcall(function()
			if TBSettings.TriggerKey.EnumType == Enum.KeyCode then
				KeyHeld = UserInputService:IsKeyDown(TBSettings.TriggerKey)
			elseif TBSettings.TriggerKey.EnumType == Enum.UserInputType then
				KeyHeld = UserInputService:IsMouseButtonPressed(TBSettings.TriggerKey)
			end
		end)
		
		if not KeyHeld then
			TriggerbotCache.LastResult = false
			return false
		end
	end
	
	-- Check shot delay
	if now - LastShotTime < TBSettings.DelayBetweenShots then
		TriggerbotCache.LastResult = false
		return false
	end
	
	local ScreenCenter = Camera.ViewportSize / 2
	local FOVRadius = TBSettings.FOVRadius
	local MaxDistance = TBSettings.MaxDistance
	
	for _, Player in next, GetPlayers(Players) do
		if Player == LocalPlayer then
			continue
		end
		
		local Character = __index(Player, "Character")
		if not Character then
			continue
		end
		
		-- Quick distance check first (cheapest check)
		local HRP = FindFirstChild(Character, "HumanoidRootPart")
		if HRP then
			local QuickDist = (Camera.CFrame.Position - __index(HRP, "Position")).Magnitude
			if QuickDist > MaxDistance then
				continue -- Skip this player entirely if too far
			end
		end
		
		-- Team check
		if TBSettings.TeamCheck then
			local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption
			if __index(Player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
				continue
			end
		end
		
		-- Alive check
		if TBSettings.AliveCheck then
			local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
			if not Humanoid or __index(Humanoid, "Health") <= 0 then
				continue
			end
		end
		
		if TBSettings.UseSpecificPart then
			-- Check specific part only
			local TargetPart = FindFirstChild(Character, TBSettings.SpecificPart or "Head")
			if not TargetPart then
				continue
			end
			
			local PartPosition = __index(TargetPart, "Position")
			local ScreenPos, OnScreen = WorldToViewportPoint(Camera, PartPosition)
			
			if not OnScreen then
				continue
			end
			
			-- FOV check early (before expensive distance calc)
			local ScreenVector = Vector2new(ScreenPos.X, ScreenPos.Y)
			local DistanceFromCenter = (ScreenCenter - ScreenVector).Magnitude
			
			if DistanceFromCenter > FOVRadius then
				continue -- Not in crosshair FOV
			end
			
			-- Wall check (only if needed)
			if TBSettings.WallCheck then
				local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
				for _, Value in next, GetDescendants(Character) do
					BlacklistTable[#BlacklistTable + 1] = Value
				end
				
				if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
					continue
				end
			end
			
			TriggerbotCache.LastResult = true
			return true, Player, TargetPart
		else
			-- Check main damageable parts only (optimized)
			local ClosestDistance = math.huge
			local ClosestPart = nil
			
			-- Pre-build blacklist once if needed
			local BlacklistTable = nil
			if TBSettings.WallCheck then
				BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
				for _, Value in next, GetDescendants(Character) do
					BlacklistTable[#BlacklistTable + 1] = Value
				end
			end
			
			for _, PartName in next, TBSettings.DamageableParts do
				local Part = FindFirstChild(Character, PartName)
				if not Part then
					continue
				end
				
				local PartPosition = __index(Part, "Position")
				local ScreenPos, OnScreen = WorldToViewportPoint(Camera, PartPosition)
				
				if not OnScreen then
					continue
				end
				
				-- FOV check first (cheapest)
				local ScreenVector = Vector2new(ScreenPos.X, ScreenPos.Y)
				local DistanceFromCenter = (ScreenCenter - ScreenVector).Magnitude
				
				if DistanceFromCenter > FOVRadius or DistanceFromCenter >= ClosestDistance then
					continue -- Not in FOV or not closer than current closest
				end
				
				-- Wall check (only if needed and passed FOV)
				if TBSettings.WallCheck then
					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
						continue
					end
				end
				
				-- This part is closest so far
				ClosestDistance = DistanceFromCenter
				ClosestPart = Part
			end
			
			if ClosestPart then
				TriggerbotCache.LastResult = true
				return true, Player, ClosestPart
			end
		end
	end
	
	TriggerbotCache.LastResult = false
	return false
end

local TriggerShot = function()
	LastShotTime = tick()
	
	-- Try multiple methods to shoot
	pcall(function()
		if mouse1click then
			mouse1click()
		elseif mouse1press and mouse1release then
			mouse1press()
			task.wait(0.05)
			mouse1release()
		end
	end)
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
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")

	local Settings, FOVCircle, FOVCircleOutline, FOVSettings, Offset = Environment.Settings, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.FOVSettings

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
		
		-- Triggerbot check (independent of aimbot)
		if Environment.TriggerbotSettings.Enabled then
			local ShouldShoot, TargetPlayer, TargetPart = CheckTriggerbotTarget()
			if ShouldShoot then
				TriggerShot()
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

		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
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
