-- features/fast_drop.lua
-- Logic for Fast Drop (Ported from CatV6)

if not Mega.Features then Mega.Features = {} end
Mega.Features.FastDrop = {}

local Services = Mega.Services or {
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if States.Misc.FastDrop == nil then States.Misc.FastDrop = false end

local DropItemRemote
task.spawn(function()
    while not DropItemRemote do
        -- Try common Bedwars drop remote names
        DropItemRemote = Mega.GetRemote("Inventory/DropItem") or Mega.GetRemote("DropItem")
        if DropItemRemote then
            print("✅ FastDrop: Remote found - " .. DropItemRemote:GetFullName())
        else
            task.wait(5)
        end
    end
end)

local function isInventoryOpen()
    -- Bedwars check for open UI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        -- Check for common Bedwars inventory/shop paths
        local inventory = playerGui:FindFirstChild("InventoryApp") or (playerGui:FindFirstChild("TopBarApp") and playerGui.TopBarApp:FindFirstChild("InventoryApp"))
        if inventory and inventory.Enabled then return true end
        
        local shop = playerGui:FindFirstChild("ShopApp") or (playerGui:FindFirstChild("TopBarApp") and playerGui.TopBarApp:FindFirstChild("ShopApp"))
        if shop and shop.Enabled then return true end
    end
    return false
end

local function getHandItem()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    -- Bedwars tools are usually in the character
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end
    
    return nil
end

local function performDrop()
    if not States.Misc.FastDrop then return end
    if not DropItemRemote then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
    
    -- Don't drop if typing
    if Services.UserInputService:GetFocusedTextBox() then return end

    -- Check if Q is held (or the drop key)
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) or Services.UserInputService:IsKeyDown(Enum.KeyCode.Backspace) or Services.UserInputService:IsKeyDown(Enum.KeyCode.H) then
        local item = getHandItem()
        if not item then return end
        
        print("🚀 FastDrop: Attempting to drop " .. item.Name)
        
        pcall(function()
            -- Bedwars usually expects a table with the item
            local args = {
                item = item
            }
            
            for i = 1, 3 do -- 3 times per tick is plenty
                if DropItemRemote:IsA("RemoteEvent") then
                    DropItemRemote:FireServer(args)
                else
                    DropItemRemote:InvokeServer(args)
                end
            end
        end)
    end
end

local connection
function Mega.Features.FastDrop.SetEnabled(state)
    States.Misc.FastDrop = state
    
    if state then
        if not connection then
            connection = Services.RunService.Heartbeat:Connect(performDrop)
        end
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

-- Initialize if already enabled in states
if States.Misc.FastDrop then
    Mega.Features.FastDrop.SetEnabled(true)
end

return Mega.Features.FastDrop
