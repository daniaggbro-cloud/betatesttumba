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
-- Periodically re-check the remote
task.spawn(function()
    while task.wait(5) do
        if not CropHarvestRemote then
            CropHarvestRemote = Mega.GetRemote("HarvestCrop")
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

-- Helper: Count items in inventory
local function getItemCount(itemName)
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
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
    scan(character)
    return count
end

-- Helper: Get current shop item price
local function getShopItemPrice(itemType)
    local price = nil
    pcall(function()
        local storeScript = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("ui") and LocalPlayer.PlayerScripts.TS.ui:FindFirstChild("store")
        if storeScript then
            local Store = require(storeScript).ClientStore
            local state = Store:getState()
            
            -- Try different possible state paths
            local shopData = (state.Bedwars and state.Bedwars.shopItems) or (state.Shop and state.Shop.shopItems)
            if shopData then
                for _, item in ipairs(shopData) do
                    if item.itemType == itemType then
                        price = item.price
                        break
                    end
                end
            end
        end
    end)
    
    -- Fallback: check config
    if not price then
        pcall(function()
            local shopItemsModule = Services.ReplicatedStorage:FindFirstChild("TS") and Services.ReplicatedStorage.TS:FindFirstChild("bedwars") and Services.ReplicatedStorage.TS.bedwars:FindFirstChild("shop") and Services.ReplicatedStorage.TS.bedwars.shop:FindFirstChild("shop-items")
            if shopItemsModule then
                local config = require(shopItemsModule).ShopItemConfig
                if config and config[itemType] then
                    price = config[itemType].price
                end
            end
        end)
    end
    
    return price
end

local purchaseRemote
local function StartHarvestLoop()
    if connections.AutoHarvestLoop then connections.AutoHarvestLoop:Disconnect() end
    
    local lastCletusRun = 0
    local lastAutoBuyRun = 0
    
    connections.AutoHarvestLoop = Services.RunService.Heartbeat:Connect(function()
        if not States.Cletus.Enabled then return end
        
        -- 1. Auto Harvest
        if States.Cletus.AutoHarvest and tick() - lastCletusRun > 0.5 then
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

        -- 2. Auto Buy Seeds
        if States.Cletus.AutoBuy and tick() - lastAutoBuyRun > 1.5 then
            lastAutoBuyRun = tick()
            
            local currentPrice = getShopItemPrice("melon_seeds")
            -- If we can't get the price, we try to guess it or use a default (2) to see if it works
            local priceToUse = currentPrice or 2 
            
            if priceToUse <= States.Cletus.AutoBuyMaxPrice then
                local emeralds = getItemCount("emerald")
                if emeralds >= priceToUse then
                    if not purchaseRemote then
                        pcall(function()
                            local netManaged = Services.ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
                            purchaseRemote = netManaged:FindFirstChild("BedwarsPurchaseItem")
                        end)
                    end
                    
                    if purchaseRemote then
                        local args = {
                            {
                                shopItem = {
                                    currency = "emerald",
                                    itemType = "melon_seeds",
                                    amount = 1,
                                    price = priceToUse,
                                    category = "Combat",
                                    requiresKit = { "farmer_cletus" }
                                },
                                shopId = "1_item_shop"
                            }
                        }
                        task.spawn(function()
                            print("[Cletus] Attempting to buy melon_seeds for " .. tostring(priceToUse) .. " emeralds")
                            local success, result = pcall(function() return purchaseRemote:InvokeServer(unpack(args)) end)
                            if not success then
                                warn("[Cletus] Purchase failed: " .. tostring(result))
                            end
                        end)
                    else
                        warn("[Cletus] PurchaseRemote not found!")
                    end
                end
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
    else
        if connections.AutoHarvestLoop then
            connections.AutoHarvestLoop:Disconnect()
            connections.AutoHarvestLoop = nil
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
