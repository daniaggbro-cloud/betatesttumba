-- features/telepearl_predict.lua
-- Telepearl ESP — визуализация траектории и места приземления
--
-- Подтверждённые данные (живой перехват):
--   Workspace object: Workspace.telepearl.Handle [MeshPart]
--   launchVelocity:   120 studs/sec (observed: 119.7)
--   gravity:          70 studs/sec² (кастомная BedWars)

if not Mega.Features then Mega.Features = {} end
Mega.Features.TelepearlESP = {}

local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")
local Debris       = game:GetService("Debris")

local States = Mega.States
-- States инициализируются в settings.lua (TelepearlESP)
-- CircleTransp / IconTransp хранятся как 0–100 (int slider), делим на 100 при использовании

local GRAVITY       = 70      -- studs/sec² (кастомная)
local LINE_COLOR    = Color3.fromRGB(160, 60, 255)   -- фиолетовый
local CIRCLE_COLOR  = Color3.fromRGB(160, 60, 255)
local PEARL_ICON    = "rbxassetid://6874950144"

-- ── Пул объектов (переиспользуем, не создаём каждый кадр) ─
local dotPool       = {}
local circleModel   = nil
local iconBillboard = nil
local currentDots   = {}

local function getOrCreateDot(idx)
    if dotPool[idx] then
        return dotPool[idx]
    end
    local p = Instance.new("Part")
    p.Name         = "PearlESPDot_" .. idx
    p.Anchored     = true
    p.CanCollide   = false
    p.CanQuery     = false
    p.CanTouch     = false
    p.CastShadow   = false
    p.Shape        = Enum.PartType.Ball
    p.Material     = Enum.Material.Neon
    p.Color        = LINE_COLOR
    p.Size         = Vector3.new(0.25, 0.25, 0.25)
    p.Parent       = Workspace
    dotPool[idx]   = p
    return p
end

local function hideDots(from)
    for i = from, #dotPool do
        if dotPool[i] then
            dotPool[i].Position = Vector3.new(0, -9999, 0)
        end
    end
end

-- ── Кольцо приземления ────────────────────────────────────
local function ensureCircle()
    if circleModel and circleModel.Parent then return end

    circleModel = Instance.new("Model")
    circleModel.Name = "PearlESPCircle"
    circleModel.Parent = Workspace

    local SEGMENTS = 40
    local RADIUS   = 3.5
    for i = 1, SEGMENTS do
        local seg = Instance.new("Part")
        seg.Name         = "Seg_" .. i
        seg.Anchored     = true
        seg.CanCollide   = false
        seg.CanQuery     = false
        seg.CanTouch     = false
        seg.CastShadow   = false
        seg.Shape        = Enum.PartType.Block
        seg.Material     = Enum.Material.Neon
        seg.Color        = CIRCLE_COLOR
        seg.Size         = Vector3.new(RADIUS * 2 * math.pi / SEGMENTS * 0.9, 0.15, 0.15)
        seg.Parent       = circleModel
    end
end

local function updateCircle(center, transp)
    if not circleModel or not circleModel.Parent then ensureCircle() end
    local SEGMENTS = 40
    local RADIUS   = 3.5
    local children = circleModel:GetChildren()
    for i, seg in ipairs(children) do
        local angle = (i / SEGMENTS) * math.pi * 2
        local x     = center.X + RADIUS * math.cos(angle)
        local z     = center.Z + RADIUS * math.sin(angle)
        local nextA = ((i) / SEGMENTS) * math.pi * 2
        local midA  = (angle + nextA) / 2
        seg.CFrame  = CFrame.new(x, center.Y + 0.1, z)
                    * CFrame.Angles(0, -(midA + math.pi/2), 0)
        seg.Transparency = transp
    end
end

local function hideCircle()
    if circleModel then
        for _, seg in ipairs(circleModel:GetChildren()) do
            seg.Position = Vector3.new(0, -9999, 0)
        end
    end
end

-- ── Иконка над местом приземления ─────────────────────────
local function ensureIcon()
    if iconBillboard and iconBillboard.Parent then return end

    local anchor = Instance.new("Part")
    anchor.Name        = "PearlESPIconAnchor"
    anchor.Anchored    = true
    anchor.CanCollide  = false
    anchor.CanQuery    = false
    anchor.CanTouch    = false
    anchor.CastShadow  = false
    anchor.Size        = Vector3.new(0.1, 0.1, 0.1)
    anchor.Transparency = 1
    anchor.Parent      = Workspace

    iconBillboard = Instance.new("BillboardGui")
    iconBillboard.Name          = "PearlESPIcon"
    iconBillboard.Size          = UDim2.new(0, 64, 0, 64)
    iconBillboard.StudsOffset   = Vector3.new(0, 2, 0)
    iconBillboard.AlwaysOnTop   = true
    iconBillboard.Adornee       = anchor
    iconBillboard.Parent        = anchor

    local img = Instance.new("ImageLabel")
    img.Name              = "Icon"
    img.Size              = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image             = PEARL_ICON
    img.Parent            = iconBillboard

    -- Сохраняем ссылку на anchor в модели
    iconBillboard:SetAttribute("AnchorRef", anchor)
end

local function updateIcon(pos, transp)
    if not iconBillboard or not iconBillboard.Parent then ensureIcon() end
    local anchor = iconBillboard:GetAttribute("AnchorRef")
            or Workspace:FindFirstChild("PearlESPIconAnchor")
    if anchor then
        anchor.Position = pos + Vector3.new(0, 2, 0)
    end
    local img = iconBillboard:FindFirstChild("Icon")
    if img then
        img.ImageTransparency = transp
    end
end

local function hideIcon()
    if iconBillboard then
        local anchor = Workspace:FindFirstChild("PearlESPIconAnchor")
        if anchor then anchor.Position = Vector3.new(0, -9999, 0) end
    end
end

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

-- ── Размещение точек с заданным шагом ─────────────────────
local function placeDots(pts, spacingStuds)
    local spacing = math.max(0.5, spacingStuds)
    local dotIdx  = 1
    local accDist = 0
    local tooMany = false

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

            local dot = getOrCreateDot(dotIdx)
            dot.Position = pos
            dotIdx = dotIdx + 1

            if dotIdx > 300 then
                tooMany = true
                break
            end
        end
    end

    hideDots(dotIdx)
    return dotIdx - 1
end

-- ── Главный render-цикл ───────────────────────────────────
local renderConn   = nil
local watcherConn  = nil
local activePearl  = nil   -- текущий Handle жемчуга
local pearlOrigin  = nil   -- позиция при рождении
local pearlVel     = nil   -- velocity при рождении

local function onPearlSpawned(handle)
    task.defer(function()
        if not handle.Parent then return end
        activePearl = handle
        pearlOrigin = handle.Position
        pearlVel    = handle.AssemblyLinearVelocity

        -- Рассчитываем траекторию один раз при появлении
        local s = States.TelepearlESP
        local pts = computeTrajectory(pearlOrigin, pearlVel)

        -- Точки (DotSpacing = studs int)
        placeDots(pts, s.DotSpacing)

        -- Landing (CircleTransp / IconTransp — 0..100 int → 0..1 float)
        local landing = findLanding(pts, pearlOrigin.Y)
        if landing then
            updateCircle(landing, (s.CircleTransp or 30) / 100)
            updateIcon(landing, (s.IconTransp or 30) / 100)
        end
    end)
end

local function clearAll()
    hideDots(1)
    hideCircle()
    hideIcon()
    activePearl = nil
    pearlOrigin = nil
    pearlVel    = nil
end

-- ── Watcher — ловим Workspace.telepearl ───────────────────
local function startWatcher()
    if watcherConn then watcherConn:Disconnect() end

    watcherConn = Workspace.DescendantAdded:Connect(function(obj)
        if not States.TelepearlESP.Enabled then return end

        -- Model "telepearl" или её Handle
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

            -- Очищаем когда pearl исчезает
            obj.AncestryChanged:Connect(function(_, newParent)
                if not newParent then
                    -- pearl уничтожен — убираем через полсекунды
                    task.delay(0.5, clearAll)
                end
            end)
        end
    end)
end

local function stopWatcher()
    if watcherConn then
        watcherConn:Disconnect()
        watcherConn = nil
    end
end

-- ── Destroy всё при выключении ────────────────────────────
local function destroyAllObjects()
    for _, d in ipairs(dotPool) do
        if d and d.Parent then d:Destroy() end
    end
    dotPool = {}
    if circleModel and circleModel.Parent then circleModel:Destroy() end
    circleModel = nil
    local anchor = Workspace:FindFirstChild("PearlESPIconAnchor")
    if anchor then anchor:Destroy() end
    iconBillboard = nil
end

-- ── Публичный API ──────────────────────────────────────────
function Mega.Features.TelepearlESP.SetEnabled(state)
    States.TelepearlESP.Enabled = state

    if state then
        ensureCircle()
        ensureIcon()
        startWatcher()
        hideCircle()
        hideIcon()
        print("[TumbaHub] TelepearlESP: Enabled")
    else
        stopWatcher()
        destroyAllObjects()
        print("[TumbaHub] TelepearlESP: Disabled")
    end
end

-- Восстанавливаем при загрузке
if States.TelepearlESP.Enabled then
    Mega.Features.TelepearlESP.SetEnabled(true)
end
