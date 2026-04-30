-- features/longjump.lua
-- Logic for Long Jump (Velocity + Gravity manipulation)

if not Mega.Features then Mega.Features = {} end
Mega.Features.LongJump = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.LongJump == nil then States.Player.LongJump = false end
if States.Player.LongJumpSpeed == nil then States.Player.LongJumpSpeed = 37 end

if not Mega.Objects.LongJumpConnections then Mega.Objects.LongJumpConnections = {} end
local connections = Mega.Objects.LongJumpConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- Variables for physics state
local JumpTick = tick()
local JumpSpeed = 0
local Direction = nil
local startPos = nil

local FireProjectileRemote = Mega.GetRemote and Mega.GetRemote("FireProjectile")
local PlaceBlockRemote
task.spawn(function()
    while not PlaceBlockRemote do
        pcall(function()
            PlaceBlockRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@easy-games"):WaitForChild("block-engine"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("PlaceBlock")
        end)
        if not PlaceBlockRemote then task.wait(2) end
    end
end)

local function getInventoryItem(nameMatch)
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, item in pairs(inv:GetChildren()) do
            if item.Name:lower():find(nameMatch) then
                return item
            end
        end
    end
    -- Also check character
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool.Name:lower():find(nameMatch) then
            return tool
        end
    end
    return nil
end

local LongJumpMethods = {
    fireball = function(pos, dir, toolObj)
        if FireProjectileRemote and toolObj then
            local speed = 60
            pos = pos - dir * 0.1
            local shootPosition = (CFrame.lookAlong(pos, Vector3.new(0, -speed, 0)) * CFrame.new(Vector3.new(0, 0, 0)))
            local toolInstance = (toolObj:IsA("ObjectValue") and toolObj.Value) or toolObj
            pcall(function()
                FireProjectileRemote:InvokeServer(toolInstance, "fireball", "fireball", shootPosition.Position, pos, shootPosition.LookVector * speed, game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
            end)
        end
    end,
    tnt = function(pos, dir)
        if PlaceBlockRemote then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                pos = pos - Vector3.new(0, (char.Humanoid.HipHeight + (char.HumanoidRootPart.Size.Y / 2)) - 3, 0)
                local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
                startPos = Vector3.new(rounded.X, startPos.Y, rounded.Z) + (dir * 0.2)
                
                local vec3 = (vector and vector.create) or Vector3.new
                local bx, by, bz = rounded.X/3, rounded.Y/3, rounded.Z/3
                local args = {{
                    ["position"] = vec3(bx, by, bz),
                    ["blockType"] = "tnt",
                    ["blockData"] = 0,
                    ["mouseBlockInfo"] = {
                        ["target"] = { ["blockRef"] = { ["blockPosition"] = vec3(bx, by - 1, bz) }, ["hitPosition"] = vec3(rounded.X, rounded.Y, rounded.Z), ["hitNormal"] = Vector3.new(0, 1, 0) },
                        ["placementPosition"] = vec3(bx, by, bz)
                    }
                }}
                pcall(function() PlaceBlockRemote:InvokeServer(unpack(args)) end)
            end
        end
    end
}

local function getBaseSpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.WalkSpeed
    end
    return 16
end

function Mega.Features.LongJump.SetEnabled(state)
    States.Player.LongJump = state
    
    if state then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        startPos = hrp and hrp.Position or nil
        
        -- 1. Damage Hook (to detect TNT/Fireball explosion)
        if hum then
            local lastHealth = hum.Health
            connections.HealthChanged = hum.HealthChanged:Connect(function(newHealth)
                if newHealth < lastHealth then
                    local damage = lastHealth - newHealth
                    if damage > 5 then
                        JumpSpeed = States.Player.LongJumpSpeed
                        JumpTick = tick() + 2.5
                        if hrp then
                            local camera = workspace.CurrentCamera
                            local dir = (camera and camera.CFrame.LookVector) or hrp.CFrame.LookVector
                            Direction = Vector3.new(dir.X, 0, dir.Z).Unit
                        end
                    end
                end
                lastHealth = newHealth
            end)
        end
        
        -- 2. Physics / Velocity Loop
        connections.PhysicsLoop = Services.RunService.PreSimulation:Connect(function(dt)
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            local root = char.HumanoidRootPart
            local humanoid = char.Humanoid
            
            if JumpTick > tick() and Direction then
                -- Вектор тяги
                root.AssemblyLinearVelocity = Direction * (getBaseSpeed() + ((JumpTick - tick()) > 1.1 and JumpSpeed or 0)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                
                -- Анти-гравитация
                if humanoid.FloorMaterial == Enum.Material.Air and not startPos then
                    root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - 23), 0)
                else
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
                end
                startPos = nil
            else
                if startPos and root then
                    root.CFrame = CFrame.lookAlong(startPos, root.CFrame.LookVector)
                end
                if Direction then
                    root.AssemblyLinearVelocity = Vector3.zero
                end
                JumpSpeed = 0
            end
        end)
        
        -- 3. Trigger item on enable
        local fireball = getInventoryItem("fireball")
        local tnt = getInventoryItem("tnt")
        local dir = hrp and hrp.CFrame.LookVector or Vector3.new(0,0,1)
        
        if fireball and LongJumpMethods.fireball then
            task.spawn(LongJumpMethods.fireball, startPos, dir, fireball)
        elseif tnt and LongJumpMethods.tnt then
            task.spawn(LongJumpMethods.tnt, startPos, dir, tnt)
        else
            JumpSpeed = States.Player.LongJumpSpeed
            JumpTick = tick() + 2.5
            Direction = Vector3.new(dir.X, 0, dir.Z).Unit
        end
    else
        -- Disconnect
        if connections.PhysicsLoop then connections.PhysicsLoop:Disconnect() end
        if connections.HealthChanged then connections.HealthChanged:Disconnect() end
        
        JumpTick = tick()
        JumpSpeed = 0
        Direction = nil
        startPos = nil
    end
end

if States.Player.LongJump then
    Mega.Features.LongJump.SetEnabled(true)
end
