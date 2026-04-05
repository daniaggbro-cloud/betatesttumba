-- gui/tabs/settings.lua
-- Content for the "SETTINGS" tab

local tabKey = "tab_settings"
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

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Защита от сбоев UI билдера: создаем нужные пути, если их нет
if not Mega.States.Localization then Mega.States.Localization = {} end

if not Mega.States.Settings then Mega.States.Settings = { Menu = {} } end
Mega.States.Settings.Menu.Transparency = math.floor((Mega.Settings.Menu.Transparency or 0.1) * 100)

if not Mega.States.Temp then Mega.States.Temp = {} end

if Mega.Settings.System.ShowNotifications == nil then
    Mega.Settings.System.ShowNotifications = true
end

if not Mega.OriginalShowNotification and Mega.ShowNotification then
    Mega.OriginalShowNotification = Mega.ShowNotification
    Mega.ShowNotification = function(...)
        if Mega.Settings.System.ShowNotifications then
            Mega.OriginalShowNotification(...)
        end
    end
end

local langKeys = {
    "language_english", "language_russian", "language_ukrainian",
    "language_spanish", "language_portuguese", "language_korean", "language_japanese"
}

local langMapReverse = {
    language_english = "en", language_russian = "ru", language_ukrainian = "uk",
    language_spanish = "es", language_portuguese = "pt", language_korean = "ko", language_japanese = "ja"
}

local currentLangKey = "language_english"
for k, v in pairs(langMapReverse) do
    if v == Mega.Localization.CurrentLanguage then
        currentLangKey = k
        break
    end
end
Mega.States.Localization.CurrentLanguage = currentLangKey

-- ТЕМЫ (цвета)
local themeOptions = {"Magenta", "Red", "Cyan", "Green", "Orange", "Yellow", "Blue"}
local themeColors = {
    Magenta = Color3.fromRGB(200, 70, 255),
    Red     = Color3.fromRGB(255, 50, 50),
    Cyan    = Color3.fromRGB(0, 255, 255),
    Green   = Color3.fromRGB(50, 255, 100),
    Orange  = Color3.fromRGB(255, 165, 0),
    Yellow  = Color3.fromRGB(255, 255, 50),
    Blue    = Color3.fromRGB(50, 100, 255)
}

if not Mega.States.Temp.ThemeName then
    Mega.States.Temp.ThemeName = "Magenta"
    for name, col in pairs(themeColors) do
        if col == Mega.Settings.Menu.AccentColor then
            Mega.States.Temp.ThemeName = name
            break
        end
    end
end

--#region -- Appearance
UI.CreateSection(TabFrame, "section_settings_appearance")

UI.CreateDropdown(TabFrame, "dropdown_language", "Localization.CurrentLanguage", langKeys, function(val)
    local lang = langMapReverse[val] or "en"
    
    if lang == Mega.Localization.CurrentLanguage then return end -- Избегаем лишней перезагрузки
    
    Mega.Localization.CurrentLanguage = lang
    Mega.SaveLanguage(lang)
    Mega.ShowNotification(Mega.GetText("notify_language_changed", Mega.GetText(val)), 3)
    
    if Mega.ReloadGUI then
        task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end)
    end
end, true)

UI.CreateDropdown(TabFrame, "button_change_theme", "Temp.ThemeName", themeOptions, function(val)
    local col = themeColors[val]
    if col then
        Mega.Settings.Menu.AccentColor = col
        Mega.States.Temp.ThemeName = val
        if Mega.ShowNotification then Mega.ShowNotification(Mega.GetText("notify_theme_changed"), 2) end
        if Mega.ReloadGUI then task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end) end
    end
end, false)

UI.CreateSlider(TabFrame, "slider_menu_transparency", "Settings.Menu.Transparency", 0, 100, function(v) 
    local trans = v / 100
    Mega.Settings.Menu.Transparency = trans
    if Mega.Objects.GUI and Mega.Objects.GUI:FindFirstChild("MainFrame") then
        Mega.Objects.GUI.MainFrame.BackgroundTransparency = trans
    end
end)

UI.CreateKeybindButton(TabFrame, "keybind_menu", "Keybinds.Menu", function(key)
    Mega.States.Keybinds.Menu = key
end)

Mega.States.Temp.ShowNotifications = Mega.Settings.System.ShowNotifications
UI.CreateToggle(TabFrame, "toggle_show_notifications", "Temp.ShowNotifications", function(state)
    Mega.Settings.System.ShowNotifications = state
end)

if Mega.Settings.Menu.ShowMenuIcon == nil then
    Mega.Settings.Menu.ShowMenuIcon = true -- Default to true for both platforms
end
Mega.States.Temp.ShowMenuIcon = Mega.Settings.Menu.ShowMenuIcon
UI.CreateToggle(TabFrame, "toggle_menu_icon", "Temp.ShowMenuIcon", function(state)
    Mega.Settings.Menu.ShowMenuIcon = state
    -- Instantly toggle visibility if the GUI exists
    if Mega.Services.CoreGui:FindFirstChild("TumbaMobileToggle") then
        Mega.Services.CoreGui.TumbaMobileToggle.Enabled = state
    end
end)

-- New Mobile HUD Section
UI.CreateSection(TabFrame, "section_settings_mobile_hud")

UI.CreateToggle(TabFrame, "toggle_killaura_mobile_btn", "Combat.Killaura.MobileBtn", function(state)
    if Mega.MobileHUD then Mega.MobileHUD.SetVisible("killaura", state) end
end)

UI.CreateToggle(TabFrame, "toggle_aim_mobile_btn", "AimAssist.MobileBtn", function(state)
    if Mega.MobileHUD then Mega.MobileHUD.SetVisible("aimassist", state) end
end)

UI.CreateToggle(TabFrame, "toggle_scaffold_mobile_btn", "Player.Scaffold.MobileBtn", function(state)
    if Mega.MobileHUD then Mega.MobileHUD.SetVisible("scaffold", state) end
end)
--#endregion

--#region -- Config Management
UI.CreateSection(TabFrame, "section_settings_config")

-- Контейнер для выпадающего списка, чтобы он не падал в конец вкладки при обновлении
local DropdownContainer = Instance.new("Frame")
DropdownContainer.Name = "DropdownContainer"
DropdownContainer.Size = UDim2.new(1, 0, 0, 35)
DropdownContainer.BackgroundTransparency = 1
DropdownContainer.Parent = TabFrame

local configDropdown
local function refreshConfigList()
    local configs = Mega.ConfigSystem.GetList()
    if #configs == 0 then table.insert(configs, "default") end
    if configDropdown then configDropdown:Destroy() end
    
    -- Безопасная проверка: существует ли текущий выбранный конфиг
    local current = Mega.States.Temp.SelectedConfig
    local found = false
    if current then for _, v in ipairs(configs) do if v == current then found = true break end end end
    if not found then Mega.States.Temp.SelectedConfig = configs[1] end
    
    configDropdown = UI.CreateDropdown(DropdownContainer, "dropdown_config_list", "Temp.SelectedConfig", configs, function(val) Mega.States.Temp.SelectedConfig = val end, false)
end

refreshConfigList() -- Initial population

-- Ручное создание поля ввода, чтобы избежать ошибок, если UI.CreateTextBox не существует
local TextBoxFrame = Instance.new("Frame")
TextBoxFrame.Size = UDim2.new(0.95, 0, 0, 35)
TextBoxFrame.BackgroundTransparency = 1
TextBoxFrame.Parent = TabFrame

local TextBoxLabel = Instance.new("TextLabel", TextBoxFrame)
TextBoxLabel.Size = UDim2.new(0.35, 0, 1, 0)
TextBoxLabel.BackgroundTransparency = 1
TextBoxLabel.Text = " " .. Mega.GetText("textbox_config_name")
TextBoxLabel.TextColor3 = Mega.Settings.Menu.TextColor
TextBoxLabel.TextSize = 13
TextBoxLabel.Font = Enum.Font.Gotham
TextBoxLabel.TextXAlignment = Enum.TextXAlignment.Left

local InputBox = Instance.new("TextBox", TextBoxFrame)
InputBox.Size = UDim2.new(0.6, 0, 0, 25)
InputBox.Position = UDim2.new(0.38, 0, 0.5, -12.5)
InputBox.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
InputBox.BorderSizePixel = 0
InputBox.Text = ""
InputBox.PlaceholderText = Mega.GetText("textbox_config_name")
InputBox.TextColor3 = Mega.Settings.Menu.TextColor
InputBox.TextSize = 11
InputBox.TextScaled = true
InputBox.TextWrapped = true
InputBox.Font = Enum.Font.Gotham
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

UI.CreateButton(TabFrame, "button_config_save", function()
    local inputName = InputBox.Text
    local targetName = Mega.States.Temp.SelectedConfig or "default"
    
    -- Если пользователь ввел имя, сохраняем под ним. Иначе - перезаписываем выбранный конфиг.
    if inputName and inputName ~= "" and inputName ~= Mega.GetText("textbox_config_name") then
        targetName = inputName
        Mega.States.Temp.SelectedConfig = targetName -- Автоматически выбираем его
    end
    
    if Mega.ConfigSystem.Save(targetName) then
        pcall(function()
            if writefile then
                if not isfolder("tumbaHub/configs") then pcall(makefolder, "tumbaHub/configs") end
                pcall(writefile, "tumbaHub/configs/LastConfig.txt", targetName)
            end
        end)
        Mega.ShowNotification(Mega.GetText("notify_config_saved") .. " (" .. targetName .. ")", 2)
        InputBox.Text = "" -- Очищаем поле после успешного сохранения
        refreshConfigList()
    end
end)

UI.CreateButton(TabFrame, "button_config_load", function()
    local name = Mega.States.Temp and Mega.States.Temp.SelectedConfig
    if name and name ~= "" then
        Mega.ConfigSystem.Load(name)
        pcall(function()
            if writefile then
                if not isfolder("tumbaHub/configs") then pcall(makefolder, "tumbaHub/configs") end
                pcall(writefile, "tumbaHub/configs/LastConfig.txt", name)
            end
        end)
        Mega.ShowNotification(Mega.GetText("notify_config_loaded"), 2)
        if Mega.ReloadGUI then
            task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end)
        end
    end
end)

UI.CreateButton(TabFrame, "button_config_delete", function()
    local name = Mega.States.Temp and Mega.States.Temp.SelectedConfig
    if name and name ~= "" and name ~= "default" then
        local newPath = "tumbaHub/configs/TumbaConfig_" .. name .. ".json"
        local oldPath = "TumbaConfig_" .. name .. ".json"
        if isfile and isfile(newPath) then
            delfile(newPath)
            Mega.ShowNotification(Mega.GetText("notify_config_deleted"), 2)
                Mega.States.Temp.SelectedConfig = "default"
            refreshConfigList()
        elseif isfile and isfile(oldPath) then
            delfile(oldPath)
            Mega.ShowNotification(Mega.GetText("notify_config_deleted"), 2)
                Mega.States.Temp.SelectedConfig = "default"
            refreshConfigList()
        end
    end
end)

UI.CreateButton(TabFrame, "button_config_refresh", refreshConfigList)
--#endregion

--#region -- Script Cleanup
UI.CreateSection(TabFrame, "button_cleanup")

UI.CreateButton(TabFrame, "button_cleanup", function()
    Mega.ShowNotification(Mega.GetText("notify_cleanup"), 2)
    Mega.Unloaded = true
    -- Disconnect all connections
    for _, c in ipairs(Mega.Objects.Connections) do pcall(c.Disconnect, c) end
    for _, c in pairs(Mega.Objects.ESP or {}) do
        if type(c) == "table" then
            for _, d in pairs(c) do pcall(function() d:Remove() end) end
        end
    end
    -- Destroy all GUI elements
    if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
    if Mega.Services.CoreGui:FindFirstChild("TumbaESP_Container") then Mega.Services.CoreGui.TumbaESP_Container:Destroy() end
    if Mega.Services.CoreGui:FindFirstChild("TumbaStatusIndicator") then Mega.Services.CoreGui.TumbaStatusIndicator:Destroy() end
    -- You might need to restore more original settings here (e.g. from Visuals)
end)
--#endregion
