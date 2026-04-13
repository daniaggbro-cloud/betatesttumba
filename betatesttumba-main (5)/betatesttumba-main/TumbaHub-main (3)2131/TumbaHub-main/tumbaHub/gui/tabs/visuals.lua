-- gui/tabs/visuals.lua
-- Content for the "VISUALS" tab

local tabKey = "tab_visuals"
local UI = Mega.UI
local Lighting = Mega.Services.Lighting

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Store original lighting values
local originalFogEnd = Lighting.FogEnd
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalGlobalShadows = Lighting.GlobalShadows

--#region -- Environment Visuals
UI.CreateSection(TabFrame, "section_visuals_env")

UI.CreateToggle(TabFrame, "toggle_nofog", "Visuals.NoFog", function(state)
    Lighting.FogEnd = state and 100000 or originalFogEnd
end)

UI.CreateToggle(TabFrame, "toggle_fullbright", "Visuals.FullBright", function(state)
    Lighting.Brightness = state and 2 or originalBrightness
end)

UI.CreateToggle(TabFrame, "toggle_nightmode", "Visuals.NightMode", function(state)
    Lighting.ClockTime = state and 22 or originalClockTime
end)

UI.CreateToggle(TabFrame, "toggle_removeshadows", "Visuals.RemoveShadows", function(state)
    Lighting.GlobalShadows = not state
end)

-- Chams are complex and would need a dedicated feature module.
-- For now, it's just a toggle that doesn't do anything.
UI.CreateToggle(TabFrame, "toggle_chams", "Visuals.Chams", function(state)
    Mega.ShowNotification("Chams not implemented yet.", 2)
    if not state then return end
    -- Immediately toggle it back off since it's not implemented
    task.wait(0.1)
    if Mega.Objects.Toggles["toggle_chams"] then
        Mega.Objects.Toggles["toggle_chams"](false)
    end
end)

-- Restore settings on script unload/cleanup
-- This would be connected in a main cleanup function
-- table.insert(Mega.Objects.Connections, function()
--     Lighting.FogEnd = originalFogEnd
--     Lighting.Brightness = originalBrightness
--     Lighting.ClockTime = originalClockTime
--     Lighting.GlobalShadows = originalGlobalShadows
-- end)
--#endregion

