-- features/alchemist.lua
-- Alchemist Kit Helper: Auto-collects ingredients and displays ESP

if not Mega.Features then Mega.Features = {} end
Mega.Features.Alchemist = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.Alchemist then
    States.Misc.Alchemist = { Enabled = false, AutoCollect = true, ESP = true }
end

local INGREDIENTS = {
    ["wild_flower"] = { name = "🌸 ЦВЕТОК", color = Color3.fromRGB(255, 255, 0) },
    ["mushrooms"]   = { name = "🍄 ГРИБ", color = Color3.fromRGB(255, 50, 50) },
    ["thorns"]      = { name = "🌿 ШИПЫ", color = Color3.fromRGB(150, 75, 0) }
}

local netManaged
task.spawn(function()
    pcall(function()
        netManaged = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
    end)
end)

local espObjects = {}

local function clearESP()
    for obj, esp in pairs(espObjects) do
        if esp then esp:Destroy() end
    end
    table.clear(espObjects)
end

local function createESP(item, data)
    if espObjects[item] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AlchemistESP"
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = data.name
    text.TextColor3 = data.color
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    
    local container = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui
    billboard.Parent = container
    billboard.Adornee = item
    
    espObjects[item] = billboard
    
    item.AncestryChanged:Connect(function()
        if not item:IsDescendantOf(workspace) then
            if espObjects[item] then
                espObjects[item]:Destroy()
                espObjects[item] = nil
            end
        end
    end)
end

local alchemistActive = false

function Mega.Features.Alchemist.SetEnabled(state)
    States.Misc.Alchemist.Enabled = state
    
    if not state then
        clearESP()
        alchemistActive = false
        return
    end
    
    if state and not alchemistActive then
        alchemistActive = true
        task.spawn(function()
            while States.Misc.Alchemist.Enabled do
                task.wait(0.15)
                if Mega.Unloaded then break end
                
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                local dropsFolder = Services.Workspace:FindFirstChild("ItemDrops")
                local mapFolder = Services.Workspace:FindFirstChild("Map")
                
                local searchFolders = { Services.Workspace }
                if dropsFolder then table.insert(searchFolders, dropsFolder) end
                if mapFolder then table.insert(searchFolders, mapFolder) end
                
                for obj, esp in pairs(espObjects) do
                    if not obj or not obj.Parent then
                        if esp then esp:Destroy() end
                        espObjects[obj] = nil
                    end
                end

                for _, folder in ipairs(searchFolders) do
                    for _, obj in ipairs(folder:GetChildren()) do
                        local ingData = INGREDIENTS[obj.Name]
                        
                        if ingData and (obj:IsA("Model") or obj:IsA("BasePart")) then
                            if States.Misc.Alchemist.ESP then
                                createESP(obj, ingData)
                            else
                                clearESP()
                            end
                            
                            if States.Misc.Alchemist.AutoCollect and hrp and netManaged then
                                local dropPos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                                local dist = (hrp.Position - dropPos).Magnitude
                                
                                if dist <= 14.5 then
                                    local pickupRemote = netManaged:FindFirstChild("PickupItemDrop")
                                    local collectRemote = netManaged:FindFirstChild("CollectCollectableEntity")
                                    
                                    if pickupRemote then
                                        task.spawn(function() pcall(function() 
                                            if pickupRemote:IsA("RemoteEvent") then pickupRemote:FireServer({itemDrop = obj}) else pickupRemote:InvokeServer({itemDrop = obj}) end
                                            if pickupRemote:IsA("RemoteEvent") then pickupRemote:FireServer(obj) else pickupRemote:InvokeServer(obj) end
                                        end) end)
                                    end
                                    if collectRemote then
                                        task.spawn(function() pcall(function() 
                                            if collectRemote:IsA("RemoteEvent") then collectRemote:FireServer({ entity = obj }) else collectRemote:InvokeServer({ entity = obj }) end
                                            if collectRemote:IsA("RemoteEvent") then collectRemote:FireServer(obj) else collectRemote:InvokeServer(obj) end
                                        end) end)
                                    end
                                    
                                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                                    if prompt and fireproximityprompt then
                                        pcall(function() fireproximityprompt(prompt) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            clearESP()
            alchemistActive = false
        end)
    end
end