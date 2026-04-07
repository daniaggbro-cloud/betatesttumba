-- features/bot.lua
-- Logic for Auto-Bot (Pathfinding, Target tracking, Auto-modules)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Bot = {}

-- Получаем сервисы НАПРЯМУЮ, не через Mega.Services (чтобы избежать nil)
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local PathSvc       = game:GetService("PathfindingService")
local CollSvc       = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace     = workspace

local LocalPlayer = Players.LocalPlayer

if not Mega.States then Mega.States = {} end
local States = Mega.States

if not States.Bot then
    States.Bot = {
        Enabled = false, TargetBeds = true, TargetPlayers = true,
        Pathfinding = true, AutoKillaura = true, AutoScaffold = true,
        AutoBedNuke = true, AutoAntiVoid = true, AutoSpider = true,
        AutoPlay = { Enabled = false, Mode = "queue_16v16" },
        AutoShop = { Enabled = false, TargetIron = 24, MinBlocks = 16 }
    }
end

if not Mega.Objects.BotConnections then Mega.Objects.BotConnections = {} end
local connections = Mega.Objects.BotConnections
for _, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- ============================================================
--  ПОИСК ОБЪЕКТОВ В МИРЕ
-- ============================================================

-- Поиск ближайшего генератора железа
local function findIronGenerator()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge

    -- Ищем по имени среди всех объектов в Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- В Bedwars генераторы называются "Iron" или "IronGenerator" или похожее
            if n:find("iron") or n:find("generator") then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = obj
                end
            end
        end
    end

    -- Если не нашли — ищем по цвету (генераторы железа обычно серые)
    return best
end

-- Поиск NPC магазина
local function findShopNPC()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge

    -- В Bedwars магазин называется "Upgrade_Shop" или "1_item_shop" или похожее
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("shop") or n:find("store") or n:find("upgrade") or n:find("merchant") or n:find("trader") then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (hrp.Position - part.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = part
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  ЛОГИКА ЦЕЛИ
-- ============================================================

local function getBotTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local bestTarget, bestDist = nil, math.huge
    local myTeam = LocalPlayer:GetAttribute("Team")

    -- 0. Приоритет: Ресурсы (Генератор -> Магазин)
    if States.Bot.AutoShop and States.Bot.AutoShop.Enabled then
        local shopMod = Mega.Features.ShopManager
        if shopMod and shopMod.NeedsBlocks() then
            local ironCount = shopMod.GetIronCount()
            local targetIron = States.Bot.AutoShop.TargetIron or 24

            if ironCount < targetIron then
                -- Нужно больше железа -> идем к генератору
                local gen = findIronGenerator()
                if gen then
                    print("[TumbaHub] ResourceBot: Going to iron generator, iron=" .. ironCount)
                    return gen
                end
            else
                -- Железо собрано -> идем в магазин
                local shop = findShopNPC()
                if shop then
                    print("[TumbaHub] ResourceBot: Going to shop, iron=" .. ironCount)
                    return shop
                end
            end
        end
    end

    -- 1. Приоритет: Кровати
    if States.Bot.TargetBeds then
        for _, bed in ipairs(CollSvc:GetTagged("bed")) do
            local bedTeam = bed:GetAttribute("TeamId") or bed:GetAttribute("Team")
            local health = bed:GetAttribute("Health")
            if bedTeam ~= myTeam and (not health or health > 0) then
                local bPart = bed:IsA("BasePart") and bed or bed.PrimaryPart
                if bPart then
                    local dist = (hrp.Position - bPart.Position).Magnitude
                    if dist < bestDist then bestDist = dist; bestTarget = bPart end
                end
            end
        end
    end

    -- 2. Приоритет: Игроки
    if States.Bot.TargetPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if tHrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - tHrp.Position).Magnitude
                    if dist < bestDist - 10 then bestDist = dist; bestTarget = tHrp end
                end
            end
        end
    end

    return bestTarget
end

-- ============================================================
--  НАВИГАЦИЯ
-- ============================================================

local function isPointSafe(pos)
    local ray = Ray.new(pos + Vector3.new(0, 2, 0), Vector3.new(0, -15, 0))
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit ~= nil
end

local function checkHurdle(hrp)
    local ray = Ray.new(hrp.Position - Vector3.new(0, 1.5, 0), hrp.CFrame.LookVector * 3)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    if hit and hit.CanCollide then
        local ray2 = Ray.new(hrp.Position + Vector3.new(0, 0.5, 0), hrp.CFrame.LookVector * 3)
        local hit2 = Workspace:FindPartOnRayWithIgnoreList(ray2, {LocalPlayer.Character})
        return not hit2
    end
    return false
end

local espPathFolder
local waypointIndex = 1
local currentPath = nil
local lastPathCalc = 0

local function drawPath(waypoints)
    if not espPathFolder then
        espPathFolder = Workspace:FindFirstChild("BotPathESP")
        if not espPathFolder then
            espPathFolder = Instance.new("Folder")
            espPathFolder.Name = "BotPathESP"
            espPathFolder.Parent = Workspace
        end
    end
    espPathFolder:ClearAllChildren()
    for _, wp in ipairs(waypoints) do
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

-- ============================================================
--  ЗАКУПКА (при приближении к магазину)
-- ============================================================

local purchaseRemote
local lastPurchaseTime = 0

local function tryFindPurchaseRemote()
    if purchaseRemote then return end
    pcall(function()
        purchaseRemote = ReplicatedStorage
            :WaitForChild("rbxts_include", 5)
            :WaitForChild("node_modules", 5)
            :WaitForChild("@rbxts", 5)
            :WaitForChild("net", 5)
            :WaitForChild("out", 5)
            :WaitForChild("_NetManaged", 5)
            :WaitForChild("BedwarsPurchaseItem", 5)
    end)
end

local function purchaseAtShop()
    if tick() - lastPurchaseTime < 3 then return end -- Не спамим
    lastPurchaseTime = tick()
    tryFindPurchaseRemote()
    if purchaseRemote then
        pcall(function()
            print("[TumbaHub] Purchasing wool at shop!")
            purchaseRemote:InvokeServer({
                shopItem = {
                    currency = "iron",
                    itemType = "wool_white",
                    amount = 16,
                    price = 8,
                    disabledInQueue = { "mine_wars" },
                    category = "Blocks"
                },
                shopId = "1_item_shop"
            })
        end)
    end
end

-- ============================================================
--  ОСНОВНАЯ ФУНКЦИЯ
-- ============================================================

local prevModuleStates = {}
local stuckTimer = 0
local strafeAngle = 0

function Mega.Features.Bot.SetEnabled(state)
    States.Bot.Enabled = state

    if state then
        stuckTimer = 0
        strafeAngle = 0

        -- Сохраняем предыдущие состояния модулей
        prevModuleStates.Killaura = States.Combat and States.Combat.Killaura and States.Combat.Killaura.Enabled
        prevModuleStates.Scaffold = States.Player and States.Player.Scaffold and States.Player.Scaffold.Enabled
        prevModuleStates.BedNuke  = States.Combat and States.Combat.BedNuke and States.Combat.BedNuke.Enabled
        prevModuleStates.AntiVoid = States.Player and States.Player.AntiVoid and (type(States.Player.AntiVoid) == "table" and States.Player.AntiVoid.Enabled or States.Player.AntiVoid)
        prevModuleStates.Spider   = States.Player and States.Player.Spider

        if States.Bot.AutoKillaura and Mega.Features.Killaura and not prevModuleStates.Killaura then Mega.Features.Killaura.SetEnabled(true) end
        if States.Bot.AutoScaffold and Mega.Features.Scaffold and not prevModuleStates.Scaffold then Mega.Features.Scaffold.SetEnabled(true) end
        if States.Bot.AutoBedNuke  and Mega.Features.BedNuke  and not prevModuleStates.BedNuke  then Mega.Features.BedNuke.SetEnabled(true) end
        if States.Bot.AutoAntiVoid and Mega.Features.AntiVoid and not prevModuleStates.AntiVoid then Mega.Features.AntiVoid.SetEnabled(true) end
        if States.Bot.AutoSpider   and Mega.Features.Spider   and not prevModuleStates.Spider   then Mega.Features.Spider.SetEnabled(true) end

        -- Загружаем Remote заранее в фоне
        task.spawn(tryFindPurchaseRemote)

        connections.BotLoop = RunService.Heartbeat:Connect(function(dt)
            if not States.Bot.Enabled then return end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local target = getBotTarget()
            if not target then
                hum:MoveTo(hrp.Position)
                if espPathFolder then espPathFolder:ClearAllChildren() end
                stuckTimer = 0
                return
            end

            local distToTarget = (hrp.Position - target.Position).Magnitude
            local distToTargetXZ = (hrp.Position * Vector3.new(1,0,1) - target.Position * Vector3.new(1,0,1)).Magnitude
            local isPlayerTarget = target.Parent and target.Parent:FindFirstChild("Humanoid") ~= nil

            -- Определяем: это магазин?
            local targetName = target.Name:lower()
            local isShopTarget = targetName:find("shop") or targetName:find("store") or targetName:find("upgrade") or targetName:find("merchant")

            -- Определяем: это генератор?
            local isGenerator = targetName:find("iron") or targetName:find("generator")

            -- ---- Стоим у генератора (пока копим железо) ----
            if isGenerator and distToTargetXZ <= 4 then
                hum:MoveTo(hrp.Position) -- Стоим на месте
                stuckTimer = 0
                return
            end

            -- ---- Купить -> когда у магазина ----
            if isShopTarget and distToTargetXZ <= 8 then
                hum:MoveTo(hrp.Position)
                purchaseAtShop()
                stuckTimer = 0
                return
            end

            -- ---- Остановиться у кровати ----
            if not isPlayerTarget and not isShopTarget and not isGenerator and distToTargetXZ <= 5 then
                hum:MoveTo(hrp.Position)
                stuckTimer = 0
                return
            end

            -- ---- Страфинг вокруг игрока ----
            if isPlayerTarget and distToTargetXZ <= 15 then
                strafeAngle = strafeAngle + dt * 2
                local offset = Vector3.new(math.cos(strafeAngle) * 10, 0, math.sin(strafeAngle) * 10)
                local strafePos = target.Position + offset
                hum:MoveTo(isPointSafe(strafePos) and strafePos or target.Position)
                stuckTimer = 0
                return
            end

            -- ---- Навигация (Pathfinding) ----
            if States.Bot.Pathfinding and PathSvc then
                if tick() - lastPathCalc > 0.5 then
                    lastPathCalc = tick()
                    pcall(function()
                        local path = PathSvc:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true })
                        path:ComputeAsync(hrp.Position, target.Position)
                        if path.Status == Enum.PathStatus.Success then
                            currentPath = path:GetWaypoints()
                            waypointIndex = 2
                            drawPath(currentPath)
                        else
                            currentPath = nil
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
                    hum:MoveTo(target.Position) -- Прямое движение
                end
            else
                hum:MoveTo(target.Position)
                if checkHurdle(hrp) then hum.Jump = true end
            end

            -- ---- Анти-застревание ----
            local velXZ = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
            if velXZ.Magnitude < 2.5 then
                stuckTimer = stuckTimer + dt
                if stuckTimer > 0.1 then hum.Jump = true end
                if stuckTimer > 1.5 then
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
        end)

    else
        -- Отключение бота
        if connections.BotLoop then connections.BotLoop:Disconnect() end
        if espPathFolder then espPathFolder:ClearAllChildren() end

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
        end

        -- Возвращаем модули в исходное состояние
        local modules = {
            { key = "AutoKillaura", feat = "Killaura" },
            { key = "AutoScaffold", feat = "Scaffold" },
            { key = "AutoBedNuke",  feat = "BedNuke"  },
            { key = "AutoAntiVoid", feat = "AntiVoid" },
            { key = "AutoSpider",   feat = "Spider"   },
        }
        for _, m in ipairs(modules) do
            if States.Bot[m.key] and Mega.Features[m.feat] and not prevModuleStates[m.feat] then
                Mega.Features[m.feat].SetEnabled(false)
            end
        end
    end
end

if States.Bot.Enabled then
    Mega.Features.Bot.SetEnabled(true)
end
