-- features/auto_drop.lua
-- Logic for Auto Drop resources (Automated item dropping)

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoDrop = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Ensure state exists (redundant but safe)
if not States.Misc then States.Misc = {} end
if not States.Misc.AutoDrop then
    States.Misc.AutoDrop = {
        Enabled = false,
        Delay = 0.5,
        Resources = {
            ["iron"] = false,
            ["diamond"] = false,
            ["emerald"] = false,
            ["gold"] = false,
            ["void_crystal"] = false
        }
    }
end

if not Mega.Objects.AutoDropConnections then Mega.Objects.AutoDropConnections = {} end
local connections = Mega.Objects.AutoDropConnections

-- Clean up previous connections if module is reloaded
for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local DropItem
task.spawn(function()
    pcall(function()
        -- Using the exact remote path provided by the user
        DropItem = Services.ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("DropItem")
    end)
end)

local lastDropTime = 0
connections.AutoDropLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Misc.AutoDrop.Enabled then return end
    if not DropItem then return end
    
    local delay = States.Misc.AutoDrop.Delay or 0.5
    if tick() - lastDropTime < delay then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end

    -- Access player inventory
    local myInventory = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if not myInventory then return end

    -- Check for items to drop
    for _, item in pairs(myInventory:GetChildren()) do
        if States.Misc.AutoDrop.Resources[item.Name] then
            lastDropTime = tick()
            task.spawn(function()
                pcall(function()
                    -- Invoke the drop remote with the item table as seen in user's snippet
                    DropItem:InvokeServer({
                        item = item
                    })
                end)
            end)
            break -- Drop one stack/item at a time based on delay
        end
    end
end)

function Mega.Features.AutoDrop.SetEnabled(state)
    States.Misc.AutoDrop.Enabled = state
end

return Mega.Features.AutoDrop
