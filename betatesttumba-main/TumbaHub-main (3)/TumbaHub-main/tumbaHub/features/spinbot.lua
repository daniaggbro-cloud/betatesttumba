-- features/spinbot.lua
-- Logic for SpinBot

if not Mega.Features then Mega.Features = {} end
Mega.Features.SpinBot = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.SpinBot == nil then States.Player.SpinBot = false end
if States.Player.SpinSpeed == nil then States.Player.SpinSpeed = 10 end

if not Mega.Objects.SpinBotConnections then Mega.Objects.SpinBotConnections = {} end
local connections = Mega.Objects.SpinBotConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.SpinBot.SetEnabled(state)
    States.Player.SpinBot = state
    
    if state then
        connections.SpinBotLoop = Services.RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local spinSpeed = States.Player.SpinSpeed or 10
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
            end
        end)
    else
        if connections.SpinBotLoop then
            connections.SpinBotLoop:Disconnect()
            connections.SpinBotLoop = nil
        end
    end
end

if States.Player.SpinBot then
    Mega.Features.SpinBot.SetEnabled(true)
end