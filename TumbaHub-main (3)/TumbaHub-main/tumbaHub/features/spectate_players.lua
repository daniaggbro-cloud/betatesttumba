-- features/spectate_players.lua
-- Logic for Spectate Player (Camera tracking)

if not Mega.Features then Mega.Features = {} end
Mega.Features.SpectatePlayers = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}
local States = Mega.States

if not Mega.Objects.SpectateConnections then Mega.Objects.SpectateConnections = {} end
local connections = Mega.Objects.SpectateConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.SpectatePlayers.StopSpectate()
    States.Player.SpectateTarget = nil
    Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("notify_spectate_stop"))
    end
end

connections.SpectateLoop = Services.RunService.Heartbeat:Connect(function()
    if States.Player.SpectateTarget then
        local target = States.Player.SpectateTarget
        if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                Services.Workspace.CurrentCamera.CFrame = targetRoot.CFrame * CFrame.new(0, 5, 15)
            end

            if target.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                Mega.Features.SpectatePlayers.StopSpectate()
            end
        else
            Mega.Features.SpectatePlayers.StopSpectate()
        end
    end
end)