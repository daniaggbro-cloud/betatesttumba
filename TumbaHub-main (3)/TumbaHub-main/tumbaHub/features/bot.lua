    -- features/bot.lua
-- Logic for Auto-Bot (Pathfinding, Target tracking, Auto-modules)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Bot = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    PathfindingService = game:GetService("PathfindingService"),
    CollectionService = game:GetService("CollectionService"),
    Workspace = game:GetService("Workspace")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Bot then
    States.Bot = {
        Enabled = false, TargetBeds = true, TargetPlayers = true,
        Pathfinding = true, AutoKillaura = true, AutoScaffold = true, 
        AutoBedNuke = true, AutoAntiVoid = true, AutoSpider = true
    }
end

if not Mega.Objects.BotConnections then Mega.Objects.BotConnections = {} end
local connections = Mega.Objects.BotConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local function getBotTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local bestTarget = nil
    local bestDist = math.huge
    local myTeam = LocalPlayer:GetAttribute("Team")

    -- 1. Приоритет кроватям
    if States.Bot.TargetBeds then
        for _, bed in ipairs(Services.CollectionService:GetTagged("bed")) do
            local bedTeam = bed:GetAttribute("TeamId") or bed:GetAttribute("Team")
            local health = bed:GetAttribute("Health")
            if bedTeam ~= myTeam and (not health or health > 0) then
                local bPart = bed:IsA("BasePart") and bed or bed.PrimaryPart
                if bPart then
                    local dist = (hrp.Position - bPart.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestTarget = bPart
                    end
                end
            end
        end
    end

    -- 2. Затем игрокам (если нет кроватей или игроки очень близко)
    if States.Bot.TargetPlayers then
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if tHrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - tHrp.Position).Magnitude
                    -- Если враг ближе чем кровать на 10 стадов — фокусим врага
                    if dist < bestDist - 10 then 
                        bestDist = dist
                        bestTarget = tHrp
                    end
                end
            end
        end
    end

    return bestTarget
end

local waypointIndex = 1
local currentPath = nil
local lastPathCalc = 0
local espPathFolder = Services.Workspace:FindFirstChild("BotPathESP")

local function drawPath(waypoints)
    if not espPathFolder then
        espPathFolder = Instance.new("Folder")
        espPathFolder.Name = "BotPathESP"
        espPathFolder.Parent = Services.Workspace
    end
    espPathFolder:ClearAllChildren()
    
    for i, wp in ipairs(waypoints) do
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.8, 0.8, 0.8)
        p.Position = wp.Position
        p.Anchored = true
        p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(0, 255, 150)
        p.Transparency = 0.5
        p.Parent = espPathFolder
    end
end

local prevModuleStates = {}
local stuckTimer = 0

function Mega.Features.Bot.SetEnabled(state)
    States.Bot.Enabled = state
    
    if state then
        stuckTimer = 0
        -- Сохраняем предыдущие состояния, чтобы вернуть их при выключении бота
        prevModuleStates.Killaura = States.Combat.Killaura and States.Combat.Killaura.Enabled
        prevModuleStates.Scaffold = States.Player.Scaffold and States.Player.Scaffold.Enabled
        prevModuleStates.BedNuke = States.Combat.BedNuke and States.Combat.BedNuke.Enabled
        prevModuleStates.AntiVoid = States.Player.AntiVoid and (type(States.Player.AntiVoid) == "table" and States.Player.AntiVoid.Enabled or States.Player.AntiVoid)
        prevModuleStates.Spider = States.Player.Spider

        -- Включаем нужные модули (если разрешено и если не были включены до этого)
        if States.Bot.AutoKillaura and Mega.Features.Killaura and not prevModuleStates.Killaura then Mega.Features.Killaura.SetEnabled(true) end
        if States.Bot.AutoScaffold and Mega.Features.Scaffold and not prevModuleStates.Scaffold then Mega.Features.Scaffold.SetEnabled(true) end
        if States.Bot.AutoBedNuke and Mega.Features.BedNuke and not prevModuleStates.BedNuke then Mega.Features.BedNuke.SetEnabled(true) end
        if States.Bot.AutoAntiVoid and Mega.Features.AntiVoid and not prevModuleStates.AntiVoid then Mega.Features.AntiVoid.SetEnabled(true) end
        if States.Bot.AutoSpider and Mega.Features.Spider and not prevModuleStates.Spider then Mega.Features.Spider.SetEnabled(true) end

        connections.BotLoop = Services.RunService.Heartbeat:Connect(function(dt)
            if not States.Bot.Enabled then return end
            
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local target = getBotTarget()
            if not target then
                hum:MoveTo(hrp.Position) -- Останавливаемся если нет целей
                if espPathFolder then espPathFolder:ClearAllChildren() end
                stuckTimer = 0
                return 
            end

            local distToTargetXZ = (hrp.Position * Vector3.new(1,0,1) - target.Position * Vector3.new(1,0,1)).Magnitude
            
            -- Если мы вошли в радиус работы модулей (12 стадов), останавливаемся, чтобы не биться головой в цель
            if distToTargetXZ <= 12 then
                hum:MoveTo(hrp.Position)
                stuckTimer = 0
                return
            end

            if States.Bot.Pathfinding then
                -- Перерасчет пути каждые 0.5 секунд
                if tick() - lastPathCalc > 0.5 then
                    lastPathCalc = tick()
                    local path = Services.PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true
                    })
                    pcall(function()
                        path:ComputeAsync(hrp.Position, target.Position)
                        if path.Status == Enum.PathStatus.Success then
                            currentPath = path:GetWaypoints()
                            waypointIndex = 2 -- Пропускаем начальную точку
                            drawPath(currentPath)
                        else
                            currentPath = nil
                        end
                    end)
                end

                if currentPath and waypointIndex <= #currentPath then
                    local wp = currentPath[waypointIndex]
                    hum:MoveTo(wp.Position)
                    
                    if wp.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end

                    local distToWp = (hrp.Position * Vector3.new(1,0,1) - wp.Position * Vector3.new(1,0,1)).Magnitude
                    if distToWp < 3 then
                        waypointIndex = waypointIndex + 1
                    end
                else
                    -- Фоллбек если маршрут не найден (Scaffold проложит мост)
                    hum:MoveTo(target.Position)
                end
            else
                -- Режим без Pathfinding (идем напрямик, строитель все делает сам)
                hum:MoveTo(target.Position)
                if espPathFolder then espPathFolder:ClearAllChildren() end
            end
            
            -- Умная логика анти-застревания (срабатывает, если мы должны идти к цели, но стоим на месте)
            local velXZ = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
            if velXZ.Magnitude < 2.5 then
                stuckTimer = stuckTimer + dt
                if stuckTimer > 0.1 then
                    hum.Jump = true -- Пытаемся перепрыгнуть
                end
                if stuckTimer > 1.0 then
                    -- Принудительный обход блока (направление берем от поворота тела, так как MoveDirection может быть 0)
                    local lookDir = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
                    if lookDir.Magnitude > 0.1 then lookDir = lookDir.Unit else lookDir = Vector3.new(1, 0, 0) end
                    
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 6.5, 0) + (lookDir * 2)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
                    stuckTimer = 0
                end
            else
                stuckTimer = 0
            end
        end)
    else
        if connections.BotLoop then connections.BotLoop:Disconnect() end
        if espPathFolder then espPathFolder:ClearAllChildren() end
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
        end

        -- Восстанавливаем оригинальные состояния модулей (выключаем то, что бот включил за нас)
        if States.Bot.AutoKillaura and Mega.Features.Killaura and not prevModuleStates.Killaura then 
            Mega.Features.Killaura.SetEnabled(false) 
            if Mega.Objects.Toggles["toggle_killaura"] then Mega.Objects.Toggles["toggle_killaura"](false) end
        end
        if States.Bot.AutoScaffold and Mega.Features.Scaffold and not prevModuleStates.Scaffold then 
            Mega.Features.Scaffold.SetEnabled(false) 
            if Mega.Objects.Toggles["toggle_scaffold"] then Mega.Objects.Toggles["toggle_scaffold"](false) end
        end
        if States.Bot.AutoBedNuke and Mega.Features.BedNuke and not prevModuleStates.BedNuke then 
            Mega.Features.BedNuke.SetEnabled(false) 
            if Mega.Objects.Toggles["toggle_bednuke"] then Mega.Objects.Toggles["toggle_bednuke"](false) end
        end
        if States.Bot.AutoAntiVoid and Mega.Features.AntiVoid and not prevModuleStates.AntiVoid then 
            Mega.Features.AntiVoid.SetEnabled(false) 
            if Mega.Objects.Toggles["toggle_antivoid"] then Mega.Objects.Toggles["toggle_antivoid"](false) end
        end
        if States.Bot.AutoSpider and Mega.Features.Spider and not prevModuleStates.Spider then 
            Mega.Features.Spider.SetEnabled(false) 
            if Mega.Objects.Toggles["toggle_spider"] then Mega.Objects.Toggles["toggle_spider"](false) end
        end
    end
end

if States.Bot.Enabled then
    Mega.Features.Bot.SetEnabled(true)
end
