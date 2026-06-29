-- features/hitboxes.lua
-- HitBoxes - expands other players hitboxes and hit reach in Roblox Bedwars

if not Mega.Features then Mega.Features = {} end
Mega.Features.HitBoxes = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Combat then States.Combat = {} end
if not States.Combat.HitBoxes then
    States.Combat.HitBoxes = {
        Enabled = false,
        Mode = "Sword",
        ExpandAmount = 14.4
    }
end

local objects = {}
local connections = {}
local active = false

local function createHitboxForPlayer(player)
    if player == LocalPlayer then return end
    
    local function setupChar(char)
        task.wait(0.2)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp and not objects[player] then
            local hitbox = Instance.new("Part")
            local size = States.Combat.HitBoxes.ExpandAmount or 14.4
            hitbox.Name = "TumbaHitbox"
            hitbox.Size = Vector3.new(3, 6, 3) + Vector3.one * (size / 5)
            hitbox.Position = hrp.Position
            hitbox.CanCollide = false
            hitbox.Massless = true
            hitbox.Transparency = 1
            hitbox.Parent = char
            
            local weld = Instance.new("Motor6D")
            weld.Part0 = hitbox
            weld.Part1 = hrp
            weld.Parent = hitbox
            
            objects[player] = hitbox
        end
    end

    if player.Character then
        task.spawn(setupChar, player.Character)
    end
    local conn = player.CharacterAdded:Connect(setupChar)
    connections["char_" .. player.Name] = conn
end

local function removeHitboxForPlayer(player)
    if objects[player] then
        pcall(function() objects[player]:Destroy() end)
        objects[player] = nil
    end
    if connections["char_" .. player.Name] then
        connections["char_" .. player.Name]:Disconnect()
        connections["char_" .. player.Name] = nil
    end
end

local function enableHitBoxes()
    if States.Combat.HitBoxes.Mode == "Sword" then
        -- Sword mode: Patches Knit SwordController
        pcall(function()
            local tsKnit = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("knit")
            local Knit = tsKnit and require(tsKnit).Knit
            if not Knit then Knit = getgenv().Knit or shared.Knit end
            local swordController = Knit and Knit.Controllers.SwordController
            if swordController then
                local size = States.Combat.HitBoxes.ExpandAmount or 14.4
                debug.setconstant(swordController.swingSwordInRegion, 6, (size / 3))
            end
        end)
    else
        -- Player mode: Create physical hitbox parts
        for _, player in ipairs(Services.Players:GetPlayers()) do
            createHitboxForPlayer(player)
        end
        connections.PlayerAdded = Services.Players.PlayerAdded:Connect(createHitboxForPlayer)
        connections.PlayerRemoving = Services.Players.PlayerRemoving:Connect(removeHitboxForPlayer)
    end
    active = true
end

local function disableHitBoxes()
    -- Restore Knit SwordController constant
    pcall(function()
        local tsKnit = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("knit")
        local Knit = tsKnit and require(tsKnit).Knit
        if not Knit then Knit = getgenv().Knit or shared.Knit end
        local swordController = Knit and Knit.Controllers.SwordController
        if swordController then
            debug.setconstant(swordController.swingSwordInRegion, 6, 3.8)
        end
    end)
    
    -- Disconnect and destroy player mode hitboxes
    if connections.PlayerAdded then connections.PlayerAdded:Disconnect() connections.PlayerAdded = nil end
    if connections.PlayerRemoving then connections.PlayerRemoving:Disconnect() connections.PlayerRemoving = nil end
    
    for player, _ in pairs(objects) do
        removeHitboxForPlayer(player)
    end
    table.clear(objects)
    active = false
end

function Mega.Features.HitBoxes.SetEnabled(state)
    States.Combat.HitBoxes.Enabled = state
    if state then
        if not active then
            enableHitBoxes()
        end
    else
        disableHitBoxes()
    end
end

function Mega.Features.HitBoxes.UpdateSettings()
    if States.Combat.HitBoxes.Enabled then
        disableHitBoxes()
        enableHitBoxes()
    end
end

if States.Combat.HitBoxes.Enabled then
    Mega.Features.HitBoxes.SetEnabled(true)
end

if Mega.UnloadedSignal then
    Mega.UnloadedSignal:Connect(function()
        disableHitBoxes()
    end)
end

return Mega.Features.HitBoxes
