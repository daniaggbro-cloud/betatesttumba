-- features/auto_honor.lua
-- Logic for Auto Honor at the end of the match

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoHonor = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.AutoHonor then
    States.Misc.AutoHonor = { Enabled = false, Target = "Teammate" } -- "Teammate" or "Enemy"
end

local gameOverConnection

local function giveHonor()
    local players = Services.Players:GetPlayers()
    local validTargets = {}
    
    for _, p in ipairs(players) do
        if p ~= LocalPlayer then
            local isTeammate = (p.Team == LocalPlayer.Team)
            if States.Misc.AutoHonor.Target == "Teammate" and isTeammate then
                table.insert(validTargets, p)
            elseif States.Misc.AutoHonor.Target == "Enemy" and not isTeammate then
                table.insert(validTargets, p)
            end
        end
    end

    -- Если подходящих целей нет (например, тиммейтов не осталось), добавляем любых других доступных игроков
    if #validTargets == 0 then
        for _, p in ipairs(players) do
            if p ~= LocalPlayer then
                table.insert(validTargets, p)
            end
        end
    end

    if #validTargets > 0 then
        local targetPlayer = validTargets[math.random(1, #validTargets)]
        task.spawn(function()
            pcall(function()
                local remote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 5):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("TryGiveMatchHonorPoints")
                if remote then
                    remote:InvokeServer({
                        toPlayerId = targetPlayer.UserId
                    })
                    print("[TumbaHub] Auto Honor given to " .. targetPlayer.Name)
                end
            end)
        end)
    end
end

function Mega.Features.AutoHonor.SetEnabled(state)
    States.Misc.AutoHonor.Enabled = state
    
    if state then
        if gameOverConnection then gameOverConnection:Disconnect() end
        
        task.spawn(function()
            local networking = Services.ReplicatedStorage:WaitForChild("events-@easy-games/game-core:shared/game-core-networking@getEvents.Events", 10)
            if networking then
                local gameOver = networking:WaitForChild("gameOver", 5)
                if gameOver then
                    gameOverConnection = gameOver.OnClientEvent:Connect(function()
                        if not States.Misc.AutoHonor.Enabled then return end
                        -- Даем время на загрузку финального экрана (3 секунды)
                        task.wait(3)
                        giveHonor()
                    end)
                end
            end
        end)
    else
        if gameOverConnection then
            gameOverConnection:Disconnect()
            gameOverConnection = nil
        end
    end
end

if States.Misc.AutoHonor.Enabled then
    Mega.Features.AutoHonor.SetEnabled(true)
end