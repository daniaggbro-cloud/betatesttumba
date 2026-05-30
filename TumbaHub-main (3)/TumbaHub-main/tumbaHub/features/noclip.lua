-- features/noclip.lua
-- Logic for NoClip (Walking through walls)

if not Mega.Features then Mega.Features = {} end
Mega.Features.NoClip = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.NoClip == nil then States.Player.NoClip = false end

if not Mega.Objects.NoClipConnections then Mega.Objects.NoClipConnections = {} end
local connections = Mega.Objects.NoClipConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.NoClip.SetEnabled(state)
    States.Player.NoClip = state
    
    if state then
        connections.NoClipLoop = Services.RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if connections.NoClipLoop then
            connections.NoClipLoop:Disconnect()
            connections.NoClipLoop = nil
        end
    end
end

if States.Player.NoClip then
    Mega.Features.NoClip.SetEnabled(true)
end