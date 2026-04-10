-- gui/loader_screen.lua
-- Enhanced Premium Startup Loading GUI for TumbaHub (v2)

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
    Background.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    Background.BorderSizePixel = 0
    Background.BackgroundTransparency = 1 -- Will fade in
    
    local Blur = Instance.new("BlurEffect", Services.Lighting)
    Blur.Size = 0
    TweenService:Create(Blur, TweenInfo.new(1), {Size = 18}):Play()
    TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()

    -- Using CanvasGroup for GroupTransparency support
    local Content = Instance.new("CanvasGroup", Background)
    Content.Size = UDim2.new(0, 320, 0, 240)
    Content.Position = UDim2.new(0.5, 0, 0.45, 0) -- Slightly higher than center
    Content.AnchorPoint = Vector2.new(0.5, 0.5)
    Content.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Content.BorderSizePixel = 0
    Content.GroupTransparency = 1
    
    local ContentCorner = Instance.new("UICorner", Content)
    ContentCorner.CornerRadius = UDim.new(0, 16)
    
    local ContentStroke = Instance.new("UIStroke", Content)
    ContentStroke.Color = Color3.fromRGB(0, 160, 255)
    ContentStroke.Thickness = 1.5
    ContentStroke.Transparency = 0.6
    
    -- Pulsing Stroke Animation
    task.spawn(function()
        while ScreenGui.Parent do
            TweenService:Create(ContentStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2, Thickness = 2}):Play()
            task.wait(2)
            TweenService:Create(ContentStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7, Thickness = 1.2}):Play()
            task.wait(2)
        end
    end)

    local Logo = Instance.new("ImageLabel", Content)
    Logo.Size = UDim2.new(0, 80, 0, 80)
    Logo.Position = UDim2.new(0.5, 0, 0, 50)
    Logo.AnchorPoint = Vector2.new(0.5, 0.5)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://13388222306"
    Logo.ImageColor3 = Color3.fromRGB(0, 160, 255)
    
    local Title = Instance.new("TextLabel", Content)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 95)
    Title.BackgroundTransparency = 1
    Title.Text = "TUMBA HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 24
    Title.TextColor3 = Color3.new(1, 1, 1)
    
    local Subtitle = Instance.new("TextLabel", Content)
    Subtitle.Size = UDim2.new(1, 0, 0, 20)
    Subtitle.Position = UDim2.new(0, 0, 0, 120)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "PREMIUM EDITION"
    Subtitle.Font = Enum.Font.GothamBold
    Subtitle.TextSize = 10
    Subtitle.TextColor3 = Color3.fromRGB(0, 160, 255)
    Subtitle.TextTransparency = 0.4

    -- Progress Bar (Smaller/Slimmer)
    local BarContainer = Instance.new("Frame", Content)
    BarContainer.Size = UDim2.new(0, 240, 0, 4)
    BarContainer.Position = UDim2.new(0.5, 0, 0, 165)
    BarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    BarContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
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
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
    })

    local PercentText = Instance.new("TextLabel", Content)
    PercentText.Size = UDim2.new(1, 0, 0, 20)
    PercentText.Position = UDim2.new(0, 0, 0, 175)
    PercentText.BackgroundTransparency = 1
    PercentText.Text = "0%"
    PercentText.Font = Enum.Font.GothamSemibold
    PercentText.TextSize = 12
    PercentText.TextColor3 = Color3.new(1, 1, 1)

    -- Details Ticker
    local StatusText = Instance.new("TextLabel", Content)
    StatusText.Size = UDim2.new(0.9, 0, 0, 20)
    StatusText.Position = UDim2.new(0.5, 0, 0, 200)
    StatusText.AnchorPoint = Vector2.new(0.5, 0.5)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Establishing connection..."
    StatusText.Font = Enum.Font.Code
    StatusText.TextSize = 10
    StatusText.TextColor3 = Color3.fromRGB(150, 150, 170)
    StatusText.ClipsDescendants = true
    
    -- Initial Fade In
    TweenService:Create(Content, TweenInfo.new(0.6), {GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

    -- Methods
    function Loader.Update(percent, status)
        TweenService:Create(BarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(percent / 100, 0, 1, 0)}):Play()
        PercentText.Text = math.floor(percent) .. "%"
        if status then 
            StatusText.Text = "> " .. status 
        end
    end

    function Loader.Destroy()
        local t = TweenService:Create(Content, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1, 
            Position = UDim2.new(0.5, 0, 0.55, 0),
            Size = UDim2.new(0, 280, 0, 200)
        })
        t:Play()
        TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
        
        t.Completed:Wait()
        ScreenGui:Destroy()
        Blur:Destroy()
    end

    return Loader
end

Mega.Loader = Loader
return Loader
