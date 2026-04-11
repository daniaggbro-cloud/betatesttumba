-- features/lucia.lua
-- Logic for Lucia (Pinata) Auto Deposit

if not Mega.Features then Mega.Features = {} end
Mega.Features.Lucia = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    CollectionService = game:GetService("CollectionService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if States.Lucia == nil then
    States.Lucia = { Enabled = false, AutoDeposit = false, Range = 20 }
elseif States.Lucia.Range == nil then
    States.Lucia.Range = 20
end

if not Mega.Objects.LuciaConnections then Mega.Objects.LuciaConnections = {} end
local connections = Mega.Objects.LuciaConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local DepositPinataRemote = Mega.GetRemote("DepositPinata")
task.spawn(function()
    while task.wait(5) do
        if not DepositPinataRemote then
            DepositPinataRemote = Mega.GetRemote("DepositPinata")
        end
    end
end)

local lastCheck = 0
connections.AutoDepositLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Lucia.Enabled or not States.Lucia.AutoDeposit then return end
    if not DepositPinataRemote then return end
    
    if tick() - lastCheck < 0.5 then return end
    lastCheck = tick()
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local pinatas = Services.CollectionService:GetTagged("piggy-bank")
    for _, pinata in ipairs(pinatas) do
        local pinataPart = pinata:IsA("BasePart") and pinata or pinata.PrimaryPart or pinata:FindFirstChildWhichIsA("BasePart", true)
        if pinataPart then
            local dist = (root.Position - pinataPart.Position).Magnitude
            if dist <= States.Lucia.Range then
                task.spawn(function()
                    pcall(function()
                        if DepositPinataRemote:IsA("RemoteEvent") then
                            DepositPinataRemote:FireServer()
                        elseif DepositPinataRemote:IsA("RemoteFunction") then
                            DepositPinataRemote:InvokeServer()
                        end
                    end)
                end)
            end
        end
    end
end)

function Mega.Features.Lucia.SetEnabled(state)
    States.Lucia.Enabled = state
end