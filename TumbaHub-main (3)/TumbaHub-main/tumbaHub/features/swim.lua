-- features/swim.lua
-- Swim - Lets you swim midair by dynamically placing temporary water terrain around you

if not Mega.Features then Mega.Features = {} end
Mega.Features.Swim = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.Swim == nil then States.Player.Swim = false end

local terrain = Services.Workspace:FindFirstChildWhichIsA('Terrain')
local lastpos = Region3.new(Vector3.zero, Vector3.zero)
local connection
local active = false

local function enableSwim()
    if connection then return end
    
    connection = Services.RunService.PreSimulation:Connect(function(dt)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and hum and hum.Health > 0 then
            local moving = hum.MoveDirection ~= Vector3.zero
            local space = Services.UserInputService:IsKeyDown(Enum.KeyCode.Space)
            
            if terrain then
                local factor = (moving or space) and Vector3.new(6, 6, 6) or Vector3.new(2, 1, 2)
                local pos = root.Position - Vector3.new(0, 1, 0)
                local newpos = Region3.new(pos - factor, pos + factor):ExpandToGrid(4)
                
                pcall(function()
                    terrain:ReplaceMaterial(lastpos, 4, Enum.Material.Water, Enum.Material.Air)
                    terrain:FillRegion(newpos, 4, Enum.Material.Water)
                end)
                
                lastpos = newpos
            end
        end
    end)
    active = true
end

local function disableSwim()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if terrain and lastpos then
        pcall(function()
            terrain:ReplaceMaterial(lastpos, 4, Enum.Material.Water, Enum.Material.Air)
        end)
    end
    active = false
end

function Mega.Features.Swim.SetEnabled(state)
    States.Player.Swim = state
    if state then
        enableSwim()
    else
        disableSwim()
    end
end

if States.Player.Swim then
    Mega.Features.Swim.SetEnabled(true)
end

if Mega.UnloadedSignal then
    Mega.UnloadedSignal.Event:Connect(function()
        disableSwim()
    end)
end

return Mega.Features.Swim
