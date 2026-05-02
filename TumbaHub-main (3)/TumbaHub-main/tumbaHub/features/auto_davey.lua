-- features/auto_davey.lua
-- Auto Davey kit features (Jump on impact, Break on impact, Legit switch)

local AutoDavey = {}
AutoDavey.__index = AutoDavey

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local oldNamecall

local function GetPickaxe()
    local inventoryFolder = ReplicatedStorage:FindFirstChild("Inventories")
    if not inventoryFolder then return nil end

    local playerInventory = inventoryFolder:FindFirstChild(LocalPlayer.Name)
    if not playerInventory then return nil end

    -- Find pickaxe in inventory
    for _, item in ipairs(playerInventory:GetChildren()) do
        if item.Name:lower():find("pickaxe") then
            return item
        end
    end
    return nil
end

local function GetNearestCannon()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local map = Workspace:FindFirstChild("Map")
    local blocks = map and map:FindFirstChild("Blocks")
    if not blocks then return nil end
    
    local closestCannon = nil
    local minDist = 20 -- Max distance to look for the cannon
    
    -- Iterate through placed blocks
    for _, block in ipairs(blocks:GetChildren()) do
        if block.Name:lower():find("cannon") or block.Name:lower():find("davey") or block.Name:lower():find("tnt") then
            local dist = (block.Position - rootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closestCannon = block
            end
        end
    end
    
    return closestCannon
end

function AutoDavey.Init()
    Mega.Features.AutoDavey = AutoDavey

    local state = Mega.States.Combat.AutoDavey
    if state and state.Enabled then
        AutoDavey.SetEnabled(true)
    end
end

function AutoDavey.SetEnabled(state)
    -- We use a global hook, but only process logic if Enabled is true.
    if not oldNamecall then
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                -- Check if this is the cannon launch remote
                if self.Name == "LaunchSelfFromCannon" or self.Name == "CannonLaunch" or self.Name == "davey_launch" then
                    task.spawn(AutoDavey.OnLaunch)
                end
            end
            
            return oldNamecall(self, ...)
        end)
    end
end

function AutoDavey.OnLaunch()
    local settings = Mega.States.Combat.AutoDavey
    if not settings or not settings.Enabled then return end
    
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    
    -- 1. Jump on impact
    if settings.JumpOnImpact and humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
    
    -- Wait a brief moment to ensure we are launched before breaking
    task.wait(0.05)
    
    -- 2. Break on impact
    if settings.BreakOnImpact then
        local cannon = GetNearestCannon()
        if cannon then
            pcall(function()
                -- Getting the exact DamageBlock remote
                local netManaged = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
                local damageRemote = netManaged:FindFirstChild("DamageBlock") or netManaged:FindFirstChild("MinerDig")
                
                if damageRemote then
                    local args = {
                        {
                            blockRef = {
                                blockPosition = cannon.Position -- Using the cannon's exact grid position
                            },
                            hitPosition = cannon.Position + Vector3.new(0, 0.5, 0),
                            hitNormal = Vector3.new(0, 1, 0)
                        }
                    }
                    if damageRemote:IsA("RemoteEvent") then
                        damageRemote:FireServer(unpack(args))
                    elseif damageRemote:IsA("RemoteFunction") then
                        damageRemote:InvokeServer(unpack(args))
                    end
                end
            end)
        end
    end
    
    -- 3. Legit switch (Switch to Pickaxe)
    if settings.LegitSwitch then
        local pickaxe = GetPickaxe()
        if pickaxe then
            pcall(function()
                local netManaged = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
                local equipRemote = netManaged:FindFirstChild("SetInvItem")
                
                if equipRemote then
                    local args = {
                        {
                            item = pickaxe
                        }
                    }
                    if equipRemote:IsA("RemoteEvent") then
                        equipRemote:FireServer(unpack(args))
                    elseif equipRemote:IsA("RemoteFunction") then
                        equipRemote:InvokeServer(unpack(args))
                    end
                end
            end)
        end
    end
end

-- Init on load
AutoDavey.Init()

return AutoDavey
