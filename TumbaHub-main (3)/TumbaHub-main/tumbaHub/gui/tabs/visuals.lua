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

task.spawn(function()
    pcall(function() Mega.LoadModule("features/environment_visuals.lua") end)
end)

--#region -- Environment Visuals
UI.CreateSection(TabFrame, "section_visuals_env")

UI.CreateToggle(TabFrame, "toggle_nofog", "Visuals.NoFog", function(state)
    Mega.States.Visuals.NoFog = state
end)

UI.CreateToggle(TabFrame, "toggle_fullbright", "Visuals.FullBright", function(state)
    Mega.States.Visuals.FullBright = state
    if not state then
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

UI.CreateToggle(TabFrame, "toggle_nightmode", "Visuals.NightMode", function(state)
    Mega.States.Visuals.NightMode = state
end)

UI.CreateToggle(TabFrame, "toggle_removeshadows", "Visuals.RemoveShadows", function(state)
    Mega.States.Visuals.RemoveShadows = state
    if not state then
        Lighting.GlobalShadows = true
    end
end)

--#region -- Custom Models
UI.CreateSection(TabFrame, "section_visuals_custom")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/gorilla_chams.lua") end)
end)

UI.CreateToggle(TabFrame, "toggle_gorilla_mode", "Visuals.GorillaMode", function(state)
    if Mega.Features.GorillaChams and Mega.Features.GorillaChams.SetEnabled then
        Mega.Features.GorillaChams.SetEnabled(state)
    end
end)

if not Mega.Localization.Strings["toggle_kit_display"] then
    Mega.Localization.Strings["toggle_kit_display"] = { ru = "Отображение китов", en = "Kit Display" }
end

UI.CreateToggle(TabFrame, "toggle_kit_display", "Render.KitDisplay", function(state)
    if Mega.Features.KitDisplay and Mega.Features.KitDisplay.SetEnabled then
        Mega.Features.KitDisplay.SetEnabled(state)
    end
end)
--#endregion
-- Restore settings on script unload/cleanup
-- This would be connected in a main cleanup function
-- table.insert(Mega.Objects.Connections, function()
--     Lighting.FogEnd = originalFogEnd
--     Lighting.Brightness = originalBrightness
--     Lighting.ClockTime = originalClockTime
--     Lighting.GlobalShadows = originalGlobalShadows
-- end)
--#endregion

--#region -- Bed Plates
UI.CreateSection(TabFrame, "toggle_bed_plates")

UI.CreateToggleWithSettings(TabFrame, "toggle_bed_plates", "Render.BedPlates", function(state)
    if Mega.Features.BedPlates and Mega.Features.BedPlates.SetEnabled then
        Mega.Features.BedPlates.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_bed_plates_background", "Render.BedPlatesBackground", function(state)
        Mega.States.Render.BedPlatesBackground = state
        if Mega.States.Render.BedPlates and Mega.Features.BedPlates and Mega.Features.BedPlates.SetEnabled then
            Mega.Features.BedPlates.SetEnabled(false)
            Mega.Features.BedPlates.SetEnabled(true)
        end
    end),
    UI.CreateToggle(nil, "toggle_bed_plates_counter", "Render.BedPlatesCounter", function(state)
        Mega.States.Render.BedPlatesCounter = state
        if Mega.States.Render.BedPlates and Mega.Features.BedPlates and Mega.Features.BedPlates.SetEnabled then
            Mega.Features.BedPlates.SetEnabled(false)
            Mega.Features.BedPlates.SetEnabled(true)
        end
    end)
})
--#endregion


