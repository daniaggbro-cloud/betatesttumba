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

local lastHitTime = 0
local COOLDOWN = 0.12 -- 120ms cooldown between reach hits

-- Main logic function
local function performReach()
    if not States.Combat.Reach.Enabled then return end
    
    -- Cooldown check
    local now = tick()
    if now - lastHitTime < COOLDOWN then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local cam = Services.Workspace.CurrentCamera
    local weapon = getWeapon()
    local remote = GetSwordRemote()
    
    if hrp and cam and weapon and remote then
        local maxReach = States.Combat.Reach.Distance or 18
        local bestTarget = nil
        local bestDot = 0.8 -- Minimum dot product (FOV check, more strict)
        
        local camPos = cam.CFrame.Position
        local lookDir = cam.CFrame.LookVector
        local myPos = hrp.Position
        
        -- Optimized Target search (Iterate players instead of workspace)
        local players = Services.Players:GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p ~= LocalPlayer and p.Character then
                local targetChar = p.Character
                local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
                local hum = targetChar:FindFirstChild("Humanoid")
                
                if tHrp and hum and hum.Health > 0 then
                    -- Team check
                    if not (p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team) then
                        local targetPos = tHrp.Position
                        local dist = (myPos - targetPos).Magnitude
                        
                        if dist <= maxReach and dist > 0 then
                            local dirToTarget = (targetPos - camPos).Unit
                            local dot = lookDir:Dot(dirToTarget)
                            
                            if dot > bestDot then
                                bestDot = dot
                                bestTarget = targetChar
                            end
                        end
                    end
                end
            end
        end
        
        -- Also check dummies (optional but common in testing)
        if not bestTarget then
            for _, obj in pairs(Services.Workspace:GetChildren()) do
                if obj.Name:find("Dummy") or obj:GetAttribute("IsDummy") then
                    local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if tHrp then
                        local targetPos = tHrp.Position
                        local dist = (myPos - targetPos).Magnitude
                        if dist <= maxReach and dist > 0 then
                            local dirToTarget = (targetPos - camPos).Unit
                            local dot = lookDir:Dot(dirToTarget)
                            if dot > bestDot then
                                bestDot = dot
                                bestTarget = obj
                            end
                        end
                    end
                end
            end
        end
        
        -- Fire hit if target found
        if bestTarget then
            lastHitTime = now -- Update cooldown
            
            local tHrp = bestTarget:FindFirstChild("HumanoidRootPart") or bestTarget.PrimaryPart
            local targetPos = tHrp.Position
            local direction = (targetPos - myPos).Unit
            local dist = (myPos - targetPos).Magnitude
            
            -- Server-side distance check bypass
            local spoofedSelfPos = myPos
            if dist > 14 then
                spoofedSelfPos = targetPos - (direction * 14)
            end
            
            local args = {
                {
                    ["chargedAttack"] = { ["chargeRatio"] = 0 },
                    ["entityInstance"] = bestTarget,
                    ["validate"] = {
                        ["targetPosition"] = { ["value"] = vec3(targetPos.X, targetPos.Y, targetPos.Z) },
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
