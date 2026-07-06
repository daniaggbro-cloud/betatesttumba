-- features/fastbreak.lua
-- Fast Break module ported from Tumba V6
-- Decreases block hit cooldown

if not Mega.Features then Mega.Features = {} end
Mega.Features.FastBreak = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.FastBreak == nil then States.Player.FastBreak = false end
if States.Player.BreakSpeed == nil then States.Player.BreakSpeed = 3 end

local bedwars = {}
local lastHit = 0
local connections = {}
local active = false

local function initBedwars()
    if bedwars.BlockBreakController then return true end
    
    local success, err = pcall(function()
        local Knit
        
        -- Try 1: LocalPlayer.PlayerScripts.TS.knit
        local tsKnit = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("knit")
        if tsKnit then
            Knit = require(tsKnit).Knit
        end
        
        -- Try 2: ReplicatedStorage.rbxts_include.node_modules['@easy-games'].knit.src
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
        
        -- Try 3: Direct global/shared check
        if not Knit then
            Knit = getgenv().Knit or shared.Knit
        end
        
        if Knit then
            bedwars.BlockBreakController = Knit.Controllers.BlockBreakController
            bedwars.BlockBreaker = Knit.Controllers.BlockBreakController and Knit.Controllers.BlockBreakController.blockBreaker or nil
        else
            --warn("FastBreak: Knit client not found.")
        end
    end)
    
    if not success then
        --warn("FastBreak: initBedwars error: " .. tostring(err))
    end
    
    return bedwars.BlockBreakController ~= nil
end

local function cooldownLoop()
    active = true
    while States.Player.FastBreak do
        pcall(function()
            if (tick() - lastHit) > 0.3 then
                if initBedwars() then
                    local breaker = bedwars.BlockBreaker or (bedwars.BlockBreakController and bedwars.BlockBreakController.blockBreaker)
                    if breaker then
                        breaker:setCooldown(0.3)
                    end
                end
            end
        end)
        task.wait(0.1)
    end
    active = false
end

local function hookHitBlock()
    if not initBedwars() then 
        --warn("FastBreak: Cannot hook, controllers not loaded.")
        return 
    end
    if not bedwars.BlockBreaker then 
        --warn("FastBreak: Cannot hook, blockBreaker is nil.")
        return 
    end
    if connections.Hooked then return end

    connections.OldHitBlock = bedwars.BlockBreaker.hitBlock
    bedwars.BlockBreaker.hitBlock = function(self, ...)
        lastHit = tick()
        local args = {...}
        -- V6: local _, params = unpack({...})
        -- First argument in ... is args[1] which corresponds to '_' (block instance/position),
        -- Second argument is args[2] which corresponds to 'params' (ray parameters).
        local rayParams = args[2] 
        pcall(function()
            local selector = self.clientManager:getBlockSelector()
            local info = selector and selector:getMouseInfo(1, { ray = rayParams })
            local block = info and info.target and info.target.blockInstance or nil

            if block and block.Name ~= "bed" then
                local speed = States.Player.BreakSpeed or 3
                local cooldown = 0.3 / math.max(speed, 0.01)
                local breaker = bedwars.BlockBreaker or (bedwars.BlockBreakController and bedwars.BlockBreakController.blockBreaker)
                if breaker then
                    breaker:setCooldown(cooldown)
                end
            end
        end)

        return connections.OldHitBlock(self, ...)
    end
    connections.Hooked = true
    --print("✅ FastBreak: Successfully hooked hitBlock!")
end

local function unhookHitBlock()
    if connections.Hooked and connections.OldHitBlock then
        if bedwars.BlockBreaker then
            bedwars.BlockBreaker.hitBlock = connections.OldHitBlock
        end
        connections.OldHitBlock = nil
        connections.Hooked = false
        --print("❌ FastBreak: Unhooked hitBlock.")
    end
    pcall(function()
        if initBedwars() then
            local breaker = bedwars.BlockBreaker or (bedwars.BlockBreakController and bedwars.BlockBreakController.blockBreaker)
            if breaker then
                breaker:setCooldown(0.3)
            end
        end
    end)
end

function Mega.Features.FastBreak.SetEnabled(state)
    States.Player.FastBreak = state
    if state then
        hookHitBlock()
        if not active then
            task.spawn(cooldownLoop)
        end
    else
        unhookHitBlock()
    end
end

-- Initialize if enabled on load
if States.Player.FastBreak then
    Mega.Features.FastBreak.SetEnabled(true)
end

-- Cleanup if module reloaded or unloaded
if Mega.UnloadedSignal then
    connections.Unload = Mega.UnloadedSignal.Event:Connect(function()
        unhookHitBlock()
        if connections.Unload then
            connections.Unload:Disconnect()
        end
    end)
end

return Mega.Features.FastBreak
