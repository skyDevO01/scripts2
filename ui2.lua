--[[
    MONO UI  -  black & white UI library built on the Drawing API

    Window  : Library:CreateWindow({Title, Size, ToggleKey, Folder})
    Tab     : Window:AddTab(name)
    Elements: Tab:AddSection / AddLabel / AddButton / AddButtons / AddToggle /
              AddSlider / AddDropdown / AddTextbox / AddKeybind / AddConfigManager
    Config  : Library:SaveConfig / LoadConfig / RenameConfig / DeleteConfig /
              ListConfigs / SetAutoload / ClearAutoload / LoadAutoload
    Misc    : Library:Notify(text, duration), Library:Unload()
]]

print("[MonoUI] build 1.2")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local HttpService          = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")

local V2 = Vector2.new
local FONT, GAP, SIDE, TOP, PAD = 2, 6, 132, 36, 12
local CONFIRM_TIME = 3

local Z = { Window = 10, Element = 20, Fill = 22, Text = 26, Popup = 60, PopupText = 66, Toast = 100 }

local Theme = {
    Background = Color3.fromRGB(12, 12, 12),
    Sidebar    = Color3.fromRGB(8, 8, 8),
    Element    = Color3.fromRGB(22, 22, 22),
    Hover      = Color3.fromRGB(34, 34, 34),
    Border     = Color3.fromRGB(44, 44, 44),
    Text       = Color3.fromRGB(235, 235, 235),
    Dim        = Color3.fromRGB(120, 120, 120),
    Accent     = Color3.fromRGB(255, 255, 255),
    Inverse    = Color3.fromRGB(10, 10, 10),
}

local Library = {
    Flags = {}, Options = {}, Windows = {}, Theme = Theme, Folder = "MonoUI",
    _drawings = {}, _conns = {}, _toasts = {},
    OnUnload = { _callbacks = {}, Connect = function(self, cb) table.insert(self._callbacks, cb) end }
}

-- re-executing the script cleans up the previous instance first
local genv = (getgenv and getgenv()) or _G
if genv.MonoUI and genv.MonoUI.Unload then pcall(genv.MonoUI.Unload, genv.MonoUI) end
genv.MonoUI = Library

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------
local function lerp(a, b, t) return a + (b - a) * t end
local function lerpC(a, b, t) return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t)) end
local function smooth(cur, target, speed, dt) return cur + (target - cur) * (1 - math.exp(-speed * dt)) end
local function inside(mx, my, x, y, w, h) return mx >= x and mx <= x + w and my >= y and my <= y + h end
local function ty(h, size) return math.floor((h - size) / 2) end

local function fire(cb, ...)
    if not cb then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[MonoUI] callback error: " .. tostring(err)) end
    end)
end

-- every drawing belongs to an "owner" ({parts = {}}) and is positioned relative to it
local function addPart(owner, class, props, ox, oy, group)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    d.Visible = false
    local p = {
        d = d, ox = ox or 0, oy = oy or 0, group = group, t = props.Transparency or 1,
        noPos = (class == "Triangle" or class == "Line"),
    }
    owner.parts[#owner.parts + 1] = p
    Library._drawings[#Library._drawings + 1] = d
    return d, p
end

local function placeParts(o, x, y, vis, alpha)
    for _, p in ipairs(o.parts) do
        local d = p.d
        if not p.noPos then d.Position = V2(x + p.ox, y + p.oy) end
        d.Transparency = p.t * alpha
        if p.group == "popup" then
            d.Visible = (vis == true and o.popupVis == true)
        elseif p.group == "dyn" then
            if not vis then d.Visible = false end -- element drives its own visibility
        else
            d.Visible = vis
        end
    end
end

local function rect(o, ox, oy, w, h, c, z, g)
    return addPart(o, "Square", { Size = V2(w, h), Color = c, Filled = true, ZIndex = z or Z.Fill }, ox, oy, g)
end
local function label(o, s, ox, oy, size, c, z, center, g)
    return addPart(o, "Text", { Text = s, Size = size or 13, Color = c, Font = FONT, Center = center or false, Outline = false, ZIndex = z or Z.Text }, ox, oy, g)
end
local function circle(o, ox, oy, r, c, z, g)
    return addPart(o, "Circle", { Radius = r, Color = c, Filled = true, NumSides = 32, ZIndex = z or Z.Text }, ox, oy, g)
end
local function pill(o, ox, oy, w, h, c, z)
    local r = h / 2
    local set = { rect(o, ox + r, oy, w - h, h, c, z), circle(o, ox + r, oy + r, r, c, z), circle(o, ox + w - r, oy + r, r, c, z) }
    function set:color(col) for _, d in ipairs(self) do d.Color = col end end
    return set
end

-- sink game input while typing into a textbox / binding a key
local sinkOn = false
local function sink(on)
    if on == sinkOn then return end
    sinkOn = on
    if on then
        pcall(function()
            ContextActionService:BindActionAtPriority("MonoSink", function() return Enum.ContextActionResult.Sink end,
                false, 3000, unpack(Enum.KeyCode:GetEnumItems()))
        end)
    else
        pcall(function() ContextActionService:UnbindAction("MonoSink") end)
    end
end

local DIGITS = { Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9" }
local function keyChar(input)
    local n = input.KeyCode.Name
    local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
    if #n == 1 and n:match("%a") then return shift and n:upper() or n:lower() end
    if DIGITS[n] then return DIGITS[n] end
    local kp = n:match("^Keypad(%a+)$")
    if kp and DIGITS[kp] then return DIGITS[kp] end
    if n == "Space" then return " " end
    if n == "Minus" then return shift and "_" or "-" end
    if n == "Period" then return "." end
    return nil
end

local function commit(el, silent)
    if el.Flag then Library.Flags[el.Flag] = el.Value end
    if not silent then fire(el.Callback, el.Value) end
end

local function register(el, o)
    el.Flag, el.Callback = o.Flag, o.Callback
    if el.Flag then
        Library.Flags[el.Flag] = el.Value
        Library.Options[el.Flag] = el
    end
end

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------
local function stepToasts(dt)
    local ts = Library._toasts
    if #ts == 0 then return end
    local vp = workspace.CurrentCamera.ViewportSize
    local y = vp.Y - 18
    for i = #ts, 1, -1 do
        local t = ts[i]
        y = y - t.h
        local age = os.clock() - t.born
        t.a = smooth(t.a, age < t.dur and 1 or 0, 14, dt)
        t.y = t.y and smooth(t.y, y, 14, dt) or y
        placeParts(t, vp.X - t.w - 18 + (1 - t.a) * 26, t.y, true, t.a)
        t.bar.Size = V2(math.max((t.w - 2) * (1 - math.min(age / t.dur, 1)), 0.01), 1)
        y = y - 8
        if age >= t.dur and t.a < 0.02 then
            for _, p in ipairs(t.parts) do pcall(function() p.d:Remove() end) end
            table.remove(ts, i)
        end
    end
end

local function ensureLoop()
    if Library._loop then return end
    Library._loop = RunService.RenderStepped:Connect(function(dt)
        local m = UserInputService:GetMouseLocation()
        for _, w in ipairs(Library.Windows) do
            local ok, err = pcall(w.Step, w, dt, m.X, m.Y)
            if not ok and err ~= Library._lastErr then
                Library._lastErr = err -- report each distinct error once instead of every frame
                warn("[MonoUI] " .. tostring(err))
            end
        end
        stepToasts(dt)
    end)
    table.insert(Library._conns, Library._loop)
end

function Library:Notify(text, duration)
    ensureLoop()
    text = tostring(text)
    local t = { parts = {}, a = 0, born = os.clock(), dur = duration or 3 }
    local txt, tp = label(t, text, 14, 0, 13, Theme.Text, Z.Toast + 3)
    local tw = txt.TextBounds.X
    if tw <= 0 then tw = #text * 6.5 end
    t.w, t.h = math.floor(tw) + 28, 34
    tp.oy = ty(t.h, 13)
    rect(t, 0, 0, t.w, t.h, Theme.Border, Z.Toast)
    rect(t, 1, 1, t.w - 2, t.h - 2, Theme.Background, Z.Toast + 1)
    t.bar = rect(t, 1, t.h - 2, t.w - 2, 1, Theme.Accent, Z.Toast + 2)
    table.insert(self._toasts, t)
end

--------------------------------------------------------------------------------
-- config system
--------------------------------------------------------------------------------
local function fsReady()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
        and type(isfolder) == "function" and type(makefolder) == "function"
        and type(listfiles) == "function" and type(delfile) == "function"
end

local function sanitize(n)
    n = tostring(n or ""):gsub("[^%w%-_ ]", "")
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    return n
end

local function dir() return Library.Folder .. "/configs" end
local function cfgPath(name) return dir() .. "/" .. name .. ".json" end
local function autoPath() return Library.Folder .. "/autoload.txt" end

local function ensureFolders()
    if not isfolder(Library.Folder) then makefolder(Library.Folder) end
    if not isfolder(dir()) then makefolder(dir()) end
end

function Library:ListConfigs()
    local out = {}
    if not fsReady() then return out end
    ensureFolders()
    for _, f in ipairs(listfiles(dir())) do
        local n = f:match("([^/\\]+)%.json$")
        if n then out[#out + 1] = n end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

function Library:SaveConfig(name, overwrite)
    if not fsReady() then return false, "Executor has no file functions" end
    name = sanitize(name)
    if name == "" then return false, "Invalid config name" end
    ensureFolders()
    if isfile(cfgPath(name)) and not overwrite then return false, "Config already exists" end
    local data = {}
    for flag, v in pairs(self.Flags) do data[flag] = v end
    writefile(cfgPath(name), HttpService:JSONEncode(data))
    return true, name
end

function Library:LoadConfig(name)
    if not fsReady() then return false, "Executor has no file functions" end
    name = sanitize(name)
    if name == "" or not isfile(cfgPath(name)) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgPath(name))) end)
    if not ok or type(data) ~= "table" then return false, "Config is corrupted" end
    for flag, v in pairs(data) do
        local el = self.Options[flag]
        if el and el.Set then pcall(el.Set, el, v) end
    end
    return true, name
end

function Library:GetAutoload()
    if not fsReady() or not isfile(autoPath()) then return nil end
    local n = sanitize(readfile(autoPath()))
    if n ~= "" and isfile(cfgPath(n)) then return n end
    return nil
end

function Library:SetAutoload(name)
    if not fsReady() then return false, "Executor has no file functions" end
    name = sanitize(name)
    if name == "" or not isfile(cfgPath(name)) then return false, "Config not found" end
    ensureFolders()
    writefile(autoPath(), name)
    return true, name
end

function Library:ClearAutoload()
    if fsReady() and isfile(autoPath()) then delfile(autoPath()) end
    return true
end

function Library:DeleteConfig(name)
    if not fsReady() then return false, "Executor has no file functions" end
    name = sanitize(name)
    if name == "" or not isfile(cfgPath(name)) then return false, "Config not found" end
    delfile(cfgPath(name))
    if self:GetAutoload() == nil and isfile(autoPath()) then delfile(autoPath()) end
    return true, name
end

function Library:RenameConfig(old, new)
    if not fsReady() then return false, "Executor has no file functions" end
    old, new = sanitize(old), sanitize(new)
    if new == "" then return false, "Enter a new name" end
    if not isfile(cfgPath(old)) then return false, "Config not found" end
    if isfile(cfgPath(new)) then return false, "Name already taken" end
    local wasAuto = (self:GetAutoload() == old)
    writefile(cfgPath(new), readfile(cfgPath(old)))
    delfile(cfgPath(old))
    if wasAuto then writefile(autoPath(), new) end
    return true, new
end

function Library:LoadAutoload()
    local n = self:GetAutoload()
    if not n then return false end
    local ok, err = self:LoadConfig(n)
    self:Notify(ok and ("Autoloaded " .. n) or tostring(err))
    return ok
end

--------------------------------------------------------------------------------
-- window
--------------------------------------------------------------------------------
local Window, Tab = {}, {}
Window.__index, Tab.__index = Window, Tab

function Library:CreateWindow(o)
    o = o or {}
    ensureLoop()
    if o.Folder then Library.Folder = o.Folder end
    local size = o.Size or V2(560, 400)
    local vp = workspace.CurrentCamera.ViewportSize
    local win = setmetatable({
        Title = o.Title or "MONO", size = size, toggleKey = o.ToggleKey or Enum.KeyCode.RightShift,
        tabs = {}, parts = {}, keybinds = {}, alpha = 0, open = true, shown = true, dirty = true, offY = 12,
        x = math.floor((vp.X - size.X) / 2), y = math.floor((vp.Y - size.Y) / 2),
        cw = size.X - SIDE - PAD * 2, ch = size.Y - TOP - 1 - PAD * 2,
    }, Window)

    rect(win, -1, -1, size.X + 2, size.Y + 2, Theme.Border, Z.Window)
    rect(win, 0, 0, size.X, size.Y, Theme.Background, Z.Window + 1)
    rect(win, 0, 0, SIDE, size.Y, Theme.Sidebar, Z.Window + 2)
    rect(win, SIDE, 0, 1, size.Y, Theme.Border, Z.Window + 3)
    rect(win, 0, TOP, size.X, 1, Theme.Border, Z.Window + 3)
    label(win, win.Title, 16, ty(TOP, 15), 15, Theme.Accent, Z.Text)
    win.titleTxt = label(win, "", SIDE + PAD + 4, ty(TOP, 13), 13, Theme.Dim, Z.Text)
    win.sbar = rect(win, size.X - 6, 0, 2, 20, Theme.Border, Z.Fill + 2, "dyn")

    table.insert(Library._conns, UserInputService.InputBegan:Connect(function(input, gp) win:OnInput(input, gp) end))
    table.insert(Library._conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then win:Wheel(input.Position.Z) end
    end))

    if genv.ui_mode == "Mobile" then
        local sg = Instance.new("ScreenGui")
        sg.Name = "MonoUI_MobileToggle"
        sg.ResetOnSpawn = false
        pcall(function()
            if gethui then sg.Parent = gethui()
            elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then sg.Parent = game:GetService("CoreGui")
            else sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        end)
        if not sg.Parent then pcall(function() sg.Parent = game:GetService("CoreGui") end) end
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 45, 0, 45)
        btn.Position = UDim2.new(0.5, -22, 0, 10)
        btn.BackgroundColor3 = Theme.Sidebar
        btn.BorderColor3 = Theme.Accent
        btn.BorderSizePixel = 2
        btn.Text = "M"
        btn.TextColor3 = Theme.Accent
        btn.TextSize = 24
        btn.Font = Enum.Font.Code
        btn.Parent = sg
        btn.Active = true
        btn.Draggable = true

        btn.MouseButton1Click:Connect(function()
            win:Toggle()
        end)

        table.insert(Library._conns, {Disconnect = function() pcall(function() sg:Destroy() end) end})
    end

    table.insert(Library.Windows, win)
    return win
end

function Window:AddTab(name)
    local tab = setmetatable({
        win = self, name = name, elements = {}, scroll = 0, scrollTarget = 0, contentH = 0,
        btn = { parts = {} }, sel = 0, hover = 0,
    }, Tab)
    tab.btnY = TOP + 1 + 12 + #self.tabs * 34
    tab.btnBg = rect(tab.btn, 8, tab.btnY, SIDE - 16, 30, Theme.Sidebar, Z.Window + 4)
    tab.btnBar = rect(tab.btn, 8, tab.btnY + 7, 2, 16, Theme.Accent, Z.Fill, "dyn")
    tab.btnTxt = label(tab.btn, name, 22, tab.btnY + ty(30, 13), 13, Theme.Dim, Z.Text)
    table.insert(self.tabs, tab)
    if not self.activeTab then self:SelectTab(tab) end
    self.dirty = true
    return tab
end

function Window:SelectTab(tab)
    if self.popup then self.popup:Close() end
    self:Blur(); self:StopListen()
    self.activeTab = tab
    self.titleTxt.Text = tab.name
    self.dirty = true
end

function Window:Blur()
    local f = self.focus
    if f then
        self.focus = nil
        f.focused = false
        sink(false)
        if f.onBlur then f.onBlur() end
    end
end

function Window:StopListen()
    local k = self.listening
    if k then
        self.listening = nil
        k.listening = false
        sink(false)
    end
end

function Window:Toggle(state)
    if state == nil then state = not self.open end
    self.open = state
    if not state then
        if self.popup then self.popup:Close() end
        self:Blur(); self:StopListen()
        self.dragging, self.dragEl = false, nil
    end
    self.dirty = true
end

function Window:Relayout()
    local ox, oy = self.x, self.y + self.offY
    placeParts(self, ox, oy, self.shown, self.alpha)
    for _, tab in ipairs(self.tabs) do
        placeParts(tab.btn, ox, oy, self.shown, self.alpha)
        tab:Layout(ox + SIDE + PAD, oy + TOP + 1 + PAD)
    end
end

function Tab:Layout(cx, cy)
    local win = self.win
    local active = win.shown and win.activeTab == self
    local y = cy - self.scroll
    local startY = y
    for _, el in ipairs(self.elements) do
        local vis = active and y >= cy - 0.5 and y + el.h <= cy + win.ch + 0.5
        if not vis and (el.open or el.popupVis) then
            el.popupVis, el.anim = false, 0
            if el.Close then el:Close() end
        end
        el.x, el.y, el.visible = cx, y, vis
        placeParts(el, cx, y, vis, win.alpha)
        y = y + el.h + GAP
    end
    self.contentH = math.max(0, y - GAP - startY)
end

function Window:Step(dt, mx, my)
    local target = self.open and 1 or 0
    if self.alpha ~= target then
        self.alpha = smooth(self.alpha, target, 14, dt)
        if math.abs(self.alpha - target) < 0.004 then self.alpha = target end
        self.offY = (1 - self.alpha) * 12
        self.dirty = true
    end
    local shown = self.open or self.alpha > 0
    if shown ~= self.shown then self.shown = shown; self.dirty = true end

    local tab = self.activeTab
    if shown then
        local down = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if self.dragging then
            if down then
                self.x, self.y = mx - self.dragOff.X, my - self.dragOff.Y
                self.dirty = true
            else
                self.dragging = false
            end
        end
        if self.dragEl and not down then self.dragEl = nil end
        if self.dragEl then self.dragEl.drag(mx, my) end
        if tab and tab.scroll ~= tab.scrollTarget then
            tab.scroll = smooth(tab.scroll, tab.scrollTarget, 16, dt)
            if math.abs(tab.scroll - tab.scrollTarget) < 0.4 then tab.scroll = tab.scrollTarget end
            self.dirty = true
        end
    end

    if self.dirty then self.dirty = false; self:Relayout() end
    if not shown or not tab then return end

    local ox, oy = self.x, self.y + self.offY

    -- tab buttons
    for _, t in ipairs(self.tabs) do
        local hov = self.open and inside(mx, my, ox + 8, oy + t.btnY, SIDE - 16, 30)
        t.hover = smooth(t.hover, hov and 1 or 0, 16, dt)
        t.sel = smooth(t.sel, t == tab and 1 or 0, 14, dt)
        t.btnBg.Color = lerpC(Theme.Sidebar, Theme.Element, math.max(t.sel, t.hover * 0.5))
        t.btnTxt.Color = lerpC(Theme.Dim, Theme.Accent, math.max(t.sel, t.hover * 0.7))
        local bh = 16 * t.sel
        t.btnBar.Visible = bh > 0.5
        t.btnBar.Size = V2(2, math.max(bh, 1))
        t.btnBar.Position = V2(ox + 8, oy + t.btnY + (30 - bh) / 2)
    end

    -- scrollbar
    local maxScroll = math.max(0, tab.contentH - self.ch)
    if maxScroll > 0 then
        local h = math.max(20, self.ch * self.ch / tab.contentH)
        self.sbar.Visible = true
        self.sbar.Size = V2(2, h)
        self.sbar.Position = V2(ox + self.size.X - 6, oy + TOP + 1 + PAD + (self.ch - h) * (tab.scroll / maxScroll))
    else
        self.sbar.Visible = false
    end

    -- hover target
    local hovEl
    if self.open then
        local pe = self.popup
        if pe and pe.popupHit(mx, my) then
            hovEl = pe
        else
            for _, el in ipairs(tab.elements) do
                if el.visible and inside(mx, my, el.x, el.y, el.w, el.h) then hovEl = el break end
            end
        end
    end
    for _, el in ipairs(tab.elements) do
        if el.visible then el.step(dt, el == hovEl, mx, my) end
    end
end

function Window:Click(mx, my)
    local pe = self.popup
    if pe then
        if pe.popupHit(mx, my) then pe.popupClick(mx, my) return end
        pe:Close()
        if inside(mx, my, pe.x, pe.y, pe.w, pe.h) then return end
    end
    local ox, oy = self.x, self.y + self.offY
    if not inside(mx, my, ox, oy, self.size.X, self.size.Y) then
        self:Blur(); self:StopListen()
        return
    end
    if inside(mx, my, ox, oy, self.size.X, TOP) then
        self:Blur(); self:StopListen()
        self.dragging, self.dragOff = true, V2(mx - self.x, my - self.y)
        return
    end
    for _, tab in ipairs(self.tabs) do
        if inside(mx, my, ox + 8, oy + tab.btnY, SIDE - 16, 30) then self:SelectTab(tab) return end
    end
    local hit
    if self.activeTab then
        for _, el in ipairs(self.activeTab.elements) do
            if el.visible and inside(mx, my, el.x, el.y, el.w, el.h) then hit = el break end
        end
    end
    if self.focus and self.focus ~= hit then self:Blur() end
    if self.listening and self.listening ~= hit then self:StopListen() end
    if hit and hit.click then hit.click(mx, my) end
end

function Window:OnInput(input, gp)
    local ut = input.UserInputType
    if ut == Enum.UserInputType.Keyboard then
        if self.focus then self.focus:key(input) return end
        if self.listening then self.listening:listen(input) return end
        if input.KeyCode == self.toggleKey then self:Toggle() return end
        if not gp then
            for _, kb in ipairs(self.keybinds) do
                if kb.Value ~= "None" and kb.Value == input.KeyCode.Name then fire(kb.Callback) end
            end
        end
    elseif ut == Enum.UserInputType.MouseButton1 and self.open then
        local m = UserInputService:GetMouseLocation()
        self:Click(m.X, m.Y)
    end
end

function Window:Wheel(dz)
    if not (self.open and self.activeTab) then return end
    local m = UserInputService:GetMouseLocation()
    local pe = self.popup
    if pe and pe.popupHit(m.X, m.Y) then pe.popupScroll(-dz) return end
    local cx, cy = self.x + SIDE + PAD, self.y + self.offY + TOP + 1 + PAD
    if inside(m.X, m.Y, cx, cy, self.cw, self.ch) then
        local tab = self.activeTab
        tab.scrollTarget = math.clamp(tab.scrollTarget - dz * 42, 0, math.max(0, tab.contentH - self.ch))
    end
end

--------------------------------------------------------------------------------
-- elements
--------------------------------------------------------------------------------
function Tab:_new(h)
    local el = {
        tab = self, win = self.win, parts = {}, h = h, w = self.win.cw,
        x = 0, y = 0, visible = false, hover = 0, step = function() end,
    }
    table.insert(self.elements, el)
    self.win.dirty = true
    return el
end

function Tab:AddSection(name)
    local el = self:_new(32)
    label(el, tostring(name):upper(), 10, 10, 11, Theme.Dim)
    rect(el, 10, 28, el.w - 20, 1, Theme.Border, Z.Fill)
    return el
end

function Tab:AddLabel(text)
    local el = self:_new(20)
    local t = label(el, text, 10, ty(20, 13), 13, Theme.Dim)
    function el:Set(s) t.Text = tostring(s) end
    return el
end

-- one or several buttons on a single row; Confirm = true -> click, then click again within 3s
function Tab:AddButtons(list)
    local el = self:_new(30)
    local n, gap = #list, 6
    local bw = (el.w - 20 - gap * (n - 1)) / n
    local btns = {}
    for i, b in ipairs(list) do
        local ox = 10 + (i - 1) * (bw + gap)
        local btn = { ox = ox, w = bw, name = b.Name or "Button", cb = b.Callback, confirm = b.Confirm, hover = 0, press = 0, arm = 0 }
        btn.border = rect(el, ox, 0, bw, 30, Theme.Border, Z.Element)
        btn.fill = rect(el, ox + 1, 1, bw - 2, 28, Theme.Element, Z.Fill)
        btn.bar = rect(el, ox + 1, 27, bw - 2, 2, Theme.Inverse, Z.Fill + 1, "dyn")
        btn.txt = label(el, btn.name, ox + bw / 2, ty(30, 13), 13, Theme.Text, Z.Text, true)
        btns[i] = btn
    end

    el.click = function(mx)
        for _, b in ipairs(btns) do
            if inside(mx, el.y, el.x + b.ox, el.y, b.w, 30) then
                if b.confirm then
                    if b.armed then
                        b.armed = nil
                        b.press = 1
                        fire(b.cb)
                    else
                        for _, o in ipairs(btns) do o.armed = nil end
                        b.armed = os.clock() + CONFIRM_TIME
                    end
                else
                    b.press = 1
                    fire(b.cb)
                end
            end
        end
    end

    el.step = function(dt, hov, mx, my)
        for _, b in ipairs(btns) do
            local h = hov and inside(mx, my, el.x + b.ox, el.y, b.w, 30)
            b.hover = smooth(b.hover, h and 1 or 0, 16, dt)
            b.press = smooth(b.press, 0, 9, dt)
            local frac = 0
            if b.armed then
                local rem = b.armed - os.clock()
                if rem <= 0 then
                    b.armed = nil
                else
                    frac = rem / CONFIRM_TIME
                    b.txt.Text = "Confirm (" .. math.ceil(rem) .. ")"
                end
            end
            if not b.armed and b.txt.Text ~= b.name then b.txt.Text = b.name end
            b.arm = smooth(b.arm, b.armed and 1 or 0, 18, dt)
            local k = math.max(b.press, b.arm)
            b.fill.Color = lerpC(lerpC(Theme.Element, Theme.Hover, b.hover), Theme.Accent, k)
            b.txt.Color = lerpC(Theme.Text, Theme.Inverse, k)
            b.border.Color = lerpC(Theme.Border, Theme.Accent, math.max(b.hover * 0.6, b.arm))
            b.bar.Visible = (b.arm > 0.05 and el.visible == true)
            b.bar.Size = V2(math.max((b.w - 2) * frac, 0.01), 2)
        end
    end
    return el
end

function Tab:AddButton(o)
    return self:AddButtons({ o })
end

function Tab:AddToggle(o)
    o = o or {}
    local el = self:_new(28)
    local w = el.w
    el.Value = o.Default and true or false
    register(el, o)
    local bg = rect(el, 0, 0, w, 28, Theme.Background, Z.Element)
    label(el, o.Name or "Toggle", 10, ty(28, 13), 13, Theme.Text)
    local tw, th = 32, 16
    local tx, tyo = w - tw - 10, (28 - th) / 2
    local border = pill(el, tx, tyo, tw, th, Theme.Border, Z.Fill)
    local track = pill(el, tx + 1, tyo + 1, tw - 2, th - 2, Theme.Element, Z.Fill + 1)
    local knob = circle(el, tx + 8, tyo + 8, 5, Theme.Dim, Z.Fill + 2)
    el.anim = el.Value and 1 or 0

    function el:Set(v, silent)
        v = v and true or false
        if v == el.Value then return end
        el.Value = v
        commit(el, silent)
    end
    el.click = function() el:Set(not el.Value) end
    el.step = function(dt, hov)
        el.hover = smooth(el.hover, hov and 1 or 0, 16, dt)
        el.anim = smooth(el.anim, el.Value and 1 or 0, 14, dt)
        local a = el.anim
        bg.Color = lerpC(Theme.Background, Theme.Element, el.hover)
        border:color(lerpC(Theme.Border, Theme.Accent, a))
        track:color(lerpC(Theme.Element, Theme.Accent, a))
        knob.Color = lerpC(Theme.Dim, Theme.Inverse, a)
        knob.Position = V2(el.x + tx + 8 + a * (tw - 16), el.y + tyo + 8)
    end
    return el
end

function Tab:AddSlider(o)
    o = o or {}
    local win = self.win
    local el = self:_new(44)
    local w = el.w
    local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
    local dec = #((tostring(inc):match("%.(%d+)")) or "")
    local suffix = o.Suffix or ""
    el.Value = math.clamp(o.Default or min, min, max)
    el.disp = el.Value
    register(el, o)

    local bg = rect(el, 0, 0, w, 44, Theme.Background, Z.Element)
    label(el, o.Name or "Slider", 10, 6, 13, Theme.Text)
    local valTxt = label(el, "", 0, 6, 13, Theme.Dim)
    rect(el, 10, 30, w - 20, 4, Theme.Border, Z.Fill)
    local fill = rect(el, 10, 30, 1, 4, Theme.Accent, Z.Fill + 1)
    local knob = circle(el, 10, 32, 5, Theme.Accent, Z.Text)

    function el:Set(v, silent)
        v = tonumber(v)
        if not v then return end
        v = min + math.floor((math.clamp(v, min, max) - min) / inc + 0.5) * inc
        local m = 10 ^ dec
        v = math.clamp(math.floor(v * m + 0.5) / m, min, max)
        if v == el.Value then return end
        el.Value = v
        commit(el, silent)
    end
    el.drag = function(mx)
        local f = math.clamp((mx - (el.x + 10)) / (w - 20), 0, 1)
        el:Set(min + f * (max - min))
    end
    el.click = function(mx) win.dragEl = el; el.drag(mx) end
    el.step = function(dt, hov)
        el.hover = smooth(el.hover, (hov or win.dragEl == el) and 1 or 0, 16, dt)
        el.disp = smooth(el.disp, el.Value, 22, dt)
        bg.Color = lerpC(Theme.Background, Theme.Element, el.hover)
        local f = (max == min) and 0 or (el.disp - min) / (max - min)
        local px = math.max(f * (w - 20), 0)
        fill.Size = V2(math.max(px, 1), 4)
        knob.Position = V2(el.x + 10 + px, el.y + 32)
        knob.Radius = lerp(4, 6, el.hover)
        local s = tostring(el.Value) .. suffix
        if s ~= el._s then el._s = s; valTxt.Text = s end
        valTxt.Position = V2(el.x + w - 10 - valTxt.TextBounds.X, el.y + 6)
        valTxt.Color = lerpC(Theme.Dim, Theme.Text, el.hover)
    end
    return el
end

function Tab:AddTextbox(o)
    o = o or {}
    local win = self.win
    local el = self:_new(30)
    local w = el.w - 20
    local maxLen = o.MaxLength or 32
    local placeholder = o.Placeholder or o.Name or "Type here..."
    el.Value = o.Default or ""
    register(el, o)

    local border = rect(el, 10, 0, w, 30, Theme.Border, Z.Element)
    rect(el, 11, 1, w - 2, 28, Theme.Element, Z.Fill)
    local txt = label(el, "", 20, ty(30, 13), 13, Theme.Dim)
    local caret = rect(el, 0, 7, 1, 16, Theme.Accent, Z.Text, "dyn")

    function el:Set(v, silent)
        el.Value = tostring(v or ""):sub(1, maxLen)
        commit(el, silent)
    end
    el.click = function()
        el.focused = true
        win.focus = el
        sink(true)
    end
    el.onBlur = function() fire(el.Callback, el.Value) end
    function el:key(input)
        local k = input.KeyCode
        if k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter or k == Enum.KeyCode.Escape then
            win:Blur()
        elseif k == Enum.KeyCode.Backspace then
            el.Value = el.Value:sub(1, -2)
            commit(el, true)
        elseif k == Enum.KeyCode.V and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            if type(getclipboard) == "function" then
                local clip = tostring(getclipboard() or ""):gsub("[\r\n]", "")
                el.Value = (el.Value .. clip):sub(1, maxLen)
                commit(el, true)
            end
        else
            local c = keyChar(input)
            if c and #el.Value < maxLen then
                el.Value = el.Value .. c
                commit(el, true)
            end
        end
    end
    el.step = function(dt, hov)
        el.hover = smooth(el.hover, (hov or el.focused) and 1 or 0, 16, dt)
        el.focus = smooth(el.focus or 0, el.focused and 1 or 0, 16, dt)
        border.Color = lerpC(lerpC(Theme.Border, Theme.Dim, el.hover), Theme.Accent, el.focus)
        if el.Value ~= el._last then
            el._last = el.Value
            if el.Value == "" then
                txt.Text = placeholder
            else
                local disp = el.Value
                txt.Text = disp
                while #disp > 1 and txt.TextBounds.X > w - 34 do
                    disp = disp:sub(2)
                    txt.Text = disp
                end
            end
        end
        txt.Color = el.Value == "" and Theme.Dim or Theme.Text
        local tw = el.Value == "" and 0 or txt.TextBounds.X
        caret.Position = V2(el.x + 20 + tw + 1, el.y + 7)
        caret.Visible = (el.visible == true and el.focused == true and (math.floor(os.clock() * 1.8) % 2 == 0))
    end
    return el
end

function Tab:AddKeybind(o)
    o = o or {}
    local win = self.win
    local el = self:_new(28)
    local w = el.w
    local d = o.Default
    el.Value = d and (typeof(d) == "EnumItem" and d.Name or tostring(d)) or "None"
    register(el, o) -- Callback = fired when the key is pressed
    el.OnChange = o.OnChange
    table.insert(win.keybinds, el)

    local bw = 96
    local bg = rect(el, 0, 0, w, 28, Theme.Background, Z.Element)
    label(el, o.Name or "Keybind", 10, ty(28, 13), 13, Theme.Text)
    local border = rect(el, w - bw - 10, 4, bw, 20, Theme.Border, Z.Fill)
    rect(el, w - bw - 9, 5, bw - 2, 18, Theme.Element, Z.Fill + 1)
    local txt = label(el, "", w - 10 - bw / 2, 4 + ty(20, 12), 12, Theme.Text, Z.Text, true)

    function el:Set(v, silent)
        el.Value = (v and v ~= "") and tostring(v) or "None"
        if el.Flag then Library.Flags[el.Flag] = el.Value end
        if not silent then fire(el.OnChange, el.Value) end
    end
    el.click = function()
        el.listening = true
        win.listening = el
        sink(true)
    end
    function el:listen(input)
        local k = input.KeyCode
        if k == Enum.KeyCode.Unknown then return end
        win.listening, el.listening = nil, false
        sink(false)
        el:Set(k == Enum.KeyCode.Escape and "None" or k.Name)
    end
    el.step = function(dt, hov)
        el.hover = smooth(el.hover, (hov or el.listening) and 1 or 0, 16, dt)
        bg.Color = lerpC(Theme.Background, Theme.Element, el.hover)
        border.Color = lerpC(Theme.Border, Theme.Accent, el.listening and 1 or el.hover * 0.5)
        local s = el.listening and "..." or el.Value
        if s ~= el._s then el._s = s; txt.Text = s end
        txt.Color = el.listening and Theme.Accent or (el.Value == "None" and Theme.Dim or Theme.Text)
    end
    return el
end

function Tab:AddDropdown(o)
    o = o or {}
    local win = self.win
    local el = self:_new(28)
    local w, IH, MAXV = el.w, 24, 7
    local multi = o.Multi and true or false
    el.Values, el.items, el.anim, el.pscroll, el.pH, el.popupVis = {}, {}, 0, 0, 0, false
    el.Value = multi and {} or o.Default
    register(el, o)

    local bg = rect(el, 0, 0, w, 28, Theme.Background, Z.Element)
    label(el, o.Name or "Dropdown", 10, ty(28, 13), 13, Theme.Text)
    local valTxt = label(el, "", 0, ty(28, 13), 13, Theme.Dim)
    local arrow = addPart(el, "Triangle", { Filled = true, Color = Theme.Dim, ZIndex = Z.Text }, 0, 0)
    local pBorder = rect(el, 10, 30, w - 20, 1, Theme.Border, Z.Popup, "popup")
    local pFill = rect(el, 11, 31, w - 22, 1, Theme.Element, Z.Popup + 1, "popup")
    local hRect = rect(el, 11, 34, w - 22, IH, Theme.Hover, Z.Popup + 2, "popup")

    local function selected(name)
        if multi then return el.Value[name] == true end
        return el.Value == name
    end
    local function display()
        if multi then
            local t = {}
            for _, n in ipairs(el.Values) do if el.Value[n] then t[#t + 1] = n end end
            return #t > 0 and table.concat(t, ", ") or "None"
        end
        return el.Value ~= nil and tostring(el.Value) or "Select"
    end

    function el:Set(v, silent)
        if multi then
            local d = {}
            if type(v) == "table" then
                for k, x in pairs(v) do
                    if type(k) == "number" then d[x] = true elseif x then d[k] = true end
                end
            end
            el.Value = d
        else
            el.Value = v
        end
        commit(el, silent)
    end

    function el:Refresh(values)
        el.Values = values or {}
        for i = #el.parts, 1, -1 do
            local p = el.parts[i]
            if p.item then
                pcall(function() p.d:Remove() end)
                table.remove(el.parts, i)
            end
        end
        el.items = {}
        for _, name in ipairs(el.Values) do
            local t, tp = label(el, name, 0, 0, 13, Theme.Dim, Z.PopupText, false, "popup")
            local dot, dp = circle(el, 0, 0, 2.5, Theme.Accent, Z.PopupText, "popup")
            tp.item, dp.item = true, true
            el.items[#el.items + 1] = { name = name, txt = t, dot = dot }
        end
        el.pscroll = math.clamp(el.pscroll, 0, math.max(0, #el.Values - MAXV))
        if not multi and el.Value ~= nil and not table.find(el.Values, el.Value) then
            el.Value = nil
            commit(el, true)
        end
        el._disp = nil
        win.dirty = true
    end

    function el:Close()
        el.open = false
        if win.popup == el then win.popup = nil end
    end

    local function popupHeight() return math.min(#el.Values, MAXV) * IH + 8 end
    el.popupHit = function(mx, my)
        return el.popupVis and inside(mx, my, el.x + 10, el.y + 30, w - 20, el.pH)
    end
    local function indexAt(my)
        local r = math.floor((my - (el.y + 34)) / IH)
        if r < 0 or r >= math.min(#el.Values, MAXV) then return nil end
        return r + 1 + el.pscroll
    end
    el.popupClick = function(mx, my)
        local idx = indexAt(my)
        local name = idx and el.Values[idx]
        if not name then return end
        if multi then
            local d = {}
            for k, v in pairs(el.Value) do d[k] = v end
            d[name] = (not d[name]) or nil
            el:Set(d)
        else
            el:Set(name)
            el:Close()
        end
    end
    el.popupScroll = function(delta)
        el.pscroll = math.clamp(el.pscroll + delta, 0, math.max(0, #el.Values - MAXV))
    end
    el.click = function()
        el.open = not el.open
        win.popup = el.open and el or nil
    end

    el.step = function(dt, hov, mx, my)
        el.hover = smooth(el.hover, (hov or el.open) and 1 or 0, 16, dt)
        el.anim = smooth(el.anim, el.open and 1 or 0, 16, dt)
        if not el.open and el.anim < 0.02 then el.anim = 0 end
        el.popupVis = el.anim > 0
        bg.Color = lerpC(Theme.Background, Theme.Element, el.hover)

        -- selected text (right aligned)
        local s = display()
        if s ~= el._disp then
            el._disp = s
            valTxt.Text = s
            local cut = s
            while valTxt.TextBounds.X > w - 130 and #cut > 3 do
                cut = cut:sub(1, -2)
                valTxt.Text = cut .. "..."
            end
        end
        valTxt.Position = V2(el.x + w - 32 - valTxt.TextBounds.X, el.y + ty(28, 13))
        valTxt.Color = lerpC(Theme.Dim, Theme.Text, el.hover)

        -- chevron
        local cx, cy, k = el.x + w - 18, el.y + 14, lerp(1, -1, el.anim)
        arrow.PointA = V2(cx - 4, cy - 2 * k)
        arrow.PointB = V2(cx + 4, cy - 2 * k)
        arrow.PointC = V2(cx, cy + 2 * k)
        arrow.Color = lerpC(Theme.Dim, Theme.Accent, el.hover)

        -- popup
        local show = el.visible and el.popupVis
        el.pH = popupHeight() * el.anim
        pBorder.Visible, pFill.Visible = (show == true), (show == true)
        pBorder.Size = V2(w - 20, math.max(el.pH, 1))
        pFill.Size = V2(w - 22, math.max(el.pH - 2, 1))
        local px, py = el.x + 10, el.y + 30
        local hoverIdx
        if show and hov and mx then hoverIdx = indexAt(my) end
        local hr = hoverIdx and (hoverIdx - el.pscroll - 1) or nil
        if hr then el.hy = smooth(el.hy or hr, hr, 24, dt) else el.hy = nil end
        hRect.Visible = (show == true and hr ~= nil)
        if hr then hRect.Position = V2(px + 1, py + 4 + el.hy * IH) end
        for i, it in ipairs(el.items) do
            local r = i - el.pscroll - 1
            local top = 4 + r * IH
            local vis = show and r >= 0 and r < MAXV and (top + IH) <= el.pH + 0.5
            it.txt.Visible = (vis == true)
            it.dot.Visible = (vis == true and selected(it.name) == true)
            if vis then
                it.txt.Position = V2(px + 10, py + top + ty(IH, 13))
                it.dot.Position = V2(px + w - 20 - 14, py + top + IH / 2)
                it.txt.Color = selected(it.name) and Theme.Accent or (hoverIdx == i and Theme.Text or Theme.Dim)
            end
        end
    end

    el:Refresh(o.Values)
    if multi and o.Default then el:Set(o.Default, true) end
    return el
end

-- Full config UI: name box, list, save / load / rename / overwrite* / delete* / autoload
-- (* = needs a second click within 3 seconds, countdown shown on the button)
function Tab:AddConfigManager()
    local nameBox, list, autoLabel

    local function refresh()
        list:Refresh(Library:ListConfigs())
        autoLabel:Set("Autoload: " .. (Library:GetAutoload() or "none"))
    end
    local function selected()
        local s = list.Value
        if not s then Library:Notify("Select a config first") end
        return s
    end
    local function report(ok, msg, err)
        Library:Notify(ok and msg or tostring(err))
    end

    self:AddSection("Configs")
    nameBox = self:AddTextbox({ Placeholder = "Config name (for save / rename)" })
    list = self:AddDropdown({ Name = "Config list", Values = Library:ListConfigs() })

    self:AddButtons({
        { Name = "Save", Callback = function()
            local ok, res = Library:SaveConfig(nameBox.Value)
            report(ok, "Saved " .. tostring(res), res)
            if ok then nameBox:Set(""); refresh(); list:Set(res, true) end
        end },
        { Name = "Load", Callback = function()
            local s = selected(); if not s then return end
            local ok, res = Library:LoadConfig(s)
            report(ok, "Loaded " .. s, res)
        end },
        { Name = "Rename", Callback = function()
            local s = selected(); if not s then return end
            local ok, res = Library:RenameConfig(s, nameBox.Value)
            report(ok, "Renamed to " .. tostring(res), res)
            if ok then nameBox:Set(""); refresh(); list:Set(res, true) end
        end },
    })

    self:AddButtons({
        { Name = "Overwrite", Confirm = true, Callback = function()
            local s = selected(); if not s then return end
            local ok, res = Library:SaveConfig(s, true)
            report(ok, "Overwrote " .. s, res)
        end },
        { Name = "Delete", Confirm = true, Callback = function()
            local s = selected(); if not s then return end
            local ok, res = Library:DeleteConfig(s)
            report(ok, "Deleted " .. s, res)
            if ok then list:Set(nil, true); refresh() end
        end },
        { Name = "Refresh", Callback = function() refresh(); Library:Notify("Refreshed") end },
    })

    self:AddSection("Autoload")
    autoLabel = self:AddLabel("Autoload: " .. (Library:GetAutoload() or "none"))
    self:AddButtons({
        { Name = "Set autoload", Callback = function()
            local s = selected(); if not s then return end
            local ok, res = Library:SetAutoload(s)
            report(ok, "Autoload set to " .. s, res)
            refresh()
        end },
        { Name = "Clear autoload", Callback = function()
            Library:ClearAutoload()
            Library:Notify("Autoload cleared")
            refresh()
        end },
    })
    refresh()
    return { Refresh = refresh, NameBox = nameBox, List = list }
end

--------------------------------------------------------------------------------
function Library:Unload()
    if self.OnUnload and self.OnUnload._callbacks then
        for _, cb in ipairs(self.OnUnload._callbacks) do
            pcall(cb)
        end
    end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(self._drawings) do pcall(function() d:Remove() end) end
    table.clear(self._conns); table.clear(self._drawings)
    table.clear(self.Windows); table.clear(self._toasts)
    self._loop = nil
    sink(false)
end

return Library
