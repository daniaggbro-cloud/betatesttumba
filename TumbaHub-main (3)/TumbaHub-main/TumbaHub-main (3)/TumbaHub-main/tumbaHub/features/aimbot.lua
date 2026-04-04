-- features/aimbot.lua
-- All logic for the Aimbot / Aim Assist feature.

Mega.Features.Aimbot = {}

local Services = Mega.Services
local States = Mega.States
local Camera = Services.Workspace.CurrentCamera

local aimbotConnection = nil
local fovCircle = nil

local function updateFovCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Radius = 100
        fovCircle.Color = States.AimAssist.FOVColor
        fovCircle.Thickness = 2
        fovCircle.Filled = false
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    fovCircle.Visible = States.AimAssist.Enabled and States.AimAssist.ShowFOV
    if fovCircle.Visible then
        fovCircle.Radius = States.AimAssist.FOV
        fovCircle.Color = States.AimAssist.FOVColor
    end
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local localPlayer = Services.LocalPlayer
    local mousePosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local root = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- Team check to prevent aiming at friends
                if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
                    continue
                end

                local targetPosition, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                    local distance = (mousePosition - Vector2.new(targetPosition.X, targetPosition.Y)).Magnitude
                    if distance <= (States.AimAssist.FOV or 120) then
                        local lpPos = localPlayer.Character and localPlayer.Character.PrimaryPart and localPlayer.Character.PrimaryPart.Position
                        local realDistance = lpPos and (lpPos - root.Position).Magnitude or 0
                        
                        if realDistance <= (States.AimAssist.Range or 100) then
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function aimbotLoop()
    if not (States.AimAssist.Active and States.AimAssist.Enabled) then return end

    local targetPlayer = getClosestPlayer()
    if targetPlayer and targetPlayer.Character then
        local targetPart = targetPlayer.Character:FindFirstChild(States.AimAssist.TargetPart or "Head") or targetPlayer.Character.PrimaryPart
        if targetPart then
            local targetPos = targetPart.Position
            -- Simple prediction if enabled
            if States.AimAssist.Prediction and targetPart:IsA("BasePart") then
                targetPos = targetPos + (targetPart.Velocity * 0.1)
            end

            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            if not States.AimAssist.SilentAim then
                -- Smooth Lerp instead of TweenService for better cam control
                local smoothness = math.clamp(1 - (States.AimAssist.Smoothness or 0.4), 0.01, 0.99)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothness)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end
end

function Mega.Features.Aimbot.SetEnabled(state)
    States.AimAssist.Enabled = state
    updateFovCircle()
    if state then
        -- Listen for key press to activate aim
        local function getAimKey()
            return Enum.KeyCode[States.Keybinds.AimAssist or "R"]
        end

        Services.UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == getAimKey() then
                States.AimAssist.Active = true
            end
        end)
        Services.UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == getAimKey() then
                States.AimAssist.Active = false
            end
        end)
        
        if not aimbotConnection then
            aimbotConnection = Services.RunService.RenderStepped:Connect(aimbotLoop)
        end
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
        States.AimAssist.Active = false
    end
end

-- Connect FOV circle update to settings changes
Mega.Services.RunService.RenderStepped:Connect(function()
    if States.AimAssist.Enabled then
        updateFovCircle()
    end
end)

