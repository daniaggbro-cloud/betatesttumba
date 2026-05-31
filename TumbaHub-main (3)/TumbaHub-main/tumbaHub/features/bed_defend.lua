-- features/bed_defend.lua
-- Bed Protector - EXACT replica of the TumbaV6 / Vape Bed Protector feature
-- Automatically builds a mathematical pyramid defense using the strongest blocks in your inventory

if not Mega.Features then Mega.Features = {} end
Mega.Features.BedDefend = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.BedDefend == nil then States.Player.BedDefend = false end

local bedwars = {}

-- Lazy-load Bedwars block controller
local function initBedwars()
    pcall(function()
        local lplr = Services.Players.LocalPlayer
        local Knit = require(lplr.PlayerScripts.TS.knit).Knit
        bedwars.BlockController = require(Services.ReplicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine
    end)
end

local function getPlacedBlock(pos)
    if not pos then return nil end
    initBedwars()
    
    local block, blockPos
    pcall(function()
        if bedwars.BlockController then
            local bp = bedwars.BlockController:getBlockPosition(pos)
            block = bedwars.BlockController:getStore():getBlockAt(bp)
            blockPos = bp
        end
    end)
    if block then return block, blockPos end
    
    -- Fallback: Scan Map blocks directly
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    local blocksFolder = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Blocks") or game.Workspace:FindFirstChild("Blocks")
    if blocksFolder then
        overlap.FilterDescendantsInstances = {blocksFolder}
    end
    local parts = game.Workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(2.8, 2.8, 2.8), overlap)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and p.Name ~= "bed" and not p:GetAttribute("NoBreak") then
            return p, Vector3.new(math.round(pos.X / 3), math.round(pos.Y / 3), math.round(pos.Z / 3))
        end
    end
    return nil
end

local function placeBlock(pos, blockName)
    local blockPlacerModule = Services.ReplicatedStorage:FindFirstChild("rbxts_include")
        and Services.ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
        and Services.ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@easy-games")
        and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]:FindFirstChild("block-engine")
        and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"]:FindFirstChild("out")
        and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out:FindFirstChild("client")
        and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client:FindFirstChild("placement")
        and Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement:FindFirstChild("block-placer")
    
    if blockPlacerModule then
        local BlockPlacer = require(blockPlacerModule).BlockPlacer
        local BlockEngine = require(Services.ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out).BlockEngine
        local placer = BlockPlacer.new(BlockEngine, blockName)
        if placer then
            local blockPos = BlockEngine:getBlockPosition(pos)
            placer:placeBlock(blockPos)
        end
    end
end

local function getBedNear()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local localPosition = hrp and hrp.Position or Vector3.zero
    for _, v in ipairs(Services.CollectionService:GetTagged('bed')) do
        if (localPosition - v.Position).Magnitude < 20 and v:GetAttribute('Team'..(LocalPlayer:GetAttribute('Team') or -1)..'NoBreak') then
            return v
        end
    end
end

local function getBlocks()
    local blocks = {}
    local inventory = nil
    pcall(function()
        local InventoryUtil = require(Services.ReplicatedStorage.TS.inventory["inventory-util"]).InventoryUtil
        inventory = InventoryUtil.getInventory(LocalPlayer)
    end)
    
    if inventory and inventory.items then
        local itemMeta = require(Services.ReplicatedStorage.TS.item['item-meta']).items
        for _, item in ipairs(inventory.items) do
            local meta = itemMeta[item.itemType]
            local block = meta and meta.block
            if block then
                table.insert(blocks, {item.itemType, block.health or 10})
            end
        end
    end
    table.sort(blocks, function(a, b) 
        return a[2] > b[2]
    end)
    return blocks
end

local function getPyramid(size, grid)
    local positions = {}
    for h = size, 0, -1 do
        for w = h, 0, -1 do
            table.insert(positions, Vector3.new(w, (size - h), ((h + 1) - w)) * grid)
            table.insert(positions, Vector3.new(w * -1, (size - h), ((h + 1) - w)) * grid)
            table.insert(positions, Vector3.new(w, (size - h), (h - w) * -1) * grid)
            table.insert(positions, Vector3.new(w * -1, (size - h), (h - w) * -1) * grid)
        end
    end
    return positions
end

local function buildDefense()
    local bed = getBedNear()
    local bedPos = bed and bed.Position or nil
    if bedPos then
        local blocks = getBlocks()
        for i, block in ipairs(blocks) do
            for _, pos in ipairs(getPyramid(i, 3)) do
                if not States.Player.BedDefend then break end
                local targetPos = bedPos + pos
                if not getPlacedBlock(targetPos) then
                    placeBlock(targetPos, block[1])
                    task.wait(0.05)
                end
            end
        end
        
        -- Automatically toggle off when finished
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_bed_defend"] then
            Mega.Objects.Toggles["toggle_bed_defend"](false)
        else
            States.Player.BedDefend = false
        end
    else
        -- Notify the user bed was not found
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("SendNotification", {
                Title = "Bed Protector",
                Text = "Unable to locate bed",
                Duration = 5
            })
        end)
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_bed_defend"] then
            Mega.Objects.Toggles["toggle_bed_defend"](false)
        else
            States.Player.BedDefend = false
        end
    end
end

function Mega.Features.BedDefend.SetEnabled(state)
    States.Player.BedDefend = state
    
    if state then
        task.spawn(buildDefense)
    end
end

if States.Player.BedDefend then
    Mega.Features.BedDefend.SetEnabled(true)
end

return Mega.Features.BedDefend
