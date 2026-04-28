-- library/notifications.lua
-- ✨ Полностью переработанная система уведомлений v2.0
-- Поддержка иконок, прогресс-бара исчезновения, типов уведомлений

local CoreGui = Mega.Services.CoreGui
local Debris = Mega.Services.Debris
local TweenService = Mega.Services.TweenService
local RunService = Mega.Services.RunService

-- Определяем иконку и цвет по типу сообщения автоматически
local function DetectNotifType(message)
    local msg = message:lower()
    -- Включение/выключение фич
    if msg:find("enabled") or msg:find("включено") or msg:find("увімкнено") or msg:find("activado") then
        return "success", Color3.fromRGB(80, 220, 120)
    elseif msg:find("disabled") or msg:find("выключено") or msg:find("вимкнено") or msg:find("desactivado") then
        return "error", Color3.fromRGB(220, 80, 80)
    elseif msg:find("warning") or msg:find("осторожно") or msg:find("внимание") then
        return "warning", Color3.fromRGB(255, 180, 50)
    end
    return "info", nil -- nil = использовать accent color
end

local function GetNotifIcon(notifType)
    if notifType == "success" then return "✅"
    elseif notifType == "error" then return "❌"
    elseif notifType == "warning" then return "⚠️"
    else return "💡" end
end

function Mega.ShowNotification(message, duration, colorOverride)
    duration = duration or 3

    -- Авто-определение типа и цвета
    local notifType, autoColor = DetectNotifType(message)
    local accentCol = colorOverride or autoColor or Mega.Settings.Menu.AccentColor

    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "TumbaGlobalNotification"
    NotifGui.Parent = CoreGui
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    NotifGui.DisplayOrder = 999

    -- Позиция с учётом других уведомлений
    local existingNotifs = 0
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "TumbaGlobalNotification" and child ~= NotifGui then
            existingNotifs = existingNotifs + 1
        end
    end

    -- Основной контейнер (280px, чуть шире)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 280, 0, 54)
    container.Position = UDim2.new(1, 20, 1, -70 - (existingNotifs * 64)) -- Начинаем за экраном справа
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    container.BackgroundTransparency = 0.08
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = NotifGui

    local ContCorner = Instance.new("UICorner", container)
    ContCorner.CornerRadius = UDim.new(0, 10)

    -- Внешний stroke с цветом типа
    local ContStroke = Instance.new("UIStroke", container)
    ContStroke.Color = accentCol
    ContStroke.Thickness = 1.2
    ContStroke.Transparency = 0.4

    -- Левая цветная полоска (как в Section headers)
    local SideAccent = Instance.new("Frame", container)
    SideAccent.Size = UDim2.new(0, 4, 0.7, 0)
    SideAccent.Position = UDim2.new(0, 0, 0.15, 0)
    SideAccent.BackgroundColor3 = accentCol
    SideAccent.BorderSizePixel = 0
    Instance.new("UICorner", SideAccent).CornerRadius = UDim.new(1, 0)

    -- Иконка типа уведомления
    local IconLabel = Instance.new("TextLabel", container)
    IconLabel.Size = UDim2.new(0, 28, 0, 28)
    IconLabel.Position = UDim2.new(0, 12, 0.5, -14)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = GetNotifIcon(notifType)
    IconLabel.TextSize = 18
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextXAlignment = Enum.TextXAlignment.Center
    IconLabel.TextYAlignment = Enum.TextYAlignment.Center

    -- Текст сообщения
    local MsgLabel = Instance.new("TextLabel", container)
    MsgLabel.Size = UDim2.new(1, -56, 0.75, 0)
    MsgLabel.Position = UDim2.new(0, 46, 0, 8)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.TextColor3 = Color3.new(1, 1, 1)
    MsgLabel.Font = Enum.Font.GothamSemibold
    MsgLabel.TextSize = 13
    MsgLabel.Text = message
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    MsgLabel.TextYAlignment = Enum.TextYAlignment.Center
    MsgLabel.TextWrapped = true

    -- Тип уведомления (маленький subtext)
    local TypeLabel = Instance.new("TextLabel", container)
    TypeLabel.Size = UDim2.new(1, -56, 0, 14)
    TypeLabel.Position = UDim2.new(0, 46, 1, -17)
    TypeLabel.BackgroundTransparency = 1
    TypeLabel.TextColor3 = accentCol
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.TextSize = 10
    TypeLabel.Text = notifType:upper()
    TypeLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- ✨ Прогресс-бар исчезновения (снизу контейнера)
    local ProgressTrack = Instance.new("Frame", container)
    ProgressTrack.Size = UDim2.new(1, 0, 0, 2)
    ProgressTrack.Position = UDim2.new(0, 0, 1, -2)
    ProgressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ProgressTrack.BorderSizePixel = 0

    local ProgressFill = Instance.new("Frame", ProgressTrack)
    ProgressFill.Size = UDim2.new(1, 0, 1, 0)
    ProgressFill.BackgroundColor3 = accentCol
    ProgressFill.BorderSizePixel = 0
    -- Gradient на прогресс-баре
    local ProgGrad = Instance.new("UIGradient", ProgressFill)
    ProgGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, accentCol),
        ColorSequenceKeypoint.new(1, accentCol:Lerp(Color3.new(1,1,1), 0.4))
    }

    -- Лазерный эффект на конце прогресс-бара
    local ProgLaser = Instance.new("Frame", ProgressFill)
    ProgLaser.Size = UDim2.new(0, 20, 3, 0)
    ProgLaser.Position = UDim2.new(1, -10, 0.5, 0)
    ProgLaser.AnchorPoint = Vector2.new(0.5, 0.5)
    ProgLaser.BackgroundColor3 = Color3.new(1, 1, 1)
    ProgLaser.BorderSizePixel = 0
    local LaserGrad = Instance.new("UIGradient", ProgLaser)
    LaserGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    }

    -- Subtle background gradient
    local BgGrad = Instance.new("UIGradient", container)
    BgGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    }
    BgGrad.Rotation = 90

    -- ✨ АНИМАЦИЯ: вылет справа с bounce
    local targetPos = UDim2.new(1, -295, 1, -70 - (existingNotifs * 64))
    TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()

    -- Анимация появления stroke (glow flash при появлении)
    TweenService:Create(ContStroke, TweenInfo.new(0.15), { Transparency = 0.0, Thickness = 2 }):Play()
    task.delay(0.4, function()
        if ContStroke.Parent then
            TweenService:Create(ContStroke, TweenInfo.new(0.4), { Transparency = 0.4, Thickness = 1.2 }):Play()
        end
    end)

    -- ✨ Прогресс-бар убывает за duration секунд
    TweenService:Create(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    -- Исчезновение
    task.delay(duration, function()
        if container and container.Parent then
            TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, container.Position.Y.Scale, container.Position.Y.Offset),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(ContStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            Debris:AddItem(NotifGui, 0.5)
        end
    end)
end

