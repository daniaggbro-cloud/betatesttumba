-- features/autoplay.lua
-- Logic for Auto-Joining games from the lobby

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoPlay = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Bot.AutoPlay then
    States.Bot.AutoPlay = {
        Enabled = false,
        Mode = "queue_16v16"
    }
end

local joinQueueRemote
task.spawn(function()
    while not joinQueueRemote do
        pcall(function()
            joinQueueRemote = Services.ReplicatedStorage:WaitForChild("events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events", 5):WaitForChild("joinQueue", 5)
        end)
        if not joinQueueRemote then task.wait(5) end
    end
end)

local function isLobby()
    -- Проверка на лобби через наличие специфичных объектов или PlaceId
    -- Обычно в Bedwars лобби есть папка "Lobby" в Workspace или специфичные реморты
    return Services.ReplicatedStorage:FindFirstChild("Lobby") ~= nil or game.PlaceId == 6872265039
end

local lastJoinAttempt = 0

function Mega.Features.AutoPlay.SetEnabled(state)
    States.Bot.AutoPlay.Enabled = state
    
    if state then
        if Mega.Objects.AutoPlayConnection then Mega.Objects.AutoPlayConnection:Disconnect() end
        
        Mega.Objects.AutoPlayConnection = Services.RunService.Heartbeat:Connect(function()
            if not States.Bot.AutoPlay.Enabled then return end
            if tick() - lastJoinAttempt < 10 then return end -- Не спамим ремортом
            
            if isLobby() and joinQueueRemote then
                lastJoinAttempt = tick()
                local modeMap = {
                    ["queue_16v16"] = "bedwars_16v16",
                    ["queue_to4"] = "bedwars_to4",
                    ["queue_to2"] = "bedwars_duels",   -- Из дампа
                    ["queue_to1"] = "winstreak_1v1",   -- Из дампа
                    ["queue_5v5"] = "bedwars_5v5",     -- Из дампа
                    ["queue_skywars"] = "skywars_to2"   -- Из дампа
                }
                
                local args = {
                    {
                        queueType = modeMap[States.Bot.AutoPlay.Mode] or "winstreak_1v1"
                    }
                }
                pcall(function()
                    print("[TumbaHub] Auto-joining queue: " .. tostring(States.Bot.AutoPlay.Mode))
                    joinQueueRemote:FireServer(unpack(args))
                end)
            end
        end)
    else
        if Mega.Objects.AutoPlayConnection then 
            Mega.Objects.AutoPlayConnection:Disconnect() 
            Mega.Objects.AutoPlayConnection = nil
        end
    end
end

if States.Bot.AutoPlay.Enabled then
    Mega.Features.AutoPlay.SetEnabled(true)
end
