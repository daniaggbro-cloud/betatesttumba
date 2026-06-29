-- features/freecam.lua
-- Freecam - Lets you fly and clip through walls freely without moving your player server-sided

if not Mega.Features then Mega.Features = {} end
Mega.Features.Freecam = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ContextActionService = game:GetService("ContextActionService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if not States.Player.Freecam then
    States.Player.Freecam = {
        Enabled = false,
        Speed = 50
    }
end

local randomkey = Services.HttpService:GenerateGUID(false)
local module, old
local camPos = Vector3.zero
local gameCamera = Services.Workspace.CurrentCamera
local connection

local function initCameraModule()
    if module then return true end
    
    pcall(function()
        local getconnections = getconnections or get_signal_cons
        if getconnections then
            for _, v in ipairs(getconnections(gameCamera:GetPropertyChangedSignal('CameraType'))) do
                if v.Function then
                    local up = debug.getupvalue(v.Function, 1)
                    if type(up) == "table" and up.activeCameraController then
                        module = up
                        break
                    end
                end
            end
        end
    end)
    
    return module ~= nil
end

local function enableFreecam()
    if not initCameraModule() then 
        -- Fallback if getconnections/debug library is not fully supported
        warn("Freecam: CameraModule not resolved.")
    end
    
    if module and module.activeCameraController then
        old = module.activeCameraController.GetSubjectPosition
        camPos = old(module.activeCameraController) or Vector3.zero
        module.activeCameraController.GetSubjectPosition = function()
            return camPos
        end
    else
        camPos = gameCamera.CFrame.Position
    end
    
    -- Disable local player controls to prevent movement
    local playerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
    if playerModule then
        pcall(function()
            local controls = require(playerModule)
            if controls and controls.Disable then
                controls:Disable()
            elseif controls and controls.GetControls then
                local ctrl = controls:GetControls()
                if ctrl and ctrl.Disable then
                    ctrl:Disable()
                end
            end
        end)
    end
    
    -- Anchor HumanoidRootPart to freeze physics
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = true
    end
    
    -- Keyboard and movement binding loop
    connection = Services.RunService.PreSimulation:Connect(function(dt)
        if not Services.UserInputService:GetFocusedTextBox() then
            local forward = (Services.UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (Services.UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local side = (Services.UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + (Services.UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
            local up = (Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0) + (Services.UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
            dt = dt * (Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 0.25 or 1)
            
            local speed = States.Player.Freecam.Speed or 50
            local moveDir = Vector3.new(side, up, forward) * (speed * dt)
            
            camPos = (CFrame.lookAlong(camPos, gameCamera.CFrame.LookVector) * CFrame.new(moveDir)).Position
            
            if not module then
                gameCamera.CFrame = CFrame.new(camPos) * (gameCamera.CFrame - gameCamera.CFrame.Position)
            end
        end
    end)
    
    -- Bind keys to sink action to freeze local player character
    pcall(function()
        Services.ContextActionService:BindActionAtPriority(
            'FreecamKeyboard'..randomkey, 
            function()
                return Enum.ContextActionResult.Sink
            end, 
            false, 
            Enum.ContextActionPriority.High.Value,
            Enum.KeyCode.W,
            Enum.KeyCode.A,
            Enum.KeyCode.S,
            Enum.KeyCode.D,
            Enum.KeyCode.E,
            Enum.KeyCode.Q,
            Enum.KeyCode.Up,
            Enum.KeyCode.Down
        )
    end)
end

local function disableFreecam()
    pcall(function()
        Services.ContextActionService:UnbindAction('FreecamKeyboard'..randomkey)
    end)
    
    -- Re-enable local player controls
    local playerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
    if playerModule then
        pcall(function()
            local controls = require(playerModule)
            if controls and controls.Enable then
                controls:Enable()
            elseif controls and controls.GetControls then
                local ctrl = controls:GetControls()
                if ctrl and ctrl.Enable then
                    ctrl:Enable()
                end
            end
        end)
    end
    
    -- Unanchor HumanoidRootPart
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if module and old then
        module.activeCameraController.GetSubjectPosition = old
        module = nil
        old = nil
    end
end

function Mega.Features.Freecam.SetEnabled(state)
    States.Player.Freecam.Enabled = state
    if state then
        enableFreecam()
    else
        disableFreecam()
    end
end

if States.Player.Freecam.Enabled then
    Mega.Features.Freecam.SetEnabled(true)
end

if Mega.UnloadedSignal then
    Mega.UnloadedSignal:Connect(function()
        disableFreecam()
    end)
end

return Mega.Features.Freecam
