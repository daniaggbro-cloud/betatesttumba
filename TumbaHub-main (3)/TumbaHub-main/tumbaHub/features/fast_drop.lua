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
        DropItemRemote = Mega.GetRemote("DropItem")
        if not DropItemRemote then task.wait(5) end
    end
end)

local function isInventoryOpen()
    -- Bedwars check for open UI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local topBarApp = playerGui:FindFirstChild("TopBarApp")
        if topBarApp and topBarApp:FindFirstChild("InventoryApp") and topBarApp.InventoryApp.Enabled then
            return true
        end
    end
    return false
end

local function performDrop()
    if not States.Misc.FastDrop then return end
    if not DropItemRemote then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
    
    -- Don't drop if typing or in menu
    if Services.UserInputService:GetFocusedTextBox() then return end
    if isInventoryOpen() then return end

    -- Check if Q is held (or the drop key)
    -- In Bedwars, Q is the default drop key. 
    -- We can also check Backspace or H as in CatV6.
    if Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) or Services.UserInputService:IsKeyDown(Enum.KeyCode.Backspace) or Services.UserInputService:IsKeyDown(Enum.KeyCode.H) then
        pcall(function()
            DropItemRemote:InvokeServer()
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
