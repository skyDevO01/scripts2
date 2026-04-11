-- Perona remake (this ass)
local PeronaLib = {}
PeronaLib.Flags   = {}
PeronaLib.Windows = {}
-- ──────────────────────── SERVICES ─────────────────────────────────────────
local GetService = function(name)
    local s = game:GetService(name)
    return (cloneref and cloneref(s)) or s
end
local Players     = GetService("Players")
local UIS         = GetService("UserInputService")
local RS          = GetService("RunService")
local TS          = GetService("TweenService")
local HS          = GetService("HttpService")
local CoreGui     = GetService("CoreGui")
local LP          = Players.LocalPlayer
-- ──────────────────────── THEME (live-mutable) ──────────────────────────────
local T = {
        Accent    = Color3.fromHex("FF1D6A"),
    Bg        = Color3.fromHex("0A0A0A"),
    Surface1  = Color3.fromHex("111111"),
    Surface2  = Color3.fromHex("181818"),
    Surface3  = Color3.fromHex("1E1E1E"),
    Border    = Color3.fromHex("262626"),
    Text      = Color3.fromHex("EFEFEF"),
    TextDim   = Color3.fromHex("555555"),
    TextMuted = Color3.fromHex("333333"),
    Green     = Color3.fromHex("3CFF6E"),
    Orange    = Color3.fromHex("FF9A1D"),
    Red       = Color3.fromHex("FF3A3A"),
    Font      = Enum.Font.Code,
    FontSm    = 11,
    FontMd    = 13,
}
-- Theme listener registry: each entry = { obj, prop, key }
local ThemeListeners = {}
local function OnTheme(obj, prop, key)
    table.insert(ThemeListeners, { obj = obj, prop = prop, key = key })
end
local function ApplyTheme()
    for _, e in ipairs(ThemeListeners) do
        pcall(function() e.obj[e.prop] = T[e.key] end)
    end
end
-- ──────────────────────── UTILITIES ────────────────────────────────────────
local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() o[k] = v end) end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end
local function Tween(obj, props, t, style, dir)
    local ts = t or 0.15
    local es = style or Enum.EasingStyle.Quint
    local ed = dir   or Enum.EasingDirection.Out
    -- Use Flags for runtime-configurable easing when available
    if not style and PeronaLib and PeronaLib.Flags then
        local fsMap = { Quint=Enum.EasingStyle.Quint, Quad=Enum.EasingStyle.Quad, Cubic=Enum.EasingStyle.Cubic, Sine=Enum.EasingStyle.Sine, Back=Enum.EasingStyle.Back, Bounce=Enum.EasingStyle.Bounce }
        local fdMap = { InOut=Enum.EasingDirection.InOut, ["In"]=Enum.EasingDirection.In, Out=Enum.EasingDirection.Out }
        local efs = PeronaLib.Flags["__easing_style"]
        local efd = PeronaLib.Flags["__easing_dir"]
        local ets = PeronaLib.Flags["__tween_speed"]
        if efs and fsMap[efs] then es = fsMap[efs] end
        if efd and fdMap[efd] then ed = fdMap[efd] end
        if ets and type(ets) == "number" and not t then ts = ets end
    end
    TS:Create(obj, TweenInfo.new(ts, es, ed), props):Play()
end
local function Round(n, d)
    local m = 10^(d or 0)
    return math.floor(n * m + .5) / m
end
local function MakeDraggable(frame, handle, winObj)
    handle = handle or frame
    local drag, ds, sp = false, nil, nil
    local targetPos = nil
    local c1, c2, c3
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag, ds, sp = true, i.Position, frame.Position
            targetPos = frame.Position
        end
    end)
    c1 = UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            targetPos = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    c2 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    -- Smooth lerp loop for dragging
    c3 = RS.RenderStepped:Connect(function(dt)
        if not targetPos then return end
        if not drag and math.abs(frame.Position.X.Offset - targetPos.X.Offset) < 0.5 and math.abs(frame.Position.Y.Offset - targetPos.Y.Offset) < 0.5 then
            frame.Position = targetPos; targetPos = nil; return
        end
        local speed = 0.15 -- default lerp alpha
        if PeronaLib and PeronaLib.Flags then
            local ds2 = PeronaLib.Flags["__drag_speed"]
            if ds2 and type(ds2) == "number" then
                -- Map 0.01-0.5 slider to lerp alpha: lower value = faster, higher = smoother
                speed = math.clamp(ds2, 0.01, 0.5)
            end
        end
        -- Lerp: lower speed = snappier, higher = smoother/laggier
        local alpha = math.clamp(1 - speed * 2, 0.05, 1)
        if speed <= 0.02 then
            frame.Position = targetPos
        else
            local cx = frame.Position.X.Offset + (targetPos.X.Offset - frame.Position.X.Offset) * alpha
            local cy = frame.Position.Y.Offset + (targetPos.Y.Offset - frame.Position.Y.Offset) * alpha
            frame.Position = UDim2.new(frame.Position.X.Scale, cx, frame.Position.Y.Scale, cy)
        end
    end)
    if winObj and winObj.AddConn then winObj:AddConn(c1); winObj:AddConn(c2); winObj:AddConn(c3) end
end
-- File-system helpers (executor env, gracefully no-ops if absent)
local function SafeWrite(path, data) pcall(function() writefile(path, data) end) end
local function SafeRead(path)
    local ok, v = pcall(function() return readfile(path) end)
    return ok and v or nil
end
local function SafeMkdir(path) pcall(function() if not isfolder(path) then makefolder(path) end end) end
local function SafeList(path)
    local ok, v = pcall(function() return listfiles(path) end)
    return ok and v or {}
end
local function SafeDel(path) pcall(function() delfile(path) end) end
-- ──────────────────────── SCREENGUI ────────────────────────────────────────
local Gui
pcall(function()
    Gui = game:GetService("CoreGui"):FindFirstChild("PeronaLib")
    if Gui then Gui:Destroy() end
    Gui = New("ScreenGui", { Name = "PeronaLib", ResetOnSpawn = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui })
end)
if not Gui then
    Gui = New("ScreenGui", { Name = "PeronaLib", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = LP:FindFirstChildOfClass("PlayerGui") })
end
PeronaLib.Gui = Gui
-- ═══════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════════════════════════
function PeronaLib:Window(opts)
    opts = opts or {}
    local title      = opts.Title      or "PeronaLib"
    local subtitle   = opts.Subtitle   or ""
    local W, H       = opts.Width or 560, opts.Height or 640
    local toggleKey  = opts.ToggleKey  or Enum.KeyCode.RightShift
    local folderName = opts.folder_name or "PeronaLib"
    local Win        = { Tabs = {}, Flags = PeronaLib.Flags, _tabOrder = 0, _keybinds = {}, _tabCount = 0, _userTabCount = 0, _settingsBuilt = false, _flagSetters = {}, _drawingMode = "InGame", _uiDrawingMethod = "InGame", _allowUnsafe = false }
    local Flags      = PeronaLib.Flags
    if shared._PeronaLib_Instance then
        pcall(function() shared._PeronaLib_Instance:Unload() end)
    end
    shared._PeronaLib_Instance = Win
    Win._espObjects   = {}
    Win._runtimeConns = {}
    Win._drawingObjects = {}
    local ESPHolder, ESPGui
    local GuiInsetY = 0
    pcall(function() GuiInsetY = game:GetService("GuiService"):GetGuiInset().Y end)
    Win._unloaded = false
    Win._inputFuncs = { changed = {}, ended = {}, began = {} }
    function Win:Debug(enabled)
        if not enabled then
            if Win._debugGui then pcall(function() Win._debugGui:Destroy() end); Win._debugGui = nil end
            if Win._debugConn then pcall(function() Win._debugConn:Disconnect() end); Win._debugConn = nil end
            return
        end
        if Win._debugGui then return end
        local sg = Instance.new("ScreenGui")
        sg.Name = "PeronaDebug"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 9999
        pcall(function() sg.Parent = (gethui and gethui()) or CoreGui end)
        if not sg.Parent then pcall(function() sg.Parent = LP:FindFirstChildOfClass("PlayerGui") end) end
        local fr = New("Frame", {
                Size = UDim2.new(0, 220, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = Color3.fromHex("0A0A0A"), BackgroundTransparency = 0.15,
            BorderSizePixel = 0, Parent = sg,
        }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            New("UIStroke", { Color = T.Border, Thickness = 1 }),
            New("UIPadding", { PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,6) }),
            New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2) }),
        })
        -- Draggable header
        local dbgHeader = New("TextLabel", {
                Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1,
            Text = "PeronaLib Debugger", TextColor3 = T.Accent,
            Font = T.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0, Parent = fr,
        })
        New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Border,BorderSizePixel=0,LayoutOrder=1,Parent=fr})
        MakeDraggable(fr, dbgHeader)
        local lbl = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, TextColor3 = Color3.fromHex("AAAAAA"),
            Font = T.Font, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            RichText = true, LayoutOrder = 2, Parent = fr,
        })
        Win._debugGui = sg
        local frames, lastFps, fpsTick = 0, 0, tick()
        local memUsage = 0
        Win._debugConn = RS.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - fpsTick >= 1 then
                lastFps = frames
                frames = 0
                fpsTick = tick()
                pcall(function() memUsage = math.round(gcinfo() / 1024 * 10) / 10 end)
            end
            local flagCount = 0; for _ in pairs(Flags) do flagCount = flagCount + 1 end
            local accentHex = string.format("#%02X%02X%02X", math.round(T.Accent.R*255), math.round(T.Accent.G*255), math.round(T.Accent.B*255))
            local dim = "#666666"
            local t = ""
            t = t .. ('<font color="'..dim..'">FPS:</font> <font color="'..accentHex..'">'..tostring(lastFps)..'</font>\n')
            t = t .. ('<font color="'..dim..'">Memory:</font> '..tostring(memUsage)..' MB\n')
            t = t .. ('<font color="'..dim..'">ESP Objects:</font> '..tostring(#Win._espObjects)..'\n')
            t = t .. ('<font color="'..dim..'">Connections:</font> '..tostring(#Win._runtimeConns)..'\n')
            t = t .. ('<font color="'..dim..'">Flags:</font> '..tostring(flagCount)..'\n')
            t = t .. ('<font color="'..dim..'">Drawing:</font> '..tostring(Win._drawingMode)..'\n')
            t = t .. ('<font color="'..dim..'">Unsafe:</font> '..(Win._allowUnsafe and '<font color="#FF3A3A">ON</font>' or '<font color="#3CFF6E">OFF</font>')..'\n')
            t = t .. ('<font color="'..dim..'">Game:</font> '..(Win._selectedGame or "N/A"))
            lbl.Text = t
        end)
        table.insert(Win._runtimeConns, Win._debugConn)
    end
    function Win:IsUnsafeAllowed()
        return Win._allowUnsafe == true
    end
    -- ── Notification System (compact watermark-style) ─────────────────────
    local _notifyGui
    local _notifyHolder
    local function EnsureNotifyGui()
        if _notifyGui and _notifyGui.Parent then return end
        _notifyGui = New("ScreenGui", { Name = "PeronaNotify", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10000 })
        pcall(function() _notifyGui.Parent = (gethui and gethui()) or CoreGui end)
        if not _notifyGui.Parent then pcall(function() _notifyGui.Parent = LP:FindFirstChildOfClass("PlayerGui") end) end
        _notifyHolder = New("Frame", {
                Size = UDim2.new(0,0,0,0), AutomaticSize = Enum.AutomaticSize.XY,
            Position = UDim2.new(0.5,0,0,10), AnchorPoint = Vector2.new(0.5,0),
            BackgroundTransparency = 1, Parent = _notifyGui,
        }, {
                New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0,4) })
        })
    end
    function Win:Notify(opts)
        opts = type(opts) == "string" and { Text = opts } or (opts or {})
        local title = opts.Title or "PeronaLib"
        local text = opts.Text or ""
        local dur = opts.Duration or 3
        local nType = opts.Type or "Info"
        local colors = { Info = T.Accent, Warning = Color3.fromHex("FFB93A"), Error = Color3.fromHex("FF3A3A"), Success = Color3.fromHex("3CFF6E") }
        local accentC = colors[nType] or T.Accent
        EnsureNotifyGui()
        -- Build inline text: "Title: body" or just "Title"
        local displayText = text ~= "" and (title .. ": " .. text) or title
        local card = New("Frame", {
                Size = UDim2.new(0,0,0,20), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromHex("0C0C0C"), BorderSizePixel = 0,
            ClipsDescendants = true, Parent = _notifyHolder,
        }, {
                New("UICorner", { CornerRadius = UDim.new(0,2) }),
            New("UIStroke", { Color = accentC, Thickness = 1 }),
            New("UIPadding", { PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) }),
        })
        New("TextLabel", {
                Size = UDim2.new(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1, Text = displayText,
            TextColor3 = accentC, Font = T.Font, TextSize = 12,
            RichText = true, Parent = card,
        })
        -- Progress bar at bottom
        local prog = New("Frame", {
                Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2),
            BackgroundColor3 = accentC, BorderSizePixel = 0, ZIndex = 2, Parent = card,
        })
        -- Animate
        card.BackgroundTransparency = 1
        Tween(card, { BackgroundTransparency = 0 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        Tween(prog, { Size = UDim2.new(0,0,0,2) }, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        -- Auto-dismiss
        task.delay(dur, function()
            pcall(function()
                Tween(card, { BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.wait(0.25)
                card:Destroy()
            end)
        end)
        return card
    end
    function Win:AddConn(conn)
        if Win._unloaded then pcall(function() conn:Disconnect() end); return end
        table.insert(Win._runtimeConns, conn)
        return conn
    end
    local myUIS = game:GetService("UserInputService")
    local UIS = setmetatable({
        InputBegan = { Connect = function(_, fn) table.insert(Win._inputFuncs.began, fn); return {Disconnect=function() end} end },
        InputChanged = { Connect = function(_, fn) table.insert(Win._inputFuncs.changed, fn); return {Disconnect=function() end} end },
        InputEnded = { Connect = function(_, fn) table.insert(Win._inputFuncs.ended, fn); return {Disconnect=function() end} end },
    }, { __index = function(_, k)
        local val = myUIS[k]
        if type(val) == "function" then
            return function(_, ...) return val(myUIS, ...) end
        end
        return val
    end })

    Win:AddConn(myUIS.InputBegan:Connect(function(inp, gpe)
        for _, fn in ipairs(Win._inputFuncs.began) do fn(inp, gpe) end
    end))
    Win:AddConn(myUIS.InputChanged:Connect(function(inp, gpe)
        for _, fn in ipairs(Win._inputFuncs.changed) do fn(inp, gpe) end
    end))
    Win:AddConn(myUIS.InputEnded:Connect(function(inp, gpe)
        for _, fn in ipairs(Win._inputFuncs.ended) do fn(inp, gpe) end
    end))
    
    function Win:Runtime(fn)
        if Win._unloaded then return end
        local conn = RS.Heartbeat:Connect(function(dt)
            if Win._unloaded then return end
            pcall(fn, dt)
        end)
        table.insert(Win._runtimeConns, conn)
        return conn
    end
    SafeMkdir(folderName)
    SafeMkdir(folderName .. "/configs")
    SafeMkdir(folderName .. "/themes")
-- ── Main Frame ──────────────────────────────────────────────────────────
    local Main = New("Frame", {
            Name = "PeronaWin", Size = UDim2.new(0, W, 0, H),
        Position = UDim2.new(.5, -W/2, .5, -H/2),
        BackgroundColor3 = T.Bg, BorderSizePixel = 0,
        ClipsDescendants = false, Parent = Gui,
    }, {
            New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        New("UIStroke", { Color = T.Border, Thickness = 1 }),
    })
    OnTheme(Main, "BackgroundColor3", "Bg")
    -- ── Header ──────────────────────────────────────────────────────────────
    local Header = New("Frame", {
            Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Surface1,
        BorderSizePixel = 0, ZIndex = 2, Parent = Main,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    -- fill bottom half so top corners only show
    New("Frame", {
            Size = UDim2.new(1, 0, .5, 0), Position = UDim2.new(0, 0, .5, 0),
        BackgroundColor3 = T.Surface1, BorderSizePixel = 0, ZIndex = 2, Parent = Header,
    })
    OnTheme(Header, "BackgroundColor3", "Surface1")
    local pref, suf = title:match("^(%a+)(.*)")
    local function titleRich()
        if pref and suf then
            return ('<font color="#FF1D6A">%s</font>%s'):format(pref, suf)
        end
        return title
    end
    local TitleLbl = New("TextLabel", {
            Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Font = T.Font, TextSize = 13,
        TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true, ZIndex = 3, Parent = Header,
    })
    local function UpdateTitle()
        local sub = subtitle ~= "" and (' <font color="#333333">~ '..subtitle.."</font>") or ""
        TitleLbl.Text = titleRich()..sub
    end
    UpdateTitle()
    local CloseBtn = New("TextButton", {
            Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -26, .5, -10),
        BackgroundTransparency = 1, Text = "×", TextColor3 = T.TextDim,
        Font = T.Font, TextSize = 16, ZIndex = 3, Parent = Header,
    })
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = T.Text end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = T.TextDim end)
    MakeDraggable(Main, Header)
    -- ── Tab Bar (inside Main, below header) ──────────────────────────────────
    local TabBar = New("Frame", {
            Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = T.Surface1, BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 2, Parent = Main,
    }, {
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    OnTheme(TabBar, "BackgroundColor3", "Surface1")
    -- Tab bar bottom border (separate from TabBar so UIListLayout doesn't affect it)
    New("Frame", {
            Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 57),
        BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 3, Parent = Main,
    })
    -- ── Content Area (fills remaining space inside Main) ─────────────────────
    local ContentArea = New("Frame", {
            Size = UDim2.new(1, 0, 1, -58), Position = UDim2.new(0, 0, 0, 58),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
    })
    -- ── HUD Watermark ───────────────────────────────────────────────────────
    local HUD = New("Frame", {
            Size = UDim2.new(0, 0, 0, 20), Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Color3.fromHex("0C0C0C"),
        BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Parent = Gui,
    }, {
            New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        New("UIStroke", { Color = T.Border, Thickness = 1 }),
        New("UIPadding", { PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) }),
    })
    local HudLbl = New("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, Font = T.Font, TextSize = 12,
        TextColor3 = T.Text, RichText = true, Parent = HUD,
    })
    local hudMode = "Title, Fps, Ping"
    local fps, pingVal = 60, 0
    local frames = 0
    Win:Runtime(function() frames = frames + 1 end)
    task.spawn(function()
        local lastTime = tick()
        while task.wait(0.5) do
            if Win._unloaded then break end
            local now = tick()
            local dt = now - lastTime
            if lastTime > 0 then
                fps = math.round(frames / dt)
            end
            frames = 0
            lastTime = now
            pcall(function() pingVal = math.round(LP:GetNetworkPing()*1000) end)
            if not HUD.Visible then continue end
            local t = os.date("*t") or {}
            local timeStr = ("%02d:%02d:%02d"):format(t.hour or 0, t.min or 0, t.sec or 0)
            local dateStr = ("%02d/%02d/%04d"):format(t.month or 1, t.day or t.mday or 1, t.year or 2025)
            local dim = '#333333'
            if hudMode == "Title, Fps, Ping" then
                HudLbl.Text = ('%s <font color="%s">~ %d fps | %d ms | %s | %s</font>'):format(
                        titleRich(), dim, fps, pingVal, dateStr, timeStr)
            elseif hudMode == "Title only" then
                HudLbl.Text = ('%s <font color="%s">~ %s | %s</font>'):format(titleRich(), dim, dateStr, timeStr)
            elseif hudMode == "Fps only" then
                HudLbl.Text = ('<font color="%s">%d fps | %d ms | %s | %s</font>'):format(dim, fps, pingVal, dateStr, timeStr)
            else
                HudLbl.Text = ""
            end
        end
    end)
    -- ── Keybind List Overlay ─────────────────────────────────────────────────
    local KBOverlay = New("Frame", {
            Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 10, 0, 38),
        BackgroundColor3 = Color3.fromHex("0C0C0C"), BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY, Visible = true, Parent = Gui,
    }, {
            New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        New("UIStroke", { Color = T.Border, Thickness = 1 }),
        New("UIPadding", {
                PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,8),
            PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4),
        }),
    })
    local KBList = New("Frame", {
            Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1, Parent = KBOverlay,
    }, {
            New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2) }),
    })
    New("TextLabel", {
            Size = UDim2.new(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, Font = T.Font, TextSize = 12,
        TextColor3 = T.Accent, Text = "keybinds",
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = KBList,
    })
    Win.KBList    = KBList
    Win.KBOverlay = KBOverlay
    -- ── Right-click Context Menu (singleton) ──────────────────────────────────
    local CtxMenu = New("Frame", {
            Size = UDim2.new(0, 120, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
        Visible = false, ZIndex = 60, Parent = Gui,
    }, {
            New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        New("UIStroke", { Color = T.Border, Thickness = 1 }),
        New("UIPadding", { PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3) }),
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1) }),
    })
    local function ShowCtx(pos, items)
        for _, c in pairs(CtxMenu:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, item in ipairs(items) do
            local B = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
                Text = item.label, TextColor3 = item.color or T.Text,
                Font = T.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i, ZIndex = 61, Parent = CtxMenu,
            }, { New("UIPadding", { PaddingLeft = UDim.new(0,8) }) })
B.MouseEnter:Connect(function()
                B.BackgroundTransparency = 0; B.BackgroundColor3 = T.Surface3
            end)
            B.MouseLeave:Connect(function() B.BackgroundTransparency = 1 end)
            B.MouseButton1Click:Connect(function()
                CtxMenu.Visible = false
                if item.cb then item.cb() end
            end)
        end
        CtxMenu.Position = UDim2.new(0, pos.X, 0, pos.Y)
        CtxMenu.Visible  = true
    end
    Win:AddConn(UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and CtxMenu.Visible then
            -- Delay so TextButton click handlers can fire first
            task.defer(function()
                if CtxMenu.Visible then CtxMenu.Visible = false end
            end)
        end
    end))
    -- ═══════════════════════════════════════════════════════════════════════
    --  TAB BUILDER
    -- ═══════════════════════════════════════════════════════════════════════
    function Win:Tab(tabName, _isInternal)
        Win._tabOrder = Win._tabOrder + 1
        local tabIdx  = Win._tabOrder
        if not _isInternal then
            Win._userTabCount = Win._userTabCount + 1
        end
        Win._tabCount = Win._tabCount + 1
        local Tab = { Name = tabName, _leftOrder = 0, _rightOrder = 0, _isInternal = _isInternal }
        -- Settings tab always gets very high LayoutOrder so it sorts last
        local layoutOrd = tabName == "Settings" and 999999 or (_isInternal and 900000 + tabIdx or tabIdx)
        local TabBtn = New("TextButton", {
                Size = UDim2.new(1/4, 0, 1, 0),
            BackgroundColor3 = T.Surface1, BorderSizePixel = 0,
            Text = tabName, TextColor3 = T.TextDim,
            Font = T.Font, TextSize = 12, LayoutOrder = layoutOrd, Parent = TabBar,
        }, { New("UIStroke", { Color = T.Border, Thickness = 1 }) })
        OnTheme(TabBtn, "BackgroundColor3", "Surface1")
        local ActiveLine = New("Frame", {
                Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0,
            BackgroundTransparency = 1, Parent = TabBtn,
        })
        OnTheme(ActiveLine, "BackgroundColor3", "Accent")
        local TabContent = New("Frame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Visible = false, Parent = ContentArea,
        })
        -- Left panel
        local LeftPanel = New("ScrollingFrame", {
                Size = UDim2.new(.5, -1, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = TabContent,
        }, {
                New("UIPadding", { PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
                PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8) }),
            New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6) }),
        })
        -- Divider
        New("Frame", {
                Size = UDim2.new(0,1,1,0), Position = UDim2.new(.5,0,0,0),
            BackgroundColor3 = T.Border, BorderSizePixel = 0, Parent = TabContent,
        })
        -- Right panel
        local RightPanel = New("ScrollingFrame", {
                Size = UDim2.new(.5,-1,1,0), Position = UDim2.new(.5,1,0,0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = TabContent,
        }, {
                New("UIPadding", { PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
                PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8) }),
            New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6) }),
        })
        Tab.LeftPanel  = LeftPanel
        Tab.RightPanel = RightPanel
        Tab.Content    = TabContent
        Tab._tabBtn    = TabBtn
        Tab._tabLine   = ActiveLine
        local function Select()
            for _, t in pairs(Win.Tabs) do
t.Content.Visible = false
                t._tabBtn.TextColor3 = T.TextDim
                t._tabLine.BackgroundTransparency = 1
            end
            TabContent.Visible = true
            TabBtn.TextColor3 = T.Text
            ActiveLine.BackgroundTransparency = 0
            Win.ActiveTab = Tab
        end
        Tab._Select = Select
        TabBtn.MouseButton1Click:Connect(Select)
        -- Auto-select: only the first USER tab auto-selects (not Settings)
        if not _isInternal and Win._userTabCount == 1 then
            Select()
        end
        -- Resize all tab buttons to share bar equally
        local totalBtns = 0
        for _, child in pairs(TabBar:GetChildren()) do
            if child:IsA("TextButton") then totalBtns = totalBtns + 1 end
        end
        for _, child in pairs(TabBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.new(1 / totalBtns, 0, 1, 0)
            end
        end
        Win.Tabs[tabName] = Tab
        -- ════════════════════════════════════════════════════════════════
        --  SECTION BUILDER
        -- ════════════════════════════════════════════════════════════════
        local function BuildSection(panel, orderRef, o)
            local sName = type(o) == "string" and o or (o and o.Name or "Section")
            Tab[orderRef] = Tab[orderRef] + 1
            local order   = Tab[orderRef]
            local SF = New("Frame", {
                    Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.Surface1, BorderSizePixel = 0,
                LayoutOrder = order, ClipsDescendants = false, Parent = panel,
            }, {
                    New("UICorner", { CornerRadius = UDim.new(0,3) }),
                New("UIStroke", { Color = T.Border, Thickness = 1 }),
                New("UIPadding", { PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
                    PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,8) }),
                New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5) }),
            })
            OnTheme(SF, "BackgroundColor3", "Surface1")
            local Sec = { Frame = SF, _order = 0 }
            if sName ~= "" then
                New("TextLabel", {
                        Size = UDim2.new(1,0,0,13), BackgroundTransparency = 1,
                    Text = sName, TextColor3 = T.TextDim, Font = T.Font,
                    TextSize = T.FontSm, TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 0, Parent = SF,
                })
            end
            local function nxt() Sec._order = Sec._order + 1; return Sec._order + 1 end
            -- ── TOGGLE (with optional Settings gear icon) ─────────────────
            function Sec:Toggle(o)
                o = o or {}
                local name = o.Name or "Toggle"; local val = o.Default or false
                local flag = o.Flag or name;     local cb  = o.Callback or function() end
                local settings = o.Settings
                local isUnsafe = o.Unsafe == true
                Flags[flag] = val
                local settingsData = {}
                local rightOffset = (settings and settings.use) and 18 or 0
                -- Unsafe: prefix name with red indicator
                local displayName = isUnsafe and ('<font color="#FF3A3A">⚠</font> ' .. name) or name
                local Row = New("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                local Box = New("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,0,.5,-6),BackgroundColor3=val and T.Accent or Color3.fromHex("1A1A1A"),BorderSizePixel=0,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local BoxStroke = New("UIStroke",{Color=val and T.Accent or T.Border,Thickness=1,Parent=Box})
                local Check = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=val and "✓" or "",TextColor3=T.Text,Font=T.Font,TextSize=10,Parent=Box})
                local Lbl = New("TextLabel",{Size=UDim2.new(1,-(18+rightOffset),1,0),Position=UDim2.new(0,18,0,0),BackgroundTransparency=1,Text=displayName,TextColor3=val and T.Text or T.TextDim,Font=T.Font,TextSize=T.FontMd,TextXAlignment=Enum.TextXAlignment.Left,RichText=true,Parent=Row})
local Hit = New("TextButton",{Size=UDim2.new(1,-rightOffset,1,0),BackgroundTransparency=1,Text="",Parent=Row})
                local function Set(v)
                    -- Unsafe gate: block if unsafe and not allowed
                    if isUnsafe and v and not Win:IsUnsafeAllowed() then
                        Win:Notify({ Title = "⚠ Unsafe Blocked", Text = '"' .. name .. '" requires Allow Unsafe to be enabled in Settings > Options.', Duration = 4, Type = "Error" })
                        return
                    end
                    val=v;Flags[flag]=v
                    Tween(Box,{BackgroundColor3=v and T.Accent or Color3.fromHex("1A1A1A")},.12)
                    BoxStroke.Color=v and T.Accent or T.Border; Check.Text=v and "✓" or ""
                    Lbl.TextColor3=v and T.Text or T.TextDim; cb(v, settingsData)
                end
                Hit.MouseButton1Click:Connect(function() Set(not val) end)
                -- Settings gear icon + sub-panel
                if settings and settings.use then
                    local gearBtn = New("TextButton",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-16,.5,-8),BackgroundColor3=T.Surface3,BorderSizePixel=0,Text="⚙",TextColor3=T.TextDim,Font=T.Font,TextSize=11,ZIndex=5,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                    local settingsOpen = false
                    local SPanel = New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=T.Surface2,BorderSizePixel=0,Visible=false,LayoutOrder=nxt(),ClipsDescendants=true,Parent=SF},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1}),New("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)}),New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)})})
                    local sOrd = 0
                    for sKey, sVal in pairs(settings) do
                        if sKey ~= "use" and type(sVal) == "table" then
                            sOrd = sOrd + 1
                            local sFlag = flag .. "_s_" .. sKey
                            local selVal = sVal[1] or "None"
                            settingsData[sKey] = selVal; Flags[sFlag] = selVal
                            New("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text=sKey,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=sOrd*2-1,Parent=SPanel})
                            local SB = New("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundColor3=T.Surface3,BorderSizePixel=0,Text="",LayoutOrder=sOrd*2,Parent=SPanel},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                            local SBT = New("TextLabel",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text=selVal,TextColor3=T.Text,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=SB})
                            local sdOpen = false
                            local SD = New("Frame",{Size=UDim2.new(1,0,0,#sVal*20),BackgroundColor3=T.Surface2,BorderSizePixel=0,Visible=false,ZIndex=15,LayoutOrder=sOrd*2+1,Parent=SPanel},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1}),New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})})
                            for si, sIt in ipairs(sVal) do
                                local sel = sIt == selVal
                                local IB = New("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundColor3=sel and Color3.fromHex("1A1A1A") or T.Surface2,BackgroundTransparency=sel and 0 or 1,BorderSizePixel=0,Text=sIt,TextColor3=sel and T.Accent or T.Text,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=si,ZIndex=16,Parent=SD},{New("UIPadding",{PaddingLeft=UDim.new(0,6)})})
                                IB.MouseButton1Click:Connect(function()
                                    selVal=sIt; settingsData[sKey]=sIt; Flags[sFlag]=sIt; SBT.Text=sIt; sdOpen=false; SD.Visible=false
                                    for _,c in pairs(SD:GetChildren()) do if c:IsA("TextButton") then local s=c.Text==sIt; c.TextColor3=s and T.Accent or T.Text; c.BackgroundTransparency=s and 0 or 1; c.BackgroundColor3=s and Color3.fromHex("1A1A1A") or T.Surface2 end end
                                    cb(val, settingsData)
                                end)
                            end
                            SB.MouseButton1Click:Connect(function() sdOpen=not sdOpen; SD.Visible=sdOpen end)
                        end
                    end
gearBtn.MouseEnter:Connect(function() Tween(gearBtn,{BackgroundColor3=T.Surface2},.1) end)
                    gearBtn.MouseLeave:Connect(function() Tween(gearBtn,{BackgroundColor3=T.Surface3},.1) end)
                    gearBtn.MouseButton1Click:Connect(function() settingsOpen=not settingsOpen; SPanel.Visible=settingsOpen; gearBtn.TextColor3=settingsOpen and T.Accent or T.TextDim end)
                end
                Win._flagSetters[flag] = function(v) Set(v) end
                local Obj={Flag=flag,Settings=settingsData}; function Obj:Get() return val end; function Obj:Set(v) Set(v) end; return Obj
            end
            -- ── SLIDER ────────────────────────────────────────────────────
            function Sec:Slider(o)
                o=o or{}; local name=o.Name or"Slider"; local min=o.Min or 0; local max=o.Max or 100
                local val=o.Default or min; local suf=o.Suffix or""; local dec=o.Decimals or 0
                local flag=o.Flag or name; local cb=o.Callback or function()end; Flags[flag]=val
                local Wrap=New("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                New("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=name,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,Parent=Wrap})
                local Track=New("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,18),BackgroundColor3=Color3.fromHex("0E0E0E"),BorderSizePixel=0,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local Fill=New("Frame",{Size=UDim2.new((val-min)/(max-min),0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=Track},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                OnTheme(Fill,"BackgroundColor3","Accent")
                local ValLbl=New("TextLabel",{Size=UDim2.new(1,-4,1,0),BackgroundTransparency=1,Text=tostring(val)..suf,TextColor3=T.Text,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Right,Parent=Track})
                local drag=false
                local function Update(x) local t=math.clamp((x-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1); val=Round(min+(max-min)*t,dec); Flags[flag]=val; Fill.Size=UDim2.new(t,0,1,0); ValLbl.Text=tostring(val)..suf; cb(val) end
                Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;Update(i.Position.X) end end)
                Win:AddConn(UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then Update(i.Position.X) end end))
                Win:AddConn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end))
                local Obj={Flag=flag}; function Obj:Get() return val end
                function Obj:Set(v) val=math.clamp(v,min,max);Flags[flag]=val;local t=(val-min)/(max-min);Fill.Size=UDim2.new(t,0,1,0);ValLbl.Text=tostring(val)..suf;cb(val) end
                -- Register setter for config loading
                Win._flagSetters[flag] = function(v) if type(v)=="number" then Obj:Set(v) end end
                return Obj
            end
            -- ── RANGE SLIDER ──────────────────────────────────────────────
            function Sec:RangeSlider(o)
                o=o or{}; local name=o.Name or"Range Slider"; local min=o.Min or 0; local max=o.Max or 100
                local defLo=o.DefaultLow or min; local defHi=o.DefaultHigh or max; local dec=o.Decimals or 1
                local flag=o.Flag or name; local cb=o.Callback or function()end; local lo,hi=defLo,defHi; Flags[flag]={lo,hi}
                local Wrap=New("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                New("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=name,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,Parent=Wrap})
local Track=New("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,18),BackgroundColor3=Color3.fromHex("0E0E0E"),BorderSizePixel=0,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local RangeFill=New("Frame",{BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=Track},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                OnTheme(RangeFill,"BackgroundColor3","Accent")
                local ValLbl=New("TextLabel",{Size=UDim2.new(1,-4,1,0),BackgroundTransparency=1,TextColor3=T.Text,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Right,Parent=Track})
                local function MkH() return New("Frame",{Size=UDim2.new(0,8,1,4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0),BackgroundColor3=T.Text,BorderSizePixel=0,ZIndex=3,Parent=Track},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=Color3.fromHex("444444"),Thickness=1})}) end
                local HndLo=MkH(); local HndHi=MkH()
                local function Refresh() Flags[flag]={lo,hi}; local tl=(lo-min)/(max-min); local th=(hi-min)/(max-min); RangeFill.Position=UDim2.new(tl,0,0,0); RangeFill.Size=UDim2.new(th-tl,0,1,0); HndLo.Position=UDim2.new(tl,0,.5,0); HndHi.Position=UDim2.new(th,0,.5,0); ValLbl.Text=tostring(lo).."-"..tostring(hi); cb(lo,hi) end
                Refresh()
                local function DH(h,isHi) local d=false; h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true end end); Win:AddConn(UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then local t=math.clamp((i.Position.X-Track.AbsolutePosition.X)/Track.AbsoluteSize.X,0,1); local v=Round(min+(max-min)*t,dec); if isHi then hi=math.max(v,lo) else lo=math.min(v,hi) end; Refresh() end end)); Win:AddConn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)) end
                DH(HndLo,false); DH(HndHi,true)
                local Obj={Flag=flag}; function Obj:Get() return lo,hi end; return Obj
            end
            -- ── INPUT ─────────────────────────────────────────────────────
            function Sec:Input(o)
                o=o or{}; local name=o.Name or"Input"; local phld=o.Placeholder or"Input here..."; local def=o.Default or""; local flag=o.Flag or name; local cb=o.Callback or function()end; local val=def; Flags[flag]=val
                local Wrap=New("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                New("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=name,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,Parent=Wrap})
                local Bg=New("Frame",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,18),BackgroundColor3=Color3.fromHex("0E0E0E"),BorderSizePixel=0,ClipsDescendants=true,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local TB=New("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,Text=def,PlaceholderText=phld,PlaceholderColor3=T.TextDim,TextColor3=T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,TextTruncate=Enum.TextTruncate.AtEnd,Parent=Bg})
                TB.Focused:Connect(function() Tween(Bg:FindFirstChildOfClass("UIStroke"),{Color=T.Accent},.1); TB.TextTruncate=Enum.TextTruncate.None end)
                TB.FocusLost:Connect(function(e) Tween(Bg:FindFirstChildOfClass("UIStroke"),{Color=T.Border},.1); val=TB.Text; Flags[flag]=val; cb(val,e) end)
                local Obj={Flag=flag}; function Obj:Get() return val end; function Obj:Set(v) val=v;TB.Text=v;Flags[flag]=v end
                -- Register setter for config loading
                Win._flagSetters[flag] = function(v) if type(v)=="string" then Obj:Set(v) end end
                return Obj
            end
            -- ── DROPDOWN ──────────────────────────────────────────────────
            function Sec:Dropdown(o)
o=o or{}; local name=o.Name or"Dropdown"; local items=o.Items or{}; local multi=o.Multi or false; local search=o.Search or false; local flag=o.Flag or name; local cb=o.Callback or function()end
                local val=o.Default or(multi and{} or(items[1] or"None")); Flags[flag]=val; local openState=false
                local Wrap=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF,ClipsDescendants=false})
                New("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=name,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,Parent=Wrap})
                local Btn=New("TextButton",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,16),BackgroundColor3=T.Surface2,BorderSizePixel=0,Text="",Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local BtnTxt=New("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text=multi and(type(val)=="table" and table.concat(val,", ") or"None") or tostring(val),TextColor3=T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=Btn})
                New("TextLabel",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),BackgroundTransparency=1,Text="−",TextColor3=T.TextDim,Font=T.Font,TextSize=14,Parent=Btn})
                local ListH=math.min(#items,6)*20; local SearchH=search and 22 or 0
                local DropPanel=New("Frame",{Size=UDim2.new(1,0,0,ListH+SearchH),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.Surface2,BorderSizePixel=0,Visible=false,ZIndex=10,ClipsDescendants=true,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local SearchBox
                if search then local SBg=New("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=T.Surface1,BorderSizePixel=0,ZIndex=11,Parent=DropPanel},{New("UIStroke",{Color=T.Border,Thickness=1})}); SearchBox=New("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,PlaceholderText="Search...",PlaceholderColor3=T.TextDim,TextColor3=T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=11,Parent=SBg}) end
                local ItemList=New("ScrollingFrame",{Size=UDim2.new(1,0,0,ListH),Position=UDim2.new(0,0,0,SearchH),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=11,Parent=DropPanel},{New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})})
                local function UD() if multi then BtnTxt.Text=(type(val)=="table" and #val>0) and table.concat(val,", ") or"None" else BtnTxt.Text=tostring(val) end end
                local function BI(f) for _,c in pairs(ItemList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                    for i,item in ipairs(items) do if f and not item:lower():find(f:lower(),1,true) then continue end
                        local sel=multi and(type(val)=="table" and table.find(val,item)) or(val==item)
                        local IB=New("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundColor3=sel and Color3.fromHex("1A1A1A") or Color3.fromHex("181818"),BackgroundTransparency=sel and 0 or 1,BorderSizePixel=0,Text=item,TextColor3=sel and T.Accent or T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=i,ZIndex=12,Parent=ItemList},{New("UIPadding",{PaddingLeft=UDim.new(0,6)})})
                        IB.MouseEnter:Connect(function() if not(multi and type(val)=="table" and table.find(val,item)) and val~=item then IB.BackgroundTransparency=0;IB.BackgroundColor3=Color3.fromHex("222222") end end)
                        IB.MouseLeave:Connect(function() local s=multi and(type(val)=="table" and table.find(val,item)) or(val==item); IB.BackgroundTransparency=s and 0 or 1; IB.BackgroundColor3=s and Color3.fromHex("1A1A1A") or Color3.fromHex("181818") end)
IB.MouseButton1Click:Connect(function() if multi then if type(val)~="table" then val={} end; local idx=table.find(val,item); if idx then table.remove(val,idx) else table.insert(val,item) end else val=item;openState=false;DropPanel.Visible=false end; Flags[flag]=val;UD();cb(val);BI(SearchBox and SearchBox.Text or nil) end)
                    end end
                BI()
                if SearchBox then SearchBox:GetPropertyChangedSignal("Text"):Connect(function() BI(SearchBox.Text) end) end
                Btn.MouseButton1Click:Connect(function() openState=not openState;DropPanel.Visible=openState; if openState and SearchBox then SearchBox.Text="";BI() end end)
                local Obj={Flag=flag}; function Obj:Get() return val end; function Obj:Set(v) val=v;Flags[flag]=v;UD();cb(v) end; function Obj:Refresh(ni) items=ni;BI() end
                -- Register setter for config loading
                Win._flagSetters[flag] = function(v) Obj:Set(v) end
                return Obj
            end
            -- ── BUTTON / BUTTON ROW ───────────────────────────────────────
            function Sec:Button(o)
                o=o or{}; local name=type(o)=="string" and o or o.Name or"Button"; local cb=(type(o)=="table" and o.Callback) or function()end
                local B=New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundColor3=T.Surface2,BorderSizePixel=0,Text=name,TextColor3=T.Text,Font=T.Font,TextSize=12,LayoutOrder=nxt(),Parent=SF},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                B.MouseEnter:Connect(function() Tween(B,{BackgroundColor3=T.Surface3},.1) end); B.MouseLeave:Connect(function() Tween(B,{BackgroundColor3=T.Surface2},.1) end)
                B.MouseButton1Click:Connect(function() Tween(B,{BackgroundColor3=T.Accent},.08); task.delay(.18,function() Tween(B,{BackgroundColor3=T.Surface2},.15) end); cb() end); return{Name=name}
            end
            function Sec:ButtonRow(buttons)
                local Row=New("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF},{New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)})})
                local n=#buttons
                for i,b in ipairs(buttons) do
                    local Btn=New("TextButton",{Size=UDim2.new(1/n,-(4*(n-1)/n),1,0),BackgroundColor3=T.Surface2,BorderSizePixel=0,Text=b.Name or"Btn",TextColor3=T.Text,Font=T.Font,TextSize=12,LayoutOrder=i,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                    Btn.MouseEnter:Connect(function() Tween(Btn,{BackgroundColor3=T.Surface3},.1) end); Btn.MouseLeave:Connect(function() Tween(Btn,{BackgroundColor3=T.Surface2},.1) end)
                    local fn=b.Callback or function()end; Btn.MouseButton1Click:Connect(function() Tween(Btn,{BackgroundColor3=T.Accent},.08); task.delay(.18,function() Tween(Btn,{BackgroundColor3=T.Surface2},.15) end); fn() end)
                end
            end
            -- ── KEYBIND (left-click=listen, click mode label=cycle mode) ──
            function Sec:Keybind(o)
                o=o or{}
                local name       = o.Name    or "Keybind"
                local defKey     = o.Default or Enum.KeyCode.Unknown
                local flag       = o.Flag    or name
                local mode       = o.Mode    or "Toggle"
                local cb         = o.Callback or function() end
                local key        = defKey
                local inputType  = (key == Enum.KeyCode.Unknown and o.InputType) or Enum.UserInputType.Keyboard
                local listen, active = false, false
                Flags[flag] = key
                Flags[flag.."_Mode"] = mode
                local modeList = {"Toggle", "Hold", "Always"}
                local Row=New("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                New("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=name,TextColor3=T.Text,Font=T.Font,TextSize=T.FontMd,TextXAlignment=Enum.TextXAlignment.Left,Parent=Row})
                local ModeBtn=New("TextButton",{Size=UDim2.new(0,18,0,16),Position=UDim2.new(1,-58,.5,-8),BackgroundColor3=T.Surface3,BorderSizePixel=0,Text=mode:sub(1,1),TextColor3=T.TextDim,Font=T.Font,TextSize=10,ZIndex=5,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local KBBtn=New("TextButton",{Size=UDim2.new(0,38,0,18),Position=UDim2.new(1,-38,.5,-9),BackgroundColor3=T.Surface2,BorderSizePixel=0,Font=T.Font,TextSize=11,TextColor3=T.TextDim,ZIndex=4,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local KBLbl
                if showInList then
                    KBLbl=New("TextLabel",{Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Font=T.Font,TextSize=12,TextColor3=T.TextDim,RichText=true,LayoutOrder=#Win._keybinds+2,Parent=Win.KBList})
                    table.insert(Win._keybinds,KBLbl)
                end
                local function FormatKeyName(k, t)
                    if t == Enum.UserInputType.MouseButton1 then return "MB1"
                    elseif t == Enum.UserInputType.MouseButton2 then return "MB2"
                    elseif t == Enum.UserInputType.MouseButton3 then return "MB3"
                    elseif k ~= Enum.KeyCode.Unknown then return k.Name
                    else return "?" end
                end

                local function UpdateKBLbl()
                    if not KBLbl then return end
                    local kn = FormatKeyName(key, inputType)
                    if active then
                        -- Active state: accent color for key, white for name
                        local accentHex = string.format("#%02X%02X%02X", math.round(T.Accent.R*255), math.round(T.Accent.G*255), math.round(T.Accent.B*255))
                        KBLbl.Text=('<font color="'..accentHex..'">[%s]</font> <font color="#FFFFFF">%s (%s)</font>'):format(kn,name,mode)
                    else
                        -- Inactive state: dim colors
                        KBLbl.Text=('<font color="#555555">[%s]</font> <font color="#888888">%s (%s)</font>'):format(kn,name,mode)
                    end
                end
                local function UpdateKB()
                    if listen then 
                        KBBtn.Text="..."; KBBtn.TextColor3=T.Accent
                    else 
                        local kn = FormatKeyName(key, inputType)
                        KBBtn.Text="["..kn:sub(1,3).."]"; KBBtn.TextColor3=T.TextDim 
                    end
                    ModeBtn.Text=mode:sub(1,1)
                    ModeBtn.TextColor3 = (mode=="Always") and T.Accent or T.TextDim
                    UpdateKBLbl()
                end
                UpdateKB()
                local function SetMode(m)
                    mode = m
                    Flags[flag.."_Mode"] = mode
                    if mode == "Always" then
                        active = true; cb(true)
                    else
                        active = false; cb(false)
                    end
                    UpdateKB()
                end
                KBBtn.MouseButton1Click:Connect(function() listen=true;UpdateKB() end)
                ModeBtn.MouseEnter:Connect(function() Tween(ModeBtn,{BackgroundColor3=T.Surface2},.1) end)
                ModeBtn.MouseLeave:Connect(function() Tween(ModeBtn,{BackgroundColor3=T.Surface3},.1) end)
                ModeBtn.MouseButton1Click:Connect(function()
                    local curIdx = 1
                    for i, m in ipairs(modeList) do if m == mode then curIdx = i; break end end
                    SetMode(modeList[(curIdx % #modeList) + 1])
                end)
                pcall(function()
                    KBBtn.MouseButton2Click:Connect(function()
                        local mpos=UIS:GetMouseLocation()
                        ShowCtx(mpos,{
                                {label="Toggle", color=mode=="Toggle" and T.Accent or T.Text, cb=function() SetMode("Toggle") end},
                            {label="Hold",   color=mode=="Hold"   and T.Accent or T.Text, cb=function() SetMode("Hold") end},
                            {label="Always", color=mode=="Always" and T.Accent or T.Text, cb=function() SetMode("Always") end},
                        })
                    end)
                end)
                local _onClickCallbacks = {}
                local _activeLoop = false
                local function StartActiveLoop()
                    if _activeLoop then return end
                    _activeLoop = true
                    task.spawn(function()
                        while _activeLoop and active do
                            for _, fn in ipairs(_onClickCallbacks) do task.spawn(fn) end
                            task.wait(0.05)
                        end
                        _activeLoop = false
                    end)
                end
                Win:AddConn(UIS.InputBegan:Connect(function(inp,gpe)
                    local isValidInput = inp.UserInputType == Enum.UserInputType.Keyboard or inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3
                    if listen and isValidInput then
                        if inp.KeyCode==Enum.KeyCode.Escape then listen=false;UpdateKB();return end
                        key = inp.KeyCode; inputType = inp.UserInputType
                        Flags[flag]=key; listen=false; UpdateKB()
                    elseif not gpe and not listen and isValidInput then
                        local isTrigger = (inputType == Enum.UserInputType.Keyboard and inp.KeyCode == key and key ~= Enum.KeyCode.Unknown) or (inputType ~= Enum.UserInputType.Keyboard and inp.UserInputType == inputType)
                        if isTrigger then
                            if mode=="Toggle" then
                                active=not active;cb(active);UpdateKBLbl()
                                if active then StartActiveLoop() end
                            elseif mode=="Hold" then
                                active=true;cb(true);UpdateKBLbl()
                                StartActiveLoop()
                            end
                        end
                    end
                end))
                Win:AddConn(UIS.InputEnded:Connect(function(inp)
                    local isValidInput = inp.UserInputType == Enum.UserInputType.Keyboard or inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3
                    if not listen and isValidInput then
                        local isTrigger = (inputType == Enum.UserInputType.Keyboard and inp.KeyCode == key and key ~= Enum.KeyCode.Unknown) or (inputType ~= Enum.UserInputType.Keyboard and inp.UserInputType == inputType)
                        if isTrigger and mode=="Hold" then
                            active=false;cb(false);UpdateKBLbl()
                            _activeLoop=false
                        end
                    end
                end))
                if mode == "Always" then
                    active = true; cb(true)
                    StartActiveLoop()
                end
                UpdateKBLbl()
                local Obj={Flag=flag}
                function Obj:Get() return key end; function Obj:GetActive() return active end; function Obj:GetMode() return mode end
                function Obj:OnClick(fn)
                    if type(fn) == "function" then
                        table.insert(_onClickCallbacks, fn)
                    end
                end
                return Obj
            end
            -- ── COLOR PICKER (hideable + Settings sub-tab) ─────────────────
            function Sec:ColorPicker(o)
                o=o or{}
                local name  = o.Name    or "Color"
                local def   = o.Default or T.Accent
                local flag  = o.Flag    or name
                local cb    = o.Callback or function() end
                local val   = def; Flags[flag]=val
                local open  = false
                local hv,sv,vv = val:ToHSV()
                local savedH,savedS,savedV = hv,sv,vv
                local colorType = "Color3.fromRGB"
                local CPWrap=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nxt(),ClipsDescendants=false,Parent=SF})
                local Row=New("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Parent=CPWrap})
                New("TextLabel",{Size=UDim2.new(1,-52,1,0),BackgroundTransparency=1,Text=name,TextColor3=T.Text,Font=T.Font,TextSize=T.FontMd,TextXAlignment=Enum.TextXAlignment.Left,Parent=Row})
                local HideBtn=New("TextButton",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(1,-52,.5,-7),BackgroundColor3=T.Surface3,BorderSizePixel=0,Text="▾",TextColor3=T.TextDim,Font=T.Font,TextSize=10,Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local Swatch=New("TextButton",{Size=UDim2.new(0,22,0,14),Position=UDim2.new(1,-22,.5,-7),BackgroundColor3=val,BorderSizePixel=0,Text="",Parent=Row},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local Panel=New("Frame",{Size=UDim2.new(1,0,0,258),BackgroundColor3=T.Surface2,BorderSizePixel=0,Visible=false,ZIndex=8,Parent=CPWrap},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local PTabBar=New("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=T.Surface1,BorderSizePixel=0,ZIndex=9,Parent=Panel},{New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local ColorPage=New("Frame",{Size=UDim2.new(1,0,1,-22),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,ZIndex=9,Visible=true,Parent=Panel})
                local SettingsPage=New("Frame",{Size=UDim2.new(1,0,1,-22),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,ZIndex=9,Visible=false,Parent=Panel})
                local pBtns={}
                for i,lbl in ipairs({"Color","Settings"}) do
                    local B=New("TextButton",{Size=UDim2.new(.5,0,1,0),BackgroundTransparency=1,Text=lbl,TextColor3=i==1 and T.Accent or T.TextDim,Font=T.Font,TextSize=11,ZIndex=9,LayoutOrder=i,Parent=PTabBar})
                    pBtns[i]=B
                    B.MouseButton1Click:Connect(function() ColorPage.Visible=i==1;SettingsPage.Visible=i==2; for j,b in ipairs(pBtns) do b.TextColor3=j==i and T.Accent or T.TextDim end end)
                end
                local SVW=New("Frame",{Size=UDim2.new(1,-36,0,140),Position=UDim2.new(0,4,0,4),BackgroundColor3=Color3.fromHSV(hv,1,1),BorderSizePixel=0,ClipsDescendants=true,ZIndex=9,Parent=ColorPage},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))}),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=SVW})
                local BlackOvl=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=10,Parent=SVW})
                New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=BlackOvl})
                local SVCursor=New("Frame",{Size=UDim2.new(0,8,0,8),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(sv,0,1-vv,0),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=12,Parent=SVW},{New("UICorner",{CornerRadius=UDim.new(1,0)}),New("UIStroke",{Color=Color3.fromRGB(0,0,0),Thickness=1})})
                local HueW=New("Frame",{Size=UDim2.new(0,14,0,140),Position=UDim2.new(1,-18,0,4),BorderSizePixel=0,ZIndex=9,Parent=ColorPage},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local hkps={}; for i=0,6 do table.insert(hkps,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
                New("UIGradient",{Color=ColorSequence.new(hkps),Rotation=90,Parent=HueW})
                local HueCursor=New("Frame",{Size=UDim2.new(1,4,0,4),Position=UDim2.new(0,-2,hv,0),AnchorPoint=Vector2.new(0,.5),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=12,Parent=HueW},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=Color3.fromRGB(0,0,0),Thickness=1})})
                local RGBLbl=New("TextLabel",{Size=UDim2.new(.6,0,0,14),Position=UDim2.new(0,4,0,150),BackgroundTransparency=1,TextColor3=T.TextDim,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9,Parent=ColorPage})
                local HexBox=New("TextBox",{Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,4,0,167),BackgroundColor3=T.Surface1,BorderSizePixel=0,TextColor3=T.TextDim,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=9,Parent=ColorPage},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                New("UIPadding",{PaddingLeft=UDim.new(0,3),Parent=HexBox})
                New("TextLabel",{Size=UDim2.new(1,-8,0,14),Position=UDim2.new(0,4,0,6),BackgroundTransparency=1,Text="Output type:",TextColor3=T.TextDim,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9,Parent=SettingsPage})
                local colorTypes={"Color3.fromRGB","Color3.fromHSV","Color3.fromHex","Color3.new"}
                local ctBtns={}
                for i,ct in ipairs(colorTypes) do
                    local B=New("TextButton",{Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,4,0,22+(i-1)*20),BackgroundTransparency=colorType==ct and 0 or 1,BackgroundColor3=T.Surface3,BorderSizePixel=0,Text=ct,TextColor3=colorType==ct and T.Accent or T.Text,Font=T.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9,Parent=SettingsPage},{New("UIPadding",{PaddingLeft=UDim.new(0,6)})})
                    ctBtns[i]=B
                    B.MouseButton1Click:Connect(function()
                        colorType=ct
                        for j,b in ipairs(ctBtns) do b.TextColor3=b.Text==colorType and T.Accent or T.Text;b.BackgroundTransparency=b.Text==colorType and 0 or 1 end
                    end)
                end
                local OutLbl=New("TextLabel",{Size=UDim2.new(1,-8,0,28),Position=UDim2.new(0,4,0,103),BackgroundTransparency=1,TextColor3=T.TextDim,Font=T.Font,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=9,Parent=SettingsPage})
                local function Refresh()
                    val=Color3.fromHSV(hv,sv,vv); Flags[flag]=val; Swatch.BackgroundColor3=val
                    SVW.BackgroundColor3=Color3.fromHSV(hv,1,1); SVCursor.Position=UDim2.new(sv,0,1-vv,0)
                    HueCursor.Position=UDim2.new(0,-2,hv,0); HueCursor.AnchorPoint=Vector2.new(0,.5)
                    local r,g,b=math.round(val.R*255),math.round(val.G*255),math.round(val.B*255)
                    RGBLbl.Text=("%d, %d, %d"):format(r,g,b)
                    local fmt
                    if colorType=="Color3.fromRGB" then fmt=("Color3.fromRGB(%d,%d,%d)"):format(r,g,b)
                    elseif colorType=="Color3.fromHSV" then fmt=("Color3.fromHSV(%.3f,%.3f,%.3f)"):format(hv,sv,vv)
                    elseif colorType=="Color3.fromHex" then fmt=("#%02X%02X%02X"):format(r,g,b)
                    elseif colorType=="Color3.new" then fmt=("Color3.new(%.3f,%.3f,%.3f)"):format(val.R,val.G,val.B) end
                    HexBox.Text=fmt or""; OutLbl.Text=fmt or""; cb(val)
                end
                Refresh()
                HexBox.FocusLost:Connect(function()
                    local hex=HexBox.Text:gsub("#","")
                    if #hex==6 then pcall(function() local r=tonumber(hex:sub(1,2),16)/255; local g=tonumber(hex:sub(3,4),16)/255; local b=tonumber(hex:sub(5,6),16)/255; hv,sv,vv=Color3.new(r,g,b):ToHSV();Refresh() end) end
                end)
                local svDrag,hueDrag=false,false
                SVW.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=true; local rel=Vector2.new(i.Position.X,i.Position.Y)-SVW.AbsolutePosition; sv=math.clamp(rel.X/SVW.AbsoluteSize.X,0,1); vv=1-math.clamp(rel.Y/SVW.AbsoluteSize.Y,0,1); Refresh() end end)
                HueW.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDrag=true; hv=math.clamp((i.Position.Y-HueW.AbsolutePosition.Y)/HueW.AbsoluteSize.Y,0,1); Refresh() end end)
                Win:AddConn(UIS.InputChanged:Connect(function(i)
                    if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
                    if svDrag then local rel=Vector2.new(i.Position.X,i.Position.Y)-SVW.AbsolutePosition; sv=math.clamp(rel.X/SVW.AbsoluteSize.X,0,1); vv=1-math.clamp(rel.Y/SVW.AbsoluteSize.Y,0,1); Refresh() end
                    if hueDrag then hv=math.clamp((i.Position.Y-HueW.AbsolutePosition.Y)/HueW.AbsoluteSize.Y,0,1); Refresh() end
                end))
                Win:AddConn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag,hueDrag=false,false end end))
                local CPBtnRow=New("Frame",{Size=UDim2.new(1,-8,0,22),Position=UDim2.new(0,4,0,192),BackgroundTransparency=1,ZIndex=9,Parent=ColorPage},{New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4)})})
                local ApplyBtn=New("TextButton",{Size=UDim2.new(.5,-2,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Text="Apply",TextColor3=T.Text,Font=T.Font,TextSize=11,ZIndex=9,Parent=CPBtnRow},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local CancelBtn=New("TextButton",{Size=UDim2.new(.5,-2,1,0),BackgroundColor3=T.Surface3,BorderSizePixel=0,Text="Cancel",TextColor3=T.Text,Font=T.Font,TextSize=11,ZIndex=9,Parent=CPBtnRow},{New("UICorner",{CornerRadius=UDim.new(0,2)}),New("UIStroke",{Color=T.Border,Thickness=1})})
                local function OpenPicker()
                    if not open then savedH,savedS,savedV=hv,sv,vv; open=true; Panel.Visible=true; HideBtn.Text="▴" end
                end
                local function ClosePicker()
                    open=false; Panel.Visible=false; HideBtn.Text="▾"
                end
                ApplyBtn.MouseButton1Click:Connect(ClosePicker)
                ApplyBtn.MouseEnter:Connect(function() Tween(ApplyBtn,{BackgroundColor3=Color3.fromHex("FF3580")},.1) end)
                ApplyBtn.MouseLeave:Connect(function() Tween(ApplyBtn,{BackgroundColor3=T.Accent},.1) end)
                CancelBtn.MouseButton1Click:Connect(function() hv,sv,vv=savedH,savedS,savedV; Refresh(); ClosePicker() end)
                CancelBtn.MouseEnter:Connect(function() Tween(CancelBtn,{BackgroundColor3=T.Surface2},.1) end)
                CancelBtn.MouseLeave:Connect(function() Tween(CancelBtn,{BackgroundColor3=T.Surface3},.1) end)
                Swatch.MouseButton1Click:Connect(function() if open then ClosePicker() else OpenPicker() end end)
                HideBtn.MouseButton1Click:Connect(function() if open then ClosePicker() else OpenPicker() end end)
                local Obj={Flag=flag}
                function Obj:Get() return val end; function Obj:Set(c) hv,sv,vv=c:ToHSV();Refresh() end; function Obj:GetColorType() return colorType end
                return Obj
            end
            -- ── LABEL / SEPARATOR ─────────────────────────────────────────
            function Sec:Label(o)
                local txt=type(o)=="string" and o or(o and o.Text or"")
                return New("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=txt,TextColor3=T.TextDim,Font=T.Font,TextSize=T.FontSm,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,RichText=true,LayoutOrder=nxt(),Parent=SF})
            end
            function Sec:Separator()
                New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Border,BorderSizePixel=0,LayoutOrder=nxt(),Parent=SF})
            end
            -- ── VIEWPORT PREVIEW (Interactive 3D Model + Image, with projected ESP) ──
            function Sec:ViewportPreview(o)
                o = o or {}
                local vpH = o.Height or 200
                local initImgUrl = o.Image or o.ImageURL
                local accent = o.BoxColor or T.Accent
                local enableInteractive = o.Interactive ~= false
                local enableModeSwitch = o.ModeSwitch == true
                local modeSwitchH = enableModeSwitch and 26 or 0
                local currentMode = (initImgUrl and not enableModeSwitch) and "Image" or "Model"
                -- Render outside main UI (anchored to right side of Main frame)
                local Wrapper = New("Frame", {
                        Size = UDim2.new(0, 260, 0, vpH + modeSwitchH + 16),
                    Position = UDim2.new(1, 10, 0, 0),
                    BackgroundColor3 = T.Bg,
                    BorderSizePixel = 0,
                    Parent = Main
                }, {
                        New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    New("UIStroke", { Color = T.Border, Thickness = 1 }),
                    New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
                })
                local ModelBtn, ImageBtn
                if enableModeSwitch then
                    local ModeBar = New("Frame", { Size = UDim2.new(1,0,0,24), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, Parent = Wrapper }, { New("UICorner",{CornerRadius=UDim.new(0,3)}), New("UIStroke",{Color=T.Border,Thickness=1}), New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal}) })
                    ModelBtn = New("TextButton", { Size=UDim2.new(.5,0,1,0), BackgroundColor3=T.Accent, BackgroundTransparency=0, BorderSizePixel=0, Text="Model Rig", TextColor3=T.Text, Font=T.Font, TextSize=11, LayoutOrder=1, Parent=ModeBar })
                    ImageBtn = New("TextButton", { Size=UDim2.new(.5,0,1,0), BackgroundColor3=Color3.fromHex("161616"), BackgroundTransparency=.3, BorderSizePixel=0, Text="Image Preview", TextColor3=T.TextDim, Font=T.Font, TextSize=11, LayoutOrder=2, Parent=ModeBar })
                end
                -- ── ViewportFrame (Model Mode) ──
                local VP = New("ViewportFrame", { Size = UDim2.new(1,0,1,-modeSwitchH), Position = UDim2.new(0,0,0,modeSwitchH), BackgroundColor3 = Color3.fromHex("0E0E0E"), BorderSizePixel = 0, Visible = (currentMode == "Model"), Parent = Wrapper }, { New("UICorner",{CornerRadius=UDim.new(0,3)}), New("UIStroke",{Color=T.Border,Thickness=1}) })
                VP.Ambient = Color3.new(1,1,1); VP.LightColor = Color3.new(1,1,1)
                local Cam = Instance.new("Camera"); Cam.Parent = VP; VP.CurrentCamera = Cam
                local WM = Instance.new("WorldModel"); WM.Parent = VP
                local currentClone = nil
                -- ── ImageLabel (Image Mode) ──
                local ImgFrame = New("ImageLabel", { Size = UDim2.new(1,0,0,vpH), Position = UDim2.new(0,0,0,modeSwitchH), BackgroundColor3 = Color3.fromHex("0E0E0E"), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, ImageColor3 = Color3.new(1,1,1), Visible = (currentMode == "Image"), Parent = Wrapper }, { New("UICorner",{CornerRadius=UDim.new(0,3)}), New("UIStroke",{Color=T.Border,Thickness=1}) })
                -- External image loader (supports http URLs via executor getcustomasset)
                local function LoadImageUrl(url)
                    if not url or url == "" then return end
                    task.spawn(function()
                        if url:match("^rbxasset") or url:match("^rbxthumb") then ImgFrame.Image = url; return end
                        local ok2, assetUrl = pcall(function()
                            local data = game:HttpGet(url)
                            SafeMkdir("PeronaLib_cache")
                            local fn = "PeronaLib_cache/prev_" .. tostring(math.random(100000,999999)) .. ".png"
                            writefile(fn, data)
                            if getcustomasset then return getcustomasset(fn) elseif getsynasset then return getsynasset(fn) end
                            return nil
                        end)
                        if ok2 and assetUrl then ImgFrame.Image = assetUrl else ImgFrame.Image = url end
                    end)
                end
                if initImgUrl then LoadImageUrl(initImgUrl) end
                -- ── Mode switching ──
                local function SetMode(mode)
                    currentMode = mode
                    VP.Visible = (mode == "Model"); ImgFrame.Visible = (mode == "Image")
                    if ModelBtn then ModelBtn.BackgroundColor3 = mode == "Model" and T.Accent or Color3.fromHex("161616"); ModelBtn.BackgroundTransparency = mode == "Model" and 0 or .3; ModelBtn.TextColor3 = mode == "Model" and T.Text or T.TextDim end
                    if ImageBtn then ImageBtn.BackgroundColor3 = mode == "Image" and T.Accent or Color3.fromHex("161616"); ImageBtn.BackgroundTransparency = mode == "Image" and 0 or .3; ImageBtn.TextColor3 = mode == "Image" and T.Text or T.TextDim end
                end
                if ModelBtn then ModelBtn.MouseButton1Click:Connect(function() SetMode("Model") end) end
                if ImageBtn then ImageBtn.MouseButton1Click:Connect(function() SetMode("Image") end) end
                -- ── Character Loading ──
                local function ClearModels()
                    for _, c in ipairs(WM:GetChildren()) do pcall(function() c:Destroy() end) end
                    currentClone = nil
                end
                local function LoadCharacter()
                    ClearModels()
                    local char = LP and LP.Character; if not char then return false end
                    local toRestore = {}
                    for _, v in ipairs(char:GetDescendants()) do if not v.Archivable then table.insert(toRestore, v); v.Archivable = true end end
                    local oldArch = char.Archivable; char.Archivable = true
                    local ok3, clone = pcall(function() return char:Clone() end)
                    char.Archivable = oldArch
                    for _, v in ipairs(toRestore) do v.Archivable = false end
                    if not ok3 or not clone then return false end
                    pcall(function() for _, v in pairs(clone:GetDescendants()) do if v:IsA("BaseScript") or v:IsA("Animator") or v:IsA("Sound") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Light") then pcall(function() v:Destroy() end) end end end)
                    pcall(function() for _, v in pairs(clone:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true end end end)
                    clone.Parent = WM; currentClone = clone; return true
                end
                task.spawn(function() for a = 1, 10 do if LoadCharacter() then break end; task.wait(0.5) end end)
                if LP then Win:AddConn(LP.CharacterAdded:Connect(function(ch) task.spawn(function() local h = ch:WaitForChild("Humanoid",5); if h then pcall(function() h:GetAppliedDescription() end) end; task.wait(1); LoadCharacter() end) end)) end
                -- ══ 3D Projection helper (Camera -> ViewportFrame 2D coords) ══
                local function ProjectToVP(worldPos)
                    local vpSz = VP.AbsoluteSize; if vpSz.X <= 0 or vpSz.Y <= 0 then return nil end
                    local lp = Cam.CFrame:PointToObjectSpace(worldPos)
                    if lp.Z >= 0 then return nil end
                    local hf = math.tan(math.rad(Cam.FieldOfView / 2))
                    local asp = vpSz.X / vpSz.Y
                    local nx = lp.X / (-lp.Z * hf * asp)
                    local ny = lp.Y / (-lp.Z * hf)
                    return Vector2.new((nx + 1) / 2 * vpSz.X, (1 - ny) / 2 * vpSz.Y)
                end
                -- ══ Model ESP Overlay (3D-projected, follows the rig) ══
                local ModelESP = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 5, ClipsDescendants = true, Parent = VP })
                -- Fill frame (solid color or image behind box)
                local mFillFrame = New("ImageLabel", { Size = UDim2.new(0,0,0,0), BackgroundColor3 = accent, BackgroundTransparency = 0.65, ImageTransparency = 0.35, Image = "", ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = ModelESP })
                local mFillVis = false
                local mFillImage = ""
                -- Corner box: 8 line frames
                local mCorners = {}; for i = 1, 8 do mCorners[i] = New("Frame", { Size = UDim2.new(0,8,0,1), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = ModelESP }) end
                -- 4 extra frames for full 2D box edges (top/bot/left/right)
                local m2DBox = {}; for i = 1, 4 do m2DBox[i] = New("Frame", { Size = UDim2.new(0,1,0,1), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = ModelESP }) end
                local mBoxVis = true
                local mBoxType = o.BoxType or "CornerBox"
                -- 3D box + skeleton: use Drawing.new when available
                local _hasDrawAPI = pcall(function() return Drawing and Drawing.new end)
                -- 3D box Drawing.new lines (12 edges)
                local m3DBoxDraw = {}
                local _3dDrawMode = false
                if _hasDrawAPI then
                    for i = 1, 12 do
                        local ok5, dl = pcall(function() local l = Drawing.new("Line"); l.Color = accent; l.Thickness = 1; l.Visible = false; return l end)
                        if ok5 and dl then m3DBoxDraw[i] = dl; table.insert(Win._drawingObjects, dl) else break end
                    end
                    if #m3DBoxDraw == 12 then _3dDrawMode = true end
                end
                if not _3dDrawMode then
                    m3DBoxDraw = {}; for i = 1, 12 do m3DBoxDraw[i] = New("Frame", { Size = UDim2.new(0,1,0,1), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = ModelESP }) end
                end
                -- Name
                local mNameLbl = New("TextLabel", { Size = UDim2.new(0,0,0,14), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = LP and LP.DisplayName or "Player", TextColor3 = Color3.new(1,1,1), Font = T.Font, TextSize = 11, TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.new(0,0,0), ZIndex = 7, Visible = false, Parent = ModelESP })
                local mNameVis = true
                -- Health bar
                local mHBbg = New("Frame", { Size = UDim2.new(0,3,0,50), BackgroundColor3 = Color3.fromHex("1A1A1A"), BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = ModelESP }, { New("UICorner",{CornerRadius=UDim.new(0,2)}) })
                local mHBfill = New("Frame", { Size = UDim2.new(1,0,1,0), AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0), BackgroundColor3 = T.Green, BorderSizePixel = 0, ZIndex = 7, Parent = mHBbg }, { New("UICorner",{CornerRadius=UDim.new(0,2)}) })
                local mHealthVis = true
                -- Tracer
                local mTracerLine = New("Frame", { Size = UDim2.new(0,1,0,0), BackgroundColor3 = accent, AnchorPoint = Vector2.new(0.5,0), BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = ModelESP })
                local mTracerVis = false
                -- Skeleton bone lines — Drawing.new for quality, fallback to Frame
                local mBoneLines = {}
                local _skelDrawingMode = false
                if _hasDrawAPI then
                    for i = 1, 14 do
                        local ok4, sl = pcall(function() local l = Drawing.new("Line"); l.Color = accent; l.Thickness = 1; l.Visible = false; return l end)
                        if ok4 and sl then mBoneLines[i] = sl; table.insert(Win._drawingObjects, sl) else break end
                    end
                    if #mBoneLines == 14 then _skelDrawingMode = true end
                end
                if not _skelDrawingMode then
                    mBoneLines = {}
                    for i = 1, 14 do mBoneLines[i] = New("Frame", { Size = UDim2.new(0,0,0,1), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 7, Visible = false, Parent = ModelESP }) end
                end
                local mSkeletonVis = false
                local skeletonColor = accent
                local R15B = { {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"} }
                local R6B = { {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"} }
                -- ══ Image ESP Overlay (fixed positions, for Image mode) ══
                local ImgESP = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 5, Parent = ImgFrame })
                local ibL, ibT, ibW, ibH = .28, .08, .44, .82
                local iBoxGroup = New("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 6, Parent = ImgESP })
                local function IMC(pos, sH, sV, xO, yO) New("Frame",{Size=sH,Position=UDim2.new(pos.X.Scale,pos.X.Offset+xO,pos.Y.Scale,pos.Y.Offset+yO),BackgroundColor3=accent,BorderSizePixel=0,ZIndex=6,Parent=iBoxGroup}); New("Frame",{Size=sV,Position=UDim2.new(pos.X.Scale,pos.X.Offset+xO,pos.Y.Scale,pos.Y.Offset+yO),BackgroundColor3=accent,BorderSizePixel=0,ZIndex=6,Parent=iBoxGroup}) end
                IMC(UDim2.new(ibL,0,ibT,0),UDim2.new(0,8,0,1),UDim2.new(0,1,0,8),0,0)
                IMC(UDim2.new(ibL+ibW,0,ibT,0),UDim2.new(0,-8,0,1),UDim2.new(0,-1,0,8),0,0)
                IMC(UDim2.new(ibL,0,ibT+ibH,0),UDim2.new(0,8,0,1),UDim2.new(0,1,0,-8),0,-1)
                IMC(UDim2.new(ibL+ibW,0,ibT+ibH,0),UDim2.new(0,-8,0,1),UDim2.new(0,-1,0,-8),0,-1)
                local iNameGroup = New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=7,Parent=ImgESP})
                local iNameLbl = New("TextLabel",{Size=UDim2.new(ibW,0,0,14),Position=UDim2.new(ibL,0,ibT,-16),BackgroundTransparency=1,Text=LP and LP.DisplayName or"Player",TextColor3=Color3.new(1,1,1),Font=T.Font,TextSize=11,TextStrokeTransparency=0.5,TextStrokeColor3=Color3.new(0,0,0),ZIndex=7,Parent=iNameGroup})
                local iHealthGroup = New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=6,Parent=ImgESP})
                local iHBbg = New("Frame",{Size=UDim2.new(0,3,ibH,0),Position=UDim2.new(ibL,-8,ibT,0),BackgroundColor3=Color3.fromHex("1A1A1A"),BorderSizePixel=0,ZIndex=6,Parent=iHealthGroup},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local iHBfill = New("Frame",{Size=UDim2.new(1,0,1,0),AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),BackgroundColor3=T.Green,BorderSizePixel=0,ZIndex=7,Parent=iHBbg},{New("UICorner",{CornerRadius=UDim.new(0,2)})})
                local iTracerGroup = New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=5,Visible=false,Parent=ImgESP})
                local iTracerLine = New("Frame",{Size=UDim2.new(0,1,0,0),BackgroundColor3=accent,AnchorPoint=Vector2.new(0.5,0),BorderSizePixel=0,ZIndex=5,Parent=iTracerGroup})
                do local sx,sy=0.5,1.0; local ex,ey=ibL+ibW/2,ibT+ibH; local ddx=ex-sx; local ddy=ey-sy; local dd=math.sqrt(ddx*ddx+ddy*ddy); local da=math.deg(math.atan2(ddx,-ddy)); iTracerLine.Position=UDim2.new(sx,0,sy,0); iTracerLine.Size=UDim2.new(0,1,dd,0); iTracerLine.Rotation=-da end
                local iSkeletonGroup = New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=7,Visible=false,Parent=ImgESP})
                local iBonePos = { {{ibL+ibW/2,ibT+0.05},{ibL+ibW/2,ibT+0.65}}, {{ibL+ibW/2,ibT+0.25},{ibL+ibW*-0.1,ibT+0.60}}, {{ibL+ibW/2,ibT+0.25},{ibL+ibW*1.1,ibT+0.60}}, {{ibL+ibW/2,ibT+0.65},{ibL+ibW*0.2,ibT+ibH*0.95}}, {{ibL+ibW/2,ibT+0.65},{ibL+ibW*0.8,ibT+ibH*0.95}} }
                for _,bp in ipairs(iBonePos) do local x1,y1=bp[1][1],bp[1][2]; local x2,y2=bp[2][1],bp[2][2]; local px1,py1=x1*220,y1*vpH; local px2,py2=x2*220,y2*vpH; local ddx,ddy=px2-px1,py2-py1; local dd=math.sqrt(ddx*ddx+ddy*ddy); local cx,cy=(x1+x2)/2,(y1+y2)/2; local da=math.deg(math.atan2(ddy,ddx)); New("Frame",{Size=UDim2.new(0,dd,0,1),Position=UDim2.new(cx,0,cy,0),AnchorPoint=Vector2.new(0.5,0.5),Rotation=da,BackgroundColor3=accent,BorderSizePixel=0,ZIndex=7,Parent=iSkeletonGroup}) end
                -- ══ Interactive Orbit Camera ══
                local autoAngle = 0
                local orbitAngle, orbitPitch, orbitDist = 0, 0.15, 6
                local isDragging, userControlled = false, false
                local lastMouse = Vector2.zero
                if enableInteractive then
                    local DI = New("TextButton", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=20, Parent=VP })
                    DI.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                            isDragging = true; userControlled = true; lastMouse = Vector2.new(inp.Position.X, inp.Position.Y)
                        end
                    end)
                    Win:AddConn(UIS.InputChanged:Connect(function(inp)
                        if isDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                            local cur = Vector2.new(inp.Position.X, inp.Position.Y); local d = cur - lastMouse; lastMouse = cur
                            orbitAngle = orbitAngle + d.X * 0.008; orbitPitch = math.clamp(orbitPitch + d.Y * 0.008, -1.2, 1.2)
                        end
                    end))
                    Win:AddConn(UIS.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then isDragging = false end
                    end))
                    Win:AddConn(UIS.InputChanged:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseWheel then
                            local mp = UIS:GetMouseLocation()
                            local ap = VP.AbsolutePosition
                            local az = VP.AbsoluteSize
                            if mp.X >= ap.X and mp.X <= ap.X+az.X and mp.Y >= ap.Y and mp.Y <= ap.Y+az.Y then
                                userControlled = true 
                                orbitDist = math.clamp(orbitDist - inp.Position.Z * 0.8, 2, 14)
                            end
                        end
                    end))
                end
                -- ══ Runtime: Camera orbit + 3D-projected ESP on model ══
                local _vpTick = 0
                local function IsVPVisible()
                    if not VP.Visible or VP.AbsoluteSize.X <= 0 then return false end
                    local p = VP.Parent; while p and p:IsA("GuiObject") do if not p.Visible then return false end; p = p.Parent end; return true
                end
                -- Hide all Drawing.new objects (called when VP not visible)
                local function HideDrawingObjects()
                    if _skelDrawingMode then for i=1,#mBoneLines do mBoneLines[i].Visible = false end end
                    if _3dDrawMode then for i=1,#m3DBoxDraw do m3DBoxDraw[i].Visible = false end end
                end
                Win:Runtime(function(dt)
                    if not IsVPVisible() then HideDrawingObjects(); return end
                    if not currentClone or not currentClone.Parent then HideDrawingObjects(); return end
                    local hrp = currentClone:FindFirstChild("HumanoidRootPart") or currentClone:FindFirstChild("Torso") or currentClone:FindFirstChild("UpperTorso")
                    if not hrp then HideDrawingObjects(); return end
                    if tick() - _vpTick < 0.033 then return end; _vpTick = tick()
                    -- Camera: auto-rotate or user orbit
                    local ang, pitch, dist
                    if userControlled then ang = orbitAngle; pitch = orbitPitch; dist = orbitDist
                    else autoAngle = (autoAngle + dt * 12) % (math.pi * 2); ang = autoAngle; pitch = 0.15; dist = 6 end
                    local lookAt = hrp.Position + Vector3.new(0, 0.5, 0)
                    Cam.CFrame = CFrame.new(lookAt + Vector3.new(math.sin(ang)*math.cos(pitch)*dist, math.sin(pitch)*dist, math.cos(ang)*math.cos(pitch)*dist), lookAt)
                    -- ── Project model parts to 2D for ESP ──
                    local vpSz = VP.AbsoluteSize; if vpSz.X <= 0 then return end
                    local headP = currentClone:FindFirstChild("Head")
                    local topW = headP and (headP.Position + Vector3.new(0, 0.8, 0)) or (hrp.Position + Vector3.new(0, 2.5, 0))
                    local lF = currentClone:FindFirstChild("LeftFoot") or currentClone:FindFirstChild("Left Leg")
                    local rF = currentClone:FindFirstChild("RightFoot") or currentClone:FindFirstChild("Right Leg")
                    local botY2; if lF and rF then botY2 = math.min(lF.Position.Y, rF.Position.Y) - 0.3 elseif lF then botY2 = lF.Position.Y - 0.3 elseif rF then botY2 = rF.Position.Y - 0.3 else botY2 = hrp.Position.Y - 3 end
                    local botW = Vector3.new(hrp.Position.X, botY2, hrp.Position.Z)
                    local top2 = ProjectToVP(topW); local bot2 = ProjectToVP(botW); local hrp2 = ProjectToVP(hrp.Position)
                    if not top2 or not bot2 or not hrp2 then
                        for i=1,8 do mCorners[i].Visible=false end; for i=1,4 do m2DBox[i].Visible=false end
                        for i=1,12 do m3DBoxDraw[i].Visible=false end
                        mNameLbl.Visible=false; mHBbg.Visible=false; mTracerLine.Visible=false; mFillFrame.Visible=false
                        for i=1,#mBoneLines do mBoneLines[i].Visible=false end; return
                    end
                    local h = math.abs(bot2.Y - top2.Y); local w = h * 0.5; local cx = hrp2.X; local bx = cx - w/2; local by = top2.Y
                    local cw = w / 4; local ch = cw
                    -- ── Box drawing (supports CornerBox, 2DBox/Box, 3DBox) ──
                    local bt = mBoxType
                    -- Hide all box types first
                    for i=1,8 do mCorners[i].Visible=false end
                    for i=1,4 do m2DBox[i].Visible=false end
                    for i=1,12 do m3DBoxDraw[i].Visible=false end
                    if mBoxVis and h > 5 then
                        if bt == "CornerBox" then
                            mCorners[1].Position=UDim2.new(0,bx,0,by); mCorners[1].Size=UDim2.new(0,cw,0,1); mCorners[1].Visible=true
                            mCorners[2].Position=UDim2.new(0,bx,0,by); mCorners[2].Size=UDim2.new(0,1,0,ch); mCorners[2].Visible=true
                            mCorners[3].Position=UDim2.new(0,bx+w-cw,0,by); mCorners[3].Size=UDim2.new(0,cw,0,1); mCorners[3].Visible=true
                            mCorners[4].Position=UDim2.new(0,bx+w-1,0,by); mCorners[4].Size=UDim2.new(0,1,0,ch); mCorners[4].Visible=true
                            mCorners[5].Position=UDim2.new(0,bx,0,by+h-1); mCorners[5].Size=UDim2.new(0,cw,0,1); mCorners[5].Visible=true
                            mCorners[6].Position=UDim2.new(0,bx,0,by+h-ch); mCorners[6].Size=UDim2.new(0,1,0,ch); mCorners[6].Visible=true
                            mCorners[7].Position=UDim2.new(0,bx+w-cw,0,by+h-1); mCorners[7].Size=UDim2.new(0,cw,0,1); mCorners[7].Visible=true
                            mCorners[8].Position=UDim2.new(0,bx+w-1,0,by+h-ch); mCorners[8].Size=UDim2.new(0,1,0,ch); mCorners[8].Visible=true
                        elseif bt == "Box" or bt == "2DBox" then
                            m2DBox[1].Position=UDim2.new(0,bx,0,by); m2DBox[1].Size=UDim2.new(0,w,0,1); m2DBox[1].Visible=true
                            m2DBox[2].Position=UDim2.new(0,bx,0,by+h); m2DBox[2].Size=UDim2.new(0,w,0,1); m2DBox[2].Visible=true
                            m2DBox[3].Position=UDim2.new(0,bx,0,by); m2DBox[3].Size=UDim2.new(0,1,0,h); m2DBox[3].Visible=true
                            m2DBox[4].Position=UDim2.new(0,bx+w,0,by); m2DBox[4].Size=UDim2.new(0,1,0,h); m2DBox[4].Visible=true
                        elseif bt == "3DBox" then
                            pcall(function()
                                local cf3, sz3 = currentClone:GetBoundingBox()
                                local hx3,hy3,hz3 = sz3.X/2, sz3.Y/2, sz3.Z/2
                                local c3d = { cf3*Vector3.new(-hx3,hy3,-hz3), cf3*Vector3.new(hx3,hy3,-hz3), cf3*Vector3.new(hx3,hy3,hz3), cf3*Vector3.new(-hx3,hy3,hz3), cf3*Vector3.new(-hx3,-hy3,-hz3), cf3*Vector3.new(hx3,-hy3,-hz3), cf3*Vector3.new(hx3,-hy3,hz3), cf3*Vector3.new(-hx3,-hy3,hz3) }
                                local edges3 = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                                local c2dArr = {}; local anyOn3 = false
                                for ci, corner in ipairs(c3d) do c2dArr[ci] = ProjectToVP(corner); if c2dArr[ci] then anyOn3 = true end end
                                if anyOn3 then
                                    local vpAP = VP.AbsolutePosition
                                    for ei, edge in ipairs(edges3) do
                                        local pp1, pp2 = c2dArr[edge[1]], c2dArr[edge[2]]
                                        if pp1 and pp2 then
                                            if _3dDrawMode then
                                                m3DBoxDraw[ei].From = Vector2.new(vpAP.X + pp1.X, vpAP.Y + pp1.Y + GuiInsetY)
                                                m3DBoxDraw[ei].To = Vector2.new(vpAP.X + pp2.X, vpAP.Y + pp2.Y + GuiInsetY)
                                                m3DBoxDraw[ei].Color = accent; m3DBoxDraw[ei].Visible = true
                                            else
                                                local edx,edy = pp2.X-pp1.X, pp2.Y-pp1.Y; local edd = math.sqrt(edx*edx+edy*edy)
                                                local eda = math.deg(math.atan2(edy, edx))
                                                m3DBoxDraw[ei].Position=UDim2.new(0,pp1.X,0,pp1.Y); m3DBoxDraw[ei].Size=UDim2.new(0,edd,0,1)
                                                m3DBoxDraw[ei].Rotation=eda; m3DBoxDraw[ei].Visible=true
                                            end
                                        else m3DBoxDraw[ei].Visible=false end
                                    end
                                end
                            end)
                        end
                    end
                    -- Fill (semi-transparent overlay behind box)
                    if mFillVis and h > 5 then
                        mFillFrame.Position = UDim2.new(0, bx, 0, by)
                        mFillFrame.Size = UDim2.new(0, w, 0, h)
                        mFillFrame.Visible = true
                    else mFillFrame.Visible = false end
                    -- Name
                    if mNameVis and h > 5 then
                        mNameLbl.Position = UDim2.new(0, cx - mNameLbl.AbsoluteSize.X/2, 0, by - 16)
                        mNameLbl.Visible = true
                    else mNameLbl.Visible = false end
                    -- Health bar
                    if mHealthVis and h > 5 then
                        mHBbg.Position = UDim2.new(0, bx - 6, 0, by); mHBbg.Size = UDim2.new(0, 3, 0, h); mHBbg.Visible = true
                    else mHBbg.Visible = false end
                    -- Tracer
                    if mTracerVis and h > 5 then
                        local sx, sy = vpSz.X / 2, vpSz.Y
                        local ex, ey = cx, by + h
                        local ddx, ddy = ex - sx, ey - sy; local dd = math.sqrt(ddx*ddx + ddy*ddy)
                        local da = math.deg(math.atan2(ddy, ddx))
                        mTracerLine.Position = UDim2.new(0, sx, 0, sy); mTracerLine.Size = UDim2.new(0, 1, 0, dd); mTracerLine.Rotation = da - 90; mTracerLine.Visible = true
                    else mTracerLine.Visible = false end
                    -- Skeleton (Drawing.new in screen-space with GuiInset, or Frame fallback)
                    if mSkeletonVis and h > 5 then
                        local bones = currentClone:FindFirstChild("UpperTorso") and R15B or R6B
                        local vpAbsPos = VP.AbsolutePosition
                        for bi, bone in ipairs(bones) do
                            if mBoneLines[bi] then
                                local p1p = currentClone:FindFirstChild(bone[1]); local p2p = currentClone:FindFirstChild(bone[2])
                                if p1p and p2p then
                                    local s1 = ProjectToVP(p1p.Position); local s2 = ProjectToVP(p2p.Position)
                                    if s1 and s2 then
                                        if _skelDrawingMode then
                                            mBoneLines[bi].From = Vector2.new(vpAbsPos.X + s1.X, vpAbsPos.Y + s1.Y + GuiInsetY)
                                            mBoneLines[bi].To = Vector2.new(vpAbsPos.X + s2.X, vpAbsPos.Y + s2.Y + GuiInsetY)
                                            mBoneLines[bi].Color = skeletonColor; mBoneLines[bi].Visible = true
                                        else
                                            local ddx2,ddy2 = s2.X-s1.X, s2.Y-s1.Y; local dd2 = math.sqrt(ddx2*ddx2+ddy2*ddy2)
                                            local da2 = math.deg(math.atan2(ddy2, ddx2))
                                            mBoneLines[bi].Position = UDim2.new(0, s1.X, 0, s1.Y); mBoneLines[bi].Size = UDim2.new(0, dd2, 0, 1)
                                            mBoneLines[bi].Rotation = da2; mBoneLines[bi].BackgroundColor3 = skeletonColor; mBoneLines[bi].Visible = true
                                        end
                                    else mBoneLines[bi].Visible = false end
                                else mBoneLines[bi].Visible = false end
                            end
                        end
                        for bi = #bones+1, #mBoneLines do mBoneLines[bi].Visible = false end
                    else for i=1,#mBoneLines do mBoneLines[i].Visible=false end end
                end)
                -- ══ Return object with all control methods ══
                local VPObj = { Frame = VP, ImageFrame = ImgFrame, Wrapper = Wrapper, HBFill = mHBfill, ESPOverlay = ModelESP }
                function VPObj:LoadCharacter() LoadCharacter() end
                function VPObj:ResetView() userControlled=false; orbitAngle=0; orbitPitch=0.15 end
                function VPObj:SetHealth(pct)
                    mHBfill.Size = UDim2.new(1,0,math.clamp(pct,0,1),0); iHBfill.Size = UDim2.new(1,0,math.clamp(pct,0,1),0)
                    local g = math.clamp(pct*2,0,1); local r = math.clamp(2-pct*2,0,1)
                    mHBfill.BackgroundColor3 = Color3.new(r,g,0); iHBfill.BackgroundColor3 = Color3.new(r,g,0)
                end
                function VPObj:SetBoxColor(c)
                    accent = c
                    for i=1,8 do mCorners[i].BackgroundColor3 = c end
                    for i=1,4 do m2DBox[i].BackgroundColor3 = c end
                    if not _3dDrawMode then for i=1,12 do if m3DBoxDraw[i].BackgroundColor3 then m3DBoxDraw[i].BackgroundColor3 = c end end end
                    mFillFrame.BackgroundColor3 = c
                    mTracerLine.BackgroundColor3 = c
                    for _,fr in pairs(iBoxGroup:GetChildren()) do if fr:IsA("Frame") then fr.BackgroundColor3 = c end end
                    iTracerLine.BackgroundColor3 = c
                end
                function VPObj:SetBoxType(bt) mBoxType = bt end
                function VPObj:SetESPVisible(v) ModelESP.Visible = v; ImgESP.Visible = v end
                function VPObj:SetBoxVisible(v) mBoxVis = v; iBoxGroup.Visible = v end
                function VPObj:SetFillVisible(v) mFillVis = v end
                function VPObj:SetFillImage(url)
                    if not url or url == "" then
                        if mFillImage ~= "" then mFillImage = ""; mFillFrame.Image = ""; mFillFrame.BackgroundTransparency = 0.65 end
                        return
                    end
                    if url == mFillImage then return end -- Skip if URL unchanged
                    mFillImage = url
                    task.spawn(function()
                        if url:match("^rbxasset") or url:match("^rbxthumb") then mFillFrame.Image = url; mFillFrame.BackgroundTransparency = 1; return end
                        local okF, aUrl = pcall(function()
                            local data = game:HttpGet(url)
                            SafeMkdir("PeronaLib_cache")
                            local fn = "PeronaLib_cache/fill_" .. tostring(math.random(100000,999999)) .. ".png"
                            writefile(fn, data)
                            if getcustomasset then return getcustomasset(fn) elseif getsynasset then return getsynasset(fn) end
                            return nil
                        end)
                        if okF and aUrl then mFillFrame.Image = aUrl; mFillFrame.BackgroundTransparency = 1 else mFillFrame.Image = url end
                    end)
                end
                function VPObj:SetNameVisible(v) mNameVis = v; iNameGroup.Visible = v end
                function VPObj:SetHealthVisible(v) mHealthVis = v; iHealthGroup.Visible = v end
                function VPObj:SetTracerVisible(v) mTracerVis = v; iTracerGroup.Visible = v end
                function VPObj:SetSkeletonVisible(v) mSkeletonVis = v; iSkeletonGroup.Visible = v end
                function VPObj:SetSkeletonColor(c)
                    skeletonColor = c
                    for _,fr in pairs(iSkeletonGroup:GetChildren()) do if fr:IsA("Frame") then fr.BackgroundColor3 = c end end
                end
                function VPObj:SetNameText(t) mNameLbl.Text = t; iNameLbl.Text = t end
                function VPObj:SetMode(m) SetMode(m) end
                function VPObj:SetImageURL(url) LoadImageUrl(url) end
                function VPObj:ResetCamera() userControlled = false; orbitAngle = 0; orbitPitch = 0.15; orbitDist = 6 end
                function VPObj:Reload() userControlled = false; orbitAngle = 0; orbitPitch = 0.15; orbitDist = 6; LoadCharacter() end
                return VPObj
            end
            -- ── TABBED LIST ───────────────────────────────────────────────
            function Sec:TabbedList(o)
                o=o or{}; local tabs=o.Tabs or{"1","2","3"}; local h=o.Height or 160
                local Wrap=New("Frame",{Size=UDim2.new(1,0,0,h+26),BackgroundTransparency=1,LayoutOrder=nxt(),Parent=SF})
                local TBar=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=T.Surface2,BorderSizePixel=0,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1}),New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal})})
                local Pages={};local Btns={}
                for i,tName in ipairs(tabs) do
                    local PF=New("ScrollingFrame",{Size=UDim2.new(1,0,0,h),Position=UDim2.new(0,0,0,26),BackgroundColor3=T.Surface2,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=i==1,Parent=Wrap},{New("UICorner",{CornerRadius=UDim.new(0,3)}),New("UIStroke",{Color=T.Border,Thickness=1}),New("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)}),New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})})
                    Pages[i]=PF
                    local BW=New("TextButton",{Size=UDim2.new(1/#tabs,0,1,0),BackgroundColor3=i==1 and T.Accent or Color3.fromHex("161616"),BackgroundTransparency=i==1 and 0 or .3,BorderSizePixel=0,Text=tName,TextColor3=i==1 and T.Text or T.TextDim,Font=T.Font,TextSize=11,LayoutOrder=i,Parent=TBar})
                    Btns[i]=BW; BW.MouseButton1Click:Connect(function() for j,p in ipairs(Pages) do p.Visible=j==i;Btns[j].BackgroundTransparency=j==i and 0 or .3;Btns[j].BackgroundColor3=j==i and T.Accent or Color3.fromHex("161616");Btns[j].TextColor3=j==i and T.Text or T.TextDim end end)
                end
                local TLObj={}
                function TLObj:AddItem(pi,text,color) return New("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=text,TextColor3=color or T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=Pages[pi] or Pages[1]},{New("UIPadding",{PaddingLeft=UDim.new(0,4)})}) end
                function TLObj:GetPage(idx) return Pages[idx] end
                return TLObj
            end
            return Sec
        end  -- BuildSection
        function Tab:Section(o)  return BuildSection(LeftPanel,  "_leftOrder",  o) end
        function Tab:RSection(o) return BuildSection(RightPanel, "_rightOrder", o) end
        return Tab
    end  -- Win:Tab
    -- ── Helpers ──────────────────────────────────────────────────────────────
    function Win:Toggle()  Main.Visible = not Main.Visible end
    function Win:Show()    Main.Visible = true  end
    function Win:Hide()    Main.Visible = false end
    function Win:Destroy() Main:Destroy(); HUD:Destroy(); KBOverlay:Destroy() end
    --- Unload: destroys UI, disconnects all runtime + ESP, cleans up
    function Win:Unload()
        Win._unloaded = true
        -- Disconnect batched ESP render loop
        pcall(function() _espBatchConn:Disconnect() end)
        -- Disconnect all runtime connections
        for _, c in ipairs(Win._runtimeConns) do pcall(function() c:Disconnect() end) end
        Win._runtimeConns = {}
        -- Destroy all ESP
        for _, e in ipairs(Win._espObjects) do pcall(function() e:Destroy() end) end
        Win._espObjects = {}
        -- Destroy all Drawing.new objects (skeleton, 3D box previews)
        for _, d in ipairs(Win._drawingObjects) do pcall(function() d:Remove() end) end
        Win._drawingObjects = {}
        -- Destroy debugger
        if Win._debugGui then pcall(function() Win._debugGui:Destroy() end); Win._debugGui = nil end
        if Win._debugConn then pcall(function() Win._debugConn:Disconnect() end); Win._debugConn = nil end
        -- Destroy ESP ScreenGui dynamically since it was created after this function is written
        pcall(function() game:GetService("CoreGui"):FindFirstChild("PeronaESP_Gui"):Destroy() end)
        pcall(function() game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui"):FindFirstChild("PeronaESP_Gui"):Destroy() end)
        -- Destroy main UI
        pcall(function() Main:Destroy() end)
        pcall(function() HUD:Destroy() end)
        pcall(function() KBOverlay:Destroy() end)
        pcall(function() Gui:Destroy() end)
    end
    -- Toggle key uses Flags so it can be rebound at runtime
    Flags["__toggle_key"] = toggleKey
    Win:AddConn(UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        local curKey = Flags["__toggle_key"]
        if curKey and inp.KeyCode == curKey then Win:Toggle() end
    end))
    -- ── Config system ─────────────────────────────────────────────────────────
    local function Serialize()
        local d={}
        for k,v in pairs(Flags) do
            local t=type(v)
            if t=="boolean" or t=="number" or t=="string" then d[k]={type=t,value=v}
            elseif t=="table" then d[k]={type="table",value=v}
            elseif typeof(v)=="Color3" then d[k]={type="Color3",r=v.R,g=v.G,b=v.B}
elseif typeof(v)=="EnumItem" then d[k]={type="EnumItem",enum=tostring(v)} end
        end
        return d
    end
    local function Deserialize(d)
        -- First pass: set all flag values
        for k,e in pairs(d) do pcall(function()
            if e.type=="boolean" or e.type=="number" or e.type=="string" then Flags[k]=e.value
            elseif e.type=="table" then Flags[k]=e.value
            elseif e.type=="Color3" then Flags[k]=Color3.new(e.r,e.g,e.b)
            elseif e.type=="EnumItem" then local p=e.enum:split("."); if #p==3 then Flags[k]=Enum[p[2]][p[3]] end end
        end) end
        -- Second pass: call UI setters so elements visually update + fire callbacks
        for k,e in pairs(d) do
            pcall(function()
                local setter = Win._flagSetters[k]
                if setter then
                    setter(Flags[k])
                end
            end)
        end
    end
    Win._memConfigs={}; Win._memThemes={}
    function Win:SaveConfig(name)
        name=name or"default"; local d=Serialize()
        local ok,enc=pcall(function() return HS:JSONEncode(d) end)
        if ok then SafeWrite(folderName.."/configs/"..name..".json",enc) end
        Win._memConfigs[name]=d; return name
    end
    function Win:LoadConfig(name)
        name=name or"default"
        local raw=SafeRead(folderName.."/configs/"..name..".json")
        if raw then local ok,d=pcall(function() return HS:JSONDecode(raw) end); if ok then Deserialize(d);return true end end
        if Win._memConfigs[name] then Deserialize(Win._memConfigs[name]);return true end; return false
    end
    function Win:ListConfigs()
        local list={}; local seen={}
        for _,f in ipairs(SafeList(folderName.."/configs")) do local n=f:match("([^/\\]+)%.json$"); if n then table.insert(list,n);seen[n]=true end end
        for k in pairs(Win._memConfigs) do if not seen[k] then table.insert(list,k) end end
        return list
    end
    function Win:DeleteConfig(name) name=name or"default"; SafeDel(folderName.."/configs/"..name..".json"); Win._memConfigs[name]=nil end
    function Win:SetThemeColor(key,color) T[key]=color; ApplyTheme() end
    function Win:SaveTheme(name)
        name=name or"default"; local d={}
        for k,v in pairs(T) do if typeof(v)=="Color3" then d[k]={r=v.R,g=v.G,b=v.B} end end
        local ok,enc=pcall(function() return HS:JSONEncode(d) end)
        if ok then SafeWrite(folderName.."/themes/"..name..".json",enc) end
        Win._memThemes[name]=d
    end
    function Win:LoadTheme(name)
        name=name or"default"
        local function Apply(d) for k,v in pairs(d) do pcall(function() if T[k] then T[k]=Color3.new(v.r,v.g,v.b) end end) end; ApplyTheme() end
        local raw=SafeRead(folderName.."/themes/"..name..".json")
        if raw then local ok,d=pcall(function() return HS:JSONDecode(raw) end); if ok then Apply(d);return true end end
        if Win._memThemes[name] then Apply(Win._memThemes[name]);return true end; return false
    end
    -- ═══════════════════════════════════════════════════════════════════════
    --  ESP API (Built-in ESP System)
    -- ═══════════════════════════════════════════════════════════════════════
    Win._espObjects = {}
    local SharedRaycastParams = RaycastParams.new()
    SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Batched ESP render loop: single connection updates ALL ESP objects
    local _lastEspCam = nil
    local _lastEspChar = nil
    local _espBatchConn = RS.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local lpChar = LP and LP.Character
        if cam ~= _lastEspCam or lpChar ~= _lastEspChar then
            _lastEspCam = cam
            _lastEspChar = lpChar
            if cam and lpChar then
                SharedRaycastParams.FilterDescendantsInstances = {cam, lpChar}
            elseif cam then
                SharedRaycastParams.FilterDescendantsInstances = {cam}
            else
                SharedRaycastParams.FilterDescendantsInstances = {}
            end
        end
        for i = 1, #Win._espObjects do
            local espObj = Win._espObjects[i]
if espObj and espObj._update then
                espObj._update()
            end
        end
    end)
    -- ESP drawing holder (separate ScreenGui behind main UI)
    local ESPGui
    pcall(function()
        ESPGui = CoreGui:FindFirstChild("PeronaESP_Gui")
        if ESPGui then ESPGui:Destroy() end
        ESPGui = New("ScreenGui", { Name = "PeronaESP_Gui", ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = -1, Parent = CoreGui })
    end)
    if not ESPGui then
        ESPGui = New("ScreenGui", { Name = "PeronaESP_Gui", ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = -1, Parent = LP:FindFirstChildOfClass("PlayerGui") })
    end
    local ESPHolder = New("Folder", { Name = "PeronaESP", Parent = ESPGui })
    local function GetCharacterFromTarget(target)
        -- target can be a Player, Model, or BasePart
        if target:IsA("Player") then
            return target.Character
        elseif target:IsA("Model") then
            return target
        elseif target:IsA("BasePart") then
            return target.Parent and target.Parent:IsA("Model") and target.Parent or nil
        end
        return nil
    end
    local function GetBoundingBox(model)
        local cf, size = model:GetBoundingBox()
        return cf, size
    end
    local function WorldToScreen(pos)
        local cam = workspace.CurrentCamera
        if not cam then return nil, false end
        local screenPos, onScreen = cam:WorldToViewportPoint(pos)
        return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
    end
    local function CreateESPObject(config)
        local espType = config.Type or "Box"
        local target = config.Target
        local color = config.Color or T.Accent
        local name = config.Name
        local thickness = config.Thickness or 1
        local showName = config.ShowName ~= false
        local showHealth = config.ShowHealth ~= false
        local showBox = config.ShowBox ~= false and (espType == "Box" or espType == "Full" or espType == "2DBox" or espType == "3DBox")
        local showTracer = config.ShowTracer == true or espType == "Tracer" or espType == "Full"
        local showSkeleton = config.ShowSkeleton == true or espType == "Full"
        local showFill = config.Fill == true
        local fillTrans = config.FillTransparency or 0.5
        local imageLink = config.Image
        local is3DBox = (espType == "3DBox")
        local enabled = true
        local espObj = { _drawings = {}, _target = target, _enabled = true, _config = config, _isRendered = false }
        function espObj:SetEnabled(bool) self._enabled = bool; if not bool and self._hideAll then self._hideAll() end end
        function espObj:GetEnabled() return self._enabled end
        function espObj:IsRendered() return self._isRendered end
        function espObj:SetColor(c) color = c; if self._updateColor then self._updateColor(c) end end
        -- Use Roblox UI elements for ESP drawing (compatible with all executors)
        local BoxFill = New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=color,BackgroundTransparency=fillTrans,BorderSizePixel=0,Visible=false,ZIndex=49,Parent=ESPHolder})
        local BoxImg = New("ImageLabel",{Size=UDim2.new(1,0,1,0),Image="",BackgroundTransparency=1,ImageTransparency=fillTrans,Visible=false,ZIndex=49,Parent=ESPHolder})
        local BoxTop = New("Frame",{Size=UDim2.new(0,0,0,thickness),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
        local BoxBot = New("Frame",{Size=UDim2.new(0,0,0,thickness),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
        local BoxLeft = New("Frame",{Size=UDim2.new(0,thickness,0,0),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
        local BoxRight = New("Frame",{Size=UDim2.new(0,thickness,0,0),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
        local NameLbl = New("TextLabel",{Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextColor3=color,Font=T.Font,TextSize=12,TextStrokeTransparency=0.5,TextStrokeColor3=Color3.new(0,0,0),Visible=false,ZIndex=51,Parent=ESPHolder})
local HBBg = New("Frame",{Size=UDim2.new(0,3,0,0),BackgroundColor3=Color3.fromHex("1A1A1A"),BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder},{New("UICorner",{CornerRadius=UDim.new(0,1)})})
        local HBFill = New("Frame",{Size=UDim2.new(1,0,1,0),AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),BackgroundColor3=T.Green,BorderSizePixel=0,ZIndex=51,Parent=HBBg},{New("UICorner",{CornerRadius=UDim.new(0,1)})})
        local TracerLine = New("Frame",{Size=UDim2.new(0,thickness,0,0),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=49,Parent=ESPHolder})
        -- Skeleton bone lines (forced Drawing.new for quality)
        local R15Bones = {
                {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
            {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        }
        local R6Bones = {
                {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
        }
        local skeletonLines = {}
        local _skeletonIsDrawing = false
        local _hasDrawingAPI = pcall(function() return Drawing and Drawing.new end)
        if _hasDrawingAPI and showSkeleton then
            for i = 1, 14 do
                local ok, sl = pcall(function()
                    local l = Drawing.new("Line")
                    l.Color = color; l.Thickness = thickness; l.Visible = false
                    return l
                end)
                if ok and sl then table.insert(skeletonLines, sl) end
            end
            if #skeletonLines > 0 then _skeletonIsDrawing = true end
        end
        -- 3D box lines (12 edges)
        local box3DLines = {}
        local _3DBoxIsDrawing = false
        if _hasDrawingAPI then
            for i = 1, 12 do
                local ok, bl = pcall(function()
                    local l = Drawing.new("Line")
                    l.Color = color; l.Thickness = thickness; l.Visible = false
                    return l
                end)
                if ok and bl then table.insert(box3DLines, bl) end
            end
            if #box3DLines == 12 then _3DBoxIsDrawing = true end
        end
        if not _3DBoxIsDrawing then
            box3DLines = {}
            for i = 1, 12 do
                local bl = New("Frame",{Size=UDim2.new(0,thickness,0,0),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
                table.insert(box3DLines, bl)
            end
        end
        local boxCornerLines = {}
        for i = 1, 8 do
            local bl = New("Frame",{Size=UDim2.new(0,thickness,0,0),BackgroundColor3=color,BorderSizePixel=0,Visible=false,ZIndex=50,Parent=ESPHolder})
            table.insert(boxCornerLines, bl)
        end
        local BoxImg = New("ImageLabel",{Size=UDim2.new(1,0,1,0),Image="",BackgroundTransparency=1,ImageTransparency=fillTrans,Visible=false,ZIndex=49,Parent=ESPHolder})
        espObj._drawings = {BoxTop, BoxBot, BoxLeft, BoxRight, BoxFill, BoxImg, NameLbl, HBBg, HBFill, TracerLine}
        for _,bl in ipairs(box3DLines) do table.insert(espObj._drawings, bl) end
        for _,bl in ipairs(boxCornerLines) do table.insert(espObj._drawings, bl) end
        -- Fast hide helper (avoids per-element pcall overhead)
        local function HideAll()
            for i = 1, #espObj._drawings do espObj._drawings[i].Visible = false end
            for i = 1, #skeletonLines do skeletonLines[i].Visible = false end
        end
        local function Update()
            if not espObj._enabled then HideAll(); return end
            local cType = espObj._config.Type or "Box"
            local eShowBox = espObj._config.ShowBox ~= false and (cType == "Box" or cType == "Full" or cType == "2DBox" or cType == "3DBox" or cType == "CornerBox")
            local eIs3DBox = (cType == "3DBox")
            local eIsCornerBox = (cType == "CornerBox")
            local eShowFill = espObj._config.Fill == true
            local eShowName = espObj._config.ShowName ~= false
local eShowHealth = espObj._config.ShowHealth ~= false
            local eShowTracer = espObj._config.ShowTracer == true or cType == "Tracer" or cType == "Full"
            local eShowSkeleton = espObj._config.ShowSkeleton == true or cType == "Full"
            local cBoxColor = espObj._config.BoxColor or color
            local cNameColor = espObj._config.NameColor or color
            local cTracerColor = espObj._config.TracerColor or color
            local cSkeletonColor = espObj._config.SkeletonColor or color
            local cFillColor = espObj._config.FillColor or cBoxColor
            local cImage = espObj._config.Image
            local char = GetCharacterFromTarget(target)
            if not char or not char.Parent then HideAll(); return end
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if not hrp then HideAll(); return end
            -- Calculate 2D bounding box from character parts (not GetBoundingBox which includes tools)
            local cam = workspace.CurrentCamera
            if not cam then return end
            local eVisibleOnly = espObj._config.VisibleOnly == true
            local eVisibleCheck = espObj._config.VisibleCheck == true
            local isVisible = true
            if eVisibleOnly or eVisibleCheck then
                local head = char:FindFirstChild("Head") or hrp
                local dir = head.Position - cam.CFrame.Position
                local ray = workspace:Raycast(cam.CFrame.Position, dir, SharedRaycastParams)
                if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then
                    isVisible = false
                end
                if eVisibleOnly and not isVisible then
                    HideAll(); return
                end
            end
            -- VisibleCheck: change color based on visibility
            local activeColor = color
            if eVisibleCheck then
                activeColor = isVisible and color or Color3.fromRGB(255, 0, 0)
                cBoxColor = activeColor; cNameColor = activeColor; cTracerColor = activeColor
            end
            -- Use Head top + feet bottom for accurate box
            local head = char:FindFirstChild("Head")
            local topPos = head and (head.Position + Vector3.new(0, 0.5, 0)) or (hrp.Position + Vector3.new(0, 2, 0))
            -- Find feet position
            local lFoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
            local rFoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")
            local botY
            if lFoot and rFoot then
                botY = math.min(lFoot.Position.Y, rFoot.Position.Y) - 0.5
            elseif lFoot then
                botY = lFoot.Position.Y - 0.5
            elseif rFoot then
                botY = rFoot.Position.Y - 0.5
            else
                botY = hrp.Position.Y - 3
            end
            local botPos = Vector3.new(hrp.Position.X, botY, hrp.Position.Z)
            local top2D, topOn = WorldToScreen(topPos)
            local bot2D, botOn = WorldToScreen(botPos)
            -- Also project HRP for centering X (avoids tool-shifting)
            local hrp2D, hrpOn = WorldToScreen(hrp.Position)
            if not topOn and not botOn then HideAll(); return end
            local height = math.abs(bot2D.Y - top2D.Y)
            local width = height * 0.5
            local centerX = hrp2D and hrp2D.X or ((top2D.X + bot2D.X) / 2)
            local bx = centerX - width/2
            local by = top2D.Y
            -- Box ESP (2D)
            if eShowBox and not eIs3DBox and not eIsCornerBox then
                BoxTop.Position = UDim2.new(0, bx, 0, by)
                BoxTop.Size = UDim2.new(0, width, 0, thickness)
                BoxTop.BackgroundColor3 = cBoxColor
                BoxTop.Visible = true
                BoxBot.Position = UDim2.new(0, bx, 0, by + height)
                BoxBot.Size = UDim2.new(0, width, 0, thickness)
                BoxBot.BackgroundColor3 = cBoxColor
                BoxBot.Visible = true
                BoxLeft.Position = UDim2.new(0, bx, 0, by)
                BoxLeft.Size = UDim2.new(0, thickness, 0, height)
                BoxLeft.BackgroundColor3 = cBoxColor
                BoxLeft.Visible = true
                BoxRight.Position = UDim2.new(0, bx + width, 0, by)
                BoxRight.Size = UDim2.new(0, thickness, 0, height)
                BoxRight.BackgroundColor3 = cBoxColor
                BoxRight.Visible = true
                if eShowFill or (cImage and cImage ~= "") then
                    if cImage and cImage ~= "" then
                        BoxFill.Visible = false
                        BoxImg.Image = cImage
                        BoxImg.Position = UDim2.new(0, (eIsCornerBox and bx or bx), 0, (eIsCornerBox and by or by))
                        BoxImg.Size = UDim2.new(0, width, 0, height)
BoxImg.Visible = true
                    else
                        BoxImg.Visible = false
                        BoxFill.BackgroundColor3 = cFillColor
                        BoxFill.Position = UDim2.new(0, bx, 0, by)
                        BoxFill.Size = UDim2.new(0, width, 0, height)
                        BoxFill.Visible = true
                        local extG = BoxFill:FindFirstChild("FillGradient")
                        if extG then extG:Destroy() end
                    end
                else
                    BoxFill.Visible = false; BoxImg.Visible = false
                end
            else
                BoxTop.Visible = false; BoxBot.Visible = false
                BoxLeft.Visible = false; BoxRight.Visible = false
            end
            if not eShowBox or eIs3DBox or not eShowFill then
                BoxFill.Visible = false; BoxImg.Visible = false
            end
            -- Corner Box ESP
            if eShowBox and eIsCornerBox then
                local cw = width / 4
                local ch = cw
                local lines = boxCornerLines
                -- Top Left
                lines[1].Position = UDim2.new(0, bx, 0, by); lines[1].Size = UDim2.new(0, cw, 0, thickness)
                lines[2].Position = UDim2.new(0, bx, 0, by); lines[2].Size = UDim2.new(0, thickness, 0, ch)
                -- Top Right
                lines[3].Position = UDim2.new(0, bx + width - cw, 0, by); lines[3].Size = UDim2.new(0, cw, 0, thickness)
                lines[4].Position = UDim2.new(0, bx + width, 0, by); lines[4].Size = UDim2.new(0, thickness, 0, ch)
                -- Bottom Left
                lines[5].Position = UDim2.new(0, bx, 0, by + height); lines[5].Size = UDim2.new(0, cw, 0, thickness)
                lines[6].Position = UDim2.new(0, bx, 0, by + height - ch); lines[6].Size = UDim2.new(0, thickness, 0, ch)
                -- Bottom Right
                lines[7].Position = UDim2.new(0, bx + width - cw, 0, by + height); lines[7].Size = UDim2.new(0, cw + thickness, 0, thickness)
                lines[8].Position = UDim2.new(0, bx + width, 0, by + height - ch); lines[8].Size = UDim2.new(0, thickness, 0, ch)
                for _,l in ipairs(lines) do l.BackgroundColor3 = cBoxColor; l.Visible = true end
            else
                for _,l in ipairs(boxCornerLines) do l.Visible = false end
            end
            -- 3D Box ESP (still uses GetBoundingBox for cube geometry)
            if eShowBox and eIs3DBox then
                local ok3d, cf3d, sz3d = pcall(GetBoundingBox, char)
                if ok3d then
                local hx, hy, hz = sz3d.X/2, sz3d.Y/2, sz3d.Z/2
                local corners3D = {
                        cf3d * Vector3.new(-hx, hy, -hz), cf3d * Vector3.new(hx, hy, -hz),
                    cf3d * Vector3.new(hx, hy, hz),   cf3d * Vector3.new(-hx, hy, hz),
                    cf3d * Vector3.new(-hx, -hy, -hz), cf3d * Vector3.new(hx, -hy, -hz),
                    cf3d * Vector3.new(hx, -hy, hz),   cf3d * Vector3.new(-hx, -hy, hz),
                }
                local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                local c2d = {}
                local cDepth = {}
                local anyOn = false
                for ci, corner in ipairs(corners3D) do
                    local s2d, sOn, sZ = WorldToScreen(corner)
                    c2d[ci] = s2d
                    cDepth[ci] = sZ or 0
                    if sOn and sZ and sZ > 0 then anyOn = true end
                end
                if anyOn then
                    for ei, edge in ipairs(edges) do
                        local p1, p2 = c2d[edge[1]], c2d[edge[2]]
                        local d1, d2 = cDepth[edge[1]], cDepth[edge[2]]
                        if p1 and p2 and d1 > 0 and d2 > 0 then
                            if _3DBoxIsDrawing then
                                box3DLines[ei].From = p1
                                box3DLines[ei].To = p2
                                box3DLines[ei].Color = cBoxColor
                                box3DLines[ei].Visible = true
                            else
                                local dx = p2.X - p1.X
                                local dy = p2.Y - p1.Y
                                local dist = math.sqrt(dx*dx + dy*dy)
                                local ang = math.atan2(dy, dx)
box3DLines[ei].Position = UDim2.new(0, p1.X, 0, p1.Y)
                                box3DLines[ei].Size = UDim2.new(0, thickness, 0, dist)
                                box3DLines[ei].Rotation = math.deg(ang) - 90
                                box3DLines[ei].BackgroundColor3 = cBoxColor
                                box3DLines[ei].Visible = true
                            end
                        else
                            box3DLines[ei].Visible = false
                        end
                    end
                else
                    for _,bl in ipairs(box3DLines) do bl.Visible = false end
                end
                else
                    for _,bl in ipairs(box3DLines) do bl.Visible = false end
                end
            else
                for _,bl in ipairs(box3DLines) do bl.Visible = false end
            end
            -- Name ESP
            if eShowName then
                local displayName = name
                if not displayName then
                    if target:IsA("Player") then displayName = target.DisplayName or target.Name
                    else displayName = target.Name end
                end
                NameLbl.Text = displayName
                NameLbl.TextColor3 = cNameColor
                NameLbl.Position = UDim2.new(0, centerX - NameLbl.AbsoluteSize.X/2, 0, by - 16)
                NameLbl.Visible = true
            else
                NameLbl.Visible = false
            end
            -- Health Bar ESP
            if eShowHealth then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    HBBg.Position = UDim2.new(0, bx - 6, 0, by)
                    HBBg.Size = UDim2.new(0, 3, 0, height)
                    HBBg.Visible = true
                    HBFill.Size = UDim2.new(1, 0, pct, 0)
                    local g = math.clamp(pct * 2, 0, 1)
                    local r = math.clamp(2 - pct * 2, 0, 1)
                    HBFill.BackgroundColor3 = Color3.new(r, g, 0)
                else
                    HBBg.Visible = false
                end
            else
                HBBg.Visible = false
            end
            -- Tracer ESP
            if eShowTracer then
                local screenBottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                local targetPos = Vector2.new(centerX, by + height)
                local delta = targetPos - screenBottom
                local dist = delta.Magnitude
                local angle = math.atan2(delta.Y, delta.X)
                TracerLine.Position = UDim2.new(0, screenBottom.X, 0, screenBottom.Y)
                TracerLine.Size = UDim2.new(0, thickness, 0, dist)
                TracerLine.Rotation = math.deg(angle) - 90
                TracerLine.BackgroundColor3 = cTracerColor
                TracerLine.Visible = true
            else
                TracerLine.Visible = false
            end
            -- Skeleton ESP (forced Drawing.new)
            if eShowSkeleton and _skeletonIsDrawing then
                local char2 = GetCharacterFromTarget(target)
                if char2 then
                    local bones = char2:FindFirstChild("UpperTorso") and R15Bones or R6Bones
                    for bi, bone in ipairs(bones) do
                        if skeletonLines[bi] then
                            local p1 = char2:FindFirstChild(bone[1])
                            local p2 = char2:FindFirstChild(bone[2])
                            if p1 and p2 then
                                local s1, on1 = WorldToScreen(p1.Position)
                                local s2, on2 = WorldToScreen(p2.Position)
                                if on1 and on2 and s1 and s2 then
                                    skeletonLines[bi].From = s1
                                    skeletonLines[bi].To = s2
                                    skeletonLines[bi].Color = cSkeletonColor
                                    skeletonLines[bi].Visible = true
                                else
                                    skeletonLines[bi].Visible = false
                                end
                            else
                                skeletonLines[bi].Visible = false
                            end
                        end
                    end
for bi = #bones+1, #skeletonLines do
                        skeletonLines[bi].Visible = false
                    end
                end
            else
                for i = 1, #skeletonLines do skeletonLines[i].Visible = false end
            end
        end
        -- Store update for batched render loop (no per-object connection)
        espObj._update = Update
        function espObj:SetEnabled(v)
            espObj._enabled = v
            if not v then HideAll() end
        end
        function espObj:SetColor(c)
            color = c
        end
        function espObj:VisibleCheck(v)
            espObj._config.VisibleCheck = v
        end
        function espObj:VisibleOnly(v)
            espObj._config.VisibleOnly = v
        end
        function espObj:SetVisibleColor(visible, hidden)
            espObj._config.VisibleColor = visible
            espObj._config.HiddenColor = hidden
        end
        function espObj:Destroy()
            espObj._update = nil
            for _,d in ipairs(espObj._drawings) do pcall(function() d:Destroy() end) end
            -- Skeleton & 3D Box drawing objects need explicit Remove
            if _skeletonIsDrawing then
                for _,sl in ipairs(skeletonLines) do pcall(function() sl:Remove() end) end
            end
            if _3DBoxIsDrawing then
                for _,bl in ipairs(box3DLines) do pcall(function() bl:Remove() end) end
            end
            for i,e in ipairs(Win._espObjects) do
                if e == espObj then table.remove(Win._espObjects, i); break end
            end
        end
        function espObj:GetEnabled() return espObj._enabled end
        table.insert(Win._espObjects, espObj)
        return espObj
    end
    -- ═══════════════════════════════════════════════════════════════════════
    --  Drawing.new ESP Renderer (executor Drawing API)
    -- ═══════════════════════════════════════════════════════════════════════
    -- Build Drawing.new ESP Object
    local function CreateDrawingESPObject(config)
        local espType = config.Type or "Box"
        local target = config.Target
        local color = config.Color or T.Accent
        local name = config.Name
        local thickness = config.Thickness or 1
        local showName = config.ShowName ~= false
        local showHealth = config.ShowHealth ~= false
        local showBox = config.ShowBox ~= false and (espType ~= "Tracer")
        local showTracer = config.ShowTracer == true or espType == "Tracer" or espType == "Full"
        local showSkeleton = config.ShowSkeleton == true or espType == "Full"
        local is3DBox = (espType == "3DBox")
        local espObj = { _drawings = {}, _target = target, _enabled = true, _config = config, _isDrawing = true }
        -- Create Drawing objects
        local dBox = {}
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Color = color; line.Thickness = thickness; line.Visible = false
            table.insert(dBox, line)
            table.insert(espObj._drawings, line)
        end
        local dCornerBox = {}
        for i = 1, 8 do
            local line = Drawing.new("Line")
            line.Color = color; line.Thickness = thickness; line.Visible = false
            table.insert(dCornerBox, line)
            table.insert(espObj._drawings, line)
        end
        -- 3D box lines
        local d3DBox = {}
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Color = color; line.Thickness = thickness; line.Visible = false
            table.insert(d3DBox, line)
            table.insert(espObj._drawings, line)
        end
        -- Name
        local dName = Drawing.new("Text")
        dName.Color = color; dName.Size = 13; dName.Center = true
        dName.Outline = true; dName.OutlineColor = Color3.new(0,0,0)
        dName.Visible = false
        pcall(function() dName.Font = 2 end) -- Plex/System font
        table.insert(espObj._drawings, dName)
        -- Health bar (bg + fill)
        local dHBBg = Drawing.new("Line")
        dHBBg.Color = Color3.fromHex("1A1A1A"); dHBBg.Thickness = 4; dHBBg.Visible = false
        table.insert(espObj._drawings, dHBBg)
        local dHBFill = Drawing.new("Line")
        dHBFill.Color = Color3.fromHex("3CFF6E"); dHBFill.Thickness = 2; dHBFill.Visible = false
        table.insert(espObj._drawings, dHBFill)
        -- Tracer
local dTracer = Drawing.new("Line")
        dTracer.Color = color; dTracer.Thickness = thickness; dTracer.Visible = false
        table.insert(espObj._drawings, dTracer)
            local dFill = Drawing.new("Square")
            dFill.Color = color; dFill.Filled = true; dFill.Transparency = 1 - (config.FillTransparency or 0.5); dFill.Visible = false
            table.insert(espObj._drawings, dFill)
            -- ImageLabel bound to ESPHolder (bypasses broken executor Drawing.new("Image"))
            local dImg = New("ImageLabel", {
                    Size = UDim2.new(1,0,1,0),
                Image = "",
                BackgroundTransparency = 1,
                ImageTransparency = config.FillTransparency or 0.5,
                Visible = false,
                ZIndex = 49,
                Parent = ESPHolder
            })
            table.insert(espObj._drawings, dImg)
            -- Skeleton lines
            local R15B = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
            local R6B = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
            local dSkeleton = {}
            for i = 1, 14 do
                local line = Drawing.new("Line")
                line.Color = color; line.Thickness = thickness; line.Visible = false
                table.insert(dSkeleton, line)
                table.insert(espObj._drawings, line)
            end
            local function HideAllD()
                espObj._isRendered = false
                for i = 1, #espObj._drawings do espObj._drawings[i].Visible = false end
            end
            espObj._hideAll = HideAllD
            local function Update()
                if not espObj._enabled then HideAllD(); return end
                local cType = espObj._config.Type or "Box"
                local eShowBox = espObj._config.ShowBox ~= false and (cType == "Box" or cType == "Full" or cType == "2DBox" or cType == "3DBox" or cType == "CornerBox")
                local eIs3DBox = (cType == "3DBox")
                local eIsCornerBox = (cType == "CornerBox")
                local eShowFill = espObj._config.Fill == true
                local eShowName = espObj._config.ShowName ~= false
                local eShowHealth = espObj._config.ShowHealth ~= false
                local eShowTracer = espObj._config.ShowTracer == true or cType == "Tracer" or cType == "Full"
                local eShowSkeleton = espObj._config.ShowSkeleton == true or cType == "Full"
                local cBoxColor = espObj._config.BoxColor or color
                local cNameColor = espObj._config.NameColor or color
                local cTracerColor = espObj._config.TracerColor or color
                local cSkeletonColor = espObj._config.SkeletonColor or color
                local cFillColor = espObj._config.FillColor or cBoxColor
                local char = GetCharacterFromTarget(target)
                if not char or not char.Parent then HideAllD(); return end
                local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if not hrp then HideAllD(); return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local eVisibleOnly = espObj._config.VisibleOnly == true
                local eVisibleCheck = espObj._config.VisibleCheck == true
                local isVisible = true
                if eVisibleOnly or eVisibleCheck then
                    local head = char:FindFirstChild("Head") or hrp
                    local dir = head.Position - cam.CFrame.Position
                    local ray = workspace:Raycast(cam.CFrame.Position, dir, SharedRaycastParams)
                    if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then
                        isVisible = false
                    end
                    if eVisibleOnly and not isVisible then
                        HideAllD(); return
                    end
                end
                local activeColor = color
                if eVisibleCheck then
                    activeColor = isVisible and color or Color3.fromRGB(255, 0, 0)
                    cBoxColor = activeColor; cNameColor = activeColor; cTracerColor = activeColor
                end
                -- Use Head top + feet bottom for accurate box (not GetBoundingBox)
                local head = char:FindFirstChild("Head")
                local topPos = head and (head.Position + Vector3.new(0, 0.5, 0)) or (hrp.Position + Vector3.new(0, 2, 0))
local lFoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
                local rFoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")
                local botY
                if lFoot and rFoot then
                    botY = math.min(lFoot.Position.Y, rFoot.Position.Y) - 0.5
                elseif lFoot then botY = lFoot.Position.Y - 0.5
                elseif rFoot then botY = rFoot.Position.Y - 0.5
                else botY = hrp.Position.Y - 3 end
                local botPos = Vector3.new(hrp.Position.X, botY, hrp.Position.Z)
                local top2D, topOn, topZ = WorldToScreen(topPos)
                local bot2D, botOn, botZ = WorldToScreen(botPos)
                local hrp2D = WorldToScreen(hrp.Position)
                if (not topOn and not botOn) or (topZ and topZ < 0) then HideAllD(); return end
                local height = math.abs(bot2D.Y - top2D.Y)
                local width = height * 0.5
                local centerX = hrp2D and hrp2D.X or ((top2D.X + bot2D.X) / 2)
                local bx = centerX - width/2
                local by = top2D.Y
                -- 2D Box
                if eShowBox and not eIs3DBox and not eIsCornerBox and #dBox >= 4 then
                    dBox[1].From = Vector2.new(bx, by); dBox[1].To = Vector2.new(bx+width, by); dBox[1].Color = cBoxColor; dBox[1].Visible = true
                    dBox[2].From = Vector2.new(bx, by+height); dBox[2].To = Vector2.new(bx+width, by+height); dBox[2].Color = cBoxColor; dBox[2].Visible = true
                    dBox[3].From = Vector2.new(bx, by); dBox[3].To = Vector2.new(bx, by+height); dBox[3].Color = cBoxColor; dBox[3].Visible = true
                    dBox[4].From = Vector2.new(bx+width, by); dBox[4].To = Vector2.new(bx+width, by+height); dBox[4].Color = cBoxColor; dBox[4].Visible = true
                else
                    for _,l in ipairs(dBox) do l.Visible = false end
                end
                local cImage = espObj._config.Image
                if eShowBox and eShowFill and not eIs3DBox then
                    if cImage and cImage ~= "" then
                        if dFill then dFill.Visible = false end
                        if dImg then
                            dImg.Image = cImage
                            dImg.Position = UDim2.new(0, bx, 0, by)
                            dImg.Size = UDim2.new(0, width, 0, height)
                            dImg.Visible = true
                        end
                    else
                        if dImg then dImg.Visible = false end
                        if dFill then
                            dFill.Color = cFillColor
                            dFill.Position = Vector2.new(bx, by); dFill.Size = Vector2.new(width, height); dFill.Visible = true
                        end
                    end
                else
                    if dFill then dFill.Visible = false end
                    if dImg then dImg.Visible = false end
                end
                -- Corner Box
                if eShowBox and eIsCornerBox and #dCornerBox >= 8 then
                    local cw = width / 4
                    local ch = cw
                    local lines = dCornerBox
                    -- Top Left
                    lines[1].From = Vector2.new(bx, by); lines[1].To = Vector2.new(bx+cw, by)
                    lines[2].From = Vector2.new(bx, by); lines[2].To = Vector2.new(bx, by+ch)
                    -- Top Right
                    lines[3].From = Vector2.new(bx+width-cw, by); lines[3].To = Vector2.new(bx+width, by)
                    lines[4].From = Vector2.new(bx+width, by); lines[4].To = Vector2.new(bx+width, by+ch)
                    -- Bottom Left
                    lines[5].From = Vector2.new(bx, by+height); lines[5].To = Vector2.new(bx+cw, by+height)
                    lines[6].From = Vector2.new(bx, by+height-ch); lines[6].To = Vector2.new(bx, by+height)
                    -- Bottom Right
                    lines[7].From = Vector2.new(bx+width-cw, by+height); lines[7].To = Vector2.new(bx+width, by+height)
                    lines[8].From = Vector2.new(bx+width, by+height-ch); lines[8].To = Vector2.new(bx+width, by+height)
                    for _,l in ipairs(lines) do l.Color = cBoxColor; l.Visible = true end
                else
                    for _,l in ipairs(dCornerBox) do l.Visible = false end
                end
-- 3D Box (uses GetBoundingBox for cube geometry)
            if eShowBox and eIs3DBox and #d3DBox >= 12 then
                local ok3d, cf3d, sz3d = pcall(function() return GetBoundingBox(char) end)
                if ok3d then
                local hx,hy,hz = sz3d.X/2, sz3d.Y/2, sz3d.Z/2
                local corners = {
                        cf3d*Vector3.new(-hx,hy,-hz), cf3d*Vector3.new(hx,hy,-hz),
                    cf3d*Vector3.new(hx,hy,hz), cf3d*Vector3.new(-hx,hy,hz),
                    cf3d*Vector3.new(-hx,-hy,-hz), cf3d*Vector3.new(hx,-hy,-hz),
                    cf3d*Vector3.new(hx,-hy,hz), cf3d*Vector3.new(-hx,-hy,hz),
                }
                local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                local c2d, cZ = {}, {}
                local anyOn = false
                for ci, corner in ipairs(corners) do
                    local s, sOn, sZ2 = WorldToScreen(corner)
                    c2d[ci] = s; cZ[ci] = sZ2 or 0
                    if sOn and sZ2 and sZ2 > 0 then anyOn = true end
                end
                if anyOn then
                    for ei, edge in ipairs(edges) do
                        local p1, p2 = c2d[edge[1]], c2d[edge[2]]
                        if p1 and p2 and cZ[edge[1]] > 0 and cZ[edge[2]] > 0 then
                            d3DBox[ei].From = p1; d3DBox[ei].To = p2; d3DBox[ei].Color = cBoxColor; d3DBox[ei].Visible = true
                        else d3DBox[ei].Visible = false end
                    end
                else for _,l in ipairs(d3DBox) do l.Visible = false end end
                else for _,l in ipairs(d3DBox) do l.Visible = false end end
            else
                for _,l in ipairs(d3DBox) do l.Visible = false end
            end
            -- Name
            if eShowName then
                local dn = name or (target:IsA("Player") and (target.DisplayName or target.Name) or target.Name)
                dName.Text = dn; dName.Position = Vector2.new(centerX, by - 16); dName.Color = cNameColor; dName.Visible = true
            else dName.Visible = false end
            -- Health
            if eShowHealth then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    dHBBg.From = Vector2.new(bx-6, by); dHBBg.To = Vector2.new(bx-6, by+height); dHBBg.Visible = true
                    local fh = height * pct
                    dHBFill.From = Vector2.new(bx-6, by+height-fh); dHBFill.To = Vector2.new(bx-6, by+height)
                    local g = math.clamp(pct*2,0,1); local r = math.clamp(2-pct*2,0,1)
                    dHBFill.Color = Color3.new(r, g, 0); dHBFill.Visible = true
                else dHBBg.Visible = false; dHBFill.Visible = false end
            else dHBBg.Visible = false; dHBFill.Visible = false end
            -- Tracer
            if eShowTracer then
                local sb = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                dTracer.From = sb; dTracer.To = Vector2.new(centerX, by+height); dTracer.Color = cTracerColor; dTracer.Visible = true
            else dTracer.Visible = false end
            -- Skeleton
            if eShowSkeleton then
                local bones = char:FindFirstChild("UpperTorso") and R15B or R6B
                for bi, bone in ipairs(bones) do
                    if dSkeleton[bi] then
                        local p1, p2 = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
                        if p1 and p2 then
                            local s1, on1, z1 = WorldToScreen(p1.Position)
                            local s2, on2, z2 = WorldToScreen(p2.Position)
                            if on1 and on2 and s1 and s2 and z1 > 0 and z2 > 0 then
                                dSkeleton[bi].From = s1; dSkeleton[bi].To = s2; dSkeleton[bi].Color = cSkeletonColor; dSkeleton[bi].Visible = true
                            else dSkeleton[bi].Visible = false end
                        else dSkeleton[bi].Visible = false end
                    end
                end
                for bi = #bones+1, #dSkeleton do dSkeleton[bi].Visible = false end
            else
                for _,l in ipairs(dSkeleton) do l.Visible = false end
            end
            espObj._isRendered = true
        end
function espObj:SetEnabled(bool) self._enabled = bool; if not bool and self._hideAll then self._hideAll() end end
        function espObj:GetEnabled() return self._enabled end
        function espObj:IsRendered() return self._isRendered end
        function espObj:SetColor(c)
            color = c
            for _, d in ipairs(espObj._drawings) do pcall(function() d.Color = c end) end
        end
        function espObj:VisibleCheck(v)
            espObj._config.VisibleCheck = v
        end
        function espObj:VisibleOnly(v)
            espObj._config.VisibleOnly = v
        end
        function espObj:SetVisibleColor(visible, hidden)
            espObj._config.VisibleColor = visible
            espObj._config.HiddenColor = hidden
        end
        -- Store update for batched render loop (no per-object connection)
        espObj._update = Update
        function espObj:Destroy()
            espObj._update = nil
            for _,d in ipairs(espObj._drawings) do pcall(function() d:Remove() end) end
            for i,e in ipairs(Win._espObjects) do if e == espObj then table.remove(Win._espObjects, i); break end end
        end
        function espObj:GetEnabled() return espObj._enabled end
        table.insert(Win._espObjects, espObj)
        return espObj
    end
    -- Route ESP creation based on drawing mode
    function Win:EspAPI(config)
        if type(config) ~= "table" then
            config = {}
        end
        -- Support both "type"/"Type" and positional target
        config.Type = config.Type or config.type or "Box"
        config.Target = config.Target or config.target
        if not config.Target then
            warn("[PeronaLib] EspAPI: No target specified")
            return nil
        end
        -- Apply team check filter
        if Win._teamCheckEnabled and config.Target then
            local tgt = config.Target
            local targetPlayer = nil
            if tgt:IsA("Player") then
                targetPlayer = tgt
            elseif tgt:IsA("Model") then
                targetPlayer = Players:GetPlayerFromCharacter(tgt)
            end
            if targetPlayer and Win._teamCheckFn then
                if not Win._teamCheckFn(targetPlayer) then
                    return nil -- blocked by team check
                end
            end
        end
        -- Route to correct renderer
        if Win._drawingMode == "Drawing.new" then
            local drawingAvailable = pcall(function() return Drawing.new end)
            if drawingAvailable then
                return CreateDrawingESPObject(config)
            else
                warn("[PeronaLib] Drawing.new not available, falling back to InGame")
                return CreateESPObject(config)
            end
        end
        return CreateESPObject(config)
    end
    --- ApiEsp: Global unified handler for all ESP instances
    --- Ex: Win:ApiEsp("SetColor", target, color3)
    function Win:ApiEsp(action, target, val)
        -- "Included" doesn't need to find the object first
        if action == "Included" then
            for _, e in ipairs(Win._espObjects) do
                if e._target == target then
                    -- If val is provided, it must match the ESP Type (e.g. "Skeleton" or "CornerBox")
                    if not val or e._config.Type == val then return true end
                end
            end
            return false
        end
        local espObj = nil
        for _, e in ipairs(Win._espObjects) do
            if e._target == target then
                espObj = e
                break
            end
        end
        if not espObj then return nil end
        if action == "VisibleCheck" then
            if type(val) == "boolean" then espObj:VisibleCheck(val) end
        elseif action == "VisibleOnly" then
            if type(val) == "boolean" then espObj:VisibleOnly(val) end
        elseif action == "SetEnabled" then
            if type(val) == "boolean" then espObj:SetEnabled(val) end
        elseif action == "SetColor" then
            if typeof(val) == "Color3" then espObj:SetColor(val) end
        elseif action == "Destroy" then
            espObj:Destroy()
        elseif action == "IsRendered" then
            return espObj:IsRendered()
        elseif action == "GetEnabled" then
            return espObj:GetEnabled()
        end
    end
    --- ApiSettings: Configure drawing methods
    --- Drawing: "InGame" (Roblox GUI frames) or "Drawing.new" (executor Drawing API)
    --- Ui_DrawingMethod: "InGame" only (Drawing.new UI is not supported)
    function Win:ApiSettings(opts)
        opts = opts or {}
        if opts.Drawing then
            Win._drawingMode = opts.Drawing
        end
        if opts.Ui_DrawingMethod then
            Win._uiDrawingMethod = opts.Ui_DrawingMethod
            if opts.Ui_DrawingMethod == "Drawing.new" then
                warn("[PeronaLib] Ui_DrawingMethod = 'Drawing.new' is not supported. The UI library requires Roblox GUI instances. Use 'InGame'.")
                Win._uiDrawingMethod = "InGame"
            end
        end
        if opts.PreEspTab or opts.PrePlayersTab or opts.PreDexTab then
            Win:_InitializeBuiltInTabs(opts)
        end
    end
    function Win:_InitializeBuiltInTabs(opts)
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        -- =============================
        -- BUILT IN ESP TAB
        -- =============================
        if opts.PreEspTab and not Win._hasEspTab then
            Win._hasEspTab = true
            local EspTab = Win:Tab("ESP", true)
            local EspSec = EspTab:Section("ESP Settings")

            local function GetAllESPTargets()
                local tgts = {}
                for _, plr in ipairs(Players:GetPlayers()) do table.insert(tgts, plr) end

                if Win._npcPaths then
                    for pth in pairs(Win._npcPaths) do
                        if type(pth) == "string" then
                            local pathSegments = pth:split(".")
                            local cur = game
                            local valid = true
                            for _, seg in ipairs(pathSegments) do
                                pcall(function()
                                    if cur:FindFirstChild(seg) then
                                        cur = cur[seg]
                                    else valid = false; end
                                end)
                                if not valid then break end
                            end
                            if valid and typeof(cur) == "Instance" then
                                pcall(function()
                                    for _, child in ipairs(cur:GetChildren()) do
                                        if child:IsA("Model") and (child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")) then
                                            table.insert(tgts, child)
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
                return tgts
            end

            local function ApplyBuiltInESP(target, forceType)
                if not target or target == LocalPlayer then return end
                local tType = forceType or Flags["preEsp_BoxType"] or "CornerBox"
                if Win:ApiEsp("Included", target, tType) then return end
                Win:ApiEsp("Destroy", target)

                local col = Flags["preEsp_Color"] or Color3.fromRGB(60, 255, 110)
                if target:IsA("Player") then
                    local fColor = Flags["preEsp_FriendlyColor"]
                    local eColor = Flags["preEsp_EnemyColor"]
                    local isFriendly = (Win._customFriendly and Win._customFriendly[target.UserId] == true)
                    if isFriendly and fColor then col = fColor end
                    if not isFriendly and eColor then col = eColor end
                end
                Win:EspAPI({
                        Target = target,
                    Type = tType,
                    Color = col,
                    ShowName = Flags["preEsp_Name"] == true,
                    ShowHealth = Flags["preEsp_Health"] == true,
                    ShowBox = Flags["preEsp_Master"] == true,
                    ShowTracer = Flags["preEsp_Tracer"] == true,
                    ShowSkeleton = Flags["preEsp_Skeleton"] == true,
                    Fill = Flags["preEsp_FillMode"] ~= "None",
                    Image = Flags["preEsp_FillImageURL"],
                    VisibleOnly = Flags["preEsp_VisOnly"] == true,
                    VisibleCheck = Flags["preEsp_VisCheck"] == true,
                    VisibleColor = col,
                    HiddenColor = Color3.fromRGB(255, 50, 50)
                })
                Win:ApiEsp("SetEnabled", target, Flags["preEsp_Master"] == true)
            end

            local function RebuildAll()
                for _, tgt in ipairs(GetAllESPTargets()) do
                    Win:ApiEsp("Destroy", tgt); ApplyBuiltInESP(tgt)
                end
            end

            -- We inject the methods into the global Window object so other events can trigger them
            Win._preEspRebuild = RebuildAll

            EspSec:Toggle({Name="Master ESP", Flag="preEsp_Master", Callback = function(v)
                for _, tgt in ipairs(GetAllESPTargets()) do Win:ApiEsp("SetEnabled", tgt, v) end
            end})
            EspSec:Dropdown({Name="Box Type", Items={"Box","2DBox","3DBox","CornerBox"}, Default="CornerBox", Flag="preEsp_BoxType", Callback=RebuildAll})
            EspSec:ColorPicker({Name="Default Target Color", Default=Color3.fromRGB(60,255,110), Flag="preEsp_Color", Callback=RebuildAll})
            EspSec:ColorPicker({Name="Friendly Override Color", Default=Color3.fromRGB(60,150,255), Flag="preEsp_FriendlyColor", Callback=RebuildAll})
            EspSec:ColorPicker({Name="Enemy Override Color", Default=Color3.fromRGB(255,60,60), Flag="preEsp_EnemyColor", Callback=RebuildAll})
            EspSec:Dropdown({Name="Fill Mode", Items={"None","Solid","Image"}, Default="None", Flag="preEsp_FillMode", Callback=RebuildAll})
            EspSec:Input({Name="Fill Image URL", Default="", Flag="preEsp_FillImageURL", Callback=RebuildAll})
            EspSec:Toggle({Name="Show Name", Flag="preEsp_Name", Callback=RebuildAll})
            EspSec:Toggle({Name="Show Health", Flag="preEsp_Health", Callback=RebuildAll})
            EspSec:Toggle({Name="Show Skeleton", Flag="preEsp_Skeleton", Callback=RebuildAll})
            EspSec:Toggle({Name="Show Tracer", Flag="preEsp_Tracer", Callback=RebuildAll})
            EspSec:Toggle({Name="Visible Only", Flag="preEsp_VisOnly", Callback=function(v)
                for _, tgt in ipairs(GetAllESPTargets()) do Win:ApiEsp("VisibleOnly", tgt, v) end
            end})
            EspSec:Toggle({Name="Visible Check", Flag="preEsp_VisCheck", Callback=function(v)
                for _, tgt in ipairs(GetAllESPTargets()) do Win:ApiEsp("VisibleCheck", tgt, v) end
            end})

            local NpcSec = EspTab:RSection("NPC System")
            NpcSec:Toggle({Name="Auto Scan NPCs", Flag="preEsp_NpcAutoScan", Callback=function(v)
                if v then RebuildAll() end
            end})
            Win._npcPaths = {}
            for i=1, 4 do
                NpcSec:Input({Name="NPC Path "..i, Placeholder="workspace.Enemies", Flag="preEsp_NpcPath"..i, Callback=function(txt)
                    if txt and txt ~= "" then
                        Win._npcPaths[txt] = true
                        if Flags["preEsp_NpcAutoScan"] then RebuildAll() end
                    end
                end})
            end

            Players.PlayerAdded:Connect(function(p) ApplyBuiltInESP(p) end)
            Win:Runtime(function()
                if Flags["preEsp_Master"] then
                    for _, tgt in ipairs(GetAllESPTargets()) do ApplyBuiltInESP(tgt) end
                end
            end)

            local PrevSec = EspTab:RSection("ESP Preview")
            Win._builtinPreview = PrevSec:ViewportPreview({Height=260, BoxColor=Color3.fromRGB(60,255,110), Interactive=true, ModeSwitch=true})
            PrevSec:ButtonRow({
                {Name="Reset Model", Callback=function() if Win._builtinPreview.LoadCharacter then Win._builtinPreview.LoadCharacter() end end},
                {Name="Reset View", Callback=function() if Win._builtinPreview.ResetView then Win._builtinPreview.ResetView() end end}
            })
            Win:Runtime(function()
                if not Win._builtinPreview then return end
                pcall(function()
                    Win._builtinPreview:SetBoxVisible(Flags["preEsp_Master"] == true)
                    Win._builtinPreview:SetNameVisible(Flags["preEsp_Name"] == true)
                    Win._builtinPreview:SetHealthVisible(Flags["preEsp_Health"] == true)
                    Win._builtinPreview:SetTracerVisible(Flags["preEsp_Tracer"] == true)
                    Win._builtinPreview:SetSkeletonVisible(Flags["preEsp_Skeleton"] == true)
                    Win._builtinPreview:SetBoxColor(Flags["preEsp_Color"] or Color3.fromRGB(60,255,110))
                    Win._builtinPreview:SetBoxType(Flags["preEsp_BoxType"] or "CornerBox")
                    local fm = Flags["preEsp_FillMode"] or "None"
                    Win._builtinPreview:SetFillVisible(fm ~= "None")
                    if fm == "Image" then Win._builtinPreview:SetFillImage(Flags["preEsp_FillImageURL"] or "")
                    else Win._builtinPreview:SetFillImage("") end
                end)
            end)
        end

        -- =============================
        -- BUILT IN PLAYERS TAB
        -- =============================
        if opts.PrePlayersTab and not Win._hasPlayersTab then
            Win._hasPlayersTab = true
            local PTab = Win:Tab("Players", true)
            local PSec = PTab:Section("Player List")

            local pNames = {}
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(pNames, p.Name) end end

            local selectedPlayer = nil
            local pDrop = PSec:Dropdown({Name="Select Target", Items=pNames, Default="None", Search=true, Callback=function(v)
                selectedPlayer = Players:FindFirstChild(v)
                if selectedPlayer then
                    Flags["preP_TargetText"] = "<b>Target:</b> " .. selectedPlayer.Name .. "\n<b>User ID:</b> " .. selectedPlayer.UserId
                end
            end})
            Players.PlayerAdded:Connect(function(p) table.insert(pNames, p.Name); pDrop:Refresh(pNames) end)
            Players.PlayerRemoving:Connect(function(p)
                local idx = table.find(pNames, p.Name); if idx then table.remove(pNames, idx); pDrop:Refresh(pNames) end
            end)

            local RSec = PTab:RSection("Player Preview")
            local infoFrame = New("Frame", { Size=UDim2.new(1,0,0,46), BackgroundTransparency=1, LayoutOrder=1, Parent=RSec.Frame })
            local pfp = New("ImageLabel", { Size=UDim2.new(0,40,0,40), Position=UDim2.new(0,0,0,0), BackgroundColor3=Color3.fromHex("181818"), BorderSizePixel=0, Parent=infoFrame }, { New("UICorner", { CornerRadius=UDim.new(1,0) }) })
            local infLbl = New("TextLabel", { Size=UDim2.new(1,-48,1,0), Position=UDim2.new(0,48,0,0), BackgroundTransparency=1, TextColor3=Color3.fromHex("EFEFEF"), Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, RichText=true, Parent=infoFrame })
            
            local VP = New("ViewportFrame", { Size=UDim2.new(1,0,0,160), BackgroundColor3=Color3.fromHex("0E0E0E"), BorderSizePixel=0, LayoutOrder=2, Parent=RSec.Frame }, { New("UICorner",{CornerRadius=UDim.new(0,3)}), New("UIStroke",{Color=T.Border,Thickness=1}) })
            local Cam = Instance.new("Camera"); Cam.Parent = VP; VP.CurrentCamera = Cam
            local WM = Instance.new("WorldModel"); WM.Parent = VP
            local currentClone = nil
            local orbitAngle, orbitPitch, orbitDist = 0, 0.15, 6
            local isDragging, userControlled = false, false
            local lastMouse = Vector2.zero

            local DI = New("TextButton", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=20, Parent=VP })
            table.insert(Win._inputFuncs.began, function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    if DI.AbsolutePosition and (Vector2.new(inp.Position.X, inp.Position.Y) - DI.AbsolutePosition).Magnitude < math.max(DI.AbsoluteSize.X, DI.AbsoluteSize.Y) then
                        isDragging = true; userControlled = true; lastMouse = Vector2.new(inp.Position.X, inp.Position.Y)
                    end
                end
            end)
            table.insert(Win._inputFuncs.changed, function(inp)
                if isDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local nm = Vector2.new(inp.Position.X, inp.Position.Y)
                    local d = nm - lastMouse
                    orbitAngle = orbitAngle + d.X * 0.01
                    orbitPitch = math.clamp(orbitPitch - d.Y * 0.01, -1.5, 1.5)
                    lastMouse = nm
                end
            end)
            table.insert(Win._inputFuncs.ended, function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then isDragging = false end
            end)

            local function LoadCharacter()
                if currentClone then currentClone:Destroy(); currentClone = nil end
                if not selectedPlayer then return end
                task.spawn(function()
                    local ok, clone = pcall(function() return game:GetService("Players"):CreateHumanoidModelFromUserId(selectedPlayer.UserId) end)
                    if ok and clone then
                        clone:PivotTo(CFrame.new(0, 0, 0))
                        clone.Parent = WM
                        currentClone = clone
                    end
                end)
            end

            Win:Runtime(function()
                if not selectedPlayer then
                    infLbl.Text = "No target selected."
                    pfp.Image = ""
                else
                    pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(selectedPlayer.UserId) .. "&w=150&h=150"
                    local coords = "Unknown"
                    if selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local pos = selectedPlayer.Character.HumanoidRootPart.Position
                        coords = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
                    end
                    infLbl.Text = "<b>Target:</b> " .. selectedPlayer.Name .. "\n<b>ID:</b> " .. selectedPlayer.UserId .. "\n<b>Pos:</b> " .. coords
                end

                if currentClone and currentClone.PrimaryPart then
                    local cf = currentClone:GetPivot()
                    if not userControlled then orbitAngle = orbitAngle + 0.005 end
                    local cx = cf.Position.X + math.sin(orbitAngle) * orbitDist * math.cos(orbitPitch)
                    local cz = cf.Position.Z + math.cos(orbitAngle) * orbitDist * math.cos(orbitPitch)
                    local cy = cf.Position.Y + math.sin(orbitPitch) * orbitDist
                    Cam.CFrame = CFrame.new(Vector3.new(cx, cy, cz), cf.Position)
                end
            end)

            local oldSelected = nil
            Win:Runtime(function()
                if selectedPlayer ~= oldSelected then
                    oldSelected = selectedPlayer
                    userControlled = false; orbitAngle = 0; orbitPitch = 0.15
                    LoadCharacter()
                end
            end)

            RSec:ButtonRow({
                {Name="Reset Model", Callback=function() LoadCharacter() end},
                {Name="Reset View", Callback=function() userControlled = false; orbitAngle = 0; orbitPitch = 0.15 end}
            })
            
            local ActSec = PTab:RSection("Target Actions")
            ActSec:ButtonRow({
                {Name="Teleport", Callback=function()
                    if selectedPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    end
                end},
                {Name="Tween", Callback=function()
                    if selectedPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local TS = game:GetService("TweenService")
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - selectedPlayer.Character.HumanoidRootPart.Position).Magnitude
                        local tInfo = TweenInfo.new(dist / 50, Enum.EasingStyle.Linear)
                        TS:Create(LocalPlayer.Character.HumanoidRootPart, tInfo, {CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame}):Play()
                    end
                end}
            })

            local isSpectating = false
            ActSec:ButtonRow({
                {Name="Spectate", Callback=function()
                    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Humanoid") then
                        workspace.CurrentCamera.CameraSubject = selectedPlayer.Character.Humanoid; isSpectating = true
                    end
                end},
                {Name="Unspectate", Callback=function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid; isSpectating = false
                    end
                end}
            })

            Win._customFriendly = Win._customFriendly or {}
            ActSec:ButtonRow({
                {Name="Set Friendly", Callback=function()
                    if selectedPlayer then Win._customFriendly[selectedPlayer.UserId] = true; Win:Notify({Title="Players", Text="Set "..selectedPlayer.Name.." to Friendly", Duration=3}); if Win._preEspRebuild then Win._preEspRebuild() end end
                end},
                {Name="Set Enemy", Callback=function()
                    if selectedPlayer then Win._customFriendly[selectedPlayer.UserId] = nil; Win:Notify({Title="Players", Text="Set "..selectedPlayer.Name.." to Enemy", Duration=3}); if Win._preEspRebuild then Win._preEspRebuild() end end
                end}
            })
        end

        -- =============================

        end
    --  Team Check API
    -- ═══════════════════════════════════════════════════════════════════════
    Win._teamCheckEnabled = false
    Win._teamCheckMode = "none"
    Win._teamCheckFn = nil
    --- TeamCheckAPI(mode, customFn)
    --- mode: "auto" = skip same-team players automatically
    ---       "custom" = use customFn(player) -> bool (true = show ESP, false = skip)
    ---       "none" / nil = disable team check
    --- customFn: only used when mode == "custom"
    function Win:TeamCheckAPI(mode, customFn)
        mode = mode or "none"
        Win._teamCheckMode = mode
        if mode == "auto" then
            Win._teamCheckEnabled = true
            Win._teamCheckFn = function(player)
                -- Auto: skip players on the same team as LocalPlayer
                if not LP then return true end
                if not LP.Team then return true end  -- no team system = show all
                if not player.Team then return true end
                return player.Team ~= LP.Team  -- true = different team = show ESP
            end
        elseif mode == "custom" and type(customFn) == "function" then
            Win._teamCheckEnabled = true
            Win._teamCheckFn = customFn
        else
            Win._teamCheckEnabled = false
            Win._teamCheckFn = nil
        end
    end
    --- Check if a specific player passes the team check
    function Win:PassesTeamCheck(player)
        if not Win._teamCheckEnabled then return true end
        if not Win._teamCheckFn then return true end
        return Win._teamCheckFn(player)
    end
    -- Cleanup all ESP on destroy
    local oldDestroy = Win.Destroy
    function Win:Destroy()
        for _,e in ipairs(Win._espObjects) do pcall(function() e:Destroy() end) end
        Win._espObjects = {}
        pcall(function() ESPHolder:Destroy() end)
        pcall(function() ESPGui:Destroy() end)
        oldDestroy(Win)
    end
    -- ── Built-in Settings Tab (always last via _isInternal) ─────────────────
    Win._settingsBuilt = true
    local SettingsTab = Win:Tab("Settings", true)
    -- Left: Config
    local CfgSec = SettingsTab:Section("Configuration")
    local cfgListObj = CfgSec:TabbedList({ Tabs={""}, Height=70 })
    local selectedCfg = "default"
    local function RefreshCfgList()
        local page=cfgListObj:GetPage(1)
        for _,c in pairs(page:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
        for _,n in ipairs(Win:ListConfigs()) do
            local B=New("TextButton",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=n,TextColor3=n==selectedCfg and T.Accent or T.Text,Font=T.Font,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=page},{New("UIPadding",{PaddingLeft=UDim.new(0,4)})})
            B.MouseButton1Click:Connect(function() selectedCfg=n;Flags["__cfg_name"]=n;RefreshCfgList() end)
        end
    end
    RefreshCfgList()
    CfgSec:Input({Name="Config Name:",Placeholder="Type name...",Flag="__cfg_name",Default="default"})
    CfgSec:ButtonRow({
            {Name="Save",   Callback=function() local n=Flags["__cfg_name"] or"default";Win:SaveConfig(n);selectedCfg=n;RefreshCfgList() end},
        {Name="Load",   Callback=function() Win:LoadConfig(Flags["__cfg_name"] or selectedCfg) end},
    })
    CfgSec:ButtonRow({
            {Name="Delete", Callback=function() Win:DeleteConfig(Flags["__cfg_name"] or selectedCfg);RefreshCfgList() end},
        {Name="Refresh",Callback=function() RefreshCfgList() end},
    })
    -- Left: Menu
    local MenuSec=SettingsTab:Section("Menu")
    MenuSec:Dropdown({Name="Easing Style",Items={"Quint","Quad","Cubic","Sine","Back","Bounce"},Default="Quint",Flag="__easing_style"})
    MenuSec:Dropdown({Name="Easing Direction",Items={"InOut","In","Out"},Default="InOut",Flag="__easing_dir"})
    MenuSec:Slider({Name="Tweening Speed",Min=0.05,Max=1,Default=0.3,Decimals=2,Suffix="s",Flag="__tween_speed"})
    MenuSec:Slider({Name="Dragging Speed",Min=0.01,Max=0.5,Default=0.05,Decimals=2,Suffix="s",Flag="__drag_speed"})
-- Rebindable toggle key (replaces the old static label)
    MenuSec:Keybind({Name="Toggle Key",Default=toggleKey,Flag="__toggle_key",ShowOnKeybindList=false})
    -- Right: HUD
    local HudSec=SettingsTab:RSection("HUD")
    HudSec:Toggle({Name="Watermark",Default=true,Flag="__hud_wm",Callback=function(v) HUD.Visible=v end})
    -- Initialize watermark visibility
    HUD.Visible = true
    local OptSec=SettingsTab:RSection("Options")
    OptSec:Dropdown({Name="HUD Mode",Flag="__hud_mode",Items={"Title, Fps, Ping","Title only","Fps only","None"},Default="Title, Fps, Ping",Callback=function(v) hudMode=v end})
    OptSec:Slider({Name="Refresh Rate",Min=0,Max=10,Default=0,Suffix="s",Flag="__hud_refresh"})
    OptSec:Toggle({Name="Keybind List",Default=true,Flag="__kb_list",Callback=function(v) KBOverlay.Visible=v end})
    OptSec:Toggle({Name="Debugger",Default=false,Flag="__debugger",Callback=function(v) Win:Debug(v) end})
    OptSec:Separator()
    OptSec:Toggle({Name='<font color="#FF3A3A">Allow Unsafe</font>',Default=false,Flag="__allow_unsafe",Callback=function(v) Win._allowUnsafe = v end})
    OptSec:Label('<font color="#FF3A3A">⚠</font> <font color="#AA3333">Unsafe features (e.g. Silent Aim) require this toggle.</font>')
    OptSec:Separator()
    OptSec:Button({Name="Unload UI",Callback=function() Win:Unload() end})
    -- Right: Theming
    local ThemeSec=SettingsTab:RSection("Theming")
    local themeColorDefs={
            {key="Accent",   name="Accent"},
        {key="Bg",       name="Background"},
        {key="Surface1", name="Surface 1"},
        {key="Surface2", name="Surface 2"},
        {key="Border",   name="Border"},
        {key="Text",     name="Text Main"},
        {key="TextDim",  name="Text Dim"},
        {key="Green",    name="Health Color"},
    }
    for _,e in ipairs(themeColorDefs) do
        ThemeSec:ColorPicker({Name=e.name,Default=T[e.key],Flag="__theme_"..e.key,Callback=function(c) Win:SetThemeColor(e.key,c) end})
    end
    local ThemeCfgSec=SettingsTab:RSection("Theme Config")
    ThemeCfgSec:Input({Name="Theme Name:",Placeholder="theme name...",Flag="__theme_cfg_name",Default="default"})
    ThemeCfgSec:ButtonRow({
            {Name="Save",Callback=function() Win:SaveTheme(Flags["__theme_cfg_name"] or"default") end},
        {Name="Load",Callback=function() Win:LoadTheme(Flags["__theme_cfg_name"] or"default") end},
    })
    ThemeCfgSec:ButtonRow({
            {Name="Delete", Callback=function() SafeDel(folderName.."/themes/"..(Flags["__theme_cfg_name"] or"default")..".json") end},
        {Name="Reset",  Callback=function()
            -- reset to defaults
            T.Accent=Color3.fromHex("FF1D6A");T.Bg=Color3.fromHex("0A0A0A");T.Surface1=Color3.fromHex("111111")
            T.Surface2=Color3.fromHex("181818");T.Border=Color3.fromHex("262626");T.Text=Color3.fromHex("EFEFEF")
            T.TextDim=Color3.fromHex("555555");T.Green=Color3.fromHex("3CFF6E")
            ApplyTheme()
        end},
    })
    -- ═══════════════════════════════════════════════════════════════════════
    --  SUPPORTED GAMES LOADER
    -- ═══════════════════════════════════════════════════════════════════════
    function Win:SupportedGames(opts)
        opts = opts or {}
        local gameList = opts.list or {}
        local currentPlaceId = game.PlaceId
        -- Hide main UI elements while loader is active
        Main.Visible = false
        HUD.Visible = false
        KBOverlay.Visible = false
        -- Loader container (no black backdrop, blur only)
        local LoaderBg = New("Frame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 100, Parent = Gui,
        })
        local Loader = New("Frame", {
                Size = UDim2.new(0, 340, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0.5, -170, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Bg, BorderSizePixel = 0, ZIndex = 101,
            BackgroundTransparency = 1, Parent = LoaderBg,
        }, {
                New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            New("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 1 }),
            New("UIPadding", { PaddingLeft=UDim.new(0,16), PaddingRight=UDim.new(0,16),
                PaddingTop=UDim.new(0,16), PaddingBottom=UDim.new(0,16) }),
            New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8),
                HorizontalAlignment=Enum.HorizontalAlignment.Center }),
        })
-- Accent line at top
        New("Frame", {
                Size = UDim2.new(1, 32, 0, 2), BackgroundColor3 = T.Accent,
            BorderSizePixel = 0, ZIndex = 102, LayoutOrder = 0, Parent = Loader,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 1) }) })
        -- Title
        local pref, suf = title:match("^(%a+)(.*)")
        local loaderTitle = pref and ('<font color="#FF1D6A">'..pref..'</font>'..suf) or title
        New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
            Text = loaderTitle, TextColor3 = T.Text, Font = T.Font, TextSize = 16,
            RichText = true, ZIndex = 102, LayoutOrder = 1, Parent = Loader,
        })
        -- Subtitle
        New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
            Text = "select your game", TextColor3 = T.TextDim, Font = T.Font, TextSize = 11,
            ZIndex = 102, LayoutOrder = 2, Parent = Loader,
        })
        -- Game list container
        local GameScroll = New("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 102, LayoutOrder = 3, Parent = Loader,
        }, {
                New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4) }),
        })
        -- Clamp scroll height
        local maxCards = 0
        local selectedGame = nil
        local selectedCard = nil
        local cardButtons = {}
        -- ── Info Panel (right side of loader) ──
        local InfoPanel = New("Frame", {
                Size = UDim2.new(0, 240, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0.5, 182, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Bg, BorderSizePixel = 0, ZIndex = 101,
            BackgroundTransparency = 1, Visible = false, Parent = LoaderBg,
        }, {
                New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            New("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 1 }),
            New("UIPadding", { PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
                PaddingTop=UDim.new(0,14), PaddingBottom=UDim.new(0,14) }),
            New("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8),
                HorizontalAlignment=Enum.HorizontalAlignment.Center }),
        })
        -- Game icon in info panel
        local InfoGameIcon = New("ImageLabel", {
                Size = UDim2.new(0, 56, 0, 56), BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
            ZIndex = 102, LayoutOrder = 1, Parent = InfoPanel,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 8) }) })
        local InfoGameName = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
            Text = "", TextColor3 = T.Text, Font = T.Font, TextSize = 14,
            ZIndex = 102, LayoutOrder = 2, Parent = InfoPanel,
        })
        local InfoGameId = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
            Text = "", TextColor3 = T.TextDim, Font = T.Font, TextSize = 10,
            ZIndex = 102, LayoutOrder = 3, Parent = InfoPanel,
        })
        -- Divider
        New("Frame", {
                Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border,
            BorderSizePixel = 0, ZIndex = 102, LayoutOrder = 4, Parent = InfoPanel,
        })
        -- Player info title
        New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
            Text = "player info", TextColor3 = T.Accent, Font = T.Font, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102, LayoutOrder = 5, Parent = InfoPanel,
        })
        -- Player row (PFP + text)
        local PlayerRow = New("Frame", {
                Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1,
            ZIndex = 102, LayoutOrder = 6, Parent = InfoPanel,
        })
        local InfoPFP = New("ImageLabel", {
                Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
            ZIndex = 103, Parent = PlayerRow,
}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        -- Load player headshot
        pcall(function()
            if LP then
                InfoPFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
            end
        end)
        local InfoPlayerName = New("TextLabel", {
                Size = UDim2.new(1, -56, 0, 14), Position = UDim2.new(0, 56, 0, 4),
            BackgroundTransparency = 1, Text = LP and LP.DisplayName or "Player",
            TextColor3 = T.Text, Font = T.Font, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 103, Parent = PlayerRow,
        })
        New("TextLabel", {
                Size = UDim2.new(1, -56, 0, 11), Position = UDim2.new(0, 56, 0, 20),
            BackgroundTransparency = 1, Text = LP and ("@" .. LP.Name) or "",
            TextColor3 = T.TextDim, Font = T.Font, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 103, Parent = PlayerRow,
        })
        New("TextLabel", {
                Size = UDim2.new(1, -56, 0, 11), Position = UDim2.new(0, 56, 0, 33),
            BackgroundTransparency = 1, Text = LP and ("ID: " .. tostring(LP.UserId)) or "",
            TextColor3 = T.TextMuted, Font = T.Font, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 103, Parent = PlayerRow,
        })
        -- Function to update info panel for a game
        local function UpdateInfoPanel(gName, gPlaceId)
            InfoGameName.Text = gName or "Universal"
            InfoGameId.Text = gPlaceId and ("Place ID: " .. tostring(gPlaceId)) or "any game"
            if gPlaceId then
                pcall(function()
                    InfoGameIcon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(gPlaceId) .. "&w=150&h=150"
                end)
            else
                InfoGameIcon.Image = ""
            end
            -- Show + animate info panel
            if not InfoPanel.Visible then
                InfoPanel.Visible = true
                InfoPanel.BackgroundTransparency = 1
                local infoStroke = InfoPanel:FindFirstChildOfClass("UIStroke")
                if infoStroke then infoStroke.Transparency = 1 end
                Tween(InfoPanel, {BackgroundTransparency = 0}, .25)
                if infoStroke then Tween(infoStroke, {Transparency = 0}, .25) end
            end
        end
        local function HighlightCard(card)
            for _, c in ipairs(cardButtons) do
                local isSelected = (c == card)
                c.BackgroundColor3 = isSelected and Color3.fromHex("1A1A1A") or T.Surface1
                local stroke = c:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = isSelected and T.Accent or T.Border end
            end
        end
        -- Build game cards
        local ord = 0
        local foundCurrent = false
        for gameName, placeId in pairs(gameList) do
            ord = ord + 1
            maxCards = maxCards + 1
            local isCurrent = (placeId == currentPlaceId)
            if isCurrent then foundCurrent = true end
            local Card = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = isCurrent and Color3.fromHex("1A1A1A") or T.Surface1,
                BorderSizePixel = 0, Text = "", ZIndex = 103, LayoutOrder = ord, Parent = GameScroll,
            }, {
                    New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", { Color = isCurrent and T.Accent or T.Border, Thickness = 1 }),
            })
            table.insert(cardButtons, Card)
            -- Thumbnail
            local Thumb = New("ImageLabel", {
                    Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 7, 0.5, -18),
                BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
                ZIndex = 104, Parent = Card,
            }, { New("UICorner", { CornerRadius = UDim.new(0, 4) }) })
            -- Try to load game icon
            pcall(function()
                local MPS = game:GetService("MarketplaceService")
                task.spawn(function()
                    pcall(function()
                        local info = MPS:GetProductInfo(placeId)
                        if info then
                            -- Use rbxassetid for game icon
                            pcall(function()
Thumb.Image = "rbxthumb://type=GameIcon&id=" .. tostring(placeId) .. "&w=150&h=150"
                            end)
                        end
                    end)
                end)
            end)
            -- Game name
            New("TextLabel", {
                    Size = UDim2.new(1, -56, 0, 16), Position = UDim2.new(0, 50, 0, 7),
                BackgroundTransparency = 1, Text = gameName, TextColor3 = T.Text,
                Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 104, Parent = Card,
            })
            -- Place ID + status
            local statusText = isCurrent and ("ID: "..tostring(placeId).."  •  current game") or ("ID: "..tostring(placeId))
            local statusClr = isCurrent and T.Green or T.TextDim
            New("TextLabel", {
                    Size = UDim2.new(1, -56, 0, 12), Position = UDim2.new(0, 50, 0, 26),
                BackgroundTransparency = 1, Text = statusText, TextColor3 = statusClr,
                Font = T.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 104, Parent = Card,
            })
            -- Auto-select current game
            if isCurrent then
                selectedGame = gameName
                selectedCard = Card
            end
            Card.MouseEnter:Connect(function()
                if Card ~= selectedCard then Tween(Card, {BackgroundColor3 = T.Surface2}, .1) end
            end)
            Card.MouseLeave:Connect(function()
                if Card ~= selectedCard then Tween(Card, {BackgroundColor3 = T.Surface1}, .1) end
            end)
            Card.MouseButton1Click:Connect(function()
                selectedGame = gameName
                selectedCard = Card
                HighlightCard(Card)
                UpdateInfoPanel(gameName, placeId)
            end)
        end
        -- Universal card (always last)
        ord = ord + 1
        maxCards = maxCards + 1
        local UniCard = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = (not foundCurrent) and Color3.fromHex("1A1A1A") or T.Surface1,
            BorderSizePixel = 0, Text = "", ZIndex = 103, LayoutOrder = 999, Parent = GameScroll,
        }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            New("UIStroke", { Color = (not foundCurrent) and T.Accent or T.Border, Thickness = 1 }),
        })
        table.insert(cardButtons, UniCard)
        New("TextLabel", {
                Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 13, 0.5, -8),
            BackgroundTransparency = 1, Text = "🌐", Font = T.Font, TextSize = 14,
            ZIndex = 104, Parent = UniCard,
        })
        New("TextLabel", {
                Size = UDim2.new(1, -44, 0, 14), Position = UDim2.new(0, 40, 0, 6),
            BackgroundTransparency = 1, Text = "Universal", TextColor3 = T.Text,
            Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 104, Parent = UniCard,
        })
        New("TextLabel", {
                Size = UDim2.new(1, -44, 0, 10), Position = UDim2.new(0, 40, 0, 22),
            BackgroundTransparency = 1, Text = "works on any game",
            TextColor3 = T.TextDim, Font = T.Font, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 104, Parent = UniCard,
        })
        if not foundCurrent then
            selectedGame = "Universal"
            selectedCard = UniCard
        end
        UniCard.MouseEnter:Connect(function()
            if UniCard ~= selectedCard then Tween(UniCard, {BackgroundColor3 = T.Surface2}, .1) end
        end)
        UniCard.MouseLeave:Connect(function()
            if UniCard ~= selectedCard then Tween(UniCard, {BackgroundColor3 = T.Surface1}, .1) end
        end)
        UniCard.MouseButton1Click:Connect(function()
            selectedGame = "Universal"
            selectedCard = UniCard
            HighlightCard(UniCard)
            UpdateInfoPanel("Universal", nil)
        end)
        -- Clamp scroll height to max ~200
        local scrollH = math.min(maxCards * 54, 220)
        GameScroll.Size = UDim2.new(1, 0, 0, scrollH)
        GameScroll.AutomaticSize = Enum.AutomaticSize.None
        -- Load button
        local LoadBtn = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Accent,
BorderSizePixel = 0, Text = "Load Script", TextColor3 = T.Text,
            Font = T.Font, TextSize = 13, ZIndex = 102, LayoutOrder = 4, Parent = Loader,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 4) }) })
        LoadBtn.MouseEnter:Connect(function() Tween(LoadBtn, {BackgroundColor3 = Color3.fromHex("FF3580")}, .1) end)
        LoadBtn.MouseLeave:Connect(function() Tween(LoadBtn, {BackgroundColor3 = T.Accent}, .1) end)
        -- Version info
        New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1,
            Text = "PeronaLib • v1.0", TextColor3 = T.TextMuted, Font = T.Font, TextSize = 9,
            ZIndex = 102, LayoutOrder = 5, Parent = Loader,
        })
        -- ── Blur effect ──
        local loaderBlur = Instance.new("BlurEffect")
        loaderBlur.Size = 0
        loaderBlur.Name = "PeronaLoaderBlur"
        loaderBlur.Parent = game:GetService("Lighting")
        -- ── Loading spinner (3 pulsing dots) ──
        local SpinWrap = New("Frame", {
                Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
            ZIndex = 102, LayoutOrder = 6, Parent = Loader,
        })
        local dots = {}
        for di = 1, 3 do
            local dot = New("Frame", {
                    Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(0.5, (di - 2) * 16 - 3, 0.5, -3),
                BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                ZIndex = 103, Parent = SpinWrap,
            }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            dots[di] = dot
        end
        -- Animate dots pulsing
        local spinConn
        spinConn = RS.Heartbeat:Connect(function()
            for di, dot in ipairs(dots) do
                local t = tick() * 3 + (di - 1) * 1.2
                local scale = 0.6 + 0.4 * math.abs(math.sin(t))
                dot.Size = UDim2.new(0, 6 * scale, 0, 6 * scale)
                dot.BackgroundTransparency = 0.3 - 0.3 * math.abs(math.sin(t))
            end
        end)
        -- ── Animate loader IN with blur ──
        LoaderBg.BackgroundTransparency = 1
        Loader.BackgroundTransparency = 1
        local loaderStroke = Loader:FindFirstChildOfClass("UIStroke")
        if loaderStroke then loaderStroke.Transparency = 1 end
        Tween(loaderBlur, {Size = 24}, .6, Enum.EasingStyle.Quint)
        task.delay(0.1, function()
            Tween(Loader, {BackgroundTransparency = 0}, .35)
            if loaderStroke then Tween(loaderStroke, {Transparency = 0}, .35) end
        end)
        -- Auto-show info panel if a game is pre-selected
        if selectedGame and selectedGame ~= "Universal" then
            for gn, gid in pairs(gameList) do
                if gn == selectedGame then
                    task.delay(0.3, function() UpdateInfoPanel(gn, gid) end)
                    break
                end
            end
        end
        -- ── Load button handler ──
        LoadBtn.MouseButton1Click:Connect(function()
            if not selectedGame then return end
            Win._selectedGame = selectedGame
            -- Stop spinner
            pcall(function() spinConn:Disconnect() end)
            -- Animate loader + info panel OUT + remove blur
            Tween(Loader, {BackgroundTransparency = 1}, .25)
            if loaderStroke then Tween(loaderStroke, {Transparency = 1}, .25) end
            if InfoPanel.Visible then
                Tween(InfoPanel, {BackgroundTransparency = 1}, .25)
                local ipStroke = InfoPanel:FindFirstChildOfClass("UIStroke")
                if ipStroke then Tween(ipStroke, {Transparency = 1}, .25) end
            end
            Tween(loaderBlur, {Size = 0}, .4, Enum.EasingStyle.Quint)
            task.delay(0.15, function()
                Tween(LoaderBg, {BackgroundTransparency = 1}, .3)
            end)
            task.delay(0.45, function()
                pcall(function() loaderBlur:Destroy() end)
                pcall(function() LoaderBg:Destroy() end)
                -- Show main UI with fade
                Main.Visible = true
                Main.BackgroundTransparency = 1
                Tween(Main, {BackgroundTransparency = 0}, .3)
                -- Restore HUD/KB visibility based on flags
                HUD.Visible = Flags["__hud_wm"] ~= false
                KBOverlay.Visible = Flags["__kb_list"] ~= false
            end)
        end)
    end
--- Get which game the user selected in the loader
    function Win:GetSelectedGame()
        return Win._selectedGame
    end
    table.insert(PeronaLib.Windows, Win)
    return Win
end
return PeronaLib
