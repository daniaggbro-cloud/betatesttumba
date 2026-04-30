-- features/auto_drop.lua
-- Redesigned Auto Drop feature with Keybind Hold and Multi-Cycle Spam support

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoDrop = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

local DropItemRemote
task.spawn(function()
    while true do
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

        if not DropItemRemote then
            DropItemRemote = Mega.GetRemote("DropItem")
        end

        if DropItemRemote then 
            print("✅ [AutoDrop] Remote ready for spam: " .. DropItemRemote:GetFullName())
            break 
        end
        task.wait(5)
    end
end)

local function getInventoryFolder()
    local inventories = Services.ReplicatedStorage:FindFirstChild("Inventories")
    if inventories then
        return inventories:FindFirstChild(LocalPlayer.Name) or inventories:FindFirstChild("DONALT_TRUMD")
    end
    return nil
end

local function isTriggerHeld()
    local config = States.Misc.AutoDrop
    if not config or not config.Enabled then return false end
    
    local bind = config.Keybind
    if not bind or bind == "None" then return true end -- Always active if no bind
    
    -- Check if typing
    if Services.UserInputService:GetFocusedTextBox() then return false end

    local success, keyCode = pcall(function() return Enum.KeyCode[bind] end)
    if success and keyCode then
        return Services.UserInputService:IsKeyDown(keyCode)
    end
    return false
end

local lastDropTime = 0
local function processAutoDrop()
    if not isTriggerHeld() then return end
    if not DropItemRemote then return end
    
    local config = States.Misc.AutoDrop
    local delay = config.Delay or 0.1
    if tick() - lastDropTime < delay then return end
    
    local inv = getInventoryFolder()
    if not inv then return end
    
    local resourcesToDrop = config.Resources
    local cycles = config.Cycles or 1

    local droppedAny = false
    -- Get children once per tick to avoid repeated calls
    local items = inv:GetChildren()

    for i = 1, cycles do
        local itemToDrop = nil
        
        -- Find the first available item that matches filters
        for _, item in pairs(items) do
            local itemName = item.Name:lower()
            if resourcesToDrop[itemName] == true then
                itemToDrop = item
                break
            end
        end

        if itemToDrop then
            droppedAny = true
            lastDropTime = tick()
            
            task.spawn(function()
                pcall(function()
                    DropItemRemote:InvokeServer({
                        item = itemToDrop
                    })
                end)
            end)
            
            -- Remove from local list so we don't try to drop the same instance twice in one burst
            for idx, itm in pairs(items) do
                if itm == itemToDrop then
                    table.remove(items, idx)
                    break
                end
            end
        else
            break -- No more items of selected types
        end
    end
end

local connection
function Mega.Features.AutoDrop.SetEnabled(state)
    if state then
        if not connection then
            connection = Services.RunService.Heartbeat:Connect(processAutoDrop)
            print("🔥 [AutoDrop] Keybind spam loop active")
        end
    else
        if connection then
            connection:Disconnect()
            connection = nil
            print("💤 [AutoDrop] Keybind spam loop inactive")
        end
    end
end

if States.Misc.AutoDrop and States.Misc.AutoDrop.Enabled then
    Mega.Features.AutoDrop.SetEnabled(true)
end

return Mega.Features.AutoDrop
