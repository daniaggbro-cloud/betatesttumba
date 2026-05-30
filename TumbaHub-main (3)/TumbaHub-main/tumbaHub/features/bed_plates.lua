-- features/bed_plates.lua
-- Bed Plates - EXACT replica of the TumbaV6 Bed Plates feature
-- Replicates the exact UI layout, hierarchy, blur shadows, and scanning behavior of TumbaV6

if not Mega.Features then Mega.Features = {} end
Mega.Features.BedPlates = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Ensure settings exist
if not States.Render then States.Render = {} end
if States.Render.BedPlates == nil then States.Render.BedPlates = false end
if States.Render.BedPlatesBackground == nil then States.Render.BedPlatesBackground = true end
if States.Render.BedPlatesCounter == nil then States.Render.BedPlatesCounter = true end

local Reference = {}
local Folder = Services.CoreGui:FindFirstChild("TumbaBedPlates_Container")
if not Folder then
    Folder = Instance.new("Folder")
    Folder.Name = "TumbaBedPlates_Container"
    Folder.Parent = Services.CoreGui
end

local connections = {}
local bedwars = {}

-- Spaced 3 studs apart for exact Bedwars grid alignment
local sides = {
    Vector3.new(3, 0, 0),
    Vector3.new(-3, 0, 0),
    Vector3.new(0, 3, 0),
    Vector3.new(0, -3, 0),
    Vector3.new(0, 0, 3),
    Vector3.new(0, 0, -3)
}

-- Ensure the exact TumbaV6 blur shadow asset is downloaded locally
local function downloadBlurIcon()
    local folderPath = "tumbascript/assets/new/"
    local fullPath = folderPath .. "blur.png"
    if isfile and not isfile(fullPath) then
        pcall(function()
            if not isfolder("tumbascript") then makefolder("tumbascript") end
            if not isfolder("tumbascript/assets") then makefolder("tumbascript/assets") end
            if not isfolder("tumbascript/assets/new") then makefolder("tumbascript/assets/new") end
            local data = game:HttpGet("https://raw.githubusercontent.com/zxcbest957-pixel/TumbaV6/main/assets/new/blur.png")
            if data and #data > 0 then
                writefile(fullPath, data)
            end
        end)
    end
end

local function addBlur(parent)
    downloadBlurIcon()
    local blur = Instance.new("ImageLabel")
    blur.Name = "Blur"
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    
    local assetPath = "tumbascript/assets/new/blur.png"
    if isfile and isfile(assetPath) and getcustomasset then
        pcall(function()
            blur.Image = getcustomasset(assetPath)
        end)
    end
    if not blur.Image or blur.Image == "" then
        blur.Image = "rbxassetid://13388222306" -- fallback logo if failed
    end
    
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.Parent = parent
    return blur
end

-- Lazy-load standard Bedwars metadata
local function initBedwars()
    pcall(function()
        local lplr = Services.Players.LocalPlayer
        local Knit = require(lplr.PlayerScripts.TS.knit).Knit
        bedwars.BlockController = require(Services.ReplicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine
        bedwars.ItemMeta = require(Services.ReplicatedStorage.TS.item['item-meta']).items
        bedwars.getIcon = function(item, showinv)
            local itemmeta = bedwars.ItemMeta[item.itemType]
            return itemmeta and showinv and itemmeta.image or ""
        end
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

local function getBlockLayerHealth(blockName)
    local health = 0
    pcall(function()
        if bedwars.ItemMeta and bedwars.ItemMeta[blockName] then
            local meta = bedwars.ItemMeta[blockName]
            health = meta and meta.block and meta.block.health or 0
        end
    end)
    if health > 0 then return health end
    
    -- Fallbacks
    local healths = {
        wool = 10,
        wood = 20,
        stone = 30,
        blastproof = 50,
        obsidian = 70
    }
    for k, v in pairs(healths) do
        if blockName:lower():find(k) then return v end
    end
    return 10
end

local function getBlockIcon(blockName)
    local icon = ""
    pcall(function()
        if bedwars.getIcon then
            icon = bedwars.getIcon({itemType = blockName}, true)
        end
    end)
    if icon and icon ~= "" then return icon end
    
    local icons = {
        wool = "rbxassetid://9166206875",
        wood = "rbxassetid://13388222306",
        stone = "rbxassetid://13388222306"
    }
    for k, v in pairs(icons) do
        if blockName:lower():find(k) then return v end
    end
    return "rbxassetid://13388222306"
end

local function scanSide(selfPart, start, tab)
    for _, side in ipairs(sides) do
        local layers = {}
        for i = 1, 15 do
            local block = getPlacedBlock(start + (side * i))
            if not block or block == selfPart or block.Name == "bed" then break end
            if not block:GetAttribute("NoBreak") then
                layers[block.Name] = (layers[block.Name] or 0) + 1
            end
        end
        for block, amount in pairs(layers) do
            tab[block] = math.max(tab[block] or 0, amount)
        end
    end
end

local function refreshAdornee(v)
    if not v or not v:FindFirstChild("Frame") then return end
    
    -- Clear old block image elements (exactly matching TumbaV6: Name ~= 'Blur')
    for _, obj in ipairs(v.Frame:GetChildren()) do
        if obj:IsA("ImageLabel") and obj.Name ~= "Blur" then
            obj:Destroy()
        end
    end

    local adornee = v.Adornee
    if not adornee then return end
    
    local start = adornee.Position
    local layers = {}
    local alreadygot = {}
    
    scanSide(adornee, start, layers)
    scanSide(adornee, start + Vector3.new(0, 0, 3), layers)
    
    for block, amount in pairs(layers) do
        table.insert(alreadygot, {block, amount})
    end
    
    table.sort(alreadygot, function(a, b)
        local healthA, healthB = getBlockLayerHealth(a[1]), getBlockLayerHealth(b[1])
        return healthA == healthB and a[1] < b[1] or healthA > healthB
    end)
    
    v.Enabled = #alreadygot > 0

    -- Build the elements exactly matching the TumbaV6 format
    for _, blockData in ipairs(alreadygot) do
        local block, amount = blockData[1], blockData[2]
        
        local blockimage = Instance.new("ImageLabel")
        blockimage.Size = UDim2.fromOffset(32, 32)
        blockimage.BackgroundTransparency = 1
        blockimage.Image = getBlockIcon(block)
        blockimage.Parent = v.Frame
    end
end

local function refreshAll()
    for _, v in pairs(Reference) do
        pcall(refreshAdornee, v)
    end
end

-- EXACT TumbaV6 Added implementation
local function Added(v)
    if not v then return end
    if Reference[v] then return end
    
    local root = v:IsA("Model") and v.PrimaryPart or v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
    if not root then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Parent = Folder
    billboard.Name = "bed"
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    billboard.Size = UDim2.fromOffset(36, 36)
    billboard.AlwaysOnTop = true
    billboard.ClipsDescendants = false
    billboard.Adornee = root
    
    -- Exact Blur shadow placement as child of billboard
    local blur = addBlur(billboard)
    blur.Visible = States.Render.BedPlatesBackground
    
    -- Exact Frame placement
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30) -- Dark, beautiful Tumba style
    frame.BackgroundTransparency = States.Render.BedPlatesBackground and 0.5 or 1
    frame.Parent = billboard
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
    end)
    layout.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    Reference[v] = billboard
    pcall(refreshAdornee, billboard)
end

local function refreshNear(blockPart)
    if not blockPart or not blockPart.Position then return end
    local pos = blockPart.Position
    for i, v in pairs(Reference) do
        if i.Parent and (pos - i.Position).Magnitude <= 30 then
            pcall(refreshAdornee, v)
        end
    end
end

function Mega.Features.BedPlates.SetEnabled(state)
    States.Render.BedPlates = state
    
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    
    for _, obj in pairs(Reference) do
        pcall(function() obj:Destroy() end)
    end
    table.clear(Reference)
    
    if state then
        -- Add existing beds
        for _, bed in ipairs(Services.CollectionService:GetTagged("bed")) do
            pcall(Added, bed)
        end
        
        -- Listen for new beds
        table.insert(connections, Services.CollectionService:GetInstanceAddedSignal("bed"):Connect(function(v)
            pcall(Added, v)
        end))
        
        table.insert(connections, Services.CollectionService:GetInstanceRemovedSignal("bed"):Connect(function(v)
            if Reference[v] then
                Reference[v]:Destroy()
                Reference[v] = nil
            end
        end))
        
        -- Listen for blocks folder changes to trigger live refresh
        local blocksFolder = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Blocks") or game.Workspace:FindFirstChild("Blocks")
        if blocksFolder then
            table.insert(connections, blocksFolder.ChildAdded:Connect(function(child)
                task.wait(0.1)
                pcall(refreshNear, child)
            end))
            table.insert(connections, blocksFolder.ChildRemoved:Connect(function(child)
                pcall(refreshNear, child)
            end))
        end
        
        -- Background auto-refresh loop to ensure 100% accurate real-time block state
        task.spawn(function()
            while States.Render.BedPlates do
                pcall(refreshAll)
                task.wait(1)
            end
        end)
    end
end

-- Initialize on load
if States.Render.BedPlates then
    Mega.Features.BedPlates.SetEnabled(true)
end

return Mega.Features.BedPlates
