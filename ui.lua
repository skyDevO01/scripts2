--!nocheck
--[[
    GlassUI  -  black & white glass UI library for Roblox
    Elements : Toggle, Keybind, Button, Dropdown (single / multi), Slider, Input, Label
    Configs  : save / load / rename / delete / overwrite (needs an executor with file functions,
               otherwise falls back to in-memory storage for the session)
    Icons    : https://github.com/latte-soft/lucide-roblox
]]

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local Lighting      = game:GetService("Lighting")
local LocalPlayer   = Players.LocalPlayer

local function Signal()
    local sig = { _h = {} }
    function sig:Connect(fn)
        local h = { fn = fn }
        table.insert(self._h, h)
        return { Disconnect = function() h.fn = nil end }
    end
    function sig:Fire(...)
        for _, h in ipairs(self._h) do
            if h.fn then
                local ok, err = pcall(h.fn, ...)
                if not ok then warn("[GlassUI] OnUnload error: " .. tostring(err)) end
            end
        end
    end
    function sig:Clear() table.clear(self._h) end
    return sig
end

local Library = {
    Flags = {}, Options = {}, Windows = {}, Folder = "GlassUI", Version = "1.1.0", _blurs = {},
    OnUnload = Signal(), Unloaded = false, Listening = false,
}
local connections = {}

------------------------------------------------------------------------------
-- Theme / helpers
------------------------------------------------------------------------------
local White, Black = Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)
local Theme = { Bg = Color3.fromRGB(8, 8, 8), Dim = Color3.fromRGB(120, 120, 120) }
local FONT, FONT_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function New(class, props, children)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    if o:IsA("GuiButton") then o.AutoButtonColor = false end
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function fire(cb, ...)
    if not cb then return end
    task.spawn(function(...)
        local ok, err = pcall(cb, ...)
        if not ok then warn("[GlassUI] callback error: " .. tostring(err)) end
    end, ...)
end

local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function Stroke(p, tr, th)
    return New("UIStroke", { Color = White, Transparency = tr or 0.9, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end

local function Label(parent, text, props)
    local l = New("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextColor3 = White, Font = FONT, TextSize = 13,
        TextXAlignment = Left, Size = UDim2.fromScale(1, 1), Parent = parent,
    })
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

local function nextOrder(c) c._order = (c._order or 0) + 1 return c._order end

------------------------------------------------------------------------------
-- Lucide icons
------------------------------------------------------------------------------
local Lucide
do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
    end)
    if ok and res then Lucide = res else warn("[GlassUI] Lucide icons failed to load; icons will be hidden.") end
end

local function applyIcon(img, name)
    if not Lucide or not name then img.Visible = false return end
    local ok, a, b, c = pcall(Lucide.GetAsset, name, 48)
    if not ok or not a then img.Visible = false return end
    if type(a) == "table" then
        img.Image, img.ImageRectOffset, img.ImageRectSize = a.Url or a.Image, a.ImageRectOffset, a.ImageRectSize
    else
        img.Image, img.ImageRectSize, img.ImageRectOffset = a, b, c
    end
    img.Visible = true
end

local function Icon(parent, name, px, props)
    local img = New("ImageLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(px, px), ImageColor3 = White, Parent = parent,
    })
    for k, v in pairs(props or {}) do img[k] = v end
    applyIcon(img, name)
    return img
end
Library.Icon = Icon

------------------------------------------------------------------------------
-- Root gui
------------------------------------------------------------------------------
local function getGui()
    if Library.Gui and Library.Gui.Parent then return Library.Gui end
    local gui = New("ScreenGui", {
        Name = "GlassUI_" .. HttpService:GenerateGUID(false):sub(1, 6), ResetOnSpawn = false,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
    })
    local ok = false
    if gethui then ok = pcall(function() gui.Parent = gethui() end) end
    if not ok or not gui.Parent then ok = pcall(function() gui.Parent = game:GetService("CoreGui") end) end
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    Library.Gui = gui
    return gui
end

------------------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------------------
function Library:Notify(o)
    o = o or {}
    local gui = getGui()
    if not self._notif then
        self._notif = New("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.fromOffset(290, 500), BackgroundTransparency = 1, Parent = gui,
        }, { New("UIListLayout", {
            VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    local dur = o.Duration or 4
    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = self._notif })
    local card = New("CanvasGroup", {
        Position = UDim2.new(1, 40, 0, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg,
        BackgroundTransparency = 0.1, GroupTransparency = 1, Parent = wrap,
    })
    Corner(card, 10) Stroke(card, 0.8)
    Icon(card, o.Icon or "info", 18, { Position = UDim2.fromOffset(14, 10) })
    Label(card, o.Title or "Notice", { Position = UDim2.fromOffset(42, 8), Size = UDim2.new(1, -54, 0, 18), Font = FONT_BOLD })
    Label(card, o.Content or "", {
        Position = UDim2.fromOffset(42, 26), Size = UDim2.new(1, -54, 0, 26), TextSize = 12,
        TextTransparency = 0.4, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
    })
    local bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = White, BackgroundTransparency = 0.6, Parent = card,
    })
    tween(card, { Position = UDim2.new(), GroupTransparency = 0 }, 0.45)
    tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
    task.delay(dur, function()
        tween(card, { Position = UDim2.new(1, 40, 0, 0), GroupTransparency = 1 }, 0.35)
        task.wait(0.35)
        tween(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.25)
        task.wait(0.25)
        wrap:Destroy()
    end)
end

------------------------------------------------------------------------------
-- Config storage
------------------------------------------------------------------------------
local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    and type(listfiles) == "function" and type(makefolder) == "function" and type(isfolder) == "function"
    and type(delfile) == "function"
local mem = {}

local function sanitize(n)
    n = (tostring(n or ""):gsub("[^%w%-%_ ]", ""))
    return n:match("^%s*(.-)%s*$")
end
local function fpath(name) return Library.Folder .. "/" .. name .. ".json" end
local function ensure() if hasFS and not isfolder(Library.Folder) then makefolder(Library.Folder) end end

local fs = {}
function fs.exists(n) if hasFS then ensure() return isfile(fpath(n)) end return mem[n] ~= nil end
function fs.read(n) if hasFS then return readfile(fpath(n)) end return mem[n] end
function fs.write(n, raw) if hasFS then ensure() writefile(fpath(n), raw) else mem[n] = raw end end
function fs.delete(n) if hasFS then delfile(fpath(n)) else mem[n] = nil end end

function Library:SetFolder(name) self.Folder = name end
function Library:ConfigExists(name) return fs.exists(sanitize(name)) end

function Library:ListConfigs()
    local out = {}
    if hasFS then
        ensure()
        for _, f in ipairs(listfiles(self.Folder)) do
            local n = tostring(f):match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    else
        for n in pairs(mem) do table.insert(out, n) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

function Library:SaveConfig(name)
    name = sanitize(name)
    if name == "" then return false, "Invalid config name" end
    local flags = {}
    for flag, opt in pairs(self.Options) do
        if opt.Get then flags[flag] = opt:Get() end
    end
    local ok, err = pcall(function() fs.write(name, HttpService:JSONEncode({ Version = 1, Flags = flags })) end)
    if not ok then return false, tostring(err) end
    return true
end

function Library:LoadConfig(name)
    name = sanitize(name)
    if not fs.exists(name) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(fs.read(name)) end)
    if not ok or type(data) ~= "table" or type(data.Flags) ~= "table" then return false, "Config is corrupted" end
    for flag, val in pairs(data.Flags) do
        local opt = self.Options[flag]
        if opt and opt.Set then pcall(opt.Set, opt, val) end
    end
    return true
end

function Library:DeleteConfig(name)
    name = sanitize(name)
    if not fs.exists(name) then return false, "Config not found" end
    local ok, err = pcall(fs.delete, name)
    return ok, not ok and tostring(err) or nil
end

function Library:RenameConfig(old, new)
    old, new = sanitize(old), sanitize(new)
    if new == "" then return false, "Enter a new name first" end
    if not fs.exists(old) then return false, "Config not found" end
    if old == new then return false, "Name is unchanged" end
    if fs.exists(new) then return false, "'" .. new .. "' already exists" end
    local ok, err = pcall(function() fs.write(new, fs.read(old)) fs.delete(old) end)
    return ok, not ok and tostring(err) or nil
end

------------------------------------------------------------------------------
-- Element building blocks
------------------------------------------------------------------------------
local Elements = {}
Elements.__index = Elements

local function register(flag, obj)
    if flag then Library.Options[flag] = obj end
end
local function sync(flag, v)
    if flag then Library.Flags[flag] = v end
end

local function Row(self, height)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 36), BackgroundColor3 = White, BackgroundTransparency = 0.95,
        ClipsDescendants = true, LayoutOrder = nextOrder(self), Parent = self.Holder,
    })
    Corner(f, 8) Stroke(f, 0.92)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.55), Parent = f })
    connect(f.MouseEnter, function() tween(f, { BackgroundTransparency = 0.91 }, 0.2) end)
    connect(f.MouseLeave, function() tween(f, { BackgroundTransparency = 0.95 }, 0.3) end)
    return f
end

local function Hit(parent, size)
    return New("TextButton", { BackgroundTransparency = 1, Text = "", Size = size or UDim2.fromScale(1, 1), Parent = parent })
end

local function Ripple(f, x, y)
    local c = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x - f.AbsolutePosition.X, y - f.AbsolutePosition.Y),
        Size = UDim2.fromOffset(0, 0), BackgroundColor3 = White, BackgroundTransparency = 0.8, Parent = f,
    })
    Corner(c, 999)
    local d = math.max(f.AbsoluteSize.X, f.AbsoluteSize.Y) * 2.2
    tween(c, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.55)
    task.delay(0.6, function() c:Destroy() end)
end

function Elements:AddSection(name)
    local sec = setmetatable({}, Elements)
    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = nextOrder(self), Parent = self.Holder,
    }, { New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
    Label(wrap, string.upper(name or "Section"), {
        Size = UDim2.new(1, 0, 0, 16), TextSize = 11, TextTransparency = 0.5, Font = FONT_BOLD, LayoutOrder = 0,
    })
    sec.Holder = wrap
    return sec
end

function Elements:AddLabel(text)
    local l = Label(self.Holder, text, {
        Size = UDim2.new(1, 0, 0, 20), TextTransparency = 0.45, TextSize = 12, TextWrapped = true,
        LayoutOrder = nextOrder(self),
    })
    return { SetText = function(_, t) l.Text = t end }
end

------------------------------------------------------------------------------
-- Toggle
------------------------------------------------------------------------------
function Elements:AddToggle(o)
    local t = { Type = "Toggle", Value = false }
    local r = Row(self, 36)
    Label(r, o.Name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0) })
    local sw = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20),
        BackgroundColor3 = White, BackgroundTransparency = 0.85, Parent = r,
    })
    Corner(sw, 10) Stroke(sw, 0.8)
    local knob = New("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = White, Parent = sw })
    Corner(knob, 7)
    local hit = Hit(r)

    function t:Get() return self.Value end
    function t:Set(v, silent)
        v = v and true or false
        self.Value = v
        tween(sw, { BackgroundTransparency = v and 0 or 0.85 }, 0.3)
        tween(knob, { Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = v and Black or White }, 0.3, Enum.EasingStyle.Back)
        sync(o.Flag, v)
        if not silent then fire(o.Callback, v) end
    end
    connect(hit.MouseButton1Down, function(x, y) Ripple(r, x, y) end)
    connect(hit.MouseButton1Click, function() t:Set(not t.Value) end)
    t:Set(o.Default, true)
    register(o.Flag, t)
    return t
end

------------------------------------------------------------------------------
-- Button
------------------------------------------------------------------------------
function Elements:AddButton(o)
    local b = { Type = "Button" }
    local r = Row(self, 36)
    local lbl = Label(r, o.Name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
    if o.Icon then Icon(r, o.Icon, 16, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0) }) end
    local hit = Hit(r)
    connect(hit.MouseButton1Down, function(x, y)
        Ripple(r, x, y)
        tween(r, { BackgroundTransparency = 0.85 }, 0.1)
    end)
    connect(hit.MouseButton1Click, function()
        tween(r, { BackgroundTransparency = 0.91 }, 0.3)
        fire(o.Callback)
    end)
    function b:SetText(t) lbl.Text = t end
    return b
end

------------------------------------------------------------------------------
-- Slider
------------------------------------------------------------------------------
function Elements:AddSlider(o)
    local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
    local dec = #(tostring(inc):match("%.(%d+)") or "")
    local s = { Type = "Slider", Value = min }
    local r = Row(self, 48)
    Label(r, o.Name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.6, 0, 0, 20) })
    local val = Label(r, "", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.new(0.4, 0, 0, 20),
        TextXAlignment = Right, TextTransparency = 0.4,
    })
    local bar = New("Frame", {
        Position = UDim2.new(0, 12, 0, 33), Size = UDim2.new(1, -24, 0, 5), BackgroundColor3 = White,
        BackgroundTransparency = 0.85, Parent = r,
    })
    Corner(bar, 3)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = White, Parent = bar })
    Corner(fill, 3)
    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = White, Parent = fill,
    })
    Corner(knob, 8)
    local hit = Hit(r, UDim2.new(1, 0, 1, -22))
    hit.Position = UDim2.fromOffset(0, 22)

    local function round(v)
        v = math.clamp(v, min, max)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        return math.clamp(tonumber(string.format("%." .. dec .. "f", v)), min, max)
    end
    function s:Get() return self.Value end
    function s:Set(v, silent)
        v = round(tonumber(v) or min)
        self.Value = v
        local a = max == min and 0 or (v - min) / (max - min)
        tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.12, Enum.EasingStyle.Sine)
        val.Text = tostring(v) .. (o.Suffix or "")
        sync(o.Flag, v)
        if not silent then fire(o.Callback, v) end
    end

    local dragging = false
    local function update(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = round(min + (max - min) * a)
        if v ~= s.Value then s:Set(v) end
    end
    connect(hit.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tween(knob, { Size = UDim2.fromOffset(15, 15) }, 0.2, Enum.EasingStyle.Back)
            update(i.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(knob, { Size = UDim2.fromOffset(11, 11) }, 0.25)
        end
    end)
    s:Set(o.Default or min, true)
    register(o.Flag, s)
    return s
end

------------------------------------------------------------------------------
-- Input box
------------------------------------------------------------------------------
function Elements:AddInput(o)
    local i = { Type = "Input", Value = "" }
    local r = Row(self, 36)
    Label(r, o.Name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, -12, 1, 0) })
    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.6, -16, 0, 24),
        BackgroundColor3 = White, BackgroundTransparency = 0.92, Text = "", PlaceholderText = o.Placeholder or "Type here...",
        PlaceholderColor3 = Theme.Dim, TextColor3 = White, Font = FONT, TextSize = 12, ClearTextOnFocus = false,
        TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
    })
    Corner(box, 6)
    local st = Stroke(box, 0.9)
    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })
    connect(box.Focused, function()
        tween(st, { Transparency = 0.4 }, 0.25) tween(box, { BackgroundTransparency = 0.86 }, 0.25)
    end)
    function i:Get() return self.Value end
    function i:Set(v, silent)
        if o.Numeric then
            local n = tonumber(v)
            if not n then box.Text = tostring(self.Value) return end
            v = n
        end
        self.Value = v
        box.Text = tostring(v)
        sync(o.Flag, v)
        if not silent then fire(o.Callback, v) end
    end
    connect(box.FocusLost, function()
        tween(st, { Transparency = 0.9 }, 0.3) tween(box, { BackgroundTransparency = 0.92 }, 0.3)
        i:Set(box.Text)
    end)
    i:Set(o.Default or (o.Numeric and 0 or ""), true)
    register(o.Flag, i)
    return i
end

------------------------------------------------------------------------------
-- Dropdown (single / multi)
------------------------------------------------------------------------------
function Elements:AddDropdown(o)
    local multi = o.Multi and true or false
    local HEAD, ITEM, GAP, MAXV = 36, 28, 3, 5
    local d = { Type = "Dropdown", Multi = multi, Options = {}, Lookup = {}, Buttons = {}, Selected = {}, Open = false }
    local r = Row(self, HEAD)
    Label(r, o.Name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, -12, 0, HEAD) })
    local valueLbl = Label(r, "None", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0.55, -40, 0, HEAD),
        TextXAlignment = Right, TextTransparency = 0.45, TextTruncate = Enum.TextTruncate.AtEnd, TextSize = 12,
    })
    local arrow = Icon(r, "chevron-down", 16, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, HEAD / 2) })
    local list = New("ScrollingFrame", {
        Position = UDim2.fromOffset(6, HEAD + 4), Size = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1,
        ScrollBarThickness = 2, ScrollBarImageColor3 = White, ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = r,
    }, { New("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local head = Hit(r, UDim2.new(1, 0, 0, HEAD))

    local function listHeight()
        local n = math.min(#d.Options, MAXV)
        return n * ITEM + math.max(n - 1, 0) * GAP
    end

    function d:Get()
        if not multi then return self.Value end
        local out = {}
        for _, n in ipairs(self.Options) do if self.Selected[n] then table.insert(out, n) end end
        return out
    end
    function d:_paint()
        for name, b in pairs(self.Buttons) do
            local sel = multi and self.Selected[name] or (not multi and self.Value == name)
            tween(b, { BackgroundTransparency = sel and 0.08 or 1, TextColor3 = sel and Black or White }, 0.2)
        end
        local v = self:Get()
        valueLbl.Text = multi and (#v > 0 and table.concat(v, ", ") or "None") or (v or "None")
    end
    function d:_commit(silent)
        self:_paint()
        sync(o.Flag, self:Get())
        if not silent then fire(o.Callback, self:Get()) end
    end
    function d:Set(v, silent)
        if multi then
            local sel = {}
            if type(v) == "table" then
                for k, val in pairs(v) do
                    local n = type(k) == "number" and val or (val and k)
                    if n and self.Lookup[n] then sel[n] = true end
                end
            end
            self.Selected = sel
        else
            self.Value = (v ~= nil and self.Lookup[v]) and v or nil
        end
        self:_commit(silent)
    end
    function d:Toggle(state)
        if state == nil then state = not self.Open end
        self.Open = state
        tween(r, { Size = UDim2.new(1, 0, 0, state and (HEAD + 12 + listHeight()) or HEAD) }, 0.35)
        tween(arrow, { Rotation = state and 180 or 0 }, 0.35)
    end
    function d:Refresh(options)
        options = options or self.Options
        for _, b in pairs(self.Buttons) do b:Destroy() end
        self.Buttons, self.Options, self.Lookup = {}, {}, {}
        for idx, n in ipairs(options) do
            n = tostring(n)
            table.insert(self.Options, n)
            self.Lookup[n] = true
            local b = New("TextButton", {
                Size = UDim2.new(1, 0, 0, ITEM), BackgroundColor3 = White, BackgroundTransparency = 1, Text = n,
                TextColor3 = White, Font = FONT, TextSize = 12, TextXAlignment = Left, LayoutOrder = idx, Parent = list,
            })
            Corner(b, 6)
            New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = b })
            self.Buttons[n] = b
            connect(b.MouseEnter, function() if b.BackgroundTransparency > 0.5 then tween(b, { BackgroundTransparency = 0.9 }, 0.15) end end)
            connect(b.MouseLeave, function() self:_paint() end)
            connect(b.MouseButton1Click, function()
                if multi then
                    self.Selected[n] = (not self.Selected[n]) or nil
                    self:_commit()
                else
                    self.Value = n
                    self:_commit()
                    self:Toggle(false)
                end
            end)
        end
        if multi then
            for n in pairs(self.Selected) do if not self.Lookup[n] then self.Selected[n] = nil end end
        elseif self.Value and not self.Lookup[self.Value] then
            self.Value = nil
        end
        list.Size = UDim2.new(1, -12, 0, listHeight())
        self:_paint()
        if self.Open then self:Toggle(true) end
    end

    connect(head.MouseButton1Click, function() d:Toggle() end)
    d:Refresh(o.Options or {})
    if o.Default ~= nil then d:Set(o.Default, true) end
    sync(o.Flag, d:Get())
    register(o.Flag, d)
    return d
end

------------------------------------------------------------------------------
-- Keybind
------------------------------------------------------------------------------
local function keyName(k)
    if not k then return "None" end
    if k.EnumType == Enum.UserInputType then
        return ({ MouseButton2 = "MB2", MouseButton3 = "MB3" })[k.Name] or k.Name
    end
    return k.Name
end

function Elements:AddKeybind(o)
    -- Mode: "Press" (callback()), "Toggle" (callback(state)), "Hold" (callback(true/false))
    local k = { Type = "Keybind", Key = nil, Mode = o.Mode or "Press", State = false, Listening = false }
    local r = Row(self, 36)
    Label(r, o.Name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -90, 1, 0) })
    local btn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = White, BackgroundTransparency = 0.9, Text = "None",
        TextColor3 = White, Font = FONT, TextSize = 12, Parent = r,
    })
    Corner(btn, 6) Stroke(btn, 0.88)
    New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = btn })

    local function parse(v)
        if typeof(v) == "EnumItem" then return v end
        if type(v) ~= "string" or v == "None" then return nil end
        local ok, e = pcall(function() return Enum.KeyCode[v] end)
        if ok and e then return e end
        ok, e = pcall(function() return Enum.UserInputType[v] end)
        if ok and e then return e end
    end
    local function matches(input)
        local key = k.Key
        if not key then return false end
        if key.EnumType == Enum.KeyCode then return input.KeyCode == key end
        return input.UserInputType == key
    end

    function k:Get() return self.Key and self.Key.Name or "None" end
    function k:Set(v, silent)
        self.Key = parse(v)
        btn.Text = keyName(self.Key)
        tween(btn, { BackgroundTransparency = 0.9 }, 0.25)
        sync(o.Flag, self:Get())
        if not silent then fire(o.Changed, self.Key) end
    end
    function k:GetState() return self.State end

    connect(btn.MouseButton1Click, function()
        k.Listening = true
        Library.Listening = true
        btn.Text = "..."
        tween(btn, { BackgroundTransparency = 0.7 }, 0.2)
    end)
    connect(UIS.InputBegan, function(input)
        if k.Listening then
            local t = input.UserInputType
            task.defer(function() Library.Listening = false end)
            if t == Enum.UserInputType.Keyboard then
                k.Listening = false
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then k:Set(nil)
                else k:Set(input.KeyCode) end
            elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
                k.Listening = false
                k:Set(t)
            end
            return
        end
        -- gameProcessed is intentionally ignored: games often sink keys like E/F via ContextActionService
        if not k.Key or UIS:GetFocusedTextBox() or not matches(input) then return end
        if k.Mode == "Toggle" then
            k.State = not k.State
            fire(o.Callback, k.State)
        elseif k.Mode == "Hold" then
            k.State = true
            fire(o.Callback, true)
        else
            fire(o.Callback)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if k.Mode == "Hold" and k.State and matches(input) then
            k.State = false
            fire(o.Callback, false)
        end
    end)
    k:Set(o.Default, true)
    register(o.Flag, k)
    return k
end

------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.ConfigFolder then self.Folder = cfg.ConfigFolder end
    local gui = getGui()
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    if type(toggleKey) == "string" then toggleKey = Enum.KeyCode[toggleKey] end
    local mode = tostring((getgenv and getgenv().ui_mode) or cfg.Mode or "Pc"):lower()
    local isMobile = mode == "mobile"
    local Window = { Tabs = {}, Visible = false, ToggleKey = toggleKey, Mobile = isMobile, OnUnload = Library.OnUnload }

    local main = New("CanvasGroup", {
        Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = cfg.Size or (isMobile and UDim2.fromOffset(500, 330) or UDim2.fromOffset(640, 440)), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.1,
        GroupTransparency = 1, Parent = gui,
    })
    Corner(main, 14)
    local rim = Stroke(main, 0.7)
    New("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 0.2) }), Parent = rim })
    local scale = New("UIScale", { Scale = 0.92, Parent = main })
    -- glossy sheen
    local gloss = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, BackgroundTransparency = 0.93, Parent = main })
    New("UIGradient", { Rotation = 60, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.85), NumberSequenceKeypoint.new(1, 1) }), Parent = gloss })

    -- top bar
    local top = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = main })
    Icon(top, cfg.Icon or "hexagon", 18, { Position = UDim2.fromOffset(16, 14) })
    Label(top, string.format('<font face="GothamBold">%s</font>  <font color="rgb(120,120,120)">%s</font>',
        cfg.Title or "Glass UI", cfg.Subtitle or ""), {
        Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -100, 1, 0), RichText = true,
    })
    New("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = White, BackgroundTransparency = 0.92, Parent = main })
    local close = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 23), Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = White, BackgroundTransparency = 1, Text = "", Parent = top,
    })
    Corner(close, 8)
    Icon(close, "minus", 16, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    connect(close.MouseEnter, function() tween(close, { BackgroundTransparency = 0.88 }, 0.2) end)
    connect(close.MouseLeave, function() tween(close, { BackgroundTransparency = 1 }, 0.25) end)
    connect(close.MouseButton1Click, function() Window:Toggle(false) end)

    -- sidebar + content
    New("Frame", { Position = UDim2.fromOffset(150, 47), Size = UDim2.new(0, 1, 1, -47), BackgroundColor3 = White, BackgroundTransparency = 0.92, Parent = main })
    local tabHolder = New("Frame", { Position = UDim2.fromOffset(10, 59), Size = UDim2.new(0, 130, 1, -71), BackgroundTransparency = 1, Parent = main })
    local pill = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = White, BackgroundTransparency = 0.88, Visible = false, Parent = tabHolder })
    Corner(pill, 8) Stroke(pill, 0.85)
    local content = New("Frame", {
        Position = UDim2.fromOffset(151, 47), Size = UDim2.new(1, -151, 1, -47), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = main,
    })

    -- dragging
    local dragging, dragStart, startPos
    connect(top.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            tween(main, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) }, 0.08, Enum.EasingStyle.Sine)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    -- blur behind window
    local blur
    if cfg.Blur ~= false then
        blur = New("BlurEffect", { Name = "GlassBlur", Size = 0, Parent = Lighting })
        table.insert(Library._blurs, blur)
    end

    -- mobile: draggable floating button that shows / hides the window
    local mobileIcon
    if isMobile then
        local tb = New("TextButton", {
            Name = "MobileToggle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 46, 0.35, 0),
            Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.15, Text = "",
            ZIndex = 100, Parent = gui,
        })
        Corner(tb, 22)
        local ts = Stroke(tb, 0.7)
        New("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.7) }), Parent = ts })
        mobileIcon = Icon(tb, "eye-off", 20, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        local bdrag, bmoved, bstart, bpos = false, false, nil, nil
        connect(tb.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                bdrag, bmoved, bstart, bpos = true, false, i.Position, tb.Position
                tween(tb, { Size = UDim2.fromOffset(38, 38) }, 0.15)
            end
        end)
        connect(UIS.InputChanged, function(i)
            if bdrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - bstart
                if d.Magnitude > 6 then bmoved = true end
                if bmoved then
                    tween(tb, { Position = UDim2.new(bpos.X.Scale, bpos.X.Offset + d.X, bpos.Y.Scale, bpos.Y.Offset + d.Y) }, 0.06, Enum.EasingStyle.Sine)
                end
            end
        end)
        connect(UIS.InputEnded, function(i)
            if bdrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                bdrag = false
                tween(tb, { Size = UDim2.fromOffset(44, 44) }, 0.3, Enum.EasingStyle.Back)
                if not bmoved then Window:Toggle() end
            end
        end)
    end

    function Window:Toggle(v)
        if v == nil then v = not self.Visible end
        self.Visible = v
        if mobileIcon then applyIcon(mobileIcon, v and "eye-off" or "eye") end
        if v then
            main.Visible = true
            tween(main, { GroupTransparency = 0 }, 0.4)
            tween(scale, { Scale = 1 }, 0.5, Enum.EasingStyle.Back)
        else
            tween(main, { GroupTransparency = 1 }, 0.25)
            tween(scale, { Scale = 0.94 }, 0.25)
            task.delay(0.26, function() if not self.Visible then main.Visible = false end end)
        end
        if blur then tween(blur, { Size = v and (cfg.BlurSize or 14) or 0 }, 0.4) end
    end
    connect(UIS.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Window.ToggleKey
            and not Library.Listening and not UIS:GetFocusedTextBox() then
            Window:Toggle()
        end
    end)

    ---------------------------------------------------------------- tabs
    function Window:AddTab(o)
        o = type(o) == "string" and { Name = o } or (o or {})
        local Tab = setmetatable({}, Elements)
        local idx = #self.Tabs + 1
        local btn = New("TextButton", {
            Position = UDim2.fromOffset(0, (idx - 1) * 38), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
            Text = "", Parent = tabHolder,
        })
        local ic = Icon(btn, o.Icon, 16, { Position = UDim2.new(0, 10, 0.5, -8), ImageTransparency = 0.5 })
        local lbl = Label(btn, o.Name or "Tab", { Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0), TextTransparency = 0.5 })
        local group = New("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = content })
        local page = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = White,
            ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = group,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
            New("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16) }),
        })
        Tab.Holder, Tab.Group = page, group

        local function setActive(a)
            tween(lbl, { TextTransparency = a and 0 or 0.5 }, 0.3)
            tween(ic, { ImageTransparency = a and 0 or 0.5 }, 0.3)
        end
        function Tab:Select()
            if Window.Current == self then return end
            local prev = Window.Current
            Window.Current = self
            if prev then
                tween(prev.Group, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -10) }, 0.2)
                prev._setActive(false)
                task.delay(0.21, function() if Window.Current ~= prev then prev.Group.Visible = false end end)
            end
            group.Position = UDim2.fromOffset(0, 16)
            group.Visible = true
            tween(group, { GroupTransparency = 0, Position = UDim2.new() }, 0.4)
            pill.Visible = true
            tween(pill, { Position = UDim2.fromOffset(0, (idx - 1) * 38) }, 0.35, Enum.EasingStyle.Quint)
            setActive(true)
        end
        Tab._setActive = setActive
        connect(btn.MouseButton1Click, function() Tab:Select() end)
        connect(btn.MouseEnter, function() if Window.Current ~= Tab then tween(lbl, { TextTransparency = 0.25 }, 0.2) end end)
        connect(btn.MouseLeave, function() if Window.Current ~= Tab then tween(lbl, { TextTransparency = 0.5 }, 0.25) end end)

        table.insert(self.Tabs, Tab)
        if idx == 1 then pill.Position = UDim2.fromOffset(0, 0) Tab:Select() end
        return Tab
    end

    ---------------------------------------------------------------- confirm modal
    function Window:Confirm(title, text, onYes, yesText)
        local ov = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Black, BackgroundTransparency = 1, Text = "", ZIndex = 50, Parent = main })
        tween(ov, { BackgroundTransparency = 0.45 }, 0.25)
        local card = New("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 132),
            BackgroundColor3 = Color3.fromRGB(14, 14, 14), BackgroundTransparency = 0.05, GroupTransparency = 1, Parent = ov,
        })
        Corner(card, 12) Stroke(card, 0.8)
        local cs = New("UIScale", { Scale = 0.9, Parent = card })
        Label(card, title, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 20), Font = FONT_BOLD, TextSize = 14 })
        Label(card, text, { Position = UDim2.fromOffset(16, 36), Size = UDim2.new(1, -32, 0, 40), TextWrapped = true, TextSize = 12, TextTransparency = 0.4, TextYAlignment = Enum.TextYAlignment.Top })
        tween(card, { GroupTransparency = 0 }, 0.3)
        tween(cs, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
        local function dismiss()
            tween(ov, { BackgroundTransparency = 1 }, 0.2)
            tween(card, { GroupTransparency = 1 }, 0.2)
            tween(cs, { Scale = 0.92 }, 0.2)
            task.delay(0.22, function() ov:Destroy() end)
        end
        local function mk(text2, x, solid)
            local b = New("TextButton", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, -14), Size = UDim2.new(0.5, -22, 0, 30),
                BackgroundColor3 = White, BackgroundTransparency = solid and 0.05 or 0.9, Text = text2,
                TextColor3 = solid and Black or White, Font = FONT_BOLD, TextSize = 12, Parent = card,
            })
            Corner(b, 8)
            return b
        end
        local no, yes = mk("Cancel", 16, false), mk(yesText or "Confirm", 158, true)
        connect(no.MouseButton1Click, dismiss)
        connect(yes.MouseButton1Click, function() dismiss() fire(onYes) end)
    end

    ---------------------------------------------------------------- config tab
    function Window:AddConfigTab(o)
        o = o or {}
        local tab = self:AddTab({ Name = o.Name or "Config", Icon = o.Icon or "settings" })
        local sec = tab:AddSection("Configurations")
        local nameBox = sec:AddInput({ Name = "Config Name", Placeholder = "my config" })
        local list = sec:AddDropdown({ Name = "Saved Configs", Options = Library:ListConfigs() })
        local function refresh() list:Refresh(Library:ListConfigs()) end
        local function note(icon, title, msg) Library:Notify({ Icon = icon, Title = title, Content = msg }) end
        local function selected()
            local s = list:Get()
            if not s then note("triangle-alert", "Config", "Select a config from the list first") end
            return s
        end
        local function save(name)
            local ok, err = Library:SaveConfig(name)
            if ok then
                refresh() list:Set(sanitize(name), true)
                note("check", "Config saved", "'" .. sanitize(name) .. "' was saved")
            else
                note("circle-x", "Save failed", tostring(err))
            end
        end

        -- double-click protection: 1st click arms the button with a 3-2-1 countdown, 2nd click confirms, timeout cancels
        local function makeArm(btn, baseText)
            local current
            return function(key, armText, action)
                if current and current.key == key then
                    current = nil
                    btn:SetText(baseText)
                    action()
                    return
                end
                local token = { key = key }
                current = token
                task.spawn(function()
                    for i = 3, 1, -1 do
                        if current ~= token then return end
                        btn:SetText(armText .. " " .. i .. "...")
                        task.wait(1)
                    end
                    if current == token then
                        current = nil
                        btn:SetText(baseText)
                    end
                end)
            end
        end

        local createBtn, createArm
        createBtn = sec:AddButton({ Name = "Create / Save Config", Icon = "save", Callback = function()
            local n = sanitize(nameBox:Get())
            if n == "" then return note("triangle-alert", "Config", "Enter a config name first") end
            if Library:ConfigExists(n) then
                createArm(n, "Are you sure to overwrite?", function() save(n) end)
            else
                save(n)
            end
        end })
        createArm = makeArm(createBtn, "Create / Save Config")

        local overwriteBtn, overwriteArm
        overwriteBtn = sec:AddButton({ Name = "Overwrite Selected", Icon = "file-pen", Callback = function()
            local s = selected() if not s then return end
            overwriteArm(s, "Are you sure to overwrite?", function() save(s) end)
        end })
        overwriteArm = makeArm(overwriteBtn, "Overwrite Selected")
        sec:AddButton({ Name = "Load Selected", Icon = "download", Callback = function()
            local s = selected() if not s then return end
            local ok, err = Library:LoadConfig(s)
            if ok then note("check", "Config loaded", "'" .. s .. "' applied") else note("circle-x", "Load failed", tostring(err)) end
        end })
        sec:AddButton({ Name = "Rename Selected  (uses Config Name)", Icon = "pencil", Callback = function()
            local s = selected() if not s then return end
            local new = sanitize(nameBox:Get())
            local ok, err = Library:RenameConfig(s, new)
            if ok then
                refresh() list:Set(new, true) nameBox:Set("", true)
                note("check", "Config renamed", "'" .. s .. "' is now '" .. new .. "'")
            else
                note("circle-x", "Rename failed", tostring(err))
            end
        end })
        local deleteBtn, deleteArm
        deleteBtn = sec:AddButton({ Name = "Delete Selected", Icon = "trash-2", Callback = function()
            local s = selected() if not s then return end
            deleteArm(s, "Are you sure to delete?", function()
                local ok, err = Library:DeleteConfig(s)
                if ok then refresh() note("check", "Config deleted", "'" .. s .. "' removed") else note("circle-x", "Delete failed", tostring(err)) end
            end)
        end })
        deleteArm = makeArm(deleteBtn, "Delete Selected")
        sec:AddButton({ Name = "Refresh List", Icon = "refresh-cw", Callback = refresh })
        local ui = tab:AddSection("Interface")
        ui.Holder.LayoutOrder = 0   -- show above Configurations
        local uiKey
        uiKey = ui:AddKeybind({
            Name = "UI Toggle Key", Default = self.ToggleKey, Mode = "Press", Flag = "ui_toggle_key",
            Changed = function(key)
                -- the window key must be a keyboard key; fall back to RightShift if cleared / mouse button
                if key and key.EnumType == Enum.KeyCode then
                    self.ToggleKey = key
                    note("keyboard", "UI keybind", "Toggle key set to " .. key.Name)
                else
                    self.ToggleKey = Enum.KeyCode.RightShift
                    uiKey:Set(Enum.KeyCode.RightShift, true)
                    note("triangle-alert", "UI keybind", "Reset to RightShift (keyboard keys only)")
                end
            end,
        })
        ui:AddButton({ Name = "Unload UI", Icon = "power", Callback = function()
            self:Confirm("Unload UI?", "This closes the interface and runs all OnUnload handlers.", function() Library:Unload() end, "Unload")
        end })
        if not hasFS then
            sec:AddLabel("No file access detected - configs are kept in memory for this session only.")
        end
        return tab
    end

    Window:Toggle(true)
    table.insert(Library.Windows, Window)
    return Window
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    self.OnUnload:Fire()      -- let the script disable its own features first
    self.OnUnload:Clear()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    for _, b in ipairs(self._blurs) do pcall(function() b:Destroy() end) end
    table.clear(self._blurs)
    if self.Gui then pcall(function() self.Gui:Destroy() end) end
    self.Gui, self._notif = nil, nil
    table.clear(self.Flags)
    table.clear(self.Options)
    table.clear(self.Windows)
end

return Library
