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
end, {})
--#endregion

--#region -- Trap ESP
UI.CreateSection(TabFrame, "toggle_trap_esp")

UI.CreateToggle(TabFrame, "toggle_trap_esp", "Render.TrapESP", function(state)
    if Mega.Features.TrapESP and Mega.Features.TrapESP.SetEnabled then
        Mega.Features.TrapESP.SetEnabled(state)
    end
end)
--#endregion

--#region -- Telepearl ESP
do
    -- Безопасная инициализация ключей, если таблица уже существует, но пустая
    if type(Mega.States.TelepearlESP) ~= "table" then
        Mega.States.TelepearlESP = {}
    end
    if Mega.States.TelepearlESP.Color == nil then
        Mega.States.TelepearlESP.Color = Color3.fromRGB(160, 60, 255)
    end
    if Mega.States.TelepearlESP.DotSpacing == nil then
        Mega.States.TelepearlESP.DotSpacing = 5
    end
    if Mega.States.TelepearlESP.Duration == nil then
        Mega.States.TelepearlESP.Duration = 1 -- Время в секундах по умолчанию
    end

    local loc = Mega.Localization.Strings
    if not loc["section_telepearl_esp"] then
        loc["section_telepearl_esp"]      = { ru = "Telepearl ESP",                en = "Telepearl ESP" }
        loc["toggle_telepearl_esp"]       = { ru = "Telepearl ESP",                en = "Telepearl ESP" }
        loc["slider_pearl_duration"]      = { ru = "Время показа (Сек)",           en = "Display Time (Sec)" }
        loc["slider_pearl_dot_spacing"]   = { ru = "Расстояние между точками",     en = "Dot Spacing" }
        loc["slider_pearl_circle_transp"] = { ru = "Прозрачность круга",           en = "Circle Transparency" }
        loc["slider_pearl_icon_transp"]   = { ru = "Прозрачность иконки",          en = "Icon Transparency" }
        loc["button_pearl_color"]         = { ru = "Цвет траектории и круга",      en = "ESP Color" }
    end

    UI.CreateSection(TabFrame, "section_telepearl_esp")

    UI.CreateToggleWithSettings(TabFrame, "toggle_telepearl_esp", "TelepearlESP.Enabled", function(state)
        if not Mega.Features.TelepearlESP then
            Mega.LoadModule("features/telepearl_predict.lua")
        end
        if Mega.Features.TelepearlESP and Mega.Features.TelepearlESP.SetEnabled then
            Mega.Features.TelepearlESP.SetEnabled(state)
        end
    end, {
        -- Ползунок от 0 до 10 секунд (0 = моментальное исчезновение)
        UI.CreateSlider(nil, "slider_pearl_duration",      "TelepearlESP.Duration",     0,  10),
        UI.CreateSlider(nil, "slider_pearl_dot_spacing",   "TelepearlESP.DotSpacing",   1,  20),
        UI.CreateSlider(nil, "slider_pearl_circle_transp", "TelepearlESP.CircleTransp", 0, 100),
        UI.CreateSlider(nil, "slider_pearl_icon_transp",   "TelepearlESP.IconTransp",   0, 100),
        CreateColorPicker(nil, "button_pearl_color", Mega.States.TelepearlESP.Color or Color3.fromRGB(160, 60, 255), function(col)
            Mega.States.TelepearlESP.Color = col
        end)
    })
end
--#endregion

--#region -- Drone ESP
do
    local loc = Mega.Localization.Strings
    if not loc["section_drone_esp"] then
        loc["section_drone_esp"]      = { ru = "Drone ESP", en = "Drone ESP" }
        loc["toggle_drone_esp"]       = { ru = "Включить Drone ESP", en = "Enable Drone ESP" }
        loc["toggle_drone_icons"]     = { ru = "Иконки дронов", en = "Drone Icons" }
        loc["toggle_drone_highlight"] = { ru = "Подсветка дронов", en = "Drone Highlight" }
    end

    UI.CreateSection(TabFrame, "section_drone_esp")

    UI.CreateToggleWithSettings(TabFrame, "toggle_drone_esp", "DroneESP.Enabled", function(state)
        if not Mega.Features.DroneESP then
            Mega.LoadModule("features/drone_esp.lua")
        end
        if Mega.Features.DroneESP and Mega.Features.DroneESP.SetEnabled then
            Mega.Features.DroneESP.SetEnabled(state)
        end
    end, {
        UI.CreateToggle(nil, "toggle_drone_icons", "DroneESP.ShowIcons", function() 
            if Mega.Features.DroneESP then Mega.Features.DroneESP.UpdateVisuals() end 
        end),
        UI.CreateToggle(nil, "toggle_drone_highlight", "DroneESP.ShowHighlight", function() 
            if Mega.Features.DroneESP then Mega.Features.DroneESP.UpdateVisuals() end 
        end)
    })
end
--#endregion
