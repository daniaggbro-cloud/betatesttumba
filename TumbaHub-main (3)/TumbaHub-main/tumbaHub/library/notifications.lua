-- library/notifications.lua
-- A modern notification system styled after Tumba Vape V6.

local CoreGui = Mega.Services.CoreGui
local Debris = Mega.Services.Debris
local TweenService = Mega.Services.TweenService
local LocalPlayer = Mega.Services.LocalPlayer

local function getNotificationParent()
    local parent
    local success = pcall(function()
        local cGui = game:GetService("CoreGui")
        local test = cGui.Name
        parent = cGui
    end)
    if success and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

function Mega.ShowNotification(message, duration, color)
    duration = duration or 3
    color = color or Mega.Settings.Menu.AccentColor

    local title = "Notification"
    local text = message
    local notifType = "info" -- "success", "error", "info"

    -- Check if this is a module toggle notification
    -- Typical format: "Killaura: Включено" or "Killaura: ENABLED"
    local parts = string.split(message, ": ")
    if #parts >= 2 then
        local possibleModule = parts[1]
        local status = parts[2]
        
        -- Check if status corresponds to Enabled or Disabled in any language
        local isToggle = false
        local isEnabled = false
        
        local enabledTexts = { "ENABLED", "ВКЛЮЧЕНО", "УВІМКНЕНО", "HABILITADO", "ATIVADO", "활성화됨", "有効" }
        local disabledTexts = { "DISABLED", "ВЫКЛЮЧЕН", "ВИМКНЕНО", "DESHABILITADO", "DESATIVADO", "비활성화됨", "無効" }
        
        local upperStatus = string.upper(status)
        for _, t in ipairs(enabledTexts) do
            if upperStatus == t or string.find(upperStatus, t) then
                isToggle = true
                isEnabled = true
                break
            end
        end
        if not isToggle then
            for _, t in ipairs(disabledTexts) do
                if upperStatus == t or string.find(upperStatus, t) then
                    isToggle = true
                    isEnabled = false
                    break
                end
            end
        end
        
        if isToggle then
            title = Mega.GetText("module_toggled") or "Module Toggled"
            if isEnabled then
                text = possibleModule .. " has been <font color='#5AFF5A'>Enabled</font>!"
                notifType = "success"
                color = Color3.fromRGB(90, 255, 90)
            else
                text = possibleModule .. " has been <font color='#FF5A5A'>Disabled</font>!"
                notifType = "error"
                color = Color3.fromRGB(255, 90, 90)
            end
        else
            title = possibleModule
            text = table.concat(parts, ": ", 2)
        end
    end

    local iconSymbol = "i"
    if notifType == "success" then
        iconSymbol = "✔"
    elseif notifType == "error" then
        iconSymbol = "X"
    end

    -- Dynamically calculate text size for compact width matching Vape
    local cleanText = string.gsub(text, "<[^>]+>", "")
    local textWidth = game:GetService("TextService"):GetTextSize(cleanText, 12, Enum.Font.Gotham, Vector2.new(1000, 1000)).X
    local titleWidth = game:GetService("TextService"):GetTextSize(title, 13, Enum.Font.GothamBold, Vector2.new(1000, 1000)).X
    local width = math.clamp(math.max(textWidth, titleWidth) + 76, 260, 420)

    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "TumbaGlobalNotification"
    NotifGui.Parent = getNotificationParent()
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Modern container frame (glassmorphic dark theme with gradient background)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, width, 0, 64)
    container.Position = UDim2.new(1, 10, 1, 0) -- Start off-screen
    container.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.Parent = NotifGui
    
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 18))
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    -- Glowing top-left border stroke using UIGradient
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.new(1, 1, 1) -- Set to white, gradient determines color
    stroke.Transparency = 0.3
    stroke.Parent = container

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 50))
    })
    strokeGradient.Rotation = 45
    strokeGradient.Parent = stroke

    -- Left Icon Circle
    local iconCircle = Instance.new("Frame")
    iconCircle.Size = UDim2.fromOffset(32, 32)
    iconCircle.Position = UDim2.fromOffset(12, 16)
    iconCircle.BackgroundColor3 = color
    iconCircle.BackgroundTransparency = 0.85
    iconCircle.BorderSizePixel = 0
    iconCircle.Parent = container

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconCircle

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Thickness = 1
    iconStroke.Color = color
    iconStroke.Transparency = 0.6
    iconStroke.Parent = iconCircle

    -- Classic text-based icon rendering
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 16
    iconLabel.Text = iconSymbol
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = iconCircle

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -76, 0, 18)
    titleLabel.Position = UDim2.fromOffset(56, 13)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.RichText = true
    titleLabel.Parent = container

    -- Text Label
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -76, 0, 18)
    textLabel.Position = UDim2.fromOffset(56, 31)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 12
    textLabel.Text = text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.RichText = true
    textLabel.Parent = container

    -- Progress Bar
    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, -24, 0, 2)
    progress.Position = UDim2.new(0, 12, 1, -5)
    progress.BackgroundColor3 = color
    progress.BorderSizePixel = 0
    progress.Parent = container

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 1)
    progressCorner.Parent = progress

    -- Find the vertical position for the new notification
    local existingNotifs = 0
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "TumbaGlobalNotification" and child ~= NotifGui then
            existingNotifs = existingNotifs + 1
        end
    end

    local targetPosition = UDim2.new(1, -(width + 20), 1, -80 - (existingNotifs * 72))

    -- Animate In (Exponential ease for snap-to-feel response)
    TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Position = targetPosition }):Play()
    TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

    -- Animate Out and destroy
    task.delay(duration, function()
        if container and container.Parent then
            TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), { Position = UDim2.new(1, 10, 1, container.Position.Y.Offset) }):Play()
            Debris:AddItem(NotifGui, 0.6)
        end
    end)
end


