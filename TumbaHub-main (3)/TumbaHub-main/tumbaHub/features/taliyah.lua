-- features/Taliyah.lua
-- Logic for Taliyah kit (Chickens ESP and Auto Collect)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Taliyah = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что настройки существуют (fallback)
if States.Taliyah == nil then
    States.Taliyah = {
        Enabled = false,
        ESP = false,
        ESPTransparency = 0.2,
        AutoCollect = false,
        AutoCollectLegit = false,
        CollectRadius = 5
    }
elseif States.Taliyah.AutoCollectLegit == nil then
    States.Taliyah.AutoCollectLegit = false
end

if not Mega.Objects.TaliyahConnections then Mega.Objects.TaliyahConnections = {} end
local connections = Mega.Objects.TaliyahConnections

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
                local targetTransparency = (States.Taliyah.Enabled and States.Taliyah.ESP) and 0 or 1
                if target:IsA("BasePart") then
                    target.Transparency = targetTransparency
                elseif target:IsA("Model") then
                    for _, v in ipairs(target:GetDescendants()) do
                        if v:IsA("BasePart") then v.Transparency = targetTransparency end
                    end
                end
            end

            if target ~= block then
                local oldEsp = block:FindFirstChild("TaliyahESP")
                if oldEsp then oldEsp:Destroy() end
            end
            
            local esp = target:FindFirstChild("TaliyahESP")
            
            if States.Taliyah.Enabled and States.Taliyah.ESP and stage == 4 then
                if not esp then
                    esp = Instance.new("Highlight")
                    esp.Name = "TaliyahESP"
                    esp.FillColor = Color3.fromRGB(255, 170, 0) -- Оранжевый
                    esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                    esp.FillTransparency = States.Taliyah.ESPTransparency
                    esp.OutlineTransparency = 0
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                else
                    -- Обновляем свойства, если уже существует
                    esp.FillTransparency = States.Taliyah.ESPTransparency
                    esp.FillColor = Color3.fromRGB(255, 170, 0)
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                end
            else
                if esp then esp:Destroy() end
                -- Очищаем возможные остатки, если цель сменилась
                local leftover = block:FindFirstChild("TaliyahESP")
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

connections.TaliyahAdded = Services.CollectionService:GetInstanceAddedSignal("HarvestableCrop"):Connect(OnCropAdded)

for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
    OnCropAdded(block)
end

-- Автономный наблюдатель за изменениями состояния UI
local lastEspState = false
local lastEspTrans = States.Taliyah.ESPTransparency

connections.StateWatcher = Services.RunService.Heartbeat:Connect(function()
    local currentEspState = States.Taliyah.Enabled and States.Taliyah.ESP
    local currentTrans = States.Taliyah.ESPTransparency
    
    if currentEspState ~= lastEspState or currentTrans ~= lastEspTrans then
        lastEspState = currentEspState
        lastEspTrans = currentTrans
        UpdateChickenESP()
    end
end)

-- Автономный цикл сбора
local lastTaliyahCheck = 0
connections.AutoCollectLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Taliyah.Enabled or (not States.Taliyah.AutoCollect and not States.Taliyah.AutoCollectLegit) then return end
    
    -- Небольшой троттлинг для производительности
    if tick() - lastTaliyahCheck < 0.1 then return end
    lastTaliyahCheck = tick()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
        if block.Name == "chicken_egg_block" then
            local stage = block:GetAttribute("CropStage")
            if stage == 4 then
                local dist = (block.Position - root.Position).Magnitude
                if dist <= States.Taliyah.CollectRadius then
                    if States.Taliyah.AutoCollect then
                        -- Быстрый сбор как у Cletus
                        if CropHarvestRemote then
                            local blockPos = Vector3.new(math.round(block.Position.X / 3), math.round(block.Position.Y / 3), math.round(block.Position.Z / 3))
                            local args = {{ ["position"] = vector.create(blockPos.X, blockPos.Y, blockPos.Z) }}
                            task.spawn(function()
                                pcall(function() CropHarvestRemote:InvokeServer(unpack(args)) end)
                            end)
                        end
                    elseif States.Taliyah.AutoCollectLegit then
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
function Mega.Features.Taliyah.SetEnabled(state)
    States.Taliyah.Enabled = state
end

function Mega.Features.Taliyah.UpdateESP()
end
