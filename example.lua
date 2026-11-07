-- example.lua — run this in an executor (loadstring context)

local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

local Window = BunLib:CreateWindow({ Title = "My Menu" })
local Tab = Window:CreateTab("Main")

Tab:CreateToggle({
    Name = "Example toggle",
    CurrentValue = false,
    Callback = function(on)
        print("toggled:", on)
    end,
})

Tab:CreateSlider({
    Name = "Example slider",
    Min = 0,
    Max = 10,
    Increment = 0.1, -- snaps to clean 0.1 steps
    CurrentValue = 5,
    Callback = function(v)
        print("slider:", v)
    end,
})

Tab:CreateButton({
    Name = "Notify me",
    Callback = function()
        BunLib:Notify({ Title = "Hello", Content = "Button clicked", Type = "Success" })
    end,
})

-- see test-all.lua for every feature (dropdown, textbox, color picker, tabs...)
