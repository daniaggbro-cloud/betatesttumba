-- features/drone_esp.lua
-- Drone ESP logic

Mega.Features.DroneESP = {}

local Services = Mega.Services
local States = Mega.States

if not States.DroneESP then
    States.DroneESP = {
        Enabled = false,
        ShowIcons = true,
        ShowHighlight = true
    }
end
local DroneESPState = States.DroneESP

if not Mega.Objects.DroneCache then Mega.Objects.DroneCache = {} end
local droneCache = Mega.Objects.DroneCache
local connections = Mega.Objects.Connections

local function IsTargetDrone(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local name = string.lower(obj.Name)
    if name == "drone" or name == "cyber_dj_drone" then return true end
    return false
end

local function UpdateDroneESP(obj)
    if not obj or not obj.Parent then return end
    
    -- Clean up if disabled or not target
    if not DroneESPState.Enabled or not IsTargetDrone(obj) then
        if obj:FindFirstChild("DroneESP_Icon") then obj.DroneESP_Icon:Destroy() end
        if obj:FindFirstChild("DroneHighlight") then obj.DroneHighlight:Destroy() end
        droneCache[obj] = nil
        return
    end

    local icon = obj:FindFirstChild("DroneESP_Icon")
    if not icon then
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart")
        if root then
            local bg = Instance.new("BillboardGui")
            bg.Name = "DroneESP_Icon"
            bg.Adornee = root
            bg.Parent = obj
            bg.Size = UDim2.new(0, 50, 0, 50)
            bg.StudsOffset = Vector3.new(0, 6, 0)
            bg.AlwaysOnTop = true
            local img = Instance.new("ImageLabel")
            img.Parent = bg
            img.BackgroundTransparency = 1
            img.Size = UDim2.new(1, 0, 1, 0)
            img.Image = "rbxassetid://9507317177"
            img.ImageTransparency = 0.25
            icon = bg
        end
    end
    if icon then icon.Enabled = DroneESPState.ShowIcons end

    local hl = obj:FindFirstChild("DroneHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "DroneHighlight"
        hl.Adornee = obj
        hl.Parent = obj
        hl.FillColor = Color3.fromRGB(0, 255, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end
    if hl then hl.Enabled = DroneESPState.ShowHighlight end

    if not droneCache[obj] then
        droneCache[obj] = true
    end
end

local function ClearDroneESP()
    for drone, _ in pairs(droneCache) do
        if drone and drone.Parent then
            if drone:FindFirstChild("DroneESP_Icon") then drone.DroneESP_Icon:Destroy() end
            if drone:FindFirstChild("DroneHighlight") then drone.DroneHighlight:Destroy() end
        end
    end
    table.clear(droneCache)
end

local function PopulateDroneCache()
    ClearDroneESP()
    if not DroneESPState.Enabled then return end

    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if IsTargetDrone(obj) then
            UpdateDroneESP(obj)
        end
    end
end

function Mega.Features.DroneESP.SetEnabled(state)
    DroneESPState.Enabled = state
    
    if state then
        PopulateDroneCache()
        
        if not connections.DroneAdded then
            connections.DroneAdded = Services.Workspace.DescendantAdded:Connect(function(descendant)
                if DroneESPState.Enabled and IsTargetDrone(descendant) then
                    UpdateDroneESP(descendant)
                end
            end)
        end
        
        if not connections.DroneRemoving then
            connections.DroneRemoving = Services.Workspace.DescendantRemoving:Connect(function(descendant)
                if droneCache[descendant] then
                    droneCache[descendant] = nil
                end
            end)
        end
    else
        ClearDroneESP()
    end
end

function Mega.Features.DroneESP.UpdateVisuals()
    if not DroneESPState.Enabled then return end
    
    for drone, _ in pairs(droneCache) do
        UpdateDroneESP(drone)
    end
end

if DroneESPState.Enabled then
    Mega.Features.DroneESP.SetEnabled(true)
end
