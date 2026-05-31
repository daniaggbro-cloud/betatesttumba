-- features/bed_defend.lua
-- Auto Bed Defend module - automatically builds a protective cover around your team's bed

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
if States.Player.BedDefendBlock == nil then States.Player.BedDefendBlock = "wool" end
if States.Player.BedDefendLayer == nil then States.Player.BedDefendLayer = 1 end

local active = false
local placeDelay = 0.05

local function getOurBed()
    local myTeam = LocalPlayer:GetAttribute("Team")
    for _, bed in ipairs(Services.CollectionService:GetTagged("bed")) do
        if bed:IsA("BasePart") or bed:IsA("Model") then
            local bedTeam = bed:GetAttribute("TeamId") or bed:GetAttribute("Team")
            if bedTeam == myTeam then
                return bed:IsA("BasePart") and bed or bed.PrimaryPart
            end
        end
    end
    
    -- Fallback: find nearest bed
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local closestBed = nil
        local closestDist = 9999
        for _, bed in ipairs(Services.CollectionService:GetTagged("bed")) do
            local bedPart = bed:IsA("BasePart") and bed or bed.PrimaryPart
            if bedPart then
                local dist = (bedPart.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestBed = bedPart
                end
            end
        end
        return closestBed
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

local function isBlockAt(pos)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    local folder = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Blocks") or game.Workspace:FindFirstChild("Blocks")
    if folder then
        overlap.FilterDescendantsInstances = {folder}
    end
    local parts = game.Workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(2.8, 2.8, 2.8), overlap)
    return #parts > 0
end

local function getInventoryBlock(blockName)
    -- In Bedwars, blockName can be e.g. "wool_white" or "wood_oak"
    -- Let's resolve the exact itemType from inventory
    local Knit = require(LocalPlayer.PlayerScripts.TS.knit).Knit
    local ClientStore = require(LocalPlayer.PlayerScripts.TS.ui.store.client_store).ClientStore
    local inventory = ClientStore:getState().Inventory.inventory
    
    if inventory and inventory.items then
        for _, item in ipairs(inventory.items) do
            if item.itemType:lower():find(blockName:lower()) then
                return item.itemType
            end
        end
    end
    return nil
end

local function buildDefense()
    if active then return end
    active = true
    
    local bed = getOurBed()
    if not bed then
        active = false
        return
    end
    
    -- Check if we have blocks
    local blockType = States.Player.BedDefendBlock or "wool"
    local resolvedBlock = getInventoryBlock(blockType)
    if not resolvedBlock then
        active = false
        return
    end

    local bedPos = bed.Position
    local layer = States.Player.BedDefendLayer or 1
    
    -- Calculate shell offsets around the bed
    -- Since bed is 2 parts (placed along either X or Z), we define a protective shell
    local offsets = {}
    local step = 3
    
    -- Layer 1 shell offsets
    for x = -step, step, step do
        for y = 0, step, step do
            for z = -step, step, step do
                -- Exclude the bed itself (center area)
                if not (x == 0 and y == 0 and z == 0) and not (x == 0 and y == 0 and z == step) then
                    table.insert(offsets, Vector3.new(x, y, z))
                end
            end
        end
    end
    
    -- Layer 2 shell offsets if enabled
    if layer > 1 then
        local step2 = step * 2
        for x = -step2, step2, step do
            for y = 0, step, step do
                for z = -step2, step2, step do
                    -- Outer shell
                    if math.abs(x) == step2 or math.abs(z) == step2 or y == step then
                        table.insert(offsets, Vector3.new(x, y, z))
                    end
                end
            end
        end
    end
    
    -- Place blocks at calculated positions
    task.spawn(function()
        for _, offset in ipairs(offsets) do
            if not States.Player.BedDefend then break end
            local targetPos = bedPos + offset
            
            if not isBlockAt(targetPos) then
                pcall(placeBlock, targetPos, resolvedBlock)
                task.wait(placeDelay)
            end
        end
        active = false
        
        -- Automatically toggle off when finished
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_bed_defend"] then
            Mega.Objects.Toggles["toggle_bed_defend"](false)
        else
            States.Player.BedDefend = false
        end
    end)
end

function Mega.Features.BedDefend.SetEnabled(state)
    States.Player.BedDefend = state
    
    if state then
        task.spawn(buildDefense)
    else
        active = false
    end
end

if States.Player.BedDefend then
    Mega.Features.BedDefend.SetEnabled(true)
end

return Mega.Features.BedDefend
