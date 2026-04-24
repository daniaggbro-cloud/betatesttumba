-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) - Optimized for Performance
-- Removed Auto-Buy functionality

if not Mega.Features then Mega.Features = {} end
Mega.Features.Cletus = {}

-- Localize Services for speed
local Services = Mega.Services
local RunService = Services.RunService
local CollectionService = Services.CollectionService
local LocalPlayer = Services.LocalPlayer
local CoreGui = Services.CoreGui
local ReplicatedStorage = Services.ReplicatedStorage

local States = Mega.States
local Objects = Mega.Objects

if not Objects.CletusConnections then Objects.CletusConnections = {} end
local connections = Objects.CletusConnections

-- Disconnect old connections
for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

-- ESP Connections container
local espConnections = {}

-- Remote Cache
local CropHarvestRemote
local function GetHarvestRemote()
    if not CropHarvestRemote then
        CropHarvestRemote = Mega.GetRemote("HarvestCrop")
    end
    return CropHarvestRemote
end

-- Periodically re-check the remote (less frequently)
task.spawn(function()
    while task.wait(10) do
        CropHarvestRemote = Mega.GetRemote("HarvestCrop")
    end
end)

-- Vector helper
local vec3 = Vector3.new

-- Cletus ESP Setup
local cletusEspFolder = CoreGui:FindFirstChild("CletusESP")
if not cletusEspFolder then
    cletusEspFolder = Instance.new("Folder")
    cletusEspFolder.Name = "CletusESP"
    cletusEspFolder.Parent = CoreGui
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
            
            local stage = crop:GetAttribute("CropStage")
            local espName = crop:GetDebugId()
            local existing = cletusEspFolder:FindFirstChild(espName)

            if stage and stage >= 3 then
                if not existing then
                    task.defer(function() -- Optimization: Defer creation
                        if not crop.Parent then return end
                        local esp = Instance.new("BoxHandleAdornment")
                        esp.Name = espName
                        esp.Adornee = crop
                        esp.Size = crop.Size + vec3(0.1, 0.1, 0.1)
                        
                        local lowerName = crop.Name:lower()
                        local color = vec3(0, 255, 0)
                        if lowerName:find("carrot") then
                            color = Color3.fromRGB(255, 170, 0)
                        elseif lowerName:find("melon") then
                            color = Color3.fromRGB(170, 255, 127)
                        else
                            color = Color3.fromRGB(0, 255, 0)
                        end
                        
                        esp.Color3 = color
                        esp.AlwaysOnTop = true
                        esp.ZIndex = 5
                        esp.Transparency = States.Cletus.ESPTransparency
                        esp.Parent = cletusEspFolder
                    end)
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

        local addedConn = CollectionService:GetInstanceAddedSignal("Crop"):Connect(onCropAdded)
        table.insert(espConnections, addedConn)

        -- Initial scan (Optimized)
        local allCrops = CollectionService:GetTagged("Crop")
        for i = 1, #allCrops do
            onCropAdded(allCrops[i])
            if i % 10 == 0 then task.wait() end -- Prevent spike
        end
    end
end

local function UpdateCletusTransparency()
    local transparency = States.Cletus.ESPTransparency
    for _, h in ipairs(cletusEspFolder:GetChildren()) do
        if h:IsA("BoxHandleAdornment") then
            h.Transparency = transparency
        end
    end
end

-- Optimized Harvest Loop (Polling instead of Heartbeat)
local function StartHarvestLoop()
    if connections.AutoHarvestLoop then 
        connections.AutoHarvestLoop = false -- Signal to stop
    end
    
    connections.AutoHarvestLoop = true
    
    task.spawn(function()
        print("[Cletus] Optimized Loop started")
        while connections.AutoHarvestLoop and States.Cletus.Enabled do
            if States.Cletus.AutoHarvest then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local playerPos = hrp.Position
                    local maxDist = States.Cletus.Range
                    local remote = GetHarvestRemote()
                    
                    if remote then
                        local crops = CollectionService:GetTagged("Crop")
                        for i = 1, #crops do
                            local crop = crops[i]
                            if crop:IsA("BasePart") then
                                local stage = crop:GetAttribute("CropStage")
                                if stage and stage >= 3 then
                                    local cropPos = crop.Position
                                    local dist = (playerPos - cropPos).Magnitude
                                    if dist <= maxDist then
                                        -- Calculate grid position
                                        local bx = math.round(cropPos.X / 3)
                                        local by = math.round(cropPos.Y / 3)
                                        local bz = math.round(cropPos.Z / 3)
                                        
                                        task.spawn(function()
                                            pcall(function() 
                                                remote:InvokeServer({
                                                    ["position"] = vec3(bx, by, bz)
                                                })
                                            end)
                                        end)
                                    end
                                end
                            end
                            -- Yield every few crops if the list is huge
                            if i % 20 == 0 then task.wait() end
                        end
                    end
                end
            end
            task.wait(0.5) -- Check twice per second, plenty for farming
        end
        print("[Cletus] Loop stopped")
    end)
end

-- Public API
function Mega.Features.Cletus.SetEnabled(state) 
    States.Cletus.Enabled = state 
    EnableCletusESP()
    if state then
        StartHarvestLoop()
    else
        connections.AutoHarvestLoop = false
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
