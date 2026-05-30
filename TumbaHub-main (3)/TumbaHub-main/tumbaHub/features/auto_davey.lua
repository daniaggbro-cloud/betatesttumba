-- features/auto_davey.lua
-- Auto Davey kit features (Jump on impact, Break on impact, Legit switch)

local AutoDavey = {}
AutoDavey.__index = AutoDavey

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local oldNamecall

local function FindPlayerPickaxe()
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

local function GetBlockPosition(block)
    if block:IsA("Model") then
        if block.PrimaryPart then
            return block.PrimaryPart.Position
        else
            return block:GetPivot().Position
        end
    elseif block:IsA("BasePart") then
        return block.Position
    end
    return nil
end

local function GetNearestCannon()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    
    -- Function to search in a specific Blocks folder
    local closestCannon = nil
    local minDist = 20
    
    local function SearchInFolder(blocksFolder)
        if not blocksFolder then return end
        for _, block in ipairs(blocksFolder:GetChildren()) do
            if block.Name:lower():find("cannon") or block.Name:lower():find("davey") or block.Name:lower():find("tnt") then
                local blockPos = GetBlockPosition(block)
                if blockPos then
                    local dist = (blockPos - rootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestCannon = block
                    end
                end
            end
        end
    end
    
    -- Check main map folder (Real match)
    SearchInFolder(map:FindFirstChild("Blocks"))
    
    -- Check custom worlds folder (Training range, custom match, etc.)
    local worlds = map:FindFirstChild("Worlds")
    if worlds then
        for _, world in ipairs(worlds:GetChildren()) do
            SearchInFolder(world:FindFirstChild("Blocks"))
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
                    task.spawn(AutoDavey.HandleCannonLaunch)
                end
            end
            
            return oldNamecall(self, ...)
        end)
    end
end

function AutoDavey.HandleCannonLaunch()
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
        local targetCannon = GetNearestCannon()
        if targetCannon then
            pcall(function()
                local damageRemote = Mega.GetRemote("DamageBlock") or Mega.GetRemote("MinerDig")
                if not damageRemote then
                    damageRemote = ReplicatedStorage:FindFirstChild("rbxts_include")
                        and ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
                        and ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@easy-games")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]:FindFirstChild("block-engine")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"]:FindFirstChild("node_modules")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules:FindFirstChild("@rbxts")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"]:FindFirstChild("net")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"].net:FindFirstChild("out")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"].net.out:FindFirstChild("_NetManaged")
                        and ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"].net.out._NetManaged:FindFirstChild("DamageBlock")
                end
                
                if damageRemote then
                    local cannonPos = GetBlockPosition(targetCannon)
                    if not cannonPos then return end
                    
                    local blockArgs = {
                        {
                            blockRef = {
                                blockPosition = Vector3.new(
                                    math.round(cannonPos.X / 3),
                                    math.round(cannonPos.Y / 3),
                                    math.round(cannonPos.Z / 3)
                                )
                            },
                            hitPosition = cannonPos + Vector3.new(0, 0.5, 0),
                            hitNormal = Vector3.zAxis
                        }
                    }
                    -- Fire multiple times to ensure it breaks
                    for i = 1, 5 do
                        if damageRemote:IsA("RemoteEvent") then
                            damageRemote:FireServer(unpack(blockArgs))
                        elseif damageRemote:IsA("RemoteFunction") then
                            -- InvokeServer yields, so we spawn it to not block the loop
                            task.spawn(function() damageRemote:InvokeServer(unpack(blockArgs)) end)
                        end
                    end
                end
            end)
        end
    end
    
    -- 3. Legit switch (Switch to Pickaxe)
    if settings.LegitSwitch then
        local pickaxe = FindPlayerPickaxe()
        if pickaxe then
            pcall(function()
                local equipRemote = Mega.GetRemote("SetInvItem") or Mega.GetRemote("EquipItem")
                
                if equipRemote then
                    local equipArgs = {
                        {
                            hand = pickaxe
                        }
                    }
                    if equipRemote:IsA("RemoteEvent") then
                        equipRemote:FireServer(unpack(equipArgs))
                    elseif equipRemote:IsA("RemoteFunction") then
                        equipRemote:InvokeServer(unpack(equipArgs))
                    end
                end
            end)
        end
    end
end

-- Init on load
AutoDavey.Init()

return AutoDavey
