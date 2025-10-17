-- Animated GUI Library
local GuiLibrary = {}
GuiLibrary.__index = GuiLibrary

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Animation settings
local ANIMATION_SPEED = 0.2
local EASING_STYLE = Enum.EasingStyle.Quad
local EASING_DIRECTION = Enum.EasingDirection.Out

-- Notifier system
local Notifier = {}
Notifier.__index = Notifier

function Notifier.new(parent)
	local self = setmetatable({}, Notifier)
	self.container = Instance.new("Frame")
	self.container.Name = "NotifierContainer"
	self.container.Size = UDim2.new(1, 0, 1, 0)
	self.container.BackgroundTransparency = 1
	self.container.Parent = parent
	self.container.ZIndex = 100
	
	self.notifications = {}
	return self
end

function Notifier:Notify(title, message, notificationType, duration)
	duration = duration or 5
	
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 300, 0, 80)
	notification.Position = UDim2.new(1, 10, 0.1, 0)
	notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	notification.BorderSizePixel = 0
	notification.ZIndex = 101
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Thickness = 2
	stroke.Parent = notification
	
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 15, 0, 15)
	icon.BackgroundTransparency = 1
	icon.ZIndex = 102
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -50, 0, 20)
	titleLabel.Position = UDim2.new(0, 50, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 102
	
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -50, 0, 40)
	messageLabel.Position = UDim2.new(0, 50, 0, 35)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.ZIndex = 102
	
	-- Set colors based on type
	local color
	if notificationType == "success" then
		color = Color3.fromRGB(76, 175, 80)
		icon.Image = "rbxassetid://3926305904"
		icon.ImageRectOffset = Vector2.new(524, 204)
		icon.ImageRectSize = Vector2.new(36, 36)
	elseif notificationType == "error" then
		color = Color3.fromRGB(244, 67, 54)
		icon.Image = "rbxassetid://3926305904"
		icon.ImageRectOffset = Vector2.new(244, 204)
		icon.ImageRectSize = Vector2.new(36, 36)
	elseif notificationType == "warning" then
		color = Color3.fromRGB(255, 193, 7)
		icon.Image = "rbxassetid://3926305904"
		icon.ImageRectOffset = Vector2.new(644, 204)
		icon.ImageRectSize = Vector2.new(36, 36)
	else
		color = Color3.fromRGB(33, 150, 243)
		icon.Image = "rbxassetid://3926305904"
		icon.ImageRectOffset = Vector2.new(164, 204)
		icon.ImageRectSize = Vector2.new(36, 36)
	end
	
	stroke.Color = color
	titleLabel.TextColor3 = color
	
	icon.Parent = notification
	titleLabel.Parent = notification
	messageLabel.Parent = notification
	notification.Parent = self.container
	
	-- Animation
	notification.Position = UDim2.new(1, 10, 0.1, 0)
	local slideIn = TweenService:Create(
		notification,
		TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
		{Position = UDim2.new(1, -310, 0.1, 0)}
	)
	slideIn:Play()
	
	-- Move other notifications up
	for _, notif in ipairs(self.notifications) do
		local currentPos = notif.Position
		local moveUp = TweenService:Create(
			notif,
			TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
			{Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset - 90)}
		)
		moveUp:Play()
	end
	
	table.insert(self.notifications, notification)
	
	-- Auto remove after duration
	task.delay(duration, function()
		self:RemoveNotification(notification)
	end)
	
	return notification
end

function Notifier:RemoveNotification(notification)
	local index = table.find(self.notifications, notification)
	if index then
		table.remove(self.notifications, index)
		
		local slideOut = TweenService:Create(
			notification,
			TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
			{Position = UDim2.new(1, 10, notification.Position.Y.Scale, notification.Position.Y.Offset)}
		)
		slideOut:Play()
		
		slideOut.Completed:Connect(function()
			notification:Destroy()
		end)
		
		-- Move other notifications down
		for i = index, #self.notifications do
			local notif = self.notifications[i]
			if notif then
				local currentPos = notif.Position
				local moveDown = TweenService:Create(
					notif,
					TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
					{Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset + 90)}
				)
				moveDown:Play()
			end
		end
	end
end

-- Code Verifier
local CodeVerifier = {}
CodeVerifier.__index = CodeVerifier

function CodeVerifier.VerifyLuaCode(code)
	local success, result = pcall(function()
		-- Basic syntax checking
		if type(code) ~= "string" then
			return false, "Code must be a string"
		end
		
		-- Check for dangerous patterns
		local dangerousPatterns = {
			"while true do",
			"while wait%(%) do",
			"coroutine%.wrap%(function%(%) while true do",
			"spawn%(function%(%) while true do",
			"game%.GetService%('RunService'%).Heartbeat:Connect%(function%(%) while true do"
		}
		
		for _, pattern in ipairs(dangerousPatterns) do
			if string.find(code:lower(), pattern:lower()) then
				return false, "Potentially dangerous code detected"
			end
		end
		
		-- Try to compile the code
		local compiled = loadstring(code)
		if not compiled then
			return false, "Syntax error in code"
		end
		
		return true, "Code verification successful"
	end)
	
	if not success then
		return false, "Verification failed: " .. tostring(result)
	end
	
	return result
end

-- Main GUI Library Functions
function GuiLibrary.new(options)
	options = options or {}
	local self = setmetatable({}, GuiLibrary)
	
	self.name = options.name or "GUI Library"
	self.version = options.version or "1.0.0"
	self.toggleKey = options.toggleKey or Enum.KeyCode.RightShift
	self.configs = {}
	
	-- Create main GUI
	self:CreateGUI()
	
	-- Create notifier
	self.notifier = Notifier.new(self.mainFrame)
	
	-- Set up toggle key
	self:SetupToggleKey()
	
	return self
end

function GuiLibrary:CreateGUI()
	-- ScreenGui
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Name = "AnimatedGUILibrary"
	self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	self.screenGui.DisplayOrder = 999
	self.screenGui.ResetOnSpawn = false
	
	if LocalPlayer then
		self.screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	
	-- Main Container
	self.mainFrame = Instance.new("Frame")
	self.mainFrame.Name = "MainFrame"
	self.mainFrame.Size = UDim2.new(0, 500, 0, 400)
	self.mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	self.mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	self.mainFrame.BorderSizePixel = 0
	self.mainFrame.ClipsDescendants = true
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = self.mainFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = self.mainFrame
	
	local dropShadow = Instance.new("ImageLabel")
	dropShadow.Name = "DropShadow"
	dropShadow.Size = UDim2.new(1, 12, 1, 12)
	dropShadow.Position = UDim2.new(0, -6, 0, -6)
	dropShadow.BackgroundTransparency = 1
	dropShadow.Image = "rbxassetid://6014261993"
	dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	dropShadow.ImageTransparency = 0.8
	dropShadow.ScaleType = Enum.ScaleType.Slice
	dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	dropShadow.Parent = self.mainFrame
	
	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = self.mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = self.name
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
	
	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "×"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	closeButton.Parent = titleBar
	
	-- Tab Container
	self.tabContainer = Instance.new("Frame")
	self.tabContainer.Name = "TabContainer"
	self.tabContainer.Size = UDim2.new(0, 120, 1, -40)
	self.tabContainer.Position = UDim2.new(0, 0, 0, 40)
	self.tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	self.tabContainer.BorderSizePixel = 0
	self.tabContainer.Parent = self.mainFrame
	
	-- Content Container
	self.contentContainer = Instance.new("Frame")
	self.contentContainer.Name = "ContentContainer"
	self.contentContainer.Size = UDim2.new(1, -120, 1, -40)
	self.contentContainer.Position = UDim2.new(0, 120, 0, 40)
	self.contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	self.contentContainer.BorderSizePixel = 0
	self.contentContainer.ClipsDescendants = true
	self.contentContainer.Parent = self.mainFrame
	
	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = self.contentContainer
	
	-- Scroll Container for content
	self.scrollContainer = Instance.new("ScrollingFrame")
	self.scrollContainer.Name = "ScrollContainer"
	self.scrollContainer.Size = UDim2.new(1, 0, 1, 0)
	self.scrollContainer.BackgroundTransparency = 1
	self.scrollContainer.BorderSizePixel = 0
	self.scrollContainer.ScrollBarThickness = 4
	self.scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	self.scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.scrollContainer.Parent = self.contentContainer
	
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 5)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = self.scrollContainer
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.PaddingTop = UDim.new(0, 10)
	uiPadding.PaddingBottom = UDim.new(0, 10)
	uiPadding.Parent = self.scrollContainer
	
	-- Store tabs and elements
	self.tabs = {}
	self.currentTab = nil
	
	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		self:ToggleGUI()
	end)
	
	-- Make draggable
	self:MakeDraggable(titleBar)
	
	self.mainFrame.Parent = self.screenGui
	self.mainFrame.Visible = false
end

function GuiLibrary:MakeDraggable(frame)
	local dragStart = nil
	local startPos = nil
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = input.Position
			startPos = self.mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragStart = nil
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
			local delta = input.Position - dragStart
			self.mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function GuiLibrary:SetupToggleKey()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == self.toggleKey then
			self:ToggleGUI()
		end
	end)
end

function GuiLibrary:ToggleGUI()
	self.mainFrame.Visible = not self.mainFrame.Visible
	
	if self.mainFrame.Visible then
		self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
		self.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		local openTween = TweenService:Create(
			self.mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 500, 0, 400), Position = UDim2.new(0.5, -250, 0.5, -200)}
		)
		openTween:Play()
	else
		local closeTween = TweenService:Create(
			self.mainFrame,
			TweenInfo.new(0.2, EASING_STYLE, EASING_DIRECTION),
			{Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
		)
		closeTween:Play()
		
		closeTween.Completed:Connect(function()
			if not self.mainFrame.Visible then
				self.mainFrame.Size = UDim2.new(0, 500, 0, 400)
				self.mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
			end
		end)
	end
end

function GuiLibrary:AddTab(tabName)
	local tab = {}
	tab.name = tabName
	tab.elements = {}
	
	-- Tab Button
	local tabButton = Instance.new("TextButton")
	tabButton.Name = tabName .. "Tab"
	tabButton.Size = UDim2.new(1, -10, 0, 35)
	tabButton.Position = UDim2.new(0, 5, 0, 5 + (#self.tabs * 40))
	tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabButton.BorderSizePixel = 0
	tabButton.Text = tabName
	tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	tabButton.TextSize = 14
	tabButton.Font = Enum.Font.Gotham
	
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tabButton
	
	-- Tab Content
	local tabContent = Instance.new("Frame")
	tabContent.Name = tabName .. "Content"
	tabContent.Size = UDim2.new(1, 0, 1, 0)
	tabContent.BackgroundTransparency = 1
	tabContent.Visible = false
	tabContent.Parent = self.scrollContainer
	
	local contentListLayout = Instance.new("UIListLayout")
	contentListLayout.Padding = UDim.new(0, 5)
	contentListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentListLayout.Parent = tabContent
	
	tab.button = tabButton
	tab.content = tabContent
	
	-- Select first tab by default
	if #self.tabs == 0 then
		self.currentTab = tab
		tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		tabContent.Visible = true
	else
		tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	end
	
	tabButton.Parent = self.tabContainer
	
	-- Tab selection
	tabButton.MouseButton1Click:Connect(function()
		if self.currentTab == tab then return end
		
		-- Animate current tab out
		if self.currentTab then
			local oldTab = self.currentTab
			oldTab.content.Visible = false
			
			local oldTween = TweenService:Create(
				oldTab.button,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{BackgroundColor3 = Color3.fromRGB(40, 40, 40)}
			)
			oldTween:Play()
		end
		
		-- Animate new tab in
		self.currentTab = tab
		tabContent.Visible = true
		
		local newTween = TweenService:Create(
			tabButton,
			TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		newTween:Play()
	end)
	
	table.insert(self.tabs, tab)
	return tab
end

-- Element creation functions
function GuiLibrary:AddButton(tab, options)
	options = options or {}
	local button = Instance.new("TextButton")
	button.Name = options.name or "Button"
	button.Size = UDim2.new(1, 0, 0, 35)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = options.text or "Button"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.Gotham
	button.AutoButtonColor = false
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Thickness = 1
	stroke.Parent = button
	
	-- Hover animations
	button.MouseEnter:Connect(function()
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
		)
		tween:Play()
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(
			button,
			TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(50, 50, 50)}
		)
		tween:Play()
	end)
	
	-- Click animation and callback
	button.MouseButton1Click:Connect(function()
		-- Click animation
		local clickTween = TweenService:Create(
			button,
			TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
		)
		clickTween:Play()
		
		clickTween.Completed:Connect(function()
			local releaseTween = TweenService:Create(
				button,
				TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
				{BackgroundColor3 = Color3.fromRGB(50, 50, 50)}
			)
			releaseTween:Play()
		end)
		
		if options.callback then
			options.callback()
		end
	end)
	
	button.Parent = tab.content
	return button
end

function GuiLibrary:AddToggle(tab, options)
	options = options or {}
	local toggle = {}
	toggle.value = options.default or false
	
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = options.name or "Toggle"
	toggleFrame.Size = UDim2.new(1, 0, 0, 30)
	toggleFrame.BackgroundTransparency = 1
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = options.text or "Toggle"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggleFrame
	
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 40, 0, 20)
	toggleButton.Position = UDim2.new(1, -40, 0.5, -10)
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = ""
	toggleButton.AutoButtonColor = false
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 10)
	toggleCorner.Parent = toggleButton
	
	local toggleKnob = Instance.new("Frame")
	toggleKnob.Name = "Knob"
	toggleKnob.Size = UDim2.new(0, 16, 0, 16)
	toggleKnob.Position = UDim2.new(0, 2, 0, 2)
	toggleKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	toggleKnob.BorderSizePixel = 0
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 8)
	knobCorner.Parent = toggleKnob
	
	toggleKnob.Parent = toggleButton
	toggleButton.Parent = toggleFrame
	
	-- Update toggle state
	local function updateToggle()
		if toggle.value then
			local tween = TweenService:Create(
				toggleButton,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{BackgroundColor3 = Color3.fromRGB(76, 175, 80)}
			)
			tween:Play()
			
			local knobTween = TweenService:Create(
				toggleKnob,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Position = UDim2.new(0, 22, 0, 2)}
			)
			knobTween:Play()
		else
			local tween = TweenService:Create(
				toggleButton,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{BackgroundColor3 = Color3.fromRGB(60, 60, 60)}
			)
			tween:Play()
			
			local knobTween = TweenService:Create(
				toggleKnob,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Position = UDim2.new(0, 2, 0, 2)}
			)
			knobTween:Play()
		end
	end
	
	-- Initial state
	updateToggle()
	
	-- Toggle click
	toggleButton.MouseButton1Click:Connect(function()
		toggle.value = not toggle.value
		updateToggle()
		
		if options.callback then
			options.callback(toggle.value)
		end
	end)
	
	toggleFrame.Parent = tab.content
	toggle.frame = toggleFrame
	toggle.update = updateToggle
	
	return toggle
end

function GuiLibrary:AddLabel(tab, options)
	options = options or {}
	local label = Instance.new("TextLabel")
	label.Name = options.name or "Label"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = options.text or "Label"
	label.TextColor3 = options.color or Color3.fromRGB(255, 255, 255)
	label.TextSize = options.size or 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	
	label.Parent = tab.content
	return label
end

function GuiLibrary:AddTextbox(tab, options)
	options = options or {}
	local textbox = Instance.new("TextBox")
	textbox.Name = options.name or "Textbox"
	textbox.Size = UDim2.new(1, 0, 0, 35)
	textbox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	textbox.BorderSizePixel = 0
	textbox.Text = options.text or ""
	textbox.PlaceholderText = options.placeholder or "Enter text..."
	textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textbox.TextSize = 14
	textbox.Font = Enum.Font.Gotham
	textbox.ClearTextOnFocus = options.clearOnFocus or false
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = textbox
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Thickness = 1
	stroke.Parent = textbox
	
	-- Focus animations
	textbox.Focused:Connect(function()
		local tween = TweenService:Create(
			textbox,
			TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(55, 55, 55)}
		)
		tween:Play()
	end)
	
	textbox.FocusLost:Connect(function()
		local tween = TweenService:Create(
			textbox,
			TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
			{BackgroundColor3 = Color3.fromRGB(45, 45, 45)}
		)
		tween:Play()
		
		if options.callback then
			options.callback(textbox.Text)
		end
	end)
	
	textbox.Parent = tab.content
	return textbox
end

function GuiLibrary:AddDropdown(tab, options)
	options = options or {}
	local dropdown = {}
	dropdown.options = options.options or {}
	dropdown.value = options.default or (options.options and options.options[1]) or nil
	dropdown.open = false
	
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Name = options.name or "Dropdown"
	dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
	dropdownFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	dropdownFrame.BorderSizePixel = 0
	dropdownFrame.ClipsDescendants = true
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = dropdownFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Thickness = 1
	stroke.Parent = dropdownFrame
	
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "Selected"
	selectedLabel.Size = UDim2.new(1, -30, 1, 0)
	selectedLabel.Position = UDim2.new(0, 10, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = dropdown.value or "Select..."
	selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectedLabel.TextSize = 14
	selectedLabel.Font = Enum.Font.Gotham
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.Parent = dropdownFrame
	
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(0, 16, 0, 16)
	arrow.Position = UDim2.new(1, -23, 0.5, -8)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://3926305904"
	arrow.ImageRectOffset = Vector2.new(884, 284)
	arrow.ImageRectSize = Vector2.new(36, 36)
	arrow.ImageColor3 = Color3.fromRGB(200, 200, 200)
	arrow.Parent = dropdownFrame
	
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.Position = UDim2.new(0, 0, 1, 5)
	optionsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	optionsFrame.BorderSizePixel = 0
	optionsFrame.ClipsDescendants = true
	
	local optionsCorner = Instance.new("UICorner")
	optionsCorner.CornerRadius = UDim.new(0, 6)
	optionsCorner.Parent = optionsFrame
	
	local optionsStroke = Instance.new("UIStroke")
	optionsStroke.Color = Color3.fromRGB(80, 80, 80)
	optionsStroke.Thickness = 1
	optionsStroke.Parent = optionsFrame
	
	local optionsList = Instance.new("UIListLayout")
	optionsList.Padding = UDim.new(0, 1)
	optionsList.SortOrder = Enum.SortOrder.LayoutOrder
	optionsList.Parent = optionsFrame
	
	optionsFrame.Parent = dropdownFrame
	
	-- Create option buttons
	local function createOptions()
		for _, option in ipairs(dropdown.options) do
			local optionButton = Instance.new("TextButton")
			optionButton.Name = option
			optionButton.Size = UDim2.new(1, 0, 0, 30)
			optionButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			optionButton.BorderSizePixel = 0
			optionButton.Text = option
			optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			optionButton.TextSize = 14
			optionButton.Font = Enum.Font.Gotham
			optionButton.AutoButtonColor = false
			
			optionButton.MouseEnter:Connect(function()
				local tween = TweenService:Create(
					optionButton,
					TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
					{BackgroundColor3 = Color3.fromRGB(55, 55, 55)}
				)
				tween:Play()
			end)
			
			optionButton.MouseLeave:Connect(function()
				local tween = TweenService:Create(
					optionButton,
					TweenInfo.new(0.1, EASING_STYLE, EASING_DIRECTION),
					{BackgroundColor3 = Color3.fromRGB(45, 45, 45)}
				)
				tween:Play()
			end)
			
			optionButton.MouseButton1Click:Connect(function()
				dropdown.value = option
				selectedLabel.Text = option
				dropdown:Toggle()
				
				if options.callback then
					options.callback(option)
				end
			end)
			
			optionButton.Parent = optionsFrame
		end
		
		optionsFrame.Size = UDim2.new(1, 0, 0, #dropdown.options * 31)
	end
	
	createOptions()
	
	-- Toggle dropdown
	function dropdown:Toggle()
		dropdown.open = not dropdown.open
		
		if dropdown.open then
			local tween = TweenService:Create(
				dropdownFrame,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Size = UDim2.new(1, 0, 0, 35 + optionsFrame.Size.Y.Offset + 5)}
			)
			tween:Play()
			
			local arrowTween = TweenService:Create(
				arrow,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Rotation = 180}
			)
			arrowTween:Play()
		else
			local tween = TweenService:Create(
				dropdownFrame,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Size = UDim2.new(1, 0, 0, 35)}
			)
			tween:Play()
			
			local arrowTween = TweenService:Create(
				arrow,
				TweenInfo.new(ANIMATION_SPEED, EASING_STYLE, EASING_DIRECTION),
				{Rotation = 0}
			)
			arrowTween:Play()
		end
	end
	
	-- Main dropdown click
	dropdownFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dropdown:Toggle()
		end
	end)
	
	dropdownFrame.Parent = tab.content
	return dropdown
end

function GuiLibrary:AddColorPicker(tab, options)
	options = options or {}
	local colorPicker = {}
	colorPicker.value = options.default or Color3.fromRGB(255, 255, 255)
	
	local colorFrame = Instance.new("Frame")
	colorFrame.Name = options.name or "ColorPicker"
	colorFrame.Size = UDim2.new(1, 0, 0, 30)
	colorFrame.BackgroundTransparency = 1
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = options.text or "Color Picker"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = colorFrame
	
	local colorPreview = Instance.new("TextButton")
	colorPreview.Name = "ColorPreview"
	colorPreview.Size = UDim2.new(0, 40, 0, 20)
	colorPreview.Position = UDim2.new(1, -40, 0.5, -10)
	colorPreview.BackgroundColor3 = colorPicker.value
	colorPreview.BorderSizePixel = 0
	colorPreview.Text = ""
	colorPreview.AutoButtonColor = false
	
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = colorPreview
	
	local previewStroke = Instance.new("UIStroke")
	previewStroke.Color = Color3.fromRGB(80, 80, 80)
	previewStroke.Thickness = 1
	previewStroke.Parent = colorPreview
	
	-- Color picker modal
	local colorModal = Instance.new("Frame")
	colorModal.Name = "ColorModal"
	colorModal.Size = UDim2.new(0, 200, 0, 150)
	colorModal.Position = UDim2.new(0.5, -100, 0.5, -75)
	colorModal.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	colorModal.BorderSizePixel = 0
	colorModal.Visible = false
	colorModal.ZIndex = 110
	
	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 8)
	modalCorner.Parent = colorModal
	
	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(80, 80, 80)
	modalStroke.Thickness = 2
	modalStroke.Parent = colorModal
	
	-- Simple color spectrum (for demo)
	local spectrum = Instance.new("ImageButton")
	spectrum.Name = "Spectrum"
	spectrum.Size = UDim2.new(0, 180, 0, 100)
	spectrum.Position = UDim2.new(0, 10, 0, 10)
	spectrum.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	spectrum.BorderSizePixel = 0
	spectrum.Image = "rbxassetid://14204231522" -- Simple gradient image
	spectrum.AutoButtonColor = false
	
	local spectrumCorner = Instance.new("UICorner")
	spectrumCorner.CornerRadius = UDim.new(0, 4)
	spectrumCorner.Parent = spectrum
	
	-- Selected color display
	local selectedColor = Instance.new("Frame")
	selectedColor.Name = "SelectedColor"
	selectedColor.Size = UDim2.new(0, 30, 0, 30)
	selectedColor.Position = UDim2.new(0, 10, 1, -45)
	selectedColor.BackgroundColor3 = colorPicker.value
	selectedColor.BorderSizePixel = 0
	
	local selectedCorner = Instance.new("UICorner")
	selectedCorner.CornerRadius = UDim.new(0, 4)
	selectedCorner.Parent = selectedColor
	
	local selectedStroke = Instance.new("UIStroke")
	selectedStroke.Color = Color3.fromRGB(80, 80, 80)
	selectedStroke.Thickness = 1
	selectedStroke.Parent = selectedColor
	
	-- OK button
	local okButton = Instance.new("TextButton")
	okButton.Name = "OKButton"
	okButton.Size = UDim2.new(0, 60, 0, 25)
	okButton.Position = UDim2.new(1, -70, 1, -45)
	okButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	okButton.BorderSizePixel = 0
	okButton.Text = "OK"
	okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	okButton.TextSize = 14
	okButton.Font = Enum.Font.Gotham
	
	local okCorner = Instance.new("UICorner")
	okCorner.CornerRadius = UDim.new(0, 4)
	okCorner.Parent = okButton
	
	spectrum.Parent = colorModal
	selectedColor.Parent = colorModal
	okButton.Parent = colorModal
	colorPreview.Parent = colorFrame
	
	-- Show/hide modal
	colorPreview.MouseButton1Click:Connect(function()
		colorModal.Visible = true
		colorModal.Parent = self.screenGui
		
		-- Animate in
		colorModal.Size = UDim2.new(0, 0, 0, 0)
		colorModal.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		local openTween = TweenService:Create(
			colorModal,
			TweenInfo.new(0.2, EASING_STYLE, EASING_DIRECTION),
			{Size = UDim2.new(0, 200, 0, 150), Position = UDim2.new(0.5, -100, 0.5, -75)}
		)
		openTween:Play()
	end)
	
	-- Color selection
	spectrum.MouseButton1Down:Connect(function()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local mouse = UserInputService:GetMouseLocation()
			local spectrumAbsPos = spectrum.AbsolutePosition
			local spectrumAbsSize = spectrum.AbsoluteSize
			
			if mouse.X >= spectrumAbsPos.X and mouse.X <= spectrumAbsPos.X + spectrumAbsSize.X and
			   mouse.Y >= spectrumAbsPos.Y and mouse.Y <= spectrumAbsPos.Y + spectrumAbsSize.Y then
				
				local relX = (mouse.X - spectrumAbsPos.X) / spectrumAbsSize.X
				local relY = (mouse.Y - spectrumAbsPos.Y) / spectrumAbsSize.Y
				
				-- Simple color calculation (for demo)
				local r = relX
				local g = 1 - relY
				local b = (relX + (1 - relY)) / 2
				
				local newColor = Color3.new(r, g, b)
				selectedColor.BackgroundColor3 = newColor
			end
		end)
		
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				connection:Disconnect()
			end
		end)
	end)
	
	-- OK button
	okButton.MouseButton1Click:Connect(function()
		colorPicker.value = selectedColor.BackgroundColor3
		colorPreview.BackgroundColor3 = colorPicker.value
		
		-- Animate out
		local closeTween = TweenService:Create(
			colorModal,
			TweenInfo.new(0.2, EASING_STYLE, EASING_DIRECTION),
			{Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
		)
		closeTween:Play()
		
		closeTween.Completed:Connect(function()
			colorModal.Visible = false
		end)
		
		if options.callback then
			options.callback(colorPicker.value)
		end
	end)
	
	colorFrame.Parent = tab.content
	return colorPicker
end

-- Settings tab with built-in features
function GuiLibrary:CreateSettingsTab()
	local settingsTab = self:AddTab("Settings")
	
	-- Keybind selector
	local keybindDropdown = self:AddDropdown(settingsTab, {
		name = "KeybindSelector",
		text = "GUI Toggle Key",
		options = {"RightShift", "LeftShift", "RightControl", "LeftControl", "F1", "F2", "F3", "F4"},
		default = "RightShift",
		callback = function(selected)
			local keyCode = Enum.KeyCode[selected]
			if keyCode then
				self.toggleKey = keyCode
				self.notifier:Notify("Success", "Keybind updated to " .. selected, "success", 2)
			end
		end
	})
	
	-- Config system
	self:AddLabel(settingsTab, {text = "Config System", size = 16, color = Color3.fromRGB(100, 150, 255)})
	
	local configName = self:AddTextbox(settingsTab, {
		name = "ConfigName",
		placeholder = "Config name...",
		text = ""
	})
	
	local saveConfig = self:AddButton(settingsTab, {
		name = "SaveConfig",
		text = "Save Config",
		callback = function()
			local name = configName.Text
			if name == "" then
				self.notifier:Notify("Error", "Please enter a config name", "error", 3)
				return
			end
			
			self.configs[name] = self:ExportConfig()
			self.notifier:Notify("Success", "Config '" .. name .. "' saved!", "success", 3)
		end
	})
	
	local loadConfig = self:AddButton(settingsTab, {
		name = "LoadConfig",
		text = "Load Config",
		callback = function()
			local name = configName.Text
			if not self.configs[name] then
				self.notifier:Notify("Error", "Config '" .. name .. "' not found", "error", 3)
				return
			end
			
			self:ImportConfig(self.configs[name])
			self.notifier:Notify("Success", "Config '" .. name .. "' loaded!", "success", 3)
		end
	})
	
	-- Code Verifier
	self:AddLabel(settingsTab, {text = "Code Verifier", size = 16, color = Color3.fromRGB(100, 150, 255)})
	
	local codeInput = Instance.new("TextBox")
	codeInput.Size = UDim2.new(1, 0, 0, 100)
	codeInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	codeInput.BorderSizePixel = 0
	codeInput.Text = ""
	codeInput.PlaceholderText = "Enter Lua code to verify..."
	codeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	codeInput.TextSize = 12
	codeInput.Font = Enum.Font.Code
	codeInput.TextXAlignment = Enum.TextXAlignment.Left
	codeInput.TextYAlignment = Enum.TextYAlignment.Top
	codeInput.ClearTextOnFocus = false
	codeInput.MultiLine = true
	
	local codeCorner = Instance.new("UICorner")
	codeCorner.CornerRadius = UDim.new(0, 6)
	codeCorner.Parent = codeInput
	
	local codeStroke = Instance.new("UIStroke")
	codeStroke.Color = Color3.fromRGB(80, 80, 80)
	codeStroke.Thickness = 1
	codeStroke.Parent = codeInput
	
	codeInput.Parent = settingsTab.content
	
	local verifyCode = self:AddButton(settingsTab, {
		name = "VerifyCode",
		text = "Verify Code",
		callback = function()
			local code = codeInput.Text
			if code == "" then
				self.notifier:Notify("Error", "Please enter some code to verify", "error", 3)
				return
			end
			
			local success, message = CodeVerifier.VerifyLuaCode(code)
			if success then
				self.notifier:Notify("Success", message, "success", 5)
			else
				self.notifier:Notify("Error", message, "error", 5)
			end
		end
	})
	
	-- Unload button
	self:AddLabel(settingsTab, {text = "Danger Zone", size = 16, color = Color3.fromRGB(255, 100, 100)})
	
	local unloadButton = self:AddButton(settingsTab, {
		name = "UnloadGUI",
		text = "Unload GUI",
		callback = function()
			self:Unload()
			self.notifier:Notify("Info", "GUI unloaded successfully", "warning", 3)
		end
	})
end

function GuiLibrary:ExportConfig()
	local config = {
		version = self.version,
		toggleKey = tostring(self.toggleKey),
		tabs = {}
	}
	
	for _, tab in ipairs(self.tabs) do
		local tabConfig = {
			name = tab.name,
			elements = {}
		}
		
		-- This would need to be expanded to save the state of each element
		-- For now, it's a basic structure
		
		table.insert(config.tabs, tabConfig)
	end
	
	return config
end

function GuiLibrary:ImportConfig(config)
	if config.version ~= self.version then
		self.notifier:Notify("Warning", "Config version mismatch", "warning", 3)
	end
	
	-- Implementation for loading config would go here
	-- This would restore the state of all GUI elements
end

function GuiLibrary:Unload()
	if self.screenGui then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

-- Example usage function
function GuiLibrary:Example()
	local mainTab = self:AddTab("Main")
	
	-- Add elements to main tab
	self:AddButton(mainTab, {
		name = "TestButton",
		text = "Click Me!",
		callback = function()
			self.notifier:Notify("Button Clicked", "You clicked the test button!", "success", 3)
		end
	})
	
	self:AddToggle(mainTab, {
		name = "TestToggle",
		text = "Enable Feature",
		default = false,
		callback = function(value)
			if value then
				self.notifier:Notify("Toggle On", "Feature enabled", "success", 2)
			else
				self.notifier:Notify("Toggle Off", "Feature disabled", "warning", 2)
			end
		end
	})
	
	self:AddLabel(mainTab, {
		text = "Welcome to the GUI Library!",
		color = Color3.fromRGB(100, 200, 255),
		size = 16
	})
	
	self:AddTextbox(mainTab, {
		name = "TestTextbox",
		placeholder = "Enter your name...",
		callback = function(text)
			self.notifier:Notify("Text Entered", "Hello, " .. text .. "!", "success", 3)
		end
	})
	
	self:AddDropdown(mainTab, {
		name = "TestDropdown",
		text = "Select Option",
		options = {"Option 1", "Option 2", "Option 3", "Option 4"},
		default = "Option 1",
		callback = function(selected)
			self.notifier:Notify("Dropdown Selected", "You selected: " .. selected, "success", 2)
		end
	})
	
	self:AddColorPicker(mainTab, {
		name = "TestColorPicker",
		text = "Select Color",
		default = Color3.fromRGB(255, 0, 0),
		callback = function(color)
			self.notifier:Notify("Color Selected", "Color changed to RGB(" .. 
				math.floor(color.R * 255) .. ", " .. 
				math.floor(color.G * 255) .. ", " .. 
				math.floor(color.B * 255) .. ")", "success", 3)
		end
	})
	
	-- Create settings tab with built-in features
	self:CreateSettingsTab()
end

return GuiLibrary
