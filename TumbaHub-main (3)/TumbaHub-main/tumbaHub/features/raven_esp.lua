-- features/raven_esp.lua
-- Raven ESP logic

Mega.Features.RavenESP = {}

local Services = Mega.Services
local States = Mega.States

if not States.RavenESP then
    States.RavenESP = {
        Enabled = false,
        ShowHighlight = true,
        HighlightColor = Color3.fromRGB(150, 0, 255)
    }
end
local RavenESPState = States.RavenESP

if not Mega.Objects.RavenCache then Mega.Objects.RavenCache = {} end
local ravenCache = Mega.Objects.RavenCache
local connections = Mega.Objects.Connections

local function IsTargetRaven(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    -- Check if it's named Raven and inside the Ravens folder
    if string.lower(obj.Name) == "raven" then
        if obj.Parent and string.lower(obj.Parent.Name) == "ravens" then
            return true
        end
    end
    return false
end

local function UpdateRavenESP(obj)
    if not obj or not obj.Parent then return end
    
    -- Clean up if disabled or not target
    if not RavenESPState.Enabled or not IsTargetRaven(obj) then
        if obj:FindFirstChild("RavenHighlight") then obj.RavenHighlight:Destroy() end
        ravenCache[obj] = nil
        return
    end

    local hl = obj:FindFirstChild("RavenHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "RavenHighlight"
        hl.Adornee = obj
        hl.Parent = obj
        hl.FillColor = RavenESPState.HighlightColor or Color3.fromRGB(150, 0, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end
    if hl then 
        hl.Enabled = RavenESPState.ShowHighlight 
        hl.FillColor = RavenESPState.HighlightColor or Color3.fromRGB(150, 0, 255)
    end

    if not ravenCache[obj] then
        ravenCache[obj] = true
    end
end

local function ClearRavenESP()
    for raven, _ in pairs(ravenCache) do
        if raven and raven.Parent then
            if raven:FindFirstChild("RavenHighlight") then raven.RavenHighlight:Destroy() end
        end
    end
    table.clear(ravenCache)
end

local function PopulateRavenCache()
    ClearRavenESP()
    if not RavenESPState.Enabled then return end

    local ravensFolder = Services.Workspace:FindFirstChild("Ravens")
    if ravensFolder then
        for _, obj in ipairs(ravensFolder:GetChildren()) do
            if IsTargetRaven(obj) then
                UpdateRavenESP(obj)
            end
        end
    end
end

function Mega.Features.RavenESP.SetEnabled(state)
    RavenESPState.Enabled = state
    
    if state then
        PopulateRavenCache()
        
        if not connections.RavenFolderAdded then
            connections.RavenFolderAdded = Services.Workspace.ChildAdded:Connect(function(child)
                if string.lower(child.Name) == "ravens" and RavenESPState.Enabled then
                    if not connections.RavenAdded then
                        connections.RavenAdded = child.ChildAdded:Connect(function(descendant)
                            if RavenESPState.Enabled and IsTargetRaven(descendant) then
                                UpdateRavenESP(descendant)
                            end
                        end)
                    end
                end
            end)
        end
        
        -- In case Ravens folder already exists
        local ravensFolder = Services.Workspace:FindFirstChild("Ravens")
        if ravensFolder and not connections.RavenAdded then
            connections.RavenAdded = ravensFolder.ChildAdded:Connect(function(descendant)
                if RavenESPState.Enabled and IsTargetRaven(descendant) then
                    UpdateRavenESP(descendant)
                end
            end)
        end
        
        if not connections.RavenRemoving then
            connections.RavenRemoving = Services.Workspace.DescendantRemoving:Connect(function(descendant)
                if ravenCache[descendant] then
                    ravenCache[descendant] = nil
                end
            end)
        end
    else
        ClearRavenESP()
    end
end

function Mega.Features.RavenESP.UpdateVisuals()
    if not RavenESPState.Enabled then return end
    
    for raven, _ in pairs(ravenCache) do
        UpdateRavenESP(raven)
    end
end

if RavenESPState.Enabled then
    Mega.Features.RavenESP.SetEnabled(true)
end
