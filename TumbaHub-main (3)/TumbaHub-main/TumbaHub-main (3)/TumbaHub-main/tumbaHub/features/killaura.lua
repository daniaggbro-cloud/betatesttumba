-- features/killaura.lua
-- Logic for Killaura (Original Logic Restored)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Killaura = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Combat then States.Combat = {} end
if not States.Combat.Killaura then
    States.Combat.Killaura = { Enabled = false, Range = 25, Delay = 0, TargetESP = true }
elseif States.Combat.Killaura.TargetESP == nil then
    States.Combat.Killaura.TargetESP = true
end

if not Mega.Objects.KillauraConnections then Mega.Objects.KillauraConnections = {} end
local connections = Mega.Objects.KillauraConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

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
    if tool and (tool.Name:lower():find("sword") or tool.Name:lower():find("blade") or tool.Name:lower():find("scythe")) then
        return tool
    end
    
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name:lower():find("sword") or v.Name:lower():find("blade") or v.Name:lower():find("scythe") then 
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
        targetMarkerArrow.Name = "KillauraArrow"
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
        targetMarkerCircle.Name = "KillauraCircle"
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

local killauraActive = false

function Mega.Features.Killaura.SetEnabled(state)
    States.Combat.Killaura.Enabled = state
    
    if not state then
        if targetMarkerArrow then targetMarkerArrow.Adornee = nil end
        if targetMarkerCircle then targetMarkerCircle.Adornee = nil end
    end
    
    if state and not killauraActive then
        killauraActive = true
        task.spawn(function()
            while States.Combat.Killaura.Enabled do
                if Mega.Unloaded then break end

                if SwordHitRemote then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local weapon = getWeapon()
                    
                    local closestTarget = nil
                    local closestDist = States.Combat.Killaura.Range

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
                                        if dist < States.Combat.Killaura.Range and dist > 0 then
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
                    if closestTarget and States.Combat.Killaura.TargetESP then
                        local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
                        arrow.Adornee = tHrp
                        circle.Adornee = tHrp
                        arrow.StudsOffset = Vector3.new(0, 4 + math.sin(tick() * 6) * 0.5, 0)
                        circle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), tick() * 3, 0)
                        circle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                    else
                        if arrow then arrow.Adornee = nil end
                        if circle then circle.Adornee = nil end
                    end
                end
                
                if States.Combat.Killaura.Delay > 0 then
                    task.wait(States.Combat.Killaura.Delay / 1000)
                else
                    Services.RunService.Heartbeat:Wait()
                end
            end
            killauraActive = false
        end)
    end
end
