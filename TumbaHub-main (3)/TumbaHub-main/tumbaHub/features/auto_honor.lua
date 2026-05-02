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
    States.Misc.AutoHonor = { Enabled = false, Target = "Teammate and Enemy" }
end

local teamChangeConnection
local lastPlayingTeam = nil

local function giveHonor(teammate, enemy)
    task.spawn(function()
        pcall(function()
            local remote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 5)
            if remote then
                remote = remote:WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("TryGiveMatchHonorPoints", 5)
            end
            
            if remote then
                if teammate then
                    remote:InvokeServer({ toPlayerId = teammate.UserId })
                    print("[TumbaHub] Auto Honor given to teammate: " .. teammate.Name)
                    task.wait(0.5)
                end
                if enemy then
                    remote:InvokeServer({ toPlayerId = enemy.UserId })
                    print("[TumbaHub] Auto Honor given to enemy: " .. enemy.Name)
                end
            end
        end)
    end)
end

local function triggerAutoHonor()
    local players = Services.Players:GetPlayers()
    local teammates = {}
    local enemies = {}
    
    for _, p in ipairs(players) do
        if p ~= LocalPlayer then
            if p.Team then
                if lastPlayingTeam and p.Team == lastPlayingTeam then
                    table.insert(teammates, p)
                elseif p.Team.Name ~= "Spectators" then
                    table.insert(enemies, p)
                end
            end
        end
    end

    local targetSetting = States.Misc.AutoHonor.Target or "Teammate and Enemy"
    local selectedTeammate = nil
    local selectedEnemy = nil
    
    if targetSetting == "Teammate" or targetSetting == "Teammate and Enemy" then
        selectedTeammate = #teammates > 0 and teammates[math.random(1, #teammates)] or nil
    end
    
    if targetSetting == "Enemy" or targetSetting == "Teammate and Enemy" then
        selectedEnemy = #enemies > 0 and enemies[math.random(1, #enemies)] or nil
    end
    
    -- Если никого подходящего не нашли (например, все ливнули), выдаем рандомному игроку
    if not selectedTeammate and not selectedEnemy then
        for _, p in ipairs(players) do
            if p ~= LocalPlayer and p ~= selectedTeammate then
                if targetSetting == "Teammate" then selectedTeammate = p else selectedEnemy = p end
                break
            end
        end
    end

    giveHonor(selectedTeammate, selectedEnemy)
end

function Mega.Features.AutoHonor.SetEnabled(state)
    States.Misc.AutoHonor.Enabled = state
    
    if state then
        if teamChangeConnection then teamChangeConnection:Disconnect() end
        
        if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Spectators" then
            lastPlayingTeam = LocalPlayer.Team
        end
        
        teamChangeConnection = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
            if not States.Misc.AutoHonor.Enabled or not LocalPlayer.Team then return end
            
            if LocalPlayer.Team.Name ~= "Spectators" then
                lastPlayingTeam = LocalPlayer.Team
            elseif LocalPlayer.Team.Name == "Spectators" and lastPlayingTeam ~= nil then
                task.wait(2) -- Даем время на загрузку финального экрана
                triggerAutoHonor()
                lastPlayingTeam = nil
            end
        end)
    else
        if teamChangeConnection then
            teamChangeConnection:Disconnect()
            teamChangeConnection = nil
        end
    end
end

if States.Misc.AutoHonor.Enabled then
    Mega.Features.AutoHonor.SetEnabled(true)
end
