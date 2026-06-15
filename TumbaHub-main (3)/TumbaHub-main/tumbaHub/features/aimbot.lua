-- features/aimbot.lua
-- Aimbot, AutoShoot, and fully remade Tumba V6 Aim Assist logic

if not Mega.Features then Mega.Features = {} end
Mega.Features.Aimbot = { Target = nil }

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    Debris = game:GetService("Debris")
}

local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local States = Mega.States

-- Ensure Combat and AimAssist states exist
if not States.Combat then States.Combat = {} end
if type(States.Combat.Aimbot) ~= "table" then
    States.Combat.Aimbot = { Enabled = (States.Combat.Aimbot == true), FOV = 250 }
end
if not States.Combat.Aimbot then States.Combat.Aimbot = { Enabled = false, FOV = 250 } end
if type(States.Combat.AutoShoot) ~= "table" then
    States.Combat.AutoShoot = { Enabled = (States.Combat.AutoShoot == true), Delay = 500 }
end
if not States.Combat.AutoShoot then States.Combat.AutoShoot = { Enabled = false, Delay = 500 } end

if not States.AimAssist then
    States.AimAssist = {
        Enabled = false,
        Active = false,
        Key = "R",
        FOV = 120,
        Smoothness = 0.4,
        Range = 100,
        Prediction = true,
        SilentAim = false,
        TargetPart = "Head",
        ShowFOV = true,
        FOVColor = Color3.fromRGB(0, 180, 255),
        Mode = "Simple",
        ClickAim = true,
        RequireMouseDown = false,
        StrafeIncrease = false,
        BlockBreak = false,
        KillauraTarget = false,
        AimSpeed = 6,
        Shake = 0,
        MaxAngle = 70,
        LimitToItems = false,
        AimArea = "Center"
    }
end

if not Mega.Objects.Connections then Mega.Objects.Connections = {} end
local connections = Mega.Objects.Connections

-- Clean up old loops/listeners on load/re-injection
if connections.AimbotLoop then connections.AimbotLoop:Disconnect() end
if connections.AimAssistBegan then connections.AimAssistBegan:Disconnect() end
if connections.AimAssistEnded then connections.AimAssistEnded:Disconnect() end
if connections.MouseClickTracker then connections.MouseClickTracker:Disconnect() end

-- Remove any old FOV circles or Target HUDs
if Mega.Objects.AimAssistFOVCircle then
    pcall(function() Mega.Objects.AimAssistFOVCircle:Remove() end)
    Mega.Objects.AimAssistFOVCircle = nil
end
if Services.CoreGui:FindFirstChild("TumbaTargetHUD") then
    pcall(function() Services.CoreGui.TumbaTargetHUD:Destroy() end)
end

-- Setup FOV circle Drawing
local fovCircle = nil
if type(Drawing) == "table" or type(Drawing) == "function" then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 0.8
        Mega.Objects.AimAssistFOVCircle = fovCircle
    end)
end

-- Target HUD GUI Creation
local function createTargetHUD()
    if Services.CoreGui:FindFirstChild("TumbaTargetHUD") then
        Services.CoreGui.TumbaTargetHUD:Destroy()
    end
    
    local TargetGui = Instance.new("ScreenGui")
    TargetGui.Name = "TumbaTargetHUD"
    TargetGui.Parent = Services.CoreGui
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 260, 0, 70)
    container.Position = UDim2.new(0.5, -130, 0.75, 0)
    container.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = TargetGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 1.2
    stroke.Color = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 70, 255)
    stroke.Transparency = 0.4
    stroke.Parent = container
    
    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0.5, -25)
    avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    avatar.BackgroundTransparency = 0.5
    avatar.BorderSizePixel = 0
    avatar.Parent = container
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatar
    
    -- Info Area
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "Info"
    infoFrame.Size = UDim2.new(1, -80, 1, -20)
    infoFrame.Position = UDim2.new(0, 70, 0, 10)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = container
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Target Name"
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame
    
    -- Health Bar Background
    local hpBack = Instance.new("Frame")
    hpBack.Name = "HPBack"
    hpBack.Size = UDim2.new(1, 0, 0, 8)
    hpBack.Position = UDim2.new(0, 0, 0, 22)
    hpBack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    hpBack.BorderSizePixel = 0
    hpBack.Parent = infoFrame
    
    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(0, 4)
    hpCorner.Parent = hpBack
    
    -- Health Bar Fill
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HPFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBack
    
    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(0, 4)
    hpFillCorner.Parent = hpFill
    
    -- Details (HP Text & Distance)
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Name = "Details"
    detailsLabel.Size = UDim2.new(1, 0, 0, 14)
    detailsLabel.Position = UDim2.new(0, 0, 1, -14)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = "HP: 100/100 | Dist: 0 studs"
    detailsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    detailsLabel.Font = Enum.Font.GothamSemibold
    detailsLabel.TextSize = 9
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailsLabel.Parent = infoFrame
    
    return TargetGui
end

local function updateTargetHUD(targetPlayer, targetPart)
    local gui = Services.CoreGui:FindFirstChild("TumbaTargetHUD")
    if not gui then
        gui = createTargetHUD()
    end
    
    local container = gui:FindFirstChild("Container")
    if not container then return end
    
    if not targetPlayer or not targetPart then
        if container.Visible then
            Services.TweenService:Create(container, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            local stroke = container:FindFirstChild("Stroke")
            if stroke then
                Services.TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
            end
            task.delay(0.2, function()
                if not (States.AimAssist and States.AimAssist.Active) or not Mega.Features.AimAssistTargetPart then
                    container.Visible = false
                end
            end)
        end
        return
    end
    
    local char = targetPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local distance = localRoot and (targetPart.Position - localRoot.Position).Magnitude or 0
    
    container.Info.Name.Text = targetPlayer.DisplayName or targetPlayer.Name
    container.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
    
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = math.clamp(health / maxHealth, 0, 1)
    
    Services.TweenService:Create(container.Info.HPBack.HPFill, TweenInfo.new(0.1), {
        Size = UDim2.new(healthPercent, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255 - (healthPercent * 255), healthPercent * 255, 0)
    }):Play()
    
    container.Info.Details.Text = string.format("HP: %d/%d | Dist: %d studs", math.floor(health), math.floor(maxHealth), math.floor(distance))
    
    if not container.Visible then
        container.BackgroundTransparency = 1
        local stroke = container:FindFirstChild("Stroke")
        if stroke then stroke.Transparency = 1 end
        container.Visible = true
        Services.TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
        if stroke then
            Services.TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.4}):Play()
        end
    end
end

-- Aimbot Target Finder (Unchanged)
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = States.Combat.Aimbot.FOV or 250
    local currentCamera = Services.Workspace.CurrentCamera
    
    if not currentCamera then return nil end
 
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            local isEnemy = true
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isEnemy = false
            end
            
            if humanoid and humanoid.Health > 0 and head and isEnemy then
                local pos, onScreen = currentCamera:WorldToViewportPoint(head.Position)
            
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Aim Assist Wall Check
local function isVisible(part, character)
    local camera = Services.Workspace.CurrentCamera
    if not camera then return false end
    
    local origin = camera.CFrame.Position
    local destination = part.Position
    local direction = destination - origin
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, character, camera}
    params.IgnoreWater = true
    
    local result = Services.Workspace:Raycast(origin, direction, params)
    return result == nil
end

-- Helper: Get part of character closest to the mouse cursor
local function getClosestPartToCursor(character)
    local currentCamera = Services.Workspace.CurrentCamera
    if not currentCamera then return nil end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local closestPart = nil
    local shortestDistance = 9e9
    
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then
            local pos, onScreen = currentCamera:WorldToViewportPoint(child.Position)
            if onScreen then
                local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if screenDist < shortestDistance then
                    closestPart = child
                    shortestDistance = screenDist
                end
            end
        end
    end
    
    return closestPart
end

-- Aim Assist Target Finder (Tumba V6 Logic)
local function getAimAssistTarget()
    -- 1. Support Killaura target option
    if States.AimAssist.KillauraTarget and Mega.Features.Killaura and Mega.Features.Killaura.TargetChar then
        local tChar = Mega.Features.Killaura.TargetChar
        local part = nil
        if States.AimAssist.AimArea == "Closest" then
            part = getClosestPartToCursor(tChar)
        else
            local partName = States.AimAssist.TargetPart or "Head"
            part = tChar:FindFirstChild(partName) or tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart")
        end
        return Services.Players:GetPlayerFromCharacter(tChar) or {Character = tChar, Name = tChar.Name, UserId = 0}, part
    end

    local closestPlayer = nil
    local closestPart = nil
    local shortestDistance = States.AimAssist.FOV or 120
    local currentCamera = Services.Workspace.CurrentCamera
    
    if not currentCamera then return nil, nil end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return nil, nil end

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            
            -- Team check
            local isTeammate = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
            
            if humanoid and humanoid.Health > 0 and not isTeammate then
                -- Target area check (Center vs Closest part to mouse cursor)
                local targetPart = nil
                if States.AimAssist.AimArea == "Closest" then
                    targetPart = getClosestPartToCursor(character)
                else
                    local partName = States.AimAssist.TargetPart or "Head"
                    targetPart = character:FindFirstChild(partName) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                end
                
                if targetPart then
                    -- 1. Range check
                    local dist = (targetPart.Position - localRoot.Position).Magnitude
                    if dist <= (States.AimAssist.Range or 100) then
                        -- 2. Max Angle check (facing angle)
                        local delta = (targetPart.Position - localRoot.Position)
                        local localFacing = localRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
                        local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
                        local maxAngleRad = math.rad(States.AimAssist.MaxAngle or 70)
                        
                        if angle <= (maxAngleRad / 2) then
                            -- 3. Screen FOV check
                            local pos, onScreen = currentCamera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                                if screenDist < shortestDistance then
                                    -- 4. Wall check
                                    if isVisible(targetPart, character) then
                                        closestPlayer = player
                                        closestPart = targetPart
                                        shortestDistance = screenDist
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer, closestPart
end

-- Check holding weapon (sword/blade/axe/katana)
local function isHoldingWeapon()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool and char and char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        tool = char.HandInvItem.Value
    end
    if tool then
        local name = tool.Name:lower()
        if name:find("sword") or name:find("blade") or name:find("scythe") or name:find("axe") or name:find("hammer") or name:find("katana") then
            return true
        end
    end
    return false
end

-- Check holding pickaxe/axe/shears (block breaking tool)
local function isHoldingBlockBreakTool()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool and char and char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        tool = char.HandInvItem.Value
    end
    if tool then
        local name = tool.Name:lower()
        if name:find("pickaxe") or name:find("axe") or name:find("shears") then
            return true
        end
    end
    return false
end

-- Check if mouse click / touchscreen is pressed
local function isMouseDown()
    return Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
           Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or
           #Services.UserInputService:GetNavigationGamepads() > 0
end

-- Remote & Helpers (Unchanged)
local function getBedwarsRemote()
    local success, result = pcall(function()
        return Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.ProjectileFire
    end)
    return success and result or nil
end
 
local function genId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    for i = 1, 8 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
    end
    return id
end
 
local isClicking = false
local lastShoot = 0
local lastClickTime = 0

-- Track mouse clicks for ClickAim option
connections.MouseClickTracker = Services.UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        lastClickTime = tick()
    end
end)

-- Validation function for triggers
local function canAimAssist()
    if not States.AimAssist or not States.AimAssist.Enabled then return false end
    if States.AimAssist.LimitToItems and not isHoldingWeapon() then return false end
    if States.AimAssist.RequireMouseDown and not isMouseDown() then return false end
    if States.AimAssist.ClickAim and (tick() - lastClickTime > 0.3) then return false end
    if States.AimAssist.BlockBreak and isHoldingBlockBreakTool() and isMouseDown() then return false end
    return true
end

-- Keybind Input listeners
local function setupInputListeners()
    if connections.AimAssistBegan then connections.AimAssistBegan:Disconnect() end
    if connections.AimAssistEnded then connections.AimAssistEnded:Disconnect() end
    
    connections.AimAssistBegan = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not (States.AimAssist and States.AimAssist.Enabled) then return end
        
        local targetKey = States.Keybinds and States.Keybinds.AimAssist or "R"
        if input.KeyCode.Name == targetKey then
            if States.AimAssist.ToggleMode then
                States.AimAssist.Active = not States.AimAssist.Active
            else
                States.AimAssist.Active = true
            end
        end
    end)
    
    connections.AimAssistEnded = Services.UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if not (States.AimAssist and States.AimAssist.Enabled) then return end
        if States.AimAssist.ToggleMode then return end
        
        local targetKey = States.Keybinds and States.Keybinds.AimAssist or "R"
        if input.KeyCode.Name == targetKey then
            States.AimAssist.Active = false
        end
    end)
end

-- Math Easing function for Adaptive Mode
local function ease(t)
    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
end

local lockStartedTime = 0
local lastTargetPart = nil

-- Main Loop Manager
local function updateAimbotLoopState()
    local aimbotEnabled = States.Combat.Aimbot and States.Combat.Aimbot.Enabled
    local autoShootEnabled = States.Combat.AutoShoot and States.Combat.AutoShoot.Enabled
    local aimAssistEnabled = States.AimAssist and States.AimAssist.Enabled
    
    if aimbotEnabled or autoShootEnabled or aimAssistEnabled then
        setupInputListeners()
        
        if not connections.AimbotLoop then
            connections.AimbotLoop = Services.RunService.RenderStepped:Connect(function(dt)
                if Mega.Unloaded then
                    if isClicking then
                        isClicking = false
                        if type(mouse1release) == "function" then pcall(mouse1release) end
                    end
                    if connections.AimbotLoop then connections.AimbotLoop:Disconnect() end
                    if connections.AimAssistBegan then connections.AimAssistBegan:Disconnect() end
                    if connections.AimAssistEnded then connections.AimAssistEnded:Disconnect() end
                    if connections.MouseClickTracker then connections.MouseClickTracker:Disconnect() end
                    if fovCircle then fovCircle:Remove() end
                    if Services.CoreGui:FindFirstChild("TumbaTargetHUD") then
                        Services.CoreGui.TumbaTargetHUD:Destroy()
                    end
                    return
                end

                -- 1. FOV Ring drawing logic
                if fovCircle then
                    if aimAssistEnabled and States.AimAssist.ShowFOV then
                        local mousePos = Services.UserInputService:GetMouseLocation()
                        fovCircle.Radius = States.AimAssist.FOV or 120
                        fovCircle.Color = States.AimAssist.FOVColor or Color3.fromRGB(0, 180, 255)
                        fovCircle.Position = mousePos
                        fovCircle.Visible = true
                    else
                        fovCircle.Visible = false
                    end
                end

                -- 2. Combat Aimbot Targeting path (Unchanged)
                if aimbotEnabled or autoShootEnabled then
                    local target = getClosestPlayerToCursor()
                    if target and target.Character then
                        Mega.Features.Aimbot.Target = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Head")
                    else
                        Mega.Features.Aimbot.Target = nil
                    end
                else
                    Mega.Features.Aimbot.Target = nil
                end

                -- 3. Aim Assist Targeting path (Fully Remade)
                local assistPlayer, assistPart = nil, nil
                local allowedToLock = canAimAssist()
                
                if aimAssistEnabled and allowedToLock then
                    assistPlayer, assistPart = getAimAssistTarget()
                    Mega.Features.AimAssistTargetPart = assistPart
                else
                    Mega.Features.AimAssistTargetPart = nil
                end

                -- 4. Camera Lock Mechanics (Simple & Adaptive)
                if aimAssistEnabled and States.AimAssist.Active and assistPart and allowedToLock then
                    -- Reset lock timer if target changed
                    if assistPart ~= lastTargetPart then
                        lockStartedTime = tick()
                        lastTargetPart = assistPart
                    end

                    -- If silent aim is enabled, we do NOT snap camera, namecall hooks handle it
                    if not States.AimAssist.SilentAim then
                        local currentCamera = Services.Workspace.CurrentCamera
                        if currentCamera then
                            local targetPos = assistPart.Position
                            
                            -- Velocity Prediction
                            if States.AimAssist.Prediction and assistPart.Parent then
                                local root = assistPart.Parent:FindFirstChild("HumanoidRootPart")
                                local velocity = root and root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                                targetPos = targetPos + (velocity * 0.05)
                            end
                            
                            -- Jitter/Shake Offset
                            if States.AimAssist.Shake and States.AimAssist.Shake > 0 then
                                local rng = Random.new()
                                local shakeFactor = States.AimAssist.Shake * 0.005
                                targetPos = targetPos + Vector3.new(
                                    (rng:NextNumber() - 0.5) * shakeFactor,
                                    (rng:NextNumber() - 0.5) * shakeFactor,
                                    (rng:NextNumber() - 0.5) * shakeFactor
                                )
                            end
                            
                            -- Calculate Lerp Alpha Factor
                            local fps = dt or 0.016
                            local lerpFactor = 0.4
                            
                            if States.AimAssist.Mode == "Adaptive" then
                                local prog = ease(math.min(tick() - lockStartedTime, 1))
                                local speed = (States.AimAssist.AimSpeed * 0.1 * prog) + (1 - prog)
                                
                                -- Strafe increase logic
                                if States.AimAssist.StrafeIncrease and (Services.UserInputService:IsKeyDown(Enum.KeyCode.A) or Services.UserInputService:IsKeyDown(Enum.KeyCode.D)) then
                                    speed = speed + 10
                                end
                                
                                lerpFactor = speed * fps
                            else
                                -- Simple mode
                                local speed = States.AimAssist.AimSpeed or 6
                                
                                -- Strafe increase logic
                                if States.AimAssist.StrafeIncrease and (Services.UserInputService:IsKeyDown(Enum.KeyCode.A) or Services.UserInputService:IsKeyDown(Enum.KeyCode.D)) then
                                    speed = speed + 10
                                end
                                
                                lerpFactor = speed * fps
                            end
                            
                            local currentCFrame = currentCamera.CFrame
                            local newCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
                            
                            currentCamera.CFrame = currentCFrame:Lerp(newCFrame, math.clamp(lerpFactor, 0, 1))
                        end
                    end
                else
                    lastTargetPart = nil
                end

                -- 5. Target HUD UI update
                if aimAssistEnabled and States.AimAssist.TargetHUD and States.AimAssist.Active and assistPlayer and assistPart and allowedToLock then
                    updateTargetHUD(assistPlayer, assistPart)
                else
                    updateTargetHUD(nil, nil)
                end
                
                -- 6. Combat AutoShoot logic (Unchanged)
                local aimbotTarget = Mega.Features.Aimbot.Target
                if autoShootEnabled and aimbotTarget then
                    local windowActive = (type(iswindowactive) == "function") and iswindowactive() or true
                    if windowActive then
                        local bwRemote = getBedwarsRemote()
                        
                        if bwRemote and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HandInvItem") then
                            local delaySec = (States.Combat.AutoShoot.Delay or 500) / 1000
                            if tick() - lastShoot > delaySec then
                                local tool = LocalPlayer.Character.HandInvItem.Value
                                if tool and (tool.Name:lower():find("bow") or tool.Name:lower():find("fireball") or tool.Name:lower():find("snowball") or tool.Name:lower():find("crossbow") or tool.Name:lower():find("headhunter")) then
                                    lastShoot = tick()
                                    
                                    local ammo = "arrow"
                                    local proj = "arrow"
                                    if tool.Name:lower():find("fireball") then ammo = "fireball"; proj = "fireball" end
                                    if tool.Name:lower():find("snowball") then ammo = "snowball"; proj = "snowball" end
                                    
                                    local origin = LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position or LocalPlayer.Character:GetPivot().Position
                                    local shootPos = origin + Vector3.new(0, 2, 0)
                                    local speed = tool.Name:lower():find("crossbow") and 180 or 130
                                    
                                    local dist = (aimbotTarget.Position - shootPos).Magnitude
                                    local timeToHit = dist / speed
                                    local drop = 0.5 * 196.2 * (timeToHit ^ 2)
                                    local targetVelocity = aimbotTarget.AssemblyLinearVelocity or Vector3.new(0,0,0)
                                    local predictedPos = aimbotTarget.Position + (targetVelocity * timeToHit) + Vector3.new(0, drop, 0)
                                    local dir = (predictedPos - shootPos).Unit
                                    
                                    local args = {
                                        tool, ammo, proj, shootPos, origin, dir * speed, genId(),
                                        { shotId = genId(), drawDurationSec = delaySec + 0.1 },
                                        workspace:GetServerTimeNow() - 0.045
                                    }
                                    
                                    task.spawn(function()
                                        pcall(function() bwRemote:InvokeServer(unpack(args)) end)
                                    end)
                                end
                            end
                        else
                            if not isClicking then
                                isClicking = true
                                if type(mouse1press) == "function" then pcall(mouse1press) end
                            end
                        end
                    end
                else
                    if isClicking then
                        isClicking = false
                        if type(mouse1release) == "function" then pcall(mouse1release) end
                    end
                end
            end)
        end
    else
        if connections.AimbotLoop then
            connections.AimbotLoop:Disconnect()
            connections.AimbotLoop = nil
        end
        if connections.AimAssistBegan then
            connections.AimAssistBegan:Disconnect()
            connections.AimAssistBegan = nil
        end
        if connections.AimAssistEnded then
            connections.AimAssistEnded:Disconnect()
            connections.AimAssistEnded = nil
        end
        if isClicking then
            isClicking = false
            if type(mouse1release) == "function" then pcall(mouse1release) end
        end
        if fovCircle then fovCircle.Visible = false end
        updateTargetHUD(nil, nil)
        
        Mega.Features.Aimbot.Target = nil
        Mega.Features.AimAssistTargetPart = nil
    end
end

-- Metamethod Hooks setup (For Silent Aim)
local execName = (type(identifyexecutor) == "function" and identifyexecutor()) or "Unknown"
local canHook = type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function"
local USE_HOOKS = true

if USE_HOOKS and canHook and not getgenv().TumbaAimbotHooksLoaded then
    getgenv().TumbaAimbotHooksLoaded = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() then
            local target = nil
            if States.Combat.Aimbot and States.Combat.Aimbot.Enabled and Mega.Features.Aimbot.Target then
                target = Mega.Features.Aimbot.Target
            elseif States.AimAssist and States.AimAssist.Enabled and States.AimAssist.SilentAim and States.AimAssist.Active and Mega.Features.AimAssistTargetPart then
                target = Mega.Features.AimAssistTargetPart
            end
            
            if target then
                if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    if self == Services.Workspace then
                        local args = {...}
                        local origin = args[1]
                        if typeof(origin) == "Vector3" then
                            local direction = (target.Position - origin).Unit * args[2].Magnitude
                            return oldNamecall(self, origin, direction, args[3])
                        elseif typeof(origin) == "Ray" then
                            local newRay = Ray.new(origin.Origin, (target.Position - origin.Origin).Unit * origin.Direction.Magnitude)
                            return oldNamecall(self, newRay, args[2], args[3], args[4])
                        end
                    end
                elseif method == "ScreenPointToRay" or method == "ViewportPointToRay" then
                    if setnamecallmethod then setnamecallmethod(method) end
                    local ray = oldNamecall(self, ...)
                    if typeof(ray) == "Ray" then
                        return Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * ray.Direction.Magnitude)
                    end
                elseif method == "InvokeServer" and tostring(self) == "ProjectileFire" then
                    local args = {...}
                    if typeof(args[4]) == "Vector3" and typeof(args[6]) == "Vector3" then
                        local speed = args[6].Magnitude
                        local dist = (target.Position - args[4]).Magnitude
                        local timeToHit = dist / speed
                        local drop = 0.5 * 196.2 * (timeToHit ^ 2)
                        local targetVelocity = target.AssemblyLinearVelocity or Vector3.new(0,0,0)
                        local predictedPos = target.Position + (targetVelocity * timeToHit) + Vector3.new(0, drop, 0)
                        
                        args[6] = (predictedPos - args[4]).Unit * speed
                        if setnamecallmethod then setnamecallmethod(method) end
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end))

    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if not checkcaller() then
            local target = nil
            if States.Combat.Aimbot and States.Combat.Aimbot.Enabled and Mega.Features.Aimbot.Target then
                target = Mega.Features.Aimbot.Target
            elseif States.AimAssist and States.AimAssist.Enabled and States.AimAssist.SilentAim and States.AimAssist.Active and Mega.Features.AimAssistTargetPart then
                target = Mega.Features.AimAssistTargetPart
            end
            
            if target and self == Mouse and (key == "Hit" or key == "Target") then
                if key == "Hit" then
                    return CFrame.new(target.Position)
                elseif key == "Target" then
                    return target
                end
            end
        end
        return oldIndex(self, key)
    end))
end

-- Export APIs
function Mega.Features.Aimbot.SetEnabled(state)
    if not States.Combat.Aimbot then States.Combat.Aimbot = { Enabled = false, FOV = 250 } end
    States.Combat.Aimbot.Enabled = state
    updateAimbotLoopState()
end

function Mega.Features.Aimbot.SetAutoShoot(state)
    if not States.Combat.AutoShoot then States.Combat.AutoShoot = { Enabled = false, Delay = 500 } end
    States.Combat.AutoShoot.Enabled = state
    updateAimbotLoopState()
end

function Mega.Features.Aimbot.SetAimAssistEnabled(state)
    if not States.AimAssist then
        States.AimAssist = {
            Enabled = false,
            Active = false,
            Key = "R",
            FOV = 120,
            Smoothness = 0.4,
            Range = 100,
            Prediction = true,
            SilentAim = false,
            TargetPart = "Head",
            ShowFOV = true,
            FOVColor = Color3.fromRGB(0, 180, 255),
            Mode = "Simple",
            ClickAim = true,
            RequireMouseDown = false,
            StrafeIncrease = false,
            BlockBreak = false,
            KillauraTarget = false,
            AimSpeed = 6,
            Shake = 0,
            MaxAngle = 70,
            LimitToItems = false,
            AimArea = "Center"
        }
    end
    States.AimAssist.Enabled = state
    if not state then
        States.AimAssist.Active = false
    end
    updateAimbotLoopState()
end

-- Initialize loop on load
updateAimbotLoopState()