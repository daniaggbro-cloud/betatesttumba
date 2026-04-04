-- features/adetunde.lua
-- Logic for Adetunde (Massive Instant Burst Hit)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Adetunde = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.Adetunde then
    States.Misc.Adetunde = { Enabled = false, Range = 100000, Duration = 5, Keybind = "None" }
elseif States.Misc.Adetunde.Keybind == nil then
    States.Misc.Adetunde.Keybind = "None"
end

if not Mega.Objects.AdetundeConnections then Mega.Objects.AdetundeConnections = {} end
local connections = Mega.Objects.AdetundeConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

connections.AdetundeInput = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode.Name == States.Misc.Adetunde.Keybind and input.KeyCode.Name ~= "None" then
        local newState = not States.Misc.Adetunde.Enabled
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_adetunde"] then
            Mega.Objects.Toggles["toggle_adetunde"](newState)
        else
            Mega.Features.Adetunde.SetEnabled(newState)
        end
    end
end)

local SwordHitRemote
task.spawn(function()
    pcall(function()
        SwordHitRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SwordHit")
    end)
end)

local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        return char.HandInvItem.Value
    end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool.Name:lower():find("sword") or tool.Name:lower():find("blade") or tool.Name:lower():find("scythe") or tool.Name:lower():find("hammer")) then
        return tool
    end
    
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name:lower():find("sword") or v.Name:lower():find("blade") or v.Name:lower():find("scythe") or v.Name:lower():find("hammer") then 
                return v 
            end
        end
    end
    return nil
end

local vec3 = (vector and vector.create) or Vector3.new

function Mega.Features.Adetunde.SetEnabled(state)
    States.Misc.Adetunde.Enabled = state
    
    if state then
        task.spawn(function()
            local durationSec = States.Misc.Adetunde.Duration / 10
            local endTime = tick() + durationSec
            
            while tick() < endTime and States.Misc.Adetunde.Enabled and not Mega.Unloaded do
                if SwordHitRemote then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local weapon = getWeapon()
                    
                    if hrp and weapon then
                        for _, obj in pairs(Services.Workspace:GetChildren()) do
                            if obj ~= char and (obj:FindFirstChild("Humanoid") or obj.Name:find("Dummy")) then
                                local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                local hum = obj:FindFirstChild("Humanoid")
                                
                                if tHrp and (not hum or hum.Health > 0) then
                                    local p = Services.Players:GetPlayerFromCharacter(obj)
                                    local isEnemy = true
                                    if p and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                                        isEnemy = false
                                    end

                                    if isEnemy then
                                        local dist = (hrp.Position - tHrp.Position).Magnitude
                                        if dist <= States.Misc.Adetunde.Range and dist > 0 then
                                            local direction = (tHrp.Position - hrp.Position).Unit
                                            local spoofedSelfPos = hrp.Position
                                            if dist > 14 then
                                                spoofedSelfPos = tHrp.Position - (direction * 14)
                                            end
                                            
                                            local args = {
                                                {
                                                    ["chargedAttack"] = { ["chargeRatio"] = 0 },
                                                    ["entityInstance"] = obj,
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
                                            pcall(function() SwordHitRemote:FireServer(unpack(args)) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                Services.RunService.Heartbeat:Wait()
            end
            
            States.Misc.Adetunde.Enabled = false
            if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_adetunde"] then
                Mega.Objects.Toggles["toggle_adetunde"](false)
            end
        end)
    end
end
