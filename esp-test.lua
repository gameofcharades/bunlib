-- esp-test.lua — paste this whole file into your executor.
-- Highlights all players (ESP) with a slider for inner (fill) opacity.

local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = BunLib:CreateWindow({ Title = "ESP Tester" })
local Tab = Window:CreateTab("ESP")

-- ============ ESP ============
local highlights = {} -- [Player] = Highlight
local espEnabled = false
local innerOpacity = 0.5 -- 1 = fully visible fill, 0 = invisible fill

local function applyStyle(h)
    h.FillColor = Color3.fromRGB(255, 60, 60)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 1 - innerOpacity -- slider is "opacity", engine wants transparency
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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

local function setEsp(on)
    espEnabled = on
    for _, player in ipairs(Players:GetPlayers()) do
        if on then
            addHighlight(player)
            player.CharacterAdded:Connect(function()
                if espEnabled then addHighlight(player) end
            end)
        elseif highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        player.CharacterAdded:Connect(function()
            if espEnabled then addHighlight(player) end
        end)
        addHighlight(player)
    end
end)

-- ============ UI ============
Tab:CreateToggle({ Name = "Highlight players", CurrentValue = false, Callback = setEsp })

Tab:CreateSlider({
    Name = "Inner opacity",
    Min = 0,
    Max = 1,
    Increment = 0.05,
    CurrentValue = innerOpacity,
    Callback = function(v)
        innerOpacity = v
        for _, h in pairs(highlights) do
            h.FillTransparency = 1 - v
        end
    end,
})
