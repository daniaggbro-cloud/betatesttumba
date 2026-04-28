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
    
    -- ОСНОВНОЙ МЕТОД: ReplicatedStorage.Inventories.<PlayerName>
    -- Предметы хранятся как Accessory с атрибутом Amount
    local ok = pcall(function()
        local inventories = game:GetService("ReplicatedStorage"):FindFirstChild("Inventories")
        if inventories then
            local playerInv = inventories:FindFirstChild(LocalPlayer.Name)
            if playerInv then
                local item = playerInv:FindFirstChild(itemName)
                if item then
                    local amount = item:GetAttribute("Amount")
                    if amount then
                        count = tonumber(amount) or 0
                    elseif item:IsA("Accessory") or item:IsA("Tool") then
                        count = 1
                    end
                end
            end
        end
    end)
    
    -- РЕЗЕРВ: Backpack + Character (на случай если структура изменится)
    if count == 0 then
        local function scan(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item.Name == itemName then
                    local amount = item:GetAttribute("Amount") or (item:IsA("Tool") and 1) or 0
                    count = count + (tonumber(amount) or 0)
                end
            end
        end
        scan(LocalPlayer:FindFirstChild("Backpack"))
        scan(LocalPlayer.Character)
    end
    
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

-- =====================================================
-- Кэш для модуля магазина и цены melon_seeds
-- =====================================================
local melonSeedsBasePrice = nil  -- Базовая цена из модуля (2)
local clientStoreRef = nil      -- Rodux ClientStore

-- Инициализация: читаем базовую цену из модуля bedwars-shop
local function ensureBasePrice()
    if melonSeedsBasePrice then return true end
    
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local shopModule = RS:FindFirstChild("TS")
            and RS.TS:FindFirstChild("games")
            and RS.TS.games:FindFirstChild("bedwars")
            and RS.TS.games.bedwars:FindFirstChild("shop")
            and RS.TS.games.bedwars.shop:FindFirstChild("bedwars-shop")
        
        if not shopModule or not shopModule:IsA("ModuleScript") then return end
        
        local data = require(shopModule)
        if type(data) ~= "table" then return end
        
        local shop = data.BedwarsShop or data
        if not shop or not shop.ShopItems then return end
        
        -- getShopItemBase может не найти (фильтр), ищем вручную
        if type(shop.getShopItemBase) == "function" then
            local ok, item = pcall(shop.getShopItemBase, "melon_seeds")
            if ok and type(item) == "table" and item.price then
                melonSeedsBasePrice = item.price
                return
            end
        end
        
        -- Ищем в RAW ShopItems
        for _, item in ipairs(shop.ShopItems) do
            if type(item) == "table" and item.itemType == "melon_seeds" then
                melonSeedsBasePrice = item.price
                return
            end
        end
    end)
    
    -- Хардкод из дампа (packages.json)
    if not melonSeedsBasePrice then
        melonSeedsBasePrice = 2
    end
    
    return true
end

-- Находим ClientStore (Rodux) для чтения taxState
local function getClientStore()
    if clientStoreRef then return clientStoreRef end
    
    pcall(function()
        for _, m in ipairs(getloadedmodules()) do
            if m:GetFullName():find("PlayerScripts.TS.ui.store") and m.Name == "store" then
                local data = require(m)
                if data and data.ClientStore then
                    clientStoreRef = data.ClientStore
                    return
                end
            end
        end
    end)
    
    return clientStoreRef
end

-- Запускаем инициализацию при загрузке модуля
task.spawn(function()
    task.wait(2)
    ensureBasePrice()
    getClientStore()
end)

-- Возвращает ТЕКУЩУЮ цену melon_seeds с учётом shop tax
-- Читает taxState из Rodux Store → Inventory.taxState
-- taxState увеличивает все цены в магазине (0 = нет налога)
local function getMelonCurrentPrice()
    ensureBasePrice()
    
    local basePrice = melonSeedsBasePrice or 2
    
    -- Читаем taxState из ClientStore
    local store = getClientStore()
    if store then
        local ok, taxState = pcall(function()
            local state = store:getState()
            if state and state.Inventory and state.Inventory.taxState then
                return state.Inventory.taxState
            end
            return 0
        end)
        
        if ok and type(taxState) == "number" and taxState > 0 then
            -- Shop tax увеличивает цену: каждый уровень налога добавляет к цене
            -- Формула: adjustedPrice = basePrice + taxState (или basePrice * множитель)
            -- В Bedwars обычно: price = ceil(basePrice * (1 + taxState * 0.5))
            -- Но точная формула зависит от версии. Безопасно: basePrice + taxState
            return math.ceil(basePrice + (basePrice * taxState * 0.5))
        end
    end
    
    return basePrice
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
            
            local actualPrice = getMelonCurrentPrice()
            local maxPrice = States.Cletus.MaxMelonPrice or 2
            
            -- Если базовая цена выше лимита - не покупаем
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
