-- UI Library
local UI = {}
UI.__index = UI

-- Animation service
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Create main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernUILib"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

-- Main container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Modern UI Library"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamSemibold

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.GothamBold

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 4)
UICorner2.Parent = CloseButton

-- Tab container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(0, 120, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabContainer.BorderSizePixel = 0

-- Content container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -120, 1, -40)
ContentContainer.Position = UDim2.new(0, 120, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ClipsDescendants = true

-- Notifications container
local Notifications = Instance.new("Frame")
Notifications.Name = "Notifications"
Notifications.Size = UDim2.new(0, 300, 1, 0)
Notifications.Position = UDim2.new(1, 10, 0, 0)
Notifications.BackgroundTransparency = 1
Notifications.BorderSizePixel = 0

-- Parent everything
TopBar.Parent = MainFrame
Title.Parent = TopBar
CloseButton.Parent = TopBar
TabContainer.Parent = MainFrame
ContentContainer.Parent = MainFrame
Notifications.Parent = MainFrame
MainFrame.Parent = ScreenGui

-- Dragging functionality
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Close button functionality
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Animation function
function UI:TweenObject(obj, properties, duration, ...)
    local tweenInfo = TweenInfo.new(duration, ...)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Notification system
function UI:Notify(title, message, duration)
    duration = duration or 5
    
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 80)
    Notification.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Notification.BorderSizePixel = 0
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Notification
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Position = UDim2.new(0, 10, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = Enum.Font.GothamSemibold
    TitleLabel.Parent = Notification
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -20, 1, -40)
    MessageLabel.Position = UDim2.new(0, 10, 0, 35)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    MessageLabel.TextSize = 12
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextWrapped = true
    MessageLabel.Parent = Notification
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 0, 3)
    ProgressBar.Position = UDim2.new(0, 0, 1, -3)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = Notification
    
    Notification.Parent = Notifications
    Notification.Position = UDim2.new(0, 0, 1, 0)
    
    -- Animate in
    self:TweenObject(Notification, {Position = UDim2.new(0, 0, 1, -90)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Animate progress bar
    self:TweenObject(ProgressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
    
    -- Remove after duration
    task.delay(duration, function()
        self:TweenObject(Notification, {Position = UDim2.new(0, 0, 1, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.wait(0.3)
        Notification:Destroy()
    end)
end

-- Tab management
UI.Tabs = {}
UI.CurrentTab = nil

function UI:AddTab(name)
    local Tab = {}
    
    -- Tab button
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(1, -10, 0, 35)
    TabButton.Position = UDim2.new(0, 5, 0, 5 + (#self.Tabs * 40))
    TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    TabButton.BorderSizePixel = 0
    TabButton.Text = name
    TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabButton.TextSize = 14
    TabButton.Font = Enum.Font.Gotham
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = TabButton
    
    -- Tab content
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = name .. "Content"
    TabContent.Size = UDim2.new(1, 0, 1, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.ScrollBarThickness = 3
    TabContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
    TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = TabContent
    
    TabButton.Parent = TabContainer
    TabContent.Parent = ContentContainer
    TabContent.Visible = false
    
    -- Tab selection
    TabButton.MouseButton1Click:Connect(function()
        self:SelectTab(Tab)
    end)
    
    -- Set as first tab if none selected
    if #self.Tabs == 0 then
        self:SelectTab(Tab)
    end
    
    Tab.Button = TabButton
    Tab.Content = TabContent
    Tab.Name = name
    Tab.Sections = {}
    
    table.insert(self.Tabs, Tab)
    return Tab
end

function UI:SelectTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Content.Visible = false
        self:TweenObject(self.CurrentTab.Button, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
    end
    
    self.CurrentTab = tab
    tab.Content.Visible = true
    self:TweenObject(tab.Button, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
end

-- Section management
function UI:AddSection(name, side)
    side = side or "Left"
    
    local Section = {}
    
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Name = name .. "Section"
    SectionFrame.Size = UDim2.new(0.95, 0, 0, 0)
    SectionFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    SectionFrame.BorderSizePixel = 0
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = SectionFrame
    
    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "Title"
    SectionTitle.Size = UDim2.new(1, -20, 0, 25)
    SectionTitle.Position = UDim2.new(0, 10, 0, 5)
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Text = name
    SectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SectionTitle.TextSize = 14
    SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SectionTitle.Font = Enum.Font.GothamSemibold
    SectionTitle.Parent = SectionFrame
    
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -40)
    Content.Position = UDim2.new(0, 10, 0, 35)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = Content
    
    Content.Parent = SectionFrame
    SectionFrame.Parent = self.CurrentTab.Content
    SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
    
    Section.Frame = SectionFrame
    Section.Content = Content
    
    table.insert(self.CurrentTab.Sections, Section)
    return Section
end

-- UI Elements
function UI:AddButton(section, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.Gotham
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        self:TweenObject(Button, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.1)
        task.wait(0.1)
        self:TweenObject(Button, {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}, 0.1)
        callback()
    end)
    
    Button.Parent = section.Content
    return Button
end

function UI:AddToggle(section, text, default, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 30)
    Toggle.BackgroundTransparency = 1
    Toggle.BorderSizePixel = 0
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleLabel.TextSize = 14
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.Parent = Toggle
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 40, 0, 20)
    ToggleButton.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = ToggleButton
    
    local ToggleKnob = Instance.new("Frame")
    ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
    ToggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
    ToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleKnob.BorderSizePixel = 0
    
    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 8)
    UICorner2.Parent = ToggleKnob
    
    ToggleKnob.Parent = ToggleButton
    ToggleButton.Parent = Toggle
    
    local state = default or false
    
    local function updateToggle()
        if state then
            self:TweenObject(ToggleButton, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
            self:TweenObject(ToggleKnob, {Position = UDim2.new(0, 22, 0.5, -8)}, 0.2)
        else
            self:TweenObject(ToggleButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.2)
            self:TweenObject(ToggleKnob, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
        end
        callback(state)
    end
    
    ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
    end)
    
    updateToggle()
    Toggle.Parent = section.Content
    return Toggle
end

function UI:AddTextbox(section, text, placeholder, callback)
    local Textbox = Instance.new("Frame")
    Textbox.Size = UDim2.new(1, 0, 0, 30)
    Textbox.BackgroundTransparency = 1
    Textbox.BorderSizePixel = 0
    
    local TextboxLabel = Instance.new("TextLabel")
    TextboxLabel.Size = UDim2.new(0.4, 0, 1, 0)
    TextboxLabel.BackgroundTransparency = 1
    TextboxLabel.Text = text
    TextboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextboxLabel.TextSize = 14
    TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextboxLabel.Font = Enum.Font.Gotham
    TextboxLabel.Parent = Textbox
    
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(0.55, 0, 1, 0)
    Input.Position = UDim2.new(0.45, 0, 0, 0)
    Input.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Input.BorderSizePixel = 0
    Input.Text = ""
    Input.PlaceholderText = placeholder
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.TextSize = 14
    Input.Font = Enum.Font.Gotham
    Input.ClearTextOnFocus = false
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Input
    
    Input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(Input.Text)
        end
    end)
    
    Input.Parent = Textbox
    Textbox.Parent = section.Content
    return Textbox
end

function UI:AddDropdown(section, text, options, callback)
    local Dropdown = {}
    local state = false
    local selected = options[1] or "Select..."
    
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Size = UDim2.new(1, 0, 0, 30)
    DropdownFrame.BackgroundTransparency = 1
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.ClipsDescendants = true
    
    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Size = UDim2.new(0.4, 0, 1, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = text
    DropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropdownLabel.TextSize = 14
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Font = Enum.Font.Gotham
    DropdownLabel.Parent = DropdownFrame
    
    local MainButton = Instance.new("TextButton")
    MainButton.Size = UDim2.new(0.55, 0, 0, 30)
    MainButton.Position = UDim2.new(0.45, 0, 0, 0)
    MainButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    MainButton.BorderSizePixel = 0
    MainButton.Text = selected
    MainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainButton.TextSize = 14
    MainButton.Font = Enum.Font.Gotham
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = MainButton
    
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    OptionsFrame.Position = UDim2.new(0, 0, 1, 5)
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    OptionsFrame.BorderSizePixel = 0
    OptionsFrame.ClipsDescendants = true
    
    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 4)
    UICorner2.Parent = OptionsFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = OptionsFrame
    
    MainButton.Parent = DropdownFrame
    OptionsFrame.Parent = DropdownFrame
    
    -- Create option buttons
    for i, option in ipairs(options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Size = UDim2.new(1, 0, 0, 25)
        OptionButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        OptionButton.BorderSizePixel = 0
        OptionButton.Text = option
        OptionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptionButton.TextSize = 12
        OptionButton.Font = Enum.Font.Gotham
        
        OptionButton.MouseButton1Click:Connect(function()
            selected = option
            MainButton.Text = selected
            callback(selected)
            self:ToggleDropdown(Dropdown)
        end)
        
        OptionButton.Parent = OptionsFrame
    end
    
    function Dropdown:Toggle()
        UI:ToggleDropdown(Dropdown)
    end
    
    function Dropdown:SetValue(value)
        selected = value
        MainButton.Text = selected
        callback(selected)
    end
    
    MainButton.MouseButton1Click:Connect(function()
        self:ToggleDropdown(Dropdown)
    end)
    
    DropdownFrame.Parent = section.Content
    Dropdown.MainFrame = DropdownFrame
    Dropdown.MainButton = MainButton
    Dropdown.OptionsFrame = OptionsFrame
    Dropdown.Options = options
    
    return Dropdown
end

function UI:ToggleDropdown(dropdown)
    local state = dropdown.OptionsFrame.Size.Y.Offset > 0
    
    if state then
        self:TweenObject(dropdown.OptionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
        self:TweenObject(dropdown.MainFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.2)
    else
        local optionCount = #dropdown.Options
        local newHeight = math.min(optionCount * 25, 125)
        self:TweenObject(dropdown.OptionsFrame, {Size = UDim2.new(1, 0, 0, newHeight)}, 0.2)
        self:TweenObject(dropdown.MainFrame, {Size = UDim2.new(1, 0, 0, 30 + newHeight + 5)}, 0.2)
    end
end

function UI:AddLabel(section, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.Parent = section.Content
    return Label
end

function UI:AddKeybind(section, text, default, callback)
    local Keybind = Instance.new("Frame")
    Keybind.Size = UDim2.new(1, 0, 0, 30)
    Keybind.BackgroundTransparency = 1
    Keybind.BorderSizePixel = 0
    
    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Size = UDim2.new(0.7, 0, 1, 0)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Text = text
    KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindLabel.TextSize = 14
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeybindLabel.Font = Enum.Font.Gotham
    KeybindLabel.Parent = Keybind
    
    local KeybindButton = Instance.new("TextButton")
    KeybindButton.Size = UDim2.new(0, 80, 0, 25)
    KeybindButton.Position = UDim2.new(1, -80, 0.5, -12.5)
    KeybindButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    KeybindButton.BorderSizePixel = 0
    KeybindButton.Text = default and default.Name or "None"
    KeybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindButton.TextSize = 12
    KeybindButton.Font = Enum.Font.Gotham
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = KeybindButton
    
    local listening = false
    
    KeybindButton.MouseButton1Click:Connect(function()
        listening = true
        KeybindButton.Text = "..."
        self:TweenObject(KeybindButton, {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}, 0.2)
    end)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and not gameProcessed then
            listening = false
            KeybindButton.Text = input.KeyCode.Name
            self:TweenObject(KeybindButton, {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}, 0.2)
            callback(input.KeyCode)
            connection:Disconnect()
        end
    end)
    
    KeybindButton.Parent = Keybind
    Keybind.Parent = section.Content
    return Keybind
end

function UI:AddColorPicker(section, text, default, callback)
    local ColorPicker = {}
    local state = false
    local currentColor = default or Color3.fromRGB(255, 255, 255)
    
    local ColorPickerFrame = Instance.new("Frame")
    ColorPickerFrame.Size = UDim2.new(1, 0, 0, 30)
    ColorPickerFrame.BackgroundTransparency = 1
    ColorPickerFrame.BorderSizePixel = 0
    
    local ColorPickerLabel = Instance.new("TextLabel")
    ColorPickerLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ColorPickerLabel.BackgroundTransparency = 1
    ColorPickerLabel.Text = text
    ColorPickerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ColorPickerLabel.TextSize = 14
    ColorPickerLabel.TextXAlignment = Enum.TextXAlignment.Left
    ColorPickerLabel.Font = Enum.Font.Gotham
    ColorPickerLabel.Parent = ColorPickerFrame
    
    local ColorButton = Instance.new("TextButton")
    ColorButton.Size = UDim2.new(0, 60, 0, 25)
    ColorButton.Position = UDim2.new(1, -60, 0.5, -12.5)
    ColorButton.BackgroundColor3 = currentColor
    ColorButton.BorderSizePixel = 0
    ColorButton.Text = ""
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = ColorButton
    
    local PickerFrame = Instance.new("Frame")
    PickerFrame.Size = UDim2.new(1, 0, 0, 100)
    PickerFrame.Position = UDim2.new(0, 0, 1, 5)
    PickerFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    PickerFrame.BorderSizePixel = 0
    PickerFrame.Visible = false
    
    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 4)
    UICorner2.Parent = PickerFrame
    
    -- Color spectrum (simplified)
    local Spectrum = Instance.new("ImageLabel")
    Spectrum.Size = UDim2.new(0.7, -5, 0, 80)
    Spectrum.Position = UDim2.new(0, 5, 0, 10)
    Spectrum.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Spectrum.BorderSizePixel = 0
    Spectrum.Image = "rbxassetid://14204231522" -- Color spectrum image
    Spectrum.Parent = PickerFrame
    
    local Brightness = Instance.new("Frame")
    Brightness.Size = UDim2.new(0, 20, 0, 80)
    Brightness.Position = UDim2.new(0.7, 10, 0, 10)
    Brightness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Brightness.BorderSizePixel = 0
    Brightness.Parent = PickerFrame
    
    local UICorner3 = Instance.new("UICorner")
    UICorner3.CornerRadius = UDim.new(0, 4)
    UICorner3.Parent = Brightness
    
    local BrightnessGradient = Instance.new("UIGradient")
    BrightnessGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
    }
    BrightnessGradient.Rotation = 90
    BrightnessGradient.Parent = Brightness
    
    ColorButton.Parent = ColorPickerFrame
    PickerFrame.Parent = ColorPickerFrame
    
    function ColorPicker:Toggle()
        state = not state
        PickerFrame.Visible = state
        if state then
            self:TweenObject(ColorPickerFrame, {Size = UDim2.new(1, 0, 0, 140)}, 0.2)
        else
            self:TweenObject(ColorPickerFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.2)
        end
    end
    
    ColorButton.MouseButton1Click:Connect(function()
        ColorPicker:Toggle()
    end)
    
    ColorPickerFrame.Parent = section.Content
    return ColorPicker
end

-- Settings tab
local SettingsTab = UI:AddTab("Settings")

-- Toggle UI keybind
local SettingsSection = SettingsTab:AddSection("UI Settings", "Left")
UI:AddKeybind(SettingsSection, "Toggle UI", Enum.KeyCode.RightShift, function(key)
    -- Toggle UI visibility
    MainFrame.Visible = not MainFrame.Visible
    UI:Notify("UI Toggled", "UI has been " .. (MainFrame.Visible and "enabled" or "disabled"), 3)
end)

-- Unload button
UI:AddButton(SettingsSection, "Unload UI", function()
    ScreenGui:Destroy()
    UI:Notify("UI Unloaded", "The UI has been successfully unloaded", 3)
end)

-- Config system (simplified)
local ConfigSection = SettingsTab:AddSection("Configs", "Left")
UI:AddTextbox(ConfigSection, "Config Name", "Enter config name", function(text)
    -- Save config logic would go here
    UI:Notify("Config Saved", "Config '" .. text .. "' has been saved", 3)
end)

UI:AddDropdown(ConfigSection, "Load Config", {"Default", "Config 1", "Config 2"}, function(selected)
    -- Load config logic would go here
    UI:Notify("Config Loaded", "Config '" .. selected .. "' has been loaded", 3)
end)

-- Example usage section
local ExampleTab = UI:AddTab("Main Tab")
local ExampleSection = ExampleTab:AddSection("Main Section", "Left")

-- Example elements
UI:AddButton(ExampleSection, "Example Button", function()
    UI:Notify("Button Clicked", "You clicked the example button!", 3)
end)

UI:AddToggle(ExampleSection, "Example Toggle", false, function(state)
    UI:Notify("Toggle Changed", "Toggle is now " .. (state and "enabled" or "disabled"), 3)
end)

UI:AddTextbox(ExampleSection, "Example Textbox", "Enter text here", function(text)
    UI:Notify("Textbox Submitted", "You entered: " .. text, 3)
end)

UI:AddDropdown(ExampleSection, "Example Dropdown", {"Option 1", "Option 2", "Option 3"}, function(selected)
    UI:Notify("Dropdown Selected", "You selected: " .. selected, 3)
end)

UI:AddLabel(ExampleSection, "This is an example label")

UI:AddKeybind(ExampleSection, "Example Keybind", Enum.KeyCode.F, function(key)
    UI:Notify("Keybind Pressed", "You pressed: " .. key.Name, 3)
end)

-- Return the UI library
return UI
