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
local matchCache = { teammates = {}, enemies = {} }

local cacheLoop = nil
local function startMatchCacheLoop()
    if cacheLoop then return end
    cacheLoop = task.spawn(function()
        while task.wait(1) do
            if not States.Misc.AutoHonor.Enabled then break end
            
            -- Если мы попали в спектаторы, прекращаем обновлять кэш, чтобы сохранить последние боевые составы
            if not LocalPlayer.Team or LocalPlayer.Team.Name:lower():find("spectator") then
                break
            end

            if lastPlayingTeam then
                for _, p in ipairs(Services.Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Team then
                        -- Сравниваем по имени
                        if p.Team.Name == lastPlayingTeam.Name then
                            if not table.find(matchCache.teammates, p) then
                                table.insert(matchCache.teammates, p)
                            end
                        elseif not p.Team.Name:lower():find("spectator") then
                            if not table.find(matchCache.enemies, p) then
                                table.insert(matchCache.enemies, p)
                            end
                        end
                    end
                end
            end
        end
        cacheLoop = nil
    end)
end

-- Рекурсивно ищет _NetManaged через ВСЕ дочерние объекты
-- (путь: rbxts_include/node_modules/@rbxts/net/out/_NetManaged)
-- Узлы могут быть Folder, ModuleScript или других типов
local function findNetManaged(parent, depth)
    depth = depth or 0
    if depth > 10 then return nil end
    local found = parent:FindFirstChild("_NetManaged")
    if found then return found end
    for _, child in pairs(parent:GetChildren()) do
        -- Ищем во всех контейнерах, не только Folder
        if not child:IsA("BasePart") and not child:IsA("LocalScript")
        and not child:IsA("Script") and not child:IsA("Animation") then
            local res = findNetManaged(child, depth + 1)
            if res then return res end
        end
    end
    return nil
end

-- Ищет Honor remote в _NetManaged
local function findHonorRemote()
    if cachedRemote then
        if cachedRemote.Parent then
            return cachedRemote
        else
            cachedRemote = nil
        end
    end

    -- 1. Сначала пробуем точный путь, который скинул юзер!
    local rs = Services.ReplicatedStorage
    local function get(p, n) return p and p:FindFirstChild(n) end
    local exactNet = get(get(get(get(get(get(rs, "rbxts_include"), "node_modules"), "@rbxts"), "net"), "out"), "_NetManaged")
    
    if exactNet then
        local r = exactNet:FindFirstChild("TryGiveMatchHonorPoints")
        if r then
            cachedRemote = r
            return r
        end
    end

    -- 2. Если точный путь не сработал, ищем рекурсивно
    local rbxts = rs:FindFirstChild("rbxts_include")
    if not rbxts then return nil end

    local netManaged = findNetManaged(rbxts)
    if not netManaged then return nil end

    local exactNames = { "TryGiveMatchHonorPoints", "GiveMatchHonorPoints" }
    for _, exact in ipairs(exactNames) do
        local r = netManaged:FindFirstChild(exact)
        if r then
            cachedRemote = r
            return r
        end
    end

    local honorKeywords = { "trygivematchhonor", "givematchhonor", "matchhonor", "givehonor", "honorpoint", "trygive", "honor" }
    for _, remote in pairs(netManaged:GetChildren()) do
        local nameLower = remote.Name:lower()
        for _, kw in ipairs(honorKeywords) do
            if nameLower:find(kw) then
                cachedRemote = remote
                return remote
            end
        end
    end

    return nil
end

local function giveHonor(teammate, enemy)
    task.spawn(function()
        local remote = findHonorRemote()
        if not remote then return end

        local function send(targetPlayer)
            if not targetPlayer then return end
            -- Полностью повторяем структуру аргументов из рабочего сниппета
            local args = {
                {
                    toPlayerId = targetPlayer.UserId
                }
            }
            local ok, err = pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(unpack(args))
                elseif remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(args))
                end
            end)
        end

        if teammate then
            send(teammate)
            task.wait(0.5) -- КД 0.5 сек
        end
        if enemy then
            send(enemy)
        end
    end)
end

local function triggerAutoHonor()
    if hasTriggeredThisMatch then return end
    hasTriggeredThisMatch = true

    local players = Services.Players:GetPlayers()
    local teammates = matchCache.teammates
    local enemies = matchCache.enemies

    local targetSetting = States.Misc.AutoHonor.Target or "Teammate and Enemy"
    local selectedTeammate = nil
    local selectedEnemy = nil

    if (targetSetting == "Teammate" or targetSetting == "Teammate and Enemy") and #teammates > 0 then
        selectedTeammate = teammates[math.random(1, #teammates)]
    end

    if (targetSetting == "Enemy" or targetSetting == "Teammate and Enemy") and #enemies > 0 then
        selectedEnemy = enemies[math.random(1, #enemies)]
    end

    -- Fallback: если никого не нашли (например игра только началась и команд не было)
    if not selectedTeammate and not selectedEnemy then
        local validPlayers = {}
        for _, p in ipairs(players) do
            if p ~= LocalPlayer then
                table.insert(validPlayers, p)
            end
        end
        
        if #validPlayers > 0 then
            if targetSetting == "Teammate and Enemy" then
                selectedTeammate = validPlayers[math.random(1, #validPlayers)]
                if #validPlayers > 1 then
                    repeat
                        selectedEnemy = validPlayers[math.random(1, #validPlayers)]
                    until selectedEnemy ~= selectedTeammate
                else
                    selectedEnemy = nil
                end
            elseif targetSetting == "Teammate" then
                selectedTeammate = validPlayers[math.random(1, #validPlayers)]
            else
                selectedEnemy = validPlayers[math.random(1, #validPlayers)]
            end
        end
    end

    giveHonor(selectedTeammate, selectedEnemy)
end

function Mega.Features.AutoHonor.SetEnabled(state)
    States.Misc.AutoHonor.Enabled = state

    if state then
        cachedRemote = nil

        if teamChangeConnection then
            teamChangeConnection:Disconnect()
            teamChangeConnection = nil
        end
        if guiAddedConnection then
            guiAddedConnection:Disconnect()
            guiAddedConnection = nil
        end

        local function resetMatchState()
            lastPlayingTeam = LocalPlayer.Team
            hasTriggeredThisMatch = false
            matchCache = { teammates = {}, enemies = {} }
            startMatchCacheLoop()
        end

        -- Запоминаем текущую боевую команду
        if LocalPlayer.Team and not LocalPlayer.Team.Name:lower():find("spectator") then
            resetMatchState()
        end

        teamChangeConnection = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
            if not States.Misc.AutoHonor.Enabled then return end
            if not LocalPlayer.Team then return end

            local teamName = LocalPlayer.Team.Name:lower()
            local isSpectator = teamName:find("spectator") ~= nil

            if not isSpectator then
                resetMatchState()
            elseif lastPlayingTeam ~= nil then
                -- Только если игрок БЫЛ в боевой команде и попал в спектаторы
                task.wait(3) -- Ждём появления экрана хонора
                if States.Misc.AutoHonor.Enabled then
                    triggerAutoHonor()
                end
                lastPlayingTeam = nil
            end
        end)

        -- Триггер по экрану победы (если игрок не попадает в спектаторы при победе)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            local function onGuiAdded(gui)
                if not States.Misc.AutoHonor.Enabled then return end
                if gui:IsA("ScreenGui") and gui.Name == "MatchEndControls" then
                    task.wait(2) -- Даём интерфейсу полностью загрузиться
                    if States.Misc.AutoHonor.Enabled then
                        triggerAutoHonor()
                    end
                end
            end
            guiAddedConnection = playerGui.ChildAdded:Connect(onGuiAdded)
            
            -- Если уже существует
            local existing = playerGui:FindFirstChild("MatchEndControls")
            if existing then
                onGuiAdded(existing)
            end
        end
        
        --print("[TumbaHub] AutoHonor: Enabled")
    else
        if teamChangeConnection then
            teamChangeConnection:Disconnect()
            teamChangeConnection = nil
        end
        lastPlayingTeam = nil
        --print("[TumbaHub] AutoHonor: Disabled")
    end
end

-- Восстанавливаем состояние при загрузке модуля
if States.Misc.AutoHonor.Enabled then
    Mega.Features.AutoHonor.SetEnabled(true)
end
