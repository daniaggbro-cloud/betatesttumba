-- core/dumper.lua
-- Advanced Game Metadata Dumper for TumbaHub
-- Generates a packages.json file similar to CatV6

if not Mega.Dumper then Mega.Dumper = {} end

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dumper = {}
Mega.Dumper = Dumper

-- configuration: which paths to scan for metadata
local SCAN_PATHS = {
    ReplicatedStorage:WaitForChild("TS"),
    game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("TS")
}

-- helper to translate Roblox path to JSON key format
local function translatePath(obj)
    local path = obj:GetFullName()
    path = path:gsub("%.", "__")
    path = path:gsub("%:", "__")
    return path .. ".json"
end

-- the meat of the dumper: recursive scan
local function scanForConstants(parent, results)
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("ModuleScript") then
            -- Skip some very large or problematic modules if needed
            local success, data = pcall(function() return require(child) end)
            if success and type(data) == "table" then
                local key = translatePath(child)
                -- Clean the table a bit to avoid circular references/functions
                local cleaned = {}
                for k, v in pairs(data) do
                    if type(v) ~= "function" and type(v) ~= "userdata" then
                        cleaned[k] = v
                    end
                end
                results[key] = HttpService:JSONEncode(cleaned)
            end
        end
        -- Recursive call for folders
        if child:IsA("Folder") or child:IsA("Model") then
            scanForConstants(child, results)
        end
    end
end

-- Remote Mapping Scanner
local function scanRemotes()
    local remotes = {}
    
    -- Robust search for _NetManaged
    local netManaged = nil
    local rbxts = ReplicatedStorage:FindFirstChild("rbxts_include")
    if rbxts then
        -- Recursively find _NetManaged because some executors/versions change paths
        local function findNet(parent)
            local found = parent:FindFirstChild("_NetManaged")
            if found then return found end
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("Folder") then
                    local res = findNet(child)
                    if res then return res end
                end
            end
            return nil
        end
        netManaged = findNet(rbxts)
    end

    if netManaged then
        print("🔍 TumbaHub Dumper: Scanning " .. netManaged.Name .. " remotes...")
        for _, remote in pairs(netManaged:GetChildren()) do
            -- Generic mapping
            remotes[remote.Name] = remote.Name
            
            -- Specific keyword mapping for features
            local n = remote.Name:lower()
            if n:find("sword") or n:find("hit") then
                remotes["AttackEntity"] = remote.Name
            end
            if n:find("pickup") then
                remotes["PickupItem"] = remote.Name
            end
            if n:find("damage") and n:find("block") then
                remotes["MinerDig"] = remote.Name
            end
            if (n:find("shop") or n:find("purchase")) and n:find("item") then
                remotes["BedwarsShop_PurchaseItem"] = remote.Name
            end
        end
    end
    return remotes
end

-- MAIN DUMP FUNCTION
function Dumper.Execute()
    print("🚀 TumbaHub Dumper: Starting full game scan...")
    local finalJSON = {
        remotes = scanRemotes()
    }

    -- Scan defined paths
    for _, path in ipairs(SCAN_PATHS) do
        print("📂 TumbaHub Dumper: Scanning " .. path.Name .. "...")
        scanForConstants(path, finalJSON)
    end

    print("💾 TumbaHub Dumper: Encoding to JSON (this may take a moment)...")
    local success, encoded = pcall(function() 
        return HttpService:JSONEncode(finalJSON) 
    end)

    if success then
        if writefile then
            local path = "tumbaHub/packages.json"
            writefile(path, encoded)
            print("✅ TumbaHub Dumper: Success! Saved to '" .. path .. "'")
            print("📊 Total Size: " .. string.format("%.2f", #encoded / 1024 / 1024) .. " MB")
        else
            warn("❌ TumbaHub Dumper: 'writefile' not supported by your executor.")
        end
    else
        warn("❌ TumbaHub Dumper: Failed to encode JSON. Error: " .. tostring(encoded))
    end
end

-- Export to global
Mega.DumpGameData = Dumper.Execute

print("🛠 TumbaHub Dumper: Module loaded. Use 'Mega.DumpGameData()' to start.")

return Dumper
