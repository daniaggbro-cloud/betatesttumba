-- features/anti_void.lua
-- Logic for Anti-Void with Auto-Calc

if not Mega.Features then Mega.Features = {} end
Mega.Features.AntiVoid = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CollectionService = game:GetService("CollectionService"),
    Workspace = game:GetService("Workspace")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if not States.Player.AntiVoid then
    States.Player.AntiVoid = { Enabled = false, AutoCalc = true, AutoCalcOffset = 9, YLevel = 20, ESP = false, ESPTransparency = 0.5 }
else
    if States.Player.AntiVoid.AutoCalc == nil then States.Player.AntiVoid.AutoCalc = true end
    if States.Player.AntiVoid.AutoCalcOffset == nil then States.Player.AntiVoid.AutoCalcOffset = 9 end
end

if not Mega.Objects.AntiVoidConnections then Mega.Objects.AntiVoidConnections = {} end
local connections = Mega.Objects.AntiVoidConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local espPart = nil
local lastCalc = 0

function Mega.Features.AntiVoid.UpdateESP()
    if States.Player.AntiVoid.Enabled and States.Player.AntiVoid.ESP then
        if not espPart then
            espPart = Instance.new("Part")
            espPart.Name = "AntiVoidESP"
            espPart.Anchored = true
            espPart.CanCollide = false
            espPart.Size = Vector3.new(2000, 1, 2000)
            espPart.Color = Color3.fromRGB(255, 50, 50)
            espPart.Material = Enum.Material.ForceField
            espPart.Parent = Services.Workspace
        end
        espPart.Transparency = States.Player.AntiVoid.ESPTransparency
        espPart.Position = Vector3.new(0, States.Player.AntiVoid.YLevel, 0)
    else
        if espPart then
            espPart:Destroy()
            espPart = nil
        end
    end
end

function Mega.Features.AntiVoid.SetAutoCalc(state)
    States.Player.AntiVoid.AutoCalc = state
    if state then lastCalc = 0 end -- Сбрасываем таймер для мгновенного расчета при включении
end

function Mega.Features.AntiVoid.SetEnabled(state)
    States.Player.AntiVoid.Enabled = state
    
    if state then
        connections.AntiVoidLoop = Services.RunService.Heartbeat:Connect(function()
            if not States.Player.AntiVoid.Enabled then return end
            
            -- Авто-расчет уровня по кроватям (раз в 2 секунды)
            if States.Player.AntiVoid.AutoCalc and tick() - lastCalc > 2 then
                lastCalc = tick()
                local bedY = nil
                
                -- Метод 1: Поиск по тегу
                local beds = Services.CollectionService:GetTagged("bed")
                for _, b in ipairs(beds) do
                    if b:IsA("BasePart") then bedY = b.Position.Y break end
                    if b:IsA("Model") and b.PrimaryPart then bedY = b.PrimaryPart.Position.Y break end
                end
                
                -- Метод 2: Прямой поиск в папке блоков (если тега нет)
                if not bedY then
                    local blocksFolder = Services.Workspace:FindFirstChild("Map") and Services.Workspace.Map:FindFirstChild("Blocks") or Services.Workspace:FindFirstChild("Blocks")
                    if blocksFolder then
                        for _, obj in pairs(blocksFolder:GetChildren()) do
                            if obj.Name:lower():find("bed") then
                                if obj:IsA("Model") and obj.PrimaryPart then
                                    bedY = obj.PrimaryPart.Position.Y
                                    break
                                elseif obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then
                                    bedY = obj:FindFirstChildWhichIsA("BasePart").Position.Y
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Обновляем уровень, отступая заданное количество стадов от кровати
                if bedY then
                    local offset = States.Player.AntiVoid.AutoCalcOffset or 9
                    local newY = math.floor(bedY - offset)
                    if States.Player.AntiVoid.YLevel ~= newY then
                        States.Player.AntiVoid.YLevel = newY
                        
                        -- Визуально обновляем ползунок в интерфейсе
                        local gui = Mega.Objects.GUI
                        if gui then
                            local slider = gui:FindFirstChild("slider_antivoid_ylevelSlider", true)
                            if slider then
                                local label = slider:FindFirstChild("Label")
                                local track = slider:FindFirstChild("Track")
                                if label and track then
                                    local fill = track:FindFirstChild("Fill")
                                    local btn = track:FindFirstChild("Button")
                                    local ratio = math.clamp((newY - (-100)) / (100 - (-100)), 0, 1)
                                    if fill then fill.Size = UDim2.new(ratio, 0, 1, 0) end
                                    if btn then btn.Position = UDim2.new(ratio, -8, 0.5, -8) end
                                    
                                    local baseText = label.Text:match("^(.-):")
                                    if baseText then label.Text = baseText .. ": " .. tostring(newY) end
                                end
                            end
                        end
                    end
                end
            end

            Mega.Features.AntiVoid.UpdateESP()

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if hrp.Position.Y <= States.Player.AntiVoid.YLevel then
                local bv = hrp:FindFirstChild("AntiVoidBV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "AntiVoidBV"
                    bv.MaxForce = Vector3.new(0, 9e9, 0)
                    bv.Velocity = Vector3.new(0, 75, 0) -- Прыжок обратно наверх
                    bv.Parent = hrp
                end
            else
                local bv = hrp:FindFirstChild("AntiVoidBV")
                if bv then
                    bv:Destroy()
                end
            end
        end)
    else
        if connections.AntiVoidLoop then
            connections.AntiVoidLoop:Disconnect()
            connections.AntiVoidLoop = nil
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:FindFirstChild("AntiVoidBV") then
            hrp.AntiVoidBV:Destroy()
        end
        Mega.Features.AntiVoid.UpdateESP()
    end
end

if States.Player.AntiVoid.Enabled then
    Mega.Features.AntiVoid.SetEnabled(true)
end
