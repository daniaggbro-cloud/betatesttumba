-- features/auto_deposit.lua
-- Logic for Auto Deposit (Personal Chest)

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoDeposit = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.AutoDeposit then
    States.Misc.AutoDeposit = {
        Enabled = false,
        Range = 25,
        Resources = {
            ["iron"] = true,
            ["diamond"] = true,
            ["emerald"] = true,
            ["gold"] = true,
            ["void_crystal"] = true,
            ["wood"] = false,
            ["stone"] = false
        }
    }
end

if not Mega.Objects.AutoDepositConnections then Mega.Objects.AutoDepositConnections = {} end
local connections = Mega.Objects.AutoDepositConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local ChestGiveItem
task.spawn(function()
    pcall(function()
        ChestGiveItem = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("Inventory/ChestGiveItem")
    end)
end)

local function getPersonalChestPart()
    for _, part in pairs(Services.CollectionService:GetTagged("personal-chest")) do
        return part
    end
    return nil
end

local lastDepositCheck = 0
connections.AutoDepositLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Misc.AutoDeposit.Enabled then return end
    if not ChestGiveItem then return end
    if tick() - lastDepositCheck < 1 then return end -- Задержка 1 секунда
    lastDepositCheck = tick()

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local chestPart = getPersonalChestPart()
    if not chestPart then return end
    
    if (chestPart.Position - root.Position).Magnitude > States.Misc.AutoDeposit.Range then
        return
    end

    local myInventory = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    local personalInventory = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name .. "_personal")

    if not myInventory or not personalInventory then return end

    for _, item in pairs(myInventory:GetChildren()) do
        if States.Misc.AutoDeposit.Resources[item.Name] then
            task.spawn(function()
                pcall(function()
                    ChestGiveItem:InvokeServer(personalInventory, item)
                end)
            end)
            task.wait(0.1) -- Небольшая задержка, чтобы не кикнуло за спам
        end
    end
end)

function Mega.Features.AutoDeposit.SetEnabled(state)
    States.Misc.AutoDeposit.Enabled = state
end