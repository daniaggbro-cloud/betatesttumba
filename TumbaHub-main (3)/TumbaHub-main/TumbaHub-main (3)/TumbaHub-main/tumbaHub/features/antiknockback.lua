-- features/antiknockback.lua
-- Logic for Anti-Knockback

if not Mega.Features then Mega.Features = {} end
Mega.Features.AntiKnockback = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.AntiKnockback == nil then States.Player.AntiKnockback = false end
if States.Player.KnockbackStrength == nil then States.Player.KnockbackStrength = 0 end

if not Mega.Objects.AntiKnockbackConnections then Mega.Objects.AntiKnockbackConnections = {} end
local connections = Mega.Objects.AntiKnockbackConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- 1. Специфичный хук для BedWars (внедряемся в контроллеры из дампа)
task.spawn(function()
    local function hookKnockback(modulePath, controllerName)
        pcall(function()
            local knockbackModule = require(modulePath)
            if knockbackModule then
                local controller = knockbackModule[controllerName] or knockbackModule.default
                if controller then
                    for _, methodName in ipairs({"applyKnockback", "ApplyKnockback"}) do
                        if type(controller[methodName]) == "function" then
                            local original = controller[methodName]
                            controller[methodName] = function(self, dir, multiplier, ...)
                                if States.Player.AntiKnockback then
                                    local strength = States.Player.KnockbackStrength / 100
                                    if strength == 0 then return end
                                    return original(self, dir, multiplier * strength, ...)
                                end
                                return original(self, dir, multiplier, ...)
                            end
                        end
                    end
                end
            end
        end)
    end
    
    -- Хукаем боевой контроллер и контроллер сущностей
    if Services.ReplicatedStorage:FindFirstChild("TS") then
        if Services.ReplicatedStorage.TS:FindFirstChild("combat") and Services.ReplicatedStorage.TS.combat:FindFirstChild("knockback-controller") then
            hookKnockback(Services.ReplicatedStorage.TS.combat["knockback-controller"], "KnockbackController")
        end
        if Services.ReplicatedStorage.TS:FindFirstChild("stateful-entity") and Services.ReplicatedStorage.TS["stateful-entity"]:FindFirstChild("stateful-entity-knockback-controller") then
            hookKnockback(Services.ReplicatedStorage.TS["stateful-entity"]["stateful-entity-knockback-controller"], "StatefulEntityKnockbackController")
        end
    end
end)

-- 2. Универсальный физический фикс (Stepped lock)
local function PhysicsAntiKB()
    if not States.Player.AntiKnockback then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    -- Удаляем любые объекты, создающие векторную тягу отдачи
    for _, obj in pairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") or obj:IsA("LinearVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyPosition") or obj:IsA("VectorForce") or obj:IsA("AlignPosition") then
            local name = obj.Name
            if name ~= "VapeFlyVelocity" and name ~= "VapeFlyGyro" and name ~= "AntiVoidBV" and name ~= "BedNukeBypass" and name ~= "NoFallVelocity" then
                obj:Destroy()
            end
        end
    end

    -- Гасим кинетическую инерцию от ApplyImpulse и подобных методов
    local currentVel = hrp.AssemblyLinearVelocity
    local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z)
    local walkSpeed = hum.WalkSpeed
    
    if horizontalVel.Magnitude > walkSpeed + 1 then
        local strengthMultiplier = States.Player.KnockbackStrength / 100
        local targetDir = hum.MoveDirection * walkSpeed
        
        -- Lerp плавно притягивает скорость к той, что мы задаем кнопками
        local newHorizontal = horizontalVel:Lerp(targetDir, 1 - strengthMultiplier)
        hrp.AssemblyLinearVelocity = Vector3.new(newHorizontal.X, currentVel.Y, newHorizontal.Z)
    end
end

function Mega.Features.AntiKnockback.SetEnabled(state)
    States.Player.AntiKnockback = state
    
    if state then
        -- Stepped выполняется СТРОГО ДО симуляции физики, что исключает "микро-рывки"
        if not connections.AntiKBStepped then
            connections.AntiKBStepped = Services.RunService.Stepped:Connect(PhysicsAntiKB)
        end
        -- Heartbeat на всякий случай "добивает" остатки скорости после отрисовки кадра
        if not connections.AntiKBHeartbeat then
            connections.AntiKBHeartbeat = Services.RunService.Heartbeat:Connect(PhysicsAntiKB)
        end
    else
        if connections.AntiKBStepped then connections.AntiKBStepped:Disconnect(); connections.AntiKBStepped = nil end
        if connections.AntiKBHeartbeat then connections.AntiKBHeartbeat:Disconnect(); connections.AntiKBHeartbeat = nil end
    end
end

if States.Player.AntiKnockback then
    Mega.Features.AntiKnockback.SetEnabled(true)
end
