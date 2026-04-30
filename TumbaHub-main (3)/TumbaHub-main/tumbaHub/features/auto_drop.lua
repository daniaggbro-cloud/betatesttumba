-- features/auto_drop.lua
-- Redesigned Auto Drop feature for resources
-- Based on user's remote event structure

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoDrop = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

local DropItemRemote
task.spawn(function()
    while true do
        -- Try specific path first (as provided by user)
        local netManaged = Services.ReplicatedStorage:FindFirstChild("rbxts_include")
        if netManaged then
            netManaged = netManaged:FindFirstChild("node_modules")
            if netManaged then
                netManaged = netManaged:FindFirstChild("@rbxts")
                if netManaged then
                    netManaged = netManaged:FindFirstChild("net")
                    if netManaged then
                        netManaged = netManaged:FindFirstChild("out")
                        if netManaged then
                            netManaged = netManaged:FindFirstChild("_NetManaged")
                        end
                    end
                end
            end
        end

        if netManaged then
            DropItemRemote = netManaged:FindFirstChild("DropItem")
        end

        -- Fallback to GetRemote
        if not DropItemRemote then
            DropItemRemote = Mega.GetRemote("DropItem")
        end

        if DropItemRemote then 
            print("✅ [AutoDrop] Remote found: " .. DropItemRemote:GetFullName())
            break 
        end
        task.wait(5)
    end
end)

local function getInventoryFolder()
    local inventories = Services.ReplicatedStorage:FindFirstChild("Inventories")
    if inventories then
        -- Try local player name and also fallback to "DONALT_TRUMD" if that was the case
        return inventories:FindFirstChild(LocalPlayer.Name) or inventories:FindFirstChild("DONALT_TRUMD")
    end
    return nil
end

local lastDropTime = 0
local function processAutoDrop()
    if not States.Misc.AutoDrop or not States.Misc.AutoDrop.Enabled then return end
    if not DropItemRemote then return end
    
    local delay = States.Misc.AutoDrop.Delay or 0.5
    if tick() - lastDropTime < delay then return end
    
    local inv = getInventoryFolder()
    if not inv then return end
    
    local resourcesToDrop = States.Misc.AutoDrop.Resources
    if not resourcesToDrop then return end

    for _, item in pairs(inv:GetChildren()) do
        local itemName = item.Name:lower()
        if resourcesToDrop[itemName] == true then
            lastDropTime = tick()
            
            -- Debug print
            if Mega.Settings and Mega.Settings.System and Mega.Settings.System.DebugMode then
                print("🚀 [AutoDrop] Dropping resource: " .. item.Name)
            end

            task.spawn(function()
                local success, err = pcall(function()
                    -- User's structure: InvokeServer({ item = itemInstance })
                    DropItemRemote:InvokeServer({
                        item = item
                    })
                end)
                if not success then
                    warn("❌ [AutoDrop] Failed to drop item: " .. tostring(err))
                end
            end)
            
            break -- Only drop one stack at a time to respect delay
        end
    end
end

local connection
function Mega.Features.AutoDrop.SetEnabled(state)
    if state then
        if not connection then
            connection = Services.RunService.Heartbeat:Connect(processAutoDrop)
            print("🔔 [AutoDrop] Feature activated")
        end
    else
        if connection then
            connection:Disconnect()
            connection = nil
            print("🔕 [AutoDrop] Feature deactivated")
        end
    end
end

-- Initialize from existing state
if States.Misc.AutoDrop and States.Misc.AutoDrop.Enabled then
    Mega.Features.AutoDrop.SetEnabled(true)
end

return Mega.Features.AutoDrop
