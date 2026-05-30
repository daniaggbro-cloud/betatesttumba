-- library/notifications.lua
-- A modern notification system.

local CoreGui = Mega.Services.CoreGui
local Debris = Mega.Services.Debris
local TweenService = Mega.Services.TweenService

function Mega.ShowNotification(message, duration, color)
    duration = duration or 3
    color = color or Mega.Settings.Menu.AccentColor

    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "TumbaGlobalNotification"
    NotifGui.Parent = CoreGui
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 250, 0, 50)
    container.Position = UDim2.new(1, 0, 1, 0) -- Start off-screen
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    container.BackgroundTransparency = 0.2
    container.BorderSizePixel = 0
    container.Parent = NotifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = color
    stroke.Transparency = 0.5
    stroke.Parent = container
    
    local sideBar = Instance.new("Frame")
    sideBar.Size = UDim2.new(0, 5, 1, 0)
    sideBar.BackgroundColor3 = color
    sideBar.BorderSizePixel = 0
    sideBar.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Mega.Settings.Menu.TextColor
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.Text = message
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = container

    -- Find the vertical position for the new notification
    local existingNotifs = 0
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "TumbaGlobalNotification" and child ~= NotifGui then
            existingNotifs = existingNotifs + 1
        end
    end

    local targetPosition = UDim2.new(1, -270, 1, -70 - (existingNotifs * 60))

    -- Animate In
    TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPosition }):Play()

    -- Animate Out and destroy
    task.delay(duration, function()
        if container and container.Parent then
            TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 0, container.Position.Y.Scale, container.Position.Y.Offset) }):Play()
            Debris:AddItem(NotifGui, 0.5)
        end
    end)
end

