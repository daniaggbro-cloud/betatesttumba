-- features/stella_star_collector.lua
-- Logic for Stella (Star Collector)

if not Mega.Features then Mega.Features = {} end
Mega.Features.StarCollector = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if States.StarCollector == nil then
    States.StarCollector = { Enabled = false, Range = 60, ESP = false, AutoCollect = false }
elseif States.StarCollector.AutoCollect == nil then
    States.StarCollector.AutoCollect = false
end

if not Mega.Objects.StarConnections then Mega.Objects.StarConnections = {} end
local connections = Mega.Objects.StarConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local espConnections = {}

-- Remote
local CollectStarRemote
task.spawn(function()
    pcall(function()
        CollectStarRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CollectCollectableEntity")
    end)
end)

-- ESP Setup
local espFolder = Services.CoreGui:FindFirstChild("StarCollectorESP")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "StarCollectorESP"
    espFolder.Parent = Services.CoreGui
end

local ICONS = {
    ["CritStar"] = "rbxassetid://9866757805",
    ["VitalityStar"] = "rbxassetid://9866757969"
}
local espCache = {}

local function ClearESP()
    for _, conn in pairs(espConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(espConnections)
    espFolder:ClearAllChildren()
    table.clear(espCache)
end

local function CreateOrbESP(model)
    if not model or not model.PrimaryPart then return end
    if espCache[model] then return end
    local icon = ICONS[model.Name]
    if not icon then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = model.PrimaryPart
    billboard.Size = UDim2.fromOffset(32, 32)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromScale(1, 1)
    img.BackgroundTransparency = 0.5
    img.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    img.Image = icon
    img.Parent = billboard
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 4)
    
    local conn = model.AncestryChanged:Connect(function(_, parent)
        if not parent then billboard:Destroy() end
    end)
    
    espCache[model] = billboard
    billboard.Destroying:Connect(function() 
        conn:Disconnect() 
        espCache[model] = nil
    end)
end

local function EnableESP()
    ClearESP()
    if not States.StarCollector.Enabled or not States.StarCollector.ESP then return end

    local function check(v)
        if v:IsA("Model") and (v.Name == "CritStar" or v.Name == "VitalityStar") then
            CreateOrbESP(v)
        end
    end

    table.insert(espConnections, Services.Workspace.ChildAdded:Connect(check))
    for _, v in ipairs(Services.Workspace:GetChildren()) do
        check(v)
    end
end

-- Auto Collect Loop
local lastStarCheck = 0
connections.AutoCollectLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.StarCollector.Enabled or not States.StarCollector.AutoCollect then return end
    if not CollectStarRemote then return end
    
    if tick() - lastStarCheck < 0.1 then return end
    lastStarCheck = tick()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local stars = Services.CollectionService:GetTagged("stars")
    for _, star in ipairs(stars) do
        if star:IsA("Model") and star.PrimaryPart then
            local distance = (root.Position - star.PrimaryPart.Position).Magnitude
            
            if distance <= States.StarCollector.Range then
                local starId = star:GetAttribute("Id")
                if starId then
                    local args = { { id = starId, collectableName = star.Name } }
                    task.spawn(function()
                        pcall(function()
                            CollectStarRemote:FireServer(unpack(args))
                        end)
                    end)
                end
            end
        end
    end
end)

-- Public API
function Mega.Features.StarCollector.SetEnabled(state)
    States.StarCollector.Enabled = state
    EnableESP()
end

function Mega.Features.StarCollector.UpdateESP()
    EnableESP()
end

-- Initialize if enabled on startup
if States.StarCollector.Enabled then
    Mega.Features.StarCollector.SetEnabled(true)
end
