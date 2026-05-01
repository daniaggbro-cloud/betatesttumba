-- features/gorilla_chams.lua
-- Gorilla 3D Model Chams

if not Mega.Features then Mega.Features = {} end
Mega.Features.GorillaChams = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Visuals then States.Visuals = {} end
if not States.Visuals.GorillaMode then
    States.Visuals.GorillaMode = false
end

if not Mega.Objects.GorillaConnections then Mega.Objects.GorillaConnections = {} end
local connections = Mega.Objects.GorillaConnections

-- Очистка старых коннекшенов
local function CleanupConnections()
    for k, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(connections)
end

local MESH_ID = "rbxassetid://430330296"
local TEXTURE_ID = "rbxassetid://430330316"

local function ApplyGorilla(character)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Проверяем, есть ли уже горилла
    if character:FindFirstChild("GorillaChamsPart") then return end

    -- Делаем оригинальное тело невидимым
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = 1 end
        end
    end

    -- Создаем парту для гориллы
    local gorillaPart = Instance.new("Part")
    gorillaPart.Name = "GorillaChamsPart"
    gorillaPart.Size = Vector3.new(2, 2, 2)
    gorillaPart.Transparency = 0
    gorillaPart.CanCollide = false
    gorillaPart.Anchored = false
    gorillaPart.Massless = true
    gorillaPart.CFrame = rootPart.CFrame * CFrame.new(0, -1, 0) -- Смещаем чуть вниз (под ноги)

    -- Создаем Mesh (саму модельку)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = MESH_ID
    mesh.TextureId = TEXTURE_ID
    -- Сделали немного меньше по просьбе (0.022 вместо 0.03)
    mesh.Scale = Vector3.new(0.022, 0.022, 0.022) 
    mesh.Parent = gorillaPart

    -- Скрепляем с телом игрока с помощью обычного Weld (чтобы можно было анимировать C0)
    local weld = Instance.new("Weld")
    weld.Name = "GorillaWeld"
    weld.Part0 = rootPart
    weld.Part1 = gorillaPart
    weld.C0 = CFrame.new(0, -1, 0) -- Базовое смещение вниз
    weld.Parent = gorillaPart

    gorillaPart.Parent = character
end

local function RemoveGorilla(character)
    if not character then return end
    
    local gorillaPart = character:FindFirstChild("GorillaChamsPart")
    if gorillaPart then gorillaPart:Destroy() end

    -- Возвращаем видимость телу
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = 0 end
        end
    end
end

local function ProcessPlayers()
    local timeSec = tick()
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if States.Visuals.GorillaMode then
                ApplyGorilla(player.Character)
                
                -- Анимация
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local gorillaPart = player.Character:FindFirstChild("GorillaChamsPart")
                if root and humanoid and gorillaPart then
                    local weld = gorillaPart:FindFirstChild("GorillaWeld")
                    if weld then
                        local velocity = root.AssemblyLinearVelocity
                        local horizSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                        local vertSpeed = velocity.Y
                        local turnSpeed = root.AssemblyAngularVelocity.Y
                        
                        -- Базовое смещение (немного ниже, чтобы ноги стояли на земле при новом размере)
                        local baseC0 = CFrame.new(0, -1.2, 0)
                        
                        if humanoid.FloorMaterial == Enum.Material.Air then
                            -- Анимация в воздухе (прыжок / падение)
                            -- При падении наклоняемся вперед, при взлете назад
                            local fallTiltX = math.clamp(-vertSpeed / 50, -0.6, 0.6)
                            weld.C0 = baseC0 * CFrame.Angles(fallTiltX, 0, 0)
                        elseif horizSpeed > 1 then
                            -- Детальная анимация бега
                            local speedMult = math.clamp(horizSpeed / 16, 0.5, 2.5)
                            local cycle = timeSec * 15 * speedMult
                            
                            local bounceY = math.abs(math.sin(cycle)) * 0.6
                            local swayX = math.sin(cycle / 2) * 0.3 -- Переваливание влево-вправо
                            local leanForward = -0.3 * speedMult -- Наклон тела вперед при разгоне
                            local turnLean = math.clamp(-turnSpeed * 0.1, -0.5, 0.5) -- Наклон в сторону при повороте
                            
                            weld.C0 = baseC0 * CFrame.new(swayX * 0.5, bounceY, 0) * CFrame.Angles(leanForward, swayX, turnLean)
                        else
                            -- Детальная анимация простоя (Idle)
                            local breathe = math.sin(timeSec * 3) * 0.05
                            local lookAround = math.sin(timeSec * 0.5) * 0.15 -- Плавное вращение туловища
                            
                            weld.C0 = baseC0 * CFrame.new(0, breathe, 0) * CFrame.Angles(0, lookAround, 0)
                        end
                    end
                end
            else
                RemoveGorilla(player.Character)
            end
        end
    end
end

function Mega.Features.GorillaChams.SetEnabled(state)
    States.Visuals.GorillaMode = state
    CleanupConnections()
    
    if state then
        -- Обновляем с высокой частотой для плавной анимации
        connections.GorillaLoop = Services.RunService.Heartbeat:Connect(function()
            if not States.Visuals.GorillaMode then return end
            ProcessPlayers()
        end)
    else
        -- Возвращаем всё как было
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                RemoveGorilla(player.Character)
            end
        end
    end
end

return Mega.Features.GorillaChams
