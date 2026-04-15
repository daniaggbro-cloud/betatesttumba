-- features/autolobby.lua
-- Logic for returning to lobby after match ends

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoLobby = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Bot.AutoLobby then
    States.Bot.AutoLobby = {
        Enabled = false
    }
end

local function leaveMatch()
    -- Common Bedwars/EasyGames leaveMatch remote paths
    local paths = {
        "events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events",
        "events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"
    }
    
    for _, path in ipairs(paths) do
        local folder = Services.ReplicatedStorage:FindFirstChild(path)
        if folder then
            local remote = folder:FindFirstChild("leaveMatch")
            if remote then
                print("[TumbaHub] Leaving match via: " .. path)
                remote:FireServer()
                return true
            end
        end
    end
    return false
end

local gameOverConnection
function Mega.Features.AutoLobby.SetEnabled(state)
    States.Bot.AutoLobby.Enabled = state
    
    if state then
        if gameOverConnection then gameOverConnection:Disconnect() end
        
        -- Method 1: Listening for gameOver remote
        task.spawn(function()
            local networking = Services.ReplicatedStorage:WaitForChild("events-@easy-games/game-core:shared/game-core-networking@getEvents.Events", 10)
            if networking then
                local gameOver = networking:WaitForChild("gameOver", 5)
                if gameOver then
                    gameOverConnection = gameOver.OnClientEvent:Connect(function()
                        if not States.Bot.AutoLobby.Enabled then return end
                        print("[TumbaHub] Match ended! Returning to lobby in 5 seconds...")
                        task.wait(5)
                        leaveMatch()
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

-- Re-enable on script load if it was active
if States.Bot.AutoLobby.Enabled then
    Mega.Features.AutoLobby.SetEnabled(true)
end
