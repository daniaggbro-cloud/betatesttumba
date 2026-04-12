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
    States.Misc.Alchemist = { Enabled = false, AutoCollect = true, ESP = true, ESPTransparency = 0, Range = 5 }
end

local INGREDIENTS = {
    ["flower"]      = { name = "🌸", color = Color3.fromRGB(255, 255, 0) },
    ["wild_flower"] = { name = "🌸", color = Color3.fromRGB(255, 255, 0) },
    ["mushrooms"]   = { name = "🍄", color = Color3.fromRGB(255, 50, 50) },
    ["thorns"]      = { name = "🌿", color = Color3.fromRGB(150, 75, 0) }
}

local netManaged
task.spawn(function()
    pcall(function()
        netManaged = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
    end)
end)

local espObjects = {}
local activeIngredients = {}
local descAddedConn = nil

local function checkIngredient(obj)
    if not obj then return end
    pcall(function()
        local targetObj = obj
        -- Если передан сам промпт (например, через DescendantAdded), берем его родителя
        if obj:IsA("ProximityPrompt") and obj.Name == "alchemist_ingedients_ProximityPrompt" then
            targetObj = obj.Parent
        end

        if targetObj and (targetObj:IsA("Model") or targetObj:IsA("BasePart")) then
            local name = targetObj.Name:lower()
            for key, data in pairs(INGREDIENTS) do
                if name:find(key) then
                    activeIngredients[targetObj] = data
                    return
                end
            end
            
            -- Если имя не совпало, но есть нужный промпт (fallback)
            if targetObj:FindFirstChild("alchemist_ingedients_ProximityPrompt", true) then
                local data = { name = "🧪", color = Color3.fromRGB(200, 100, 255) }
                if name:find("flower") then data = INGREDIENTS["flower"] end
                activeIngredients[targetObj] = data
            end
        end
    end)
end

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
    local trans = States.Misc.Alchemist.ESPTransparency or 0
    text.TextTransparency = trans
    text.TextStrokeTransparency = trans
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

function Mega.Features.Alchemist.UpdateVisuals()
    local trans = States.Misc.Alchemist.ESPTransparency or 0
    for obj, billboard in pairs(espObjects) do
        if billboard and billboard:FindFirstChildWhichIsA("TextLabel") then
            billboard.TextLabel.TextTransparency = trans
            billboard.TextLabel.TextStrokeTransparency = trans
        end
    end
end

local alchemistActive = false

function Mega.Features.Alchemist.SetEnabled(state)
    States.Misc.Alchemist.Enabled = state
    
    if not state then
        clearESP()
        alchemistActive = false
        if descAddedConn then descAddedConn:Disconnect(); descAddedConn = nil end
        table.clear(activeIngredients)
        return
    end
    
    if state and not alchemistActive then
        alchemistActive = true
        
        for _, obj in ipairs(Services.Workspace:GetDescendants()) do
            checkIngredient(obj)
        end
        
        descAddedConn = Services.Workspace.DescendantAdded:Connect(checkIngredient)
        
        task.spawn(function()
            while States.Misc.Alchemist.Enabled do
                task.wait(0.15)
                if Mega.Unloaded then break end
                
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                for obj, data in pairs(activeIngredients) do
                    if not obj or not obj.Parent then
                        activeIngredients[obj] = nil
                        if espObjects[obj] then
                            espObjects[obj]:Destroy()
                            espObjects[obj] = nil
                        end
                    else
                    if States.Misc.Alchemist.ESP then
                        createESP(obj, data)
                    else
                        if espObjects[obj] then
                            espObjects[obj]:Destroy()
                            espObjects[obj] = nil
                        end
                    end
                    
                    if States.Misc.Alchemist.AutoCollect and hrp then
                        local dropPos
                        pcall(function()
                            if obj:IsA("Model") then
                                dropPos = obj:GetPivot().Position
                            elseif obj:IsA("BasePart") then
                                dropPos = obj.Position
                            end
                        end)
                        
                        if dropPos then
                            local dist = (hrp.Position - dropPos).Magnitude
                            
                            if dist <= (States.Misc.Alchemist.Range or 5) then
                                task.spawn(function()
                                    pcall(function()
                                        local prompt = obj:FindFirstChild("alchemist_ingedients_ProximityPrompt", true) or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if prompt and prompt.Enabled then
                                            if fireproximityprompt then
                                                fireproximityprompt(prompt)
                                            else
                                                prompt:InputHoldBegin()
                                                task.wait(prompt.HoldDuration or 0)
                                                prompt:InputHoldEnd()
                                            end
                                        end
                                    end)
                                end)
                                
                                if netManaged then
                                    task.spawn(function()
                                        pcall(function()
                                            local pickupRemote = netManaged:FindFirstChild("PickupItemDrop")
                                            if pickupRemote then
                                                if pickupRemote:IsA("RemoteEvent") then pickupRemote:FireServer({itemDrop = obj})
                                                elseif pickupRemote:IsA("RemoteFunction") then pickupRemote:InvokeServer({itemDrop = obj}) end
                                            end
                                            
                                            local collectRemote = netManaged:FindFirstChild("CollectCollectableEntity")
                                            if collectRemote then
                                                if collectRemote:IsA("RemoteEvent") then collectRemote:FireServer({ entity = obj })
                                                elseif collectRemote:IsA("RemoteFunction") then collectRemote:InvokeServer({ entity = obj }) end
                                            end
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
                end
            end
            clearESP()
            table.clear(activeIngredients)
            if descAddedConn then descAddedConn:Disconnect(); descAddedConn = nil end
            alchemistActive = false
        end)
    end
end
