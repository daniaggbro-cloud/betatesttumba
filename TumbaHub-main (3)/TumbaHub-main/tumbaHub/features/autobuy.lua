-- features/autobuy.lua
-- Professional AutoBuy System for BedWars
-- Uses dynamic metadata for item prizes and remotes

local Players = Mega.Services.Players
local ReplicatedStorage = Mega.Services.ReplicatedStorage
local lplr = Players.LocalPlayer

-- Module state
local AutoBuy = {
    Enabled = false,
    Categories = {
        Armor = { Enabled = false, Priority = 1 },
        Swords = { Enabled = false, Priority = 2 },
        Tools = { Enabled = false, Priority = 3 },
        Wool = { Enabled = false, Priority = 4 },
        Arrows = { Enabled = false, Priority = 5 }
    },
    LastCheck = 0,
    CheckInterval = 2, -- Seconds between checks
}

-- Utility: Recursive search for a module or object
local function findDeep(parent, name)
    if not parent then return nil end
    local found = parent:FindFirstChild(name)
    if found then return found end
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Folder") or child:IsA("ModuleScript") then
            local res = findDeep(child, name)
            if res then return res end
        end
    end
    return nil
end

-- Utility: Get inventory resource count
local function getResourceCount(name)
    local count = 0
    
    -- 1. Try ClientStore (Most Reliable)
    local clientStore = nil
    pcall(function()
        local rbxts = ReplicatedStorage:FindFirstChild("rbxts_include")
        if rbxts then
            local appController = findDeep(rbxts, "app-controller")
            if appController then
                clientStore = require(appController).AppController:getStore()
            end
            if not clientStore then
                local storeMod = findDeep(rbxts, "client-store")
                if storeMod then
                    clientStore = require(storeMod).ClientStore
                end
            end
        end
    end)
    
    if clientStore then
        local success, state = pcall(function() return clientStore:getState() end)
        if success and state and state.Inventory and state.Inventory.inventory then
            local items = state.Inventory.inventory.items or state.Inventory.inventory.itemsList
            if items then
                for _, item in pairs(items) do -- pairs instead of ipairs in case of dict
                    if item.itemType == name then
                        count = count + (item.amount or 1)
                    end
                end
                return count
            end
        end
    end
    
    -- 2. Try InventoryUtil Fallback
    pcall(function()
        local ts = ReplicatedStorage:FindFirstChild("TS")
        if ts then
            local inv = ts:FindFirstChild("inventory")
            if inv then
                local invUtil = inv:FindFirstChild("inventory-util")
                if invUtil then
                    local util = require(invUtil).InventoryUtil
                    if util and util.getAmount then
                        count = util.getAmount(lplr, name)
                    end
                end
            end
        end
    end)
    
    return count
end

-- Utility: Check if item is in inventory
local function hasItem(name)
    return getResourceCount(name) > 0
end

-- Utility: Buy item via remote
local function buyItem(itemType)
    local remote = Mega.GetRemote("BedwarsShop_PurchaseItem")
    
    -- Robust Manual Fallback
    if not remote then
        local rbxts = ReplicatedStorage:FindFirstChild("rbxts_include")
        if rbxts then
            local nm = findDeep(rbxts, "_NetManaged")
            if nm then
                for _, child in pairs(nm:GetChildren()) do
                    local n = child.Name:lower()
                    if (n:find("shop") or n:find("purchase")) and n:find("item") then
                        remote = child
                        print("🛠 AutoBuy: Found Remote manually -> " .. child.Name)
                        break
                    end
                end
            end
        end
    end

    if remote then
        warn("🛒 AutoBuy: Attempting to buy " .. itemType)
        local args = {
            shopItem = {
                itemType = itemType
            }
        }
        
        local success, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(args)
            else
                remote:InvokeServer(args)
            end
        end)
        
        if not success then
            warn("❌ AutoBuy Purchase Error: " .. tostring(err))
        end
        return success
    else
        warn("❌ AutoBuy Error: Shop Remote NOT FOUND!")
    end
    return false
end

-- Main purchase logic
local function processAutoBuy()
    if not AutoBuy.Enabled then return end
    
    local iron = getResourceCount("iron")
    local emeralds = getResourceCount("emerald")
    
    -- Debug every 10 seconds to avoid spam
    if tick() - AutoBuy.LastCheck > 10 then
        print(string.format("📊 AutoBuy Status: Iron=%d, Emeralds=%d, Enabled=%s", iron, emeralds, tostring(AutoBuy.Enabled)))
        AutoBuy.LastCheck = tick()
    end
    
    -- 1. Armor Logic (High Priority)
    if AutoBuy.Categories.Armor.Enabled then
        local armorTiers = {
            {id = "emerald_chestplate", price = 40, currency = "emerald"},
            {id = "diamond_chestplate", price = 8, currency = "emerald"},
            {id = "iron_chestplate", price = 120, currency = "iron"},
            {id = "leather_chestplate", price = 50, currency = "iron"}
        }
        
        for _, armor in ipairs(armorTiers) do
            if not hasItem(armor.id) then
                local canAfford = (armor.currency == "iron" and iron >= armor.price) or (armor.currency == "emerald" and emeralds >= armor.price)
                if canAfford then
                    if buyItem(armor.id) then return end -- One purchase per tick
                end
            else
                break -- We have this or better
            end
        end
    end
    
    -- 2. Sword Logic
    if AutoBuy.Categories.Swords.Enabled then
        local swordTiers = {
            {id = "emerald_sword", price = 20, currency = "emerald"},
            {id = "diamond_sword", price = 4, currency = "emerald"},
            {id = "iron_sword", price = 70, currency = "iron"},
            {id = "stone_sword", price = 20, currency = "iron"}
        }
        
        for _, sword in ipairs(swordTiers) do
            if not hasItem(sword.id) then
                local canAfford = (sword.currency == "iron" and iron >= sword.price) or (sword.currency == "emerald" and emeralds >= sword.price)
                if canAfford then
                    if buyItem(sword.id) then return end
                end
            else
                break
            end
        end
    end
    
    -- 3. Tools Logic
    if AutoBuy.Categories.Tools.Enabled then
        -- Pickaxes
        local pickTiers = {
            {id = "diamond_pickaxe", price = 60, currency = "iron"},
            {id = "iron_pickaxe", price = 20, currency = "iron"},
            {id = "stone_pickaxe", price = 20, currency = "iron"}
        }
        for _, pick in ipairs(pickTiers) do
            if not hasItem(pick.id) then
                if iron >= pick.price then
                    if buyItem(pick.id) then return end
                end
            else break end
        end
        
        -- Axes
        local axeTiers = {
            {id = "diamond_axe", price = 60, currency = "iron"},
            {id = "iron_axe", price = 30, currency = "iron"},
            {id = "stone_axe", price = 20, currency = "iron"}
        }
        for _, axe in ipairs(axeTiers) do
            if not hasItem(axe.id) then
                if iron >= axe.price then
                    if buyItem(axe.id) then return end
                end
            else break end
        end
    end
    
    -- 4. Wool Logic
    if AutoBuy.Categories.Wool.Enabled then
        local woolCount = getResourceCount("wool_white") -- Simplification, checks white wool
        if woolCount < 16 and iron >= 8 then
            buyItem("wool_white")
            return
        end
    end
    
    -- 5. Arrows Logic
    if AutoBuy.Categories.Arrows.Enabled then
        local hasBow = hasItem("wood_bow") or hasItem("wood_crossbow") or hasItem("tactical_crossbow")
        if hasBow then
            local arrowCount = getResourceCount("arrow")
            if arrowCount < 8 and iron >= 16 then
                buyItem("arrow")
                return
            end
        end
    end
end

-- Register Feature
Mega.Features["AutoBuy"] = {
    Name = "Auto Buy",
    Description = "Automatically purchases items from the shop.",
    Toggles = {
        ["Enabled"] = function(val) 
            AutoBuy.Enabled = val 
            if val then
                task.spawn(function()
                    while AutoBuy.Enabled do
                        processAutoBuy()
                        task.wait(AutoBuy.CheckInterval)
                    end
                end)
            end
        end,
        ["Armor"] = function(val) AutoBuy.Categories.Armor.Enabled = val end,
        ["Swords"] = function(val) AutoBuy.Categories.Swords.Enabled = val end,
        ["Tools"] = function(val) AutoBuy.Categories.Tools.Enabled = val end,
        ["Wool"] = function(val) AutoBuy.Categories.Wool.Enabled = val end,
        ["Arrows"] = function(val) AutoBuy.Categories.Arrows.Enabled = val end,
    }
}

return AutoBuy
