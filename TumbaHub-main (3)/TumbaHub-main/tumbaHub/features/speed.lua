-- features/speed.lua
-- Advanced Speedhack module ported completely from Tumba V6
-- Supports: Velocity, Impulse, CFrame, TP, WalkSpeed, Pulse modes

if not Mega.Features then Mega.Features = {} end
Mega.Features.Speed = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.Speed == nil then States.Player.Speed = false end
if States.Player.SpeedValue == nil then States.Player.SpeedValue = 23 end
if States.Player.SpeedMode == nil then States.Player.SpeedMode = "Velocity" end
if States.Player.SpeedMoveMode == nil then States.Player.SpeedMoveMode = "MoveDirection" end
if States.Player.SpeedTPFrequency == nil then States.Player.SpeedTPFrequency = 0.5 end
if States.Player.SpeedPulseLength == nil then States.Player.SpeedPulseLength = 0.5 end
if States.Player.SpeedPulseDelay == nil then States.Player.SpeedPulseDelay = 0.5 end
if States.Player.SpeedWallCheck == nil then States.Player.SpeedWallCheck = true end
if States.Player.SpeedAutoJump == nil then States.Player.SpeedAutoJump = false end
if States.Player.SpeedCustomJump == nil then States.Player.SpeedCustomJump = false end
if States.Player.SpeedJumpPower == nil then States.Player.SpeedJumpPower = 30 end
if States.Player.SpeedTPTiming == nil then States.Player.SpeedTPTiming = 0 end

if not Mega.Objects.SpeedConnections then Mega.Objects.SpeedConnections = {} end
local connections = Mega.Objects.SpeedConnections

local function CleanupConnections()
    for k, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(connections)
end

-- Key states for Direct movement calculation
local w, s, a, d = 0, 0, 0, 0

local function calculateMoveVector(vec)
    local camera = Services.Workspace.CurrentCamera or Services.Workspace:FindFirstChildWhichIsA("Camera")
    if not camera then return Vector3.zero end
    
    local c, sVal
    local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = camera.CFrame:GetComponents()
    if R12 < 1 and R12 > -1 then
        c = R22
        sVal = R02
    else
        c = R00
        sVal = -R01 * math.sign(R12)
    end
    vec = Vector3.new((c * vec.X + sVal * vec.Z), 0, (c * vec.Z - sVal * vec.X)) / math.sqrt(c * c + sVal * sVal)
    return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local SpeedMethods = {
    Velocity = function(hrp, hum, speed, moveDirection)
        hrp.AssemblyLinearVelocity = (moveDirection * speed) + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
    end,
    Impulse = function(hrp, hum, speed, moveDirection)
        local diff = ((moveDirection * speed) - hrp.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
        if diff.Magnitude > (moveDirection == Vector3.zero and 10 or 2) then
            hrp:ApplyImpulse(diff * hrp.AssemblyMass)
        end
    end,
    CFrame = function(hrp, hum, speed, moveDirection, dt, wallCheck)
        local dest = (moveDirection * math.max(speed - hum.WalkSpeed, 0) * dt)
        if wallCheck then
            local rayCheck = RaycastParams.new()
            rayCheck.FilterDescendantsInstances = {LocalPlayer.Character, Services.Workspace.CurrentCamera}
            rayCheck.CollisionGroup = hrp.CollisionGroup
            rayCheck.RespectCanCollide = true
            local ray = Services.Workspace:Raycast(hrp.Position, dest, rayCheck)
            if ray then
                dest = ((ray.Position + ray.Normal) - hrp.Position)
            end
        end
        hrp.CFrame = hrp.CFrame + dest
    end,
    TP = function(hrp, hum, speed, moveDirection, dt, wallCheck)
        local timing = States.Player.SpeedTPTiming or 0
        local freq = States.Player.SpeedTPFrequency or 0.5
        if timing < os.clock() then
            States.Player.SpeedTPTiming = os.clock() + freq
            local dest = (moveDirection * math.max(speed - hum.WalkSpeed, 0))
            if wallCheck then
                local rayCheck = RaycastParams.new()
                rayCheck.FilterDescendantsInstances = {LocalPlayer.Character, Services.Workspace.CurrentCamera}
                rayCheck.CollisionGroup = hrp.CollisionGroup
                rayCheck.RespectCanCollide = true
                local ray = Services.Workspace:Raycast(hrp.Position, dest, rayCheck)
                if ray then
                    dest = ((ray.Position + ray.Normal) - hrp.Position)
                end
            end
            hrp.CFrame = hrp.CFrame + dest
        end
    end,
    WalkSpeed = function(hrp, hum, speed)
        if not States.Player.OriginalWalkSpeed then 
            States.Player.OriginalWalkSpeed = hum.WalkSpeed 
        end
        hum.WalkSpeed = speed
    end,
    Pulse = function(hrp, hum, speed, moveDirection)
        local dt = math.max(speed - hum.WalkSpeed, 0)
        local length = States.Player.SpeedPulseLength or 0.5
        local delay = States.Player.SpeedPulseDelay or 0.5
        dt = dt * (1 - math.min((os.clock() % (length + delay)) / length, 1))
        hrp.AssemblyLinearVelocity = (moveDirection * (hum.WalkSpeed + dt)) + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
    end
}

function Mega.Features.Speed.SetEnabled(state)
    States.Player.Speed = state
    CleanupConnections()
    
    if state then
        -- Track keyboard keybind inputs for Direct movement calculation
        w = Services.UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0
        s = Services.UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
        a = Services.UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        d = Services.UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        
        connections.InputBegan = Services.UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then w = -1
            elseif input.KeyCode == Enum.KeyCode.S then s = 1
            elseif input.KeyCode == Enum.KeyCode.A then a = -1
            elseif input.KeyCode == Enum.KeyCode.D then d = 1 end
        end)
        
        connections.InputEnded = Services.UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then w = 0
            elseif input.KeyCode == Enum.KeyCode.S then s = 0
            elseif input.KeyCode == Enum.KeyCode.A then a = 0
            elseif input.KeyCode == Enum.KeyCode.D then d = 0 end
        end)

        connections.SpeedLoop = Services.RunService.PreSimulation:Connect(function(dt)
            local char = LocalPlayer.Character
            if not char then return end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end
            
            -- Ignore climbing states
            local stateType = hum:GetState()
            if stateType == Enum.HumanoidStateType.Climbing then return end
            
            -- Bypass Fly & LongJump active states to not conflicts
            if States.Player.Fly or States.Player.LongJump then return end
            
            -- Calculate movement vector
            local movevec
            if States.Player.SpeedMoveMode == "Direct" then
                movevec = calculateMoveVector(Vector3.new(a + d, 0, w + s))
            else
                movevec = hum.MoveDirection
            end
            
            local speedVal = States.Player.SpeedValue or 23
            local mode = States.Player.SpeedMode or "Velocity"
            
            -- Execute selected Speed Method
            if SpeedMethods[mode] then
                SpeedMethods[mode](hrp, hum, speedVal, movevec, dt, States.Player.SpeedWallCheck)
            end
            
            -- AutoJump Logic
            if States.Player.SpeedAutoJump and hum.FloorMaterial ~= Enum.Material.Air and movevec ~= Vector3.zero then
                if States.Player.SpeedCustomJump then
                    local currentVel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, States.Player.SpeedJumpPower or 30, currentVel.Z)
                else
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        -- Restore original WalkSpeed if it was changed
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and States.Player.OriginalWalkSpeed then
            hum.WalkSpeed = States.Player.OriginalWalkSpeed
        end
        States.Player.OriginalWalkSpeed = nil
    end
end

if States.Player.Speed then
    Mega.Features.Speed.SetEnabled(true)
end

if Mega.UnloadedSignal then
    if not connections.Unload then
        connections.Unload = Mega.UnloadedSignal.Event:Connect(function()
            CleanupConnections()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and States.Player.OriginalWalkSpeed then
                hum.WalkSpeed = States.Player.OriginalWalkSpeed
            end
        end)
    end
end

return Mega.Features.Speed
