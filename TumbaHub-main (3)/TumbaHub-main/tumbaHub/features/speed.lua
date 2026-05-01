-- features/speed.lua
-- Advanced Velocity-Sync Speedhack module

if not Mega.Features then Mega.Features = {} end
Mega.Features.Speed = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

if not Mega.Objects.SpeedConnections then Mega.Objects.SpeedConnections = {} end
local connections = Mega.Objects.SpeedConnections

local function CleanupConnections()
    for k, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(connections)
end

function Mega.Features.Speed.SetEnabled(state)
    States.Player.Speed = state
    CleanupConnections()
    
    if state then
        -- We use Heartbeat because it runs after physics calculation, 
        -- making CFrame micro-teleports smoother and less jittery.
        connections.SpeedLoop = Services.RunService.Heartbeat:Connect(function(deltaTime)
            if not States.Player.Speed then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                -- Target speed from the menu slider
                local targetSpeed = States.Player.SpeedValue or 23
                
                -- Check if the player is trying to move (WASD/Joystick)
                if hum.MoveDirection.Magnitude > 0 then
                    -- 1. Velocity-Sync: Reduce the physics velocity to near-zero on the X/Z plane.
                    -- This tricks the server's velocity magnitude checks into thinking we are walking normally or lagging.
                    local currentVel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.01, currentVel.Y, currentVel.Z * 0.01)
                    
                    -- 2. CFrame Translation: Manually move the player forward.
                    -- We use the full targetSpeed because we zeroed out the native velocity.
                    local moveVector = hum.MoveDirection * targetSpeed * deltaTime
                    hrp.CFrame = hrp.CFrame + moveVector
                end
            end
        end)
    end
end

-- Initialize if it was enabled before the script loaded
if States.Player.Speed then
    Mega.Features.Speed.SetEnabled(true)
end

-- Handle Script Unload
if Mega.UnloadedSignal then
    if not connections.Unload then
        connections.Unload = Mega.UnloadedSignal:Connect(CleanupConnections)
    end
end

return Mega.Features.Speed
