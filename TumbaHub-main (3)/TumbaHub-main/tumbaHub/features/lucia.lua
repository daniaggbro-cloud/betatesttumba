-- features/lucia.lua
-- Logic for Lucia (Pinata) Auto Deposit

if not Mega.Features then Mega.Features = {} end
Mega.Features.Lucia = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService")
}
local States = Mega.States

if States.Lucia == nil then
    States.Lucia = { Enabled = false, AutoDeposit = false }
end

if not Mega.Objects.LuciaConnections then Mega.Objects.LuciaConnections = {} end
local connections = Mega.Objects.LuciaConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local DepositPinataRemote
task.spawn(function()
    pcall(function()
        local netManaged = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
        DepositPinataRemote = netManaged:FindFirstChild("DepositCoins") or netManaged:FindFirstChild("DepositPinata")
    end)
end)

local lastCheck = 0
connections.AutoDepositLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Lucia.Enabled or not States.Lucia.AutoDeposit then return end
    
    if tick() - lastCheck < 0.5 then return end
    lastCheck = tick()
    
    if DepositPinataRemote then
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
end)

function Mega.Features.Lucia.SetEnabled(state)
    States.Lucia.Enabled = state
end