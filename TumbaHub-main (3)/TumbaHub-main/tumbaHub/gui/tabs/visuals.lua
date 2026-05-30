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

if not Mega.Localization.Strings["toggle_fov_zoom"] then
    Mega.Localization.Strings["toggle_fov_zoom"] = { ru = "FOV & Приближение", en = "FOV & Zoom" }
end
if not Mega.Localization.Strings["slider_fov"] then
    Mega.Localization.Strings["slider_fov"] = { ru = "Угол обзора (FOV)", en = "Field of View (FOV)" }
end
if not Mega.Localization.Strings["toggle_zoom"] then
    Mega.Localization.Strings["toggle_zoom"] = { ru = "Включить приближение", en = "Enable Zoom" }
end
if not Mega.Localization.Strings["button_zoom_key"] then
    Mega.Localization.Strings["button_zoom_key"] = { ru = "Клавиша зума", en = "Zoom Key" }
end
if not Mega.Localization.Strings["slider_zoom_fov"] then
    Mega.Localization.Strings["slider_zoom_fov"] = { ru = "FOV при зуме", en = "Zoom FOV" }
end

UI.CreateToggleWithSettings(TabFrame, "toggle_fov_zoom", "Visuals.FOVZoom.Enabled", function(state)
    if Mega.Features.FOVZoom and Mega.Features.FOVZoom.SetEnabled then
        Mega.Features.FOVZoom.SetEnabled(state)
    end
end, {
    UI.CreateSlider(nil, "slider_fov", "Visuals.FOVZoom.FOV", 30, 120),
    UI.CreateToggle(nil, "toggle_zoom", "Visuals.FOVZoom.ZoomEnabled"),
    UI.CreateKeybindButton(nil, "button_zoom_key", "Visuals.FOVZoom.ZoomKey"),
    UI.CreateSlider(nil, "slider_zoom_fov", "Visuals.FOVZoom.ZoomFOV", 10, 60)
})
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

