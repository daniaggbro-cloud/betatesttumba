-- features/kaida.lua
-- KillAura для кита Kaida (Summoner) — Roblox Bedwars
-- Kaida бьёт когтем дракона (summoner_claw)
-- Использует SummonerClawAttackRequest + SwordHit как fallback
-- Огромный радиус атаки через спуфинг позиции
-- ============================================================

if not Mega.Features then Mega.Features = {} end
Mega.Features.Kaida = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace         = game:GetService("Workspace"),
    RunService        = game:GetService("RunService"),
    Players           = game:GetService("Players"),
    UserInputService  = game:GetService("UserInputService"),
    CoreGui           = game:GetService("CoreGui"),
}
local LP     = Services.Players.LocalPlayer
local States = Mega.States

-- ────────────────────────────────────────────────────────────
-- СОСТОЯНИЯ
-- ────────────────────────────────────────────────────────────
if not States.Kaida then
    States.Kaida = {
        Enabled    = false,
        Range      = 300,     -- дистанция атаки (огромная, спуфим позицию)
        Delay      = 0,       -- задержка между ударами мс
        TargetESP  = true,    -- подсветка цели
        AutoClick  = false,   -- симуляция ЛКМ для анимации
        OnlyOnClick = false,  -- атака только при клике
        FOVEnabled = false,
        FOVAngle   = 180,
    }
end

-- ────────────────────────────────────────────────────────────
-- ПОДКЛЮЧЕНИЯ (очистка при перезагрузке)
-- ────────────────────────────────────────────────────────────
if not Mega.Objects.KaidaConnections then Mega.Objects.KaidaConnections = {} end
local connections = Mega.Objects.KaidaConnections

for _, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- ────────────────────────────────────────────────────────────
-- REMOTE ПОИСК
-- Из скана найдено:
--   • SummonerClawAttackRequest — основной ремоут когтя Kaida
--   • SwordHit — стандартный ремоут удара мечом (fallback)
-- Оба лежат в _NetManaged
-- ────────────────────────────────────────────────────────────
local SummonerClawRemote = nil
local SwordHitRemote     = nil

local function FindNetManaged()
    local rbxts = Services.ReplicatedStorage:FindFirstChild("rbxts_include")
    if not rbxts then return nil end
    
    local function findNet(parent)
        local f = parent:FindFirstChild("_NetManaged")
        if f then return f end
        for _, c in pairs(parent:GetChildren()) do
            if c:IsA("Folder") then
                local r = findNet(c)
                if r then return r end
            end
        end
    end
    return findNet(rbxts)
end

local function FindRemotes()
    local net = FindNetManaged()
    if not net then return end
    
    -- Основной ремоут Kaida (коготь дракона)
    SummonerClawRemote = net:FindFirstChild("SummonerClawAttackRequest")
    if SummonerClawRemote then
        print("[KaidaAura] ✅ SummonerClawAttackRequest найден!")
    end
    
    -- Fallback: стандартный SwordHit
    SwordHitRemote = net:FindFirstChild("SwordHit")
    if SwordHitRemote then
        print("[KaidaAura] ✅ SwordHit (fallback) найден!")
    end
    
    -- Если оба не найдены — ищем по ключевым словам
    if not SummonerClawRemote and not SwordHitRemote then
        for _, r in pairs(net:GetChildren()) do
            local n = r.Name:lower()
            if n:find("summoner") and n:find("claw") then
                SummonerClawRemote = r
                print("[KaidaAura] ✅ Summoner claw remote (by keyword): " .. r.Name)
            elseif n:find("sword") and n:find("hit") then
                SwordHitRemote = r
                print("[KaidaAura] ✅ Sword hit remote (by keyword): " .. r.Name)
            end
        end
    end
end

task.spawn(function()
    FindRemotes()
    -- Перепроверяем каждые 5 секунд если не нашли
    while not SummonerClawRemote and not SwordHitRemote do
        task.wait(5)
        FindRemotes()
    end
end)

-- ────────────────────────────────────────────────────────────
-- ПОЛУЧЕНИЕ WEAPON (summoner_claw)
-- Из скана: HandInvItem.Value = summoner_claw_1 (Accessory)
-- Это и есть "оружие" Kaida — коготь дракона
-- ────────────────────────────────────────────────────────────
local function getKaidaWeapon()
    local char = LP.Character
    if not char then return nil end

    -- Вариант 1: HandInvItem (главный способ)
    local handInv = char:FindFirstChild("HandInvItem")
    if handInv and handInv.Value then
        return handInv.Value
    end

    -- Вариант 2: Ищем summoner_claw в Character (Accessory)
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") and v.Name:lower():find("summoner_claw") then
            return v
        end
    end

    -- Вариант 3: Ищем в инвентаре RS
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories")
    if inv then
        local playerInv = inv:FindFirstChild(LP.Name)
        if playerInv then
            for _, item in pairs(playerInv:GetChildren()) do
                if item.Name:lower():find("summoner_claw") then
                    return item
                end
            end
            -- Если нет claw — берём любой меч
            for _, item in pairs(playerInv:GetChildren()) do
                local n = item.Name:lower()
                if n:find("sword") or n:find("blade") or n:find("scythe") or n:find("dagger") then
                    return item
                end
            end
        end
    end

    -- Вариант 4: Tool в Character
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end

    return nil
end

-- ────────────────────────────────────────────────────────────
-- VEC3 СОВМЕСТИМОСТЬ
-- ────────────────────────────────────────────────────────────
local vec3 = (vector and vector.create) or Vector3.new

-- ────────────────────────────────────────────────────────────
-- ВИЗУАЛИЗАЦИЯ ЦЕЛИ
-- ────────────────────────────────────────────────────────────
local targetArrow, targetCircle

local function GetVisuals()
    if not targetArrow then
        targetArrow = Instance.new("BillboardGui")
        targetArrow.Name = "KaidaAuraArrow"
        targetArrow.Size = UDim2.new(0, 60, 0, 60)
        targetArrow.StudsOffset = Vector3.new(0, 5, 0)
        targetArrow.AlwaysOnTop = true
        local lbl = Instance.new("TextLabel", targetArrow)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "🐉"
        lbl.TextScaled = true
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBlack
    end
    if not targetCircle then
        targetCircle = Instance.new("CylinderHandleAdornment")
        targetCircle.Name = "KaidaAuraCircle"
        targetCircle.Height = 0.05
        targetCircle.Radius = 3
        targetCircle.InnerRadius = 2.6
        targetCircle.Color3 = Color3.fromRGB(180, 50, 255)   -- фиолетовый (Summoner/Kaida)
        targetCircle.Transparency = 0.25
        targetCircle.AlwaysOnTop = true
        targetCircle.ZIndex = 1
        targetCircle.CFrame = CFrame.new(0, -2.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    local container = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui
    if targetArrow.Parent ~= container then targetArrow.Parent = container end
    if targetCircle.Parent ~= container then targetCircle.Parent = container end
    return targetArrow, targetCircle
end

local function HideVisuals()
    if targetArrow  then targetArrow.Adornee  = nil; targetArrow.Enabled  = false end
    if targetCircle then targetCircle.Adornee = nil; targetCircle.Visible = false end
end

-- ────────────────────────────────────────────────────────────
-- FOV ПРОВЕРКА
-- ────────────────────────────────────────────────────────────
local function inFOV(targetPart)
    if not States.Kaida.FOVEnabled then return true end
    local cam = workspace.CurrentCamera
    if not cam then return true end
    local look = cam.CFrame.LookVector
    local dir  = (targetPart.Position - cam.CFrame.Position).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(dir), -1, 1)))
    return angle <= (States.Kaida.FOVAngle or 180)
end

-- ────────────────────────────────────────────────────────────
-- ПОИСК ЦЕЛИ
-- ────────────────────────────────────────────────────────────
local function findTarget(hrp)
    local best, bestDist = nil, States.Kaida.Range

    -- Игроки
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LP and p.Team ~= LP.Team then
            local c = p.Character
            local tHrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum  = c and c:FindFirstChild("Humanoid")
            if tHrp and hum and hum.Health > 0 then
                local d = (hrp.Position - tHrp.Position).Magnitude
                if d < bestDist and inFOV(tHrp) then
                    bestDist = d
                    best = c
                end
            end
        end
    end

    -- Дамми / NPC (если нет игроков)
    if not best then
        for _, obj in pairs(Services.Workspace:GetChildren()) do
            if obj ~= LP.Character and obj:FindFirstChild("Humanoid") then
                local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                local hum  = obj:FindFirstChild("Humanoid")
                if tHrp and hum and hum.Health > 0 then
                    local p2 = Services.Players:GetPlayerFromCharacter(obj)
                    local isEnemy = true
                    if p2 and (p2 == LP or (p2.Team and LP.Team and p2.Team == LP.Team)) then
                        isEnemy = false
                    end
                    if isEnemy then
                        local d = (hrp.Position - tHrp.Position).Magnitude
                        if d < bestDist and inFOV(tHrp) then
                            bestDist = d
                            best = obj
                        end
                    end
                end
            end
        end
    end

    return best, bestDist
end

-- ────────────────────────────────────────────────────────────
-- КЛИК-ТРЕКИНГ
-- ────────────────────────────────────────────────────────────
local clickTriggered     = false
local isSimulatingClick  = false

if not Mega.Objects.KaidaInputConns then
    Mega.Objects.KaidaInputConns = {}
    table.insert(Mega.Objects.KaidaInputConns, Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed or isSimulatingClick then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            clickTriggered = true
        end
    end))
end

-- ────────────────────────────────────────────────────────────
-- АТАКА KAIDA — ключевая функция
-- Стратегия атаки:
-- 1) SummonerClawAttackRequest — специфичный ремоут Kaida
-- 2) SwordHit — стандартный ремоут (с weapon = summoner_claw_1)
-- Позиция спуфится вплотную к цели (2.5 studs)
-- ────────────────────────────────────────────────────────────
local lastAttackTime  = 0
local kaidaAuraActive = false

local function doAttack(target, hrp, dist)
    local tHrp = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
    if not tHrp then return end

    local weapon = getKaidaWeapon()
    local dir = (tHrp.Position - hrp.Position).Unit

    -- Спуфим позицию на 2.5 studs от цели (обход серверной проверки дистанции)
    local spoofPos = tHrp.Position - (dir * 2.5)
    -- Если расстояние маленькое — не спуфим
    if dist <= 14 then
        spoofPos = hrp.Position
    end

    -- === Попытка 1: SummonerClawAttackRequest ===
    if SummonerClawRemote then
        pcall(function()
            SummonerClawRemote:FireServer({
                ["entityInstance"] = target,
                ["validate"] = {
                    ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                    ["selfPosition"]   = { ["value"] = vec3(spoofPos.X, spoofPos.Y, spoofPos.Z) },
                    ["raycast"] = {
                        ["cameraPosition"] = { ["value"] = vec3(spoofPos.X, spoofPos.Y + 3, spoofPos.Z) },
                        ["cursorDirection"] = { ["value"] = vec3(dir.X, dir.Y, dir.Z) }
                    }
                }
            })
        end)
    end

    -- === Попытка 2: SwordHit с weapon = summoner_claw ===
    if SwordHitRemote and weapon then
        pcall(function()
            SwordHitRemote:FireServer({
                ["chargedAttack"] = { ["chargeRatio"] = 0 },
                ["entityInstance"] = target,
                ["validate"] = {
                    ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                    ["selfPosition"]   = { ["value"] = vec3(spoofPos.X, spoofPos.Y, spoofPos.Z) },
                    ["raycast"] = {
                        ["cameraPosition"] = { ["value"] = vec3(spoofPos.X, spoofPos.Y + 3, spoofPos.Z) },
                        ["cursorDirection"] = { ["value"] = vec3(dir.X, dir.Y, dir.Z) }
                    }
                },
                ["weapon"] = weapon
            })
        end)
    end

    -- Если ни один ремоут не найден — пробуем через Mega.GetRemote (стандартный killaura)
    if not SummonerClawRemote and not SwordHitRemote then
        local fallbackRemote = Mega.GetRemote and Mega.GetRemote("AttackEntity")
        if fallbackRemote and weapon then
            pcall(function()
                fallbackRemote:FireServer({
                    ["chargedAttack"] = { ["chargeRatio"] = 0 },
                    ["entityInstance"] = target,
                    ["validate"] = {
                        ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                        ["selfPosition"]   = { ["value"] = vec3(spoofPos.X, spoofPos.Y, spoofPos.Z) },
                        ["raycast"] = {
                            ["cameraPosition"] = { ["value"] = vec3(spoofPos.X, spoofPos.Y + 3, spoofPos.Z) },
                            ["cursorDirection"] = { ["value"] = vec3(dir.X, dir.Y, dir.Z) }
                        }
                    },
                    ["weapon"] = weapon
                })
            end)
        end
    end

    -- Симуляция клика для анимации удара
    if States.Kaida.AutoClick then
        task.spawn(function()
            isSimulatingClick = true
            if mouse1click then
                mouse1click()
            else
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait()
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
            task.wait(0.05)
            isSimulatingClick = false
        end)
    end
end

-- ────────────────────────────────────────────────────────────
-- ГЛАВНЫЙ ЦИКЛ
-- ────────────────────────────────────────────────────────────
function Mega.Features.Kaida.SetEnabled(state)
    States.Kaida.Enabled = state

    if not state then
        HideVisuals()
        return
    end

    if kaidaAuraActive then return end
    kaidaAuraActive = true

    task.spawn(function()
        while States.Kaida.Enabled do
            if Mega.Unloaded then break end

            local char = LP.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            local arrow, circle = GetVisuals()

            if hrp then
                local target, dist = findTarget(hrp)

                -- Визуализация
                if target and States.Kaida.TargetESP then
                    local tHrp = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                    arrow.Adornee  = tHrp
                    circle.Adornee = tHrp
                    arrow.Enabled  = true
                    circle.Visible = true
                    arrow.StudsOffset = Vector3.new(0, 5 + math.sin(tick() * 6) * 0.5, 0)
                else
                    HideVisuals()
                end

                -- Атака
                if target then
                    local now = tick()
                    local delay = math.max(0, (States.Kaida.Delay or 0) / 1000)
                    local jitter = math.random(-20, 20) / 1000
                    local effectiveDelay = math.max(0, delay + jitter)

                    local canAttack = true
                    if States.Kaida.OnlyOnClick then
                        if clickTriggered then
                            clickTriggered = false
                        else
                            canAttack = false
                        end
                    end

                    if canAttack and (now - lastAttackTime) >= effectiveDelay then
                        lastAttackTime = now
                        doAttack(target, hrp, dist)
                    end
                end
            end

            Services.RunService.Heartbeat:Wait()
        end
        kaidaAuraActive = false
        HideVisuals()
    end)
end
