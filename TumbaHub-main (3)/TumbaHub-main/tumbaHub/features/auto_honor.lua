-- features/auto_honor.lua
-- Logic for Auto Honor at the end of the match

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoHonor = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer

-- Используем States из Mega (уже инициализированы в settings.lua)
local States = Mega.States
if not States.Misc then States.Misc = {} end
if not States.Misc.AutoHonor then
    States.Misc.AutoHonor = { Enabled = false, Target = "Teammate and Enemy" }
end

local teamChangeConnection = nil
local lastPlayingTeam = nil
local cachedRemote = nil  -- Кэш remote чтобы не искать каждый раз

-- Рекурсивно ищет _NetManaged в rbxts_include (как в dumper.lua)
local function findNetManaged(parent)
    local found = parent:FindFirstChild("_NetManaged")
    if found then return found end
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Folder") then
            local res = findNetManaged(child)
            if res then return res end
        end
    end
    return nil
end

-- Ищет Honor remote в _NetManaged по ключевым словам
local function findHonorRemote()
    if cachedRemote then
        -- Проверяем что remote ещё существует
        if cachedRemote.Parent then
            return cachedRemote
        else
            cachedRemote = nil
        end
    end

    local rbxts = Services.ReplicatedStorage:FindFirstChild("rbxts_include")
    if not rbxts then
        warn("[TumbaHub] AutoHonor: rbxts_include not found in ReplicatedStorage")
        return nil
    end

    local netManaged = findNetManaged(rbxts)
    if not netManaged then
        warn("[TumbaHub] AutoHonor: _NetManaged not found")
        return nil
    end

    -- Ищем remote по ключевым словам в имени
    local honorKeywords = { "honor", "matchhonor", "givehonor", "trygive", "honorpoint" }
    for _, remote in pairs(netManaged:GetChildren()) do
        local nameLower = remote.Name:lower()
        for _, kw in ipairs(honorKeywords) do
            if nameLower:find(kw) then
                cachedRemote = remote
                print("[TumbaHub] AutoHonor: Found remote → " .. remote.Name)
                return remote
            end
        end
    end

    warn("[TumbaHub] AutoHonor: No honor remote found in _NetManaged")
    return nil
end

-- Безопасно вызывает remote (поддерживает RemoteEvent и RemoteFunction)
local function callRemote(remote, args)
    if not remote or not remote.Parent then return end
    local ok, err = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(args)
        elseif remote:IsA("RemoteEvent") then
            remote:FireServer(args)
        end
    end)
    if not ok then
        warn("[TumbaHub] AutoHonor: Error calling remote: " .. tostring(err))
    end
end

local function giveHonor(teammate, enemy)
    task.spawn(function()
        local remote = findHonorRemote()
        if not remote then return end

        if teammate then
            callRemote(remote, { toPlayerId = teammate.UserId })
            print("[TumbaHub] Auto Honor → teammate: " .. teammate.Name)
            task.wait(0.5)
        end
        if enemy then
            callRemote(remote, { toPlayerId = enemy.UserId })
            print("[TumbaHub] Auto Honor → enemy: " .. enemy.Name)
        end
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

    if (targetSetting == "Teammate" or targetSetting == "Teammate and Enemy") and #teammates > 0 then
        selectedTeammate = teammates[math.random(1, #teammates)]
    end

    if (targetSetting == "Enemy" or targetSetting == "Teammate and Enemy") and #enemies > 0 then
        selectedEnemy = enemies[math.random(1, #enemies)]
    end

    -- Fallback: если никого не нашли — даём случайному игроку
    if not selectedTeammate and not selectedEnemy then
        for _, p in ipairs(players) do
            if p ~= LocalPlayer then
                if targetSetting == "Teammate" then
                    selectedTeammate = p
                else
                    selectedEnemy = p
                end
                break
            end
        end
    end

    giveHonor(selectedTeammate, selectedEnemy)
end

function Mega.Features.AutoHonor.SetEnabled(state)
    States.Misc.AutoHonor.Enabled = state

    if state then
        -- Сбрасываем кэш remote при включении (на случай если игра перезагрузилась)
        cachedRemote = nil

        if teamChangeConnection then
            teamChangeConnection:Disconnect()
            teamChangeConnection = nil
        end

        -- Запоминаем текущую боевую команду
        if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Spectators" then
            lastPlayingTeam = LocalPlayer.Team
        end

        teamChangeConnection = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
            if not States.Misc.AutoHonor.Enabled then return end
            if not LocalPlayer.Team then return end

            local teamName = LocalPlayer.Team.Name
            if teamName ~= "Spectators" then
                -- Игрок в боевой команде — запоминаем
                lastPlayingTeam = LocalPlayer.Team
            elseif lastPlayingTeam ~= nil then
                -- Игрок перешёл в Spectators после игры — даём хонор
                task.wait(3) -- Ждём появления экрана хонора
                if States.Misc.AutoHonor.Enabled then
                    triggerAutoHonor()
                end
                lastPlayingTeam = nil
            end
        end)

        print("[TumbaHub] AutoHonor: Enabled")
    else
        if teamChangeConnection then
            teamChangeConnection:Disconnect()
            teamChangeConnection = nil
        end
        lastPlayingTeam = nil
        print("[TumbaHub] AutoHonor: Disabled")
    end
end

-- Восстанавливаем состояние при загрузке модуля
if States.Misc.AutoHonor.Enabled then
    Mega.Features.AutoHonor.SetEnabled(true)
end
