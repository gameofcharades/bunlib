# bunlib

A small single-file UI library for Roblox, loadstring-ready (Rayfield/Obsidian style).

## Usage (executor)

```lua
local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

BunLib:Init({ Title = "My Menu" }) -- RightShift toggles the panel by default

local toggle = BunLib:AddCheckbox("Example toggle", false, function(on)
    print("toggled:", on)
end)

local slider = BunLib:AddSlider("Multiplier", 1, 3, 0.1, 2, function(v)
    print("slider:", v)
end)

BunLib:AddLabel("some text")
```

See `example.lua` for a full example.

## API

| Method | Description |
| --- | --- |
| `BunLib:Init(config)` | Builds the panel (visible by default). Config keys: `Title`, `ToggleKey`, `Position`, `Width`, `RowHeight`, `Padding`, `TitleHeight`, `StartVisible` |
| `BunLib:AddCheckbox(label, initial, onChange)` | Returns `{ SetChecked(bool), IsChecked() }` |
| `BunLib:AddSlider(label, min, max, step, initial, onChange)` | Returns `{ SetValue(v), GetValue() }` |
| `BunLib:AddLabel(text)` | Plain text row |
| `BunLib:SetVisible(bool)` / `BunLib:IsVisible()` | Show/hide the panel |
| `BunLib:OnToggle(cb)` | `cb(visible)` fires every time the panel is toggled |

## Testing in a baseplate (Studio)

`game:HttpGet` needs HTTP requests enabled, so for a quick local test:

1. Paste `bunlib.lua` into a **ModuleScript** named `BunLib` in `ReplicatedStorage`.
2. In a **LocalScript** (e.g. `StarterPlayerScripts`):

```lua
local BunLib = require(game:GetService("ReplicatedStorage"):WaitForChild("BunLib"))
BunLib:Init({ Title = "Test" })
BunLib:AddCheckbox("Test checkbox", false, print)
```

The same file works both ways: `loadstring(...)()` in an executor, `require(...)` in Studio.
