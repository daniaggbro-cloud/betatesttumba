-- features/lucia.lua
-- Logic for Lucia (Pinata) Auto Deposit

if not Mega.Features then Mega.Features = {} end
Mega.Features.Lucia = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    CollectionService = game:GetService("CollectionService"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if States.Lucia == nil then
    States.Lucia = { Enabled = false, ESP = false, AutoDeposit = false, Range = 20, Legit = false }
elseif States.Lucia.Range == nil then
    States.Lucia.Range = 20
end
if States.Lucia.Legit == nil then
    States.Lucia.Legit = false
end
if States.Lucia.ESP == nil then
    States.Lucia.ESP = false
end

if not Mega.Objects.LuciaConnections then Mega.Objects.LuciaConnections = {} end
local connections = Mega.Objects.LuciaConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local DepositPinataRemote = Mega.GetRemote("DepositPinata")
task.spawn(function()
    while task.wait(5) do
        if not DepositPinataRemote then
            DepositPinataRemote = Mega.GetRemote("DepositPinata")
        end
    end
end)

local espFolder = Services.CoreGui:FindFirstChild("LuciaESP")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "LuciaESP"
    espFolder.Parent = Services.CoreGui
end

local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}

local function getCandyCount()
    local count = 0
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories")
    if inv then
        local pInv = inv:FindFirstChild(LocalPlayer.Name)
        if pInv then
            for _, v in ipairs(pInv:GetChildren()) do
                if v.Name == "candy" then
                    count = count + (v:GetAttribute("Amount") or 1)
                end
            end
        end
    end
    return count
end

local function getPinatas()
    local pinatas = Services.CollectionService:GetTagged("piggy-bank")
    if #pinatas == 0 then
        local blocksFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Blocks") or workspace:FindFirstChild("Blocks")
        if blocksFolder then
            for _, obj in ipairs(blocksFolder:GetChildren()) do
                if obj.Name:lower():find("pinata") or obj.Name:lower():find("piggy") then
                    table.insert(pinatas, obj)
                end
            end
        end
    end
    return pinatas
end

local lastCheck = 0
connections.AutoDepositLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Lucia.Enabled then 
        espFolder:ClearAllChildren()
        for _, pinata in ipairs(getPinatas()) do
            local hl = pinata:FindFirstChild("LuciaHighlight")
            if hl then hl:Destroy() end
        end
        return 
    end
    
    -- Логика ESP Пиньяты
    local activePinatas = {}
    local pinatas = getPinatas()
    for _, pinata in ipairs(pinatas) do
        local pinataPart = pinata:IsA("BasePart") and pinata or pinata.PrimaryPart or pinata:FindFirstChildWhichIsA("BasePart", true)
        if pinataPart then
            if States.Lucia.ESP then
                activePinatas[pinataPart] = true
                local hl = pinata:FindFirstChild("LuciaHighlight")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "LuciaHighlight"
                    hl.FillColor = Color3.fromRGB(255, 100, 200)
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.Parent = pinata
                end
                
                local espName = "ESP_" .. pinata:GetDebugId()
                if not espFolder:FindFirstChild(espName) then
                    local b = Instance.new("BillboardGui")
                    b.Name = espName
                    b.Adornee = pinataPart
                    b.Size = UDim2.new(0, 100, 0, 30)
                    b.StudsOffset = Vector3.new(0, 3, 0)
                    b.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel", b)
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.Text = "Piñata"
                    txt.TextColor3 = Color3.fromRGB(255, 100, 200)
                    txt.Font = Enum.Font.GothamBold
                    txt.TextStrokeTransparency = 0
                    b.Parent = espFolder
                end
            else
                local hl = pinata:FindFirstChild("LuciaHighlight")
                if hl then hl:Destroy() end
            end
        end
    end
    
    -- Очистка старого ESP
    for _, child in ipairs(espFolder:GetChildren()) do
        if child:IsA("BillboardGui") and child.Adornee then
            if not activePinatas[child.Adornee] then
                child:Destroy()
            end
        else
            child:Destroy()
        end
    end

    if not States.Lucia.AutoDeposit then return end
    
    if tick() - lastCheck < 0.5 then return end
    lastCheck = tick()
    
    if getCandyCount() == 0 then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, pinata in ipairs(pinatas) do
        local pinataPart = pinata:IsA("BasePart") and pinata or pinata.PrimaryPart or pinata:FindFirstChildWhichIsA("BasePart", true)
        if pinataPart then
            local dist = (root.Position - pinataPart.Position).Magnitude
            local targetRange = States.Lucia.Legit and States.Lucia.Range or math.huge
            
            if dist <= targetRange then
                
                if States.Lucia.Legit then
                    -- 1. Метод через ProximityPrompt (Легитный)
                    local prompt = pinata:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            task.spawn(function()
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration or 0)
                                    prompt:InputHoldEnd()
                                end)
                            end)
                        end
                        return 
                    end
                end

                -- 2. Метод через Ремоут (Уязвимость сервера BedWars - дистанция не проверяется)
                if DepositPinataRemote then
                    task.spawn(function()
                        pcall(function()
                            if DepositPinataRemote:IsA("RemoteEvent") then
                                DepositPinataRemote:FireServer(pinata)
                            elseif DepositPinataRemote:IsA("RemoteFunction") then
                                DepositPinataRemote:InvokeServer(pinata)
                            end
                        end)
                        -- Дублирующие аргументы на случай других проверок
                        local possibleArgs = {
                            { ["piggyBank"] = pinata },
                            {}
                        }
                        for _, arg in ipairs(possibleArgs) do
                            pcall(function()
                                if DepositPinataRemote:IsA("RemoteEvent") then
                                    DepositPinataRemote:FireServer(arg)
                                elseif DepositPinataRemote:IsA("RemoteFunction") then
                                    DepositPinataRemote:InvokeServer(arg)
                                end
                            end)
                        end
                    end)
                end
            end
        end
    end
end)

function Mega.Features.Lucia.SetEnabled(state)
    States.Lucia.Enabled = state
    if not state then 
        if espFolder then espFolder:ClearAllChildren() end 
        for _, pinata in ipairs(getPinatas()) do
            local hl = pinata:FindFirstChild("LuciaHighlight")
            if hl then hl:Destroy() end
        end
    end
end