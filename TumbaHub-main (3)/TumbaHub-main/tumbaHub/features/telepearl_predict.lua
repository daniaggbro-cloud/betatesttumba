-- features/telepearl_predict.lua
-- Telepearl ESP — визуализация траектории и места приземления (Поддержка множества жемчугов)

if not Mega.Features then Mega.Features = {} end
Mega.Features.TelepearlESP = {}

local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")
local Debris       = game:GetService("Debris")

local States = Mega.States

local GRAVITY       = 70      -- studs/sec² (кастомная)
local LINE_COLOR    = Color3.fromRGB(160, 60, 255)
local CIRCLE_COLOR  = Color3.fromRGB(160, 60, 255)
local PEARL_ICON    = "rbxassetid://6874950144"

-- Таблица для хранения всех активных траекторий
local activeESPFolders = {}
local watcherConn  = nil

-- ── Расчёт траектории ─────────────────────────────────────
local function computeTrajectory(origin, velocity)
    local g   = GRAVITY
    local pts = {}
    local dt  = 0.016
    local t   = 0
    while t <= 6 do
        local p = Vector3.new(
            origin.X + velocity.X * t,
            origin.Y + velocity.Y * t - 0.5 * g * t * t,
            origin.Z + velocity.Z * t
        )
        table.insert(pts, { t = t, pos = p })
        if t > 0.2 and p.Y < origin.Y - 600 then break end
        t = t + dt
    end
    return pts
end

local function findLanding(pts, originY)
    for i = 2, #pts do
        local a, b = pts[i-1], pts[i]
        if b.pos.Y <= originY and a.pos.Y > originY then
            local r  = (a.pos.Y - originY) / (a.pos.Y - b.pos.Y)
            return a.pos + (b.pos - a.pos) * r
        end
    end
    return nil
end

-- ── Отрисовка ESP для ОДНОГО жемчуга ──────────────────────
local function createPearlESP(pts, landingPos, s)
    -- Создаем уникальную папку для этого броска
    local folder = Instance.new("Folder")
    folder.Name = "TelepearlESP_Instance"
    folder.Parent = Workspace
    table.insert(activeESPFolders, folder)

    local currentColor = s.Color or LINE_COLOR

    -- 1. Точки (Траектория)
    local spacing = math.max(0.5, s.DotSpacing or 5)
    local accDist = 0
    local tooMany = false
    local dotCount = 0

    for i = 2, #pts do
        if tooMany then break end
        local prev = pts[i-1].pos
        local curr = pts[i].pos
        local seg  = (curr - prev).Magnitude
        if seg < 0.001 then continue end
        accDist = accDist + seg

        while accDist >= spacing do
            accDist = accDist - spacing
            local frac = 1 - (accDist / seg)
            local pos  = prev + (curr - prev) * frac

            local p = Instance.new("Part")
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.CastShadow = false
            p.Shape = Enum.PartType.Ball
            p.Material = Enum.Material.Neon
            p.Color = currentColor
            p.Size = Vector3.new(0.25, 0.25, 0.25)
            p.Position = pos
            p.Parent = folder

            dotCount = dotCount + 1
            if dotCount > 300 then
                tooMany = true
                break
            end
        end
    end

    -- 2. Кольцо и Иконка (Место приземления)
    if landingPos then
        local circleTransp = (s.CircleTransp or 30) / 100
        local iconTransp   = (s.IconTransp or 30) / 100

        -- Создаем кольцо
        local SEGMENTS = 40
        local RADIUS   = 3.5
        for i = 1, SEGMENTS do
            local seg = Instance.new("Part")
            seg.Anchored     = true
            seg.CanCollide   = false
            seg.CanQuery     = false
            seg.CanTouch     = false
            seg.CastShadow   = false
            seg.Shape        = Enum.PartType.Block
            seg.Material     = Enum.Material.Neon
            seg.Color        = currentColor
            seg.Size         = Vector3.new(RADIUS * 2 * math.pi / SEGMENTS * 0.9, 0.15, 0.15)
            
            local angle = (i / SEGMENTS) * math.pi * 2
            local x     = landingPos.X + RADIUS * math.cos(angle)
            local z     = landingPos.Z + RADIUS * math.sin(angle)
            local nextA = ((i) / SEGMENTS) * math.pi * 2
            local midA  = (angle + nextA) / 2
            seg.CFrame  = CFrame.new(x, landingPos.Y + 0.1, z)
                        * CFrame.Angles(0, -(midA + math.pi/2), 0)
            seg.Transparency = circleTransp
            seg.Parent       = folder
        end

        -- Создаем иконку
        local anchor = Instance.new("Part")
        anchor.Name        = "PearlESPIconAnchor"
        anchor.Anchored    = true
        anchor.CanCollide  = false
        anchor.CanQuery    = false
        anchor.CanTouch    = false
        anchor.CastShadow  = false
        anchor.Size        = Vector3.new(0.1, 0.1, 0.1)
        anchor.Transparency = 1
        anchor.Position    = landingPos + Vector3.new(0, 2, 0)
        anchor.Parent      = folder

        local iconBillboard = Instance.new("BillboardGui")
        iconBillboard.Size          = UDim2.new(0, 32, 0, 32)
        iconBillboard.StudsOffset   = Vector3.new(0, 2, 0)
        iconBillboard.AlwaysOnTop   = true
        iconBillboard.Adornee       = anchor
        iconBillboard.Parent        = anchor

        local img = Instance.new("ImageLabel")
        img.Size              = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.ImageTransparency = iconTransp
        img.Image             = PEARL_ICON
        img.Parent            = iconBillboard
    end

    return folder
end

-- ── Главный обработчик ────────────────────────────────────
local function onPearlSpawned(handle)
    task.defer(function()
        if not handle.Parent then return end
        
        local origin = handle.Position
        local vel    = handle.AssemblyLinearVelocity
        local s      = States.TelepearlESP

        -- Считаем
        local pts     = computeTrajectory(origin, vel)
        local landing = findLanding(pts, origin.Y)

        -- Рисуем уникальную траекторию
        local espFolder = createPearlESP(pts, landing, s)

        -- Ждем уничтожения ЭТОГО конкретного жемчуга
        local conn
        conn = handle.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                if conn then conn:Disconnect() end
                
                -- Запускаем таймер из UI
                local delayTime = s.Duration or 1
                task.delay(delayTime, function()
                    if espFolder and espFolder.Parent then
                        espFolder:Destroy()
                    end
                    -- Убираем из трекера активных папок
                    local idx = table.find(activeESPFolders, espFolder)
                    if idx then table.remove(activeESPFolders, idx) end
                end)
            end
        end)
    end)
end

-- ── Watcher — ловим Workspace.telepearl ───────────────────
local function startWatcher()
    if watcherConn then watcherConn:Disconnect() end

    watcherConn = Workspace.DescendantAdded:Connect(function(obj)
        if not States.TelepearlESP.Enabled then return end

        if obj.Name == "telepearl" and obj:IsA("Model") then
            local h = obj:FindFirstChild("Handle")
            if h then
                onPearlSpawned(h)
            else
                local conn
                conn = obj.ChildAdded:Connect(function(child)
                    if child.Name == "Handle" then
                        conn:Disconnect()
                        onPearlSpawned(child)
                    end
                end)
            end
        end
    end)
end

local function stopWatcher()
    if watcherConn then
        watcherConn:Disconnect()
        watcherConn = nil
    end
end

-- Удаляем ВСЕ нарисованные траектории при выключении функции
local function destroyAllObjects()
    for _, folder in ipairs(activeESPFolders) do
        if folder and folder.Parent then
            folder:Destroy()
        end
    end
    table.clear(activeESPFolders)
end

-- ── Публичный API ──────────────────────────────────────────
function Mega.Features.TelepearlESP.SetEnabled(state)
    States.TelepearlESP.Enabled = state

    if state then
        startWatcher()
    else
        stopWatcher()
        destroyAllObjects()
    end
end

if States.TelepearlESP.Enabled then
    Mega.Features.TelepearlESP.SetEnabled(true)
end
