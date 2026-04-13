-- features/metal_detector.lua
-- Logic for Metal Detector (ESP and Auto Collect)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Metal = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что настройки существуют
if States.Metal == nil then
    States.Metal = { Enabled = false, ESP = true, AutoCollect = false, AutoCollectLegit = false, Range = 25 }
elseif States.Metal.AutoCollectLegit == nil then
    States.Metal.AutoCollectLegit = false
end

if not Mega.Objects.MetalConnections then Mega.Objects.MetalConnections = {} end
local connections = Mega.Objects.MetalConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- Remote
local CollectMetalRemote
task.spawn(function()
    pcall(function()
        CollectMetalRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CollectCollectableEntity")
    end)
end)

local function isShopItem(v)
    if not v then return false end
    if not v:IsDescendantOf(Services.Workspace) then return true end
    if v:FindFirstAncestorOfClass("ViewportFrame") then return true end
    
    local pg = Services.LocalPlayer:FindFirstChild("PlayerGui")
    if pg and v:IsDescendantOf(pg) then return true end
    
    local map = Services.Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Shops") and v:IsDescendantOf(map.Shops) then
        return true
    end
    
    return false
end

local function AddMetalESP(model)
    if not model:IsA("Model") or isShopItem(model) then return end
    if model:FindFirstChild("MetalESP_Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MetalESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 170, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MetalESP_Text"
    billboard.Adornee = model
    billboard.Size = UDim2.new(0, 32, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = model
    
    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = UDim2.new(1, 0, 1, 0)
    image.Image = "rbxassetid://6850537969"
    image.Parent = billboard
end

local function UpdateMetalESP()
    for _, m in ipairs(Services.CollectionService:GetTagged("hidden-metal")) do
        if States.Metal.Enabled and States.Metal.ESP and not isShopItem(m) then
            AddMetalESP(m)
        else
            if m:FindFirstChild("MetalESP_Highlight") then m.MetalESP_Highlight:Destroy() end
            if m:FindFirstChild("MetalESP_Text") then m.MetalESP_Text:Destroy() end
        end
    end
end

connections.MetalAdded = Services.CollectionService:GetInstanceAddedSignal("hidden-metal"):Connect(function(m)
    if States.Metal.Enabled and States.Metal.ESP then AddMetalESP(m) end
end)

local lastMetalCheck = 0
connections.MetalLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Metal.Enabled or (not States.Metal.AutoCollect and not States.Metal.AutoCollectLegit) then return end
    
    if tick() - lastMetalCheck < 0.1 then return end
    lastMetalCheck = tick()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local minDistance = States.Metal.Range
    
    for _, model in ipairs(Services.CollectionService:GetTagged("hidden-metal")) do
        if model:IsA("Model") then
            local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChild("Part")
            if primary then
                local dist = (root.Position - primary.Position).Magnitude
                if dist <= minDistance then
                    if States.Metal.AutoCollect and CollectMetalRemote then
                        local metalId = model:GetAttribute("Id")
                        if metalId then
                            task.spawn(function()
                                pcall(function() CollectMetalRemote:FireServer({ ["id"] = metalId }) end)
                            end)
                        end
                    elseif States.Metal.AutoCollectLegit then
                        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
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

-- Public API
function Mega.Features.Metal.SetEnabled(state)
    States.Metal.Enabled = state
    UpdateMetalESP()
end

function Mega.Features.Metal.UpdateESP()
    UpdateMetalESP()
end

-- Initialize if enabled on startup
if States.Metal.Enabled then
    Mega.Features.Metal.SetEnabled(true)
end