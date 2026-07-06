-- features/wall_hop.lua
-- Logic for Auto Wall Hop (Flick / Physics Glitch and Velocity / CFrame modes)

if not Mega.Features then Mega.Features = {} end
Mega.Features.WallHop = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.WallHop == nil then States.Player.WallHop = false end
if States.Player.WallHopMode == nil then States.Player.WallHopMode = "Flick" end
if States.Player.WallHopAngle == nil then States.Player.WallHopAngle = 80 end
if States.Player.WallHopForce == nil then States.Player.WallHopForce = 35 end

if not Mega.Objects.WallHopConnections then Mega.Objects.WallHopConnections = {} end
local connections = Mega.Objects.WallHopConnections

-- Clean up any existing connection
for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local lastHopTime = 0
local isFlicking = false

local function performWallHop()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    if humanoid.Health <= 0 then return end

    -- Raycast to detect wall in front of player
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.IgnoreWater = true

    -- Cast ray from HumanoidRootPart looking forward
    local rayOrigin = hrp.Position
    local rayDirection = hrp.CFrame.LookVector * 2.0 -- 2 studs detection range
    
    local raycastResult = Services.Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        local now = os.clock()
        if now - lastHopTime < 0.18 then return end -- Cooldown between hops to maintain rhythm
        lastHopTime = now

        local mode = States.Player.WallHopMode or "Flick"
        
        if mode == "Flick" then
            if isFlicking then return end
            isFlicking = true
            
            task.spawn(function()
                local camera = Services.Workspace.CurrentCamera
                if camera then
                    local angleRad = math.rad(States.Player.WallHopAngle or 80)
                    
                    -- Dynamic flick direction based on active strafe keys (A for left, D for right)
                    local isLeft = Services.UserInputService:IsKeyDown(Enum.KeyCode.A)
                    local isRight = Services.UserInputService:IsKeyDown(Enum.KeyCode.D)
                    
                    local directionSign = -1 -- Default right flick
                    if isLeft then
                        directionSign = 1 -- Flick Left
                    elseif isRight then
                        directionSign = -1 -- Flick Right
                    end
                    
                    local steps = 8 -- More frames for a smooth human-like swipe
                    -- Smoothly rotate camera to the side
                    for i = 1, steps do
                        camera.CFrame = camera.CFrame * CFrame.Angles(0, directionSign * (angleRad / steps), 0)
                        Services.RunService.RenderStepped:Wait()
                    end
                    
                    -- Trigger jump state at the peak of the flick (most realistic timing)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    
                    -- Brief pause at the peak of the turn to ensure Roblox replicates the rotation to other players
                    task.wait(0.04)
                    
                    -- Smoothly rotate camera back
                    for i = 1, steps do
                        camera.CFrame = camera.CFrame * CFrame.Angles(0, -directionSign * (angleRad / steps), 0)
                        Services.RunService.RenderStepped:Wait()
                    end
                end
                isFlicking = false
            end)
        elseif mode == "Velocity" then
            -- Cheat mode: reset jump state and apply vertical velocity
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            local force = States.Player.WallHopForce or 35
            hrp.Velocity = Vector3.new(hrp.Velocity.X, force, hrp.Velocity.Z)
        end
    end
end

function Mega.Features.WallHop.UpdateFPSLimit()
    if setfpscap then
        local cap = (States.Player.WallHop and States.Player.WallHopLimitFPS) and 60 or 999
        pcall(setfpscap, cap)
    end
end

function Mega.Features.WallHop.SetEnabled(state)
    States.Player.WallHop = state
    
    if connections.RenderStep then
        connections.RenderStep:Disconnect()
        connections.RenderStep = nil
    end

    if state then
        connections.RenderStep = Services.RunService.RenderStepped:Connect(function()
            -- Make sure user is not chatting
            if Services.UserInputService:GetFocusedTextBox() then return end
            
            -- Only Wall Hop if player is moving forward (W key) and holding/tapping Space
            local isMovingForward = Services.UserInputService:IsKeyDown(Enum.KeyCode.W)
            local isJumping = Services.UserInputService:IsKeyDown(Enum.KeyCode.Space)
            
            if isMovingForward and isJumping then
                performWallHop()
            end
        end)
    end
    
    Mega.Features.WallHop.UpdateFPSLimit()
end

if States.Player.WallHop then
    Mega.Features.WallHop.SetEnabled(true)
end

if Mega.UnloadedSignal then
    if not connections.Unload then
        connections.Unload = Mega.UnloadedSignal.Event:Connect(function()
            if setfpscap then pcall(setfpscap, 999) end
            for _, conn in pairs(connections) do 
                if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
            end
        end)
    end
end

return Mega.Features.WallHop
