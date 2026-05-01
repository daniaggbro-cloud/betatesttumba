-- features/high_jump.lua
-- Logic for High Jump / Boost

if not Mega.Features then Mega.Features = {} end
Mega.Features.HighJump = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.HighJump == nil then States.Player.HighJump = false end
if States.Player.HighJumpPower == nil then States.Player.HighJumpPower = 150 end

if not Mega.Objects.HighJumpConnections then Mega.Objects.HighJumpConnections = {} end
local connections = Mega.Objects.HighJumpConnections

for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local lastJump = 0

local function OnJumpRequest()
    if not States.Player.HighJump then return end
    
    -- Prevent spamming
    if tick() - lastJump < 1 then return end
    lastJump = tick()
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and humanoid then
            -- We apply the velocity
            local bv = Instance.new("BodyVelocity")
            bv.Name = "HighJumpBoost"
            bv.MaxForce = Vector3.new(0, 100000, 0)
            bv.Velocity = Vector3.new(0, States.Player.HighJumpPower, 0)
            bv.Parent = hrp
            
            task.delay(0.15, function()
                if bv and bv.Parent then 
                    bv:Destroy() 
                end
            end)
        end
    end
end

function Mega.Features.HighJump.SetEnabled(state)
    States.Player.HighJump = state
    if state then
        if not connections.JumpReq then
            connections.JumpReq = Services.UserInputService.JumpRequest:Connect(OnJumpRequest)
        end
    else
        if connections.JumpReq then
            connections.JumpReq:Disconnect()
            connections.JumpReq = nil
        end
        -- Cleanup existing boosts
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("HighJumpBoost") then
                hrp.HighJumpBoost:Destroy()
            end
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
