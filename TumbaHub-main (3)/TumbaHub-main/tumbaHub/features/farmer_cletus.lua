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

-- =====================================================
-- Кэш для модуля магазина и функции расчёта цен
-- =====================================================
local BedwarsShopData = nil     -- Результат require(bedwars-shop) ModuleScript
local BedwarsShopItems = nil    -- Массив ShopItems
local BedwarsGetAdjusted = nil  -- Функция getAdjustedShopPrice
local BedwarsGetShopItem = nil  -- Функция getShopItem
local melonSeedsEntry = nil     -- Закэшированная запись melon_seeds

-- ====================================================================
-- МЕТОД A: Прямой require() модуля по известному пути в ReplicatedStorage
-- Путь: ReplicatedStorage → TS → games → bedwars → shop → bedwars-shop
-- ====================================================================
local function tryDirectRequire()
    if BedwarsShopData then return true end
    
    local success = pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local TS = RS:FindFirstChild("TS")
        if not TS then return end
        
        local games = TS:FindFirstChild("games")
        if not games then return end
        
        local bedwars = games:FindFirstChild("bedwars")
        if not bedwars then return end
        
        local shopFolder = bedwars:FindFirstChild("shop")
        if not shopFolder then return end
        
        local shopModule = shopFolder:FindFirstChild("bedwars-shop")
        if not shopModule or not shopModule:IsA("ModuleScript") then return end
        
        local data = require(shopModule)
        if type(data) ~= "table" then return end
        
        -- Модуль возвращает таблицу с BedwarsShop внутри
        local shop = data.BedwarsShop or data
        if shop and shop.ShopItems then
            BedwarsShopData = shop
            BedwarsShopItems = shop.ShopItems
            
            if type(shop.getAdjustedShopPrice) == "function" then
                BedwarsGetAdjusted = shop.getAdjustedShopPrice
            end
            if type(shop.getShopItem) == "function" then
                BedwarsGetShopItem = shop.getShopItem
            end
            
            -- Кэшируем melon_seeds
            for _, item in ipairs(BedwarsShopItems) do
                if type(item) == "table" and item.itemType == "melon_seeds" then
                    melonSeedsEntry = item
                    break
                end
            end
        end
    end)
    
    return BedwarsShopData ~= nil
end

-- ====================================================================
-- МЕТОД B: Поиск через getloadedmodules() (если прямой путь не сработал)
-- ====================================================================
local function tryLoadedModules()
    if BedwarsShopData then return true end
    if not getloadedmodules then return false end
    
    pcall(function()
        for _, obj in ipairs(getloadedmodules()) do
            -- Ищем по имени или по полному пути
            local name = obj.Name
            if name == "bedwars-shop" or name:find("bedwars%-shop") then
                local data = require(obj)
                if type(data) == "table" then
                    local shop = data.BedwarsShop or data
                    if shop and shop.ShopItems then
                        BedwarsShopData = shop
                        BedwarsShopItems = shop.ShopItems
                        if type(shop.getAdjustedShopPrice) == "function" then
                            BedwarsGetAdjusted = shop.getAdjustedShopPrice
                        end
                        if type(shop.getShopItem) == "function" then
                            BedwarsGetShopItem = shop.getShopItem
                        end
                        for _, item in ipairs(BedwarsShopItems) do
                            if type(item) == "table" and item.itemType == "melon_seeds" then
                                melonSeedsEntry = item
                                break
                            end
                        end
                        return
                    end
                end
            end
        end
    end)
    
    return BedwarsShopData ~= nil
end

-- Инициализация кэша - вызывается один раз
local function ensureShopData()
    if BedwarsShopData then return true end
    if tryDirectRequire() then return true end
    if tryLoadedModules() then return true end
    return false
end

-- Пробуем инициализировать сразу при загрузке модуля
task.spawn(function()
    task.wait(2) -- Даём игре загрузить все модули
    ensureShopData()
end)

-- Rodux Store (доп. резерв)
local BedwarsStore = nil
local function getClientStore()
    if BedwarsStore then return BedwarsStore end
    if not getloadedmodules then return nil end
    pcall(function()
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
    end)
    return BedwarsStore
end

local function getMelonPriceInvisibly()
    -- ============================================================
    -- 1. МОДУЛЬ МАГАЗИНА (основной метод, работает ВСЕГДА)
    -- ============================================================
    ensureShopData()
    
    if melonSeedsEntry then
        -- Сначала пробуем динамическую цену через getAdjustedShopPrice
        if BedwarsGetAdjusted then
            local ok, adjusted = pcall(BedwarsGetAdjusted, melonSeedsEntry)
            if ok and type(adjusted) == "number" then
                return adjusted
            end
        end
        
        -- Или через getShopItem (может вернуть актуальный объект с ценой)
        if BedwarsGetShopItem then
            local ok, shopItem = pcall(BedwarsGetShopItem, "melon_seeds")
            if ok and type(shopItem) == "table" and shopItem.price then
                return shopItem.price
            end
        end
        
        -- Базовая цена из модуля (статическая, но точная)
        if melonSeedsEntry.price then
            return melonSeedsEntry.price
        end
    end
    
    -- ============================================================
    -- 2. RODUX STORE (резервный)
    -- ============================================================
    local store = getClientStore()
    if store then
        local storePrice = nil
        pcall(function()
            local state = store:getState()
            if state then
                local function searchPrice(t, depth)
                    if depth > 6 or type(t) ~= "table" then return nil end
                    
                    if rawget(t, "itemType") == "melon_seeds" then
                        if rawget(t, "price") then return rawget(t, "price") end
                    end
                    if rawget(t, "melon_seeds") and type(rawget(t, "melon_seeds")) == "table" then
                        local ms = rawget(t, "melon_seeds")
                        if ms.price then return ms.price end
                    end
                    
                    for k, v in pairs(t) do
                        if type(v) == "table" then
                            local found = searchPrice(v, depth + 1)
                            if found then return found end
                        end
                    end
                    return nil
                end
                storePrice = searchPrice(state, 1)
            end
        end)
        if storePrice then return storePrice end
    end
    
    -- ============================================================
    -- 3. ХАРДКОД ИЗ PACKAGES.JSON (если вообще ничего не сработало)
    -- Базовая цена melon_seeds = 2 emerald (из дампа игры)
    -- ============================================================
    -- Не возвращаем сразу — сначала проверим UI
    
    -- ============================================================
    -- 4. UI SCAN (если магазин открыт)
    -- ============================================================
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
                    end
                end
            end
        end
    end
    
    -- ============================================================
    -- 5. ХАРДКОД FALLBACK: если ВСЕ методы не сработали
    -- Возвращаем базовую цену из дампа (2 emerald)
    -- ============================================================
    return 2
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
