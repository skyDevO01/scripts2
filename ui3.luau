local env = (getgenv and getgenv()) or _G
if env.__SmoothUI and type(env.__SmoothUI.Unload) == "function" then
    pcall(function() env.__SmoothUI:Unload() end)
end

local cloneref = cloneref or function(i) return i end
local Players          = cloneref(game:GetService("Players"))
local TweenService     = cloneref(game:GetService("TweenService"))
local UIS              = cloneref(game:GetService("UserInputService"))
local RunService       = cloneref(game:GetService("RunService"))
local HttpService      = cloneref(game:GetService("HttpService"))
local TextService      = cloneref(game:GetService("TextService"))
local Stats            = cloneref(game:GetService("Stats"))
local CoreGui          = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer

local Library = {
    Version = "1.0.0",
    Theme = {
        Background   = Color3.fromRGB(14, 14, 19),
        Panel        = Color3.fromRGB(20, 20, 27),
        Element      = Color3.fromRGB(28, 28, 37),
        ElementHover = Color3.fromRGB(38, 38, 50),
        Outline      = Color3.fromRGB(42, 42, 56),
        Text         = Color3.fromRGB(235, 235, 245),
        SubText      = Color3.fromRGB(150, 150, 170),
        Accent       = Color3.fromRGB(125, 95, 255),
    },
    Radius = 6,
    Options = {},
    Flags = {},
    Windows = {},
    Connections = {},
    UnloadCallbacks = {},
    AccentFns = {},
    Unloaded = false,
    ToggleKey = Enum.KeyCode.RightShift,
    Folder = "SmoothUI",
    LastBind = 0,
    Panels = {},
    PanelTransparency = 0.2,
    ThemeName = "Default",
    DefaultBackground = "https://i.pinimg.com/736x/06/a1/39/06a139f637935c7e6baa69059d895460.jpg",
}

local SectionMT, TabMT, WindowMT = {}, {}, {}
SectionMT.__index, TabMT.__index, WindowMT.__index = SectionMT, TabMT, WindowMT

-- themes (add your own: Library.Themes.MyTheme = {...}; table.insert(Library.ThemeOrder, "MyTheme"))
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
Library.Themes = {
    Default = table.clone(Library.Theme),
    Ocean = {
        Background = rgb(10, 16, 24), Panel = rgb(15, 24, 36), Element = rgb(21, 33, 48), ElementHover = rgb(30, 46, 66),
        Outline = rgb(35, 56, 80), Text = rgb(230, 240, 250), SubText = rgb(130, 155, 180), Accent = rgb(0, 170, 255),
    },
    Rose = {
        Background = rgb(20, 12, 16), Panel = rgb(28, 17, 23), Element = rgb(38, 24, 31), ElementHover = rgb(52, 33, 43),
        Outline = rgb(66, 42, 54), Text = rgb(250, 235, 240), SubText = rgb(180, 145, 158), Accent = rgb(255, 85, 140),
    },
    Emerald = {
        Background = rgb(10, 18, 14), Panel = rgb(15, 26, 20), Element = rgb(21, 36, 29), ElementHover = rgb(30, 50, 40),
        Outline = rgb(38, 64, 50), Text = rgb(230, 248, 238), SubText = rgb(135, 170, 150), Accent = rgb(40, 220, 130),
    },
    Sunset = {
        Background = rgb(20, 13, 12), Panel = rgb(29, 19, 16), Element = rgb(40, 27, 22), ElementHover = rgb(55, 37, 30),
        Outline = rgb(72, 48, 38), Text = rgb(252, 240, 230), SubText = rgb(185, 155, 140), Accent = rgb(255, 140, 50),
    },
    Amoled = {
        Background = rgb(0, 0, 0), Panel = rgb(10, 10, 10), Element = rgb(18, 18, 18), ElementHover = rgb(28, 28, 28),
        Outline = rgb(38, 38, 38), Text = rgb(240, 240, 240), SubText = rgb(140, 140, 140), Accent = rgb(120, 200, 255),
    },
    Light = {
        Background = rgb(238, 239, 244), Panel = rgb(250, 250, 253), Element = rgb(228, 229, 236), ElementHover = rgb(214, 216, 226),
        Outline = rgb(200, 202, 214), Text = rgb(25, 25, 35), SubText = rgb(100, 102, 120), Accent = rgb(90, 80, 240),
    },
}
Library.ThemeOrder = { "Default", "Ocean", "Rose", "Emerald", "Sunset", "Amoled", "Light" }

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------
local function New(class, props, children)
    local inst = Instance.new(class)
    if class == "Frame" or class == "TextButton" or class == "TextLabel" or class == "TextBox"
        or class == "ScrollingFrame" or class == "CanvasGroup" then
        inst.BorderSizePixel = 0
    end
    if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
        inst.Font = Enum.Font.GothamMedium
        inst.TextSize = 13
        inst.TextColor3 = Library.Theme.Text
        if class ~= "TextBox" then inst.BackgroundTransparency = 1 end
        if class == "TextButton" then inst.AutoButtonColor = false; inst.Text = "" end
    end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    inst.Parent = parent
    return inst
end

local function Tween(inst, props, t, style, dir)
    local tw = TweenService:Create(inst, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Corner(inst, r)
    return New("UICorner", { Parent = inst, CornerRadius = UDim.new(0, r or Library.Radius) })
end

local function Stroke(inst, color, thickness, transparency)
    return New("UIStroke", {
        Parent = inst, Color = color or Library.Theme.Outline, Thickness = thickness or 1,
        Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Pad(inst, l, t, r, b)
    return New("UIPadding", {
        Parent = inst, PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0),
    })
end

local function List(inst, padding, dir)
    return New("UIListLayout", {
        Parent = inst, Padding = UDim.new(0, padding or 0),
        SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = dir or Enum.FillDirection.Vertical,
    })
end

local function protect(gui)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function keyToString(k) return k and tostring(k) or "None" end
local function stringToKey(s)
    if type(s) ~= "string" or s == "None" then return nil end
    local t, n = s:match("^Enum%.(%w+)%.(%w+)$")
    if not t then return nil end
    local ok, res = pcall(function() return Enum[t][n] end)
    return ok and res or nil
end
local function keyName(k)
    if not k then return "None" end
    if k.EnumType == Enum.KeyCode then return k.Name end
    return (k.Name:gsub("MouseButton", "MB"))
end

local function cleanName(s)
    s = tostring(s or ""):gsub("[^%w%-%_ ]", "")
    s = s:match("^%s*(.-)%s*$")
    return s ~= "" and s or nil
end

local function Fire(obj)
    for _, cb in ipairs(obj.Callbacks) do
        local ok, err = pcall(cb, obj.Value)
        if not ok then warn("[SmoothUI] callback error (" .. tostring(obj.Flag) .. "): " .. tostring(err)) end
    end
end

local function register(obj, flag, opts)
    obj.Flag = flag
    obj.NoSave = opts.NoSave
    obj.Callbacks = {}
    if flag then Library.Options[flag] = obj end
    if opts.Callback then table.insert(obj.Callbacks, opts.Callback) end
    function obj:OnChanged(fn) table.insert(self.Callbacks, fn); return self end
end

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging, dragStart, startPos = true, i.Position, target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Library:Connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Tween(target, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) }, 0.07, Enum.EasingStyle.Linear)
        end
    end)
end

----------------------------------------------------------------------
-- core
----------------------------------------------------------------------
function Library:Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self.Connections, c)
    return c
end

function Library:OnUnload(fn)
    table.insert(self.UnloadCallbacks, fn)
end

function Library:Accent(inst, prop)
    prop = prop or "BackgroundColor3"
    local fn = function() inst[prop] = Library.Theme.Accent end
    table.insert(self.AccentFns, fn)
    fn()
end

function Library:OnAccent(fn) table.insert(self.AccentFns, fn) end

function Library:SetAccent(color)
    self.Theme.Accent = color
    for _, f in ipairs(self.AccentFns) do pcall(f) end
end

local function ckey(c)
    return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- switches theme live: every UI color matching the old theme is tweened to the new one
function Library:SetTheme(name)
    local new = self.Themes[name]
    if not new then return false end
    self.ThemeName = name
    local map = {}
    for k, nv in pairs(new) do
        local ov = self.Theme[k]
        if ov and ckey(ov) ~= ckey(nv) and not map[ckey(ov)] then map[ckey(ov)] = nv end
    end
    for k, v in pairs(new) do self.Theme[k] = v end -- mutate in place, elements keep their reference
    if not self.Gui then return true end
    local function fix(inst, prop)
        local n = map[ckey(inst[prop])]
        if n then Tween(inst, { [prop] = n }, 0.35) end
    end
    for _, d in ipairs(self.Gui:GetDescendants()) do
        if d:IsA("GuiObject") then fix(d, "BackgroundColor3") end
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then fix(d, "TextColor3") end
        if d:IsA("TextBox") then fix(d, "PlaceholderColor3") end
        if d:IsA("ScrollingFrame") then fix(d, "ScrollBarImageColor3") end
        if d:IsA("UIStroke") then fix(d, "Color") end
    end
    for _, f in ipairs(self.AccentFns) do pcall(f) end
    return true
end

function Library:SetPanelTransparency(a)
    self.PanelTransparency = a
    for _, f in ipairs(self.Panels) do
        if f.Parent then Tween(f, { BackgroundTransparency = a }, 0.2) end
    end
end

-- turns an image link into something an ImageLabel can show (downloads + caches it)
function Library:_resolveImage(url)
    if url:match("^rbxassetid://") or url:match("^rbxasset://") or url:match("^rbxthumb://") then return url end
    if url:match("^%d+$") then return "rbxassetid://" .. url end
    local getAsset = getcustomasset or getsynasset
    if not (getAsset and writefile and isfile and isfolder and makefolder) then
        return nil, "This executor can't load web images (needs getcustomasset + writefile)"
    end
    local ext = url:lower():match("%.png") and "png" or "jpg"
    local h = 5381
    for i = 1, #url do h = (h * 33 + url:byte(i)) % 4294967296 end
    local path = string.format("%s/bg_%x.%s", self.Folder, h, ext)
    self:_ensureFolders()
    if not isfile(path) then
        local data
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" then data = res end
        if not data then
            local req = (syn and syn.request) or request or http_request
            if req then
                local ok2, r = pcall(req, { Url = url, Method = "GET" })
                if ok2 and r and r.Body then data = r.Body end
            end
        end
        if not data or #data < 100 then return nil, "Couldn't download the image" end
        local w, e = pcall(writefile, path, data)
        if not w then return nil, tostring(e) end
    end
    local ok, asset = pcall(getAsset, path)
    if not ok or not asset then return nil, "Couldn't load the image file" end
    return asset
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, cb in ipairs(self.UnloadCallbacks) do
        local ok, err = pcall(cb)
        if not ok then warn("[SmoothUI] OnUnload error: " .. tostring(err)) end
    end
    for _, w in ipairs(self.Windows) do pcall(function() w:SetVisible(false) end) end
    if self.Watermark then Tween(self.Watermark, { BackgroundTransparency = 1 }, 0.2); self.Watermark.Visible = false end
    if self.KeybindFrame then self.KeybindFrame.Visible = false end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Connections = {}
    task.delay(0.35, function()
        if self.Gui then self.Gui:Destroy() end
    end)
    if env.__SmoothUI == self then env.__SmoothUI = nil end
end

function Library:_init(opts)
    if self.Gui then return end
    local T = self.Theme
    self.Folder = opts.ConfigFolder or opts.Title or "SmoothUI"
    if opts.Keybind then self.ToggleKey = opts.Keybind end
    -- mobile mode: auto (touch device without keyboard) unless opts.Mobile is set
    if opts.Mobile ~= nil then self.Mobile = opts.Mobile and true or false
    else self.Mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled end
    self._showToggleBtn = opts.ToggleButton
    if self._showToggleBtn == nil then self._showToggleBtn = self.Mobile end
    if opts.Theme and self.Themes[opts.Theme] then
        for k, v in pairs(self.Themes[opts.Theme]) do self.Theme[k] = v end
        self.ThemeName = opts.Theme
    end

    local gui = New("ScreenGui", {
        Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
    })
    protect(gui)
    self.Gui = gui

    -- notifications
    self.NotifyHolder = New("Frame", {
        Parent = gui, Size = UDim2.new(0, 260, 1, -70), BackgroundTransparency = 1,
    })
    self.NotifyLayout = New("UIListLayout", {
        Parent = self.NotifyHolder, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self:SetNotifyPosition(opts.NotifyPosition or "Top Right")

    -- watermark
    self.WatermarkBase = opts.Title or "SmoothUI"
    local wm = New("Frame", {
        Parent = gui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0), BackgroundColor3 = T.Panel,
    })
    Corner(wm); Stroke(wm, T.Outline)
    local wmLine = New("Frame", { Parent = wm, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -12, 0, 2) })
    Corner(wmLine, 2); self:Accent(wmLine)
    self.WatermarkLabel = New("TextLabel", {
        Parent = wm, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
        Text = self.WatermarkBase, TextSize = 12,
    })
    Pad(self.WatermarkLabel, 10, 6, 10, 6)
    self.Watermark = wm
    MakeDraggable(wm, wm)

    -- keybind list
    local kb = New("Frame", {
        Parent = gui, Position = UDim2.new(0, 12, 0.4, 0), Size = UDim2.fromOffset(170, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel,
    })
    Corner(kb); Stroke(kb, T.Outline)
    local kbTitle = New("TextLabel", {
        Parent = kb, Size = UDim2.new(1, 0, 0, 24), Text = "Keybinds", Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = 0,
    })
    local kbLine = New("Frame", { Parent = kbTitle, Position = UDim2.new(0, 6, 1, -2), Size = UDim2.new(1, -12, 0, 2) })
    Corner(kbLine, 2); self:Accent(kbLine)
    local kbList = New("Frame", {
        Parent = kb, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 1,
    })
    List(kbList, 2); Pad(kbList, 10, 4, 10, 6)
    List(kb, 0)
    self.KeybindFrame, self.KeybindContainer = kb, kbList
    MakeDraggable(kbTitle, kb)

    -- floating button that opens / closes the menu (draggable)
    self:_makeToggleButton()
    self:SetToggleButtonVisible(self._showToggleBtn)
    if self.Mobile then self:SetKeybindListVisible(false) end

    -- keep the window fitted to the screen in mobile mode
    local function hookCamera()
        local cam = workspace.CurrentCamera
        if cam then
            self:Connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
                for _, w in ipairs(self.Windows) do w:_fit() end
            end)
        end
    end
    hookCamera()
    self:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        hookCamera()
        for _, w in ipairs(self.Windows) do w:_fit() end
    end)

    -- click outside an open popup closes it
    self:Connect(UIS.InputBegan, function(i)
        if self.Popup and (isPress(i) or i.UserInputType == Enum.UserInputType.MouseButton2) then
            local f = self.Popup.frame
            local p, s, pos = f.AbsolutePosition, f.AbsoluteSize, i.Position
            -- AbsolutePosition is already the top-left corner, whatever the anchor point
            if pos.X < p.X or pos.X > p.X + s.X or pos.Y < p.Y or pos.Y > p.Y + s.Y then
                self:_closePopup()
            end
        end
    end)

    -- menu toggle key
    self:Connect(UIS.InputBegan, function(i, gp)
        if gp or self.Unloaded then return end
        if os.clock() - self.LastBind < 0.15 then return end
        if self.ToggleKey and i.KeyCode == self.ToggleKey then
            for _, w in ipairs(self.Windows) do w:SetVisible(not w.Visible) end
        end
    end)

    -- fps / ping
    local frames, last = 0, os.clock()
    self:Connect(RunService.RenderStepped, function()
        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            local fps = math.floor(frames / (now - last) + 0.5)
            frames, last = 0, now
            local ok, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            self.WatermarkLabel.Text = string.format("%s  |  %d fps%s", self.WatermarkBase, fps, ok and ("  |  " .. ping .. " ms") or "")
        end
    end)
end

function Library:_makeToggleButton()
    local T = self.Theme
    local btn = New("Frame", {
        Parent = self.Gui, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.Panel, Visible = false,
    })
    Corner(btn, 22)
    local st = Stroke(btn, T.Outline, 2)
    local sc = New("UIScale", { Parent = btn, Scale = 1 })
    for i = 0, 2 do
        local bar = New("Frame", {
            Parent = btn, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14 + i * 6),
            Size = UDim2.fromOffset(i == 1 and 12 or 18, 3),
        })
        Corner(bar, 2); self:Accent(bar)
    end
    local hit = New("TextButton", { Parent = btn, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
    self.ToggleBtn, self.ToggleBtnStroke, self.ToggleBtnScale = btn, st, sc

    local dragging, moved, dragStart, startPos = false, false, nil, nil
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging, moved = true, false
            dragStart, startPos = i.Position, btn.Position
            Tween(sc, { Scale = 0.88 }, 0.1)
        end
    end)
    self:Connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            if moved or d.Magnitude > 8 then
                moved = true
                Tween(btn, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) }, 0.06, Enum.EasingStyle.Linear)
            end
        end
    end)
    self:Connect(UIS.InputEnded, function(i)
        if dragging and isPress(i) then
            dragging = false
            Tween(sc, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
            if not moved then
                for _, w in ipairs(self.Windows) do w:SetVisible(not w.Visible) end
            end
        end
    end)
    self:OnAccent(function() self:_syncToggleBtn() end)
end

function Library:_syncToggleBtn()
    if not self.ToggleBtnStroke then return end
    local open = false
    for _, w in ipairs(self.Windows) do if w.Visible then open = true end end
    Tween(self.ToggleBtnStroke, { Color = open and self.Theme.Accent or self.Theme.Outline }, 0.25)
end

function Library:SetToggleButtonVisible(v)
    if not self.ToggleBtn then return end
    v = v and true or false
    if v and not self.ToggleBtn.Visible then
        self.ToggleBtn.Visible = true
        self.ToggleBtnScale.Scale = 0
        Tween(self.ToggleBtnScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
    elseif not v and self.ToggleBtn.Visible then
        Tween(self.ToggleBtnScale, { Scale = 0 }, 0.2)
        task.delay(0.22, function()
            if self.ToggleBtn and self.ToggleBtn.Parent and self.ToggleBtnScale.Scale == 0 then self.ToggleBtn.Visible = false end
        end)
    end
    self:_syncToggleBtn()
end

function Library:SetMobile(v)
    self.Mobile = v and true or false
    for _, w in ipairs(self.Windows) do w:_fit() end
    if self.Mobile then
        local o = self.Options.UI_ToggleBtn
        if o then o:SetValue(true) else self:SetToggleButtonVisible(true) end
    end
end

function Library:SetWatermark(text) self.WatermarkBase = text end
function Library:SetWatermarkVisible(v) if self.Watermark then self.Watermark.Visible = v end end
function Library:SetKeybindListVisible(v) if self.KeybindFrame then self.KeybindFrame.Visible = v end end

Library.NotifyPositions = { "Top Left", "Top Center", "Top Right", "Bottom Left", "Bottom Center", "Bottom Right" }

function Library:SetNotifyPosition(name)
    local top = name:find("Top") ~= nil
    local x = name:find("Left") and 0 or (name:find("Right") and 1 or 0.5)
    if not (name:find("Top") or name:find("Bottom")) then return false end
    self.NotifyPosition = name
    self._notifyTop, self._notifyX = top, x
    local yOff = top and ((x == 0.5) and 54 or 14) or -14 -- top center sits below the watermark
    local xOff = x == 0 and 14 or (x == 1 and -14 or 0)
    self.NotifyHolder.AnchorPoint = Vector2.new(x, top and 0 or 1)
    self.NotifyHolder.Position = UDim2.new(x, xOff, top and 0 or 1, yOff)
    self.NotifyLayout.HorizontalAlignment = x == 0 and Enum.HorizontalAlignment.Left
        or (x == 1 and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center)
    self.NotifyLayout.VerticalAlignment = top and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
    return true
end

-- off-screen position a notification slides from / to
function Library:_notifyHidden()
    if self._notifyX == 0 then return UDim2.fromOffset(-300, 0) end
    if self._notifyX == 1 then return UDim2.fromOffset(300, 0) end
    return UDim2.fromOffset(0, self._notifyTop and -80 or 80)
end

function Library:Notify(text, duration, title)
    if not self.Gui then return end
    local T = self.Theme
    duration = duration or 4
    local holder = New("Frame", {
        Parent = self.NotifyHolder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = math.floor(os.clock() * 100),
    })
    local inner = New("Frame", {
        Parent = holder, Position = self:_notifyHidden(), Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, ClipsDescendants = true,
    })
    Corner(inner); Stroke(inner, T.Outline)
    local content = New("Frame", { Parent = inner, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    List(content, 2); Pad(content, 12, 10, 12, 12)
    if title then
        New("TextLabel", { Parent = content, Size = UDim2.new(1, 0, 0, 16), Text = title, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 })
    end
    New("TextLabel", {
        Parent = content, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(text),
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.SubText, LayoutOrder = 1,
    })
    local bar = New("Frame", { Parent = inner, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2) })
    self:Accent(bar)
    Tween(inner, { Position = UDim2.new(0, 0, 0, 0) }, 0.4, Enum.EasingStyle.Back)
    Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        if not inner.Parent then return end
        Tween(inner, { Position = self:_notifyHidden() }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.32)
        holder:Destroy()
    end)
end

----------------------------------------------------------------------
-- config system
----------------------------------------------------------------------
function Library:_fsOk()
    return (writefile and readfile and isfile and isfolder and makefolder and listfiles and delfile) and true or false
end
function Library:_cfgPath(name) return self.Folder .. "/configs/" .. name .. ".json" end
function Library:_ensureFolders()
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    if not isfolder(self.Folder .. "/configs") then makefolder(self.Folder .. "/configs") end
end

function Library:GetConfigs()
    if not self:_fsOk() then return {} end
    self:_ensureFolders()
    local out = {}
    local ok, files = pcall(listfiles, self.Folder .. "/configs")
    if ok then
        for _, f in ipairs(files) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    table.sort(out)
    return out
end

function Library:_serialize()
    local data = {}
    for flag, o in pairs(self.Options) do
        if not o.NoSave then
            local t = o.Type
            if t == "Toggle" or t == "Slider" or t == "Input" then
                data[flag] = o.Value
            elseif t == "Dropdown" then
                if o.Multi then
                    local l = {}
                    for k, v in pairs(o.Value) do if v then table.insert(l, k) end end
                    table.sort(l)
                    data[flag] = l
                else
                    data[flag] = o.Value or ""
                end
            elseif t == "Keybind" then
                data[flag] = { Key = keyToString(o.Key), Mode = o.Mode }
            end
        end
    end
    return data
end

function Library:SaveConfig(name)
    name = cleanName(name)
    if not name then return false, "Invalid config name" end
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    local ok, err = pcall(function()
        self:_ensureFolders()
        writefile(self:_cfgPath(name), HttpService:JSONEncode(self:_serialize()))
    end)
    return ok, ok and ("Saved config '" .. name .. "'") or tostring(err)
end

function Library:LoadConfig(name)
    name = cleanName(name)
    if not name then return false, "No config selected" end
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    local path = self:_cfgPath(name)
    if not isfile(path) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false, "Config file is corrupted" end
    for flag, val in pairs(data) do
        local o = self.Options[flag]
        if o and not o.NoSave then
            pcall(function()
                if o.Type == "Keybind" then
                    if type(val) == "table" then
                        o:SetMode(val.Mode or o.Mode)
                        o:SetKey(stringToKey(val.Key))
                    end
                elseif o.Type == "Dropdown" and not o.Multi then
                    o:SetValue(val ~= "" and val or nil)
                else
                    o:SetValue(val)
                end
            end)
        end
    end
    return true, "Loaded config '" .. name .. "'"
end

function Library:DeleteConfig(name)
    name = cleanName(name)
    if not name then return false, "No config selected" end
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    local path = self:_cfgPath(name)
    if not isfile(path) then return false, "Config not found" end
    local ok, err = pcall(delfile, path)
    if ok and self:GetAutoLoad() == name then self:ClearAutoLoad() end
    return ok, ok and ("Deleted config '" .. name .. "'") or tostring(err)
end

function Library:RenameConfig(old, new)
    old, new = cleanName(old), cleanName(new)
    if not old then return false, "No config selected" end
    if not new then return false, "Invalid new name" end
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    if not isfile(self:_cfgPath(old)) then return false, "Config not found" end
    if isfile(self:_cfgPath(new)) then return false, "A config with that name exists" end
    local ok, err = pcall(function()
        writefile(self:_cfgPath(new), readfile(self:_cfgPath(old)))
        delfile(self:_cfgPath(old))
    end)
    if ok and self:GetAutoLoad() == old then self:SetAutoLoad(new) end
    return ok, ok and ("Renamed '" .. old .. "' to '" .. new .. "'") or tostring(err)
end

function Library:GetAutoLoad()
    if not self:_fsOk() then return nil end
    local p = self.Folder .. "/autoload.txt"
    if isfile(p) then
        local n = cleanName(readfile(p))
        return n
    end
end

function Library:SetAutoLoad(name)
    name = cleanName(name)
    if not name then return false, "No config selected" end
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    local ok, err = pcall(function()
        self:_ensureFolders()
        writefile(self.Folder .. "/autoload.txt", name)
    end)
    return ok, ok and ("'" .. name .. "' will load automatically") or tostring(err)
end

function Library:ClearAutoLoad()
    if not self:_fsOk() then return false, "Filesystem not supported here" end
    local p = self.Folder .. "/autoload.txt"
    if isfile(p) then pcall(delfile, p) end
    return true, "Auto load cleared"
end

-- call this once at the END of your script, after all elements exist
function Library:LoadAutoload()
    local name = self:GetAutoLoad()
    if name and isfile(self:_cfgPath(name)) then
        local ok, msg = self:LoadConfig(name)
        self:Notify(msg, 3, ok and "Auto Load" or "Auto Load failed")
    end
end

----------------------------------------------------------------------
-- window
----------------------------------------------------------------------
function Library:CreateWindow(opts)
    opts = opts or {}
    self:_init(opts)
    local T = self.Theme
    local Window = setmetatable({ Tabs = {}, Visible = false, BaseScale = 1, Library = self, UserTabs = 0 }, WindowMT)

    local holder = New("Frame", {
        Parent = self.Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = opts.Size or UDim2.fromOffset(580, 420), BackgroundTransparency = 1, Visible = false,
    })
    Corner(holder, 10)
    local holderStroke = Stroke(holder, T.Outline, 1, 1)
    local scale = New("UIScale", { Parent = holder, Scale = 0.92 })
    local main = New("CanvasGroup", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, GroupTransparency = 1 })
    Corner(main, 10)

    Window.Holder, Window.Main, Window.Scale, Window.HolderStroke = holder, main, scale, holderStroke

    -- custom background (image + dim overlay), sits behind everything else
    Window.BgDim = 0.45
    Window.BgImage = New("ImageLabel", {
        Parent = main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 1, ZIndex = 0, Visible = false, BorderSizePixel = 0,
    })
    Window.BgOverlay = New("Frame", {
        Parent = main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
        ZIndex = 1, Visible = false, BorderSizePixel = 0,
    })
    local bg = opts.Background
    if bg == nil then bg = Library.DefaultBackground end
    Window.InitialBg = bg or ""

    -- top bar
    local top = New("Frame", { Parent = main, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 })
    local dot = New("Frame", { Parent = top, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(8, 8) })
    Corner(dot, 4); self:Accent(dot)
    local sub = opts.Subtitle and string.format(' <font color="rgb(%d,%d,%d)">%s</font>', T.SubText.R * 255, T.SubText.G * 255, T.SubText.B * 255, opts.Subtitle) or ""
    New("TextLabel", {
        Parent = top, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -80, 1, 0), RichText = true,
        Text = (opts.Title or "SmoothUI") .. sub, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local close = New("TextButton", {
        Parent = top, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(24, 24),
        Text = "×", TextSize = 20, TextColor3 = T.SubText,
    })
    close.MouseEnter:Connect(function() Tween(close, { TextColor3 = Color3.fromRGB(255, 90, 100) }, 0.15) end)
    close.MouseLeave:Connect(function() Tween(close, { TextColor3 = T.SubText }, 0.15) end)
    close.MouseButton1Click:Connect(function()
        Window:SetVisible(false)
        if self.ToggleBtn and self.ToggleBtn.Visible then
            self:Notify("Tap the menu button to open the UI again", 3)
        else
            self:Notify("Press " .. keyName(self.ToggleKey) .. " to open the menu again", 3)
        end
    end)
    MakeDraggable(top, holder)
    New("Frame", { Parent = main, Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Outline })

    -- tab bar (horizontal)
    local tabBar = New("ScrollingFrame", {
        Parent = main, Position = UDim2.new(0, 0, 0, 39), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
        ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
    })
    local indicator = New("Frame", { Parent = tabBar, Position = UDim2.fromOffset(10, 28), Size = UDim2.fromOffset(20, 2) })
    Corner(indicator, 2); self:Accent(indicator)
    New("Frame", { Parent = main, Position = UDim2.new(0, 0, 0, 71), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Outline })
    Window.TabBar, Window.Indicator = tabBar, indicator

    Window.Content = New("Frame", {
        Parent = main, Position = UDim2.new(0, 10, 0, 82), Size = UDim2.new(1, -20, 1, -92), BackgroundTransparency = 1,
    })

    table.insert(self.Windows, Window)
    Window.UserScale = 1
    Window:_fit()
    Window:_buildSettings()
    task.defer(function() Window:SetVisible(true) end)
    return Window
end

function WindowMT:_applyDim()
    if self.BgImage.Visible then
        Tween(self.BgOverlay, { BackgroundTransparency = 1 - self.BgDim }, 0.25)
    end
end

function WindowMT:SetBackgroundDim(d)
    self.BgDim = math.clamp(d, 0, 1)
    self:_applyDim()
end

-- url: image link / rbxassetid / "" to remove
function WindowMT:SetBackground(url)
    local lib = self.Library
    url = tostring(url or ""):match("^%s*(.-)%s*$")
    self._bgTok = (self._bgTok or 0) + 1
    local tok = self._bgTok
    if url == "" then
        Tween(self.BgImage, { ImageTransparency = 1 }, 0.3)
        Tween(self.BgOverlay, { BackgroundTransparency = 1 }, 0.3)
        task.delay(0.32, function()
            if self._bgTok == tok then self.BgImage.Visible = false; self.BgOverlay.Visible = false end
        end)
        return
    end
    task.spawn(function()
        local asset, err = lib:_resolveImage(url)
        if self._bgTok ~= tok or lib.Unloaded then return end
        if not asset then
            lib:Notify(err or "Unknown error", 4, "Background failed")
            return
        end
        self.BgImage.Image = asset
        self.BgImage.ImageTransparency = 1
        self.BgImage.Visible = true
        self.BgOverlay.Visible = true
        Tween(self.BgImage, { ImageTransparency = 0 }, 0.6)
        self:_applyDim()
    end)
end

-- user scale (slider) * screen fit (mobile mode only)
function WindowMT:_fit()
    local fit = 1
    if self.Library.Mobile then
        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            local w, h = self.Holder.Size.X.Offset, self.Holder.Size.Y.Offset
            if w > 0 and h > 0 then
                fit = math.clamp(math.min((vp.X - 16) / w, (vp.Y - 16) / h), 0.4, 1)
            end
        end
    end
    local s = (self.UserScale or 1) * fit
    self.BaseScale = s
    if self.Visible then Tween(self.Scale, { Scale = s }, 0.25)
    else self.Scale.Scale = s * 0.92 end
end

function WindowMT:SetScale(s)
    self.UserScale = s
    self:_fit()
end

function WindowMT:SetVisible(v)
    if self.Visible == v then return end
    self.Visible = v
    self._tok = (self._tok or 0) + 1
    local tok = self._tok
    self.Library:_syncToggleBtn()
    if not v then self.Library:_closePopup() end
    if v then
        self.Holder.Visible = true
        Tween(self.Scale, { Scale = self.BaseScale }, 0.4, Enum.EasingStyle.Back)
        Tween(self.Main, { GroupTransparency = 0 }, 0.25)
        Tween(self.HolderStroke, { Transparency = 0 }, 0.25)
    else
        Tween(self.Scale, { Scale = self.BaseScale * 0.94 }, 0.2)
        Tween(self.Main, { GroupTransparency = 1 }, 0.2)
        Tween(self.HolderStroke, { Transparency = 1 }, 0.2)
        task.delay(0.22, function()
            if self._tok == tok then self.Holder.Visible = false end
        end)
    end
end

function WindowMT:_relayoutTabs()
    local x = 8
    for i, t in ipairs(self.Tabs) do
        t.X = x
        t.Button.Position = UDim2.fromOffset(x, 0)
        x += t.Width + 4
    end
    if self.Current then
        Tween(self.Indicator, {
            Position = UDim2.fromOffset(self.Current.X + 10, 28),
            Size = UDim2.fromOffset(self.Current.Width - 20, 2),
        }, 0.3)
    end
end

function WindowMT:SelectTab(tab)
    if self.Current == tab then return end
    local T = self.Library.Theme
    local old = self.Current
    self.Current = tab
    if old then
        old._tok = (old._tok or 0) + 1
        local tok = old._tok
        Tween(old.Button, { TextColor3 = T.SubText }, 0.2)
        Tween(old.Page, { GroupTransparency = 1 }, 0.15)
        task.delay(0.16, function() if old._tok == tok then old.Page.Visible = false end end)
    end
    tab._tok = (tab._tok or 0) + 1
    tab.Page.Visible = true
    tab.Page.Position = UDim2.fromOffset(0, 12)
    tab.Page.GroupTransparency = 1
    Tween(tab.Page, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.3)
    Tween(tab.Button, { TextColor3 = T.Text }, 0.2)
    self:_relayoutTabs()
end

function WindowMT:AddTab(name)
    local T = self.Library.Theme
    local tab = setmetatable({ Name = name, Window = self, Sections = {} }, TabMT)
    tab.Width = TextService:GetTextSize(name, 13, Enum.Font.GothamMedium, Vector2.new(1000, 100)).X + 28
    tab.Button = New("TextButton", {
        Parent = self.TabBar, Size = UDim2.new(0, tab.Width, 0, 30), Text = name, TextColor3 = T.SubText,
    })
    tab.Button.MouseEnter:Connect(function() if self.Current ~= tab then Tween(tab.Button, { TextColor3 = T.Text }, 0.15) end end)
    tab.Button.MouseLeave:Connect(function() if self.Current ~= tab then Tween(tab.Button, { TextColor3 = T.SubText }, 0.15) end end)
    tab.Button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    tab.Page = New("CanvasGroup", {
        Parent = self.Content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1,
    })
    local scroll
    scroll = New("ScrollingFrame", {
        Parent = tab.Page, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Outline, CanvasSize = UDim2.new(), BorderSizePixel = 0,
    })
    tab.Scroll = scroll
    local function column(x)
        local c = New("Frame", {
            Parent = scroll, Position = UDim2.new(x, x == 0 and 0 or 5, 0, 0), Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        })
        return c, List(c, 10)
    end
    tab.Left, tab.LeftLayout = column(0)
    tab.Right, tab.RightLayout = column(0.5)
    local function resize()
        scroll.CanvasSize = UDim2.fromOffset(0, math.max(tab.LeftLayout.AbsoluteContentSize.Y, tab.RightLayout.AbsoluteContentSize.Y) + 6)
    end
    tab.LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    tab.RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)

    -- user tabs go before the Settings tab
    local idx = self.SettingsTab and #self.Tabs or (#self.Tabs + 1)
    table.insert(self.Tabs, idx, tab)
    if self.SettingsTab then
        self.UserTabs += 1
        if self.UserTabs == 1 then self:SelectTab(tab) end
    elseif not self.Current then
        self:SelectTab(tab)
    end
    self:_relayoutTabs()
    return tab
end

----------------------------------------------------------------------
-- tab / section
----------------------------------------------------------------------
function TabMT:AddSection(name, side)
    local T = Library.Theme
    if side ~= "Left" and side ~= "Right" then side = (#self.Sections % 2 == 0) and "Left" or "Right" end
    local col = side == "Left" and self.Left or self.Right
    local frame = New("Frame", {
        Parent = col, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Panel, LayoutOrder = #self.Sections + 1, BackgroundTransparency = Library.PanelTransparency,
    })
    table.insert(Library.Panels, frame)
    Corner(frame, 8); Stroke(frame, T.Outline)
    Pad(frame, 10, 10, 10, 10)
    List(frame, 7)
    New("TextLabel", {
        Parent = frame, Size = UDim2.new(1, 0, 0, 16), Text = name or "Section", Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
    })
    local line = New("Frame", { Parent = frame, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Outline, LayoutOrder = 1 })
    local sec = setmetatable({ Frame = frame, Container = frame, Count = 1, Tab = self }, SectionMT)
    table.insert(self.Sections, sec)
    return sec
end

function SectionMT:_order() self.Count += 1; return self.Count end
function SectionMT:_row(h)
    return New("Frame", { Parent = self.Container, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = self:_order() })
end

-- Label ---------------------------------------------------------------
function SectionMT:AddLabel(text)
    local T = Library.Theme
    local lbl = New("TextLabel", {
        Parent = self.Container, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = text,
        TextColor3 = T.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = self:_order(),
    })
    local obj = {}
    function obj:SetText(t) lbl.Text = t end
    return obj
end

function SectionMT:AddDivider()
    New("Frame", { Parent = self.Container, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Library.Theme.Outline, LayoutOrder = self:_order() })
end

-- Button --------------------------------------------------------------
function SectionMT:AddButton(opts, cb)
    if type(opts) == "string" then opts = { Text = opts, Callback = cb } end
    local T = Library.Theme
    local btn = New("TextButton", {
        Parent = self.Container, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Element,
        Text = opts.Text or "Button", ClipsDescendants = true, LayoutOrder = self:_order(),
    })
    Corner(btn); local st = Stroke(btn, T.Outline)
    local RED = Color3.fromRGB(255, 90, 100)
    local confirmSecs = opts.Confirm and (type(opts.Confirm) == "number" and opts.Confirm or 3) or nil
    local armed, armTok = false, 0
    local timerBar
    if confirmSecs then
        timerBar = New("Frame", {
            Parent = btn, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = RED, Visible = false, ZIndex = 3,
        })
    end
    btn.MouseEnter:Connect(function()
        if armed then return end
        Tween(btn, { BackgroundColor3 = T.ElementHover }, 0.15); Tween(st, { Color = Library.Theme.Accent }, 0.2)
    end)
    btn.MouseLeave:Connect(function()
        if armed then return end
        Tween(btn, { BackgroundColor3 = T.Element }, 0.15); Tween(st, { Color = T.Outline }, 0.2)
    end)
    btn.InputBegan:Connect(function(i)
        if isPress(i) then
            local us = 1
            local p = btn.Parent
            while p do
                local s = p:FindFirstChildOfClass("UIScale")
                if s then us = us * s.Scale end
                p = p.Parent
            end
            local rel = (Vector2.new(i.Position.X, i.Position.Y) - btn.AbsolutePosition) / us
            local ripple = New("Frame", {
                Parent = btn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(rel.X, rel.Y),
                Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Library.Theme.Accent, BackgroundTransparency = 0.6, ZIndex = 2,
            })
            Corner(ripple, 999)
            local d = (btn.AbsoluteSize.X / us) * 2.4
            Tween(ripple, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.5)
            task.delay(0.52, function() ripple:Destroy() end)
        end
    end)
    local obj = { Type = "Button" }
    local baseText = opts.Text or "Button"
    local function run()
        if opts.Callback then
            local ok, err = pcall(opts.Callback)
            if not ok then warn("[SmoothUI] button error: " .. tostring(err)) end
        end
    end
    local function disarm()
        armed = false
        armTok += 1
        timerBar.Visible = false
        btn.Text = baseText
        Tween(btn, { BackgroundColor3 = T.Element }, 0.2)
        Tween(st, { Color = T.Outline }, 0.2)
    end
    btn.MouseButton1Click:Connect(function()
        if not confirmSecs then return run() end
        if armed then
            disarm()
            return run()
        end
        if opts.Precheck and opts.Precheck() == false then return end
        armed = true
        armTok += 1
        local tok = armTok
        Tween(btn, { BackgroundColor3 = Color3.fromRGB(70, 28, 34) }, 0.2)
        Tween(st, { Color = RED }, 0.2)
        timerBar.Size = UDim2.new(1, 0, 0, 2)
        timerBar.Visible = true
        Tween(timerBar, { Size = UDim2.new(0, 0, 0, 2) }, confirmSecs, Enum.EasingStyle.Linear)
        task.spawn(function()
            for s = confirmSecs, 1, -1 do
                if armTok ~= tok then return end
                btn.Text = string.format("Are you sure? Click to confirm (%d)", s)
                task.wait(1)
            end
            if armTok == tok then disarm() end
        end)
    end)
    function obj:SetText(t) btn.Text = t end
    return obj
end

-- Toggle --------------------------------------------------------------
function SectionMT:AddToggle(flag, opts)
    opts = opts or {}
    local T = Library.Theme
    local obj = { Type = "Toggle", Value = false }
    register(obj, flag, opts)
    local row = self:_row(24)
    local label = New("TextLabel", {
        Parent = row, Size = UDim2.new(1, -48, 1, 0), Text = opts.Text or flag, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left,
    })
    local switch = New("Frame", {
        Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(36, 18), BackgroundColor3 = T.Element,
    })
    Corner(switch, 9); local st = Stroke(switch, T.Outline)
    local knob = New("Frame", {
        Parent = switch, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = T.SubText,
    })
    Corner(knob, 6)
    local hit = New("TextButton", { Parent = row, Size = UDim2.fromScale(1, 1), ZIndex = 3 })

    function obj:SetValue(v, silent)
        v = v and true or false
        local changed = v ~= self.Value
        self.Value = v
        Library.Flags[flag] = v
        Tween(switch, { BackgroundColor3 = v and Library.Theme.Accent or T.Element }, 0.2)
        Tween(st, { Color = v and Library.Theme.Accent or T.Outline }, 0.2)
        Tween(knob, { Position = v and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = v and Color3.new(1, 1, 1) or T.SubText }, 0.25, Enum.EasingStyle.Back)
        Tween(label, { TextColor3 = v and T.Text or T.SubText }, 0.2)
        if changed and not silent then Fire(self) end
    end
    hit.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)
    Library:OnAccent(function()
        if obj.Value then switch.BackgroundColor3 = Library.Theme.Accent; st.Color = Library.Theme.Accent end
    end)
    obj:SetValue(opts.Default or false, true)
    return obj
end

-- Slider --------------------------------------------------------------
function SectionMT:AddSlider(flag, opts)
    opts = opts or {}
    local T = Library.Theme
    local min, max = opts.Min or 0, opts.Max or 100
    local rounding = opts.Rounding or 0
    local obj = { Type = "Slider", Value = min }
    register(obj, flag, opts)
    local row = self:_row(40)
    New("TextLabel", { Parent = row, Size = UDim2.new(1, -70, 0, 16), Text = opts.Text or flag, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
    local valueLabel = New("TextLabel", {
        Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(70, 16),
        Text = "", TextXAlignment = Enum.TextXAlignment.Right,
    })
    local bar = New("Frame", { Parent = row, Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.Element })
    Corner(bar, 4); Stroke(bar, T.Outline)
    local fill = New("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1) })
    Corner(fill, 4); Library:Accent(fill)
    local knob = New("Frame", {
        Parent = fill, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2,
    })
    Corner(knob, 8)
    local hit = New("TextButton", { Parent = row, Position = UDim2.new(0, 0, 0, 18), Size = UDim2.new(1, 0, 0, 24), ZIndex = 3 })

    local function fmt(v)
        local s = rounding > 0 and string.format("%." .. rounding .. "f", v) or tostring(math.floor(v + 0.5))
        return s .. (opts.Suffix or "")
    end
    function obj:SetValue(v, silent)
        v = math.clamp(tonumber(v) or min, min, max)
        local m = 10 ^ rounding
        v = math.floor(v * m + 0.5) / m
        local changed = v ~= self.Value
        self.Value = v
        Library.Flags[flag] = v
        valueLabel.Text = fmt(v)
        local a = (max - min) == 0 and 0 or (v - min) / (max - min)
        Tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.1, Enum.EasingStyle.Quad)
        if changed and not silent then Fire(self) end
    end

    local dragging = false
    local function update(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        obj:SetValue(min + (max - min) * a)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            if self.Tab.Scroll then self.Tab.Scroll.ScrollingEnabled = false end
            Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.12)
            update(i.Position.X)
        end
    end)
    Library:Connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    Library:Connect(UIS.InputEnded, function(i)
        if dragging and isPress(i) then
            dragging = false
            if self.Tab.Scroll then self.Tab.Scroll.ScrollingEnabled = true end
            Tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.12)
        end
    end)
    obj:SetValue(opts.Default or min, true)
    return obj
end

-- Dropdown (single + multi) ------------------------------------------
function SectionMT:AddDropdown(flag, opts)
    opts = opts or {}
    local T = Library.Theme
    local multi = opts.Multi and true or false
    local obj = { Type = "Dropdown", Multi = multi, Values = opts.Values or {}, Value = multi and {} or nil, Open = false }
    register(obj, flag, opts)

    local row = self:_row(48)
    row.ClipsDescendants = true
    New("TextLabel", { Parent = row, Size = UDim2.new(1, 0, 0, 16), Text = opts.Text or flag, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
    local header = New("TextButton", { Parent = row, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.Element })
    Corner(header); local hs = Stroke(header, T.Outline)
    local valueLabel = New("TextLabel", {
        Parent = header, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -30, 1, 0), Text = "None",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = T.SubText,
    })
    local arrow = New("TextLabel", {
        Parent = header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(12, 12),
        Text = "▼", TextSize = 9, TextColor3 = T.SubText,
    })
    local list = New("ScrollingFrame", {
        Parent = row, Position = UDim2.new(0, 0, 0, 50), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = T.Panel,
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.Outline, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    })
    Corner(list); Stroke(list, T.Outline); List(list, 2); Pad(list, 3, 3, 3, 3)

    local items, token = {}, 0
    local function selected(v)
        if multi then return obj.Value[v] == true end
        return obj.Value == v
    end
    local function refresh()
        for v, it in pairs(items) do
            local s = selected(v)
            Tween(it.Label, { TextColor3 = s and Library.Theme.Accent or T.SubText }, 0.15)
            Tween(it.Bar, { Size = UDim2.fromOffset(3, s and 14 or 0) }, 0.2)
        end
    end
    local function display()
        local has = false
        if multi then
            local l = {}
            for _, v in ipairs(obj.Values) do if obj.Value[v] then table.insert(l, v) end end
            has = #l > 0
            valueLabel.Text = has and table.concat(l, ", ") or "None"
        else
            has = obj.Value ~= nil
            valueLabel.Text = obj.Value or "None"
        end
        valueLabel.TextColor3 = has and T.Text or T.SubText
    end
    local function listHeight() return math.max(math.min(#obj.Values, 6) * 26 + 6, 32) end
    local function setOpen(o)
        obj.Open = o
        token += 1
        local t = token
        Tween(arrow, { Rotation = o and 180 or 0 }, 0.2)
        Tween(hs, { Color = o and Library.Theme.Accent or T.Outline }, 0.2)
        if o then
            list.Visible = true
            Tween(list, { Size = UDim2.new(1, 0, 0, listHeight()) }, 0.22)
            Tween(row, { Size = UDim2.new(1, 0, 0, 50 + listHeight() + 2) }, 0.22)
        else
            Tween(list, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
            Tween(row, { Size = UDim2.new(1, 0, 0, 48) }, 0.18)
            task.delay(0.2, function() if token == t then list.Visible = false end end)
        end
    end
    local function build()
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        items = {}
        for i, v in ipairs(obj.Values) do
            local b = New("TextButton", { Parent = list, Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.ElementHover, BackgroundTransparency = 1, LayoutOrder = i })
            Corner(b, 4)
            local lb = New("TextLabel", { Parent = b, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -14, 1, 0), Text = tostring(v), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.SubText })
            local bar = New("Frame", { Parent = b, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, 0) })
            Corner(bar, 2); Library:Accent(bar)
            b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.4 }, 0.12) end)
            b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 1 }, 0.12) end)
            b.MouseButton1Click:Connect(function()
                if multi then
                    local m = table.clone(obj.Value)
                    if m[v] then m[v] = nil else m[v] = true end
                    obj:SetValue(m)
                else
                    if obj.Value == v and opts.AllowNull then obj:SetValue(nil) else obj:SetValue(v) end
                    setOpen(false)
                end
            end)
            items[v] = { Label = lb, Bar = bar }
        end
        refresh()
    end

    function obj:SetValue(v, silent)
        if multi then
            local m = {}
            if type(v) == "table" then
                for k, x in pairs(v) do
                    if type(k) == "number" then m[x] = true elseif x then m[k] = true end
                end
            end
            self.Value = m
        else
            self.Value = (type(v) == "string" and v ~= "") and v or nil
        end
        Library.Flags[flag] = self.Value
        refresh(); display()
        if not silent then Fire(self) end
    end
    function obj:SetValues(vals)
        self.Values = vals or {}
        if multi then
            for k in pairs(self.Value) do if not table.find(self.Values, k) then self.Value[k] = nil end end
        elseif self.Value and not table.find(self.Values, self.Value) then
            self.Value = nil
        end
        Library.Flags[flag] = self.Value
        build(); display()
        if self.Open then
            Tween(list, { Size = UDim2.new(1, 0, 0, listHeight()) }, 0.2)
            Tween(row, { Size = UDim2.new(1, 0, 0, 50 + listHeight() + 2) }, 0.2)
        end
    end
    header.MouseEnter:Connect(function() if not obj.Open then Tween(header, { BackgroundColor3 = T.ElementHover }, 0.15) end end)
    header.MouseLeave:Connect(function() Tween(header, { BackgroundColor3 = T.Element }, 0.15) end)
    header.MouseButton1Click:Connect(function() setOpen(not obj.Open) end)

    build()
    local def = opts.Default
    if type(def) == "number" then def = obj.Values[def] end
    obj:SetValue(def, true)
    return obj
end

-- Input ---------------------------------------------------------------
function SectionMT:AddInput(flag, opts)
    opts = opts or {}
    local T = Library.Theme
    local obj = { Type = "Input", Value = "" }
    register(obj, flag, opts)
    local row = self:_row(48)
    New("TextLabel", { Parent = row, Size = UDim2.new(1, 0, 0, 16), Text = opts.Text or flag, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
    local box = New("TextBox", {
        Parent = row, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.Element,
        Text = "", PlaceholderText = opts.Placeholder or "Type here...", PlaceholderColor3 = T.SubText,
        ClearTextOnFocus = opts.ClearTextOnFocus or false, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true,
    })
    Corner(box); local st = Stroke(box, T.Outline); Pad(box, 10, 0, 10, 0)
    if opts.MaxLength then box.MaxVisibleGraphemes = opts.MaxLength end
    box.Focused:Connect(function() Tween(st, { Color = Library.Theme.Accent }, 0.2); Tween(box, { BackgroundColor3 = T.ElementHover }, 0.2) end)
    box.FocusLost:Connect(function()
        Tween(st, { Color = T.Outline }, 0.2); Tween(box, { BackgroundColor3 = T.Element }, 0.2)
        obj:SetValue(box.Text)
    end)
    if opts.Numeric then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local f = box.Text:gsub("[^%d%.%-]", "")
            if f ~= box.Text then box.Text = f end
        end)
    end
    if opts.Finished == false then
        box:GetPropertyChangedSignal("Text"):Connect(function() obj:SetValue(box.Text) end)
    end
    function obj:SetValue(v, silent)
        v = tostring(v or "")
        local changed = v ~= self.Value
        self.Value = v
        Library.Flags[flag] = v
        if box.Text ~= v then box.Text = v end
        if changed and not silent then Fire(self) end
    end
    obj:SetValue(opts.Default or "", true)
    return obj
end

-- Keybind -------------------------------------------------------------
local MODES = { "Hold", "Toggle", "Always" }
function SectionMT:AddKeybind(flag, opts)
    opts = opts or {}
    local T = Library.Theme
    local obj = { Type = "Keybind", Key = nil, Mode = opts.Mode or "Toggle", State = false, Value = false, Binding = false }
    register(obj, flag, opts)
    local text = opts.Text or flag

    local row = self:_row(24)
    New("TextLabel", { Parent = row, Size = UDim2.new(1, -90, 1, 0), Text = text, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
    local btn = New("TextButton", {
        Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Element, Text = "", TextSize = 12,
    })
    Corner(btn, 5); local st = Stroke(btn, T.Outline); Pad(btn, 8, 0, 8, 0)
    local btnLabel = New("TextLabel", { Parent = btn, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 12, TextColor3 = T.SubText })
    btn.AutomaticSize = Enum.AutomaticSize.X

    local entry
    if not opts.NoList and Library.KeybindContainer then
        entry = New("TextLabel", {
            Parent = Library.KeybindContainer, Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, Visible = false, TextTransparency = 1, LayoutOrder = Library:_nextKbOrder(),
        })
    end

    local function updateButton()
        if obj.Binding then
            btnLabel.Text = "..."
        elseif opts.Passive then
            btnLabel.Text = "[" .. keyName(obj.Key) .. "]"
        else
            btnLabel.Text = string.format("[%s | %s]", keyName(obj.Key), obj.Mode)
        end
    end
    local function updateEntry()
        if not entry then return end
        entry.Text = string.format("[%s] %s", obj.Mode == "Always" and "Always" or keyName(obj.Key), text)
        if obj.State then
            entry.Visible = true
            Tween(entry, { TextTransparency = 0 }, 0.2)
        else
            Tween(entry, { TextTransparency = 1 }, 0.15)
            task.delay(0.16, function() if not obj.State and entry.Parent then entry.Visible = false end end)
        end
    end

    function obj:SetState(s, silent)
        s = s and true or false
        if self.State == s then updateEntry(); return end
        self.State, self.Value = s, s
        Library.Flags[flag] = s
        updateEntry()
        if not silent then Fire(self) end
    end
    function obj:SetValue(v, silent) self:SetState(v, silent) end
    function obj:SetMode(m, silent)
        if not table.find(MODES, m) then return end
        self.Mode = m
        updateButton()
        self:SetState(m == "Always", silent)
        updateEntry()
    end
    function obj:SetKey(k, silent)
        self.Key = k
        updateButton()
        if k == nil and self.Mode ~= "Always" then self:SetState(false, silent) end
        updateEntry()
        if not silent and opts.ChangedCallback then pcall(opts.ChangedCallback, k) end
    end
    function obj:GetState() return self.State end

    -- small popup with Hold / Toggle / Always, anchored under the key button
    local function openModeMenu()
        Library:_closePopup()
        local win = self.Tab and self.Tab.Window
        local base = (win and win.BaseScale) or 1
        local itemH = 26
        local w, h = 112, #MODES * itemH + 8
        local pop = New("Frame", { Parent = Library.Gui, AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, ZIndex = 50 })
        Corner(pop, 8)
        local ps = Stroke(pop, Library.Theme.Accent, 1, 1)
        local sc = New("UIScale", { Parent = pop, Scale = base * 0.9 })
        local grp = New("CanvasGroup", { Parent = pop, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, GroupTransparency = 1 })
        Corner(grp, 8); List(grp, 2); Pad(grp, 4, 4, 4, 4)

        local ap, as = btn.AbsolutePosition, btn.AbsoluteSize
        local gs = Library.Gui.AbsoluteSize
        local x, y = ap.X + as.X, ap.Y + as.Y + 4
        if y + h * base > gs.Y - 8 then y = ap.Y - h * base - 4 end
        pop.Position = UDim2.fromOffset(x, y)

        for idx, m in ipairs(MODES) do
            local item = New("TextButton", { Parent = grp, Size = UDim2.new(1, 0, 0, itemH - 2), BackgroundColor3 = T.ElementHover, BackgroundTransparency = 1, LayoutOrder = idx })
            Corner(item, 5)
            local cur = obj.Mode == m
            New("TextLabel", {
                Parent = item, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0), Text = m,
                TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cur and Library.Theme.Accent or T.SubText,
            })
            if cur then
                local bar = New("Frame", { Parent = item, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(3, 12) })
                Corner(bar, 2); Library:Accent(bar)
            end
            item.MouseEnter:Connect(function() Tween(item, { BackgroundTransparency = 0.4 }, 0.12) end)
            item.MouseLeave:Connect(function() Tween(item, { BackgroundTransparency = 1 }, 0.12) end)
            item.MouseButton1Click:Connect(function()
                obj:SetMode(m)
                Library:_closePopup()
            end)
        end

        Tween(sc, { Scale = base }, 0.3, Enum.EasingStyle.Back)
        Tween(grp, { GroupTransparency = 0 }, 0.18)
        Tween(ps, { Transparency = 0.4 }, 0.18)
        local closed = false
        Library.Popup = {
            frame = pop,
            close = function()
                if closed then return end
                closed = true
                Tween(sc, { Scale = base * 0.92 }, 0.15)
                Tween(grp, { GroupTransparency = 1 }, 0.15)
                Tween(ps, { Transparency = 1 }, 0.15)
                task.delay(0.17, function() pop:Destroy() end)
            end,
        }
    end

    local pressStart, longPressed = 0, false
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch and Library.Mobile and not opts.Passive then
            pressStart, longPressed = os.clock(), false
            local t0 = pressStart
            task.delay(0.5, function()
                if pressStart == t0 and not longPressed then
                    longPressed = true
                    openModeMenu()
                end
            end)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if Library.Mobile and not opts.Passive then
            -- touch: tap flips the state (Toggle / Hold), hold 0.5s opens the mode menu
            pressStart = 0
            if longPressed then longPressed = false return end
            if obj.Mode ~= "Always" then obj:SetState(not obj.State) end
            return
        end
        if obj.Binding then return end
        obj.Binding = true
        updateButton()
        Tween(st, { Color = Library.Theme.Accent }, 0.2)
    end)
    btn.MouseButton2Click:Connect(function()
        if opts.Passive or obj.Binding then return end
        openModeMenu() -- right click: choose Hold / Toggle / Always
    end)
    btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = T.ElementHover }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = T.Element }, 0.15) end)

    Library:Connect(UIS.InputBegan, function(input, gp)
        if obj.Binding then
            local k
            if input.UserInputType == Enum.UserInputType.Keyboard then
                k = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                k = input.UserInputType
            else
                return
            end
            if k == Enum.KeyCode.Escape then k = nil end
            obj.Binding = false
            Library.LastBind = os.clock()
            Tween(st, { Color = T.Outline }, 0.2)
            obj:SetKey(k)
            return
        end
        if gp or opts.Passive or not obj.Key then return end
        if input.KeyCode == obj.Key or input.UserInputType == obj.Key then
            if obj.Mode == "Toggle" then obj:SetState(not obj.State)
            elseif obj.Mode == "Hold" then obj:SetState(true) end
        end
    end)
    Library:Connect(UIS.InputEnded, function(input)
        if opts.Passive or not obj.Key or obj.Mode ~= "Hold" then return end
        if input.KeyCode == obj.Key or input.UserInputType == obj.Key then obj:SetState(false) end
    end)

    obj.Key = opts.Default
    updateButton()
    obj:SetMode(obj.Mode, true)
    return obj
end

function Library:_closePopup()
    if self.Popup then
        local p = self.Popup
        self.Popup = nil
        p.close()
    end
end

function Library:_nextKbOrder()
    self._kbOrder = (self._kbOrder or 0) + 1
    return self._kbOrder
end

----------------------------------------------------------------------
-- built-in settings tab
----------------------------------------------------------------------
function WindowMT:_buildSettings()
    local lib = self.Library
    local tab = self:AddTab("Settings")
    self.SettingsTab = tab

    -- Menu -------------------------------------------------------------
    local menu = tab:AddSection("Menu", "Left")
    menu:AddToggle("UI_Watermark", { Text = "Show Watermark", Default = true, Callback = function(v) lib:SetWatermarkVisible(v) end })
    menu:AddToggle("UI_KeybindList", { Text = "Show Keybind List", Default = not lib.Mobile, Callback = function(v) lib:SetKeybindListVisible(v) end })
    menu:AddToggle("UI_Mobile", { Text = "Mobile Mode", Default = lib.Mobile, Callback = function(v) lib:SetMobile(v) end })
    menu:AddToggle("UI_ToggleBtn", { Text = "Show Menu Button", Default = lib._showToggleBtn, Callback = function(v) lib:SetToggleButtonVisible(v) end })
    menu:AddKeybind("UI_MenuKey", {
        Text = "Menu Keybind", Default = lib.ToggleKey, Passive = true, NoList = true,
        ChangedCallback = function(k) lib.ToggleKey = k or Enum.KeyCode.RightShift end,
    })
    menu:AddDropdown("UI_NotifyPos", {
        Text = "Notification Position", Values = lib.NotifyPositions, Default = lib.NotifyPosition,
        Callback = function(v)
            if v and v ~= lib.NotifyPosition then
                lib:SetNotifyPosition(v)
                lib:Notify("Notifications will appear here", 2.5, v)
            end
        end,
    })
    menu:AddSlider("UI_Scale", { Text = "UI Scale", Min = 70, Max = 130, Default = 100, Suffix = "%", Callback = function(v) self:SetScale(v / 100) end })
    menu:AddDivider()
    menu:AddButton({ Text = "Unload UI", Callback = function() lib:Unload() end })

    -- Appearance (themes + background) -----------------------------------
    local look = tab:AddSection("Appearance", "Left")
    look:AddDropdown("UI_Theme", {
        Text = "Theme", Values = lib.ThemeOrder, Default = lib.ThemeName,
        Callback = function(v) if v then lib:SetTheme(v) end end,
    })
    local bgInput = look:AddInput("UI_BgUrl", {
        Text = "Background image link", Placeholder = "https://... (.jpg / .png)", Default = self.InitialBg,
        Callback = function(v) self:SetBackground(v) end,
    })
    look:AddSlider("UI_BgDim", {
        Text = "Background Dim", Min = 0, Max = 100, Default = 45, Suffix = "%",
        Callback = function(v) self:SetBackgroundDim(v / 100) end,
    })
    look:AddSlider("UI_PanelAlpha", {
        Text = "Section Transparency", Min = 0, Max = 80, Default = 20, Suffix = "%",
        Callback = function(v) lib:SetPanelTransparency(v / 100) end,
    })
    look:AddButton({ Text = "Remove Background", Callback = function() bgInput:SetValue("") end })
    if self.InitialBg ~= "" then self:SetBackground(self.InitialBg) end

    -- Configs ----------------------------------------------------------
    local cfg = tab:AddSection("Configuration", "Right")
    local nameInput = cfg:AddInput("UI_ConfigName", { Text = "Config name", Placeholder = "my config", NoSave = true })
    local autoLabel
    local dd
    local function selected() return dd.Value end
    local function refreshAuto()
        local a = lib:GetAutoLoad()
        autoLabel:SetText("Auto load: " .. (a or "none"))
    end
    local function refreshList()
        dd:SetValues(lib:GetConfigs())
        refreshAuto()
    end
    local function report(ok, msg)
        lib:Notify(msg, 3, ok and "Config" or "Config error")
    end

    cfg:AddButton({ Text = "Create Config", Callback = function()
        local ok, msg = lib:SaveConfig(nameInput.Value)
        report(ok, msg)
        if ok then refreshList(); dd:SetValue(cleanName(nameInput.Value), true); nameInput:SetValue("") end
    end })
    cfg:AddDivider()
    dd = cfg:AddDropdown("UI_ConfigList", { Text = "Configs", Values = lib:GetConfigs(), NoSave = true })
    cfg:AddButton({ Text = "Load Config", Callback = function() report(lib:LoadConfig(selected())) end })
    local function needSelection()
        if not selected() then report(false, "No config selected"); return false end
        return true
    end
    cfg:AddButton({ Text = "Overwrite Config", Confirm = 3, Precheck = needSelection, Callback = function()
        report(lib:SaveConfig(selected()))
    end })
    cfg:AddButton({ Text = "Delete Config", Confirm = 3, Precheck = needSelection, Callback = function()
        local ok, msg = lib:DeleteConfig(selected())
        report(ok, msg)
        if ok then refreshList() end
    end })
    cfg:AddButton({ Text = "Refresh List", Callback = refreshList })
    cfg:AddDivider()
    local renameInput = cfg:AddInput("UI_ConfigRename", { Text = "Rename selected to", Placeholder = "new name", NoSave = true })
    cfg:AddButton({ Text = "Rename Config", Callback = function()
        local old = selected()
        local new = cleanName(renameInput.Value)
        local ok, msg = lib:RenameConfig(old, new)
        report(ok, msg)
        if ok then refreshList(); dd:SetValue(new, true); renameInput:SetValue("") end
    end })
    cfg:AddDivider()
    cfg:AddButton({ Text = "Set As Auto Load", Callback = function()
        local ok, msg = lib:SetAutoLoad(selected())
        report(ok, msg); refreshAuto()
    end })
    cfg:AddButton({ Text = "Clear Auto Load", Callback = function()
        local ok, msg = lib:ClearAutoLoad()
        report(ok, msg); refreshAuto()
    end })
    autoLabel = cfg:AddLabel("Auto load: none")
    refreshAuto()
end

env.__SmoothUI = Library
return Library
