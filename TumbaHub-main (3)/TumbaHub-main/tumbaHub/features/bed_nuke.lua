-- features/bed_nuke.lua
-- Breaker - EXACT replica of the TumbaV6 / Vape Bed Breaker & Nuker module
-- Automatically breaks beds, lucky blocks, beehives, iron ores, and tesla traps around you

if not Mega.Features then Mega.Features = {} end
Mega.Features.BedNuke = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Ensure settings exist exactly matching TumbaV6
if not States.Combat then States.Combat = {} end
if type(States.Combat.BedNuke) ~= "table" then
    States.Combat.BedNuke = {
        Enabled = false,
        Sorting = "Health",
        Range = 25,
        BreakSpeed = 0.25,
        MaxAngle = 360,
        UpdateRate = 60,
        BreakBed = true,
        BreakTesla = true,
        BreakHive = true,
        BreakLuckyBlock = true,
        BreakIronOre = true,
        LimitItem = false,
        SelfBreak = false,
        InstantBreak = false
    }
end

local DamageBlockRemote = Mega.GetRemote("MinerDig")
task.spawn(function()
    while task.wait(5) do
        if not DamageBlockRemote then
            DamageBlockRemote = Mega.GetRemote("MinerDig")
        end
    end
end)

local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}
local active = false

local function attemptBreak(tab, localPosition)
    if not tab then return false end
    
    local myTeam = LocalPlayer:GetAttribute("Team")
    local validTargets = {}
    
    for _, v in ipairs(tab) do
        if v and v.Parent then
            local pos = v:IsA("Model") and (v.PrimaryPart and v.PrimaryPart.Position or v:GetPivot().Position) or v.Position
            local dist = (pos - localPosition).Magnitude
            if dist < States.Combat.BedNuke.Range then
                -- Self break check for traps / hives
                local plId = v:GetAttribute("PlacedByUserId")
                if plId == LocalPlayer.UserId and not States.Combat.BedNuke.SelfBreak then
                    continue
                end
                
                -- Check for own bed protection
                if v.Name == "bed" and (v:GetAttribute("TeamId") == myTeam or v:GetAttribute("Team") == myTeam) then
                    continue
                end
                
                table.insert(validTargets, {Instance = v, Position = pos, Distance = dist})
            end
        end
    end
    
    if #validTargets == 0 then return false end
    
    -- Sorting
    if States.Combat.BedNuke.Sorting == "Distance" then
        table.sort(validTargets, function(a, b)
            return a.Distance < b.Distance
        end)
    end
    
    local target = validTargets[1]
    local dpos = Vector3.new(
        math.round(target.Position.X / 3),
        math.round(target.Position.Y / 3),
        math.round(target.Position.Z / 3)
    )
    
    local posArg = vector.create(dpos.X, dpos.Y, dpos.Z)
    local hitPosArg = vector.create(target.Position.X, target.Position.Y, target.Position.Z)
    
    local args = {
        {
            ["blockRef"] = {
                ["blockPosition"] = posArg
            },
            ["hitPosition"] = hitPosArg,
            ["hitNormal"] = vector.create(0, 1, 0)
        }
    }
    
    pcall(function()
        if DamageBlockRemote:IsA("RemoteEvent") then
            DamageBlockRemote:FireServer(unpack(args))
        elseif DamageBlockRemote:IsA("RemoteFunction") then
            DamageBlockRemote:InvokeServer(unpack(args))
        end
    end)
    
    return true
end

local function breakerLoop()
    active = true
    
    while States.Combat.BedNuke.Enabled do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and DamageBlockRemote then
            local localPosition = hrp.Position
            
            -- Query tagged items matching TumbaV6 collections
            local beds = States.Combat.BedNuke.BreakBed and Services.CollectionService:GetTagged("bed") or {}
            local teslas = States.Combat.BedNuke.BreakTesla and Services.CollectionService:GetTagged("tesla-trap") or {}
            local hives = States.Combat.BedNuke.BreakHive and Services.CollectionService:GetTagged("beehive") or {}
            local luckyblocks = States.Combat.BedNuke.BreakLuckyBlock and Services.CollectionService:GetTagged("LuckyBlock") or {}
            local ironores = States.Combat.BedNuke.BreakIronOre and Services.CollectionService:GetTagged("iron_ore_mesh_block") or {}
            
            local broken = false
            if attemptBreak(teslas, localPosition) then broken = true end
            if not broken and attemptBreak(beds, localPosition) then broken = true end
            if not broken and attemptBreak(hives, localPosition) then broken = true end
            if not broken and attemptBreak(luckyblocks, localPosition) then broken = true end
            if not broken and attemptBreak(ironores, localPosition) then broken = true end
            
            if broken then
                task.wait(States.Combat.BedNuke.InstantBreak and 0.05 or States.Combat.BedNuke.BreakSpeed)
            end
        end
        task.wait(1 / States.Combat.BedNuke.UpdateRate)
    end
    
    active = false
end

function Mega.Features.BedNuke.SetEnabled(state)
    States.Combat.BedNuke.Enabled = state
    
    if state then
        if not active then
            task.spawn(breakerLoop)
        end
    end
end

if States.Combat.BedNuke.Enabled then
    Mega.Features.BedNuke.SetEnabled(true)
end

return Mega.Features.BedNuke
