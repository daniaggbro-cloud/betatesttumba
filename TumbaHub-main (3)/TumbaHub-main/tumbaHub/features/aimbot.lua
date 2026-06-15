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
        Range = 100,
        AimSpeed = 6,
        TargetPart = "Head",
        ShowFOV = true,
        Prediction = true,
        ToggleMode = false,
        MobileBtn = false,
        FOVColor = Color3.fromRGB(0, 180, 255)
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

-- Target HUD functionality removed

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

-- Aim Assist Target Finder (Distance-based)
local function getAimAssistTarget()
    local closestPlayer = nil
    local closestPart = nil
    local shortestDistance = States.AimAssist.Range or 100 -- Distance in studs
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
                local partName = States.AimAssist.TargetPart or "Head"
                local targetPart = character:FindFirstChild(partName) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                
                if targetPart then
                    -- 1. Range check (physical distance in studs)
                    local dist = (targetPart.Position - localRoot.Position).Magnitude
                    if dist <= shortestDistance then
                        -- 2. Screen FOV check
                        local pos, onScreen = currentCamera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            local maxFOV = States.AimAssist.FOV or 120
                            
                            if screenDist <= maxFOV then
                                -- 3. Wall check (visibility check)
                                if isVisible(targetPart, character) then
                                    closestPlayer = player
                                    closestPart = targetPart
                                    shortestDistance = dist -- Keep closest physical distance
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

local lastShoot = 0
local isClicking = false

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
                    if fovCircle then fovCircle:Remove() end
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

                -- 3. Aim Assist Targeting path
                local assistPlayer, assistPart = nil, nil
                
                if aimAssistEnabled then
                    assistPlayer, assistPart = getAimAssistTarget()
                    Mega.Features.AimAssistTargetPart = assistPart
                else
                    Mega.Features.AimAssistTargetPart = nil
                end

                -- 4. Camera Lock Mechanics (Lerp)
                if aimAssistEnabled and States.AimAssist.Active and assistPart then
                    local currentCamera = Services.Workspace.CurrentCamera
                    if currentCamera then
                        local targetPos = assistPart.Position
                        
                        -- Velocity Prediction
                        if States.AimAssist.Prediction and assistPart.Parent then
                            local root = assistPart.Parent:FindFirstChild("HumanoidRootPart")
                            local velocity = root and root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                            targetPos = targetPos + (velocity * 0.05)
                        end
                        
                        -- Lerp Factor
                        local fps = dt or 0.016
                        local speed = States.AimAssist.AimSpeed or 6
                        local lerpFactor = speed * fps
                        
                        local currentCFrame = currentCamera.CFrame
                        local newCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
                        
                        currentCamera.CFrame = currentCFrame:Lerp(newCFrame, math.clamp(lerpFactor, 0, 1))
                    end
                end

                -- 5. Combat AutoShoot logic (Unchanged)
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
            Range = 100,
            AimSpeed = 6,
            TargetPart = "Head",
            ShowFOV = true,
            Prediction = true,
            ToggleMode = false,
            MobileBtn = false,
            FOVColor = Color3.fromRGB(0, 180, 255)
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