-- features/aimbot.lua
-- All logic for the Aimbot / Aim Assist feature.

Mega.Features.Aimbot = {}

local Services = Mega.Services
local States = Mega.States
local Camera = Services.Workspace.CurrentCamera

local aimbotConnection = nil
local fovCircle = nil
local aimInputBeganConnection = nil
local aimInputEndedConnection = nil

-- Target HUD Data
local TargetHUD = {
    Frame = nil,
    TargetName = nil,
    HealthBar = nil,
    HealthBarBack = nil,
    DistanceText = nil,
    HealthPercent = nil,
    Avatar = nil,
    Visible = false,
    CurrentTarget = nil
}

local function InitTargetHUD()
    if TargetHUD.Frame then return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "TumbaTargetHUD"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = Services.CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 70)
    mainFrame.Position = UDim2.new(0.5, -110, 0.8, 0) -- Bottom center default
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Mega.Settings.Menu.AccentColor or Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    
    -- Glass effect (subtle gradient)
    local gradient = Instance.new("UIGradient", mainFrame)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 200))
    })
    gradient.Rotation = 45
    gradient.Transparency = NumberSequence.new(0, 0.2)
    
    -- Avatar
    local avatar = Instance.new("ImageLabel", mainFrame)
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.BackgroundTransparency = 1
    avatar.Image = ""
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    
    -- Name
    local nameLabel = Instance.new("TextLabel", mainFrame)
    nameLabel.Name = "TargetName"
    nameLabel.Size = UDim2.new(1, -75, 0, 20)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = "Target Name"
    
    -- Health Bar Backdrop
    local hbBack = Instance.new("Frame", mainFrame)
    hbBack.Name = "HealthBack"
    hbBack.Size = UDim2.new(1, -80, 0, 8)
    hbBack.Position = UDim2.new(0, 70, 0, 35)
    hbBack.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    hbBack.BorderSizePixel = 0
    Instance.new("UICorner", hbBack).CornerRadius = UDim.new(0, 4)
    
    -- Health Bar Fill
    local hbFill = Instance.new("Frame", hbBack)
    hbFill.Name = "HealthFill"
    hbFill.Size = UDim2.new(0.5, 0, 1, 0)
    hbFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hbFill.BorderSizePixel = 0
    Instance.new("UICorner", hbFill).CornerRadius = UDim.new(0, 4)
    
    -- Stats
    local stats = Instance.new("TextLabel", mainFrame)
    stats.Name = "Stats"
    stats.Size = UDim2.new(1, -80, 0, 15)
    stats.Position = UDim2.new(0, 70, 0, 45)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.Gotham
    stats.TextColor3 = Color3.fromRGB(200, 200, 200)
    stats.TextSize = 12
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Text = "100 HP | 25 Studs"
    
    TargetHUD.Frame = mainFrame
    TargetHUD.TargetName = nameLabel
    TargetHUD.HealthBar = hbFill
    TargetHUD.DistanceText = stats
    TargetHUD.Avatar = avatar
    
    -- Dragging Logic
    local dragging = false
    local dragInput, dragStart, startPos
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function UpdateTargetHUD(target)
    if not States.AimAssist.TargetHUD then
        if TargetHUD.Frame then TargetHUD.Frame.Visible = false end
        return
    end
    
    if not target then
        if TargetHUD.Visible then
            TargetHUD.Visible = false
            Services.TweenService:Create(TargetHUD.Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.delay(0.3, function() if not TargetHUD.Visible then TargetHUD.Frame.Visible = false end end)
        end
        return
    end
    
    InitTargetHUD()
    
    if not TargetHUD.Visible then
        TargetHUD.Visible = true
        TargetHUD.Frame.Visible = true
        TargetHUD.Frame.BackgroundTransparency = 1
        Services.TweenService:Create(TargetHUD.Frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    end
    
    local hum = target.Character:FindFirstChild("Humanoid")
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    local lpRoot = Services.LocalPlayer.Character and Services.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if hum and root then
        TargetHUD.TargetName.Text = target.Name
        local hp = math.floor(hum.Health)
        local maxHp = math.floor(hum.MaxHealth)
        local dist = lpRoot and math.floor((lpRoot.Position - root.Position).Magnitude) or 0
        
        TargetHUD.DistanceText.Text = string.format("%d HP | %d Studs", hp, dist)
        
        local hpPercent = math.clamp(hp / maxHp, 0, 1)
        Services.TweenService:Create(TargetHUD.HealthBar, TweenInfo.new(0.2), {Size = UDim2.new(hpPercent, 0, 1, 0)}):Play()
        
        -- Color transitions
        local hpColor = Color3.fromHSV(0.33 * hpPercent, 1, 1)
        TargetHUD.HealthBar.BackgroundColor3 = hpColor
        
        -- Avatar
        local userId = target.UserId
        TargetHUD.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
    end
end

local function updateFovCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Radius = 100
        fovCircle.Color = States.AimAssist.FOVColor
        fovCircle.Thickness = 2
        fovCircle.Filled = false
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    fovCircle.Visible = States.AimAssist.Enabled and States.AimAssist.ShowFOV
    if fovCircle.Visible then
        fovCircle.Radius = States.AimAssist.FOV
        fovCircle.Color = States.AimAssist.FOVColor
    end
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local localPlayer = Services.LocalPlayer
    local mousePosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local root = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- Team check to prevent aiming at friends
                if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
                    continue
                end

                local targetPosition, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local fovDistance = (mousePosition - Vector2.new(targetPosition.X, targetPosition.Y)).Magnitude
                    if fovDistance <= (States.AimAssist.FOV or 120) then
                        local lpPos = localPlayer.Character and localPlayer.Character.PrimaryPart and localPlayer.Character.PrimaryPart.Position
                        local realDistance = lpPos and (lpPos - root.Position).Magnitude or 0
                        
                        if realDistance <= (States.AimAssist.Range or 100) then
                            if realDistance < closestDistance then
                                closestDistance = realDistance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

    local targetPlayer = (States.AimAssist.Active and States.AimAssist.Enabled) and getClosestPlayer() or nil
    UpdateTargetHUD(targetPlayer)
    
    if targetPlayer and targetPlayer.Character then
        local targetPart = targetPlayer.Character:FindFirstChild(States.AimAssist.TargetPart or "Head") or targetPlayer.Character.PrimaryPart
        if targetPart then
            local targetPos = targetPart.Position
            -- Simple prediction if enabled
            if States.AimAssist.Prediction and targetPart:IsA("BasePart") then
                targetPos = targetPos + (targetPart.Velocity * 0.1)
            end

            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            if not States.AimAssist.SilentAim then
                -- Smooth Lerp instead of TweenService for better cam control
                local smoothness = math.clamp(1 - (States.AimAssist.Smoothness or 0.4), 0.01, 0.99)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothness)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end
end

function Mega.Features.Aimbot.SetEnabled(state)
    States.AimAssist.Enabled = state
    updateFovCircle()
    if state then
        -- Default to Toggle Mode if nil
        if States.AimAssist.ToggleMode == nil then States.AimAssist.ToggleMode = true end

        -- Listen for key press to activate aim
        local function getAimKey()
            return Enum.KeyCode[States.Keybinds.AimAssist or "R"]
        end

        if not aimInputBeganConnection then
            aimInputBeganConnection = Services.UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == getAimKey() then
                    if States.AimAssist.ToggleMode then
                        States.AimAssist.Active = not States.AimAssist.Active
                    else
                        States.AimAssist.Active = true
                    end
                end
            end)
        end
        
        if not aimInputEndedConnection then
            aimInputEndedConnection = Services.UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == getAimKey() then
                    if not States.AimAssist.ToggleMode then
                        States.AimAssist.Active = false
                    end
                end
            end)
        end
        
        if not aimbotConnection then
            aimbotConnection = Services.RunService.RenderStepped:Connect(aimbotLoop)
        end
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        if aimInputBeganConnection then
            aimInputBeganConnection:Disconnect()
            aimInputBeganConnection = nil
        end
        if aimInputEndedConnection then
            aimInputEndedConnection:Disconnect()
            aimInputEndedConnection = nil
        end
        States.AimAssist.Active = false
    end
end

-- Connect FOV circle update to settings changes
Mega.Services.RunService.RenderStepped:Connect(function()
    if States.AimAssist.Enabled then
        updateFovCircle()
    end
end)

