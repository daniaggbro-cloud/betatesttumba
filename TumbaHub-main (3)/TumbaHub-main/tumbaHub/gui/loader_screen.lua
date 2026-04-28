-- gui/loader_screen.lua
-- TumbaHub "Titan" Initialization Engine v3.1 (Hotfix Update)
-- Instance-based structure for better stability.

local Services = Mega.Services
local TweenService = Services.TweenService
local RunService = Services.RunService
local Loader = {}

-- Utility to get localized text safely (may be nil during bootstrap)
local function SafeGetText(key)
    if Mega.GetText then
        return Mega.GetText(key)
    end
    return key
end

function Loader.Create()
    local self = {}
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TumbaTitanLoader"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 2000
    ScreenGui.Parent = Services.CoreGui
    
    -- Main Overlay
    local Overlay = Instance.new("Frame", ScreenGui)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    Overlay.BorderSizePixel = 0
    Overlay.BackgroundTransparency = 1 
    
    local Blur = Instance.new("BlurEffect", Services.Lighting)
    Blur.Size = 0
    TweenService:Create(Blur, TweenInfo.new(1.5), {Size = 24}):Play()
    TweenService:Create(Overlay, TweenInfo.new(0.8), {BackgroundTransparency = 0.15}):Play()

    -- Rotating Backdrop
    local Grid = Instance.new("ImageLabel", Overlay)
    Grid.Size = UDim2.new(2, 0, 2, 0)
    Grid.Position = UDim2.new(0.5, 0, 0.5, 0)
    Grid.AnchorPoint = Vector2.new(0.5, 0.5)
    Grid.BackgroundTransparency = 1
    Grid.Image = "rbxassetid://13419086708"
    Grid.ImageColor3 = Color3.fromRGB(0, 160, 255)
    Grid.ImageTransparency = 0.95
    Grid.Rotation = 0
    
    task.spawn(function()
        while ScreenGui.Parent do
            Grid.Rotation = Grid.Rotation + 0.05
            RunService.RenderStepped:Wait()
        end
    end)

    -- THE TITAN CONTAINER
    local Titan = Instance.new("CanvasGroup", Overlay)
    Titan.Size = UDim2.new(0, 550, 0, 380)
    Titan.Position = UDim2.new(0.5, 0, 0.48, 0)
    Titan.AnchorPoint = Vector2.new(0.5, 0.5)
    Titan.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Titan.BorderSizePixel = 0
    Titan.GroupTransparency = 1
    Instance.new("UICorner", Titan).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", Titan).Color = Color3.fromRGB(0, 160, 255)
    
    -- Header: Stages
    local Header = Instance.new("Frame", Titan)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    Header.BorderSizePixel = 0
    
    local StageList = {
        {id = "network", key = "phase_network"},
        {id = "core", key = "phase_core"},
        {id = "features", key = "phase_features"},
        {id = "ui", key = "phase_ui"}
    }
    local StageButtons = {}
    
    local HeaderLayout = Instance.new("UIListLayout", Header)
    HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
    HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    HeaderLayout.Padding = UDim.new(0, 2)
    
    for _, s in ipairs(StageList) do
        local btn = Instance.new("Frame", Header)
        btn.Size = UDim2.new(0.25, -2, 1, 0)
        btn.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        -- Initial text bypasses GetText if it's not ready
        label.Text = s.id:upper()
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextTransparency = 0.6
        
        local line = Instance.new("Frame", btn)
        line.Size = UDim2.new(0, 0, 0, 2)
        line.Position = UDim2.new(0.5, 0, 1, -2)
        line.AnchorPoint = Vector2.new(0.5, 0)
        line.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
        line.BorderSizePixel = 0
        
        StageButtons[s.id] = {label = label, line = line, key = s.key}
    end

    -- Stats Panel
    local StatsPanel = Instance.new("Frame", Titan)
    StatsPanel.Size = UDim2.new(0, 140, 0, 200)
    StatsPanel.Position = UDim2.new(1, -150, 0, 60)
    StatsPanel.BackgroundTransparency = 1
    
    local function CreateStat(name, valFunc)
        local f = Instance.new("TextLabel", StatsPanel)
        f.Size = UDim2.new(1, 0, 0, 20)
        f.BackgroundTransparency = 1
        f.Font = Enum.Font.Code
        f.TextSize = 12
        f.TextColor3 = Color3.fromRGB(0, 160, 255)
        f.TextXAlignment = Enum.TextXAlignment.Right
        
        task.spawn(function()
            while f.Parent do
                local success, result = pcall(valFunc)
                f.Text = name .. ": " .. (success and tostring(result) or "...")
                task.wait(0.5)
            end
        end)
    end
    
    CreateStat("PING", function() return math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms" end)
    CreateStat("FPS", function() return math.floor(1 / RunService.RenderStepped:Wait()) end)
    CreateStat("MEM", function() return math.floor(Services.Stats:GetTotalMemoryUsageMb()) .. "MB" end)

    -- LOGS TERMINAL
    local Terminal = Instance.new("ScrollingFrame", Titan)
    Terminal.Size = UDim2.new(1, -30, 0, 100)
    Terminal.Position = UDim2.new(0, 15, 1, -115)
    Terminal.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    Terminal.BorderSizePixel = 0
    Terminal.ScrollBarThickness = 2
    Terminal.ScrollingEnabled = false
    Instance.new("UICorner", Terminal).CornerRadius = UDim.new(0, 6)
    local LogLayout = Instance.new("UIListLayout", Terminal)
    LogLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    LogLayout.Padding = UDim.new(0, 2)
    
    local function AddLog(msg, color)
        local l = Instance.new("TextLabel", Terminal)
        l.Size = UDim2.new(1, -10, 0, 16)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 11
        l.TextColor3 = color or Color3.fromRGB(150, 150, 170)
        l.Text = "> " .. msg
        l.TextXAlignment = Enum.TextXAlignment.Left
        Terminal.CanvasPosition = Vector2.new(0, 9999)
        local fullText = l.Text
        l.Text = "> "
        task.spawn(function()
            for i = 3, #fullText do l.Text = fullText:sub(1, i) task.wait(0.01) end
        end)
    end

    -- Centerpiece
    local Logo = Instance.new("ImageLabel", Titan)
    Logo.Size = UDim2.new(0, 70, 0, 70)
    Logo.Position = UDim2.new(0, 60, 0, 100)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://13388222306"
    Logo.ImageColor3 = Color3.fromRGB(0, 160, 255)
    local PhaseLabel = Instance.new("TextLabel", Titan)
    PhaseLabel.Size = UDim2.new(0, 300, 0, 30)
    PhaseLabel.Position = UDim2.new(0, 110, 0, 85)
    PhaseLabel.BackgroundTransparency = 1
    PhaseLabel.Font = Enum.Font.GothamBlack
    PhaseLabel.TextSize = 20
    PhaseLabel.TextColor3 = Color3.new(1, 1, 1)
    PhaseLabel.TextXAlignment = Enum.TextXAlignment.Left
    local StatusLabel = Instance.new("TextLabel", Titan)
    StatusLabel.Size = UDim2.new(0, 300, 0, 20)
    StatusLabel.Position = UDim2.new(0, 110, 0, 110)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 12
    StatusLabel.TextColor3 = Color3.fromRGB(0, 160, 255)
    StatusLabel.TextTransparency = 0.5
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Progress Bar
    local BarBase = Instance.new("Frame", Titan)
    BarBase.Size = UDim2.new(1, -60, 0, 6)
    BarBase.Position = UDim2.new(0.5, 0, 0, 250)
    BarBase.AnchorPoint = Vector2.new(0.5, 0.5)
    BarBase.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    BarBase.BorderSizePixel = 0
    local BarFill = Instance.new("Frame", BarBase)
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    BarFill.BorderSizePixel = 0
    local Laser = Instance.new("Frame", BarFill)
    Laser.Size = UDim2.new(0, 40, 2, 0)
    Laser.Position = UDim2.new(1, -20, 0.5, 0)
    Laser.AnchorPoint = Vector2.new(0.5, 0.5)
    Laser.BackgroundColor3 = Color3.new(1, 1, 1)
    Laser.BorderSizePixel = 0
    Instance.new("UIGradient", Laser).Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)
    })
    local Percent = Instance.new("TextLabel", BarBase)
    Percent.Size = UDim2.new(0, 50, 0, 20)
    Percent.Position = UDim2.new(1, -25, 0, -15)
    Percent.BackgroundTransparency = 1
    Percent.Font = Enum.Font.Code
    Percent.TextSize = 14
    Percent.TextColor3 = Color3.new(1, 1, 1)
    Percent.Text = "0%"

    -- Intro Transition
    TweenService:Create(Titan, TweenInfo.new(1.2, Enum.EasingStyle.Quart), {GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

    -- INSTANCE METHODS (Attach directly to self)
    function self.SetStage(id)
        for stage, comp in pairs(StageButtons) do
            local active = stage == id
            TweenService:Create(comp.label, TweenInfo.new(0.4), {TextTransparency = active and 0 or 0.6}):Play()
            TweenService:Create(comp.line, TweenInfo.new(0.4), {Size = active and UDim2.new(0.8, 0, 0, 2) or UDim2.new(0, 0, 0, 2)}):Play()
            -- Update header text with localization if available
            if active then
                local text = SafeGetText(comp.key)
                comp.label.Text = text:match("%((.-)%)") or text
            end
        end
        
        local stageKey = nil
        for _, s in ipairs(StageList) do if s.id == id then stageKey = s.key break end end
        if stageKey then
            PhaseLabel.Text = SafeGetText(stageKey)
            AddLog("SWITCHING TO " .. id:upper() .. " ENVIRONMENT...", Color3.fromRGB(0, 255, 180))
        end
    end

    function self.Update(percent, status)
        TweenService:Create(BarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = UDim2.new(percent / 100, 0, 1, 0)}):Play()
        Percent.Text = math.floor(percent) .. "%"
        if status then
            StatusLabel.Text = status:upper()
            AddLog(status)
        end
    end

    function self.Destroy()
        AddLog("INITIALIZATION COMPLETE. READY.", Color3.new(1,1,1))
        task.wait(0.5)
        local t = TweenService:Create(Titan, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.55, 0),
            Size = UDim2.new(0, 450, 0, 300)
        })
        t:Play()
        TweenService:Create(Overlay, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
        TweenService:Create(Blur, TweenInfo.new(0.8), {Size = 0}):Play()
        t.Completed:Wait()
        ScreenGui:Destroy()
        Blur:Destroy()
    end

    return self -- Return the instance, not the factory table
end

Mega.Loader = Loader
return Loader
