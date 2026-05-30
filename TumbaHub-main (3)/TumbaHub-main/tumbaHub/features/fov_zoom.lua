-- features/fov_zoom.lua
-- Advanced FOV controller and Zoom keybind for TumbaHub

if not Mega.Features then Mega.Features = {} end
Mega.Features.FOVZoom = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Visuals then States.Visuals = {} end
if not States.Visuals.FOVZoom then
    States.Visuals.FOVZoom = {
        Enabled = false,
        FOV = 70,
        ZoomEnabled = false,
        ZoomKey = "C",
        ZoomFOV = 30
    }
end

local FovController
local oldSetFOV
local oldGetFOV
local connections = {}
local isZoomed = false

local function getFovController()
    if FovController then return FovController end
    pcall(function()
        local TS = Services.ReplicatedStorage:FindFirstChild("TS")
        local controllers = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("controllers")
        local globalFolder = controllers and controllers:FindFirstChild("global")
        local fovFolder = globalFolder and globalFolder:FindFirstChild("fov")
        local fovControllerFile = fovFolder and fovFolder:FindFirstChild("fov-controller")
        if fovControllerFile then
            FovController = require(fovControllerFile).FovController
        end
    end)
    return FovController
end

local function updateFov()
    local controller = getFovController()
    if controller then
        local targetFOV = States.Visuals.FOVZoom.FOV
        if isZoomed then
            targetFOV = States.Visuals.FOVZoom.ZoomFOV
        end
        
        pcall(function()
            local camera = Services.Workspace.CurrentCamera
            if camera then
                camera.FieldOfView = targetFOV
            end
        end)
    end
end

function Mega.Features.FOVZoom.SetEnabled(state)
    States.Visuals.FOVZoom.Enabled = state
    
    local controller = getFovController()
    if state then
        if controller then
            if not oldSetFOV then
                oldSetFOV = controller.setFOV
                oldGetFOV = controller.getFOV
            end
            
            controller.setFOV = function(self)
                local target = States.Visuals.FOVZoom.FOV
                if isZoomed then
                    target = States.Visuals.FOVZoom.ZoomFOV
                end
                pcall(function()
                    local camera = Services.Workspace.CurrentCamera
                    if camera then camera.FieldOfView = target end
                end)
                return target
            end
            
            controller.getFOV = function()
                local target = States.Visuals.FOVZoom.FOV
                if isZoomed then
                    target = States.Visuals.FOVZoom.ZoomFOV
                end
                return target
            end
            
            pcall(function()
                controller:setFOV(States.Visuals.FOVZoom.FOV)
            end)
        end
        
        -- Set up Keybind listener for Zoom
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        table.clear(connections)
        
        table.insert(connections, Services.UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if States.Visuals.FOVZoom.ZoomEnabled and input.KeyCode.Name == States.Visuals.FOVZoom.ZoomKey and States.Visuals.FOVZoom.ZoomKey ~= "None" then
                isZoomed = true
                updateFov()
            end
        end))
        
        table.insert(connections, Services.UserInputService.InputEnded:Connect(function(input)
            if States.Visuals.FOVZoom.ZoomEnabled and input.KeyCode.Name == States.Visuals.FOVZoom.ZoomKey and States.Visuals.FOVZoom.ZoomKey ~= "None" then
                isZoomed = false
                updateFov()
            end
        end))
        
        -- RenderStepped to enforce FOV constantly
        table.insert(connections, Services.RunService.RenderStepped:Connect(function()
            updateFov()
        end))
    else
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        table.clear(connections)
        isZoomed = false
        
        if controller and oldSetFOV then
            controller.setFOV = oldSetFOV
            controller.getFOV = oldGetFOV
            pcall(function()
                local TS = Services.ReplicatedStorage:FindFirstChild("TS")
                local storeFile = TS and TS:FindFirstChild("store")
                if storeFile then
                    local store = require(storeFile).ClientStore
                    if store then
                        controller:setFOV(store:getState().Settings.fov or 70)
                    end
                end
            end)
        end
        
        pcall(function()
            local camera = Services.Workspace.CurrentCamera
            if camera then camera.FieldOfView = 70 end
        end)
    end
end

-- Initialize if enabled in config
if States.Visuals.FOVZoom.Enabled then
    Mega.Features.FOVZoom.SetEnabled(true)
end

return Mega.Features.FOVZoom
