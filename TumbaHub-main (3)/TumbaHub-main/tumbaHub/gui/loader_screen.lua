-- gui/loader_screen.lua
-- Premium Startup Loading GUI for TumbaHub

local Services = Mega.Services
local TweenService = Services.TweenService
local Loader = {}

function Loader.Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TumbaLoader"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 1000
    ScreenGui.Parent = Services.CoreGui
    
    local Background = Instance.new("Frame", ScreenGui)
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    Background.BorderSizePixel = 0
    
    local Blur = Instance.new("BlurEffect", Services.Lighting)
    Blur.Size = 0
    TweenService:Create(Blur, TweenInfo.new(1), {Size = 24}):Play()

    local Content = Instance.new("Frame", Background)
    Content.Size = UDim2.new(0, 400, 0, 300)
    Content.Position = UDim2.new(0.5, 0, 0.5, 0)
    Content.AnchorPoint = Vector2.new(0.5, 0.5)
    Content.BackgroundTransparency = 1

    local Logo = Instance.new("ImageLabel", Content)
    Logo.Size = UDim2.new(0, 120, 0, 120)
    Logo.Position = UDim2.new(0.5, 0, 0, 40)
    Logo.AnchorPoint = Vector2.new(0.5, 0.5)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://13388222306" -- Tumba Logo
    Logo.ImageColor3 = Color3.fromRGB(0, 160, 255)
    
    -- Logo Pulse Animation
    task.spawn(function()
        while ScreenGui.Parent do
            TweenService:Create(Logo, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 130, 0, 130), ImageTransparency = 0.2}):Play()
            task.wait(1.5)
            TweenService:Create(Logo, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 110, 0, 110), ImageTransparency = 0}):Play()
            task.wait(1.5)
        end
    end)

    local Title = Instance.new("TextLabel", Content)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 110)
    Title.BackgroundTransparency = 1
    Title.Text = "TUMBA HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 32
    Title.TextColor3 = Color3.new(1, 1, 1)
    
    local Subtitle = Instance.new("TextLabel", Content)
    Subtitle.Size = UDim2.new(1, 0, 0, 20)
    Subtitle.Position = UDim2.new(0, 0, 0, 145)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "INITIALIZING SYSTEM..."
    Subtitle.Font = Enum.Font.GothamBold
    Subtitle.TextSize = 14
    Subtitle.TextColor3 = Color3.fromRGB(0, 160, 255)
    Subtitle.TextTransparency = 0.5

    -- Progress Container
    local BarContainer = Instance.new("Frame", Content)
    BarContainer.Size = UDim2.new(0.8, 0, 0, 6)
    BarContainer.Position = UDim2.new(0.1, 0, 0, 200)
    BarContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    BarContainer.BorderSizePixel = 0
    Instance.new("UICorner", BarContainer).CornerRadius = UDim.new(1, 0)
    
    local BarFill = Instance.new("Frame", BarContainer)
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.new(1, 1, 1)
    BarFill.BorderSizePixel = 0
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
    
    local Gradient = Instance.new("UIGradient", BarFill)
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
    })

    local PercentText = Instance.new("TextLabel", Content)
    PercentText.Size = UDim2.new(1, 0, 0, 20)
    PercentText.Position = UDim2.new(0, 0, 0, 220)
    PercentText.BackgroundTransparency = 1
    PercentText.Text = "0%"
    PercentText.Font = Enum.Font.GothamSemibold
    PercentText.TextSize = 12
    PercentText.TextColor3 = Color3.new(1, 1, 1)
    PercentText.TextTransparency = 0.4

    local StatusText = Instance.new("TextLabel", Content)
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Position = UDim2.new(0, 0, 0, 250)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Waiting for server..."
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextSize = 11
    StatusText.TextColor3 = Color3.new(0.7, 0.7, 0.7)

    -- Methods
    function Loader.Update(percent, status)
        TweenService:Create(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Size = UDim2.new(percent / 100, 0, 1, 0)}):Play()
        PercentText.Text = math.floor(percent) .. "%"
        if status then StatusText.Text = status end
    end

    function Loader.Destroy()
        TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(Content, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0.6, 0), GroupTransparency = 1}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
        task.wait(0.5)
        ScreenGui:Destroy()
        Blur:Destroy()
    end

    return Loader
end

Mega.Loader = Loader
return Loader
