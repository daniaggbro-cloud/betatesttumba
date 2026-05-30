-- features/trap_disabler.lua
-- Trap Disabler (Blocks Snap Traps) and Trap ESP for TumbaHub

if not Mega.Features then Mega.Features = {} end
Mega.Features.TrapDisabler = {}
Mega.Features.TrapESP = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Utility then States.Utility = {} end
if States.Utility.TrapDisabler == nil then States.Utility.TrapDisabler = false end

if not States.Render then States.Render = {} end
if States.Render.TrapESP == nil then States.Render.TrapESP = false end

local oldNamecall
local espConnections = {}
local trapBillboardObjects = {}

-- Create a folder in CoreGui to hold trap billboards
local container = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui

-- Trap Disabler Metamethod Hook
local function hookTrapRemote()
    if oldNamecall then return end
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            -- Block snap traps from registering our character stepping on them
            if States.Utility.TrapDisabler and self.Name == "StepOnSnapTrap" then
                return nil
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

function Mega.Features.TrapDisabler.SetEnabled(state)
    States.Utility.TrapDisabler = state
    if state then
        pcall(hookTrapRemote)
    end
end

-- Trap ESP implementation
local function addTrapESP(v)
    if not v or not v.Parent then return end
    
    local root = v:IsA("Model") and v.PrimaryPart or v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
    if not root then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TrapESP_Gui"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(36, 36)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = container
    
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    frame.BackgroundTransparency = 0.5
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local image = Instance.new("ImageLabel", frame)
    image.Size = UDim2.fromScale(0.8, 0.8)
    image.Position = UDim2.fromScale(0.1, 0.1)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://9166206875" -- Trapper/Snap Trap icon
    
    trapBillboardObjects[v] = billboard
    
    local conn
    conn = v.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if trapBillboardObjects[v] == billboard then trapBillboardObjects[v] = nil end
            billboard:Destroy()
            if conn then conn:Disconnect() end
        end
    end)
end

function Mega.Features.TrapESP.SetEnabled(state)
    States.Render.TrapESP = state
    
    for _, conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(espConnections)
    
    for _, obj in pairs(trapBillboardObjects) do pcall(function() obj:Destroy() end) end
    table.clear(trapBillboardObjects)
    
    if state then
        -- Add existing traps
        for _, trap in ipairs(Services.CollectionService:GetTagged("snap_trap")) do
            pcall(addTrapESP, trap)
        end
        
        -- Listen for new traps
        table.insert(espConnections, Services.CollectionService:GetInstanceAddedSignal("snap_trap"):Connect(function(v)
            pcall(addTrapESP, v)
        end))
        
        table.insert(espConnections, Services.CollectionService:GetInstanceRemovedSignal("snap_trap"):Connect(function(v)
            if trapBillboardObjects[v] then
                trapBillboardObjects[v]:Destroy()
                trapBillboardObjects[v] = nil
            end
        end))
    end
end

-- Initialize
if States.Utility.TrapDisabler then
    Mega.Features.TrapDisabler.SetEnabled(true)
end
if States.Render.TrapESP then
    Mega.Features.TrapESP.SetEnabled(true)
end

return Mega.Features.TrapDisabler
