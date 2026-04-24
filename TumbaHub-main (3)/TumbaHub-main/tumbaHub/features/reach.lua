-- features/reach.lua
-- Logic for Attack Reach (Manual Hits)
-- Extends the distance at which you can hit enemies manually.

if not Mega.Features then Mega.Features = {} end
Mega.Features.Reach = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Remote Retrieval
local SwordHitRemote
local function GetSwordRemote()
    if SwordHitRemote and SwordHitRemote.Parent then return SwordHitRemote end
    SwordHitRemote = Mega.GetRemote("SwordHit")
    return SwordHitRemote
end

-- Helper to get current weapon
local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    -- Check hand value (Bedwars specific)
    local handValue = char:FindFirstChild("HandInvItem")
    if handValue and handValue.Value then
        return handValue.Value
    end
    
    -- Fallback to tool
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool.Name:lower():find("sword") or tool.Name:lower():find("blade") or tool.Name:lower():find("scythe") or tool.Name:lower():find("hammer")) then
        return tool
    end
    return nil
end

local vec3 = Vector3.new

-- Main logic function
local function performReach()
    if not States.Combat.Reach.Enabled then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local weapon = getWeapon()
    local remote = GetSwordRemote()
    
    if hrp and weapon and remote then
        local maxReach = States.Combat.Reach.Distance or 18
        local closestTarget = nil
        local closestDist = maxReach
        
        -- Target search
        for _, obj in pairs(Services.Workspace:GetChildren()) do
            if obj ~= char and (obj:FindFirstChild("Humanoid") or obj.Name:find("Dummy")) then
                local tHrp = obj:FindFirstChild("HumanoidRootPart") or (obj:IsA("Model") and obj.PrimaryPart)
                local hum = obj:FindFirstChild("Humanoid")
                
                if tHrp and (not hum or hum.Health > 0) then
                    local p = Services.Players:GetPlayerFromCharacter(obj)
                    local isEnemy = true
                    if p and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                        isEnemy = false
                    end
                    
                    if isEnemy then
                        local dist = (hrp.Position - tHrp.Position).Magnitude
                        if dist <= maxReach and dist > 0 then
                            if dist < closestDist then
                                closestDist = dist
                                closestTarget = obj
                            end
                        end
                    end
                end
            end
        end
        
        -- Fire hit if target found
        if closestTarget then
            local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or (closestTarget:IsA("Model") and closestTarget.PrimaryPart)
            local direction = (tHrp.Position - hrp.Position).Unit
            
            -- Server-side distance check bypass (spoof self position within 14 studs)
            local spoofedSelfPos = hrp.Position
            if closestDist > 14 then
                spoofedSelfPos = tHrp.Position - (direction * 14)
            end
            
            local args = {
                {
                    ["chargedAttack"] = { ["chargeRatio"] = 0 },
                    ["entityInstance"] = closestTarget,
                    ["validate"] = {
                        ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                        ["selfPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y, spoofedSelfPos.Z) },
                        ["raycast"] = {
                            ["cameraPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y + 3, spoofedSelfPos.Z) },
                            ["cursorDirection"] = { ["value"] = vec3(direction.X, direction.Y, direction.Z) }
                        }
                    },
                    ["weapon"] = weapon
                }
            }
            pcall(function() remote:FireServer(unpack(args)) end)
        end
    end
end

-- Listener for manual clicks
if not Mega.Objects.ReachConnections then Mega.Objects.ReachConnections = {} end
local connections = Mega.Objects.ReachConnections

for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

connections.ReachInput = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Trigger on click, but not if typing in chat
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        performReach()
    end
end)

function Mega.Features.Reach.SetEnabled(state)
    States.Combat.Reach.Enabled = state
end

-- Cleanup if module reloaded
if Mega.UnloadedSignal then
    Mega.UnloadedSignal:Connect(function()
        for _, conn in pairs(connections) do conn:Disconnect() end
    end)
end

return Mega.Features.Reach
