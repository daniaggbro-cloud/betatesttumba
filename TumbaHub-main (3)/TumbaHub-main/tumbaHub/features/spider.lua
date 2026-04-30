-- features/spider.lua
-- Logic for Spider (Climbing walls)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Spider = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что параметры существуют
if not States.Player then States.Player = {} end
if States.Player.Spider == nil then States.Player.Spider = false end
if States.Player.SpiderMode == nil then States.Player.SpiderMode = "Velocity" end
if States.Player.SpiderSpeed == nil then States.Player.SpiderSpeed = 30 end

if not Mega.Objects.SpiderConnections then Mega.Objects.SpiderConnections = {} end
local connections = Mega.Objects.SpiderConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.Spider.SetEnabled(state)
    States.Player.Spider = state
    
    if connections.SpiderLoop then
        connections.SpiderLoop:Disconnect()
        connections.SpiderLoop = nil
    end
    
    if state then
        local rayCheck = RaycastParams.new()
        rayCheck.FilterType = Enum.RaycastFilterType.Blacklist
        local Active = nil
        
        connections.SpiderLoop = Services.RunService.Heartbeat:Connect(function(dt)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local hum = LocalPlayer.Character.Humanoid
                
                rayCheck.FilterDescendantsInstances = {LocalPlayer.Character, Services.Workspace.CurrentCamera}
                
                local vec = hum.MoveDirection * 2.5
                local ray = Services.Workspace:Raycast(root.Position - Vector3.new(0, 2, 0), vec, rayCheck)
                
                if Active and not ray then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                end

                Active = ray
                if Active and ray.Normal.Y == 0 then
                    local speed = States.Player.SpiderSpeed
                    
                    if States.Player.SpiderMode == "CFrame" then
                        root.CFrame = root.CFrame + Vector3.new(0, speed * dt, 0)
                        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                    elseif States.Player.SpiderMode == "Velocity" then
                        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, speed, root.AssemblyLinearVelocity.Z)
                    end
                end
            end
        end)
    else
        if connections.SpiderLoop then
            connections.SpiderLoop:Disconnect()
            connections.SpiderLoop = nil
        end
    end
end

-- Инициализация при включении во время запуска
if States.Player.Spider then
    Mega.Features.Spider.SetEnabled(true)
end
