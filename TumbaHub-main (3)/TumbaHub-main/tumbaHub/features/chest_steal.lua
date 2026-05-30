-- features/chest_steal.lua
-- Logic for Auto-Loot (Chest Steal)

if not Mega.Features then Mega.Features = {} end
Mega.Features.ChestSteal = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.ChestSteal then
    States.Misc.ChestSteal = { Enabled = false, Range = 25 }
end

if not Mega.Objects.ChestStealConnections then Mega.Objects.ChestStealConnections = {} end
local connections = Mega.Objects.ChestStealConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local ChestGetItem
task.spawn(function()
    pcall(function()
        ChestGetItem = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("Inventory/ChestGetItem")
    end)
end)

local lastChestCheck = 0
connections.ChestStealLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Misc.ChestSteal.Enabled then return end
    if not ChestGetItem then return end
    
    if tick() - lastChestCheck > 0.1 then
        lastChestCheck = tick()
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local chests = Services.CollectionService:GetTagged("chest")
        for _, chest in pairs(chests) do
            if chest:IsA("BasePart") then
                if (chest.Position - root.Position).Magnitude <= States.Misc.ChestSteal.Range then
                    local chestFolderValue = chest:FindFirstChild("ChestFolderValue")
                    if chestFolderValue then
                        local inventoryFolder = chestFolderValue.Value
                        if inventoryFolder then
                            local items = inventoryFolder:GetChildren()
                            for _, item in pairs(items) do
                                if item:IsA("Accessory") or item:IsA("Tool") then
                                    task.spawn(function()
                                        pcall(function()
                                            ChestGetItem:InvokeServer(inventoryFolder, item)
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

function Mega.Features.ChestSteal.SetEnabled(state)
    States.Misc.ChestSteal.Enabled = state
end