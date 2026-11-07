-- bunlib.lua — single-file UI library, loadstring-ready.
--
-- Executor:
--   local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()
--   local Window = BunLib:CreateWindow({ Title = "My Menu" })
--   local Tab = Window:CreateTab("Main")
--   Tab:CreateToggle({ Name = "Example", Callback = function(v) end })
--
-- Studio/baseplate test: paste this file into a ModuleScript (e.g.
-- ReplicatedStorage.BunLib), then: local BunLib = require(game.ReplicatedStorage.BunLib)

local BunLib = {}
BunLib.Version = "2.0.0"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============ THEME ============
local THEME = {
    Frame = Color3.fromRGB(30, 30, 30),
    Title = Color3.fromRGB(45, 45, 45),
    TabBar = Color3.fromRGB(38, 38, 38),
    TabActive = Color3.fromRGB(62, 62, 62),
    Row = Color3.fromRGB(50, 50, 50),
    RowBorder = Color3.fromRGB(80, 80, 80),
    Box = Color3.fromRGB(80, 80, 80),
    BoxBorder = Color3.fromRGB(130, 130, 130),
    Accent = Color3.fromRGB(0, 200, 100),
    Text = Color3.fromRGB(220, 220, 220),
    TitleText = Color3.fromRGB(230, 230, 230),
    SectionText = Color3.fromRGB(160, 160, 160),
    Popup = Color3.fromRGB(40, 40, 40),
}

local NOTIFY_COLORS = {
    Info = Color3.fromRGB(80, 160, 255),
    Success = Color3.fromRGB(0, 200, 100),
    Warning = Color3.fromRGB(240, 200, 60),
    Error = Color3.fromRGB(240, 80, 80),
}

local DEFAULTS = {
    Title = "BunLib",
    ToggleKey = Enum.KeyCode.RightShift,
    Position = UDim2.new(0, 40, 0, 40),
    Width = 320,
    Height = 380,
    MinWidth = 240,
    MinHeight = 160,
    Padding = 6,
    TitleHeight = 28,
    TabHeight = 26,
    RowHeight = 26,
    StartVisible = true,
}

-- default notification corner; override per call with Notify({ Position = ... })
BunLib.NotifyPosition = "BottomRight"

local TabMethods = {}

-- ============ HELPERS ============
-- Prefer gethui()/CoreGui: safer in executors, since games can tamper with
-- PlayerGui. PlayerGui is only a last-resort fallback (e.g. Studio baseplate).
local function getGuiParent()
    if gethui then
        return gethui()
    end
    local coreGui = game:GetService("CoreGui")
    if coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = parent
    return c
end

local function makeLabel(parent, text, size, color, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or THEME.Text
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = size or 12
    l.Parent = parent
    return l
end

-- ============ NOTIFICATIONS ============
local notifyGui

local NOTIFY_POSITIONS = {
    TopLeft      = { anchor = Vector2.new(0, 0),   pos = UDim2.new(0, 10, 0, 10),   h = Enum.HorizontalAlignment.Left,   v = Enum.VerticalAlignment.Top },
    TopRight     = { anchor = Vector2.new(1, 0),   pos = UDim2.new(1, -10, 0, 10),  h = Enum.HorizontalAlignment.Right,  v = Enum.VerticalAlignment.Top },
    BottomLeft   = { anchor = Vector2.new(0, 1),   pos = UDim2.new(0, 10, 1, -10),  h = Enum.HorizontalAlignment.Left,   v = Enum.VerticalAlignment.Bottom },
    BottomRight  = { anchor = Vector2.new(1, 1),   pos = UDim2.new(1, -10, 1, -10), h = Enum.HorizontalAlignment.Right,  v = Enum.VerticalAlignment.Bottom },
    TopCenter    = { anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 0, 10),  h = Enum.HorizontalAlignment.Center, v = Enum.VerticalAlignment.Top },
    BottomCenter = { anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, -10), h = Enum.HorizontalAlignment.Center, v = Enum.VerticalAlignment.Bottom },
}

local function getNotifyGui()
    if notifyGui and notifyGui.Parent then
        return notifyGui
    end
    notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "BunLib.Notifications"
    notifyGui.ResetOnSpawn = false
    notifyGui.IgnoreGuiInset = true
    notifyGui.DisplayOrder = 1000
    notifyGui.Parent = getGuiParent()
    return notifyGui
end

-- BunLib:Notify({ Title, Content, Duration, Type = "Info"|"Success"|"Warning"|"Error",
--                 Position = "TopLeft"|"TopRight"|"BottomLeft"|"BottomRight"|"TopCenter"|"BottomCenter" })
function BunLib:Notify(opts)
    opts = opts or {}
    local posName = opts.Position or BunLib.NotifyPosition or "BottomRight"
    local p = NOTIFY_POSITIONS[posName] or NOTIFY_POSITIONS.BottomRight

    local gui = getNotifyGui()
    local container = gui:FindFirstChild("Pos_" .. posName)
    if not container then
        container = Instance.new("Frame")
        container.Name = "Pos_" .. posName
        container.AnchorPoint = p.anchor
        container.Position = p.pos
        container.Size = UDim2.fromOffset(280, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = p.h
        layout.VerticalAlignment = p.v
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
    end

    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 54)
    n.BackgroundColor3 = THEME.Popup
    n.BorderSizePixel = 1
    n.BorderColor3 = THEME.RowBorder
    corner(n, 4)
    n.Parent = container

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = NOTIFY_COLORS[opts.Type] or NOTIFY_COLORS.Info
    accent.BorderSizePixel = 0
    accent.Parent = n

    local title = makeLabel(n, opts.Title or "Notification", 13, THEME.TitleText)
    title.Size = UDim2.new(1, -16, 0, 16)
    title.Position = UDim2.fromOffset(10, 5)

    local content = makeLabel(n, opts.Content or "", 12, THEME.Text)
    content.Size = UDim2.new(1, -16, 1, -24)
    content.Position = UDim2.fromOffset(10, 22)
    content.TextWrapped = true

    task.delay(opts.Duration or 5, function()
        if not n.Parent then return end
        local tweens = { TweenService:Create(n, TweenInfo.new(0.3), { BackgroundTransparency = 1 }) }
        for _, inst in ipairs(n:GetDescendants()) do
            if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                table.insert(tweens, TweenService:Create(inst, TweenInfo.new(0.3), { TextTransparency = 1 }))
            elseif inst:IsA("GuiObject") then
                table.insert(tweens, TweenService:Create(inst, TweenInfo.new(0.3), { BackgroundTransparency = 1 }))
            end
        end
        for _, tw in ipairs(tweens) do tw:Play() end
        task.wait(0.35)
        n:Destroy()
    end)

    return n
end

-- ============ WINDOW ============
function BunLib:CreateWindow(config)
    config = config or {}
    local cfg = {}
    for k, v in pairs(DEFAULTS) do cfg[k] = v end
    for k, v in pairs(config) do cfg[k] = v end
    if config.Theme then
        for k, v in pairs(config.Theme) do THEME[k] = v end
    end

    local Window = {}
    local gui, frame, titleBar, tabBar, content
    local tabs = {}
    local activeTabName = nil
    local toggleCallbacks = {}
    local conns = {}

    local function track(c)
        conns[#conns + 1] = c
        return c
    end

    -- show/hide with OnToggle callbacks. Debounced so the key event and the
    -- key-state poll below can't both fire for a single press.
    local lastToggle = -math.huge
    local function toggle()
        local now = tick()
        if now - lastToggle < 0.15 then return end
        lastToggle = now
        gui.Enabled = not gui.Enabled
        for _, cb in ipairs(toggleCallbacks) do cb(gui.Enabled) end
    end

    local function build()
        gui = Instance.new("ScreenGui")
        gui.Name = "BunLib"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999
        gui.Enabled = cfg.StartVisible ~= false
        gui.Parent = getGuiParent()

        frame = Instance.new("Frame")
        frame.Name = "Window"
        frame.Position = cfg.Position
        frame.Size = UDim2.fromOffset(cfg.Width, cfg.Height)
        frame.BackgroundColor3 = THEME.Frame
        frame.BorderSizePixel = 1
        frame.BorderColor3 = THEME.RowBorder
        frame.Active = true
        corner(frame, 6)
        frame.Parent = gui

        -- title bar (drag handle + toggle button)
        titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, cfg.TitleHeight)
        titleBar.BackgroundColor3 = THEME.Title
        titleBar.BorderSizePixel = 0
        titleBar.Active = true
        titleBar.Parent = frame

        local title = makeLabel(titleBar, "  " .. cfg.Title, 13, THEME.TitleText)
        title.Size = UDim2.new(1, -24, 1, 0)

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleButton"
        toggleBtn.Size = UDim2.fromOffset(24, cfg.TitleHeight)
        toggleBtn.Position = UDim2.new(1, -24, 0, 0)
        toggleBtn.BackgroundColor3 = THEME.Title
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        toggleBtn.Text = "_"
        toggleBtn.TextColor3 = THEME.TitleText
        toggleBtn.Font = Enum.Font.Code
        toggleBtn.TextSize = 14
        toggleBtn.Parent = frame
        toggleBtn.MouseButton1Click:Connect(toggle)

        -- tab bar
        tabBar = Instance.new("Frame")
        tabBar.Name = "TabBar"
        tabBar.Size = UDim2.new(1, 0, 0, cfg.TabHeight)
        tabBar.Position = UDim2.new(0, 0, 0, cfg.TitleHeight)
        tabBar.BackgroundColor3 = THEME.TabBar
        tabBar.BorderSizePixel = 0
        tabBar.Parent = frame

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        tabLayout.Padding = UDim.new(0, 4)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabBar

        local tabPad = Instance.new("UIPadding")
        tabPad.PaddingLeft = UDim.new(0, cfg.Padding)
        tabPad.PaddingRight = UDim.new(0, cfg.Padding)
        tabPad.PaddingTop = UDim.new(0, 3)
        tabPad.Parent = tabBar

        -- content area (holds one ScrollingFrame per tab)
        content = Instance.new("Frame")
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -(cfg.TitleHeight + cfg.TabHeight))
        content.Position = UDim2.new(0, 0, 0, cfg.TitleHeight + cfg.TabHeight)
        content.BackgroundTransparency = 1
        content.ClipsDescendants = true
        content.Parent = frame

        -- resize handle (bottom-right corner)
        local handle = Instance.new("Frame")
        handle.Name = "ResizeHandle"
        handle.Size = UDim2.fromOffset(14, 14)
        handle.Position = UDim2.new(1, -14, 1, -14)
        handle.BackgroundColor3 = THEME.Box
        handle.BorderSizePixel = 1
        handle.BorderColor3 = THEME.BoxBorder
        handle.Active = true
        handle.Parent = frame

        -- dragging the window by the title bar
        local dragging, dragStart, startPos = false, nil, nil
        track(titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        -- resizing via the corner handle
        local resizing, rStart, rSize = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                rStart = input.Position
                rSize = frame.Size
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - rStart
                local max = gui.AbsoluteSize - frame.AbsolutePosition
                local w = math.clamp(rSize.X.Offset + delta.X, cfg.MinWidth, math.max(cfg.MinWidth, max.X))
                local h = math.clamp(rSize.Y.Offset + delta.Y, cfg.MinHeight, math.max(cfg.MinHeight, max.Y))
                frame.Size = UDim2.fromOffset(w, h)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end))

        -- toggle key, path 1: input event (ignores gameProcessedEvent)
        track(UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == cfg.ToggleKey then
                toggle()
            end
        end))
        -- toggle key, path 2: per-frame key-state poll (works even if the
        -- executor/game swallows InputBegan entirely)
        local keyWasDown = false
        track(RunService.RenderStepped:Connect(function()
            local down = UserInputService:IsKeyDown(cfg.ToggleKey)
            if down and not keyWasDown then
                toggle()
            end
            keyWasDown = down
        end))
    end

    -- ---- tabs ----
    function Window:SelectTab(name)
        for _, t in ipairs(tabs) do
            local active = t.name == name
            t.scroll.Visible = active
            t.button.BackgroundColor3 = active and THEME.TabActive or THEME.Row
            t.button.TextColor3 = active and THEME.TitleText or THEME.Text
            if not active and t.popup then
                t.popup:Destroy()
                t.popup = nil
            end
        end
        activeTabName = name
    end

    function Window:GetActiveTab() return activeTabName end

    function Window:CreateTab(name)
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. tostring(name)
        btn.Size = UDim2.new(0, 92, 1, -6)
        btn.BackgroundColor3 = THEME.Row
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = tostring(name)
        btn.TextColor3 = THEME.Text
        btn.Font = Enum.Font.Code
        btn.TextSize = 12
        btn.Parent = tabBar

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Content_" .. tostring(name)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = THEME.BoxBorder
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.fromOffset(0, 0)
        scroll.Visible = false
        scroll.Parent = content

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, cfg.Padding)
        pad.PaddingBottom = UDim.new(0, cfg.Padding)
        pad.PaddingLeft = UDim.new(0, cfg.Padding)
        pad.PaddingRight = UDim.new(0, cfg.Padding)
        pad.Parent = scroll

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, cfg.Padding)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scroll

        local tab = { name = name, button = btn, scroll = scroll, order = 0, frame = frame, popup = nil, cfg = cfg }
        setmetatable(tab, { __index = TabMethods })
        function tab:nextOrder()
            self.order += 1
            return self.order
        end
        table.insert(tabs, tab)
        btn.MouseButton1Click:Connect(function() Window:SelectTab(name) end)
        if not activeTabName then Window:SelectTab(name) end
        return tab
    end

    -- ---- window-level API ----
    function Window:SetVisible(v)
        if gui then gui.Enabled = v and true or false end
    end

    function Window:IsVisible()
        return gui ~= nil and gui.Enabled
    end

    function Window:Toggle()
        if gui then
            gui.Enabled = not gui.Enabled
            for _, cb in ipairs(toggleCallbacks) do cb(gui.Enabled) end
        end
    end

    function Window:OnToggle(cb)
        table.insert(toggleCallbacks, cb)
    end

    function Window:Destroy()
        for _, c in ipairs(conns) do c:Disconnect() end
        if gui then gui:Destroy() end
    end

    build()
    return Window
end

-- ============ TAB ELEMENTS ============

function TabMethods:CreateSection(name)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = THEME.Accent
    bar.BorderSizePixel = 0
    bar.Parent = row

    local l = makeLabel(row, tostring(name), 12, THEME.SectionText)
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.fromOffset(9, 0)
    return row
end

function TabMethods:CreateToggle(opt)
    opt = opt or {}
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    row.AutoButtonColor = false
    row.Text = ""
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(16, 16)
    box.Position = UDim2.new(0, 6, 0.5, -8)
    box.BackgroundColor3 = THEME.Box
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.BoxBorder
    box.Parent = row

    local tick = Instance.new("Frame")
    tick.Size = UDim2.new(1, -4, 1, -4)
    tick.Position = UDim2.fromOffset(2, 2)
    tick.BackgroundColor3 = THEME.Accent
    tick.BorderSizePixel = 0
    tick.Parent = box

    local l = makeLabel(row, opt.Name or "Toggle", 13)
    l.Size = UDim2.new(1, -34, 1, 0)
    l.Position = UDim2.fromOffset(30, 0)

    local state = opt.CurrentValue and true or false
    tick.Visible = state

    local handle = {}
    function handle:Set(v)
        state = v and true or false
        tick.Visible = state
    end
    function handle:Get() return state end
    row.MouseButton1Click:Connect(function()
        state = not state
        tick.Visible = state
        if opt.Callback then opt.Callback(state) end
    end)
    return handle
end

function TabMethods:CreateLabel(text)
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 0
    row.Text = "  " .. tostring(text or "")
    row.TextColor3 = THEME.Text
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Font = Enum.Font.Code
    row.TextSize = 12
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local handle = {}
    function handle:SetText(t) row.Text = "  " .. tostring(t) end
    function handle:GetText() return row.Text end
    return handle
end

function TabMethods:CreateButton(opt)
    opt = opt or {}
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    row.AutoButtonColor = false
    row.Text = tostring(opt.Name or "Button")
    row.TextColor3 = THEME.Text
    row.Font = Enum.Font.Code
    row.TextSize = 12
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local handle = {}
    function handle:Fire()
        if opt.Callback then opt.Callback() end
    end
    function handle:SetText(t) row.Text = tostring(t) end
    row.MouseButton1Click:Connect(function()
        if opt.Callback then opt.Callback() end
    end)
    return handle
end

-- ============ SLIDER ============
local SLIDER_HEIGHT = 38 -- taller row: label on top, gap, bar at the bottom

local function decimalsOf(n)
    local d = 0
    local x = math.abs(n)
    while x > 0 and x < 1 and d < 12 do
        x *= 10
        d += 1
    end
    return d
end

-- Builds a slider row inside any container.
-- opt: { Name, Min, Max, Increment, CurrentValue, Callback }
-- Increment > 0 snaps values to clean steps (0.1 -> 0.1, 0.2, 0.3... never 0.30000000000000004).
local function makeSliderRow(parent, layoutOrder, opt)
    local minV = opt.Min or 0
    local maxV = opt.Max or 100
    if maxV < minV then minV, maxV = maxV, minV end
    local inc = opt.Increment or opt.Step or 0
    local dec = decimalsOf(inc > 0 and inc or (maxV - minV))
    local pow = 10 ^ dec

    local function clean(v)
        v = math.clamp(v, minV, maxV)
        if inc > 0 then
            v = minV + math.floor((v - minV) / inc + 0.5) * inc
        end
        v = math.floor(v * pow + 0.5) / pow -- kill float noise
        return math.clamp(v, minV, maxV)
    end

    local value = clean(opt.CurrentValue or minV)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, SLIDER_HEIGHT)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    if layoutOrder then row.LayoutOrder = layoutOrder end
    row.Parent = parent

    local nameL = makeLabel(row, opt.Name or "Slider", 12)
    nameL.Size = UDim2.new(1, -70, 0, 13)
    nameL.Position = UDim2.fromOffset(6, 4)

    local valL = makeLabel(row, tostring(value), 12, THEME.TitleText, Enum.TextXAlignment.Right)
    valL.Size = UDim2.fromOffset(62, 13)
    valL.Position = UDim2.new(1, -68, 0, 4)

    -- bar at the bottom; the label sits above with a clear gap
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -12, 0, 6)
    bar.Position = UDim2.new(0, 6, 1, -9)
    bar.BackgroundColor3 = THEME.Box
    bar.BorderSizePixel = 0
    bar.Parent = row

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local function render()
        local disp = (maxV - minV) > 0 and (value - minV) / (maxV - minV) or 0
        fill.Size = UDim2.fromScale(disp, 1)
        valL.Text = tostring(value)
    end

    local function setValue(v, fire)
        value = clean(v)
        render()
        if fire and opt.Callback then opt.Callback(value) end
    end

    local dragging = false
    local function fromInput(input)
        local rel = (input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
        setValue(minV + (maxV - minV) * math.clamp(rel, 0, 1), true)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    render()

    local handle = {}
    function handle:Set(v) setValue(v, false) end
    function handle:Get() return value end
    return handle
end

function TabMethods:CreateSlider(opt)
    opt = opt or {}
    return makeSliderRow(self.scroll, self:nextOrder(), opt)
end

-- ============ DROPDOWN ============
function TabMethods:CreateDropdown(opt)
    opt = opt or {}
    local options = opt.Options or {}
    local current = opt.CurrentOption or options[1]
    local prefix = tostring(opt.Name or "Dropdown") .. ": "

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    row.AutoButtonColor = false
    row.Text = prefix .. tostring(current)
    row.TextColor3 = THEME.Text
    row.Font = Enum.Font.Code
    row.TextSize = 12
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local tab = self
    local function closePopup()
        if tab.popup then
            tab.popup:Destroy()
            tab.popup = nil
        end
    end
    tab.scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)

    local function openPopup()
        closePopup()
        local popup = Instance.new("ScrollingFrame")
        popup.Name = "DropdownPopup"
        popup.Size = UDim2.fromOffset(row.AbsoluteSize.X, math.min(160, #options * 24 + 6))
        popup.Position = UDim2.fromOffset(
            row.AbsolutePosition.X - tab.frame.AbsolutePosition.X,
            row.AbsolutePosition.Y - tab.frame.AbsolutePosition.Y + row.AbsoluteSize.Y
        )
        popup.BackgroundColor3 = THEME.Popup
        popup.BorderSizePixel = 1
        popup.BorderColor3 = THEME.BoxBorder
        popup.ScrollBarThickness = 3
        popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
        popup.CanvasSize = UDim2.fromOffset(0, 0)
        popup.ZIndex = 10
        corner(popup, 4)
        popup.Parent = tab.frame

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = popup

        for i, o in ipairs(options) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 24)
            b.BackgroundColor3 = THEME.Row
            b.BorderSizePixel = 0
            b.AutoButtonColor = false
            b.Text = "  " .. tostring(o)
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.Code
            b.TextSize = 12
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.LayoutOrder = i
            b.ZIndex = 11
            b.Parent = popup
            b.MouseButton1Click:Connect(function()
                current = o
                row.Text = prefix .. tostring(current)
                closePopup()
                if opt.Callback then opt.Callback(current) end
            end)
        end
        tab.popup = popup
    end

    row.MouseButton1Click:Connect(function()
        if tab.popup then closePopup() else openPopup() end
    end)

    local handle = {}
    function handle:Set(o)
        current = o
        row.Text = prefix .. tostring(o)
    end
    function handle:Get() return current end
    function handle:GetOptions() return options end
    return handle
end

-- ============ TEXTBOX ============
function TabMethods:CreateTextBox(opt)
    opt = opt or {}
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local nameL = makeLabel(row, tostring(opt.Name or "Input") .. ":", 12)
    nameL.Size = UDim2.new(0, 92, 1, 0)
    nameL.Position = UDim2.fromOffset(6, 0)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -104, 1, -8)
    box.Position = UDim2.fromOffset(98, 4)
    box.BackgroundColor3 = THEME.Box
    box.BorderSizePixel = 1
    box.BorderColor3 = THEME.BoxBorder
    box.Text = tostring(opt.CurrentText or "")
    box.PlaceholderText = tostring(opt.Placeholder or "")
    box.TextColor3 = THEME.Text
    box.PlaceholderColor3 = THEME.SectionText
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = row

    box.FocusLost:Connect(function()
        if opt.Callback then opt.Callback(box.Text) end
    end)

    local handle = {}
    function handle:Set(t) box.Text = tostring(t) end
    function handle:Get() return box.Text end
    return handle
end

-- ============ COLOR PICKER ============
function TabMethods:CreateColorPicker(opt)
    opt = opt or {}
    local color = opt.CurrentColor or Color3.fromRGB(255, 60, 60)

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, self.cfg.RowHeight)
    row.BackgroundColor3 = THEME.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = THEME.RowBorder
    row.AutoButtonColor = false
    row.Text = ""
    row.LayoutOrder = self:nextOrder()
    row.Parent = self.scroll

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.fromOffset(16, 16)
    swatch.Position = UDim2.new(0, 6, 0.5, -8)
    swatch.BackgroundColor3 = color
    swatch.BorderSizePixel = 1
    swatch.BorderColor3 = THEME.BoxBorder
    swatch.Parent = row

    local l = makeLabel(row, opt.Name or "Color", 13)
    l.Size = UDim2.new(1, -34, 1, 0)
    l.Position = UDim2.fromOffset(30, 0)

    local tab = self
    local preview
    local function closePopup()
        if tab.popup then
            tab.popup:Destroy()
            tab.popup = nil
        end
    end
    tab.scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)

    local function fire()
        swatch.BackgroundColor3 = color
        if preview then preview.BackgroundColor3 = color end
        if opt.Callback then opt.Callback(color) end
    end

    local function openPopup()
        closePopup()
        local popup = Instance.new("Frame")
        popup.Name = "ColorPickerPopup"
        popup.Size = UDim2.fromOffset(row.AbsoluteSize.X, 0)
        popup.Position = UDim2.fromOffset(
            row.AbsolutePosition.X - tab.frame.AbsolutePosition.X,
            row.AbsolutePosition.Y - tab.frame.AbsolutePosition.Y + row.AbsoluteSize.Y
        )
        popup.BackgroundColor3 = THEME.Popup
        popup.BorderSizePixel = 1
        popup.BorderColor3 = THEME.BoxBorder
        popup.AutomaticSize = Enum.AutomaticSize.Y
        popup.ZIndex = 10
        corner(popup, 4)
        popup.Parent = tab.frame

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = popup

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = popup

        preview = Instance.new("Frame")
        preview.Size = UDim2.new(1, 0, 0, 22)
        preview.BackgroundColor3 = color
        preview.BorderSizePixel = 0
        preview.LayoutOrder = 0
        preview.ZIndex = 11
        preview.Parent = popup

        local order = 1
        local function channel(name, initial, setFn)
            makeSliderRow(popup, order, {
                Name = name,
                Min = 0,
                Max = 255,
                Increment = 1,
                CurrentValue = initial,
                Callback = function(v)
                    color = setFn(v)
                    fire()
                end,
            })
            order += 1
        end
        channel("R", math.floor(color.R * 255 + 0.5), function(v)
            return Color3.fromRGB(v, math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
        end)
        channel("G", math.floor(color.G * 255 + 0.5), function(v)
            return Color3.fromRGB(math.floor(color.R * 255 + 0.5), v, math.floor(color.B * 255 + 0.5))
        end)
        channel("B", math.floor(color.B * 255 + 0.5), function(v)
            return Color3.fromRGB(math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), v)
        end)

        tab.popup = popup
    end

    row.MouseButton1Click:Connect(function()
        if tab.popup then closePopup() else openPopup() end
    end)

    local handle = {}
    function handle:SetColor(c)
        color = c
        swatch.BackgroundColor3 = c
    end
    function handle:GetColor() return color end
    return handle
end

return BunLib
