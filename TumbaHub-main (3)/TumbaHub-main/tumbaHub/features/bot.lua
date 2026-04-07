-- features/bot.lua
-- Logic for Auto-Bot (Pathfinding, Target tracking, Auto-modules)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Bot = {}

-- Сервисы напрямую (НЕ через Mega.Services, чтобы избежать nil)
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local PathSvc           = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = workspace

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
--  ПОИСК ОБЪЕКТОВ (точные пути из GameDump)
-- ============================================================

-- Находит ближайший железный генератор команды игрока
-- В Bedwars генераторы - это модели с именем вида "blue_generator", "red_generator"
-- или объекты с тегом "generator", или содержащие "Generator" в имени
-- Вспомогательная функция: получить позицию из любого объекта
local function getObjPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("CFrameValue") then
        -- В Bedwars генераторы - это CFrameValue! Позиция берётся через .Value
        return obj.Value.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    return nil
end

local function findIronGenerator()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge

    -- В Bedwars генераторы называются "cframe-N_generator" и являются CFrameValue
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("generator") then
            local pos = getObjPosition(obj)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = obj
                end
            end
        end
    end

    -- Дополнительный поиск по GetDescendants если не нашли
    if not best then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("generator") then
                local pos = getObjPosition(obj)
                if pos then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = obj
                    end
                end
            end
        end
    end

    return best
end

-- Находит NPC магазина по точному пути из GameDump:
-- workspace["1_item_shop"].desertMerchant
local function findShopNPC()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- ТОЧНЫЙ путь из GameDump
    local shopModel = Workspace:FindFirstChild("1_item_shop")
    if shopModel then
        local merchant = shopModel:FindFirstChild("desertMerchant")
        if merchant then
            local part = merchant.PrimaryPart or merchant:FindFirstChildWhichIsA("BasePart", true)
            if part then return part end
        end
        -- Резерв: любая BasePart внутри shopModel
        local part = shopModel.PrimaryPart or shopModel:FindFirstChildWhichIsA("BasePart", true)
        if part then return part end
    end

    -- Резервный поиск по имени если точный путь не сработал
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("shop") or obj.Name == "1_item_shop") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then return part end
        end
    end

    return nil
end

-- Счетчик железа в инвентаре
local function getIronCount()
    local count = 0
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")

    local function countIn(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item.Name == "iron" or item.Name == "Iron" then
                local amt = item:GetAttribute("Amount") or item:GetAttribute("amount") or 1
                count = count + (tonumber(amt) or 1)
            end
        end
    end

    countIn(bp)
    if char then countIn(char) end
    return count
end

-- Нужно ли покупать блоки?
local function needsBlocks()
    if not States.Bot.AutoShop or not States.Bot.AutoShop.Enabled then return false end
    -- Считаем шерсть в инвентаре
    local count = 0
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local minBlocks = States.Bot.AutoShop.MinBlocks or 16
    local function countIn(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item.Name:lower():find("wool") then
                local amt = item:GetAttribute("Amount") or item:GetAttribute("amount") or 1
                count = count + (tonumber(amt) or 1)
            end
        end
    end
    countIn(bp)
    if char then countIn(char) end
    return count < minBlocks
end

-- ============================================================
--  ЛОГИКА ЦЕЛИ
-- ============================================================

-- Состояние машины
-- "idle" -> "farm_iron" -> "go_shop" -> "buy" -> "combat"
local botPhase = "idle"

local function getBotTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, "idle" end

    local myTeam = LocalPlayer:GetAttribute("Team")

    -- Фаза ресурсов
    if States.Bot.AutoShop and States.Bot.AutoShop.Enabled then
        if needsBlocks() then
            local iron = getIronCount()
            local targetIron = States.Bot.AutoShop.TargetIron or 24

            if iron < targetIron then
                -- ФАЗА 1: Накапливаем железо у генератора
                local gen = findIronGenerator()
                if gen then
                    return gen, "farm_iron"
                end
            else
                -- ФАЗА 2: Идем в магазин покупать
                local shop = findShopNPC()
                if shop then
                    return shop, "go_shop"
                end
            end
        end
    end

    -- ФАЗА 3: Боевая логика
    local bestTarget, bestDist = nil, math.huge

    -- Кровати
    if States.Bot.TargetBeds then
        local CollSvc = game:GetService("CollectionService")
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

    -- Игроки
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

    return bestTarget, "combat"
end

-- ============================================================
--  ПОКУПКА
-- ============================================================

local purchaseRemote
local lastPurchaseTime = 0

local function tryBuy()
    if tick() - lastPurchaseTime < 3 then return end
    lastPurchaseTime = tick()

    if not purchaseRemote then
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

    if purchaseRemote then
        pcall(function()
            print("[TumbaHub] Buying wool_white for 8 iron...")
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
    else
        warn("[TumbaHub] BedwarsPurchaseItem remote not found!")
    end
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
    local dir = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
    local ray = Ray.new(hrp.Position - Vector3.new(0, 1.5, 0), dir * 3)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    if hit and hit.CanCollide then
        local ray2 = Ray.new(hrp.Position + Vector3.new(0, 0.5, 0), dir * 3)
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
        espPathFolder = Workspace:FindFirstChild("BotPathESP") or Instance.new("Folder")
        espPathFolder.Name = "BotPathESP"
        espPathFolder.Parent = Workspace
    end
    espPathFolder:ClearAllChildren()
    for _, wp in ipairs(waypoints) do
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.8, 0.8, 0.8)
        p.Position = wp.Position
        p.Anchored = true; p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(0, 255, 150)
        p.Transparency = 0.5
        p.Parent = espPathFolder
    end
end

-- ============================================================
--  ОСНОВНОЙ ЦИКЛ
-- ============================================================

local prevModuleStates = {}
local stuckTimer = 0
local strafeAngle = 0

function Mega.Features.Bot.SetEnabled(state)
    States.Bot.Enabled = state

    if state then
        stuckTimer = 0; strafeAngle = 0
        currentPath = nil; waypointIndex = 1

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

        -- Инициализация remote заранее
        task.spawn(function()
            pcall(function()
                purchaseRemote = ReplicatedStorage
                    :WaitForChild("rbxts_include", 10)
                    :WaitForChild("node_modules", 10)
                    :WaitForChild("@rbxts", 10)
                    :WaitForChild("net", 10)
                    :WaitForChild("out", 10)
                    :WaitForChild("_NetManaged", 10)
                    :WaitForChild("BedwarsPurchaseItem", 10)
                print("[TumbaHub] BedwarsPurchaseItem remote loaded!")
            end)
        end)

        connections.BotLoop = RunService.Heartbeat:Connect(function(dt)
            if not States.Bot.Enabled then return end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local target, phase = getBotTarget()

            if not target then
                hum:MoveTo(hrp.Position)
                if espPathFolder then espPathFolder:ClearAllChildren() end
                stuckTimer = 0
                return
            end

            -- Безопасно получаем позицию (учитываем CFrameValue генераторы)
            local targetPos = getObjPosition(target) or (target:IsA("Instance") and target:FindFirstChildWhichIsA("BasePart") and target:FindFirstChildWhichIsA("BasePart").Position)
            if not targetPos then return end

            local distXZ = (hrp.Position * Vector3.new(1,0,1) - targetPos * Vector3.new(1,0,1)).Magnitude

            -- == Обработка по фазе ==

            if phase == "farm_iron" then
                -- Стоим у генератора пока не наберем железа
                if distXZ <= 3 then
                    hum:MoveTo(hrp.Position) -- стоим на месте
                    stuckTimer = 0
                    return
                end
                -- Идем к генератору (ниже навигация)

            elseif phase == "go_shop" then
                -- Подошли к магазину - покупаем!
                if distXZ <= 5 then
                    hum:MoveTo(hrp.Position)
                    tryBuy()
                    stuckTimer = 0
                    return
                end
                -- Идем к магазину (ниже навигация)

            elseif phase == "combat" then
                local isPlayerTarget = target.Parent and target.Parent:FindFirstChild("Humanoid") ~= nil

                -- Страфинг вокруг игрока
                if isPlayerTarget and distXZ <= 15 then
                    strafeAngle = strafeAngle + dt * 2
                    local offset = Vector3.new(math.cos(strafeAngle) * 10, 0, math.sin(strafeAngle) * 10)
                    local strafePos = target.Position + offset
                    hum:MoveTo(isPointSafe(strafePos) and strafePos or target.Position)
                    stuckTimer = 0
                    return
                end

                -- Стоим у кровати
                if not isPlayerTarget and distXZ <= 5 then
                    hum:MoveTo(hrp.Position)
                    stuckTimer = 0
                    return
                end
            end

            -- == Общая навигация (Pathfinding) ==
            if PathSvc and States.Bot.Pathfinding then
                if tick() - lastPathCalc > 0.5 then
                    lastPathCalc = tick()
                    pcall(function()
                        local path = PathSvc:CreatePath({
                            AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true
                        })
                        path:ComputeAsync(hrp.Position, targetPos)
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
                    if wp.Action == Enum.PathWaypointAction.Jump or checkHurdle(hrp) then
                        hum.Jump = true
                    end
                    if (hrp.Position * Vector3.new(1,0,1) - wp.Position * Vector3.new(1,0,1)).Magnitude < 3 then
                        waypointIndex = waypointIndex + 1
                    end
                else
                    hum:MoveTo(targetPos)
                end
            else
                hum:MoveTo(targetPos)
                if checkHurdle(hrp) then hum.Jump = true end
            end

            -- == Анти-застрявание ==
            local velXZ = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
            if velXZ.Magnitude < 2.5 then
                stuckTimer = stuckTimer + dt
                if stuckTimer > 0.3 then hum.Jump = true end
                if stuckTimer > 1.5 then
                    local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
                    local side = hrp.CFrame.RightVector * Vector3.new(1, 0, 1)
                    if look.Magnitude < 0.1 then look = Vector3.new(1, 0, 0) end
                    local tp = hrp.Position + look * 3 + side * 2 + Vector3.new(0, 5, 0)
                    if isPointSafe(tp) then
                        hrp.CFrame = CFrame.new(tp, targetPos)
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
                    end
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
