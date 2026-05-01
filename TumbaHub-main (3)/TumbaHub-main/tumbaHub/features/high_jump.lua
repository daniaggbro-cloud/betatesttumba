-- features/high_jump.lua
-- Logic for High Jump / Boost (Ported from CatV6 style)

if not Mega.Features then Mega.Features = {} end
Mega.Features.HighJump = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.HighJump == nil then States.Player.HighJump = false end
if States.Player.HighJumpMode == nil then States.Player.HighJumpMode = "Velocity" end
if States.Player.HighJumpPower == nil then States.Player.HighJumpPower = 50 end
if States.Player.HighJumpAutoDisable == nil then States.Player.HighJumpAutoDisable = false end

if not Mega.Objects.HighJumpConnections then Mega.Objects.HighJumpConnections = {} end
local connections = Mega.Objects.HighJumpConnections

for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local function jump()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    if humanoid.Health <= 0 then return end

    local mode = States.Player.HighJumpMode or "Velocity"
    local power = States.Player.HighJumpPower or 50

    if mode == "Velocity" then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        hrp.Velocity = Vector3.new(hrp.Velocity.X, power, hrp.Velocity.Z)
    elseif mode == "CFrame" then
        local start = math.max(power - humanoid.JumpHeight, 0)
        task.spawn(function()
            repeat
                if not hrp or not humanoid or humanoid.Health <= 0 then break end
                hrp.CFrame = hrp.CFrame + Vector3.new(0, start * 0.016, 0)
                start = start - (workspace.Gravity * 0.016)
                task.wait()
            until start <= 0
        end)
    end
end

function Mega.Features.HighJump.SetEnabled(state)
    States.Player.HighJump = state
    
    -- Cleanup previous connections
    if connections.RenderStep then
        connections.RenderStep:Disconnect()
        connections.RenderStep = nil
    end

    if state then
        if States.Player.HighJumpAutoDisable then
            jump()
            -- Automatically toggle off in UI after a tiny delay
            task.delay(0.05, function()
                if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_high_jump"] then
                    Mega.Objects.Toggles["toggle_high_jump"](false)
                else
                    Mega.Features.HighJump.SetEnabled(false)
                end
            end)
        else
            connections.RenderStep = Services.RunService.RenderStepped:Connect(function()
                if not Services.UserInputService:GetFocusedTextBox() and Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    jump()
                end
            end)
        end
    end
end

if States.Player.HighJump then
    Mega.Features.HighJump.SetEnabled(true)
end

if Mega.UnloadedSignal then
    if not connections.Unload then
        connections.Unload = Mega.UnloadedSignal:Connect(function()
            for _, conn in pairs(connections) do 
                if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
            end
        end)
    end
end

return Mega.Features.HighJump
