    -- gui/main_window.lua
-- Creates the main GUI window for TumbaHub: BedWars Edition
-- Restored and optimized by Antigravity

local Services = Mega.Services
local Settings = Mega.Settings
local States = Mega.States
local GetText = Mega.GetText

function Mega.ReloadGUI()
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

local TumbaGUI = Instance.new("ScreenGui")
TumbaGUI.Name = "TumbaMegaSystem"
TumbaGUI.Parent = Services.CoreGui
TumbaGUI.Enabled = false
TumbaGUI.ResetOnSpawn = false
TumbaGUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
Mega.Objects.GUI = TumbaGUI

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 950, 0, 600)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Settings.Menu.BackgroundColor
MainFrame.BackgroundTransparency = Settings.Menu.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = TumbaGUI

local MenuScale = Instance.new("UIScale", MainFrame)
Mega.Objects.MenuScale = MenuScale

local function UpdateScale()
    local vp = Services and Services.Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local scaleX = vp.X / 1100
    local scaleY = vp.Y / 700
    MenuScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.5, 1)
end
UpdateScale()

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Settings.Menu.AccentColor
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.6

-- Window Canvas for animations
local WindowCanvas = Instance.new("CanvasGroup", MainFrame)
WindowCanvas.Size = UDim2.new(1, 0, 1, 0)
WindowCanvas.BackgroundTransparency = 1
WindowCanvas.BorderSizePixel = 0

-- Sidebar
local Sidebar = Instance.new("Frame", WindowCanvas)
Sidebar.Size = UDim2.new(0, 220, 1, -10)
Sidebar.Position = UDim2.new(0, 5, 0, 5)
Sidebar.BackgroundColor3 = Settings.Menu.SidebarColor
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

-- Profile
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Size = UDim2.new(1, -20, 0, 50)
UserProfile.Position = UDim2.new(0, 10, 0, 10)
UserProfile.BackgroundTransparency = 1

local AvatarImage = Instance.new("ImageLabel", UserProfile)
AvatarImage.Size = UDim2.new(0, 36, 0, 36)
AvatarImage.Position = UDim2.new(0, 5, 0.5, -18)
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Services.Players.LocalPlayer.UserId .. "&w=150&h=150"
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)

local UserName = Instance.new("TextLabel", UserProfile)
UserName.Size = UDim2.new(1, -50, 1, 0)
UserName.Position = UDim2.new(0, 50, 0, 0)
UserName.BackgroundTransparency = 1
UserName.Text = Services.Players.LocalPlayer.DisplayName or Services.Players.LocalPlayer.Name
UserName.TextColor3 = Color3.new(1, 1, 1)
UserName.Font = Enum.Font.GothamBold
UserName.TextSize = 14
UserName.TextXAlignment = Enum.TextXAlignment.Left

local TabContainer = Instance.new("ScrollingFrame", Sidebar)
TabContainer.Size = UDim2.new(1, -10, 1, -80)
TabContainer.Position = UDim2.new(0, 5, 0, 70)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 2
TabContainer.ScrollBarImageColor3 = Settings.Menu.AccentColor
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 4)

local ContentContainer = Instance.new("Frame", WindowCanvas)
ContentContainer.Size = UDim2.new(1, -240, 1, -60)
ContentContainer.Position = UDim2.new(0, 230, 0, 50)
ContentContainer.BackgroundTransparency = 1
Mega.Objects.ContentContainer = ContentContainer

local Title = Instance.new("TextLabel", WindowCanvas)
Title.Size = UDim2.new(1, -240, 0, 40)
Title.Position = UDim2.new(0, 235, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = GetText("title_bar", Settings.System.Version)
Title.TextColor3 = Settings.Menu.TextColor
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Tab Logic
local TabKeys = { 
    "tab_home", "tab_combat", "tab_esp", "tab_aim", 
    "tab_bot", "tab_farm", "tab_player", "tab_visuals", 
    "tab_utils", "tab_users", "tab_ai_chat", "tab_settings" 
}
local TabButtons = {}
Mega.Objects.TabFrames = {}

local function SelectTab(tabKey, tabButton)
    print("Selecting tab: " .. tabKey)
    for k, btn in pairs(TabButtons) do
        local isSelected = k == tabKey
        Services.TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = isSelected and Settings.Menu.AccentColor or Settings.Menu.ElementColor,
            BackgroundTransparency = isSelected and 0.8 or 0.5
        }):Play()
        local txt = btn:FindFirstChildOfClass("TextLabel")
        if txt then txt.TextColor3 = isSelected and Color3.new(1,1,1) or Settings.Menu.TextMutedColor end
    end

    for k, frame in pairs(Mega.Objects.TabFrames) do frame.Visible = false end

    local modulePath = "gui/tabs/" .. tabKey:gsub("^tab_", "") .. ".lua"
    if not Mega.LoadedModules[modulePath] then
        Mega.LoadModule(modulePath)
    end
    
    if Mega.Objects.TabFrames[tabKey] then
        Mega.Objects.TabFrames[tabKey].Visible = true
    end
end

for _, tabKey in ipairs(TabKeys) do
    local TabButton = Instance.new("TextButton", TabContainer)
    TabButton.Size = UDim2.new(1, 0, 0, 36)
    TabButton.BackgroundColor3 = Settings.Menu.ElementColor
    TabButton.BackgroundTransparency = 0.5
    TabButton.Text = ""
    TabButton.AutoButtonColor = false
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    
    local TabText = Instance.new("TextLabel", TabButton)
    TabText.Size = UDim2.new(1, -15, 1, 0)
    TabText.Position = UDim2.new(0, 15, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = GetText(tabKey)
    TabText.TextColor3 = Settings.Menu.TextMutedColor
    TabText.Font = Enum.Font.GothamBold
    TabText.TextSize = 13
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    
    TabButton.MouseButton1Click:Connect(function() SelectTab(tabKey, TabButton) end)
    TabButtons[tabKey] = TabButton
end

-- Toggle Logic (Keybinds)
local function ToggleMenu(state)
    if state == nil then state = not TumbaGUI.Enabled end
    TumbaGUI.Enabled = state
end

Mega.Objects.Connections.MainWindowKeybinds = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode.Name == States.Keybinds.Menu then
        ToggleMenu()
    end
end)

-- Default Tab
task.wait(0.1)
SelectTab("tab_home", TabButtons["tab_home"])

-- Mobile Button
if Services.UserInputService.TouchEnabled then
    local MobileGUI = Instance.new("ScreenGui", Services.CoreGui)
    MobileGUI.Name = "TumbaMobileToggle"
    local MB = Instance.new("ImageButton", MobileGUI)
    MB.Size = UDim2.new(0, 50, 0, 50)
    MB.Position = UDim2.new(1, -60, 0.4, 0)
    MB.BackgroundColor3 = Settings.Menu.AccentColor
    MB.Image = "rbxassetid://13388222306"
    MB.Draggable = true
    Instance.new("UICorner", MB).CornerRadius = UDim.new(1, 0)
    MB.MouseButton1Click:Connect(function() ToggleMenu() end)
end

end -- End InitializeMainGUI

Mega.InitializeMainGUI()
