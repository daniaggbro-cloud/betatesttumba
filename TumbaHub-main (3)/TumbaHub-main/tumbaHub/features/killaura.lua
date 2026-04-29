-- features/killaura.lua
-- Logic for Killaura (Original Logic Restored)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Killaura = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Combat then States.Combat = {} end
if not States.Combat.Killaura then
    States.Combat.Killaura = { 
        Enabled = false, 
        Range = 25, 
        Delay = 0, 
        TargetESP = true, 
        TargetESPMode = "Arrow",
        TargetESPColor = "Red",
        Tracers = false,
        TargetInfo = false,
        UseFOV = false, 
        FOVAngle = 90, 
        OnlyOnClick = false, 
        AutoClick = false,
        AnimationEnabled = true,
        AnimationMode = "Normal",
        AnimationSpeed = 1
    }
else
    local defaults = {
        TargetESP = true,
        TargetESPMode = "Arrow",
        TargetESPColor = "Red",
        Tracers = false,
        TargetInfo = false,
        AnimationEnabled = true,
        AnimationMode = "Normal",
        AnimationSpeed = 1,
        UseFOV = false,
        FOVAngle = 90,
        OnlyOnClick = false,
        AutoClick = false
    }
    for k, v in pairs(defaults) do
        if States.Combat.Killaura[k] == nil then
            States.Combat.Killaura[k] = v
        end
    end
end

if not Mega.Objects.KillauraConnections then Mega.Objects.KillauraConnections = {} end
local connections = Mega.Objects.KillauraConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local SwordHitRemote = Mega.GetRemote("AttackEntity")
-- Periodically re-check the remote in case of game updates or late loading
task.spawn(function()
    while task.wait(5) do
        if not SwordHitRemote then
            SwordHitRemote = Mega.GetRemote("AttackEntity")
        end
    end
end)


local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        return char.HandInvItem.Value
    end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool.Name:lower():find("sword") or tool.Name:lower():find("blade") or tool.Name:lower():find("scythe")) then
        return tool
    end
    
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name:lower():find("sword") or v.Name:lower():find("blade") or v.Name:lower():find("scythe") then 
                return v 
            end
        end
    end
    return nil
end

local vec3 = (vector and vector.create) or Vector3.new

local function GetTargetColor()
    return Color3.fromRGB(255, 50, 50)
end

local targetMarkerArrow
local targetMarkerCircle
local targetMarkerOrbit = {}
local targetMarkerPulse = {}
local targetMarkerTracers
local targetMarkerInfo

local function GetTargetVisuals()
    local color = GetTargetColor()
    
    if not targetMarkerArrow then
        targetMarkerArrow = Instance.new("BillboardGui")
        targetMarkerArrow.Name = "KillauraArrow"
        targetMarkerArrow.Size = UDim2.new(0, 50, 0, 50)
        targetMarkerArrow.StudsOffset = Vector3.new(0, 4, 0)
        targetMarkerArrow.AlwaysOnTop = true
        
        local arrowText = Instance.new("TextLabel", targetMarkerArrow)
        arrowText.Size = UDim2.new(1, 0, 1, 0)
        arrowText.BackgroundTransparency = 1
        arrowText.Text = "▼"
        arrowText.TextColor3 = color
        arrowText.TextScaled = true
        arrowText.TextStrokeTransparency = 0
        arrowText.Font = Enum.Font.GothamBlack
        targetMarkerArrow.Parent = (Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui)
    end
    targetMarkerArrow.TextLabel.TextColor3 = color
    
    return targetMarkerArrow
end
end

local killauraActive = false
local lastAttackTime = 0
local isManualAttacking = false
local clickTriggered = false
local isSimulatingClick = false
-- Лимит убран для синхронизации с каждым кадром игры (Heartbeat)

-- Отслеживание кликов игрока с фильтром интерфейса
if not Mega.Objects.KillauraInputConnections then
    Mega.Objects.KillauraInputConnections = {}
    
    table.insert(Mega.Objects.KillauraInputConnections, Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end -- Игнорируем клики по интерфейсу (меню, ползунки)
        if isSimulatingClick then return end -- Игнорируем наши собственные авто-клики
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isManualAttacking = true
            clickTriggered = true
            if States.Combat.Killaura.OnlyOnClick then
                lastAttackTime = 0 -- Сброс таймера для моментального удара
            end
        end
    end))
    
    table.insert(Mega.Objects.KillauraInputConnections, Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isManualAttacking = false
        end
    end))
end



local function isWithinFOV(targetPart)
    if not States.Combat.Killaura.UseFOV then return true end
    
    local camera = workspace.CurrentCamera
    if not camera then return true end
    
    local lookVector = camera.CFrame.LookVector
    local directionToTarget = (targetPart.Position - camera.CFrame.Position).Unit
    local dot = lookVector:Dot(directionToTarget)
    local angle = math.deg(math.acos(dot))
    
    return angle <= (States.Combat.Killaura.FOVAngle or 90)
end

local function hasLineOfSight(targetChar)
    if not States.Combat.Killaura.WallCheck then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    local tHead = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not head or not tHead then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char, targetChar}
    raycastParams.IgnoreWater = true

    local direction = tHead.Position - head.Position
    local rayResult = Services.Workspace:Raycast(head.Position, direction, raycastParams)
    
    -- If no obstacle hit or it hit something non-collidable (if we wanted to check, but exclude covers most cases)
    if rayResult and rayResult.Instance and rayResult.Instance.CanCollide == true then
        return false
    end
    return true
end

local function isAimingAt(targetChar)
    if not States.Combat.Killaura.RequireAim then return true end
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local tHrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    if not tHrp then return false end
    
    -- Project target position to screen
    local screenPos, onScreen = camera:WorldToScreenPoint(tHrp.Position)
    if not onScreen then return false end
    
    -- Get current mouse position
    local mouse = LocalPlayer:GetMouse()
    local mouseX, mouseY = mouse.X, mouse.Y
    
    -- Allow a configurable pixel radius around the target (default 95px)
    local aimRadius = States.Combat.Killaura.AimRadius or 95
    local dx = screenPos.X - mouseX
    local dy = screenPos.Y - mouseY
    return (dx * dx + dy * dy) <= (aimRadius * aimRadius)
end

local AuraAnimations = {
    Normal = {
        {CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
        {CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08},
        {CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03},
        {CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03}
    },
    Astral = {
        {CFrame = CFrame.new(0.7, -0.7, 0.6) * CFrame.Angles(math.rad(-16), math.rad(60), math.rad(-80)), Time = 0.1},
        {CFrame = CFrame.new(0.7, -0.7, 0.6) * CFrame.Angles(math.rad(-16), math.rad(60), math.rad(-80)), Time = 0.15},
        {CFrame = CFrame.new(0.95, -1.06, -2.25) * CFrame.Angles(math.rad(-179), math.rad(61), math.rad(80)), Time = 0.15}
    },
    ["Horizontal Spin"] = {
        {CFrame = CFrame.Angles(math.rad(-10), math.rad(-90), math.rad(-80)), Time = 0.12},
        {CFrame = CFrame.Angles(math.rad(-10), math.rad(180), math.rad(-80)), Time = 0.12},
        {CFrame = CFrame.Angles(math.rad(-10), math.rad(90), math.rad(-80)), Time = 0.12},
        {CFrame = CFrame.Angles(math.rad(-10), 0, math.rad(-80)), Time = 0.12}
    },
    Exhibition = {
        {CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
        {CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08}
    },
    Smooth = {
        {CFrame = CFrame.new(-0.4, -0.3, -0.2) * CFrame.Angles(math.rad(-40), math.rad(30), math.rad(-20)), Time = 0.15},
        {CFrame = CFrame.new(-0.2, -0.1, 0) * CFrame.Angles(0, 0, 0), Time = 0.15}
    },
    Hamsterware = {
        {CFrame = CFrame.new(-0.1, -0.2, -0.3) * CFrame.Angles(math.rad(-10), math.rad(10), math.rad(-10)), Time = 0.1},
        {CFrame = CFrame.new(-0.5, -0.5, -0.5) * CFrame.Angles(math.rad(-90), math.rad(90), math.rad(-90)), Time = 0.1}
    }
}

local cachedWrist = nil
local lastViewmodel = nil

local function getArmWrist()
    local cam = workspace.CurrentCamera
    local viewmodel = cam and cam:FindFirstChild("Viewmodel")
    if not viewmodel then 
        cachedWrist = nil
        lastViewmodel = nil
        return nil 
    end
    
    if viewmodel == lastViewmodel and cachedWrist then
        return cachedWrist
    end
    
    local rightHand = viewmodel:FindFirstChild("RightHand") or viewmodel:FindFirstChild("RightArm")
    if not rightHand then return nil end
    
    cachedWrist = rightHand:FindFirstChild("RightWrist") or rightHand:FindFirstChild("RightShoulder")
    lastViewmodel = viewmodel
    return cachedWrist
end

local armC0 = nil
local AnimTween = nil

function Mega.Features.Killaura.SetEnabled(state)
    States.Combat.Killaura.Enabled = state
    
    if not state then
        if targetMarkerArrow then 
            targetMarkerArrow.Adornee = nil 
            targetMarkerArrow.Enabled = false
        end
        if targetMarkerCircle then 
            targetMarkerCircle.Adornee = nil 
            targetMarkerCircle.Visible = false
        end
        if AnimTween then AnimTween:Cancel() end
        local wrist = getArmWrist()
        if wrist and armC0 then
            game:GetService("TweenService"):Create(wrist, TweenInfo.new(0.3), {C0 = armC0}):Play()
        end
    end
    
    if state and not killauraActive then
        killauraActive = true
        
        -- Ultra-Optimized Animation Loop with Lag Protection
        task.spawn(function()
            local started = false
            local currentStep = 1
            local progress = 0
            
            local RunService = Services.RunService
            local currentState = States.Combat.Killaura
            
            while currentState.Enabled do
                if currentState.AnimationEnabled and currentState.IsAttacking then
                    local wrist = getArmWrist()
                    if wrist then
                        if not armC0 then armC0 = wrist.C0 end
                        started = true
                        
                        local speed = currentState.AnimationSpeed or 1
                        local animData = AuraAnimations[currentState.AnimationMode or "Normal"] or AuraAnimations.Normal
                        
                        local step = animData[currentStep]
                        local prevStep = animData[currentStep - 1] or {CFrame = CFrame.new()}
                        
                        -- LAG PROTECTION: Adjust duration based on delta time
                        local dt = RunService.RenderStepped:Wait()
                        if dt > 0.033 then -- If FPS < 30, boost speed to skip frames visually
                            speed = speed * (dt / 0.016)
                        end
                        
                        local duration = math.max(0.01, step.Time / speed)
                        progress = progress + dt
                        
                        local alpha = math.clamp(progress / duration, 0, 1)
                        wrist.C0 = armC0 * prevStep.CFrame:Lerp(step.CFrame, alpha)
                        
                        if alpha >= 1 then
                            progress = 0
                            currentStep = currentStep + 1
                            if currentStep > #animData then
                                currentStep = 1
                            end
                        end
                    else
                        RunService.Heartbeat:Wait()
                    end
                else
                    if started then
                        started = false
                        currentStep = 1
                        progress = 0
                        local wrist = getArmWrist()
                        if wrist and armC0 then
                            wrist.C0 = armC0
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end
        end)

        task.spawn(function()
            while States.Combat.Killaura.Enabled do
                if Mega.Unloaded then break end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local weapon = getWeapon()
                
                local closestTarget = nil
                local closestDist = States.Combat.Killaura.Range

                -- 1. Find Closest Target (Optimized search)
                if hrp then
                    for _, player in pairs(Services.Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
                            local tChar = player.Character
                            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
                            local hum = tChar and tChar:FindFirstChild("Humanoid")
                            
                            if tHrp and hum and hum.Health > 0 then
                                local dist = (hrp.Position - tHrp.Position).Magnitude
                                if dist < closestDist and dist > 0 and isWithinFOV(tHrp) and hasLineOfSight(tChar) and isAimingAt(tChar) then
                                    closestDist = dist
                                    closestTarget = tChar
                                end
                            end
                        end
                    end
                    
                    -- Handle NPCS/Dummies if no players found (With Teammate Protection)
                    if not closestTarget then
                        for _, obj in pairs(Services.Workspace:GetChildren()) do
                            if obj.Name:lower():find("dummy") or obj:FindFirstChild("Humanoid") then
                                local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                local hum = obj:FindFirstChild("Humanoid")
                                
                                if tHrp and hum and hum.Health > 0 and obj ~= char then
                                    -- Проверка, не является ли это игроком из нашей команды
                                    local p = Services.Players:GetPlayerFromCharacter(obj)
                                    local isEnemy = true
                                    if p and (p == LocalPlayer or (p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team)) then
                                        isEnemy = false
                                    end

                                    if isEnemy then
                                        local dist = (hrp.Position - tHrp.Position).Magnitude
                                        if dist < closestDist and dist > 0 and isWithinFOV(tHrp) and hasLineOfSight(obj) and isAimingAt(obj) then
                                            closestDist = dist
                                            closestTarget = obj
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- 2. Visual & Legit Update (Every Heartbeat for smoothness)
                local arrow = GetTargetVisuals()
                local showESP = closestTarget and States.Combat.Killaura.TargetESP
                
                if showESP then
                    local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
                    if tHrp then
                        arrow.Adornee = tHrp
                        arrow.Enabled = true
                        arrow.StudsOffset = Vector3.new(0, 4 + math.sin(tick() * 6) * 0.5, 0)
                    else
                        arrow.Enabled = false
                    end
                else
                    arrow.Enabled = false
                end

                -- 3. Attack Logic (Every Heartbeat for max Speed)
                if closestTarget and weapon and SwordHitRemote then
                    States.Combat.Killaura.IsAttacking = true
                    local currentTime = tick()
                    local userDelay = (States.Combat.Killaura.Delay or 0) / 1000
                    local jitter = math.random(-20, 20) / 1000
                    local effectiveDelay = math.max(0, userDelay + jitter)
                    
                    -- Check "Only on Click" condition
                    local canAttack = true
                    if States.Combat.Killaura.OnlyOnClick then
                        if not clickTriggered then 
                            canAttack = false 
                        else
                            clickTriggered = false -- Сбрасываем триггер после одного удара (1 клик = 1 удар)
                        end
                    end

                    -- Если задержка 0 и проверка пройдена, бьем без остановки на каждом кадре
                    if canAttack and (currentTime - lastAttackTime) >= effectiveDelay then
                        lastAttackTime = currentTime
                        
                        local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
                        local direction = (tHrp.Position - hrp.Position).Unit
                        local spoofedSelfPos = hrp.Position
                        
                        -- Агрессивный спуфинг для лучшего рега
                        if closestDist > 14 then
                            spoofedSelfPos = tHrp.Position - (direction * 13.5)
                        end
                        
                        local args = {
                            {
                                ["chargedAttack"] = { ["chargeRatio"] = 0 },
                                ["entityInstance"] = closestTarget,
                                ["validate"] = {
                                    ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                                    ["selfPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y, spoofedSelfPos.Z) },
                                    ["raycast"] = {
                                        ["cameraPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y + 3, spoofedSelfPos.Z) },
                                        ["cursorDirection"] = { ["value"] = vec3(direction.X, direction.Y, direction.Z) }
                                    }
                                },
                                ["weapon"] = weapon
                            }
                        }
                        pcall(function() SwordHitRemote:FireServer(unpack(args)) end)
                        
                        
                        -- [ Симуляция клика (ЛКМ) при ударе киллауры для анимации ]
                        if States.Combat.Killaura.AutoClick then
                            task.spawn(function()
                                isSimulatingClick = true
                                if mouse1click then
                                    mouse1click()
                                else
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                    task.wait()
                                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                                end
                                task.wait(0.05)
                                isSimulatingClick = false
                            end)
                        end
                    end
                else
                    States.Combat.Killaura.IsAttacking = false
                end
                
                Services.RunService.Heartbeat:Wait()
            end
            killauraActive = false
            States.Combat.Killaura.IsAttacking = false
        end)
    end
end
