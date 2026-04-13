-- core/metadata.lua
-- Dynamic Remote Mapping and Game Metadata System
-- Inspired by CatV6 implementation

if not Mega.Metadata then Mega.Metadata = {} end

local HttpService = game:GetService("HttpService")
local MetadataManager = {}
Mega.MetadataManager = MetadataManager

local jsonContent = nil

local baseURL = "https://raw.githubusercontent.com/daniaggbro-cloud/betatesttumba/main/TumbaHub-main%20(3)/TumbaHub-main/tumbaHub/"

-- Function to load metadata
function MetadataManager.Init()
    local fileName = "packages.json"
    local localPath = "tumbaHub/" .. fileName
    
    -- 1. Try local file first
    if isfile and readfile then
        if isfile(localPath) then
            print("📦 TumbaHub: Loading metadata from local file...")
            local success, data = pcall(function() return readfile(localPath) end)
            if success then jsonContent = data end
        end
    end
    
    -- 2. If no local file, try fetching from GitHub
    if not jsonContent then
        print("📦 TumbaHub: packages.json not found locally. Fetching from GitHub...")
        local success, data = pcall(function() return game:HttpGet(baseURL .. fileName) end)
        if success and data then
            jsonContent = data
            -- Cache it locally for next time
            if writefile then
                pcall(function() 
                    if not isfolder("tumbaHub") then makefolder("tumbaHub") end
                    writefile(localPath, data) 
                    print("✅ TumbaHub: Metadata cached locally.")
                end)
            end
        else
            warn("❌ TumbaHub: Failed to download metadata from GitHub.")
        end
    end
    
    if jsonContent then
        local success, decoded = pcall(function() return HttpService:JSONDecode(jsonContent) end)
        if success then
            Mega.Metadata = decoded
            print("✅ TumbaHub: Metadata loaded successfully!")
        else
            warn("❌ TumbaHub: Failed to parse packages.json")
        end
    end
end

-- Function to get a remote by internal name
function Mega.GetRemote(name)
    local actualName = name
    
    -- Check mapping in metadata
    if Mega.Metadata and Mega.Metadata.remotes then
        actualName = Mega.Metadata.remotes[name] or name
    end
    
    -- Search in _NetManaged (standard for BedWars)
    local netManaged = game:GetService("ReplicatedStorage"):FindFirstChild("rbxts_include")
    if netManaged then
        netManaged = netManaged:FindFirstChild("node_modules")
        if netManaged then
            netManaged = netManaged:FindFirstChild("@rbxts")
            if netManaged then
                netManaged = netManaged:FindFirstChild("net")
                if netManaged then
                   netManaged = netManaged:FindFirstChild("out")
                   if netManaged then
                       netManaged = netManaged:FindFirstChild("_NetManaged")
                   end
                end
            end
        end
    end

    if netManaged then
        local remote = netManaged:FindFirstChild(actualName)
        if remote then
            return remote
        end
    end
    
    -- Fallback: Search the whole ReplicatedStorage (slower)
    return game:GetService("ReplicatedStorage"):FindFirstChild(actualName, true)
end

-- Initialize immediately if module is loaded
MetadataManager.Init()

return MetadataManager
