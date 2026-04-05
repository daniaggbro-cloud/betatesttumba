-- gui/main_window.lua
-- Creates the main GUI window, sidebar, tabs, and status indicator.
-- Handles tab switching and menu visibility.

local Services = Mega.Services
local Settings = Mega.Settings
local States = Mega.States
local GetText = Mega.GetText

function Mega.ReloadGUI()
    -- 1. Очищаем все старые подключения и объекты перед рестартом
    if Mega.Objects and Mega.Objects.Connections then
        for _, conn in pairs(Mega.Objects.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    if Mega.Objects.GUI then
        local wasEnabled = Mega.Objects.GUI.Enabled
        Mega.Objects.GUI:Destroy()
        Mega.Objects.GUI = nil
        
        if Services.CoreGui:FindFirstChild("TumbaStatusIndicator") then
            Services.CoreGui.TumbaStatusIndicator:Destroy()
        end

        -- Очищаем кэш вкладок, чтобы они перерисовались с новым языком
        Mega.Objects.TabFrames = {}
        Mega.Objects.Connections = {}
        Mega.Objects.Toggles = {}
        
        for k in pairs(Mega.LoadedModules) do
            if k:find("^gui/tabs/") then
                Mega.LoadedModules[k] = nil
            end
        end
        
        Mega.InitializeMainGUI()
        
        if Mega.Objects.GUI then
            Mega.Objects.GUI.Enabled = wasEnabled
        end
    end
end

function Mega.InitializeMainGUI()

-- Main GUI container
local TumbaGUI = Instance.new("ScreenGui")
TumbaGUI.Name = "TumbaMegaSystem"
TumbaGUI.Parent = Services.CoreGui
TumbaGUI.Enabled = false
TumbaGUI.ResetOnSpawn = false
TumbaGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
Mega.Objects.GUI = TumbaGUI

-- Draggable Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 1100, 0, 650)
MainFrame.Position = UDim2.new(0.5, -550, 0.5, -325)
MainFrame.BackgroundColor3 = Settings.Menu.BackgroundColor
MainFrame.BackgroundTransparency = Settings.Menu.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = TumbaGUI
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, Settings.Menu.CornerRadius)

-- UI Stroke (Border Glow)
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Settings.Menu.AccentColor
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Settings.Menu.AccentColor
Shadow.ImageTransparency = 0.7
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ZIndex = 0
Shadow.Parent = MainFrame

-- Background Gradient
local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Settings.Menu.BackgroundColor), ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 45)) }
MainGradient.Rotation = 135
MainGradient.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = Settings.Menu.TitleBarColor
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, Settings.Menu.CornerRadius)

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Settings.Menu.AccentColor), ColorSequenceKeypoint.new(1, Settings.Menu.SecondaryColor) }
TitleGradient.Rotation = 90
TitleGradient.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = GetText("title_bar", Mega.VERSION)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextStrokeTransparency = 0.7
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Controls (Close/Minimize)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 38, 0, 38)
CloseButton.Position = UDim2.new(1, -48, 0.5, -19)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 10)
CloseButton.MouseButton1Click:Connect(function() TumbaGUI.Enabled = false end)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 38, 0, 38)
MinimizeButton.Position = UDim2.new(1, -90, 0.5, -19)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.TextSize = 20
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 10)

-- Sidebar & Content
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 200, 1, -65)
Sidebar.Position = UDim2.new(0, 10, 0, 60)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Sidebar.BackgroundTransparency = 0.3
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, -10, 1, -10)
TabContainer.Position = UDim2.new(0, 5, 0, 5)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 0
TabContainer.Parent = Sidebar
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 3)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -230, 1, -70)
ContentContainer.Position = UDim2.new(0, 220, 0, 60)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame
Mega.Objects.ContentContainer = ContentContainer

-- Minimize Logic
local isMinimized = false
local originalSize = MainFrame.Size
local miniSize = UDim2.new(0, 220, 0, 55)
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and miniSize or originalSize
    Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), { Size = targetSize }):Play()
    Sidebar.Visible = not isMinimized
    ContentContainer.Visible = not isMinimized
    Shadow.Visible = not isMinimized
    MinimizeButton.Text = isMinimized and "❐" or "—"
end)

-- Tab System
local TabKeys = { "tab_home", "tab_updates", "tab_esp", "tab_aim", "tab_player", "tab_combat", "tab_bot", "tab_visuals", "tab_farm", "tab_users", "tab_utils", "tab_settings" }
local TabButtons = {}
Mega.Objects.TabFrames = {}

local function SelectTab(tabKey, tabButton)
    -- De-select all other buttons
    for k, btn in pairs(TabButtons) do
        Services.TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(25, 30, 40),
            BackgroundTransparency = 0.3,
            TextColor3 = Color3.fromRGB(180, 180, 200)
        }):Play()
    end
    -- Select the current button
    Services.TweenService:Create(tabButton, TweenInfo.new(0.3), {
        BackgroundColor3 = Settings.Menu.AccentColor,
        BackgroundTransparency = 0,
        TextColor3 = Color3.new(1, 1, 1)
    }):Play()

    -- Hide all other frames
    for k, frame in pairs(Mega.Objects.TabFrames) do
        frame.Visible = false
    end

    -- Load module if it's the first time
    local modulePath = "gui/tabs/" .. tabKey:gsub("^tab_", "") .. ".lua"
    if not Mega.LoadedModules[modulePath] then
        Mega.LoadModule(modulePath)
    end
    
    -- Show the frame for this tab
    if Mega.Objects.TabFrames[tabKey] then
        Mega.Objects.TabFrames[tabKey].Visible = true
    end

    Title.Text = GetText("title_bar_with_tab", GetText(tabKey))
end

for _, tabKey in ipairs(TabKeys) do
    local tabName = GetText(tabKey)
    local TabButton = Instance.new("TextButton", TabContainer)
    TabButton.Name = tabKey
    TabButton.Size = UDim2.new(1, -10, 0, 42)
    TabButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    TabButton.BackgroundTransparency = 0.3
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 200)
    TabButton.TextSize = 14
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", TabButton).PaddingLeft = UDim.new(0, 15)
    
    TabButton.MouseButton1Click:Connect(function() SelectTab(tabKey, TabButton) end)
    TabButtons[tabKey] = TabButton
end

-- Select the first tab by default
task.wait(0.1)
SelectTab("tab_home", TabButtons["tab_home"])

-- === ФОНОВАЯ ПРОГРУЗКА ВСЕХ ВКЛАДОК ===
-- Прогружаем модули с небольшим КД, чтобы функции из конфига активировались автоматически
task.spawn(function()
    for _, tabKey in ipairs(TabKeys) do
        local modulePath = "gui/tabs/" .. tabKey:gsub("^tab_", "") .. ".lua"
        if not Mega.LoadedModules[modulePath] then
            pcall(function() Mega.LoadModule(modulePath) end)
            task.wait(0.15) -- КД 150мс между прогрузкой вкладок, чтобы избежать фризов игры
        end
    end
end)

-- Keybinds Logic
Mega.Objects.Connections.MainWindowKeybinds = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode.Name
    
    if key == States.Keybinds.Menu and key ~= "None" then
        TumbaGUI.Enabled = not TumbaGUI.Enabled
    end
    
    if key == States.Keybinds.Killaura and key ~= "None" then
        local newState = not States.Combat.Killaura.Enabled
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_killaura"] then
            Mega.Objects.Toggles["toggle_killaura"](newState)
        else
            States.Combat.Killaura.Enabled = newState
            if Mega.Features.Killaura and Mega.Features.Killaura.SetEnabled then Mega.Features.Killaura.SetEnabled(newState) end
            if Mega.ShowNotification then Mega.ShowNotification((GetText("toggle_killaura") or "Killaura") .. ": " .. (newState and GetText("notify_enabled") or GetText("notify_disabled")), 2) end
        end
    end
    
    if key == States.Keybinds.Scaffold and key ~= "None" then
        local newState = not States.Player.Scaffold.Enabled
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_scaffold"] then
            Mega.Objects.Toggles["toggle_scaffold"](newState)
        else
            States.Player.Scaffold.Enabled = newState
            if Mega.Features.Scaffold and Mega.Features.Scaffold.SetEnabled then Mega.Features.Scaffold.SetEnabled(newState) end
            if Mega.ShowNotification then Mega.ShowNotification((GetText("toggle_scaffold") or "Scaffold") .. ": " .. (newState and GetText("notify_enabled") or GetText("notify_disabled")), 2) end
        end
    end
end)

-- Status Indicator GUI
if Services.CoreGui:FindFirstChild("TumbaStatusIndicator") then
    Services.CoreGui.TumbaStatusIndicator:Destroy()
end

local StatusGUI = Instance.new("ScreenGui", Services.CoreGui)
StatusGUI.Name = "TumbaStatusIndicator"
StatusGUI.ResetOnSpawn = false
StatusGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local StatusIndicator = Instance.new("Frame", StatusGUI)
StatusIndicator.Name = "StatusList"
StatusIndicator.Size = UDim2.new(0, 200, 1, 0)
StatusIndicator.Position = UDim2.new(1, -210, 0, 10)
StatusIndicator.BackgroundTransparency = 1
local StatusLayout = Instance.new("UIListLayout", StatusIndicator)
StatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
StatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatusLayout.Padding = UDim.new(0, 4)

local Watermark = Instance.new("TextLabel", StatusIndicator)
Watermark.Name = "Watermark"
Watermark.Text = "TUMBA HUB"
Watermark.Font = Enum.Font.GothamBlack
Watermark.TextSize = 22
Watermark.TextColor3 = Settings.Menu.AccentColor
Watermark.Size = UDim2.new(1, 0, 0, 30)
Watermark.BackgroundTransparency = 1
Watermark.TextXAlignment = Enum.TextXAlignment.Right
Watermark.LayoutOrder = -1
Instance.new("UIStroke", Watermark).Thickness = 2

-- Function to update the status list (will be called by features)
function Mega.UpdateStatus()
    if not Settings.System.ShowStatusIndicator then
        StatusIndicator.Visible = false
        return
    end
    StatusIndicator.Visible = true

    if Settings.StatusIndicator.RainbowMode then
        Watermark.TextColor3 = Color3.fromHSV((tick() % 5) / 5, 0.8, 1)
    else
        Watermark.TextColor3 = Settings.Menu.AccentColor
    end

    for _, child in pairs(StatusIndicator:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local activeCount = 0
    local function AddStatus(text, color)
        local item = Instance.new("Frame", StatusIndicator)
        item.Size = UDim2.new(0, Services.TextService:GetTextSize(text, 14, Enum.Font.GothamBold, Vector2.new(1000, 1000)).X + 24, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        item.BackgroundTransparency = 0.3
        item.LayoutOrder = activeCount
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
        
        local bar = Instance.new("Frame", item)
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.Position = UDim2.new(1, -3, 0, 0)
        bar.BackgroundColor3 = color or Settings.Menu.AccentColor
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel", item)
        label.Size = UDim2.new(1, -10, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1,1,1)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Right
        Instance.new("UIStroke", label).Thickness = 1
        activeCount = activeCount + 1
    end

    if States.ESP.Enabled then AddStatus("ESP", Settings.Menu.SecondaryColor) end
    if States.KitESP.Enabled then AddStatus("Kit ESP", Color3.fromRGB(255, 165, 0)) end
    if States.AimAssist.Enabled then AddStatus("Aim Assist", Settings.Menu.AccentColor) end
    if States.Player.Speed then AddStatus("Speed", Color3.fromRGB(255, 220, 0)) end
    if States.Player.Fly then AddStatus("Fly", Color3.fromRGB(100, 200, 255)) end
    if States.Player.NoClip then AddStatus("NoClip", Color3.fromRGB(150, 255, 150)) end
end

-- Auto-update status
Mega.Objects.Connections.MainWindowStatusUpdate = Services.RunService.RenderStepped:Connect(function()
    if TumbaGUI.Enabled then
        Mega.UpdateStatus()
    end
end)

-- Mobile Toggle GUI
if Services.CoreGui:FindFirstChild("TumbaMobileToggle") then
    Services.CoreGui.TumbaMobileToggle:Destroy()
end

-- Premium Mobile Button GUI
local MobileGUI = Instance.new("ScreenGui", Services.CoreGui)
MobileGUI.Name = "TumbaMobileToggle"
MobileGUI.ResetOnSpawn = false
MobileGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global

local ToggleButton = Instance.new("ImageButton", MobileGUI)
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.5, -25, 0, 20) -- Center Top
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Image = "rbxassetid://6031090990" -- Sleek menu icon
ToggleButton.ImageColor3 = Color3.new(1, 1, 1)
ToggleButton.Active = true

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0) -- Circular

local btnStroke = Instance.new("UIStroke", ToggleButton)
btnStroke.Color = Settings.Menu.AccentColor
btnStroke.Thickness = 2.5
btnStroke.Transparency = 0.1

-- Glowing drop shadow
local shadow = Instance.new("ImageLabel", ToggleButton)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Settings.Menu.AccentColor
shadow.ImageTransparency = 0.6
shadow.ZIndex = -1

-- Custom Smooth Drag Logic (Replaces deprecated Draggable)
local dragging, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)
Services.UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Services.TweenService:Create(ToggleButton, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end
end)
Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Click logic
ToggleButton.MouseButton1Click:Connect(function()
    TumbaGUI.Enabled = not TumbaGUI.Enabled
end)

-- Dynamic Updater
Mega.Objects.Connections.MobileColorUpdate = Services.RunService.RenderStepped:Connect(function()
    btnStroke.Color = Settings.Menu.AccentColor
    shadow.ImageColor3 = Settings.Menu.AccentColor
    
    -- Sync visibility with Settings
    local showBtn = Settings.Menu.ShowMobileButton
    if showBtn == nil then showBtn = Services.UserInputService.TouchEnabled end
    MobileGUI.Enabled = showBtn
    
    -- Visual feedback based on open state
    if TumbaGUI.Enabled then
        btnStroke.Transparency = 0.1
        shadow.ImageTransparency = 0.4
    else
        btnStroke.Transparency = 0.3
        shadow.ImageTransparency = 0.8
    end
end)

end -- End of Mega.InitializeMainGUI

local function LoadStartupConfig()
    if not Mega.ConfigSystem or not Mega.ConfigSystem.Load then return end
    pcall(function()
        if isfile and readfile and isfile("tumbaHub/configs/LastConfig.txt") then
            local lastConf = readfile("tumbaHub/configs/LastConfig.txt")
            if lastConf and lastConf ~= "" then
                Mega.ConfigSystem.Load(lastConf)
            end
        end
    end)
    -- Загружаем autosave поверх, чтобы восстановить точное состояние до телепорта
    Mega.ConfigSystem.Load("autosave")
end

if not Mega.HasSavedLanguage() then
    local LanguagePrompt = Instance.new("ScreenGui")
    LanguagePrompt.Name = "LanguagePrompt"
    LanguagePrompt.Parent = Services.CoreGui
    LanguagePrompt.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(0, 300, 0, 470)
    Background.Position = UDim2.new(0.5, -150, 0.5, -210)
    Background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Background.BorderSizePixel = 0
    Instance.new("UICorner", Background).CornerRadius = UDim.new(0, 10)
    Background.Parent = LanguagePrompt

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Text = "TUMBA v5.0 - Select Language"
    Title.TextXAlignment = Enum.TextXAlignment.Center
    Title.Parent = Background

    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, 0, 0, 400)
    ButtonContainer.Position = UDim2.new(0, 0, 0, 70)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = Background

    local ButtonLayout = Instance.new("UIListLayout", ButtonContainer)
    ButtonLayout.FillDirection = Enum.FillDirection.Vertical
    ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ButtonLayout.Padding = UDim.new(0, 10)

    local function OnLanguageSelected(lang)
        Mega.Localization.CurrentLanguage = lang
        Mega.SaveLanguage(lang)
        LoadStartupConfig()
        LanguagePrompt:Destroy()
        if Mega.ShowNotification then
            Mega.ShowNotification("Меню открывается на RightShift", 5)
        end
        Mega.InitializeMainGUI()
    end

    local languages = {
        { Name = "English", Code = "en" }, { Name = "Русский", Code = "ru" },
        { Name = "Українська", Code = "uk" }, { Name = "Español", Code = "es" },
        { Name = "Português", Code = "pt" }, { Name = "한국어", Code = "ko" },
        { Name = "日本語", Code = "ja" }
    }

    for _, lang in ipairs(languages) do
        local btn = Instance.new("TextButton", ButtonContainer)
        btn.Size = UDim2.new(0, 250, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = lang.Name
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function() OnLanguageSelected(lang.Code) end)
    end
else
    LoadStartupConfig()
    if Mega.ShowNotification then
        Mega.ShowNotification("Меню открывается на RightShift", 5)
    end
    Mega.InitializeMainGUI()
end
