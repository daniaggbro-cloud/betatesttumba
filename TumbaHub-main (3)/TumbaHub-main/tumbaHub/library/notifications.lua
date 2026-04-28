-- library/notifications.lua
-- TUMBA HUB — Elite Notification System
-- Минимализм. Точность. Без лишнего.

local CoreGui = Mega.Services.CoreGui
local Debris = Mega.Services.Debris
local TweenService = Mega.Services.TweenService

-- Авто-определение статуса по тексту
local function DetectStatus(message)
    local msg = message:lower()
    if msg:find("enabled") or msg:find("включено") or msg:find("увімкнено") or msg:find("activado") then
        return "ON",  Color3.fromRGB(100, 220, 140)
    elseif msg:find("disabled") or msg:find("выключено") or msg:find("вимкнено") or msg:find("desactivado") then
        return "OFF", Color3.fromRGB(200, 75, 75)
    elseif msg:find("warning") or msg:find("осторожно") or msg:find("внимание") then
        return "WARN", Color3.fromRGB(210, 160, 50)
    end
    return "SYS", nil
end

function Mega.ShowNotification(message, duration, colorOverride)
    duration = duration or 3

    local statusTag, autoColor = DetectStatus(message)
    local accentCol = colorOverride or autoColor or Mega.Settings.Menu.AccentColor

    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "TumbaGlobalNotification"
    NotifGui.Parent = CoreGui
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    NotifGui.DisplayOrder = 999

    local existingNotifs = 0
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "TumbaGlobalNotification" and child ~= NotifGui then
            existingNotifs = existingNotifs + 1
        end
    end

    -- Контейнер: ультра-тёмный, острые углы (4px), элитный вид
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 290, 0, 52)
    container.Position = UDim2.new(1, 16, 1, -68 - (existingNotifs * 60))
    container.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    container.BackgroundTransparency = 0
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = NotifGui
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)

    -- Левая accent-полоска: тонкая (3px), на всю высоту, без скруглений
    local SideBar = Instance.new("Frame", container)
    SideBar.Size = UDim2.new(0, 3, 1, 0)
    SideBar.BackgroundColor3 = accentCol
    SideBar.BorderSizePixel = 0

    -- Тонкий border вокруг контейнера
    local Border = Instance.new("UIStroke", container)
    Border.Color = Color3.fromRGB(35, 35, 50)
    Border.Thickness = 1
    Border.Transparency = 0

    -- Статус-тег: [ ON ] / [ OFF ] / [ SYS ] — строгий моноширинный
    local TagBg = Instance.new("Frame", container)
    TagBg.Size = UDim2.new(0, 44, 0, 20)
    TagBg.Position = UDim2.new(0, 12, 0, 8)
    TagBg.BackgroundColor3 = accentCol
    TagBg.BackgroundTransparency = 0.82
    TagBg.BorderSizePixel = 0
    Instance.new("UICorner", TagBg).CornerRadius = UDim.new(0, 3)

    local TagLabel = Instance.new("TextLabel", TagBg)
    TagLabel.Size = UDim2.new(1, 0, 1, 0)
    TagLabel.BackgroundTransparency = 1
    TagLabel.Text = statusTag
    TagLabel.TextColor3 = accentCol
    TagLabel.TextSize = 10
    TagLabel.Font = Enum.Font.GothamBlack
    TagLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Основное сообщение: чистое, белое
    local MsgLabel = Instance.new("TextLabel", container)
    MsgLabel.Size = UDim2.new(1, -20, 0, 18)
    MsgLabel.Position = UDim2.new(0, 12, 0, 30)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.TextColor3 = Color3.fromRGB(200, 200, 215)
    MsgLabel.Font = Enum.Font.GothamSemibold
    MsgLabel.TextSize = 12
    MsgLabel.Text = message
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    MsgLabel.TextTruncate = Enum.TextTruncate.AtEnd

    -- Временной маркер
    local TimeLabel = Instance.new("TextLabel", container)
    TimeLabel.Size = UDim2.new(0, 60, 0, 20)
    TimeLabel.Position = UDim2.new(1, -68, 0, 8)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
    TimeLabel.Font = Enum.Font.Code
    TimeLabel.TextSize = 10
    TimeLabel.Text = "TUMBA HUB"
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Прогресс-бар исчезновения: 1px линия снизу, строгая
    local ProgFill = Instance.new("Frame", container)
    ProgFill.Size = UDim2.new(1, 0, 0, 1)
    ProgFill.Position = UDim2.new(0, 0, 1, -1)
    ProgFill.BackgroundColor3 = accentCol
    ProgFill.BackgroundTransparency = 0.4
    ProgFill.BorderSizePixel = 0

    -- Анимация: слайд справа, быстрая, линейная (без bounce — строго)
    local targetPos = UDim2.new(1, -306, 1, -68 - (existingNotifs * 60))
    TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()

    -- Accent bar появляется с лёгким fade-in
    SideBar.BackgroundTransparency = 1
    TweenService:Create(SideBar, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()

    -- Прогресс-бар убывает линейно
    TweenService:Create(ProgFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 1)
    }):Play()

    -- Исчезновение: слайд вправо, быстрое
    task.delay(duration, function()
        if container and container.Parent then
            TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 16, container.Position.Y.Scale, container.Position.Y.Offset),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(Border, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            TweenService:Create(SideBar, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            Debris:AddItem(NotifGui, 0.4)
        end
    end)
end
