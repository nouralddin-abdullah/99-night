--[[
    Universal Custom GUI Library
    Created for ESP, Aimbot, and Player Movement features
    
    Features:
    - Modern, sleek design
    - Drag & Drop windows
    - Tabs & Sub-sections
    - Buttons
    - Toggles
    - Dropdowns (Single & Multi-select)
    - Sliders
    - Color Pickers
    - Text Input
    - Labels & Paragraphs
    - Fully customizable
]]

local CustomGUI = {}
CustomGUI.__index = CustomGUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Detect screen size and device type
local function GetScreenInfo()
    local ViewportSize = workspace.Camera.ViewportSize
    local screenWidth = ViewportSize.X
    local screenHeight = ViewportSize.Y
    
    -- Determine device type based on screen size
    local isMobile = screenWidth < 768 or screenHeight < 768
    local isTablet = screenWidth >= 768 and screenWidth < 1024
    local isDesktop = screenWidth >= 1024
    
    return {
        Width = screenWidth,
        Height = screenHeight,
        IsMobile = isMobile,
        IsTablet = isTablet,
        IsDesktop = isDesktop
    }
end

local ScreenInfo = GetScreenInfo()

-- Responsive sizing based on device
local function GetResponsiveConfig()
    if ScreenInfo.IsMobile then
        -- Mobile: Smaller, more compact
        return {
            WindowWidth = math.min(ScreenInfo.Width * 0.95, 380),
            WindowHeight = math.min(ScreenInfo.Height * 0.85, 500),
            TabContainerWidth = 100,
            HeaderHeight = 45,
            ButtonHeight = 32,
            ToggleHeight = 32,
            SliderHeight = 40,
            DropdownHeight = 32,
            MinimizeCircleSize = 50,
            FontSizeTitle = 16,
            FontSizeNormal = 13,
        }
    elseif ScreenInfo.IsTablet then
        -- Tablet: Medium size
        return {
            WindowWidth = math.min(ScreenInfo.Width * 0.75, 480),
            WindowHeight = math.min(ScreenInfo.Height * 0.80, 550),
            TabContainerWidth = 120,
            HeaderHeight = 48,
            ButtonHeight = 34,
            ToggleHeight = 34,
            SliderHeight = 43,
            DropdownHeight = 34,
            MinimizeCircleSize = 55,
            FontSizeTitle = 18,
            FontSizeNormal = 14,
        }
    else
        -- Desktop: Full size
        return {
            WindowWidth = 550,
            WindowHeight = 600,
            TabContainerWidth = 140,
            HeaderHeight = 50,
            ButtonHeight = 35,
            ToggleHeight = 35,
            SliderHeight = 45,
            DropdownHeight = 35,
            MinimizeCircleSize = 60,
            FontSizeTitle = 20,
            FontSizeNormal = 14,
        }
    end
end

local ResponsiveConfig = GetResponsiveConfig()

-- Configuration
local Config = {
    -- Colors
    BackgroundColor = Color3.fromRGB(20, 20, 25),
    SecondaryColor = Color3.fromRGB(30, 30, 35),
    AccentColor = Color3.fromRGB(88, 101, 242), -- Discord blurple
    TextColor = Color3.fromRGB(255, 255, 255),
    SubTextColor = Color3.fromRGB(180, 180, 190),
    BorderColor = Color3.fromRGB(50, 50, 60),
    SuccessColor = Color3.fromRGB(67, 181, 129),
    ErrorColor = Color3.fromRGB(240, 71, 71),
    
    -- Responsive Sizes
    WindowSize = UDim2.new(0, ResponsiveConfig.WindowWidth, 0, ResponsiveConfig.WindowHeight),
    TabContainerWidth = ResponsiveConfig.TabContainerWidth,
    HeaderHeight = ResponsiveConfig.HeaderHeight,
    ButtonHeight = ResponsiveConfig.ButtonHeight,
    ToggleHeight = ResponsiveConfig.ToggleHeight,
    SliderHeight = ResponsiveConfig.SliderHeight,
    DropdownHeight = ResponsiveConfig.DropdownHeight,
    MinimizeCircleSize = ResponsiveConfig.MinimizeCircleSize,
    
    -- Font Sizes
    FontSizeTitle = ResponsiveConfig.FontSizeTitle,
    FontSizeNormal = ResponsiveConfig.FontSizeNormal,
    
    -- Animation
    AnimationSpeed = 0.2,
    EasingStyle = Enum.EasingStyle.Quad,
    EasingDirection = Enum.EasingDirection.Out,
    
    -- Fonts
    TitleFont = Enum.Font.GothamBold,
    MainFont = Enum.Font.Gotham,
    
    -- Border & Corner Radius
    CornerRadius = UDim.new(0, 8),
    BorderThickness = 1,
}

-- Utility Functions
local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Config.CornerRadius
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.BorderColor
    stroke.Thickness = thickness or Config.BorderThickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function CreatePadding(parent, all)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, all)
    padding.PaddingBottom = UDim.new(0, all)
    padding.PaddingLeft = UDim.new(0, all)
    padding.PaddingRight = UDim.new(0, all)
    padding.Parent = parent
    return padding
end

local function Tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(
        duration or Config.AnimationSpeed,
        Config.EasingStyle,
        Config.EasingDirection
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.1)
    end
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Main Library Functions
function CustomGUI.new(config)
    local self = setmetatable({}, CustomGUI)
    
    -- Configuration
    self.Title = config.Title or "Universal GUI"
    self.Size = config.Size or Config.WindowSize
    -- Center window based on responsive size
    local xOffset = -ResponsiveConfig.WindowWidth / 2
    local yOffset = -ResponsiveConfig.WindowHeight / 2
    self.Position = config.Position or UDim2.new(0.5, xOffset, 0.5, yOffset)
    self.Visible = config.Visible ~= false
    
    -- Storage
    self.Tabs = {}
    self.CurrentTab = nil
    self.Flags = {}
    
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "CustomGUI_" .. math.random(1000, 9999)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protection
    if gethui then
        self.ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(self.ScreenGui)
        self.ScreenGui.Parent = game:GetService("CoreGui")
    else
        self.ScreenGui.Parent = game:GetService("CoreGui")
    end
    
    -- Main Window
    self.MainWindow = Instance.new("Frame")
    self.MainWindow.Name = "MainWindow"
    self.MainWindow.Size = self.Size
    self.MainWindow.Position = self.Position
    self.MainWindow.BackgroundColor3 = Config.BackgroundColor
    self.MainWindow.BorderSizePixel = 0
    self.MainWindow.Visible = self.Visible
    self.MainWindow.Parent = self.ScreenGui
    CreateCorner(self.MainWindow)
    CreateStroke(self.MainWindow)
    
    -- Shadow Effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(100, 100, 100, 100)
    shadow.ZIndex = 0
    shadow.Parent = self.MainWindow
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.Size = UDim2.new(1, 0, 0, Config.HeaderHeight)
    self.Header.BackgroundColor3 = Config.SecondaryColor
    self.Header.BorderSizePixel = 0
    self.Header.Parent = self.MainWindow
    CreateCorner(self.Header, UDim.new(0, 8))
    
    -- Title Label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "Title"
    self.TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Text = self.Title
    self.TitleLabel.TextColor3 = Config.TextColor
    self.TitleLabel.TextSize = Config.FontSizeTitle
    self.TitleLabel.Font = Config.TitleFont
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.Header
    
    -- Minimize Button
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Name = "MinimizeButton"
    self.MinimizeButton.Size = UDim2.new(0, 40, 0, 40)
    self.MinimizeButton.Position = UDim2.new(1, -90, 0, 5)
    self.MinimizeButton.BackgroundColor3 = Config.AccentColor
    self.MinimizeButton.BorderSizePixel = 0
    self.MinimizeButton.Text = "─"
    self.MinimizeButton.TextColor3 = Config.TextColor
    self.MinimizeButton.TextSize = Config.FontSizeTitle
    self.MinimizeButton.Font = Config.TitleFont
    self.MinimizeButton.Parent = self.Header
    CreateCorner(self.MinimizeButton, UDim.new(0, 6))
    
    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 40, 0, 40)
    self.CloseButton.Position = UDim2.new(1, -45, 0, 5)
    self.CloseButton.BackgroundColor3 = Config.ErrorColor
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Text = "✕"
    self.CloseButton.TextColor3 = Config.TextColor
    self.CloseButton.TextSize = Config.FontSizeTitle
    self.CloseButton.Font = Config.TitleFont
    self.CloseButton.Parent = self.Header
    CreateCorner(self.CloseButton, UDim.new(0, 6))
    
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    self.CloseButton.MouseEnter:Connect(function()
        Tween(self.CloseButton, {BackgroundColor3 = Color3.fromRGB(220, 50, 50)})
    end)
    
    self.CloseButton.MouseLeave:Connect(function()
        Tween(self.CloseButton, {BackgroundColor3 = Config.ErrorColor})
    end)
    
    self.MinimizeButton.MouseEnter:Connect(function()
        Tween(self.MinimizeButton, {BackgroundColor3 = Color3.fromRGB(70, 80, 200)})
    end)
    
    self.MinimizeButton.MouseLeave:Connect(function()
        Tween(self.MinimizeButton, {BackgroundColor3 = Config.AccentColor})
    end)
    
    -- Minimize Circle (Hidden by default)
    self.MinimizeCircle = Instance.new("Frame")
    self.MinimizeCircle.Name = "MinimizeCircle"
    self.MinimizeCircle.Size = UDim2.new(0, Config.MinimizeCircleSize, 0, Config.MinimizeCircleSize)
    self.MinimizeCircle.Position = UDim2.new(1, -(Config.MinimizeCircleSize + 20), 0, 20)
    self.MinimizeCircle.BackgroundColor3 = Config.AccentColor
    self.MinimizeCircle.BorderSizePixel = 0
    self.MinimizeCircle.Visible = false
    self.MinimizeCircle.Parent = self.ScreenGui
    CreateCorner(self.MinimizeCircle, UDim.new(1, 0)) -- Full circle
    CreateStroke(self.MinimizeCircle, Config.BorderColor, 2)
    
    local CircleButton = Instance.new("TextButton")
    CircleButton.Size = UDim2.new(1, 0, 1, 0)
    CircleButton.BackgroundTransparency = 1
    CircleButton.Text = "+"
    CircleButton.TextColor3 = Config.TextColor
    CircleButton.TextSize = 24
    CircleButton.Font = Config.TitleFont
    CircleButton.Parent = self.MinimizeCircle
    
    -- Circle shadow
    local circleShadow = Instance.new("ImageLabel")
    circleShadow.Name = "Shadow"
    circleShadow.Size = UDim2.new(1, 20, 1, 20)
    circleShadow.Position = UDim2.new(0, -10, 0, -10)
    circleShadow.BackgroundTransparency = 1
    circleShadow.Image = "rbxassetid://6015897843"
    circleShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    circleShadow.ImageTransparency = 0.7
    circleShadow.ScaleType = Enum.ScaleType.Slice
    circleShadow.SliceCenter = Rect.new(100, 100, 100, 100)
    circleShadow.ZIndex = 0
    circleShadow.Parent = self.MinimizeCircle
    
    -- Make circle draggable
    MakeDraggable(self.MinimizeCircle, CircleButton)
    
    -- Minimize/Restore functionality
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.MainWindow.Visible = false
        self.MinimizeCircle.Visible = true
    end)
    
    CircleButton.MouseButton1Click:Connect(function()
        self.MinimizeCircle.Visible = false
        self.MainWindow.Visible = true
    end)
    
    CircleButton.MouseEnter:Connect(function()
        Tween(self.MinimizeCircle, {BackgroundColor3 = Color3.fromRGB(70, 80, 200)})
    end)
    
    CircleButton.MouseLeave:Connect(function()
        Tween(self.MinimizeCircle, {BackgroundColor3 = Config.AccentColor})
    end)
    
    -- Tab Container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(0, Config.TabContainerWidth, 1, -(Config.HeaderHeight + 10))
    self.TabContainer.Position = UDim2.new(0, 10, 0, Config.HeaderHeight + 5)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.MainWindow
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = self.TabContainer
    
    -- Content Container
    self.ContentContainer = Instance.new("ScrollingFrame")
    self.ContentContainer.Name = "ContentContainer"
    self.ContentContainer.Size = UDim2.new(1, -(Config.TabContainerWidth + 30), 1, -(Config.HeaderHeight + 20))
    self.ContentContainer.Position = UDim2.new(0, Config.TabContainerWidth + 20, 0, Config.HeaderHeight + 10)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.ScrollBarThickness = ScreenInfo.IsMobile and 3 or 4
    self.ContentContainer.ScrollBarImageColor3 = Config.AccentColor
    self.ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ContentContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ContentContainer.Parent = self.MainWindow
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = self.ContentContainer
    CreatePadding(self.ContentContainer, 5)
    
    -- Make window draggable
    MakeDraggable(self.MainWindow, self.Header)
    
    return self
end

function CustomGUI:CreateTab(config)
    local Tab = {
        Name = config.Name or "Tab",
        Icon = config.Icon or "📁",
        Elements = {},
        Visible = false
    }
    
    -- Tab Button
    Tab.Button = Instance.new("TextButton")
    Tab.Button.Name = "TabButton_" .. Tab.Name
    Tab.Button.Size = UDim2.new(1, 0, 0, 40)
    Tab.Button.BackgroundColor3 = Config.SecondaryColor
    Tab.Button.BorderSizePixel = 0
    Tab.Button.Text = Tab.Icon .. " " .. Tab.Name
    Tab.Button.TextColor3 = Config.SubTextColor
    Tab.Button.TextSize = Config.FontSizeNormal
    Tab.Button.Font = Config.MainFont
    Tab.Button.TextXAlignment = Enum.TextXAlignment.Left
    Tab.Button.Parent = self.TabContainer
    CreateCorner(Tab.Button)
    CreatePadding(Tab.Button, 10)
    
    -- Tab Content Container
    Tab.Container = Instance.new("Frame")
    Tab.Container.Name = "TabContent_" .. Tab.Name
    Tab.Container.Size = UDim2.new(1, 0, 0, 0)
    Tab.Container.BackgroundTransparency = 1
    Tab.Container.Visible = false
    Tab.Container.Parent = self.ContentContainer
    Tab.Container.AutomaticSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = Tab.Container
    
    -- Tab Button Click
    Tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(Tab)
    end)
    
    Tab.Button.MouseEnter:Connect(function()
        if not Tab.Visible then
            Tween(Tab.Button, {BackgroundColor3 = Config.BorderColor})
        end
    end)
    
    Tab.Button.MouseLeave:Connect(function()
        if not Tab.Visible then
            Tween(Tab.Button, {BackgroundColor3 = Config.SecondaryColor})
        end
    end)
    
    -- Add methods to Tab
    Tab.CreateSection = function(self, name)
        return self:_CreateSection(name, Tab)
    end
    
    Tab.CreateButton = function(self, config)
        return self:_CreateButton(config, Tab)
    end
    
    Tab.CreateToggle = function(self, config)
        return self:_CreateToggle(config, Tab)
    end
    
    Tab.CreateSlider = function(self, config)
        return self:_CreateSlider(config, Tab)
    end
    
    Tab.CreateDropdown = function(self, config)
        return self:_CreateDropdown(config, Tab)
    end
    
    Tab.CreateColorPicker = function(self, config)
        return self:_CreateColorPicker(config, Tab)
    end
    
    Tab.CreateTextBox = function(self, config)
        return self:_CreateTextBox(config, Tab)
    end
    
    Tab.CreateLabel = function(self, text)
        return self:_CreateLabel(text, Tab)
    end
    
    Tab.CreateParagraph = function(self, config)
        return self:_CreateParagraph(config, Tab)
    end
    
    -- Store tab
    table.insert(self.Tabs, Tab)
    
    -- Auto-select first tab
    if #self.Tabs == 1 then
        self:SwitchTab(Tab)
    end
    
    return setmetatable(Tab, {__index = self})
end

function CustomGUI:SwitchTab(tab)
    -- Hide all tabs
    for _, t in ipairs(self.Tabs) do
        t.Visible = false
        t.Container.Visible = false
        Tween(t.Button, {
            BackgroundColor3 = Config.SecondaryColor,
            TextColor3 = Config.SubTextColor
        })
    end
    
    -- Show selected tab
    tab.Visible = true
    tab.Container.Visible = true
    self.CurrentTab = tab
    Tween(tab.Button, {
        BackgroundColor3 = Config.AccentColor,
        TextColor3 = Config.TextColor
    })
end

function CustomGUI:_CreateSection(name, tab)
    local Section = Instance.new("Frame")
    Section.Name = "Section_" .. name
    Section.Size = UDim2.new(1, 0, 0, 30)
    Section.BackgroundTransparency = 1
    Section.Parent = tab.Container
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "━━ " .. name .. " ━━"
    Label.TextColor3 = Config.AccentColor
    Label.TextSize = Config.FontSizeNormal
    Label.Font = Config.TitleFont
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section
    
    return Section
end

function CustomGUI:_CreateButton(config, tab)
    local Button = {
        Name = config.Name or "Button",
        Callback = config.Callback or function() end
    }
    
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Name = "Button_" .. Button.Name
    ButtonFrame.Size = UDim2.new(1, 0, 0, Config.ButtonHeight)
    ButtonFrame.BackgroundColor3 = Config.SecondaryColor
    ButtonFrame.BorderSizePixel = 0
    ButtonFrame.Parent = tab.Container
    CreateCorner(ButtonFrame)
    
    local ButtonClick = Instance.new("TextButton")
    ButtonClick.Size = UDim2.new(1, 0, 1, 0)
    ButtonClick.BackgroundTransparency = 1
    ButtonClick.Text = ""
    ButtonClick.Parent = ButtonFrame
    
    local ButtonLabel = Instance.new("TextLabel")
    ButtonLabel.Size = UDim2.new(1, -20, 1, 0)
    ButtonLabel.Position = UDim2.new(0, 10, 0, 0)
    ButtonLabel.BackgroundTransparency = 1
    ButtonLabel.Text = Button.Name
    ButtonLabel.TextColor3 = Config.TextColor
    ButtonLabel.TextSize = Config.FontSizeNormal
    ButtonLabel.Font = Config.MainFont
    ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
    ButtonLabel.Parent = ButtonFrame
    
    ButtonClick.MouseButton1Click:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Config.AccentColor})
        task.wait(0.1)
        Tween(ButtonFrame, {BackgroundColor3 = Config.SecondaryColor})
        
        pcall(function()
            Button.Callback()
        end)
    end)
    
    ButtonClick.MouseEnter:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Config.BorderColor})
    end)
    
    ButtonClick.MouseLeave:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Config.SecondaryColor})
    end)
    
    return Button
end

function CustomGUI:_CreateToggle(config, tab)
    local Toggle = {
        Name = config.Name or "Toggle",
        CurrentValue = config.CurrentValue or false,
        Flag = config.Flag,
        Callback = config.Callback or function() end
    }
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = "Toggle_" .. Toggle.Name
    ToggleFrame.Size = UDim2.new(1, 0, 0, Config.ToggleHeight)
    ToggleFrame.BackgroundColor3 = Config.SecondaryColor
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = tab.Container
    CreateCorner(ToggleFrame)
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Text = ""
    ToggleButton.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = Toggle.Name
    ToggleLabel.TextColor3 = Config.TextColor
    ToggleLabel.TextSize = 14
    ToggleLabel.Font = Config.MainFont
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    
    -- Toggle Switch
    local SwitchFrame = Instance.new("Frame")
    SwitchFrame.Size = UDim2.new(0, 40, 0, 20)
    SwitchFrame.Position = UDim2.new(1, -50, 0.5, -10)
    SwitchFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    SwitchFrame.BorderSizePixel = 0
    SwitchFrame.Parent = ToggleFrame
    CreateCorner(SwitchFrame, UDim.new(0, 10))
    
    local SwitchCircle = Instance.new("Frame")
    SwitchCircle.Size = UDim2.new(0, 16, 0, 16)
    SwitchCircle.Position = UDim2.new(0, 2, 0.5, -8)
    SwitchCircle.BackgroundColor3 = Config.TextColor
    SwitchCircle.BorderSizePixel = 0
    SwitchCircle.Parent = SwitchFrame
    CreateCorner(SwitchCircle, UDim.new(0, 8))
    
    local function UpdateToggle(value)
        Toggle.CurrentValue = value
        
        if value then
            Tween(SwitchFrame, {BackgroundColor3 = Config.AccentColor})
            Tween(SwitchCircle, {Position = UDim2.new(1, -18, 0.5, -8)})
        else
            Tween(SwitchFrame, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
            Tween(SwitchCircle, {Position = UDim2.new(0, 2, 0.5, -8)})
        end
        
        if Toggle.Flag then
            self.Flags[Toggle.Flag] = value
        end
        
        pcall(function()
            Toggle.Callback(value)
        end)
    end
    
    ToggleButton.MouseButton1Click:Connect(function()
        UpdateToggle(not Toggle.CurrentValue)
    end)
    
    ToggleButton.MouseEnter:Connect(function()
        Tween(ToggleFrame, {BackgroundColor3 = Config.BorderColor})
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        Tween(ToggleFrame, {BackgroundColor3 = Config.SecondaryColor})
    end)
    
    -- Initialize
    UpdateToggle(Toggle.CurrentValue)
    
    -- Add Set method
    Toggle.Set = function(self, value)
        UpdateToggle(value)
    end
    
    return Toggle
end

function CustomGUI:_CreateSlider(config, tab)
    local Slider = {
        Name = config.Name or "Slider",
        Min = config.Min or 0,
        Max = config.Max or 100,
        Default = config.Default or 50,
        Increment = config.Increment or 1,
        CurrentValue = config.CurrentValue or config.Default or 50,
        Flag = config.Flag,
        Callback = config.Callback or function() end
    }
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = "Slider_" .. Slider.Name
    SliderFrame.Size = UDim2.new(1, 0, 0, Config.SliderHeight)
    SliderFrame.BackgroundColor3 = Config.SecondaryColor
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = tab.Container
    CreateCorner(SliderFrame)
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(0.7, 0, 0, 20)
    SliderLabel.Position = UDim2.new(0, 10, 0, 5)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = Slider.Name
    SliderLabel.TextColor3 = Config.TextColor
    SliderLabel.TextSize = 14
    SliderLabel.Font = Config.MainFont
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.3, -10, 0, 20)
    ValueLabel.Position = UDim2.new(0.7, 0, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(Slider.CurrentValue)
    ValueLabel.TextColor3 = Config.AccentColor
    ValueLabel.TextSize = 14
    ValueLabel.Font = Config.TitleFont
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame
    
    -- Slider Track
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Size = UDim2.new(1, -20, 0, 4)
    SliderTrack.Position = UDim2.new(0, 10, 1, -12)
    SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = SliderFrame
    CreateCorner(SliderTrack, UDim.new(0, 2))
    
    -- Slider Fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(0, 0, 1, 0)
    SliderFill.BackgroundColor3 = Config.AccentColor
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack
    CreateCorner(SliderFill, UDim.new(0, 2))
    
    -- Slider Button
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(0, 12, 0, 12)
    SliderButton.Position = UDim2.new(0, 0, 0.5, -6)
    SliderButton.BackgroundColor3 = Config.TextColor
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""
    SliderButton.Parent = SliderTrack
    CreateCorner(SliderButton, UDim.new(0, 6))
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        local value = Slider.Min + (Slider.Max - Slider.Min) * pos
        
        -- Round to nearest increment (supports decimals)
        value = math.floor(value / Slider.Increment + 0.5) * Slider.Increment
        value = math.clamp(value, Slider.Min, Slider.Max)
        
        -- Round to appropriate decimal places based on increment
        local decimalPlaces = 0
        if Slider.Increment < 1 then
            decimalPlaces = math.max(0, math.ceil(-math.log10(Slider.Increment)))
        end
        value = math.floor(value * (10 ^ decimalPlaces) + 0.5) / (10 ^ decimalPlaces)
        
        Slider.CurrentValue = value
        ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", value)
        
        local fillSize = (value - Slider.Min) / (Slider.Max - Slider.Min)
        SliderFill.Size = UDim2.new(fillSize, 0, 1, 0)
        SliderButton.Position = UDim2.new(fillSize, -6, 0.5, -6)
        
        if Slider.Flag then
            self.Flags[Slider.Flag] = value
        end
        
        pcall(function()
            Slider.Callback(value)
        end)
    end
    
    SliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    SliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    
    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UpdateSlider(input)
        end
    end)
    
    -- Initialize
    local decimalPlaces = 0
    if Slider.Increment < 1 then
        decimalPlaces = math.max(0, math.ceil(-math.log10(Slider.Increment)))
    end
    ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", Slider.CurrentValue)
    
    local initialFill = (Slider.CurrentValue - Slider.Min) / (Slider.Max - Slider.Min)
    SliderFill.Size = UDim2.new(initialFill, 0, 1, 0)
    SliderButton.Position = UDim2.new(initialFill, -6, 0.5, -6)
    
    -- Add Set method
    Slider.Set = function(self, value)
        value = math.clamp(value, Slider.Min, Slider.Max)
        
        -- Round to appropriate decimal places based on increment
        local decimalPlaces = 0
        if Slider.Increment < 1 then
            decimalPlaces = math.max(0, math.ceil(-math.log10(Slider.Increment)))
        end
        value = math.floor(value * (10 ^ decimalPlaces) + 0.5) / (10 ^ decimalPlaces)
        
        Slider.CurrentValue = value
        ValueLabel.Text = string.format("%." .. decimalPlaces .. "f", value)
        
        local fillSize = (value - Slider.Min) / (Slider.Max - Slider.Min)
        SliderFill.Size = UDim2.new(fillSize, 0, 1, 0)
        SliderButton.Position = UDim2.new(fillSize, -6, 0.5, -6)
    end
    
    return Slider
end

function CustomGUI:_CreateDropdown(config, tab)
    local Dropdown = {
        Name = config.Name or "Dropdown",
        Options = config.Options or {},
        Default = config.Default,
        Multi = config.Multi or false,
        CurrentValue = config.Multi and {} or config.Default,
        Flag = config.Flag,
        Callback = config.Callback or function() end,
        Opened = false
    }
    
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = "Dropdown_" .. Dropdown.Name
    DropdownFrame.Size = UDim2.new(1, 0, 0, Config.DropdownHeight)
    DropdownFrame.BackgroundColor3 = Config.SecondaryColor
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Parent = tab.Container
    DropdownFrame.ClipsDescendants = true
    CreateCorner(DropdownFrame)
    
    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Size = UDim2.new(1, 0, 0, Config.DropdownHeight)
    DropdownButton.BackgroundTransparency = 1
    DropdownButton.Text = ""
    DropdownButton.Parent = DropdownFrame
    
    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Size = UDim2.new(1, -60, 1, 0)
    DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = Dropdown.Name
    DropdownLabel.TextColor3 = Config.TextColor
    DropdownLabel.TextSize = 14
    DropdownLabel.Font = Config.MainFont
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = DropdownFrame
    
    local DropdownValue = Instance.new("TextLabel")
    DropdownValue.Size = UDim2.new(0, 200, 0, Config.DropdownHeight)
    DropdownValue.Position = UDim2.new(1, -240, 0, 0)
    DropdownValue.BackgroundTransparency = 1
    DropdownValue.Text = Dropdown.Multi and "None" or (Dropdown.Default or "Select...")
    DropdownValue.TextColor3 = Config.SubTextColor
    DropdownValue.TextSize = 13
    DropdownValue.Font = Config.MainFont
    DropdownValue.TextXAlignment = Enum.TextXAlignment.Right
    DropdownValue.TextTruncate = Enum.TextTruncate.AtEnd
    DropdownValue.Parent = DropdownFrame
    
    local DropdownArrow = Instance.new("TextLabel")
    DropdownArrow.Size = UDim2.new(0, 30, 1, 0)
    DropdownArrow.Position = UDim2.new(1, -35, 0, 0)
    DropdownArrow.BackgroundTransparency = 1
    DropdownArrow.Text = "▼"
    DropdownArrow.TextColor3 = Config.SubTextColor
    DropdownArrow.TextSize = 12
    DropdownArrow.Font = Config.MainFont
    DropdownArrow.Parent = DropdownFrame
    
    -- Options Container
    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Name = "OptionsContainer"
    OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
    OptionsContainer.Position = UDim2.new(0, 0, 0, Config.DropdownHeight)
    OptionsContainer.BackgroundTransparency = 1
    OptionsContainer.Parent = DropdownFrame
    OptionsContainer.AutomaticSize = Enum.AutomaticSize.Y
    
    local OptionsLayout = Instance.new("UIListLayout")
    OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OptionsLayout.Padding = UDim.new(0, 2)
    OptionsLayout.Parent = OptionsContainer
    
    local function UpdateDisplay()
        if Dropdown.Multi then
            local selected = {}
            for option, state in pairs(Dropdown.CurrentValue) do
                if state then
                    table.insert(selected, option)
                end
            end
            DropdownValue.Text = #selected > 0 and table.concat(selected, ", ") or "None"
        else
            DropdownValue.Text = Dropdown.CurrentValue or "Select..."
        end
    end
    
    local function ToggleDropdown()
        Dropdown.Opened = not Dropdown.Opened
        
        if Dropdown.Opened then
            local optionsHeight = #Dropdown.Options * 32 + (#Dropdown.Options - 1) * 2
            Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, Config.DropdownHeight + optionsHeight + 5)})
            Tween(DropdownArrow, {Rotation = 180})
        else
            Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, Config.DropdownHeight)})
            Tween(DropdownArrow, {Rotation = 0})
        end
    end
    
    DropdownButton.MouseButton1Click:Connect(ToggleDropdown)
    
    -- Create option buttons
    for _, option in ipairs(Dropdown.Options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Size = UDim2.new(1, -10, 0, 30)
        OptionButton.BackgroundColor3 = Config.BackgroundColor
        OptionButton.BorderSizePixel = 0
        OptionButton.Text = ""
        OptionButton.Parent = OptionsContainer
        CreateCorner(OptionButton, UDim.new(0, 5))
        
        local OptionLabel = Instance.new("TextLabel")
        OptionLabel.Size = UDim2.new(1, -20, 1, 0)
        OptionLabel.Position = UDim2.new(0, 10, 0, 0)
        OptionLabel.BackgroundTransparency = 1
        OptionLabel.Text = option
        OptionLabel.TextColor3 = Config.TextColor
        OptionLabel.TextSize = 13
        OptionLabel.Font = Config.MainFont
        OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        OptionLabel.Parent = OptionButton
        
        if Dropdown.Multi then
            -- Checkbox for multi-select
            local Checkbox = Instance.new("Frame")
            Checkbox.Size = UDim2.new(0, 16, 0, 16)
            Checkbox.Position = UDim2.new(1, -26, 0.5, -8)
            Checkbox.BackgroundColor3 = Config.BackgroundColor
            Checkbox.BorderSizePixel = 0
            Checkbox.Parent = OptionButton
            CreateCorner(Checkbox, UDim.new(0, 3))
            CreateStroke(Checkbox, Config.BorderColor)
            
            local Checkmark = Instance.new("TextLabel")
            Checkmark.Size = UDim2.new(1, 0, 1, 0)
            Checkmark.BackgroundTransparency = 1
            Checkmark.Text = "✓"
            Checkmark.TextColor3 = Config.AccentColor
            Checkmark.TextSize = 14
            Checkmark.Font = Config.TitleFont
            Checkmark.Visible = false
            Checkmark.Parent = Checkbox
            
            OptionButton.MouseButton1Click:Connect(function()
                Dropdown.CurrentValue[option] = not Dropdown.CurrentValue[option]
                Checkmark.Visible = Dropdown.CurrentValue[option]
                
                if Dropdown.CurrentValue[option] then
                    Tween(Checkbox, {BackgroundColor3 = Config.AccentColor})
                else
                    Tween(Checkbox, {BackgroundColor3 = Config.BackgroundColor})
                end
                
                UpdateDisplay()
                
                if Dropdown.Flag then
                    self.Flags[Dropdown.Flag] = Dropdown.CurrentValue
                end
                
                pcall(function()
                    Dropdown.Callback(Dropdown.CurrentValue)
                end)
            end)
        else
            -- Single select
            OptionButton.MouseButton1Click:Connect(function()
                Dropdown.CurrentValue = option
                UpdateDisplay()
                ToggleDropdown()
                
                if Dropdown.Flag then
                    self.Flags[Dropdown.Flag] = option
                end
                
                pcall(function()
                    Dropdown.Callback(option)
                end)
            end)
        end
        
        OptionButton.MouseEnter:Connect(function()
            Tween(OptionButton, {BackgroundColor3 = Config.BorderColor})
        end)
        
        OptionButton.MouseLeave:Connect(function()
            Tween(OptionButton, {BackgroundColor3 = Config.BackgroundColor})
        end)
    end
    
    -- Initialize multi-select
    if Dropdown.Multi then
        for _, option in ipairs(Dropdown.Options) do
            Dropdown.CurrentValue[option] = false
        end
    end
    
    UpdateDisplay()
    
    -- Add UpdateOptions method to refresh dropdown options dynamically
    Dropdown.UpdateOptions = function(self, newOptions, newDefault)
        -- Clear existing options
        for _, child in ipairs(OptionsContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Update options list
        Dropdown.Options = newOptions or {}
        
        -- Reset current value based on new options
        if Dropdown.Multi then
            Dropdown.CurrentValue = {}
            for _, option in ipairs(Dropdown.Options) do
                Dropdown.CurrentValue[option] = false
            end
        else
            Dropdown.CurrentValue = newDefault or (newOptions and newOptions[1]) or nil
        end
        
        -- Recreate option buttons
        for _, option in ipairs(Dropdown.Options) do
            local OptionButton = Instance.new("TextButton")
            OptionButton.Size = UDim2.new(1, -10, 0, 30)
            OptionButton.BackgroundColor3 = Config.BackgroundColor
            OptionButton.BorderSizePixel = 0
            OptionButton.Text = ""
            OptionButton.Parent = OptionsContainer
            CreateCorner(OptionButton, UDim.new(0, 5))
            
            local OptionLabel = Instance.new("TextLabel")
            OptionLabel.Size = UDim2.new(1, -20, 1, 0)
            OptionLabel.Position = UDim2.new(0, 10, 0, 0)
            OptionLabel.BackgroundTransparency = 1
            OptionLabel.Text = option
            OptionLabel.TextColor3 = Config.TextColor
            OptionLabel.TextSize = 13
            OptionLabel.Font = Config.MainFont
            OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
            OptionLabel.Parent = OptionButton
            
            if Dropdown.Multi then
                -- Checkbox for multi-select
                local Checkbox = Instance.new("Frame")
                Checkbox.Size = UDim2.new(0, 16, 0, 16)
                Checkbox.Position = UDim2.new(1, -26, 0.5, -8)
                Checkbox.BackgroundColor3 = Config.BackgroundColor
                Checkbox.BorderSizePixel = 0
                Checkbox.Parent = OptionButton
                CreateCorner(Checkbox, UDim.new(0, 3))
                CreateStroke(Checkbox, Config.BorderColor)
                
                local Checkmark = Instance.new("TextLabel")
                Checkmark.Size = UDim2.new(1, 0, 1, 0)
                Checkmark.BackgroundTransparency = 1
                Checkmark.Text = "✓"
                Checkmark.TextColor3 = Config.AccentColor
                Checkmark.TextSize = 14
                Checkmark.Font = Config.TitleFont
                Checkmark.Visible = false
                Checkmark.Parent = Checkbox
                
                OptionButton.MouseButton1Click:Connect(function()
                    Dropdown.CurrentValue[option] = not Dropdown.CurrentValue[option]
                    Checkmark.Visible = Dropdown.CurrentValue[option]
                    
                    if Dropdown.CurrentValue[option] then
                        Tween(Checkbox, {BackgroundColor3 = Config.AccentColor})
                    else
                        Tween(Checkbox, {BackgroundColor3 = Config.BackgroundColor})
                    end
                    
                    UpdateDisplay()
                    
                    if Dropdown.Flag then
                        self.Flags[Dropdown.Flag] = Dropdown.CurrentValue
                    end
                    
                    pcall(function()
                        Dropdown.Callback(Dropdown.CurrentValue)
                    end)
                end)
            else
                -- Single select
                OptionButton.MouseButton1Click:Connect(function()
                    Dropdown.CurrentValue = option
                    UpdateDisplay()
                    ToggleDropdown()
                    
                    if Dropdown.Flag then
                        self.Flags[Dropdown.Flag] = option
                    end
                    
                    pcall(function()
                        Dropdown.Callback(option)
                    end)
                end)
            end
            
            OptionButton.MouseEnter:Connect(function()
                Tween(OptionButton, {BackgroundColor3 = Config.BorderColor})
            end)
            
            OptionButton.MouseLeave:Connect(function()
                Tween(OptionButton, {BackgroundColor3 = Config.BackgroundColor})
            end)
        end
        
        -- Update display with new values
        UpdateDisplay()
        
        -- Close dropdown if it was open
        if Dropdown.Opened then
            ToggleDropdown()
        end
    end
    
    -- Add Set method to update dropdown value programmatically
    Dropdown.Set = function(self, value)
        if Dropdown.Multi then
            -- For multi-select, value should be a table
            if type(value) == "table" then
                Dropdown.CurrentValue = value
                UpdateDisplay()
            end
        else
            -- For single-select, check if value exists in options
            local exists = false
            for _, option in ipairs(Dropdown.Options) do
                if option == value then
                    exists = true
                    break
                end
            end
            
            if exists then
                Dropdown.CurrentValue = value
                UpdateDisplay()
            end
        end
    end
    
    return Dropdown
end

function CustomGUI:_CreateLabel(text, tab)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Config.TextColor
    Label.TextSize = 13
    Label.Font = Config.MainFont
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Parent = tab.Container
    CreatePadding(Label, 5)
    
    return Label
end

function CustomGUI:_CreateParagraph(config, tab)
    local Paragraph = {
        Title = config.Title or "Paragraph",
        Content = config.Content or ""
    }
    
    local ParagraphFrame = Instance.new("Frame")
    ParagraphFrame.Name = "Paragraph_" .. Paragraph.Title
    ParagraphFrame.Size = UDim2.new(1, 0, 0, 0)
    ParagraphFrame.BackgroundColor3 = Config.SecondaryColor
    ParagraphFrame.BorderSizePixel = 0
    ParagraphFrame.AutomaticSize = Enum.AutomaticSize.Y
    ParagraphFrame.Parent = tab.Container
    CreateCorner(ParagraphFrame)
    CreatePadding(ParagraphFrame, 10)
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Paragraph.Title
    TitleLabel.TextColor3 = Config.AccentColor
    TitleLabel.TextSize = 14
    TitleLabel.Font = Config.TitleFont
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = ParagraphFrame
    
    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Size = UDim2.new(1, 0, 0, 0)
    ContentLabel.Position = UDim2.new(0, 0, 0, 25)
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Text = Paragraph.Content
    ContentLabel.TextColor3 = Config.SubTextColor
    ContentLabel.TextSize = 13
    ContentLabel.Font = Config.MainFont
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
    ContentLabel.TextWrapped = true
    ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
    ContentLabel.Parent = ParagraphFrame
    
    return Paragraph
end

function CustomGUI:_CreateTextBox(config, tab)
    local TextBox = {
        Name = config.Name or "TextBox",
        Placeholder = config.Placeholder or "Enter text...",
        Default = config.Default or "",
        Flag = config.Flag,
        Callback = config.Callback or function() end
    }
    
    local TextBoxFrame = Instance.new("Frame")
    TextBoxFrame.Name = "TextBox_" .. TextBox.Name
    TextBoxFrame.Size = UDim2.new(1, 0, 0, 60)
    TextBoxFrame.BackgroundColor3 = Config.SecondaryColor
    TextBoxFrame.BorderSizePixel = 0
    TextBoxFrame.Parent = tab.Container
    CreateCorner(TextBoxFrame)
    CreatePadding(TextBoxFrame, 10)
    
    local TextBoxLabel = Instance.new("TextLabel")
    TextBoxLabel.Size = UDim2.new(1, 0, 0, 20)
    TextBoxLabel.BackgroundTransparency = 1
    TextBoxLabel.Text = TextBox.Name
    TextBoxLabel.TextColor3 = Config.TextColor
    TextBoxLabel.TextSize = 14
    TextBoxLabel.Font = Config.MainFont
    TextBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextBoxLabel.Parent = TextBoxFrame
    
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, 0, 0, 25)
    Input.Position = UDim2.new(0, 0, 0, 25)
    Input.BackgroundColor3 = Config.BackgroundColor
    Input.BorderSizePixel = 0
    Input.PlaceholderText = TextBox.Placeholder
    Input.PlaceholderColor3 = Config.SubTextColor
    Input.Text = TextBox.Default
    Input.TextColor3 = Config.TextColor
    Input.TextSize = 13
    Input.Font = Config.MainFont
    -- ClearButtonMode REMOVED - causes issues in some executors
    Input.Parent = TextBoxFrame
    CreateCorner(Input, UDim.new(0, 5))
    CreatePadding(Input, 8)
    
    Input.FocusLost:Connect(function()
        if TextBox.Flag then
            self.Flags[TextBox.Flag] = Input.Text
        end
        
        pcall(function()
            TextBox.Callback(Input.Text)
        end)
    end)
    
    -- Add Set method to update text programmatically
    TextBox.Set = function(self, text)
        Input.Text = text
    end
    
    return TextBox
end

function CustomGUI:_CreateColorPicker(config, tab)
    local ColorPicker = {
        Name = config.Name or "Color Picker",
        Default = config.Default or Color3.fromRGB(255, 255, 255),
        CurrentColor = config.Default or Color3.fromRGB(255, 255, 255),
        Flag = config.Flag,
        Callback = config.Callback or function() end
    }
    
    local ColorFrame = Instance.new("Frame")
    ColorFrame.Name = "ColorPicker_" .. ColorPicker.Name
    ColorFrame.Size = UDim2.new(1, 0, 0, Config.ButtonHeight)
    ColorFrame.BackgroundColor3 = Config.SecondaryColor
    ColorFrame.BorderSizePixel = 0
    ColorFrame.Parent = tab.Container
    CreateCorner(ColorFrame)
    
    local ColorLabel = Instance.new("TextLabel")
    ColorLabel.Size = UDim2.new(1, -60, 1, 0)
    ColorLabel.Position = UDim2.new(0, 10, 0, 0)
    ColorLabel.BackgroundTransparency = 1
    ColorLabel.Text = ColorPicker.Name
    ColorLabel.TextColor3 = Config.TextColor
    ColorLabel.TextSize = 14
    ColorLabel.Font = Config.MainFont
    ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    ColorLabel.Parent = ColorFrame
    
    local ColorDisplay = Instance.new("Frame")
    ColorDisplay.Size = UDim2.new(0, 40, 0, 25)
    ColorDisplay.Position = UDim2.new(1, -50, 0.5, -12.5)
    ColorDisplay.BackgroundColor3 = ColorPicker.CurrentColor
    ColorDisplay.BorderSizePixel = 0
    ColorDisplay.Parent = ColorFrame
    CreateCorner(ColorDisplay, UDim.new(0, 5))
    CreateStroke(ColorDisplay, Config.BorderColor)
    
    local ColorButton = Instance.new("TextButton")
    ColorButton.Size = UDim2.new(1, 0, 1, 0)
    ColorButton.BackgroundTransparency = 1
    ColorButton.Text = ""
    ColorButton.Parent = ColorFrame
    
    ColorButton.MouseButton1Click:Connect(function()
        -- Simple color randomizer for demo (you can expand this to a full color picker)
        local randomColor = Color3.fromRGB(
            math.random(0, 255),
            math.random(0, 255),
            math.random(0, 255)
        )
        ColorPicker.CurrentColor = randomColor
        ColorDisplay.BackgroundColor3 = randomColor
        
        if ColorPicker.Flag then
            self.Flags[ColorPicker.Flag] = randomColor
        end
        
        pcall(function()
            ColorPicker.Callback(randomColor)
        end)
    end)
    
    ColorButton.MouseEnter:Connect(function()
        Tween(ColorFrame, {BackgroundColor3 = Config.BorderColor})
    end)
    
    ColorButton.MouseLeave:Connect(function()
        Tween(ColorFrame, {BackgroundColor3 = Config.SecondaryColor})
    end)
    
    -- Add Set method to update color programmatically
    ColorPicker.Set = function(self, color)
        ColorPicker.CurrentColor = color
        ColorDisplay.BackgroundColor3 = color
    end
    
    return ColorPicker
end

function CustomGUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function CustomGUI:SetVisible(visible)
    if self.MainWindow then
        self.MainWindow.Visible = visible
    end
end

function CustomGUI:GetFlag(flag)
    return self.Flags[flag]
end

return CustomGUI
