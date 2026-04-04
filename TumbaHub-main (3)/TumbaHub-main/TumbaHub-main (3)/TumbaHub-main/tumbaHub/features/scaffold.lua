-- features/scaffold.lua
-- Logic for Scaffold (Auto bridging)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Scaffold = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if not States.Player.Scaffold then
    States.Player.Scaffold = {
        Enabled = false,
        GridSize = 3,
        Delay = 0.05,
        YOffset = -3.5,
        Predict = 0.15
    }
end

if not Mega.Objects.ScaffoldConnections then Mega.Objects.ScaffoldConnections = {} end
local connections = Mega.Objects.ScaffoldConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local PlaceBlockRemote
task.spawn(function()
    while not PlaceBlockRemote do
        pcall(function()
            PlaceBlockRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@easy-games"):WaitForChild("block-engine"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("PlaceBlock")
        end)
        if not PlaceBlockRemote then task.wait(2) end
    end
end)

local function getWoolName()
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, item in pairs(inv:GetChildren()) do
            if item.Name:find("wool") then return item.Name end
        end
    end
    return nil
end

local function snapToGrid(v3)
    local gridSize = States.Player.Scaffold.GridSize
    return Vector3.new(
        math.floor(v3.X / gridSize + 0.5) * gridSize,
        math.floor(v3.Y / gridSize + 0.5) * gridSize,
        math.floor(v3.Z / gridSize + 0.5) * gridSize
    )
end

function Mega.Features.Scaffold.SetEnabled(state)
    States.Player.Scaffold.Enabled = state
    
    if state then
        local lastScaffoldPlace = 0
        connections.ScaffoldLoop = Services.RunService.Heartbeat:Connect(function()
            if not States.Player.Scaffold.Enabled then return end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            if tick() - lastScaffoldPlace > States.Player.Scaffold.Delay then
                local wool = getWoolName()
                if not wool then return end

                local moveDir = hrp.Velocity * Vector3.new(1, 0, 1)
                local predictPos = hrp.Position + (moveDir * States.Player.Scaffold.Predict)
                local targetPos = predictPos + Vector3.new(0, States.Player.Scaffold.YOffset, 0)
                local gridPos = snapToGrid(targetPos)
                
                local gridSize = States.Player.Scaffold.GridSize
                local bx, by, bz = math.floor(gridPos.X / gridSize), math.floor(gridPos.Y / gridSize), math.floor(gridPos.Z / gridSize)
                local vec3 = (vector and vector.create) or Vector3.new
                
                local args = {{
                    ["position"] = vec3(bx, by, bz),
                    ["blockType"] = wool,
                    ["blockData"] = 0,
                    ["mouseBlockInfo"] = {
                        ["target"] = { ["blockRef"] = { ["blockPosition"] = vec3(bx, by - 1, bz) }, ["hitPosition"] = vec3(gridPos.X, gridPos.Y, gridPos.Z), ["hitNormal"] = Vector3.new(0, 1, 0) },
                        ["placementPosition"] = vec3(bx, by, bz)
                    }
                }}
                
                if PlaceBlockRemote then
                     task.spawn(function()
                         pcall(function() PlaceBlockRemote:InvokeServer(unpack(args)) end)
                     end)
                     lastScaffoldPlace = tick()
                end
            end
        end)
    else
        if connections.ScaffoldLoop then
            connections.ScaffoldLoop:Disconnect()
            connections.ScaffoldLoop = nil
        end
    end
end

if States.Player.Scaffold.Enabled then
    Mega.Features.Scaffold.SetEnabled(true)
end
