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
        AutoBedNuke = true, AutoAntiVoid = true, AutoSpider = true,
        AutoPlay = { Enabled = false, Mode = "bedwars_16v16" }
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

--#region Navigation Helpers
local function isPointSafe(pos)
    local ray = Ray.new(pos + Vector3.new(0, 2, 0), Vector3.new(0, -15, 0))
    local hit, _ = Services.Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Services.Workspace:FindFirstChild("BotPathESP")})
    return hit ~= nil
end

local function checkHurdle(hrp)
    local ray = Ray.new(hrp.Position - Vector3.new(0, 1.5, 0), hrp.CFrame.LookVector * 3)
    local hit, _ = Services.Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    if hit and hit.CanCollide then
        -- Проверяем высоту препятствия (луч чуть выше)
        local ray2 = Ray.new(hrp.Position + Vector3.new(0, 0.5, 0), hrp.CFrame.LookVector * 3)
        local hit2, _ = Services.Workspace:FindPartOnRayWithIgnoreList(ray2, {LocalPlayer.Character})
        return not hit2 -- Если выше чисто, значит препятствие в 1 блок
    end
    return false
end
--#endregion

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
local strafeAngle = 0

function Mega.Features.Bot.SetEnabled(state)
    States.Bot.Enabled = state
    
    if state then
        stuckTimer = 0
        strafeAngle = 0
        -- Сохраняем предыдущие состояния, чтобы вернуть их при выключении бота
        prevModuleStates.Killaura = States.Combat.Killaura and States.Combat.Killaura.Enabled
        prevModuleStates.Scaffold = States.Player.Scaffold and States.Player.Scaffold.Enabled
        prevModuleStates.BedNuke = States.Combat.BedNuke and States.Combat.BedNuke.Enabled
        prevModuleStates.AntiVoid = States.Player.AntiVoid and (type(States.Player.AntiVoid) == "table" and States.Player.AntiVoid.Enabled or States.Player.AntiVoid)
        prevModuleStates.Spider = States.Player.Spider

        -- Включаем нужные модули
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
                hum:MoveTo(hrp.Position)
                if espPathFolder then espPathFolder:ClearAllChildren() end
                stuckTimer = 0
                return 
            end

            local isPlayerTarget = target.Parent:FindFirstChild("Humanoid") ~= nil
            local distToTargetXZ = (hrp.Position * Vector3.new(1,0,1) - target.Position * Vector3.new(1,0,1)).Magnitude
            
            --#region Combat Strafe Logic
            if isPlayerTarget and distToTargetXZ <= 15 then
                strafeAngle = strafeAngle + dt * 2 -- Скорость кружения
                local offset = Vector3.new(math.cos(strafeAngle) * 10, 0, math.sin(strafeAngle) * 10)
                local strafePos = target.Position + offset
                
                if isPointSafe(strafePos) then
                    hum:MoveTo(strafePos)
                else
                    hum:MoveTo(target.Position) -- Если кружить опасно, идем прямо
                end
                
                stuckTimer = 0
                return
            end
            --#endregion

            -- Если мы у кровати (5 стадов), просто стоим и ломаем
            if not isPlayerTarget and distToTargetXZ <= 5 then
                hum:MoveTo(hrp.Position)
                stuckTimer = 0
                return
            end

            --#region Navigation Logic
            if States.Bot.Pathfinding then
                if tick() - lastPathCalc > 0.5 then
                    lastPathCalc = tick()
                    local path = Services.PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true })
                    pcall(function()
                        path:ComputeAsync(hrp.Position, target.Position)
                        if path.Status == Enum.PathStatus.Success then
                            currentPath = path:GetWaypoints()
                            waypointIndex = 2
                            drawPath(currentPath)
                        else
                            currentPath = nil -- Fallback to direct
                        end
                    end)
                end

                if currentPath and waypointIndex <= #currentPath then
                    local wp = currentPath[waypointIndex]
                    hum:MoveTo(wp.Position)
                    if wp.Action == Enum.PathWaypointAction.Jump or checkHurdle(hrp) then hum.Jump = true end
                    if (hrp.Position * Vector3.new(1,0,1) - wp.Position * Vector3.new(1,0,1)).Magnitude < 3 then
                        waypointIndex = waypointIndex + 1
                    end
                else
                    hum:MoveTo(target.Position) -- Direct Fallback
                end
            else
                hum:MoveTo(target.Position)
                if checkHurdle(hrp) then hum.Jump = true end
            end
            --#endregion
            
            --#region Stuck Recovery
            local velXZ = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
            if velXZ.Magnitude < 2.5 then
                stuckTimer = stuckTimer + dt
                if stuckTimer > 0.1 then hum.Jump = true end
                if stuckTimer > 1.2 then
                    -- Попытка "Орбитального ТП" для обхода затора
                    local lookDir = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
                    local sideDir = hrp.CFrame.RightVector * Vector3.new(1, 0, 1)
                    if lookDir.Magnitude < 0.1 then lookDir = Vector3.new(1, 0, 0) end
                    
                    local tpTarget = hrp.Position + (lookDir * 3) + (sideDir * 3) + Vector3.new(0, 5, 0)
                    if isPointSafe(tpTarget) then
                        hrp.CFrame = CFrame.new(tpTarget, target.Position)
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
                    end
                    stuckTimer = 0
                end
            else
                stuckTimer = 0
            end
            --#endregion
        end)
    else
        if connections.BotLoop then connections.BotLoop:Disconnect() end
        if espPathFolder then espPathFolder:ClearAllChildren() end
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
        end

        -- Восстановление состояний
        local modules = {
            {key = "AutoKillaura", feat = "Killaura", toggle = "toggle_killaura"},
            {key = "AutoScaffold", feat = "Scaffold", toggle = "toggle_scaffold"},
            {key = "AutoBedNuke", feat = "BedNuke", toggle = "toggle_bednuke"},
            {key = "AutoAntiVoid", feat = "AntiVoid", toggle = "toggle_antivoid"},
            {key = "AutoSpider", feat = "Spider", toggle = "toggle_spider"}
        }

        for _, m in ipairs(modules) do
            if States.Bot[m.key] and Mega.Features[m.feat] and not prevModuleStates[m.feat] then
                Mega.Features[m.feat].SetEnabled(false)
                if Mega.Objects.Toggles[m.toggle] then Mega.Objects.Toggles[m.toggle](false) end
            end
        end
    end
end

if States.Bot.Enabled then
    Mega.Features.Bot.SetEnabled(true)
end
