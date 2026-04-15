-- gui/main_window.lua
-- Creates the main GUI window, sidebar, tabs, and status indicator.
-- Handles tab switching and menu visibility.

local Services = Mega.Services
local Settings = Mega.Settings
local States = Mega.States
local GetText = Mega.GetText
local iconBaseUrl = "https://raw.githubusercontent.com/daniaggbro-cloud/betatesttumba/main/TumbaHub-main%20(3)/TumbaHub-main/tumbaHub/icon/"

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

local isMobile = Services.UserInputService.TouchEnabled

-- Draggable Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 1100, 0, 650)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

-- UIScale for smart responsiveness
local MenuScale = Instance.new("UIScale", MainFrame)
Mega.Objects.MenuScale = MenuScale

local function UpdateScale()
    local viewportSize = Services.Workspace.CurrentCamera.ViewportSize
    -- Detection: Touch enabled but NO keyboard = Phone/Tablet
    local isRealMobile = Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
    
    local baseWidth = 1100
    local baseHeight = 650
    
    local scaleX = viewportSize.X / (baseWidth + 50)
    local scaleY = viewportSize.Y / (baseHeight + 50)
    local targetScale = math.min(scaleX, scaleY)
    
    if isRealMobile then
        -- On mobile, we want to use as much screen as possible while staying centered
        targetScale = math.clamp(targetScale, 0.4, 0.95)
    else
        targetScale = math.clamp(targetScale, 0.5, 1)
    end
    
    MenuScale.Scale = targetScale
end

UpdateScale()
Mega.Objects.Connections.MenuScaleUpdate = Services.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
MainFrame.BackgroundColor3 = Settings.Menu.BackgroundColor
MainFrame.BackgroundTransparency = Settings.Menu.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = TumbaGUI

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 15)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Settings.Menu.AccentColor
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.6

local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Settings.Menu.SectionGradient1),
    ColorSequenceKeypoint.new(1, Settings.Menu.SectionGradient2)
}
MainGradient.Rotation = 90

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

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, -220, 0, 50) -- Adjusted for new sidebar
TitleBar.Position = UDim2.new(0, 220, 0, 5)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = GetText("title_bar", Settings.System.Version)
Title.TextColor3 = Settings.Menu.TextColor
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Canvas Group for smooth fade/minimize (Linux Style)
local WindowCanvas = Instance.new("CanvasGroup", MainFrame)
WindowCanvas.Size = UDim2.new(1, 0, 1, 0)
WindowCanvas.BackgroundTransparency = 1
WindowCanvas.BorderSizePixel = 0

local MinimizeButton = Instance.new("ImageButton", MainFrame)
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 26, 0, 26) -- Slightly more refined size
MinimizeButton.Position = UDim2.new(1, -38, 0, 12)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Image = Mega.GetImageFromURL(iconBaseUrl .. "minimize.png", "minimize.png")
MinimizeButton.ImageColor3 = Settings.Menu.AccentColor

local btnCorner = Instance.new("UICorner", MinimizeButton)
btnCorner.CornerRadius = UDim.new(1, 0)

local btnStroke = Instance.new("UIStroke", MinimizeButton)
btnStroke.Color = Settings.Menu.AccentColor
btnStroke.Thickness = 1.5
btnStroke.Transparency = 0.6
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

MinimizeButton.MouseEnter:Connect(function()
    Services.TweenService:Create(MinimizeButton, TweenInfo.new(0.3), { ImageTransparency = 0, Rotation = 90 }):Play()
    Services.TweenService:Create(btnStroke, TweenInfo.new(0.3), { Transparency = 0.2, Thickness = 2 }):Play()
end)
MinimizeButton.MouseLeave:Connect(function()
    Services.TweenService:Create(MinimizeButton, TweenInfo.new(0.3), { ImageTransparency = 0.2, Rotation = 0 }):Play()
    Services.TweenService:Create(btnStroke, TweenInfo.new(0.3), { Transparency = 0.6, Thickness = 1.5 }):Play()
end)

MinimizeButton.Parent = TitleBar
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 10)

-- Sidebar & Content
-- Move elements into Canvas for clean animation
TitleBar.Parent = WindowCanvas

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 210, 1, -10) -- Full height sidebar
Sidebar.Position = UDim2.new(0, 5, 0, 5)
Sidebar.BackgroundColor3 = Settings.Menu.SidebarColor
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
Sidebar.Parent = WindowCanvas
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

-- User Profile Widget
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Name = "UserProfile"
UserProfile.Size = UDim2.new(1, -20, 0, 60)
UserProfile.Position = UDim2.new(0, 10, 0, 10)
UserProfile.BackgroundTransparency = 1

local AvatarImage = Instance.new("ImageLabel", UserProfile)
AvatarImage.Size = UDim2.new(0, 44, 0, 44)
AvatarImage.Position = UDim2.new(0, 5, 0.5, -22)
AvatarImage.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Services.Players.LocalPlayer.UserId .. "&w=150&h=150"
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", AvatarImage).Color = Settings.Menu.AccentColor

local UserName = Instance.new("TextLabel", UserProfile)
UserName.Size = UDim2.new(1, -60, 0, 20)
UserName.Position = UDim2.new(0, 55, 0.5, -12)
UserName.BackgroundTransparency = 1
UserName.Text = Services.Players.LocalPlayer.Name
UserName.TextColor3 = Color3.new(1, 1, 1)
UserName.TextSize = 14
UserName.Font = Enum.Font.GothamBold
UserName.TextXAlignment = Enum.TextXAlignment.Left

local UserStatus = Instance.new("TextLabel", UserProfile)
UserStatus.Size = UDim2.new(1, -60, 0, 15)
UserStatus.Position = UDim2.new(0, 55, 0.5, 5)
UserStatus.BackgroundTransparency = 1
UserStatus.Text = GetText("user_status_beloved")
UserStatus.TextColor3 = Settings.Menu.AccentColor
UserStatus.TextSize = 10
UserStatus.Font = Enum.Font.GothamSemibold
UserStatus.TextXAlignment = Enum.TextXAlignment.Left

local Separator = Instance.new("Frame", Sidebar)
Separator.Size = UDim2.new(1, -30, 0, 1)
Separator.Position = UDim2.new(0, 15, 0, 75)
Separator.BackgroundColor3 = Color3.new(1, 1, 1)
Separator.BackgroundTransparency = 0.8
Separator.BorderSizePixel = 0

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, -10, 1, -90)
TabContainer.Position = UDim2.new(0, 5, 0, 85)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 0
TabContainer.Parent = Sidebar
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -235, 1, -70)
ContentContainer.Position = UDim2.new(0, 225, 0, 60)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = WindowCanvas
Mega.Objects.ContentContainer = ContentContainer

-- Minimize Logic (Linux Style Genie Animation)
local isMinimized = false
local originalSize = MainFrame.Size
local originalPos = MainFrame.Position
local miniSize = UDim2.new(0, 40, 0, 40)

local function ToggleMenu(state)
    if state == nil then state = not TumbaGUI.Enabled end
    TumbaGUI.Enabled = state
    
    if state then
        -- Restore animation
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 10, 0, 10)
        WindowCanvas.GroupTransparency = 1
        
        Services.TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = originalSize,
            Position = originalPos
        }):Play()
        Services.TweenService:Create(WindowCanvas, TweenInfo.new(0.5), { GroupTransparency = 0 }):Play()
    end
end

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    -- Animate to the corner where the icon usually is
    local targetPos = UDim2.new(1, -50, 0, 50) 
    
    Services.TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = miniSize,
        Position = targetPos
    }):Play()
    
    Services.TweenService:Create(WindowCanvas, TweenInfo.new(0.4), { GroupTransparency = 1 }):Play()
    
    task.delay(0.5, function()
        if isMinimized then
            ToggleMenu(false)
            -- Reset for next time
            MainFrame.Size = originalSize
            MainFrame.Position = originalPos
            WindowCanvas.GroupTransparency = 0
            isMinimized = false
        end
    end)
end)

-- Tab Icons Mapping (GitHub Paths)
Mega.Icons = {
    ["tab_home"] = iconBaseUrl .. "home.png",
    ["tab_esp"] = iconBaseUrl .. "esp.png",
    ["tab_aim"] = iconBaseUrl .. "aim.png",
    ["tab_player"] = iconBaseUrl .. "player.png",
    ["tab_combat"] = iconBaseUrl .. "combat.png",
    ["tab_visuals"] = iconBaseUrl .. "visuals.png",
    ["tab_farm"] = iconBaseUrl .. "kit.png",
    ["tab_users"] = iconBaseUrl .. "users.png",
    ["tab_utils"] = iconBaseUrl .. "utils.png",
    ["tab_settings"] = iconBaseUrl .. "settings.png",
    ["tab_bot"] = iconBaseUrl .. "bot.png",
    ["tab_ai_chat"] = iconBaseUrl .. "ai_chat.png"
}

-- Tab System
local TabKeys = { "tab_home", "tab_esp", "tab_aim", "tab_player", "tab_combat", "tab_visuals", "tab_farm", "tab_users", "tab_utils", "tab_settings", "tab_bot", "tab_ai_chat" }
local TabButtons = {}
Mega.Objects.TabFrames = {}

local function SelectTab(tabKey, tabButton)
    local indicator = tabButton:FindFirstChild("Indicator")
    
    -- De-select all other buttons
    for k, btn in pairs(TabButtons) do
        local otherInd = btn:FindFirstChild("Indicator")
        local tabText = btn:FindFirstChild("TabText")
        local icon = btn:FindFirstChild("Icon")
        if otherInd then
            Services.TweenService:Create(otherInd, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0.6, 0), BackgroundTransparency = 1 }):Play()
        end
        if icon then
            Services.TweenService:Create(icon, TweenInfo.new(0.3), { ImageColor3 = Settings.Menu.IconColor, ImageTransparency = 0.3 }):Play()
        end
        if tabText then
            Services.TweenService:Create(tabText, TweenInfo.new(0.3), { TextColor3 = Settings.Menu.TextMutedColor }):Play()
        end
        Services.TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = Settings.Menu.ElementColor,
            BackgroundTransparency = 0.5
        }):Play()
    end
    
    -- Select the current button
    if indicator then
        Services.TweenService:Create(indicator, TweenInfo.new(0.3), { Size = UDim2.new(0, 4, 0.6, 0), BackgroundTransparency = 0 }):Play()
    end
    local currentIcon = tabButton:FindFirstChild("Icon")
    if currentIcon then
        Services.TweenService:Create(currentIcon, TweenInfo.new(0.3), { ImageColor3 = Settings.Menu.IconActiveColor, ImageTransparency = 0 }):Play()
    end
    local currentText = tabButton:FindFirstChild("TabText")
    if currentText then
        Services.TweenService:Create(currentText, TweenInfo.new(0.3), { TextColor3 = Settings.Menu.TextColor }):Play()
    end
    Services.TweenService:Create(tabButton, TweenInfo.new(0.3), {
        BackgroundColor3 = Settings.Menu.AccentColor,
        BackgroundTransparency = 0.8, -- Subtle highlight
        TextColor3 = Settings.Menu.TextColor
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
        local frame = Mega.Objects.TabFrames[tabKey]
        frame.Visible = true
    end

    Title.Text = GetText("title_bar_with_tab", GetText(tabKey))
end

for _, tabKey in ipairs(TabKeys) do
    local tabName = GetText(tabKey)
    local TabButton = Instance.new("TextButton", TabContainer)
    TabButton.Name = tabKey
    TabButton.Size = UDim2.new(1, -10, 0, 40)
    TabButton.BackgroundColor3 = Settings.Menu.ElementColor
    TabButton.BackgroundTransparency = 0.5
    TabButton.Text = tabName
    TabButton.TextColor3 = Settings.Menu.TextMutedColor
    TabButton.TextSize = 13
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.Text = "" -- Clear standard text
    TabButton.AutoButtonColor = false
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 8)
    
    local Icon = Instance.new("ImageLabel", TabButton)
    Icon.Name = "Icon"
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.Position = UDim2.new(0, 15, 0.5, -10)
    Icon.BackgroundTransparency = 1
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.Image = Mega.GetImageFromURL(Mega.Icons[tabKey] or "", tabKey .. ".png")
    Icon.ImageColor3 = Settings.Menu.IconColor
    Icon.ImageTransparency = 0.3
    
    local TabText = Instance.new("TextLabel", TabButton)
    TabText.Name = "TabText"
    TabText.Size = UDim2.new(1, -50, 1, 0)
    TabText.Position = UDim2.new(0, 50, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = GetText(tabKey)
    TabText.TextColor3 = Settings.Menu.TextMutedColor
    TabText.TextSize = 14
    TabText.Font = Enum.Font.GothamBold
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    
    local Indicator = Instance.new("Frame", TabButton)
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 0, 0.6, 0)
    Indicator.Position = UDim2.new(0, -15, 0.2, 0)
    Indicator.BackgroundColor3 = Settings.Menu.AccentColor
    Indicator.BackgroundTransparency = 1
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
    
    TabButton.MouseEnter:Connect(function()
        if Title.Text:find(GetText(tabKey)) then return end
        Services.TweenService:Create(TabButton, TweenInfo.new(0.3), { BackgroundTransparency = 0.3 }):Play()
        Services.TweenService:Create(TabText, TweenInfo.new(0.3), { TextColor3 = Settings.Menu.TextColor }):Play()
        Services.TweenService:Create(Icon, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
    end)
    TabButton.MouseLeave:Connect(function()
        if Title.Text:find(GetText(tabKey)) then return end
        Services.TweenService:Create(TabButton, TweenInfo.new(0.3), { BackgroundTransparency = 0.5 }):Play()
        Services.TweenService:Create(TabText, TweenInfo.new(0.3), { TextColor3 = Settings.Menu.TextMutedColor }):Play()
        Services.TweenService:Create(Icon, TweenInfo.new(0.3), { ImageTransparency = 0.3 }):Play()
    end)
    
    TabButton.MouseButton1Click:Connect(function() SelectTab(tabKey, TabButton) end)
    TabButtons[tabKey] = TabButton
end

-- Select the first tab by default
task.wait(0.1)
SelectTab("tab_home", TabButtons["tab_home"])

-- === ФОНОВАЯ ПРОГРУЗКА ВСЕХ ВКЛАДОК ===
task.spawn(function()
    for _, tabKey in ipairs(TabKeys) do
        local modulePath = "gui/tabs/" .. tabKey:gsub("^tab_", "") .. ".lua"
        if not Mega.LoadedModules[modulePath] then
            pcall(function() Mega.LoadModule(modulePath) end)
            task.wait(0.15)
        end
    end
end)

-- Keybinds Logic
Mega.Objects.Connections.MainWindowKeybinds = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode.Name
    
    if key == States.Keybinds.Menu and key ~= "None" then
        ToggleMenu()
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
StatusIndicator.Position = UDim2.new(1, -210, 0, 70)
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

Mega.Objects.Connections.MainWindowStatusUpdate = Services.RunService.RenderStepped:Connect(function()
    if TumbaGUI.Enabled then
        Mega.UpdateStatus()
    end
    
    if workspace.CurrentCamera then
        local vp = workspace.CurrentCamera.ViewportSize
        if vp.X > 0 and vp.Y > 0 then
            local scaleX = (vp.X * 0.95) / 1100
            local scaleY = (vp.Y * 0.90) / 650
            MenuScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.3, 1)
        end
    end
end)

-- Mobile Toggle GUI
if Services.CoreGui:FindFirstChild("TumbaMobileToggle") then
    Services.CoreGui.TumbaMobileToggle:Destroy()
end

local MobileGUI = Instance.new("ScreenGui", Services.CoreGui)
MobileGUI.Name = "TumbaMobileToggle"
MobileGUI.ResetOnSpawn = false
MobileGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global

local ToggleButton = Instance.new("ImageButton", MobileGUI)
ToggleButton.Name = "TumbaMenuIcon"
ToggleButton.Size = UDim2.new(0, 42, 0, 42)
ToggleButton.AnchorPoint = Vector2.new(1, 0)
ToggleButton.Position = UDim2.new(1, -15, 0, 15)
ToggleButton.BackgroundTransparency = 1 
ToggleButton.Image = Mega.GetImageFromURL(iconBaseUrl .. "minimize.png", "minimize.png")
ToggleButton.ImageColor3 = Settings.Menu.AccentColor
ToggleButton.Active = true

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local btnStroke = Instance.new("UIStroke", ToggleButton)
btnStroke.Color = Settings.Menu.AccentColor
btnStroke.Thickness = 1.5
btnStroke.Transparency = 0.6
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local dragging = false
local dragStart = nil
local startPos = nil
local hasDragged = false

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        hasDragged = false
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)

Services.UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then
            hasDragged = true
        end
        Services.TweenService:Create(ToggleButton, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end
end)

Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            if not hasDragged then
                ToggleMenu()
            end
        end
    end
end)

Mega.Objects.Connections.MobileColorUpdate = Services.RunService.RenderStepped:Connect(function()
    btnStroke.Color = Settings.Menu.AccentColor
    ToggleButton.ImageColor3 = Settings.Menu.AccentColor
    
    local showBtn = Settings.Menu.ShowMenuIcon
    if showBtn == nil then showBtn = false end
    MobileGUI.Enabled = showBtn
    
    if TumbaGUI.Enabled then
        btnStroke.Transparency = 0.4
        Services.TweenService:Create(ToggleButton, TweenInfo.new(0.3), { Rotation = 180, ImageTransparency = 0 }):Play()
    else
        btnStroke.Transparency = 0.7 
        Services.TweenService:Create(ToggleButton, TweenInfo.new(0.3), { Rotation = 0, ImageTransparency = 0.2 }):Play()
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
    
    local LangScale = Instance.new("UIScale", Background)
    local LangScaleUpdate = Services.RunService.RenderStepped:Connect(function()
        if workspace.CurrentCamera then
            local vp = workspace.CurrentCamera.ViewportSize
            if vp.X > 0 and vp.Y > 0 then
                local scaleX = (vp.X * 0.95) / 300
                local scaleY = (vp.Y * 0.90) / 470
                LangScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.3, 1)
            end
        end
    end)
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
        pcall(function() LangScaleUpdate:Disconnect() end)
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
