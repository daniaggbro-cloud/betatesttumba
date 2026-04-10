-- features/beekeeper.lua
-- All logic for the Beekeeper feature

Mega.Features.Beekeeper = {}

local Services = Mega.Services
local States = Mega.States
local BeekeeperState = States.Beekeeper

-- Ensure objects exist
if not Mega.Objects.BeeCache then Mega.Objects.BeeCache = {} end
if not Mega.Objects.Connections then Mega.Objects.Connections = {} end

local beeCache = Mega.Objects.BeeCache
local connections = Mega.Objects.Connections

-- Remote
local PickUpBeeRemote = Mega.GetRemote("BeePickup")
-- Periodically re-check the remote
task.spawn(function()
    while task.wait(5) do
        if not PickUpBeeRemote then
            PickUpBeeRemote = Mega.GetRemote("BeePickup")
        end
    end
end)


local function IsTargetBee(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local name = string.lower(obj.Name)
    if name == "tamedbee" or string.find(name, "tamed") then return false end
    if name == "bee" then return true end
    if obj:GetAttribute("BeeId") then return true end
    return false
end

local function AddHiveESP(obj)
    if not obj or not obj.Parent then return end
    if obj.Name ~= "beehive" then return end
    
    if BeekeeperState.ShowHiveLevels and BeekeeperState.Enabled then
        local tag = obj:FindFirstChild("HiveLevelTag")
        if not tag then
            tag = Instance.new("BillboardGui")
            tag.Name = "HiveLevelTag"
            tag.Adornee = obj
            tag.Parent = obj
            tag.Size = UDim2.new(0, 80, 0, 40)
            tag.StudsOffset = Vector3.new(0, 4, 0)
            tag.AlwaysOnTop = true
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Value"
            lbl.Parent = tag
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextStrokeTransparency = 0
            lbl.TextColor3 = Color3.fromRGB(0, 255, 255)
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextSize = 16
            
            local function update()
                if not obj or not obj.Parent then return end
                local level = obj:GetAttribute("Level")
                if not level then
                    local lvlObj = obj:FindFirstChild("Level")
                    if lvlObj and (lvlObj:IsA("IntValue") or lvlObj:IsA("NumberValue")) then level = lvlObj.Value end
                end
                level = level or 0
                if tag and tag:FindFirstChild("Value") then
                    tag.Value.Text = "Lvl " .. tostring(level)
                end
            end
            
            update()
            
            local conns = {}
            table.insert(conns, obj:GetAttributeChangedSignal("Level"):Connect(update))
            local lvlObj = obj:FindFirstChild("Level")
            if lvlObj then table.insert(conns, lvlObj.Changed:Connect(update)) end
            table.insert(conns, obj.ChildAdded:Connect(function(c)
                if c.Name == "Level" then
                    update()
                    table.insert(conns, c.Changed:Connect(update))
                end
            end))
            
            tag.Destroying:Connect(function()
                for _, c in ipairs(conns) do c:Disconnect() end
            end)
        end
    else
        local tag = obj:FindFirstChild("HiveLevelTag")
        if tag then tag:Destroy() end
    end
end

local function UpdateHiveESP()
    if not BeekeeperState.Enabled then return end
    
    local blocksFolder = Services.Workspace:FindFirstChild("Blocks", true) or (Services.Workspace:FindFirstChild("Map") and Services.Workspace.Map:FindFirstChild("Blocks", true))
    if blocksFolder then
        if not connections.HiveAdded then
            connections.HiveAdded = blocksFolder.ChildAdded:Connect(function(child)
                if BeekeeperState.Enabled then
                    task.delay(0.2, function() AddHiveESP(child) end)
                end
            end)
        end
        for _, obj in ipairs(blocksFolder:GetChildren()) do
            AddHiveESP(obj)
        end
    end
end

local function UpdateBeeESP(obj)
    if not obj or not obj.Parent then return end
    
    -- Clean up if disabled or not target
    if not BeekeeperState.Enabled or not IsTargetBee(obj) then
        if obj:FindFirstChild("BeeESP_Icon") then obj.BeeESP_Icon:Destroy() end
        if obj:FindFirstChild("BeeHighlight") then obj.BeeHighlight:Destroy() end
        beeCache[obj] = nil -- Удаляем из кэша
        return
    end

    local icon = obj:FindFirstChild("BeeESP_Icon")
    if not icon then
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart")
        if root then
            local bg = Instance.new("BillboardGui")
            bg.Name = "BeeESP_Icon"
            bg.Adornee = root
            bg.Parent = obj
            bg.Size = UDim2.new(0, 50, 0, 50)
            bg.StudsOffset = Vector3.new(0, 6, 0)
            bg.AlwaysOnTop = true
            local img = Instance.new("ImageLabel")
            img.Parent = bg
            img.BackgroundTransparency = 1
            img.Size = UDim2.new(1, 0, 1, 0)
            img.Image = "rbxassetid://7343272839"
            img.ImageTransparency = 0.75
            icon = bg
        end
    end
    if icon then icon.Enabled = BeekeeperState.ShowIcons end

    local hl = obj:FindFirstChild("BeeHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "BeeHighlight"
        hl.Adornee = obj
        hl.Parent = obj
        hl.FillColor = Color3.fromRGB(255, 230, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end
    if hl then hl.Enabled = BeekeeperState.ShowHighlight end

    -- Добавляем в кэш, если еще не там
    if not beeCache[obj] then
        beeCache[obj] = true
    end
end

local function ClearBeekeeperESP()
    for bee, _ in pairs(beeCache) do
        if bee and bee.Parent then
            if bee:FindFirstChild("BeeESP_Icon") then bee.BeeESP_Icon:Destroy() end
            if bee:FindFirstChild("BeeHighlight") then bee.BeeHighlight:Destroy() end
        end
    end
    table.clear(beeCache)
    -- Также очищаем ESP ульев
    pcall(function()
        local blocksFolder = Services.Workspace:FindFirstChild("Blocks", true) or (Services.Workspace:FindFirstChild("Map") and Services.Workspace.Map:FindFirstChild("Blocks", true))
        if blocksFolder then
            for _, obj in ipairs(blocksFolder:GetChildren()) do
                if obj.Name == "beehive" and obj:FindFirstChild("HiveLevelTag") then
                    obj.HiveLevelTag:Destroy()
                end
            end
        end
    end)
end

local function PopulateBeeCache()
    ClearBeekeeperESP()
    if not BeekeeperState.Enabled then return end

    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if IsTargetBee(obj) then
            UpdateBeeESP(obj)
        end
    end
    UpdateHiveESP()
    
    -- Count bees for debug print (since beeCache is a dictionary)
    local count = 0
    for _ in pairs(beeCache) do count = count + 1 end
    print("Beekeeper cache populated with " .. tostring(count) .. " bees.")
end

-- Auto Catch Loop
local lastBeeCatch = 0
local function AutoCatchLoop()
    if not BeekeeperState.Enabled or not BeekeeperState.AutoCatch then return end
    if tick() - lastBeeCatch > 0.5 then -- Run exactly every 0.5 second
        lastBeeCatch = tick()

        if not PickUpBeeRemote then return end

        local char = Services.LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local myPos = char.HumanoidRootPart.Position
        local closestBee, closestBeeId, minDistance = nil, nil, 20 -- Max distance 20
        
        for bee, _ in pairs(beeCache) do
            if bee and bee.Parent then
                local beeId = bee:GetAttribute("Id") or bee:GetAttribute("BeeId")
                if beeId then
                    local pos = (bee:IsA("BasePart") and bee.Position) or (bee:IsA("Model") and bee:GetPivot().Position)
                    if pos then
                        local dist = (pos - myPos).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closestBeeId = beeId
                            closestBee = bee
                        end
                    end
                end
            else
                beeCache[bee] = nil
            end
        end
        
        if closestBeeId then
            PickUpBeeRemote:FireServer({ beeId = closestBeeId })
        end
    end
end

-- Public Functions
function Mega.Features.Beekeeper.SetEnabled(state)
    BeekeeperState.Enabled = state
    
    if state then
        PopulateBeeCache()
        
        if not connections.BeekeeperAdded then
            connections.BeekeeperAdded = Services.Workspace.DescendantAdded:Connect(function(descendant)
                if BeekeeperState.Enabled and IsTargetBee(descendant) then
                    UpdateBeeESP(descendant)
                end
            end)
        end
        
        if not connections.BeekeeperRemoving then
            connections.BeekeeperRemoving = Services.Workspace.DescendantRemoving:Connect(function(descendant)
                if beeCache[descendant] then
                    beeCache[descendant] = nil
                end
            end)
        end
        
        if not connections.BeekeeperCatch then
            connections.BeekeeperCatch = Services.RunService.Heartbeat:Connect(AutoCatchLoop)
        end
    else
        ClearBeekeeperESP()
        -- We don't disconnect events here to keep them ready, but we could if we wanted to save performance when disabled
    end
end

function Mega.Features.Beekeeper.UpdateVisuals()
    if not BeekeeperState.Enabled then return end
    
    -- Update existing bees
    for bee, _ in pairs(beeCache) do
        UpdateBeeESP(bee)
    end
    
    -- Update hives
    UpdateHiveESP()
end

-- Initialize if enabled in config
if BeekeeperState.Enabled then
    Mega.Features.Beekeeper.SetEnabled(true)
end
