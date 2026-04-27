-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) - Ported from tumbaHub.lua

if not Mega.Features then Mega.Features = {} end
Mega.Features.Cletus = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

if not Mega.Objects.CletusConnections then Mega.Objects.CletusConnections = {} end
local connections = Mega.Objects.CletusConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- Контейнер для событий ESP
local espConnections = {}

-- Remote
local CropHarvestRemote = Mega.GetRemote("HarvestCrop")
local PurchaseRemote = nil
-- Periodically re-check the remote
task.spawn(function()
    while task.wait(5) do
        if not CropHarvestRemote then
            CropHarvestRemote = Mega.GetRemote("HarvestCrop")
        end
        if not PurchaseRemote then
            pcall(function()
                PurchaseRemote = game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BedwarsPurchaseItem")
            end)
        end
    end
end)


local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}

-- Cletus ESP Logic
local cletusEspFolder = Services.CoreGui:FindFirstChild("CletusESP")
if not cletusEspFolder then
    cletusEspFolder = Instance.new("Folder")
    cletusEspFolder.Name = "CletusESP"
    cletusEspFolder.Parent = Services.CoreGui
end

local function EnableCletusESP()
    for _, conn in pairs(espConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(espConnections)
    cletusEspFolder:ClearAllChildren()

    if States.Cletus.Enabled and States.Cletus.ESP then
        local function updateCrop(crop)
            if not crop:IsA("BasePart") then return end
            local espName = crop:GetDebugId()
            local existing = cletusEspFolder:FindFirstChild(espName)

            local stage = crop:GetAttribute("CropStage")

            if stage and stage >= 3 then
                if not existing then
                    local esp = Instance.new("BoxHandleAdornment")
                    esp.Name = espName
                    esp.Adornee = crop
                    esp.Size = crop.Size + Vector3.new(0.1, 0.1, 0.1)
                    
                    local color = Color3.fromRGB(0, 255, 0)
                    if crop.Name:lower():find("carrot") then
                        color = Color3.fromRGB(255, 170, 0)
                    elseif crop.Name:lower():find("melon") then
                        color = Color3.fromRGB(170, 255, 127)
                    end
                    esp.Color3 = color
                    esp.AlwaysOnTop = true
                    esp.ZIndex = 5
                    esp.Transparency = States.Cletus.ESPTransparency
                    esp.Parent = cletusEspFolder
                end
            else
                if existing then existing:Destroy() end
            end
        end

        local function onCropAdded(crop)
            updateCrop(crop)
            local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function()
                updateCrop(crop)
            end)
            table.insert(espConnections, conn)

            local ancestryConn = crop.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    local espName = crop:GetDebugId()
                    local existing = cletusEspFolder:FindFirstChild(espName)
                    if existing then existing:Destroy() end
                end
            end)
            table.insert(espConnections, ancestryConn)
        end

        local addedConn = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(onCropAdded)
        table.insert(espConnections, addedConn)

        for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
            onCropAdded(crop)
        end
    end
end

local function UpdateCletusTransparency()
    for _, h in ipairs(cletusEspFolder:GetChildren()) do
        if h:IsA("BoxHandleAdornment") then
            h.Transparency = States.Cletus.ESPTransparency
        end
    end
end

local function StartHarvestLoop()
    if connections.AutoHarvestLoop then connections.AutoHarvestLoop:Disconnect() end
    
    local lastCletusRun = 0
    connections.AutoHarvestLoop = Services.RunService.Heartbeat:Connect(function()
        if not States.Cletus.Enabled or not States.Cletus.AutoHarvest then return end
        
        if tick() - lastCletusRun > 0.5 then
            lastCletusRun = tick()

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local crops = Services.CollectionService:GetTagged("Crop")
                for _, crop in ipairs(crops) do
                    if crop:IsA("BasePart") then
                        local stage = crop:GetAttribute("CropStage")
                        if stage and stage >= 3 then
                            local dist = (hrp.Position - crop.Position).Magnitude
                            if dist <= States.Cletus.Range then
                                local blockPos = Vector3.new(math.round(crop.Position.X / 3), math.round(crop.Position.Y / 3), math.round(crop.Position.Z / 3))
                                local args = {{ ["position"] = vector.create(blockPos.X, blockPos.Y, blockPos.Z) }}
                                task.spawn(function()
                                    pcall(function() if CropHarvestRemote then CropHarvestRemote:InvokeServer(unpack(args)) end end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function getItemCount(itemName)
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    
    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item.Name == itemName then
                local amount = item:GetAttribute("Amount") or (item:IsA("Tool") and 1) or 0
                count = count + (tonumber(amount) or 0)
            end
        end
    end
    
    scan(backpack)
    scan(char)
    return count
end

local function getClosestItemShop()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "1_item_shop" end

    local closestShopId = "1_item_shop"
    local closestDist = math.huge

    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("item_shop") then
            local primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if primary then
                local dist = (hrp.Position - primary.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestShopId = obj.Name
                end
            end
        end
    end
    
    return closestShopId
end

local BedwarsStore = nil
local function getClientStore()
    if BedwarsStore then return BedwarsStore end
    for _, obj in ipairs(getloadedmodules()) do
        if obj.Name == "ClientStore" or obj.Name == "Store" then
            pcall(function()
                local req = require(obj)
                if type(req) == "table" then
                    if req.getState then BedwarsStore = req end
                    if req.Store and req.Store.getState then BedwarsStore = req.Store end
                    if req.clientStore and req.clientStore.getState then BedwarsStore = req.clientStore end
                end
            end)
        end
    end
    return BedwarsStore
end

local function getMelonPriceInvisibly()
    -- 1. Сначала пробуем найти через UI (самый точный метод, если интерфейс кэширован)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local itemShop = pg:FindFirstChild("ItemShop")
        if itemShop then
            for _, obj in ipairs(itemShop:GetDescendants()) do
                if obj.Name == "melon_seeds_ShopItemCard" then
                    local priceContainer = obj:FindFirstChild("Price")
                    if priceContainer then
                        for _, desc in ipairs(priceContainer:GetDescendants()) do
                            if desc:IsA("TextLabel") and desc.Text then
                                local num = tonumber(desc.Text:match("%d+"))
                                if num then return num end
                            end
                        end
                        for _, desc in ipairs(priceContainer:GetChildren()) do
                            local num = tonumber(desc.Name)
                            if num then return num end
                        end
                    end
                end
            end
        end
    end
    
    -- 2. Если UI закрыт/удален, "невидимо" читаем внутреннее состояние игры (Rodux Store)
    local store = getClientStore()
    if store then
        local state = store:getState()
        if state then
            -- Рекурсивный безопасный поиск цены арбузов в дереве состояний
            local function searchPrice(t, depth)
                if depth > 6 then return nil end
                if type(t) ~= "table" then return nil end
                
                -- Если нашли таблицу семян
                if rawget(t, "itemType") == "melon_seeds" or rawget(t, "melon_seeds") then
                    if rawget(t, "price") then return rawget(t, "price") end
                end
                
                for k, v in pairs(t) do
                    if type(v) == "table" then
                        if k == "melon_seeds" and rawget(v, "price") then
                            return rawget(v, "price")
                        end
                        local found = searchPrice(v, depth + 1)
                        if found then return found end
                    end
                end
                return nil
            end
            
            local storePrice = searchPrice(state, 1)
            if storePrice then return storePrice end
        end
    end
    
    return nil
end

local function StartAutoBuyLoop()
    if connections.AutoBuyLoop then connections.AutoBuyLoop:Disconnect() end
    
    local lastBuyRun = 0
    connections.AutoBuyLoop = Services.RunService.Heartbeat:Connect(function()
        if not States.Cletus.Enabled or not States.Cletus.AutoBuyMelons then return end
        
        if tick() - lastBuyRun > (States.Cletus.AutoBuySpeed or 1) then
            lastBuyRun = tick()
            
            -- Подстраховка инвентаря (вдруг они называются melon)
            local currentSeeds = getItemCount("melon_seeds") + getItemCount("melon")
            if currentSeeds >= (States.Cletus.AutoBuyMaxAmount or 3) then return end
            
            local actualPrice = getMelonPriceInvisibly()
            local maxPrice = States.Cletus.MaxMelonPrice or 2
            
            -- Если не удалось узнать цену или она выше лимита - ждем
            if not actualPrice then return end
            if actualPrice > maxPrice then return end
            
            if PurchaseRemote then
                local shopId = getClosestItemShop()
                local args = {
                    {
                        shopItem = {
                            currency = "emerald",
                            itemType = "melon_seeds",
                            amount = 1,
                            price = actualPrice,
                            category = "Combat",
                            requiresKit = { "farmer_cletus" }
                        },
                        shopId = shopId
                    }
                }
                
                task.spawn(function()
                    pcall(function()
                        PurchaseRemote:InvokeServer(unpack(args))
                    end)
                end)
            end
        end
    end)
end

-- Public API
function Mega.Features.Cletus.SetEnabled(state) 
    States.Cletus.Enabled = state 
    EnableCletusESP()
    if state then
        StartHarvestLoop()
        StartAutoBuyLoop()
    else
        if connections.AutoHarvestLoop then
            connections.AutoHarvestLoop:Disconnect()
            connections.AutoHarvestLoop = nil
        end
        if connections.AutoBuyLoop then
            connections.AutoBuyLoop:Disconnect()
            connections.AutoBuyLoop = nil
        end
    end
end

function Mega.Features.Cletus.UpdateVisuals() 
    UpdateCletusTransparency()
end

function Mega.Features.Cletus.RecreateESP() 
    EnableCletusESP()
end

-- Initialize if enabled on startup
if States.Cletus.Enabled then
    Mega.Features.Cletus.SetEnabled(true)
end
