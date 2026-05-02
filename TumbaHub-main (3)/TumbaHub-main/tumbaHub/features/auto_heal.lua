-- features/auto_heal.lua
-- Automatically consumes healing items when health is low

local AutoHeal = {}
AutoHeal.__index = AutoHeal

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local autoHealConnection = nil
local lastHealTick = 0

local healingItems = {
    "golden_apple",
    "apple"
}

function AutoHeal.Init()
    -- Register to Mega.Features
    Mega.Features.AutoHeal = AutoHeal

    -- Load state from config
    local state = Mega.States.Combat.AutoHeal
    if state and state.Enabled then
        AutoHeal.SetEnabled(true)
    end
end

function AutoHeal.SetEnabled(state)
    if state then
        if not autoHealConnection then
            autoHealConnection = RunService.Heartbeat:Connect(AutoHeal.OnHeartbeat)
        end
    else
        if autoHealConnection then
            autoHealConnection:Disconnect()
            autoHealConnection = nil
        end
    end
end

local function GetHealingItem()
    local inventoryFolder = ReplicatedStorage:FindFirstChild("Inventories")
    if not inventoryFolder then return nil end

    local playerInventory = inventoryFolder:FindFirstChild(LocalPlayer.Name)
    if not playerInventory then return nil end

    -- Prioritize golden apples over normal apples
    for _, itemName in ipairs(healingItems) do
        local item = playerInventory:FindFirstChild(itemName)
        if item then
            return item
        end
    end

    return nil
end

local function ConsumeItem(item)
    task.spawn(function()
        pcall(function()
            local netManaged = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
            local consumeEvent = netManaged:WaitForChild("ConsumeItem")
            
            local args = {
                {
                    item = item
                }
            }
            consumeEvent:InvokeServer(unpack(args))
        end)
    end)
end

function AutoHeal.OnHeartbeat()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local settings = Mega.States.Combat.AutoHeal
    if not settings or not settings.Enabled then return end

    -- Check health threshold
    if humanoid.Health < settings.Threshold then
        local currentTick = tick()
        -- Respect the configured delay
        if currentTick - lastHealTick >= (settings.Delay / 1000) then
            local itemToConsume = GetHealingItem()
            if itemToConsume then
                lastHealTick = tick() -- Update immediately to prevent duplicate fires before the remote yields
                ConsumeItem(itemToConsume)
            end
        end
    end
end

-- Init on load
AutoHeal.Init()

return AutoHeal
