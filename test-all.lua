-- test-all.lua — paste into your executor. Exercises every bunlib feature.

local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = BunLib:CreateWindow({
    Title = "bunlib test",
    Width = 340,
    Height = 400,
})

-- ============ ESP state ============
local highlights = {} -- [Player] = Highlight
local espEnabled = false
local innerOpacity = 0.5
local fillColor = Color3.fromRGB(255, 60, 60)
local depthMode = Enum.HighlightDepthMode.AlwaysOnTop

local function applyStyle(h)
    h.FillColor = fillColor
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 1 - innerOpacity
    h.OutlineTransparency = 0
    h.DepthMode = depthMode
end

local function addHighlight(player)
    if player == LocalPlayer or highlights[player] then return end
    local char = player.Character
    if not char then return end
    local h = Instance.new("Highlight")
    applyStyle(h)
    h.Parent = char
    highlights[player] = h
end

local function removeHighlight(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

local function setEsp(on)
    espEnabled = on
    for _, p in ipairs(Players:GetPlayers()) do
        if on then
            addHighlight(p)
            p.CharacterAdded:Connect(function()
                if espEnabled then addHighlight(p) end
            end)
        else
            removeHighlight(p)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if espEnabled then
        p.CharacterAdded:Connect(function()
            if espEnabled then addHighlight(p) end
        end)
        addHighlight(p)
    end
end)

-- ============ TAB 1: ESP ============
local EspTab = Window:CreateTab("ESP")

EspTab:CreateSection("Highlight")

EspTab:CreateToggle({
    Name = "Highlight players",
    CurrentValue = false,
    Callback = setEsp,
})

EspTab:CreateSlider({
    Name = "Inner opacity",
    Min = 0,
    Max = 1,
    Increment = 0.1, -- snaps to clean 0.1 steps
    CurrentValue = innerOpacity,
    Callback = function(v)
        innerOpacity = v
        for _, h in pairs(highlights) do
            h.FillTransparency = 1 - v
        end
    end,
})

EspTab:CreateColorPicker({
    Name = "Highlight color",
    CurrentColor = fillColor,
    Callback = function(c)
        fillColor = c
        for _, h in pairs(highlights) do
            h.FillColor = c
        end
    end,
})

EspTab:CreateDropdown({
    Name = "Depth mode",
    Options = { "AlwaysOnTop", "Occluded" },
    CurrentOption = "AlwaysOnTop",
    Callback = function(opt)
        depthMode = opt == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop
            or Enum.HighlightDepthMode.Occluded
        for _, h in pairs(highlights) do
            h.DepthMode = depthMode
        end
    end,
})

-- ============ TAB 2: UI ============
local UiTab = Window:CreateTab("UI")

UiTab:CreateSection("Notifications")

UiTab:CreateButton({
    Name = "Notify bottom-right (default)",
    Callback = function()
        BunLib:Notify({ Title = "Info", Content = "Default position: bottom right", Type = "Info", Duration = 4 })
    end,
})

UiTab:CreateButton({
    Name = "Notify top-left",
    Callback = function()
        BunLib:Notify({ Title = "Top left", Content = "Position override works", Type = "Success", Duration = 4, Position = "TopLeft" })
    end,
})

UiTab:CreateButton({
    Name = "Notify error top-right",
    Callback = function()
        BunLib:Notify({ Title = "Error", Content = "Something failed", Type = "Error", Duration = 4, Position = "TopRight" })
    end,
})

UiTab:CreateSection("Inputs")

UiTab:CreateTextBox({
    Name = "Say",
    Placeholder = "type + enter",
    Callback = function(text)
        BunLib:Notify({ Title = "TextBox", Content = text, Duration = 3 })
    end,
})

local statusLabel = UiTab:CreateLabel("status: idle")

UiTab:CreateButton({
    Name = "Update label + warn",
    Callback = function()
        statusLabel:SetText("status: button clicked at " .. os.date("%H:%M:%S"))
        BunLib:Notify({ Title = "Warning", Content = "Label updated", Type = "Warning", Duration = 3, Position = "BottomLeft" })
    end,
})

Window:OnToggle(function(visible)
    BunLib:Notify({ Title = "Window", Content = visible and "shown" or "hidden", Duration = 2, Position = "TopCenter" })
end)
