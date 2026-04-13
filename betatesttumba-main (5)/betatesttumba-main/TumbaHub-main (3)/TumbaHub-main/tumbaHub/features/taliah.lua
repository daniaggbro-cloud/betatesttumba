-- features/taliah.lua
-- Logic for Taliah kit (Chickens ESP and Auto Collect)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Taliah = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что настройки существуют (fallback)
if States.Taliah == nil then
    States.Taliah = {
        Enabled = false,
        ESP = false,
        ESPTransparency = 0.2,
        AutoCollect = false,
        AutoCollectLegit = false,
        CollectRadius = 5
    }
elseif States.Taliah.AutoCollectLegit == nil then
    States.Taliah.AutoCollectLegit = false
end

if not Mega.Objects.TaliahConnections then Mega.Objects.TaliahConnections = {} end
local connections = Mega.Objects.TaliahConnections

-- Очистка старых соединений на случай перезапуска
for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then
        conn:Disconnect()
    end
end
table.clear(connections)

-- Remote
local CropHarvestRemote
task.spawn(function()
    pcall(function()
        CropHarvestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CropHarvest")
    end)
end)

local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}

local function UpdateChickenESP()
    for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
        if block.Name == "chicken_egg_block" then
            local stage = block:GetAttribute("CropStage")
            
            -- Находим визуальную цель (stage_4 или сам блок)
            local target = block:FindFirstChild("stage_4") or block
            
            -- Принудительная видимость для stage_4
            if target.Name == "stage_4" then
                local targetTransparency = (States.Taliah.Enabled and States.Taliah.ESP) and 0 or 1
                if target:IsA("BasePart") then
                    target.Transparency = targetTransparency
                elseif target:IsA("Model") then
                    for _, v in ipairs(target:GetDescendants()) do
                        if v:IsA("BasePart") then v.Transparency = targetTransparency end
                    end
                end
            end

            if target ~= block then
                local oldEsp = block:FindFirstChild("TaliahESP")
                if oldEsp then oldEsp:Destroy() end
            end
            
            local esp = target:FindFirstChild("TaliahESP")
            
            if States.Taliah.Enabled and States.Taliah.ESP and stage == 4 then
                if not esp then
                    esp = Instance.new("Highlight")
                    esp.Name = "TaliahESP"
                    esp.FillColor = Color3.fromRGB(255, 170, 0) -- Оранжевый
                    esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                    esp.FillTransparency = States.Taliah.ESPTransparency
                    esp.OutlineTransparency = 0
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                else
                    -- Обновляем свойства, если уже существует
                    esp.FillTransparency = States.Taliah.ESPTransparency
                    esp.FillColor = Color3.fromRGB(255, 170, 0)
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                end
            else
                if esp then esp:Destroy() end
                -- Очищаем возможные остатки, если цель сменилась
                local leftover = block:FindFirstChild("TaliahESP")
                if leftover then leftover:Destroy() end
            end
        end
    end
end

-- Подключаем события для обновления ESP при спавне новых куриц или изменении стадии
local function OnCropAdded(block)
    if block.Name == "chicken_egg_block" then
        local conn = block:GetAttributeChangedSignal("CropStage"):Connect(function()
            UpdateChickenESP()
        end)
        table.insert(connections, conn)
        UpdateChickenESP()
    end
end

connections.TaliahAdded = Services.CollectionService:GetInstanceAddedSignal("HarvestableCrop"):Connect(OnCropAdded)

for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
    OnCropAdded(block)
end

-- Автономный наблюдатель за изменениями состояния UI
local lastEspState = false
local lastEspTrans = States.Taliah.ESPTransparency

connections.StateWatcher = Services.RunService.Heartbeat:Connect(function()
    local currentEspState = States.Taliah.Enabled and States.Taliah.ESP
    local currentTrans = States.Taliah.ESPTransparency
    
    if currentEspState ~= lastEspState or currentTrans ~= lastEspTrans then
        lastEspState = currentEspState
        lastEspTrans = currentTrans
        UpdateChickenESP()
    end
end)

-- Автономный цикл сбора
local lastTaliahCheck = 0
connections.AutoCollectLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Taliah.Enabled or (not States.Taliah.AutoCollect and not States.Taliah.AutoCollectLegit) then return end
    
    -- Небольшой троттлинг для производительности
    if tick() - lastTaliahCheck < 0.1 then return end
    lastTaliahCheck = tick()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
        if block.Name == "chicken_egg_block" then
            local stage = block:GetAttribute("CropStage")
            if stage == 4 then
                local dist = (block.Position - root.Position).Magnitude
                if dist <= States.Taliah.CollectRadius then
                    if States.Taliah.AutoCollect then
                        -- Быстрый сбор как у Cletus
                        if CropHarvestRemote then
                            local blockPos = Vector3.new(math.round(block.Position.X / 3), math.round(block.Position.Y / 3), math.round(block.Position.Z / 3))
                            local args = {{ ["position"] = vector.create(blockPos.X, blockPos.Y, blockPos.Z) }}
                            task.spawn(function()
                                pcall(function() CropHarvestRemote:InvokeServer(unpack(args)) end)
                            end)
                        end
                    elseif States.Taliah.AutoCollectLegit then
                        -- Сбор через ProximityPrompt (Legit)
                        local prompt = block:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                task.spawn(function()
                                    pcall(function()
                                        prompt:InputHoldBegin()
                                        task.wait(prompt.HoldDuration)
                                        prompt:InputHoldEnd()
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Пустые функции для обратной совместимости, чтобы UI не выдавал ошибку,
-- если он попытается их вызвать. Вся логика теперь автономна.
function Mega.Features.Taliah.SetEnabled(state)
    States.Taliah.Enabled = state
end

function Mega.Features.Taliah.UpdateESP()
end
