-- features/autotool.lua
-- AutoTool - automatically switches to the best breaking tool for Bedwars blocks

if not Mega.Features then Mega.Features = {} end
Mega.Features.AutoTool = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    ContextActionService = game:GetService("ContextActionService"),
    UserInputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Combat then States.Combat = {} end
if States.Combat.AutoTool == nil then States.Combat.AutoTool = { Enabled = false } end

local bedwars = {}
local store = {
    inventory = {
        inventory = {
            items = {}
        },
        hotbar = {},
        hotbarSlot = 1
    },
    tools = {}
}

local storeChangedConnection
local oldHitBlock
local active = false

local InventoryChanged = Instance.new("BindableEvent")
local blockBreakTrigger = Instance.new("BindableEvent")
local blockBreakConnection

local function initBedwars()
    if bedwars.BlockBreaker then return true end
    
    pcall(function()
        local tsKnit = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("knit")
        local Knit = tsKnit and require(tsKnit).Knit
        if not Knit then
            local knitModule = Services.ReplicatedStorage:FindFirstChild("rbxts_include")
                and Services.ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
                and Services.ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@easy-games")
                and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]:FindFirstChild("knit")
                and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit:FindFirstChild("src")
            if knitModule then
                Knit = require(knitModule).KnitClient
            end
        end
        if not Knit then
            Knit = getgenv().Knit or shared.Knit
        end
        
        if Knit then
            bedwars.BlockBreakController = Knit.Controllers.BlockBreakController
            bedwars.BlockBreaker = Knit.Controllers.BlockBreakController and Knit.Controllers.BlockBreakController.blockBreaker or nil
            
            local replicatedStorage = Services.ReplicatedStorage
            bedwars.BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine
            bedwars.ItemMeta = require(replicatedStorage.TS.item['item-meta']).items
            bedwars.Store = require(LocalPlayer.PlayerScripts.TS.ui.store).ClientStore
        end
    end)
    
    return bedwars.BlockBreaker ~= nil
end

local function getActiveSlot()
    if bedwars.Store then
        local success, state = pcall(function() return bedwars.Store:getState() end)
        if success and state and state.Inventory and state.Inventory.observedInventory then
            return state.Inventory.observedInventory.hotbarSlot
        end
    end
    return store.inventory and store.inventory.hotbarSlot
end

local function getTool(breakType)
    local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
    if not bedwars.ItemMeta then return nil, nil end
    if not store.inventory or not store.inventory.inventory or not store.inventory.inventory.items then return nil, nil end
    for slot, item in pairs(store.inventory.inventory.items) do
        local itemData = bedwars.ItemMeta[item.itemType]
        local toolMeta = itemData and itemData.breakBlock
        if toolMeta then
            local toolDamage = toolMeta[breakType] or 0
            if toolDamage > bestToolDamage then
                bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
            end
        end
    end
    return bestTool, bestToolSlot
end

local function updateStore(new, oldState)
    if new.Inventory ~= oldState.Inventory then
        local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
        store.inventory = newinv
        
        if newinv.inventory and newinv.inventory.items then
            for _, v in ipairs({'stone', 'wood', 'wool'}) do
                local tool, slot = getTool(v)
                store.tools[v] = tool
            end
        end
        
        InventoryChanged:Fire()
    end
end

local function hotbarSwitch(slot)
    if slot ~= nil and store.inventory and getActiveSlot() ~= slot then
        bedwars.Store:dispatch({
            type = 'InventorySelectHotbarSlot',
            slot = slot
        })
        InventoryChanged.Event:Wait()
        return true
    end
    return false
end

local function switchHotbarItem(block)
    if not bedwars.ItemMeta then return nil end
    if block and not block:GetAttribute('NoBreak') and not block:GetAttribute('Team'..(LocalPlayer:GetAttribute('Team') or 0)..'NoBreak') then
        local itemData = bedwars.ItemMeta[block.Name]
        local breakType = itemData and itemData.block and itemData.block.breakType
        if breakType == 'gumdrop_bounce_pad' then breakType = 'stone' end
        
        local tool = breakType and store.tools[breakType]
        local slot = nil
        if tool and store.inventory and store.inventory.hotbar then
            for i, v in ipairs(store.inventory.hotbar) do
                if v.item and v.item.itemType == tool.itemType then
                    slot = i - 1
                    break
                end
            end
            if slot ~= nil and hotbarSwitch(slot) then
                if Services.UserInputService:IsMouseButtonPressed(0) then
                    blockBreakTrigger:Fire()
                end
                return true
            end
        end
    end
    return nil
end

local function hookHitBlock()
    if not initBedwars() then return end
    if oldHitBlock then return end
    
    oldHitBlock = bedwars.BlockBreaker.hitBlock
    bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
        local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
        if switchHotbarItem(block and block.target and block.target.blockInstance or nil) then
            return
        end
        return oldHitBlock(self, maid, raycastparams, ...)
    end
end

local function unhookHitBlock()
    if oldHitBlock then
        if bedwars.BlockBreaker then
            bedwars.BlockBreaker.hitBlock = oldHitBlock
        end
        oldHitBlock = nil
    end
end

function Mega.Features.AutoTool.SetEnabled(state)
    States.Combat.AutoTool.Enabled = state
    if state then
        if initBedwars() then
            if not storeChangedConnection then
                storeChangedConnection = bedwars.Store.changed:connect(updateStore)
                updateStore(bedwars.Store:getState(), {})
            end
            if not blockBreakConnection then
                blockBreakConnection = blockBreakTrigger.Event:Connect(function()
                    Services.ContextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
                end)
            end
            hookHitBlock()
            active = true
        end
    else
        unhookHitBlock()
        if storeChangedConnection then
            storeChangedConnection:disconnect()
            storeChangedConnection = nil
        end
        if blockBreakConnection then
            blockBreakConnection:Disconnect()
            blockBreakConnection = nil
        end
        active = false
    end
end

if States.Combat.AutoTool.Enabled then
    Mega.Features.AutoTool.SetEnabled(true)
end

if Mega.UnloadedSignal then
    Mega.UnloadedSignal:Connect(function()
        unhookHitBlock()
        if storeChangedConnection then
            storeChangedConnection:disconnect()
            storeChangedConnection = nil
        end
        if blockBreakConnection then
            blockBreakConnection:Disconnect()
            blockBreakConnection = nil
        end
    end)
end

return Mega.Features.AutoTool
