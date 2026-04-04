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
        if player ~= localPlayer and player.Character and player.Character.PrimaryPart and player.Character.Humanoid.Health > 0 then
            local targetPosition, onScreen = Camera:WorldToScreenPoint(player.Character.PrimaryPart.Position)
            if onScreen then
                local distance = (mousePosition - Vector2.new(targetPosition.X, targetPosition.Y)).Magnitude
                if distance < closestDistance and distance <= States.AimAssist.FOV then
                    local realDistance = (localPlayer.Character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
                    if realDistance <= States.AimAssist.Range then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function aimbotLoop()
    if not States.AimAssist.Active then return end

    local targetPlayer = getClosestPlayer()
    if targetPlayer and targetPlayer.Character then
        local targetPart = targetPlayer.Character:FindFirstChild(States.AimAssist.TargetPart) or targetPlayer.Character.PrimaryPart
        if targetPart then
            local newCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            if not States.AimAssist.SilentAim then
                -- Smooth tweening for visible aim
                local tweenInfo = TweenInfo.new(States.AimAssist.Smoothness, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                local tween = Services.TweenService:Create(Camera, tweenInfo, { CFrame = newCFrame })
                tween:Play()
            else
                -- For silent aim, you would typically hook into the game's aiming functions.
                -- A simple CFrame change is a basic implementation.
                Camera.CFrame = newCFrame
            end
        end
    end
end

function Mega.Features.Aimbot.SetEnabled(state)
    States.AimAssist.Enabled = state
    updateFovCircle()
    if state then
        -- Listen for key press to activate aim
        Services.UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode.Name == States.Keybinds.AimAssist then
                States.AimAssist.Active = true
            end
        end)
        Services.UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode.Name == States.Keybinds.AimAssist then
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

