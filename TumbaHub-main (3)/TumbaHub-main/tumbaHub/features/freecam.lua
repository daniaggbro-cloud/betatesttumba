-- features/freecam.lua
-- Robust Freecam implementation

Mega.Features.Freecam = {}

local Services = Mega.Services
local States = Mega.States

if not States.Player then States.Player = {} end
if not States.Player.Freecam then
    States.Player.Freecam = {
        Enabled = false,
        Speed = 50
    }
end

local camera = Services.Workspace.CurrentCamera
local connection
local inputConn
local isEnabled = false

local moveKeys = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
    [Enum.KeyCode.E] = false,
    [Enum.KeyCode.Q] = false,
}

local cameraPos = Vector3.zero
local cameraRot = Vector2.zero

local function enableFreecam()
    if isEnabled then return end
    isEnabled = true
    
    camera = Services.Workspace.CurrentCamera
    
    local char = Services.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = true
    end
    
    camera.CameraType = Enum.CameraType.Scriptable
    cameraPos = camera.CFrame.Position
    local x, y, z = camera.CFrame:ToEulerAnglesYXZ()
    cameraRot = Vector2.new(x, y)
    
    Mega.Objects.Connections.FreecamIB = Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if moveKeys[input.KeyCode] ~= nil then moveKeys[input.KeyCode] = true end
    end)
    
    Mega.Objects.Connections.FreecamIE = Services.UserInputService.InputEnded:Connect(function(input, gp)
        if moveKeys[input.KeyCode] ~= nil then moveKeys[input.KeyCode] = false end
    end)
    
    Mega.Objects.Connections.FreecamIC = Services.UserInputService.InputChanged:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Delta
            cameraRot = cameraRot + Vector2.new(-delta.Y, -delta.X) * 0.005
            -- Limit pitch
            cameraRot = Vector2.new(math.clamp(cameraRot.X, -math.rad(90), math.rad(90)), cameraRot.Y)
        end
    end)
    
    connection = Services.RunService.RenderStepped:Connect(function(dt)
        local speed = States.Player.Freecam.Speed or 50
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            speed = speed * 0.25
        end
        
        local camCFrame = CFrame.new(cameraPos) * CFrame.Angles(0, cameraRot.Y, 0) * CFrame.Angles(cameraRot.X, 0, 0)
        
        local lookVector = camCFrame.LookVector
        local rightVector = camCFrame.RightVector
        local upVector = camCFrame.UpVector
        
        local moveDir = Vector3.zero
        if moveKeys[Enum.KeyCode.W] then moveDir = moveDir + lookVector end
        if moveKeys[Enum.KeyCode.S] then moveDir = moveDir - lookVector end
        if moveKeys[Enum.KeyCode.D] then moveDir = moveDir + rightVector end
        if moveKeys[Enum.KeyCode.A] then moveDir = moveDir - rightVector end
        if moveKeys[Enum.KeyCode.E] then moveDir = moveDir + upVector end
        if moveKeys[Enum.KeyCode.Q] then moveDir = moveDir - upVector end
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            cameraPos = cameraPos + (moveDir * speed * dt)
        end
        
        camera.CFrame = CFrame.new(cameraPos) * CFrame.Angles(0, cameraRot.Y, 0) * CFrame.Angles(cameraRot.X, 0, 0)
    end)
end

local function disableFreecam()
    isEnabled = false
    
    if connection then connection:Disconnect(); connection = nil end
    if Mega.Objects.Connections.FreecamIB then Mega.Objects.Connections.FreecamIB:Disconnect() end
    if Mega.Objects.Connections.FreecamIE then Mega.Objects.Connections.FreecamIE:Disconnect() end
    if Mega.Objects.Connections.FreecamIC then Mega.Objects.Connections.FreecamIC:Disconnect() end
    
    -- Reset keys
    for k, v in pairs(moveKeys) do moveKeys[k] = false end
    
    local char = Services.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = false
    end
    
    camera = Services.Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = char and char:FindFirstChild("Humanoid")
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
    Mega.UnloadedSignal.Event:Connect(function()
        disableFreecam()
    end)
end

return Mega.Features.Freecam
