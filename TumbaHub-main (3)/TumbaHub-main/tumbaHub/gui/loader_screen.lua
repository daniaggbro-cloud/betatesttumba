-- gui/loader_screen.lua
-- TumbaHub V6-styled compact top-bar loader screen for TumbaHub

local Services = Mega.Services
local TweenService = Services.TweenService
local Loader = {}

function Loader.Create()
    local self = {}
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TumbaHubLoader"
    ScreenGui.DisplayOrder = 2000
    ScreenGui.Parent = gethui and gethui() or Services.CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 360, 0, 40)
    MainFrame.Position = UDim2.new(0.5, -180, 0, -50) -- Start offscreen for animation
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    MainFrame.BackgroundTransparency = 0.25
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 65)
    UIStroke.Thickness = 1
    UIStroke.Parent = MainFrame
    
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -60, 1, -4)
    Status.Position = UDim2.new(0, 12, 0, 0)
    Status.BackgroundTransparency = 1
    Status.TextColor3 = Color3.fromRGB(240, 240, 240)
    Status.Font = Enum.Font.GothamBold
    Status.TextSize = 13
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Text = "TumbaHub v5 (TEST) | Connecting..."
    Status.Parent = MainFrame
    
    local Percentage = Instance.new("TextLabel")
    Percentage.Size = UDim2.new(0, 40, 1, -4)
    Percentage.Position = UDim2.new(1, -48, 0, 0)
    Percentage.BackgroundTransparency = 1
    Percentage.TextColor3 = Color3.fromRGB(240, 240, 240)
    Percentage.Font = Enum.Font.GothamBold
    Percentage.TextSize = 13
    Percentage.TextXAlignment = Enum.TextXAlignment.Right
    Percentage.Text = "0%"
    Percentage.Parent = MainFrame
    
    local BarContainer = Instance.new("Frame")
    BarContainer.Size = UDim2.new(1, -20, 0, 2)
    BarContainer.Position = UDim2.new(0, 10, 1, -4)
    BarContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    BarContainer.BorderSizePixel = 0
    BarContainer.Parent = MainFrame
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = BarContainer
    
    -- Animate Intro
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -180, 0, 15)
    }):Play()

    -- INSTANCE METHODS
    function self.SetStage(id)
        -- Adapt to TumbaHub Stage Loader structure
        pcall(function()
            Status.Text = "TumbaHub v5 | " .. string.upper(id) .. "..."
        end)
    end
    
    function self.Update(percent, status)
        Percentage.Text = tostring(math.round(percent)) .. "%"
        if status then
            Status.Text = "TumbaHub v5 | " .. status
        end
        TweenService:Create(ProgressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(percent / 100, 0, 1, 0)
        }):Play()
    end
    
    function self.Destroy()
        Percentage.Text = "100%"
        Status.Text = "TumbaHub v5 | Loaded successfully!"
        task.wait(0.5)
        
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local t = TweenService:Create(MainFrame, tweenInfo, {
            Position = UDim2.new(0.5, -180, 0, -50),
            BackgroundTransparency = 1
        })
        t:Play()
        TweenService:Create(Status, tweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(Percentage, tweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(BarContainer, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(ProgressBar, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(UIStroke, tweenInfo, {Transparency = 1}):Play()
        
        t.Completed:Wait()
        ScreenGui:Destroy()
    end
    
    return self
end

Mega.Loader = Loader
return Loader
