-- features/long_jump.lua
-- Item-Abuse Long Jump for Bedwars (CatV6 Port with Fireball/TNT Support)

if not Mega.Features then Mega.Features = {} end
Mega.Features.LongJump = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.LongJump == nil then States.Player.LongJump = false end
if States.Player.LongJumpSpeed == nil then States.Player.LongJumpSpeed = 37 end
if States.Player.LongJumpCamera == nil then States.Player.LongJumpCamera = false end

if not Mega.Objects.LongJumpConnections then Mega.Objects.LongJumpConnections = {} end
local connections = Mega.Objects.LongJumpConnections

for _, conn in pairs(connections) do 
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local jumpTick = 0
local jumpSpeed = 0
local direction = Vector3.new(0,0,0)
local startPos = nil

local isWaitingForKnockback = false
local expectedSpeed = 0
local expectedDir = Vector3.new(0,0,0)

-- Remotes
local useAbilityRemote = nil
task.spawn(function()
    local events = Services.ReplicatedStorage:FindFirstChild("events-@easy-games/game-core:shared/game-core-networking@getEvents.Events")
    if events then
        useAbilityRemote = events:FindFirstChild("useAbility")
    end
end)

local function getEquippedItem()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    
    -- Bedwars uses HandInvItem to store the equipped tool reference
    local handInvItem = char:FindFirstChild("HandInvItem")
    if handInvItem and handInvItem.Value then
        return handInvItem.Value.Name, handInvItem.Value
    end
    
    -- Fallback for standard games
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then return tool.Name, tool end
    return nil, nil
end

local function executeJump()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local cam = Services.Workspace.CurrentCamera
    local dir = (States.Player.LongJumpCamera and cam) and cam.CFrame.LookVector or hrp.CFrame.LookVector
    dir = Vector3.new(dir.X, 0, dir.Z).Unit
    local pos = hrp.Position

    local itemName, tool = getEquippedItem()
    local speedVal = States.Player.LongJumpSpeed or 37
    startPos = hrp.Position

    if itemName and itemName:lower():find("dao") then
        if useAbilityRemote then
            useAbilityRemote:FireServer('dash', {
                direction = dir,
                origin = pos,
                weapon = itemName
            })
            jumpSpeed = 4.5 * speedVal
            jumpTick = tick() + 2.4
            direction = dir
        end
    elseif itemName and (itemName:lower():find("jade_hammer") or itemName:lower():find("void_axe")) then
        if useAbilityRemote then
            useAbilityRemote:FireServer(itemName..'_jump', {})
            jumpSpeed = 1.4 * speedVal
            jumpTick = tick() + 2.5
            direction = dir
        end
    elseif itemName and itemName:lower():find("fireball") then
        local projectileRemote = Mega.GetRemote("ProjectileFire")
        if not projectileRemote then
            pcall(function()
                projectileRemote = Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.ProjectileFire
            end)
        end
        if projectileRemote then
            -- Throw fireball straight down
            local shootDir = Vector3.new(0, -60, 0)
            local guid = HttpService:GenerateGUID(true)
            
            pcall(function()
                projectileRemote:InvokeServer(
                    tool,
                    "fireball",
                    "fireball",
                    hrp.Position,
                    hrp.Position,
                    shootDir,
                    guid,
                    {shotId = guid, drawDurationSec = 1},
                    workspace:GetServerTimeNow() - 0.045
                )
            end)

            -- Freeze player to wait for explosion
            hrp.Anchored = true
            isWaitingForKnockback = true
            expectedDir = dir
            expectedSpeed = speedVal * 1.8 
            
            -- Setup Health Changed Connection
            if connections.HealthCheck then connections.HealthCheck:Disconnect() end
            connections.HealthCheck = hum.HealthChanged:Connect(function(health)
                if isWaitingForKnockback then
                    isWaitingForKnockback = false
                    hrp.Anchored = false
                    jumpSpeed = expectedSpeed
                    jumpTick = tick() + 2.5
                    direction = expectedDir
                    if connections.HealthCheck then connections.HealthCheck:Disconnect() end
                end
            end)

            -- Failsafe: Unfreeze after 1.5s if no explosion hit
            task.delay(1.5, function()
                if isWaitingForKnockback then
                    isWaitingForKnockback = false
                    if hrp then hrp.Anchored = false end
                    if connections.HealthCheck then connections.HealthCheck:Disconnect() end
                    if States.Player.LongJump then
                        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_long_jump"] then
                            Mega.Objects.Toggles["toggle_long_jump"](false)
                        else
                            Mega.Features.LongJump.SetEnabled(false)
                        end
                    end
                end
            end)
        end
    else
        -- Fallback removed: If no valid item is held, don't do a generic jump 
        -- because it will just trigger anticheat and rubberband.
        if States.Player.LongJump then
            task.delay(0.1, function()
                if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_long_jump"] then
                    Mega.Objects.Toggles["toggle_long_jump"](false)
                end
            end)
        end
    end
end

function Mega.Features.LongJump.SetEnabled(state)
    States.Player.LongJump = state

    if connections.PreSim then
        connections.PreSim:Disconnect()
        connections.PreSim = nil
    end

    if state then
        executeJump()
        
        connections.PreSim = Services.RunService.PreSimulation:Connect(function(dt)
            if isWaitingForKnockback then return end -- Don't apply velocity while frozen
            
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            if jumpTick > tick() then
                local currentVelocity = hrp.AssemblyLinearVelocity
                local targetVel = direction * (16 + ((jumpTick - tick()) > 1.1 and jumpSpeed or 0))
                
                hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, currentVelocity.Y, targetVel.Z)
                
                if hum.FloorMaterial == Enum.Material.Air and not startPos then
                    hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, dt * (Services.Workspace.Gravity - 23), 0)
                else
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 15, hrp.AssemblyLinearVelocity.Z)
                end
                startPos = nil
            elseif jumpSpeed > 0 then
                -- Jump finished
                if startPos then
                    hrp.CFrame = CFrame.lookAlong(startPos, hrp.CFrame.LookVector)
                end
                hrp.AssemblyLinearVelocity = Vector3.zero
                jumpSpeed = 0
                
                -- Auto Disable when finished
                if States.Player.LongJump then
                    States.Player.LongJump = false
                    if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_long_jump"] then
                        Mega.Objects.Toggles["toggle_long_jump"](false)
                    else
                        Mega.Features.LongJump.SetEnabled(false)
                    end
                end
            end
        end)
    else
        isWaitingForKnockback = false
        jumpTick = tick()
        direction = Vector3.new(0,0,0)
        jumpSpeed = 0
        
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored then hrp.Anchored = false end
        end
    end
end

if States.Player.LongJump then
    Mega.Features.LongJump.SetEnabled(true)
end

if not connections.Keybind then
    connections.Keybind = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local bindString = Mega.States.Player.LongJumpKeybind or "None"
        if bindString == "None" then return end
        
        local success, bindEnum = pcall(function() return Enum.KeyCode[bindString] end)
        if not success or not bindEnum then return end
        
        if not gameProcessed and input.KeyCode == bindEnum then
            local newState = not States.Player.LongJump
            States.Player.LongJump = newState
            if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_long_jump"] then
                Mega.Objects.Toggles["toggle_long_jump"](newState)
            else
                Mega.Features.LongJump.SetEnabled(newState)
            end
        end
    end)
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

return Mega.Features.LongJump
