# bunlib

A small single-file UI library for Roblox, loadstring-ready (Rayfield/Obsidian style).

## Usage (executor)

```lua
local BunLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/gameofcharades/bunlib/main/bunlib.lua"))()

local Window = BunLib:CreateWindow({ Title = "My Menu" })
local Tab = Window:CreateTab("Main")

Tab:CreateToggle({ Name = "ESP", CurrentValue = false, Callback = function(on) end })
Tab:CreateSlider({ Name = "Opacity", Min = 0, Max = 1, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) end })
```

See `test-all.lua` for every feature.

## API

### Library
| Method | Description |
| --- | --- |
| `BunLib:CreateWindow(config)` | Returns a Window. Config: `Title`, `ToggleKey` (default RightShift), `Position`, `Width`, `Height`, `MinWidth`, `MinHeight`, `Padding`, `StartVisible` (default true), `Theme` (partial table merged over defaults) |
| `BunLib:Notify(opts)` | Toast notification. `opts`: `Title`, `Content`, `Duration` (default 5), `Type` (`Info`/`Success`/`Warning`/`Error`), `Position` (default `BunLib.NotifyPosition`, which defaults to `"BottomRight"`; also `TopLeft`, `TopRight`, `BottomLeft`, `TopCenter`, `BottomCenter`) |
| `BunLib.NotifyPosition` | Global default notification corner |

### Window
| Method | Description |
| --- | --- |
| `Window:CreateTab(name)` | Returns a Tab (first tab is selected automatically) |
| `Window:SelectTab(name)` / `Window:GetActiveTab()` | Switch tabs |
| `Window:SetVisible(bool)` / `Window:IsVisible()` / `Window:Toggle()` | Show/hide |
| `Window:OnToggle(cb)` | `cb(visible)` on every toggle |
| `Window:Destroy()` | Remove the UI |

The window is draggable by the title bar and resizable via the bottom-right corner handle. Toggle with the toggle key or the `_` button on the title bar.

### Tab elements
All element `Callback`s fire on user interaction. `Set(...)` methods update state/visuals without firing the callback.

| Method | Options | Handle |
| --- | --- | --- |
| `Tab:CreateSection(name)` | — | row |
| `Tab:CreateToggle(opt)` | `Name`, `CurrentValue`, `Callback(bool)` | `Set(bool)`, `Get()` |
| `Tab:CreateSlider(opt)` | `Name`, `Min`, `Max`, `Increment` (0 = continuous; >0 snaps to clean steps), `CurrentValue`, `Callback(value)` | `Set(v)`, `Get()` |
| `Tab:CreateButton(opt)` | `Name`, `Callback()` | `Fire()`, `SetText(t)` |
| `Tab:CreateLabel(text)` | — | `SetText(t)`, `GetText()` |
| `Tab:CreateDropdown(opt)` | `Name`, `Options` (array), `CurrentOption`, `Callback(option)` | `Set(o)`, `Get()`, `GetOptions()` |
| `Tab:CreateTextBox(opt)` | `Name`, `Placeholder`, `CurrentText`, `Callback(text)` on Enter | `Set(t)`, `Get()` |
| `Tab:CreateColorPicker(opt)` | `Name`, `CurrentColor`, `Callback(Color3)` live | `SetColor(c)`, `GetColor()` |

## Testing in a baseplate (Studio)

`game:HttpGet` needs HTTP requests enabled, so for a quick local test:

1. Paste `bunlib.lua` into a **ModuleScript** named `BunLib` in `ReplicatedStorage`.
2. In a **LocalScript** (e.g. `StarterPlayerScripts`):

```lua
local BunLib = require(game:GetService("ReplicatedStorage"):WaitForChild("BunLib"))
local Window = BunLib:CreateWindow({ Title = "Test" })
local Tab = Window:CreateTab("Main")
Tab:CreateToggle({ Name = "Test", Callback = print })
```

The same file works both ways: `loadstring(...)()` in an executor, `require(...)` in Studio.
