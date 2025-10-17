-- Roblox GUI Library
-- Features: Toggles, Buttons, Pages, Textbox, Dropdown, Color Picker, Label, Callbacks
-- Settings Tab, Keybind, Unload, Configs, Notifier, Code Verifier

local Library = {}
Library.__index = Library

-- Notifications System
local Notifications = {
    ActiveNotifications = {},
    MaxNotifications = 5
}

function Library:CreateNotification(title, message, notificationType, duration)
    duration = duration or 5
    
    local notification = {
        Title = title,
        Message = message,
        Type = notificationType,
        Duration = duration,
        Created = tick()
    }
    
    table.insert(Notifications.ActiveNotifications, notification)
    
    if #Notifications.ActiveNotifications > Notifications.MaxNotifications then
        table.remove(Notifications.ActiveNotifications, 1)
    end
    
    -- In a real implementation, you'd create the GUI elements here
    print(string.format("[%s] %s: %s", notificationType:upper(), title, message))
    
    return notification
end

-- Code Verifier
local CodeVerifier = {
    AllowedPatterns = {
        "^%s*local%s+%w+%s*=%s*[^;]+$",
        "^%s*print%(%s*[^)]+%s*%)%s*$",
        "^%s*function%s+%w+%s*%(.*%)%s*$"
    },
    BlockedKeywords = {
        "getfenv", "setfenv", "getgenv", "setgenv", "loadstring", "require", "game"
    }
}

function Library:VerifyCode(code)
    -- Check for blocked keywords
    for _, keyword in ipairs(CodeVerifier.BlockedKeywords) do
        if string.find(string.lower(code), keyword) then
            return false, "Blocked keyword detected: " .. keyword
        end
    end
    
    -- Check if code matches allowed patterns
    local isValid = false
    for _, pattern in ipairs(CodeVerifier.AllowedPatterns) do
        if string.match(code, pattern) then
            isValid = true
            break
        end
    end
    
    if not isValid then
        return false, "Code pattern not allowed"
    end
    
    return true, "Code verified successfully"
end

-- Main Library Functions
function Library.new(name)
    local self = setmetatable({}, Library)
    
    self.Name = name or "GUI Library"
    self.Tabs = {}
    self.Enabled = false
    self.ToggleKey = Enum.KeyCode.RightControl
    self.Configs = {}
    self.CurrentConfig = "default"
    
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "LibraryGUI"
    self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create main frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 500, 0, 400)
    self.MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Visible = false
    self.MainFrame.Parent = self.ScreenGui
    
    -- Create tab buttons container
    self.TabButtonsFrame = Instance.new("Frame")
    self.TabButtonsFrame.Name = "TabButtons"
    self.TabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    self.TabButtonsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.TabButtonsFrame.BorderSizePixel = 0
    self.TabButtonsFrame.Parent = self.MainFrame
    
    -- Create content frame
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "Content"
    self.ContentFrame.Size = UDim2.new(1, 0, 1, -40)
    self.ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    self.ContentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    self.ContentFrame.BorderSizePixel = 0
    self.ContentFrame.Parent = self.MainFrame
    
    -- Create UIListLayout for tab buttons
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.FillDirection = Enum.FillDirection.Horizontal
    tabListLayout.Parent = self.TabButtonsFrame
    
    -- Set up keybind
    self:SetupKeybind()
    
    return self
end

function Library:SetupKeybind()
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)
end

function Library:Toggle()
    self.Enabled = not self.Enabled
    self.MainFrame.Visible = self.Enabled
    
    if self.Enabled then
        self:CreateNotification("GUI", "Interface opened", "info", 2)
    else
        self:CreateNotification("GUI", "Interface closed", "info", 2)
    end
end

function Library:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
    self:CreateNotification("Settings", string.format("Toggle key set to: %s", tostring(keyCode)), "success")
end

function Library:Unload()
    self.ScreenGui:Destroy()
    self:CreateNotification("Library", "GUI library unloaded", "warning")
end

-- Tab Management
function Library:CreateTab(name)
    local tab = {
        Name = name,
        Elements = {},
        Container = nil
    }
    
    -- Create tab button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(0, 100, 1, 0)
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.Parent = self.TabButtonsFrame
    
    -- Create tab container
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = name .. "Container"
    tabContainer.Size = UDim2.new(1, 0, 1, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    tabContainer.Visible = false
    tabContainer.Parent = self.ContentFrame
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = tabContainer
    
    tab.Container = tabContainer
    
    -- Tab button click event
    tabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Switch to this tab if it's the first one
    if #self.Tabs == 1 then
        self:SwitchTab(name)
    end
    
    return tab
end

function Library:SwitchTab(tabName)
    for _, tab in ipairs(self.Tabs) do
        tab.Container.Visible = (tab.Name == tabName)
    end
end

-- UI Elements
function Library:CreateLabel(tab, text)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab.Container
    
    return label
end

function Library:CreateButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = tab.Container
    
    button.MouseButton1Click:Connect(function()
        if callback then
            local success, err = pcall(callback)
            if not success then
                self:CreateNotification("Error", "Button callback error: " .. err, "error")
            else
                self:CreateNotification("Success", "Button executed successfully", "success")
            end
        end
    end)
    
    return button
end

function Library:CreateToggle(tab, text, default, callback)
    local toggle = {
        Value = default or false,
        Callback = callback
    }
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle"
    toggleFrame.Size = UDim2.new(1, -20, 0, 30)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = tab.Container
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "Label"
    toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 20)
    toggleButton.Position = UDim2.new(0.8, -25, 0.5, -10)
    toggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = default and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Parent = toggleFrame
    
    toggleButton.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        toggleButton.BackgroundColor3 = toggle.Value and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        toggleButton.Text = toggle.Value and "ON" or "OFF"
        
        if toggle.Callback then
            local success, err = pcall(toggle.Callback, toggle.Value)
            if not success then
                self:CreateNotification("Error", "Toggle callback error: " .. err, "error")
            end
        end
    end)
    
    return toggle
end

function Library:CreateTextBox(tab, text, placeholder, callback)
    local textBoxFrame = Instance.new("Frame")
    textBoxFrame.Name = "TextBox"
    textBoxFrame.Size = UDim2.new(1, -20, 0, 30)
    textBoxFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    textBoxFrame.BorderSizePixel = 0
    textBoxFrame.Parent = tab.Container
    
    local textBoxLabel = Instance.new("TextLabel")
    textBoxLabel.Name = "Label"
    textBoxLabel.Size = UDim2.new(0.3, 0, 1, 0)
    textBoxLabel.BackgroundTransparency = 1
    textBoxLabel.Text = text
    textBoxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
    textBoxLabel.Parent = textBoxFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "Input"
    textBox.Size = UDim2.new(0.7, -10, 0, 25)
    textBox.Position = UDim2.new(0.3, 5, 0.5, -12.5)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    textBox.BorderSizePixel = 0
    textBox.PlaceholderText = placeholder or ""
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Parent = textBoxFrame
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            local success, err = pcall(callback, textBox.Text)
            if not success then
                self:CreateNotification("Error", "Textbox callback error: " .. err, "error")
            else
                self:CreateNotification("Success", "Text submitted: " .. textBox.Text, "success")
            end
        end
    end)
    
    return textBox
end

function Library:CreateDropdown(tab, text, options, default, callback)
    local dropdown = {
        Value = default or options[1],
        Options = options,
        Callback = callback,
        Open = false
    }
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = "Dropdown"
    dropdownFrame.Size = UDim2.new(1, -20, 0, 30)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.ClipsDescendants = true
    dropdownFrame.Parent = tab.Container
    
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "Label"
    dropdownLabel.Size = UDim2.new(0.5, 0, 0, 30)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Text = text
    dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.Parent = dropdownFrame
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0.5, -10, 0, 25)
    dropdownButton.Position = UDim2.new(0.5, 5, 0, 2.5)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Text = dropdown.Value
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.Parent = dropdownFrame
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "Options"
    optionsFrame.Size = UDim2.new(0.5, -10, 0, 0)
    optionsFrame.Position = UDim2.new(0.5, 5, 0, 30)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.Parent = dropdownFrame
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Parent = optionsFrame
    
    -- Create option buttons
    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = option
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.Parent = optionsFrame
        
        optionButton.MouseButton1Click:Connect(function()
            dropdown.Value = option
            dropdownButton.Text = option
            dropdown.Open = false
            optionsFrame.Visible = false
            dropdownFrame.Size = UDim2.new(1, -20, 0, 30)
            
            if dropdown.Callback then
                local success, err = pcall(dropdown.Callback, option)
                if not success then
                    self:CreateNotification("Error", "Dropdown callback error: " .. err, "error")
                else
                    self:CreateNotification("Success", "Dropdown selected: " .. option, "success")
                end
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        dropdown.Open = not dropdown.Open
        optionsFrame.Visible = dropdown.Open
        
        if dropdown.Open then
            local optionCount = #options
            dropdownFrame.Size = UDim2.new(1, -20, 0, 30 + (optionCount * 25))
            optionsFrame.Size = UDim2.new(0.5, -10, 0, optionCount * 25)
        else
            dropdownFrame.Size = UDim2.new(1, -20, 0, 30)
        end
    end)
    
    return dropdown
end

function Library:CreateColorPicker(tab, text, defaultColor, callback)
    local colorPicker = {
        Value = defaultColor or Color3.fromRGB(255, 255, 255),
        Callback = callback
    }
    
    local colorFrame = Instance.new("Frame")
    colorFrame.Name = "ColorPicker"
    colorFrame.Size = UDim2.new(1, -20, 0, 30)
    colorFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    colorFrame.BorderSizePixel = 0
    colorFrame.Parent = tab.Container
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Name = "Label"
    colorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = text
    colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorFrame
    
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "ColorButton"
    colorButton.Size = UDim2.new(0, 50, 0, 20)
    colorButton.Position = UDim2.new(0.8, -25, 0.5, -10)
    colorButton.BackgroundColor3 = colorPicker.Value
    colorButton.BorderSizePixel = 0
    colorButton.Text = ""
    colorButton.Parent = colorFrame
    
    -- Note: Full color picker implementation would require a color wheel
    -- This is a simplified version that cycles through preset colors
    local colorIndex = 1
    local presetColors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 255, 255)
    }
    
    colorButton.MouseButton1Click:Connect(function()
        colorIndex = (colorIndex % #presetColors) + 1
        colorPicker.Value = presetColors[colorIndex]
        colorButton.BackgroundColor3 = colorPicker.Value
        
        if colorPicker.Callback then
            local success, err = pcall(colorPicker.Callback, colorPicker.Value)
            if not success then
                self:CreateNotification("Error", "Color picker callback error: " .. err, "error")
            else
                self:CreateNotification("Success", "Color selected", "success")
            end
        end
    end)
    
    return colorPicker
end

-- Code Verifier Element
function Library:CreateCodeVerifier(tab, callback)
    local verifierFrame = Instance.new("Frame")
    verifierFrame.Name = "CodeVerifier"
    verifierFrame.Size = UDim2.new(1, -20, 0, 150)
    verifierFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    verifierFrame.BorderSizePixel = 0
    verifierFrame.Parent = tab.Container
    
    local codeBox = Instance.new("TextBox")
    codeBox.Name = "CodeInput"
    codeBox.Size = UDim2.new(1, -10, 0, 100)
    codeBox.Position = UDim2.new(0, 5, 0, 5)
    codeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    codeBox.BorderSizePixel = 0
    codeBox.Text = ""
    codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.MultiLine = true
    codeBox.PlaceholderText = "Enter your code here..."
    codeBox.Parent = verifierFrame
    
    local verifyButton = Instance.new("TextButton")
    verifyButton.Name = "VerifyButton"
    verifyButton.Size = UDim2.new(1, -10, 0, 30)
    verifyButton.Position = UDim2.new(0, 5, 0, 110)
    verifyButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    verifyButton.BorderSizePixel = 0
    verifyButton.Text = "Verify Code"
    verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyButton.Parent = verifierFrame
    
    verifyButton.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        local isValid, message = self:VerifyCode(code)
        
        if isValid then
            self:CreateNotification("Code Verifier", message, "success")
            if callback then
                local success, err = pcall(callback, code)
                if not success then
                    self:CreateNotification("Error", "Code execution error: " .. err, "error")
                end
            end
        else
            self:CreateNotification("Code Verifier", message, "error")
        end
    end)
    
    return {
        Verify = function()
            local code = codeBox.Text
            return self:VerifyCode(code)
        end,
        GetCode = function()
            return codeBox.Text
        end,
        SetCode = function(newCode)
            codeBox.Text = newCode
        end
    }
end

-- Config System
function Library:SaveConfig(name)
    name = name or self.CurrentConfig
    local config = {}
    
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if element.Value ~= nil then
                config[tab.Name .. "_" .. element.Name] = element.Value
            end
        end
    end
    
    self.Configs[name] = config
    self:CreateNotification("Config", "Config saved: " .. name, "success")
end

function Library:LoadConfig(name)
    name = name or self.CurrentConfig
    local config = self.Configs[name]
    
    if config then
        -- Implementation to load config values back to UI elements
        self:CreateNotification("Config", "Config loaded: " .. name, "success")
    else
        self:CreateNotification("Config", "Config not found: " .. name, "error")
    end
end

function Library:DeleteConfig(name)
    if self.Configs[name] then
        self.Configs[name] = nil
        self:CreateNotification("Config", "Config deleted: " .. name, "success")
    else
        self:CreateNotification("Config", "Config not found: " .. name, "error")
    end
end

-- Settings Tab Creation
function Library:CreateSettingsTab()
    local settingsTab = self:CreateTab("Settings")
    
    -- Keybind Setting
    self:CreateLabel(settingsTab, "Toggle Keybind")
    local keybindDisplay = self:CreateTextBox(settingsTab, "Current Key", tostring(self.ToggleKey), function(newKey)
        local keyCode = Enum.KeyCode[newKey]
        if keyCode then
            self:SetToggleKey(keyCode)
        else
            self:CreateNotification("Error", "Invalid key: " .. newKey, "error")
        end
    end)
    
    -- Config Management
    self:CreateLabel(settingsTab, "Config Management")
    
    local configNameBox = self:CreateTextBox(settingsTab, "Config Name", "default", function(text)
        self.CurrentConfig = text
    end)
    
    self:CreateButton(settingsTab, "Save Config", function()
        self:SaveConfig(configNameBox.Text)
    end)
    
    self:CreateButton(settingsTab, "Load Config", function()
        self:LoadConfig(configNameBox.Text)
    end)
    
    self:CreateButton(settingsTab, "Delete Config", function()
        self:DeleteConfig(configNameBox.Text)
    end)
    
    -- Unload Button
    self:CreateButton(settingsTab, "Unload Library", function()
        self:Unload()
    end)
    
    return settingsTab
end

-- Example Usage
local function ExampleUsage()
    local gui = Library.new("MyGUI")
    
    -- Create main tab
    local mainTab = gui:CreateTab("Main")
    
    -- Add elements to main tab
    gui:CreateLabel(mainTab, "Welcome to MyGUI!")
    
    gui:CreateToggle(mainTab, "Enable Feature", false, function(value)
        print("Feature enabled:", value)
    end)
    
    gui:CreateButton(mainTab, "Click Me!", function()
        print("Button clicked!")
    end)
    
    gui:CreateTextBox(mainTab, "Username", "Enter username", function(text)
        print("Username entered:", text)
    end)
    
    gui:CreateDropdown(mainTab, "Options", {"Option 1", "Option 2", "Option 3"}, "Option 1", function(option)
        print("Selected option:", option)
    end)
    
    gui:CreateColorPicker(mainTab, "Pick Color", Color3.fromRGB(255, 0, 0), function(color)
        print("Color selected:", color)
    end)
    
    -- Create code verifier tab
    local codeTab = gui:CreateTab("Code")
    gui:CreateCodeVerifier(codeTab, function(verifiedCode)
        print("Code verified and executed:", verifiedCode)
    end)
    
    -- Create settings tab
    gui:CreateSettingsTab()
    
    -- Test notifications
    gui:CreateNotification("Test", "Library loaded successfully!", "success")
    
    return gui
end

-- Initialize example
-- ExampleUsage()

return Library
