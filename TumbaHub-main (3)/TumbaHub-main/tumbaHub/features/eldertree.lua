-- features/eldertree.lua
-- Logic for Eldertree (Tree Orbs collection and ESP)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Eldertree = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что новая настройка существует, и установим значение по умолчанию
if States.Eldertree.AutoCollect == nil then
    States.Eldertree.AutoCollect = false
end

-- Ensure connection container exists
if not Mega.Objects.EldertreeConnections then Mega.Objects.EldertreeConnections = {} end
local connections = Mega.Objects.EldertreeConnections

-- Очищаем старые коннекты, если скрипт перезапускается
if connections.ESPLoop then connections.ESPLoop:Disconnect() end
if connections.AutoCollectLoop then connections.AutoCollectLoop:Disconnect() end
if connections.ESPAdded then connections.ESPAdded:Disconnect() end
table.clear(connections)

-- Remote
local ConsumeTreeOrbRemote
task.spawn(function()
    pcall(function()
        ConsumeTreeOrbRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("ConsumeTreeOrb")
    end)
    if not ConsumeTreeOrbRemote then
        warn("TumbaHub: ConsumeTreeOrbRemote not found! Eldertree AutoCollect will not work.")
    end
end)

-- ESP Setup
local espFolder = Services.CoreGui:FindFirstChild("EldertreeESP")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "EldertreeESP"
    espFolder.Parent = Services.CoreGui
end

local ORB_ICON = "rbxassetid://11003449842"

local espCache = {}
local function ClearESP()
    if connections.ESPAdded then connections.ESPAdded:Disconnect() end
    connections.ESPAdded = nil
    espFolder:ClearAllChildren()
    table.clear(espCache)
end

local function CreateOrbESP(orb)
    if not orb then return end
    local part = orb:IsA("Model") and (orb.PrimaryPart or orb:FindFirstChildWhichIsA("BasePart")) or (orb:IsA("BasePart") and orb or nil)
    if not part then return end
    if espCache[orb] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(32, 32)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromScale(1, 1)
    img.BackgroundTransparency = 0.5
    img.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    img.Image = ORB_ICON
    img.Parent = billboard
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 4)
    
    local conn = orb.AncestryChanged:Connect(function(_, parent)
        if not parent then billboard:Destroy() end
    end)
    
    espCache[orb] = billboard
    billboard.Destroying:Connect(function() 
        conn:Disconnect() 
        espCache[orb] = nil
    end)
end

local lastEspState = false

-- 1. Отдельный цикл для контроля ESP
connections.ESPLoop = Services.RunService.Heartbeat:Connect(function()
    local currentEspState = States.Eldertree.Enabled and States.Eldertree.ESP
    if currentEspState ~= lastEspState then
        lastEspState = currentEspState
        ClearESP()
        if currentEspState then
            connections.ESPAdded = Services.CollectionService:GetInstanceAddedSignal("treeOrb"):Connect(function(orb)
                if States.Eldertree.Enabled and States.Eldertree.ESP then CreateOrbESP(orb) end
            end)
            for _, orb in ipairs(Services.CollectionService:GetTagged("treeOrb")) do
                CreateOrbESP(orb)
            end
        end
    end
end)

-- 2. Отдельная логика вкл/выкл Авто-сбора
local lastCheck = 0
connections.AutoCollectLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Eldertree.Enabled or not States.Eldertree.AutoCollect or not ConsumeTreeOrbRemote then return end
    
    if tick() - lastCheck < 0.1 then return end
    lastCheck = tick()
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, orb in ipairs(Services.CollectionService:GetTagged("treeOrb")) do
        local part = orb:IsA("Model") and (orb.PrimaryPart or orb:FindFirstChildWhichIsA("BasePart")) or (orb:IsA("BasePart") and orb or nil)
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist <= States.Eldertree.Range then
                local secret = orb:GetAttribute("TreeOrbSecret")
                if secret then
                    local args = { { treeOrbSecret = secret } }
                    task.spawn(function()
                        pcall(function() if ConsumeTreeOrbRemote then ConsumeTreeOrbRemote:InvokeServer(unpack(args)) end end)
                    end)
                end
            end
        end
    end
end)

-- Оставляем эти функции для обратной совместимости, чтобы ничего не сломалось
-- если другие скрипты попытаются их вызвать, но логика уже обрабатывается автономно
function Mega.Features.Eldertree.SetEnabled(state)
    States.Eldertree.Enabled = state
end

function Mega.Features.Eldertree.UpdateESP()
    -- Пусто, так как ESPLoop автоматически обнаружит изменение States.Eldertree.ESP
end

function Mega.Features.Eldertree.SetAutoCollect(state)
    States.Eldertree.AutoCollect = state
end
