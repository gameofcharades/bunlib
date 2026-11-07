-- bunlib.lua — single-file UI library, loadstring-ready.
--
-- Executor usage:
--   local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()
--   BunLib:Init({ Title = "My Menu" })
--   BunLib:AddCheckbox("Example", false, function(on) end)
--
-- Studio/baseplate test usage (paste this file into a ModuleScript, e.g.
-- ReplicatedStorage.BunLib, then require it from a LocalScript):
--   local BunLib = require(game:GetService("ReplicatedStorage"):WaitForChild("BunLib"))
--   BunLib:Init({ Title = "My Menu" })

local BunLib = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local CONFIG = {
    Title = "BunLib",
    ToggleKey = Enum.KeyCode.RightShift,
    Position = UDim2.new(0, 40, 0, 40),
    Width = 240,
    RowHeight = 26,
    Padding = 6,
    TitleHeight = 28,
    StartVisible = true, -- open by default; pass StartVisible = false to Init to start hidden
}

local COLORS = {
    Frame = Color3.fromRGB(30, 30, 30),
    Title = Color3.fromRGB(45, 45, 45),
    Row = Color3.fromRGB(50, 50, 50),
    RowBorder = Color3.fromRGB(80, 80, 80),
    Box = Color3.fromRGB(80, 80, 80),
    BoxBorder = Color3.fromRGB(130, 130, 130),
    Tick = Color3.fromRGB(0, 200, 100),
    Text = Color3.fromRGB(220, 220, 220),
    TitleText = Color3.fromRGB(230, 230, 230),
}

-- ============ INTERNALS ============
local gui, frame, list, layout
local rows = {}       -- ordered list of row frames for sizing
local rowCount = 0
local dragging, dragStart, startPos = false, nil, nil
local toggleCallbacks = {}

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

local function updateHeight()
    local contentHeight = rowCount * CONFIG.RowHeight
        + math.max(0, rowCount - 1) * CONFIG.Padding
    frame.Size = UDim2.fromOffset(
        CONFIG.Width,
        CONFIG.TitleHeight + CONFIG.Padding * 2 + contentHeight
    )
end

local function buildUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "BunLib"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Enabled = CONFIG.StartVisible ~= false
    gui.Parent = getGuiParent()

    frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Position = CONFIG.Position
    frame.BackgroundColor3 = COLORS.Frame
    frame.BorderSizePixel = 1
    frame.BorderColor3 = COLORS.RowBorder
    frame.Active = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -24, 0, CONFIG.TitleHeight)
    title.BackgroundColor3 = COLORS.Title
    title.BorderSizePixel = 0
    title.Text = "  " .. CONFIG.Title .. " (" .. CONFIG.ToggleKey.Name .. ")"
    title.TextColor3 = COLORS.TitleText
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.Code
    title.TextSize = 13
    title.Parent = frame

    -- clickable toggle button on the title bar (mouse fallback for the key)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.fromOffset(24, CONFIG.TitleHeight)
    toggleBtn.Position = UDim2.new(1, -24, 0, 0)
    toggleBtn.BackgroundColor3 = COLORS.Title
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "_"
    toggleBtn.TextColor3 = COLORS.TitleText
    toggleBtn.Font = Enum.Font.Code
    toggleBtn.TextSize = 14
    toggleBtn.Parent = frame

    list = Instance.new("Frame")
    list.Name = "List"
    list.Size = UDim2.new(1, -CONFIG.Padding * 2, 1, -(CONFIG.TitleHeight + CONFIG.Padding * 2))
    list.Position = UDim2.new(0, CONFIG.Padding, 0, CONFIG.TitleHeight + CONFIG.Padding)
    list.BackgroundTransparency = 1
    list.Parent = frame

    layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, CONFIG.Padding)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    -- dragging
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

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
    toggleBtn.MouseButton1Click:Connect(toggle)

    -- toggle key, path 1: input event (ignore gameProcessedEvent: games often
    -- mark the key as processed, which would swallow the toggle)
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == CONFIG.ToggleKey then
            toggle()
        end
    end)

    -- toggle key, path 2: poll key state every frame (works even if the
    -- executor/game swallows InputBegan entirely)
    local keyWasDown = false
    RunService.RenderStepped:Connect(function()
        local down = UserInputService:IsKeyDown(CONFIG.ToggleKey)
        if down and not keyWasDown then
            toggle()
        end
        keyWasDown = down
    end)

    updateHeight()
end

local function nextOrder()
    rowCount += 1
    return rowCount
end

-- ============ PUBLIC API ============

function BunLib:Init(config)
    if config then
        for k, v in pairs(config) do CONFIG[k] = v end
    end
    buildUI()
end

-- Checkbox row. onChange(newValue) fires on every click.
-- Returns a handle: { SetChecked(bool), IsChecked() }
function BunLib:AddCheckbox(label, initial, onChange)
    local order = nextOrder()
    local checked = initial and true or false

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, CONFIG.RowHeight)
    row.BackgroundColor3 = COLORS.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = COLORS.RowBorder
    row.AutoButtonColor = false
    row.Text = ""
    row.LayoutOrder = order
    row.Parent = list

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(16, 16)
    box.Position = UDim2.new(0, 6, 0.5, -8)
    box.BackgroundColor3 = COLORS.Box
    box.BorderSizePixel = 1
    box.BorderColor3 = COLORS.BoxBorder
    box.Parent = row

    local tick = Instance.new("Frame")
    tick.Size = UDim2.new(1, -4, 1, -4)
    tick.Position = UDim2.fromOffset(2, 2)
    tick.BackgroundColor3 = COLORS.Tick
    tick.BorderSizePixel = 0
    tick.Visible = checked
    tick.Parent = box

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -34, 1, 0)
    text.Position = UDim2.fromOffset(30, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = COLORS.Text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Font = Enum.Font.Code
    text.TextSize = 13
    text.Parent = row

    local handle = {}
    function handle:SetChecked(value)
        checked = value and true or false
        tick.Visible = checked
    end
    function handle:IsChecked() return checked end

    row.MouseButton1Click:Connect(function()
        checked = not checked
        tick.Visible = checked
        if onChange then onChange(checked) end
    end)

    updateHeight()
    return handle
end

-- Slider row (0-1 by default, or custom min/max/step).
-- onChange(value) fires while dragging and on release.
-- Returns { SetValue(v), GetValue() }
function BunLib:AddSlider(label, minValue, maxValue, step, initial, onChange)
    local order = nextOrder()
    minValue = minValue or 0
    maxValue = maxValue or 1
    step = step or 0
    local value = initial or minValue
    if value < minValue then value = minValue end
    if value > maxValue then value = maxValue end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, CONFIG.RowHeight)
    row.BackgroundColor3 = COLORS.Row
    row.BorderSizePixel = 1
    row.BorderColor3 = COLORS.RowBorder
    row.LayoutOrder = order
    row.Parent = list

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 0, 14)
    text.Position = UDim2.fromOffset(6, 2)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = COLORS.Text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Font = Enum.Font.Code
    text.TextSize = 12
    text.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -70, 0, 6)
    bar.Position = UDim2.new(0, 6, 1, -10)
    bar.BackgroundColor3 = COLORS.Box
    bar.BorderSizePixel = 0
    bar.Parent = row

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = COLORS.Tick
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(58, 14)
    valueLabel.Position = UDim2.new(1, -64, 1, -16)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 12
    valueLabel.Parent = row

    local function setFromScale(scale)
        scale = math.clamp(scale, 0, 1)
        local raw = minValue + (maxValue - minValue) * scale
        if step > 0 then
            raw = minValue + math.floor((raw - minValue) / step + 0.5) * step
        end
        value = math.clamp(raw, minValue, maxValue)
        local disp = (maxValue - minValue) > 0 and (value - minValue) / (maxValue - minValue) or 0
        fill.Size = UDim2.fromScale(disp, 1)
        valueLabel.Text = tostring(value)
        if onChange then onChange(value) end
    end

    local draggingBar = false
    local function updateFromInput(input)
        local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        setFromScale(rel)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingBar and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = false
        end
    end)

    local handle = {}
    function handle:SetValue(v)
        local disp = (maxValue - minValue) > 0 and (math.clamp(v, minValue, maxValue) - minValue) / (maxValue - minValue) or 0
        value = math.clamp(v, minValue, maxValue)
        fill.Size = UDim2.fromScale(disp, 1)
        valueLabel.Text = tostring(value)
    end
    function handle:GetValue() return value end

    -- initial fill
    local initDisp = (maxValue - minValue) > 0 and (value - minValue) / (maxValue - minValue) or 0
    fill.Size = UDim2.fromScale(initDisp, 1)

    updateHeight()
    return handle
end

-- Plain label row
function BunLib:AddLabel(text)
    local order = nextOrder()
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, 0, 0, CONFIG.RowHeight)
    row.BackgroundColor3 = COLORS.Row
    row.BorderSizePixel = 0
    row.Text = "  " .. text
    row.TextColor3 = COLORS.Text
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Font = Enum.Font.Code
    row.TextSize = 12
    row.LayoutOrder = order
    row.Parent = list
    updateHeight()
    return row
end

-- Show/hide programmatically
function BunLib:SetVisible(v)
    if gui then gui.Enabled = v and true or false end
end

-- Flip visibility (same as pressing the toggle key / clicking the title button)
function BunLib:Toggle()
    if gui then gui.Enabled = not gui.Enabled end
    for _, cb in ipairs(toggleCallbacks) do
        if gui then cb(gui.Enabled) end
    end
end

function BunLib:IsVisible()
    return gui and gui.Enabled
end

-- Register a callback for every toggle (fires with new visibility)
function BunLib:OnToggle(cb)
    table.insert(toggleCallbacks, cb)
end

return BunLib
