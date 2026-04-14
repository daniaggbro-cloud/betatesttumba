-- features/aimbot.lua
-- Aimbot and AutoShoot logic

if not Mega.Features then Mega.Features = {} end
Mega.Features.Aimbot = { Target = nil }

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}

local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local States = Mega.States

if not States.Combat then States.Combat = {} end
if not States.Combat.Aimbot then States.Combat.Aimbot = { Enabled = false, FOV = 250 } end
if not States.Combat.AutoShoot then States.Combat.AutoShoot = { Enabled = false, Delay = 500 } end

if not Mega.Objects.Connections then Mega.Objects.Connections = {} end
local connections = Mega.Objects.Connections

-- Clean up old loop
if connections.AimbotLoop then connections.AimbotLoop:Disconnect() end

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

connections.AimbotLoop = Services.RunService.RenderStepped:Connect(function()
    if Mega.Unloaded then
        if isClicking then
            isClicking = false
            if type(mouse1release) == "function" then pcall(mouse1release) end
        end
        if connections.AimbotLoop then connections.AimbotLoop:Disconnect() end
        return
    end

    local aimbotEnabled = States.Combat.Aimbot.Enabled
    local autoShootEnabled = States.Combat.AutoShoot.Enabled

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

if not getgenv().TumbaAimbotHooksLoaded then
    getgenv().TumbaAimbotHooksLoaded = true
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local target = Mega.Features.Aimbot.Target
        local enabled = (States.Combat.Aimbot.Enabled or States.Combat.AutoShoot.Enabled) and target and not checkcaller()

        if enabled then
            if self == Services.Workspace and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                local origin = ({...})[1]
                if typeof(origin) == "Vector3" then
                    local direction = (target.Position - origin).Unit * ({...})[2].Magnitude
                    return oldNamecall(self, origin, direction, ({...})[3])
                elseif typeof(origin) == "Ray" then
                    local newRay = Ray.new(origin.Origin, (target.Position - origin.Origin).Unit * origin.Direction.Magnitude)
                    return oldNamecall(self, newRay, ({...})[2], ({...})[3], ({...})[4])
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
        return oldNamecall(self, ...)
    end))

    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        local target = Mega.Features.Aimbot.Target
        local enabled = (States.Combat.Aimbot.Enabled or States.Combat.AutoShoot.Enabled) and target and not checkcaller()

        if enabled and self == Mouse and (key == "Hit" or key == "Target") then
            if key == "Hit" then
                return CFrame.new(target.Position)
            elseif key == "Target" then
                return target
            end
        end
        
        return oldIndex(self, key)
    end))
end

function Mega.Features.Aimbot.SetEnabled(state)
    States.Combat.Aimbot.Enabled = state
end

function Mega.Features.Aimbot.SetAutoShoot(state)
    States.Combat.AutoShoot.Enabled = state
end