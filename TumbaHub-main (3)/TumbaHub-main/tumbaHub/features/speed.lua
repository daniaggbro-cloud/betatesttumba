-- features/speed.lua
-- Advanced Speedhack module with Bhop support and animation fixes

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
        connections.SpeedLoop = Services.RunService.Heartbeat:Connect(function(deltaTime)
            if not States.Player.Speed then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local targetSpeed = States.Player.SpeedValue or 23
                local mode = States.Player.SpeedMode or "CFrame"
                
                -- Check if the player is trying to move
                if hum.MoveDirection.Magnitude > 0 then
                    local moveDir = hum.MoveDirection
                    
                    if mode == "CFrame" then
                        -- FIX ANIMATION: We do NOT zero out the velocity. 
                        -- We let the normal WalkSpeed (16) handle physics and animations,
                        -- then we use CFrame to teleport the REMAINING difference.
                        local extraSpeed = math.max(0, targetSpeed - 16)
                        
                        if extraSpeed > 0 then
                            local moveVector = moveDir * extraSpeed * deltaTime
                            hrp.CFrame = hrp.CFrame + moveVector
                        end
                        
                    elseif mode == "Bhop" then
                        -- BUNNY HOP METHOD: Best for strict anti-cheats.
                        -- Force jump if on ground
                        if hum.FloorMaterial ~= Enum.Material.Air then
                            hum.Jump = true
                        end
                        
                        -- Apply speed boost while in the air
                        -- Bedwars is often more lenient with horizontal distance when falling/jumping
                        local extraSpeed = math.max(0, targetSpeed - 16)
                        
                        if extraSpeed > 0 then
                            local moveVector = moveDir * extraSpeed * deltaTime
                            hrp.CFrame = hrp.CFrame + moveVector
                            
                            -- Slight velocity push to maintain momentum
                            local currentVel = hrp.AssemblyLinearVelocity
                            hrp.AssemblyLinearVelocity = Vector3.new(
                                moveDir.X * targetSpeed, 
                                currentVel.Y, 
                                moveDir.Z * targetSpeed
                            )
                        end
                    end
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
