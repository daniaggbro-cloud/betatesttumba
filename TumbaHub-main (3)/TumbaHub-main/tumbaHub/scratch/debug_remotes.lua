-- debug_remotes.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rbxts = ReplicatedStorage:FindFirstChild("rbxts_include")
if not rbxts then print("❌ No rbxts_include") return end

local function findNetManaged(parent)
    local found = parent:FindFirstChild("_NetManaged")
    if found then return found end
    for _, child in pairs(parent:GetChildren()) do
        local res = findNetManaged(child)
        if res then return res end
    end
    return nil
end

local net = findNetManaged(rbxts)
if not net then print("❌ No _NetManaged") return end

print("✅ Found _NetManaged at: " .. net:GetFullName())
local drop = net:FindFirstChild("Inventory/DropItem")
if drop then
    print("✅ Found Inventory/DropItem - Type: " .. drop.ClassName)
else
    print("❌ Inventory/DropItem not found in _NetManaged")
    print("Listing children (first 10):")
    local children = net:GetChildren()
    for i = 1, math.min(10, #children) do
        print(" - " .. children[i].Name)
    end
end
