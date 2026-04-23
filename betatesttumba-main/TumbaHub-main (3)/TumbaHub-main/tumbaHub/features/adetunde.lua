-- features/adetunde.lua
-- Logic for Adetunde (Multi-Aura Variant of Killaura)
-- WARNING: May cause ping spikes!

if not Mega.Features then Mega.Features = {} end
Mega.Features.Adetunde = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.Adetunde then
    States.Misc.Adetunde = { Enabled = false, Range = 50, Delay = 0, TargetESP = true, Keybind = "None" }
elseif States.Misc.Adetunde.TargetESP == nil then
    States.Misc.Adetunde.TargetESP = true
end
if States.Misc.Adetunde.Keybind == nil then States.Misc.Adetunde.Keybind = "None" end

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

local targetMarkerArrow
local targetMarkerCircle

local function GetTargetVisuals()
    if not targetMarkerArrow then
        targetMarkerArrow = Instance.new("BillboardGui")
        targetMarkerArrow.Name = "AdetundeArrow"
        targetMarkerArrow.Size = UDim2.new(0, 50, 0, 50)
        targetMarkerArrow.StudsOffset = Vector3.new(0, 4, 0)
        targetMarkerArrow.AlwaysOnTop = true
        
        local arrowText = Instance.new("TextLabel", targetMarkerArrow)
        arrowText.Size = UDim2.new(1, 0, 1, 0)
        arrowText.BackgroundTransparency = 1
        arrowText.Text = "▼"
        arrowText.TextColor3 = Color3.fromRGB(255, 50, 50)
        arrowText.TextScaled = true
        arrowText.TextStrokeTransparency = 0
        arrowText.Font = Enum.Font.GothamBlack
    end
    
    if not targetMarkerCircle then
        targetMarkerCircle = Instance.new("CylinderHandleAdornment")
        targetMarkerCircle.Name = "AdetundeCircle"
        targetMarkerCircle.Height = 0.05
        targetMarkerCircle.Radius = 3
        targetMarkerCircle.InnerRadius = 2.7
        targetMarkerCircle.Color3 = Color3.fromRGB(255, 50, 50)
        targetMarkerCircle.Transparency = 0.3
        targetMarkerCircle.AlwaysOnTop = true
        targetMarkerCircle.ZIndex = 1
        targetMarkerCircle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    
    if Services.CoreGui then
        local container = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui
        if targetMarkerArrow.Parent ~= container then targetMarkerArrow.Parent = container end
        if targetMarkerCircle.Parent ~= container then targetMarkerCircle.Parent = container end
    end
    
    return targetMarkerArrow, targetMarkerCircle
end

local adetundeActive = false

function Mega.Features.Adetunde.SetEnabled(state)
    States.Misc.Adetunde.Enabled = state
    
    if not state then
        if targetMarkerArrow then targetMarkerArrow.Adornee = nil end
        if targetMarkerCircle then targetMarkerCircle.Adornee = nil end
    end
    
    if state and not adetundeActive then
        adetundeActive = true
        task.spawn(function()
            while States.Misc.Adetunde.Enabled do
                if Mega.Unloaded then break end

                if SwordHitRemote then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local weapon = getWeapon()
                    
                    local closestTarget = nil
                    local currentRange = math.min(States.Misc.Adetunde.Range, 50)
                    local closestDist = currentRange

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
                                        if dist <= currentRange and dist > 0 then
                                            if dist < closestDist then
                                                closestDist = dist
                                                closestTarget = obj
                                            end

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
                    
                    local arrow, circle = GetTargetVisuals()
                    if closestTarget and States.Misc.Adetunde.TargetESP then
                        local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
                        arrow.Adornee = tHrp
                        circle.Adornee = tHrp
                        arrow.StudsOffset = Vector3.new(0, 4 + math.sin(tick() * 6) * 0.5, 0)
                        circle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                    else
                        if arrow then arrow.Adornee = nil end
                        if circle then circle.Adornee = nil end
                    end
                end
                
                if States.Misc.Adetunde.Delay > 0 then
                    task.wait(States.Misc.Adetunde.Delay / 1000)
                else
                    Services.RunService.Heartbeat:Wait()
                end
            end
            adetundeActive = false
        end)
    end
end
