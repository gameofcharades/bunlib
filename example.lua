-- example.lua — run this in an executor (loadstring context)

local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

BunLib:Init({ Title = "Anti-Cheat Tester" })

BunLib:AddCheckbox("Extended Hitboxes (2x)", false, function(on)
    -- your refreshHitbox logic
end)

BunLib:AddCheckbox("Highlight ESP", false, function(on)
    -- your refreshESP logic
end)

local slider = BunLib:AddSlider("Hitbox Multiplier", 1.0, 3.0, 0.1, 2.0, function(v)
    -- your applyMultiplier(v) logic
end)

BunLib:AddLabel("RightShift to toggle panel")
