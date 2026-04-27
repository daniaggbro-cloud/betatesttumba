-- gui/tabs/esp.lua
-- Content for the "ESP" tab

local tabKey = "tab_esp"
local UI = Mega.UI

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

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)
end)
TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Load the actual ESP logic feature module
Mega.LoadModule("features/esp.lua")

if Mega.States.ESP.UseTeamColor == nil then Mega.States.ESP.UseTeamColor = true end
if not Mega.Localization.Strings["toggle_use_team_colors"] then
    Mega.Localization.Strings["toggle_use_team_colors"] = { ru = "Использовать цвета команд", en = "Use Native Team Colors" }
end

local function CreateColorPicker(parent, textKey, initialColor, callback)
    local translatedText = Mega.GetText(textKey)
    if translatedText == textKey then translatedText = textKey end
    
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = textKey .. "ColorPicker"
    MainContainer.Size = UDim2.new(0.95, 0, 0, 35)
    MainContainer.BackgroundTransparency = 1
    MainContainer.ClipsDescendants = true
    MainContainer.Parent = parent

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Button.BorderSizePixel = 0
    Button.Text = "🎨 " .. translatedText
    Button.TextColor3 = Color3.new(1,1,1)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    Button.Parent = MainContainer
    
    local ColorPreview = Instance.new("Frame")
    ColorPreview.Size = UDim2.new(0, 20, 0, 20)
    ColorPreview.Position = UDim2.new(1, -30, 0.5, -10)
    ColorPreview.BackgroundColor3 = initialColor
    Instance.new("UICorner", ColorPreview).CornerRadius = UDim.new(1, 0)
    ColorPreview.Parent = Button

    local PaletteContainer = Instance.new("Frame")
    PaletteContainer.Size = UDim2.new(1, 0, 0, 100)
    PaletteContainer.Position = UDim2.new(0, 0, 0, 40)
    PaletteContainer.BackgroundTransparency = 1
    PaletteContainer.Parent = MainContainer

    local Grid = Instance.new("UIGridLayout")
    Grid.Parent = PaletteContainer
    Grid.CellSize = UDim2.new(0, 30, 0, 30)
    Grid.CellPadding = UDim2.new(0, 6, 0, 6)
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local colors = {
        Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 255, 50), Color3.fromRGB(50, 100, 255),
        Color3.fromRGB(255, 255, 50), Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 50, 255),
        Color3.fromRGB(50, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 20),
        Color3.fromRGB(150, 50, 150), Color3.fromRGB(50, 150, 150), Color3.fromRGB(150, 150, 50),
        Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 255, 100), Color3.fromRGB(100, 100, 255)
    }
    
    for _, col in ipairs(colors) do
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0, 30, 0, 30)
        cBtn.BackgroundColor3 = col
        cBtn.Text = ""
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)
        cBtn.Parent = PaletteContainer
        
        cBtn.MouseButton1Click:Connect(function()
            ColorPreview.BackgroundColor3 = col
            if callback then callback(col) end
        end)
    end
    
    local isOpen = false
    Button.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetHeight = isOpen and 155 or 35
        Mega.Services.TweenService:Create(MainContainer, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, targetHeight)}):Play()
    end)
    
    return MainContainer
end

--#region -- Main Player ESP
UI.CreateSection(TabFrame, "section_esp_main")

UI.CreateToggleWithSettings(TabFrame, "toggle_esp", "ESP.Enabled", function(state)
    if Mega.Features.ESP then
        Mega.Features.ESP.SetEnabled(state)
    end
end, {
    UI.CreateSection(nil, "section_esp_visuals"),
    UI.CreateToggle(nil, "toggle_esp_boxes", "ESP.Boxes"),
    UI.CreateToggle(nil, "toggle_esp_outline", "ESP.Outline"),
    UI.CreateToggle(nil, "toggle_esp_names", "ESP.Names"),
    UI.CreateToggle(nil, "toggle_esp_health", "ESP.Health"),
    UI.CreateToggle(nil, "toggle_esp_health_text", "ESP.HealthText"),
    UI.CreateToggle(nil, "toggle_esp_tool", "ESP.HeldItem"),
    UI.CreateToggle(nil, "toggle_esp_distance", "ESP.Distance"),
    UI.CreateToggle(nil, "toggle_esp_skeleton", "ESP.Skeleton"),
    UI.CreateToggle(nil, "toggle_esp_chams", "ESP.Chams"),
    UI.CreateToggle(nil, "toggle_esp_tracers", "ESP.Tracers"),
    UI.CreateDropdown(nil, "dropdown_tracer_origin", "ESP.TracerOrigin", {"Bottom", "Center", "Top", "Mouse"}),
    UI.CreateToggle(nil, "toggle_esp_team", "ESP.ShowTeam"),
    UI.CreateSlider(nil, "slider_esp_max_dist", "ESP.MaxDistance", 50, 2000),
    UI.CreateSection(nil, "section_esp_colors"),
    UI.CreateToggle(nil, "toggle_use_team_colors", "ESP.UseTeamColor"),
    CreateColorPicker(nil, "button_team_color", Mega.States.ESP.TeamColor, function(col)
        Mega.States.ESP.TeamColor = col
        if Mega.ShowNotification then Mega.ShowNotification(Mega.GetText("notify_team_color_changed")) end
    end),
    CreateColorPicker(nil, "button_enemy_color", Mega.States.ESP.EnemyColor, function(col)
        Mega.States.ESP.EnemyColor = col
        if Mega.ShowNotification then Mega.ShowNotification(Mega.GetText("notify_enemy_color_changed")) end
    end)
})
--#endregion


--#region -- Kit ESP
UI.CreateSection(TabFrame, "section_kit_esp")

UI.CreateToggleWithSettings(TabFrame, "toggle_kit_esp", "KitESP.Enabled", function(state)
    pcall(function()
        if Mega.Features.ESP and Mega.Features.ESP.SetKitEnabled then
            Mega.Features.ESP.SetKitEnabled(state)
        end
    end)
    pcall(function()
        Mega.ShowNotification(Mega.GetText(state and "notify_kit_esp_on" or "notify_kit_esp_off"))
    end)

    if state then
        task.spawn(function()
            -- Убедимся, что вкладка farm прогружена
            if not Mega.LoadedModules["gui/tabs/farm.lua"] then
                pcall(function() Mega.LoadModule("gui/tabs/farm.lua") end)
                task.wait(0.3)
            end

            -- Напрямую ставим нужные стейты (не зависим от UI-тогглов)
            -- Beekeeper: включаем + ESP-визуал
            Mega.States.Beekeeper.Enabled = true
            Mega.States.Beekeeper.ShowIcons = true
            Mega.States.Beekeeper.ShowHighlight = true
            Mega.States.Beekeeper.ShowHiveLevels = true
            Mega.States.Beekeeper.AutoCatch = false
            pcall(function() if Mega.Features.Beekeeper and Mega.Features.Beekeeper.SetEnabled then Mega.Features.Beekeeper.SetEnabled(true) end end)
            pcall(function() if Mega.Features.Beekeeper and Mega.Features.Beekeeper.UpdateVisuals then Mega.Features.Beekeeper.UpdateVisuals() end end)

            -- Cletus: включаем + ESP
            Mega.States.Cletus.Enabled = true
            Mega.States.Cletus.ESP = true
            Mega.States.Cletus.AutoHarvest = false
            pcall(function() if Mega.Features.Cletus and Mega.Features.Cletus.SetEnabled then Mega.Features.Cletus.SetEnabled(true) end end)
            pcall(function() if Mega.Features.Cletus and Mega.Features.Cletus.RecreateESP then Mega.Features.Cletus.RecreateESP() end end)

            -- Eldertree: включаем + ESP, без автосбора
            Mega.States.Eldertree.Enabled = true
            Mega.States.Eldertree.ESP = true
            Mega.States.Eldertree.AutoCollect = false
            pcall(function() if Mega.Features.Eldertree and Mega.Features.Eldertree.SetEnabled then Mega.Features.Eldertree.SetEnabled(true) end end)
            pcall(function() if Mega.Features.Eldertree and Mega.Features.Eldertree.UpdateESP then Mega.Features.Eldertree.UpdateESP() end end)

            -- StarCollector: включаем + ESP, без автосбора
            Mega.States.StarCollector.Enabled = true
            Mega.States.StarCollector.ESP = true
            Mega.States.StarCollector.AutoCollect = false
            pcall(function() if Mega.Features.StarCollector and Mega.Features.StarCollector.SetEnabled then Mega.Features.StarCollector.SetEnabled(true) end end)
            pcall(function() if Mega.Features.StarCollector and Mega.Features.StarCollector.UpdateESP then Mega.Features.StarCollector.UpdateESP() end end)

            -- Metal: включаем + ESP, без автосбора
            Mega.States.Metal.Enabled = true
            Mega.States.Metal.ESP = true
            Mega.States.Metal.AutoCollect = false
            Mega.States.Metal.AutoCollectLegit = false
            pcall(function() if Mega.Features.Metal and Mega.Features.Metal.SetEnabled then Mega.Features.Metal.SetEnabled(true) end end)
            pcall(function() if Mega.Features.Metal and Mega.Features.Metal.UpdateESP then Mega.Features.Metal.UpdateESP() end end)

            -- Taliah: включаем + ESP, без автосбора
            Mega.States.Taliah.Enabled = true
            Mega.States.Taliah.ESP = true
            Mega.States.Taliah.AutoCollect = false
            Mega.States.Taliah.AutoCollectLegit = false
            pcall(function() if Mega.Features.Taliah and Mega.Features.Taliah.SetEnabled then Mega.Features.Taliah.SetEnabled(true) end end)

            -- Lucia: включаем + ESP, без автодепозита
            Mega.States.Lucia.Enabled = true
            Mega.States.Lucia.ESP = true
            Mega.States.Lucia.AutoDeposit = false
            Mega.States.Lucia.Legit = false
            pcall(function() if Mega.Features.Lucia and Mega.Features.Lucia.SetEnabled then Mega.Features.Lucia.SetEnabled(true) end end)

            -- Alchemist: включаем + ESP, без автосбора
            if Mega.States.Misc and Mega.States.Misc.Alchemist then
                Mega.States.Misc.Alchemist.Enabled = true
                Mega.States.Misc.Alchemist.ESP = true
                Mega.States.Misc.Alchemist.AutoCollect = false
            end
            pcall(function() if Mega.Features.Alchemist and Mega.Features.Alchemist.SetEnabled then Mega.Features.Alchemist.SetEnabled(true) end end)

            -- Отключаем всё лишнее
            Mega.States.Fisherman.Enabled = false
            Mega.States.Noelle.Enabled = false
            pcall(function() if Mega.Features.Noelle and Mega.Features.Noelle.SetEnabled then Mega.Features.Noelle.SetEnabled(false) end end)

            -- Синхронизация UI-тогглов (если вкладка farm прогружена)
            task.wait(0.1)
            local allToggles = {
                {"toggle_beekeeper", true}, {"toggle_bee_icons", true}, {"toggle_bee_highlight", true}, {"toggle_hive_levels", true}, {"toggle_auto_catch", false},
                {"toggle_cletus", true}, {"toggle_cletus_esp", true}, {"toggle_cletus_harvest", false},
                {"toggle_eldertree", true}, {"toggle_eldertree_esp", true}, {"toggle_eldertree_autocollect", false},
                {"toggle_star_collector", true}, {"toggle_star_collector_esp", true}, {"toggle_star_collector_autocollect", false},
                {"toggle_metal", true}, {"toggle_metal_esp", true}, {"toggle_metal_collect", false}, {"toggle_metal_collect_legit", false},
                {"toggle_taliah", true}, {"toggle_taliah_esp", true}, {"toggle_taliah_collect", false}, {"toggle_taliah_collect_legit", false},
                {"toggle_lucia", true}, {"toggle_lucia_esp", true}, {"toggle_lucia_deposit", false}, {"toggle_lucia_legit", false},
                {"toggle_alchemist", true}, {"toggle_alchemist_esp", true}, {"toggle_alchemist_autocollect", false},
                {"toggle_autofish", false}, {"toggle_autofarm", false},
                {"toggle_noelle", false}
            }
            for _, info in ipairs(allToggles) do
                pcall(function()
                    local key, val = info[1], info[2]
                    if Mega.Objects.Toggles and Mega.Objects.Toggles[key] then
                        Mega.Objects.Toggles[key](val)
                    end
                end)
            end
        end)
    end
end, {})
--#endregion
