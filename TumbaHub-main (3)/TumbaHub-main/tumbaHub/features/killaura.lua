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
    States.Combat.Killaura = { Enabled = false, Range = 25, Delay = 0, TargetESP = true, UseFOV = false, FOVAngle = 90, OnlyOnClick = false }
elseif States.Combat.Killaura.TargetESP == nil then
    States.Combat.Killaura.TargetESP = true
    States.Combat.Killaura.UseFOV = false
    States.Combat.Killaura.FOVAngle = 90
    States.Combat.Killaura.OnlyOnClick = false
end

if not Mega.Objects.KillauraConnections then Mega.Objects.KillauraConnections = {} end
local connections = Mega.Objects.KillauraConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local SwordHitRemote
task.spawn(function()
    pcall(function()
        SwordHitRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SwordHit")
    end)
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
-- Лимит убран для синхронизации с каждым кадром игры (Heartbeat)

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

function Mega.Features.Killaura.SetEnabled(state)
    States.Combat.Killaura.Enabled = state
    
    if not state then
        if targetMarkerArrow then targetMarkerArrow.Adornee = nil end
        if targetMarkerCircle then targetMarkerCircle.Adornee = nil end
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
                                if dist < closestDist and dist > 0 and isWithinFOV(tHrp) then
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
                                        if dist < closestDist and dist > 0 and isWithinFOV(tHrp) then
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
                    arrow.StudsOffset = Vector3.new(0, 4 + math.sin(tick() * 6) * 0.5, 0)
                    circle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                else
                    if arrow then arrow.Adornee = nil end
                    if circle then circle.Adornee = nil end
                end

                -- 3. Attack Logic (Every Heartbeat for max Speed)
                if closestTarget and weapon and SwordHitRemote then
                    local currentTime = tick()
                    local userDelay = (States.Combat.Killaura.Delay or 0) / 1000
                    
                    -- Check "Only on Click" condition
                    local canAttack = true
                    if States.Combat.Killaura.OnlyOnClick then
                        local isPressing = Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
                                           Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
                        if not isPressing then canAttack = false end
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
                    end
                end
                
                Services.RunService.Heartbeat:Wait()
            end
            killauraActive = false
        end)
    end
end
