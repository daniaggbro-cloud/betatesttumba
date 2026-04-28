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
    States.Combat.Killaura = { Enabled = false, Range = 25, Delay = 0, TargetESP = true, UseFOV = false, FOVAngle = 90, OnlyOnClick = false, AutoClick = false }
elseif States.Combat.Killaura.TargetESP == nil then
    States.Combat.Killaura.TargetESP = true
    States.Combat.Killaura.UseFOV = false
    States.Combat.Killaura.FOVAngle = 90
    States.Combat.Killaura.OnlyOnClick = false
    States.Combat.Killaura.AutoClick = false
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

local targetMarkerArrow
local targetMarkerCircle

local function GetTargetVisuals()
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
        arrowText.TextColor3 = Color3.fromRGB(255, 50, 50)
        arrowText.TextScaled = true
        arrowText.TextStrokeTransparency = 0
        arrowText.Font = Enum.Font.GothamBlack
    end
    
    if not targetMarkerCircle then
        targetMarkerCircle = Instance.new("CylinderHandleAdornment")
        targetMarkerCircle.Name = "KillauraCircle"
        targetMarkerCircle.Height = 0.05
        targetMarkerCircle.Radius = 3
        targetMarkerCircle.InnerRadius = 2.7
        targetMarkerCircle.Color3 = Color3.fromRGB(255, 50, 50)
        targetMarkerCircle.Transparency = 0.3
        targetMarkerCircle.AlwaysOnTop = true
        targetMarkerCircle.ZIndex = 1
        targetMarkerCircle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    
    if Services.CoreGui then
        local container = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui
        if targetMarkerArrow.Parent ~= container then targetMarkerArrow.Parent = container end
        if targetMarkerCircle.Parent ~= container then targetMarkerCircle.Parent = container end
    end
    
    return targetMarkerArrow, targetMarkerCircle
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
    end
    
    if state and not killauraActive then
        killauraActive = true
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
                local arrow, circle = GetTargetVisuals()
                if closestTarget and States.Combat.Killaura.TargetESP then
                    local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
                    
                    arrow.Adornee = tHrp
                    circle.Adornee = tHrp
                    arrow.Enabled = true
                    circle.Visible = true
                    arrow.StudsOffset = Vector3.new(0, 4 + math.sin(tick() * 6) * 0.5, 0)
                    circle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                else
                    if arrow then 
                        arrow.Adornee = nil 
                        arrow.Enabled = false
                    end
                    if circle then 
                        circle.Adornee = nil 
                        circle.Visible = false
                    end
                end

                -- 3. Attack Logic (Every Heartbeat for max Speed)
                if closestTarget and weapon and SwordHitRemote then
                    local currentTime = tick()
                    local userDelay = (States.Combat.Killaura.Delay or 0) / 1000
                    
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
                    if canAttack and (currentTime - lastAttackTime) >= userDelay then
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
                end
                
                Services.RunService.Heartbeat:Wait()
            end
            killauraActive = false
        end)
    end
end
