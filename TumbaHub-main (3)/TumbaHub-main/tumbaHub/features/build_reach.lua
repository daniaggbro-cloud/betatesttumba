-- features/build_reach.lua
-- Logic for Build Reach (Block Reach)
-- Extends the distance at which you can place blocks manually.

if not Mega.Features then Mega.Features = {} end
Mega.Features.BuildReach = {}

local Services = Mega.Services or {
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local States = Mega.States

if not States.Player.BuildReach then
    States.Player.BuildReach = {
        Enabled = false,
        Range = 100
    }
end

local PlaceBlockRemote
task.spawn(function()
    while not PlaceBlockRemote do
        pcall(function()
            PlaceBlockRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@easy-games"):WaitForChild("block-engine"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("PlaceBlock")
        end)
        if not PlaceBlockRemote then task.wait(2) end
    end
end)

local function getEquippedBlock()
    local char = LocalPlayer.Character
    if not char then return nil end
    local handVal = char:FindFirstChild("HandInvItem")
    if handVal and handVal.Value then
        local itemName = handVal.Value.Name:lower()
        if itemName:find("wool") or itemName:find("stone") or itemName:find("wood") or itemName:find("glass") or itemName:find("ceramic") or itemName:find("obsidian") or itemName:find("slime") then
            return handVal.Value.Name
        end
    end
    return nil
end

local vec3 = (vector and vector.create) or Vector3.new

local function performBuildReach()
    if not States.Player.BuildReach.Enabled then return end
    
    local blockType = getEquippedBlock()
    if not blockType then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local maxReach = States.Player.BuildReach.Range or 100
    
    local ray = Mouse.UnitRay
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Services.Workspace:Raycast(ray.Origin, ray.Direction * maxReach, params)
    
    if result then
        local hitPos = result.Position
        local hitNorm = result.Normal
        
        local gridSize = 3
        -- Calc block position adjacent to the hit face
        local placementWorldPos = hitPos + (hitNorm * 1.5)
        local bx = math.floor(placementWorldPos.X / gridSize)
        local by = math.floor(placementWorldPos.Y / gridSize)
        local bz = math.floor(placementWorldPos.Z / gridSize)
        
        -- The block we are attaching to
        local refWorldPos = hitPos - (hitNorm * 1.5)
        local rx = math.floor(refWorldPos.X / gridSize)
        local ry = math.floor(refWorldPos.Y / gridSize)
        local rz = math.floor(refWorldPos.Z / gridSize)
        
        -- Spoofed hit position to bypass anti-cheat (must be near player, slightly below to avoid client-side player collision bugs)
        local myPos = hrp.Position
        local spoofedHitPos = vec3(myPos.X, myPos.Y - 3, myPos.Z)
        
        local args = {
            {
                ["position"] = vec3(bx, by, bz),
                ["blockType"] = blockType,
                ["blockData"] = 0,
                ["mouseBlockInfo"] = {
                    ["target"] = {
                        ["blockRef"] = { ["blockPosition"] = vec3(rx, ry, rz) },
                        ["hitPosition"] = spoofedHitPos,
                        ["hitNormal"] = vec3(0, 1, 0)
                    },
                    ["placementPosition"] = vec3(bx, by, bz)
                }
            }
        }
        
        if PlaceBlockRemote then
            task.spawn(function()
                pcall(function() PlaceBlockRemote:InvokeServer(unpack(args)) end)
            end)
        end
    end
end

if not Mega.Objects.BuildReachConnections then Mega.Objects.BuildReachConnections = {} end
local connections = Mega.Objects.BuildReachConnections

for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

connections.BuildInput = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
        performBuildReach()
    end
end)

function Mega.Features.BuildReach.SetEnabled(state)
    States.Player.BuildReach.Enabled = state
end

if Mega.UnloadedSignal then
    Mega.UnloadedSignal:Connect(function()
        for _, conn in pairs(connections) do conn:Disconnect() end
    end)
end

return Mega.Features.BuildReach
