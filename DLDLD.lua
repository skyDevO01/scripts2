-- UnknowHub Emotes GUI Library
local UnknowHubGUI = {}
UnknowHubGUI.__index = UnknowHubGUI

-- Configuration
local folder = "@unknowHubEmotes"
local emotesFolder = folder .. "/emotes"

-- Utility functions (your existing code)
local function normalizePath(p)
    p = p:gsub("\\", "/")
    p = p:gsub("/+", "/")
    if #p > 1 then
        p = p:gsub("/$", "")
    end
    return p
end

local function ensureFolder(path)
    path = normalizePath(path)

    if type(isfolder) == "function" then
        if not isfolder(path) then
            local ok, err = pcall(makefolder, path)
            if ok then
                print("Created folder:", path)
                return true
            else
                warn("Failed to create folder (" .. path .. "): " .. tostring(err))
                return false
            end
        else
            return false
        end
    end

    local ok, err = pcall(makefolder, path)
    if ok then
        print("Created folder (fallback):", path)
        return true
    else
        warn("makefolder failed (fallback) for '" .. path .. "': " .. tostring(err))
        return false
    end
end

-- Initialize folders
ensureFolder(folder)
ensureFolder(emotesFolder)

if isfolder(emotesFolder) and not isfile(emotesFolder .. "/Emote1.txt") then
    writefile(emotesFolder .. "/Emote1.txt", "1234567890")
    print("Created Emote1.txt")
end

-- Tween service for animations
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Animation presets
UnknowHubGUI.Animations = {
    ButtonHover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    ButtonClick = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabSwitch = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    PanelSlide = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

-- Define Color3 constants to replace Color3.white, Color3.new, etc.
local COLORS = {
    WHITE = Color3.fromRGB(255, 255, 255),
    BLACK = Color3.fromRGB(0, 0, 0),
    RED = Color3.fromRGB(255, 60, 60),
    GREEN = Color3.fromRGB(70, 150, 70),
    DARK_GREEN = Color3.fromRGB(50, 120, 50),
    BRIGHT_GREEN = Color3.fromRGB(90, 180, 90),
    DARK_BLUE = Color3.fromRGB(20, 20, 30),
    MEDIUM_BLUE = Color3.fromRGB(30, 30, 45),
    LIGHT_BLUE = Color3.fromRGB(50, 50, 80),
    HOVER_BLUE = Color3.fromRGB(60, 60, 100),
    SELECTED_BLUE = Color3.fromRGB(70, 70, 120),
    GRAY = Color3.fromRGB(150, 150, 150),
    LIGHT_GRAY = Color3.fromRGB(200, 200, 200),
    DARK_GRAY = Color3.fromRGB(40, 40, 60)
}

function UnknowHubGUI.new()
    local self = setmetatable({}, UnknowHubGUI)
    
    self.gui = nil
    self.currentTab = "Emotes"
    self.emotes = {}
    self.settings = {}
    self.autoRefreshEnabled = false
    self.refreshConnection = nil
    self.lastRefreshTime = 0
    self.refreshCooldown = 2 -- seconds between auto-refreshes
    
    return self
end

function UnknowHubGUI:CreateMainGUI()
    -- Create main ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "UnknowHubEmotesGUI"
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.ResetOnSpawn = false

    -- Main container with glass morphism effect
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600) -- Increased size for better fit
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.DARK_BLUE
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    
    -- Apply glass effect
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = mainFrame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(100, 100, 150)
    uiStroke.Thickness = 1
    uiStroke.Transparency = 0.7
    uiStroke.Parent = mainFrame
    
    local backgroundBlur = Instance.new("BlurEffect")
    backgroundBlur.Size = 8
    backgroundBlur.Parent = self.gui

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = COLORS.MEDIUM_BLUE
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "UnknowHub Emotes"
    title.TextColor3 = COLORS.WHITE
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
    closeButton.BackgroundColor3 = COLORS.RED
    closeButton.Text = "X"
    closeButton.TextColor3 = COLORS.WHITE
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton

    -- Tab buttons container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -30, 0, 40)
    tabContainer.Position = UDim2.new(0, 15, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    -- Tab buttons
    local emotesTab = self:CreateTabButton("Emotes", true)
    emotesTab.Position = UDim2.new(0, 0, 0, 0)
    emotesTab.Parent = tabContainer
    
    local settingsTab = self:CreateTabButton("Settings", false)
    settingsTab.Position = UDim2.new(0, 120, 0, 0)
    settingsTab.Parent = tabContainer

    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -30, 1, -120)
    contentFrame.Position = UDim2.new(0, 15, 0, 110)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = mainFrame

    -- Create tab contents
    self.emotesContent = self:CreateEmotesTab()
    self.emotesContent.Parent = contentFrame
    
    self.settingsContent = self:CreateSettingsTab()
    self.settingsContent.Position = UDim2.new(1, 0, 0, 0)
    self.settingsContent.Parent = contentFrame

    -- Make draggable
    self:MakeDraggable(header, mainFrame)

    -- Connect events
    self:ConnectEvents(emotesTab, settingsTab, closeButton)

    mainFrame.Parent = self.gui
    return self.gui
end

function UnknowHubGUI:CreateTabButton(text, isSelected)
    local button = Instance.new("TextButton")
    button.Name = text .. "Tab"
    button.Size = UDim2.new(0, 100, 1, 0)
    button.BackgroundColor3 = isSelected and COLORS.SELECTED_BLUE or COLORS.LIGHT_BLUE
    button.Text = text
    button.TextColor3 = COLORS.WHITE
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Hover animation
    button.MouseEnter:Connect(function()
        if not isSelected then
            local tween = TweenService:Create(button, self.Animations.ButtonHover, {
                BackgroundColor3 = COLORS.HOVER_BLUE
            })
            tween:Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not isSelected then
            local tween = TweenService:Create(button, self.Animations.ButtonHover, {
                BackgroundColor3 = COLORS.LIGHT_BLUE
            })
            tween:Play()
        end
    end)
    
    return button
end

function UnknowHubGUI:CreateEmotesTab()
    local frame = Instance.new("Frame")
    frame.Name = "EmotesTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    
    -- Top controls container
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsFrame"
    controlsFrame.Size = UDim2.new(1, 0, 0, 80)
    controlsFrame.Position = UDim2.new(0, 0, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = frame
    
    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, 0, 0, 35)
    searchBox.Position = UDim2.new(0, 0, 0, 0)
    searchBox.BackgroundColor3 = COLORS.DARK_GRAY
    searchBox.PlaceholderText = "Search emotes..."
    searchBox.PlaceholderColor3 = COLORS.GRAY
    searchBox.TextColor3 = COLORS.WHITE
    searchBox.TextSize = 14
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = controlsFrame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchBox
    
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 10)
    searchPadding.Parent = searchBox
    
    -- Refresh button container
    local refreshContainer = Instance.new("Frame")
    refreshContainer.Name = "RefreshContainer"
    refreshContainer.Size = UDim2.new(1, 0, 0, 35)
    refreshContainer.Position = UDim2.new(0, 0, 0, 45)
    refreshContainer.BackgroundTransparency = 1
    refreshContainer.Parent = controlsFrame
    
    -- Manual refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 120, 1, 0)
    refreshButton.Position = UDim2.new(0, 0, 0, 0)
    refreshButton.BackgroundColor3 = COLORS.LIGHT_BLUE
    refreshButton.Text = "🔄 Refresh"
    refreshButton.TextColor3 = COLORS.WHITE
    refreshButton.TextSize = 14
    refreshButton.Font = Enum.Font.Gotham
    refreshButton.AutoButtonColor = false
    refreshButton.Parent = refreshContainer
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    -- Auto-refresh toggle
    local autoRefreshFrame = Instance.new("Frame")
    autoRefreshFrame.Name = "AutoRefreshFrame"
    autoRefreshFrame.Size = UDim2.new(0, 180, 1, 0)
    autoRefreshFrame.Position = UDim2.new(1, -180, 0, 0)
    autoRefreshFrame.BackgroundTransparency = 1
    autoRefreshFrame.Parent = refreshContainer
    
    local autoRefreshLabel = Instance.new("TextLabel")
    autoRefreshLabel.Name = "AutoRefreshLabel"
    autoRefreshLabel.Size = UDim2.new(0, 120, 1, 0)
    autoRefreshLabel.Position = UDim2.new(0, 0, 0, 0)
    autoRefreshLabel.BackgroundTransparency = 1
    autoRefreshLabel.Text = "Auto Refresh:"
    autoRefreshLabel.TextColor3 = COLORS.WHITE
    autoRefreshLabel.TextSize = 14
    autoRefreshLabel.Font = Enum.Font.Gotham
    autoRefreshLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoRefreshLabel.Parent = autoRefreshFrame
    
    local autoRefreshToggle = Instance.new("TextButton")
    autoRefreshToggle.Name = "AutoRefreshToggle"
    autoRefreshToggle.Size = UDim2.new(0, 40, 0, 20)
    autoRefreshToggle.Position = UDim2.new(1, -40, 0.5, -10)
    autoRefreshToggle.AnchorPoint = Vector2.new(0.5, 0.5)
    autoRefreshToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    autoRefreshToggle.Text = ""
    autoRefreshToggle.AutoButtonColor = false
    autoRefreshToggle.Parent = autoRefreshFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = autoRefreshToggle
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "Knob"
    toggleKnob.Size = UDim2.new(0, 16, 0, 16)
    toggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
    toggleKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleKnob.BackgroundColor3 = COLORS.WHITE
    toggleKnob.Parent = autoRefreshToggle
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    -- Emotes scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "EmotesScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, -85) -- Adjusted for controls
    scrollFrame.Position = UDim2.new(0, 0, 0, 85)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = scrollFrame
    
    -- Setup refresh functionality
    self:SetupRefreshFunctionality(refreshButton, autoRefreshToggle, toggleKnob, scrollFrame)
    
    -- Load emotes initially
    self:LoadEmotes(scrollFrame)
    
    -- Setup search functionality
    self:SetupSearchFunctionality(searchBox, scrollFrame)
    
    return frame
end

function UnknowHubGUI:SetupRefreshFunctionality(refreshButton, autoToggle, toggleKnob, scrollFrame)
    -- Manual refresh button animations
    refreshButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(refreshButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.HOVER_BLUE
        })
        tween:Play()
    end)
    
    refreshButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(refreshButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.LIGHT_BLUE
        })
        tween:Play()
    end)
    
    refreshButton.MouseButton1Click:Connect(function()
        -- Click animation
        local tween = TweenService:Create(refreshButton, self.Animations.ButtonClick, {
            BackgroundColor3 = COLORS.SELECTED_BLUE
        })
        tween:Play()
        
        -- Refresh emotes
        self:LoadEmotes(scrollFrame)
        
        -- Reset button color after animation
        delay(0.1, function()
            if refreshButton then
                local tween2 = TweenService:Create(refreshButton, self.Animations.ButtonHover, {
                    BackgroundColor3 = COLORS.LIGHT_BLUE
                })
                tween2:Play()
            end
        end)
    end)
    
    -- Auto-refresh toggle functionality
    autoToggle.MouseButton1Click:Connect(function()
        self.autoRefreshEnabled = not self.autoRefreshEnabled
        
        local targetPosition = self.autoRefreshEnabled and UDim2.new(1, -2, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = self.autoRefreshEnabled and COLORS.GREEN or Color3.fromRGB(80, 80, 80)
        
        local tween1 = TweenService:Create(toggleKnob, self.Animations.ButtonHover, {
            Position = targetPosition
        })
        
        local tween2 = TweenService:Create(autoToggle, self.Animations.ButtonHover, {
            BackgroundColor3 = targetColor
        })
        
        tween1:Play()
        tween2:Play()
        
        -- Start or stop auto-refresh
        self:ToggleAutoRefresh(scrollFrame)
    end)
end

function UnknowHubGUI:ToggleAutoRefresh(scrollFrame)
    if self.autoRefreshEnabled then
        -- Start auto-refresh
        self:CreateNotification("Auto-refresh enabled")
        
        if self.refreshConnection then
            self.refreshConnection:Disconnect()
        end
        
        self.refreshConnection = RunService.Heartbeat:Connect(function()
            local currentTime = os.time()
            if currentTime - self.lastRefreshTime >= self.refreshCooldown then
                self.lastRefreshTime = currentTime
                self:LoadEmotes(scrollFrame)
            end
        end)
    else
        -- Stop auto-refresh
        if self.refreshConnection then
            self.refreshConnection:Disconnect()
            self.refreshConnection = nil
        end
        self:CreateNotification("Auto-refresh disabled")
    end
end

function UnknowHubGUI:SetupSearchFunctionality(searchBox, scrollFrame)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:FilterEmotes(searchBox.Text, scrollFrame)
    end)
end

function UnknowHubGUI:FilterEmotes(searchText, scrollFrame)
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name:match("Emote_") then
            local emoteName = child:FindFirstChild("EmoteName")
            if emoteName then
                local name = emoteName.Text:lower()
                local search = searchText:lower()
                
                if search == "" or name:find(search, 1, true) then
                    child.Visible = true
                else
                    child.Visible = false
                end
            end
        end
    end
end

function UnknowHubGUI:LoadEmotes(scrollFrame)
    if not isfolder(emotesFolder) then
        self:CreateNotification("Emotes folder not found")
        return
    end
    
    -- Clear existing emotes
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    self.emotes = {}
    
    -- Read all emote files
    local success, files = pcall(function()
        return listfiles(emotesFolder)
    end)
    
    if not success then
        warn("Failed to read emotes folder: " .. tostring(files))
        self:CreateNotification("Failed to load emotes")
        return
    end
    
    for _, filePath in ipairs(files) do
        local fileName = filePath:match("([^/]+)%.txt$")
        if fileName then
            local success, content = pcall(readfile, filePath)
            if success then
                table.insert(self.emotes, {
                    name = fileName,
                    id = content:gsub("%s+", ""), -- Remove whitespace
                    filePath = filePath
                })
            end
        end
    end
    
    -- Create emote buttons
    for i, emote in ipairs(self.emotes) do
        local emoteButton = Instance.new("TextButton")
        emoteButton.Name = "Emote_" .. emote.name
        emoteButton.Size = UDim2.new(1, -5, 0, 60) -- Adjusted for better fit
        emoteButton.BackgroundColor3 = COLORS.LIGHT_BLUE
        emoteButton.Text = ""
        emoteButton.AutoButtonColor = false
        emoteButton.LayoutOrder = i
        emoteButton.Parent = scrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = emoteButton
        
        -- Emote info container
        local infoContainer = Instance.new("Frame")
        infoContainer.Name = "InfoContainer"
        infoContainer.Size = UDim2.new(0.7, 0, 1, 0)
        infoContainer.Position = UDim2.new(0, 0, 0, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.Parent = emoteButton
        
        local emoteName = Instance.new("TextLabel")
        emoteName.Name = "EmoteName"
        emoteName.Size = UDim2.new(1, -10, 0, 25)
        emoteName.Position = UDim2.new(0, 10, 0, 5)
        emoteName.BackgroundTransparency = 1
        emoteName.Text = emote.name
        emoteName.TextColor3 = COLORS.WHITE
        emoteName.TextSize = 14
        emoteName.Font = Enum.Font.GothamBold
        emoteName.TextXAlignment = Enum.TextXAlignment.Left
        emoteName.TextTruncate = Enum.TextTruncate.AtEnd
        emoteName.Parent = infoContainer
        
        local emoteId = Instance.new("TextLabel")
        emoteId.Name = "EmoteID"
        emoteId.Size = UDim2.new(1, -10, 0, 20)
        emoteId.Position = UDim2.new(0, 10, 0, 30)
        emoteId.BackgroundTransparency = 1
        emoteId.Text = "ID: " .. (emote.id:len() > 20 and emote.id:sub(1, 20) .. "..." or emote.id)
        emoteId.TextColor3 = COLORS.LIGHT_GRAY
        emoteId.TextSize = 12
        emoteId.Font = Enum.Font.Gotham
        emoteId.TextXAlignment = Enum.TextXAlignment.Left
        emoteId.TextTruncate = Enum.TextTruncate.AtEnd
        emoteId.Parent = infoContainer
        
        local loadButton = Instance.new("TextButton")
        loadButton.Name = "LoadButton"
        loadButton.Size = UDim2.new(0, 80, 0, 35) -- Better size
        loadButton.Position = UDim2.new(1, -85, 0.5, -17.5)
        loadButton.AnchorPoint = Vector2.new(0.5, 0.5)
        loadButton.BackgroundColor3 = COLORS.GREEN
        loadButton.Text = "LOAD"
        loadButton.TextColor3 = COLORS.WHITE
        loadButton.TextSize = 12
        loadButton.Font = Enum.Font.GothamBold
        loadButton.AutoButtonColor = false
        loadButton.Parent = emoteButton
        
        local loadCorner = Instance.new("UICorner")
        loadCorner.CornerRadius = UDim.new(0, 6)
        loadCorner.Parent = loadButton
        
        -- Animations
        self:SetupButtonAnimations(emoteButton, loadButton, emote)
    end
    
    -- Update notification if auto-refresh is enabled
    if self.autoRefreshEnabled then
        self:CreateNotification("Emotes refreshed (" .. #self.emotes .. " found)")
    end
end

function UnknowHubGUI:SetupButtonAnimations(emoteButton, loadButton, emote)
    -- Main button hover
    emoteButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(emoteButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.HOVER_BLUE
        })
        tween:Play()
    end)
    
    emoteButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(emoteButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.LIGHT_BLUE
        })
        tween:Play()
    end)
    
    -- Load button animations
    loadButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(loadButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.BRIGHT_GREEN,
            Size = UDim2.new(0, 85, 0, 38)
        })
        tween:Play()
    end)
    
    loadButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(loadButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.GREEN,
            Size = UDim2.new(0, 80, 0, 35)
        })
        tween:Play()
    end)
    
    loadButton.MouseButton1Down:Connect(function()
        local tween = TweenService:Create(loadButton, self.Animations.ButtonClick, {
            BackgroundColor3 = COLORS.DARK_GREEN,
            Size = UDim2.new(0, 75, 0, 32)
        })
        tween:Play()
    end)
    
    loadButton.MouseButton1Up:Connect(function()
        local tween = TweenService:Create(loadButton, self.Animations.ButtonHover, {
            BackgroundColor3 = COLORS.BRIGHT_GREEN,
            Size = UDim2.new(0, 85, 0, 38)
        })
        tween:Play()
        
        -- Load emote functionality
        self:LoadEmote(emote)
    end)
end

function UnknowHubGUI:LoadEmote(emote)
    print("Loading emote: " .. emote.name .. " (ID: " .. emote.id .. ")")
    
    -- Here you would integrate with your emote system
    -- For example:
    -- game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(emote.id):Play()
    
    -- Show loading feedback
    local notification = self:CreateNotification("Loaded: " .. emote.name)
    notification.Parent = self.gui
    
    -- Auto-remove notification after 2 seconds
    delay(2, function()
        if notification and notification.Parent then
            notification:Destroy()
        end
    end)
end

function UnknowHubGUI:CreateSettingsTab()
    local frame = Instance.new("Frame")
    frame.Name = "SettingsTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "SettingsScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = scrollFrame
    
    local settings = {
        "Auto-load on join",
        "Show emote notifications", 
        "Enable sound effects",
        "Dark mode",
        "Compact view",
        "Confirm before loading",
        "Show emote IDs",
        "Auto-close after load"
    }
    
    for i, setting in ipairs(settings) do
        local settingFrame = Instance.new("Frame")
        settingFrame.Name = setting .. "Setting"
        settingFrame.Size = UDim2.new(1, 0, 0, 50)
        settingFrame.BackgroundColor3 = COLORS.LIGHT_BLUE
        settingFrame.BackgroundTransparency = 0
        settingFrame.LayoutOrder = i
        settingFrame.Parent = scrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = settingFrame
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = setting
        label.TextColor3 = COLORS.WHITE
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = settingFrame
        
        local toggle = Instance.new("TextButton")
        toggle.Name = "Toggle"
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(1, -50, 0.5, -10)
        toggle.AnchorPoint = Vector2.new(0.5, 0.5)
        toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        toggle.Text = ""
        toggle.AutoButtonColor = false
        toggle.Parent = settingFrame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggle
        
        local toggleKnob = Instance.new("Frame")
        toggleKnob.Name = "Knob"
        toggleKnob.Size = UDim2.new(0, 16, 0, 16)
        toggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
        toggleKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        toggleKnob.BackgroundColor3 = COLORS.WHITE
        toggleKnob.Parent = toggle
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = toggleKnob
        
        -- Toggle functionality
        self:SetupToggleAnimation(toggle, toggleKnob, setting)
    end
    
    return frame
end

function UnknowHubGUI:SetupToggleAnimation(toggle, knob, settingName)
    local isOn = false
    
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        local targetPosition = isOn and UDim2.new(1, -2, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = isOn and COLORS.GREEN or Color3.fromRGB(80, 80, 80)
        
        local tween1 = TweenService:Create(knob, self.Animations.ButtonHover, {
            Position = targetPosition
        })
        
        local tween2 = TweenService:Create(toggle, self.Animations.ButtonHover, {
            BackgroundColor3 = targetColor
        })
        
        tween1:Play()
        tween2:Play()
        
        -- Save setting
        self.settings[settingName] = isOn
        print("Setting '" .. settingName .. "' set to: " .. tostring(isOn))
        
        -- Special handling for auto-refresh
        if settingName == "Auto-load on join" then
            self:CreateNotification(isOn and "Auto-load enabled" or "Auto-load disabled")
        end
    end)
end

function UnknowHubGUI:CreateNotification(message)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 1, -80)
    notification.AnchorPoint = Vector2.new(0.5, 0.5)
    notification.BackgroundColor3 = COLORS.DARK_GRAY
    notification.BackgroundTransparency = 0.1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 150, 100)
    stroke.Thickness = 2
    stroke.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Name = "Message"
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = COLORS.WHITE
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextWrapped = true
    label.Parent = notification
    
    -- Animate entrance
    notification.Position = UDim2.new(0.5, -150, 1, 100)
    local tween = TweenService:Create(notification, self.Animations.PanelSlide, {
        Position = UDim2.new(0.5, -150, 1, -80)
    })
    tween:Play()
    
    return notification
end

function UnknowHubGUI:MakeDraggable(dragHandle, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function UnknowHubGUI:ConnectEvents(emotesTab, settingsTab, closeButton)
    -- Tab switching
    emotesTab.MouseButton1Click:Connect(function()
        self:SwitchTab("Emotes", emotesTab, settingsTab)
    end)
    
    settingsTab.MouseButton1Click:Connect(function()
        self:SwitchTab("Settings", emotesTab, settingsTab)
    end)
    
    -- Close button
    closeButton.MouseButton1Click:Connect(function()
        self:CloseGUI()
    end)
    
    -- Escape key to close
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape and not gameProcessed then
            self:CloseGUI()
        end
    end)
end

function UnknowHubGUI:SwitchTab(tabName, emotesTab, settingsTab)
    if self.currentTab == tabName then return end
    
    self.currentTab = tabName
    
    -- Update tab buttons
    emotesTab.BackgroundColor3 = tabName == "Emotes" and COLORS.SELECTED_BLUE or COLORS.LIGHT_BLUE
    settingsTab.BackgroundColor3 = tabName == "Settings" and COLORS.SELECTED_BLUE or COLORS.LIGHT_BLUE
    
    -- Slide animation
    if tabName == "Emotes" then
        local tween1 = TweenService:Create(self.emotesContent, self.Animations.PanelSlide, {
            Position = UDim2.new(0, 0, 0, 0)
        })
        local tween2 = TweenService:Create(self.settingsContent, self.Animations.PanelSlide, {
            Position = UDim2.new(1, 0, 0, 0)
        })
        tween1:Play()
        tween2:Play()
    else
        local tween1 = TweenService:Create(self.emotesContent, self.Animations.PanelSlide, {
            Position = UDim2.new(-1, 0, 0, 0)
        })
        local tween2 = TweenService:Create(self.settingsContent, self.Animations.PanelSlide, {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tween1:Play()
        tween2:Play()
    end
end

function UnknowHubGUI:CloseGUI()
    -- Stop auto-refresh if running
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
        self.refreshConnection = nil
    end
    
    if self.gui then
        -- Fade out animation
        local tween = TweenService:Create(self.gui.MainFrame, self.Animations.Fade, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        
        tween.Completed:Wait()
        self.gui:Destroy()
        self.gui = nil
    end
end

function UnknowHubGUI:ToggleGUI()
    if self.gui and self.gui.Parent then
        self:CloseGUI()
    else
        local gui = self:CreateMainGUI()
        gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        
        -- Entrance animation
        self.gui.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        self.gui.MainFrame.BackgroundTransparency = 1
        
        local tween = TweenService:Create(self.gui.MainFrame, self.Animations.PanelSlide, {
            Size = UDim2.new(0, 500, 0, 600),
            BackgroundTransparency = 0.1
        })
        tween:Play()
    end
end

-- Export the library
return UnknowHubGUI
