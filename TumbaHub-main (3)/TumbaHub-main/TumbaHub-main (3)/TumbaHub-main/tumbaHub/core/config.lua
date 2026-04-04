-- core/config.lua
-- Configuration save/load system (JSON-based)

Mega.ConfigSystem = {}

local HttpService = Mega.Services.HttpService

function Mega.ConfigSystem.Sanitize(data)
    local copy = {}
    for k, v in pairs(data) do
        if type(v) == "table" then
            copy[k] = Mega.ConfigSystem.Sanitize(v)
        elseif typeof(v) == "Color3" then
            copy[k] = { _type = "Color3", R = v.R, G = v.G, B = v.B }
        elseif typeof(v) == "EnumItem" then
            copy[k] = { _type = "Enum", EnumType = tostring(v.EnumType), Name = v.Name }
        elseif typeof(v) == "Instance" then
            copy[k] = nil -- Don't save instances
        else
            copy[k] = v
        end
    end
    return copy
end

function Mega.ConfigSystem.Reconstruct(data)
    local copy = {}
    for k, v in pairs(data) do
        if type(v) == "table" then
            if v._type == "Color3" then
                copy[k] = Color3.new(v.R, v.G, v.B)
            elseif v._type == "Enum" then
                local success, result = pcall(function() return Enum[tostring(v.EnumType)][v.Name] end)
                if success then copy[k] = result else copy[k] = v.Name end
            else
                copy[k] = Mega.ConfigSystem.Reconstruct(v)
            end
        else
            copy[k] = v
        end
    end
    return copy
end

function Mega.ConfigSystem.Save(name)
    if not writefile then return false end
    
    if not isfolder("tumbaHub") then pcall(makefolder, "tumbaHub") end
    if not isfolder("tumbaHub/configs") then pcall(makefolder, "tumbaHub/configs") end

    local dataToSave = {
        Settings = Mega.Settings,
        States = Mega.States,
        Language = Mega.Localization.CurrentLanguage
    }
    
    local sanitizedData = Mega.ConfigSystem.Sanitize(dataToSave)
    local success, json = pcall(HttpService.JSONEncode, HttpService, sanitizedData)

    if not success then
        warn("Failed to encode config:", json)
        return false
    end
    
    pcall(writefile, "tumbaHub/configs/TumbaConfig_" .. name .. ".json", json)
    return true
end

function Mega.ConfigSystem.Load(name)
    if not readfile or not isfile then return false end
    
    local fileName = "tumbaHub/configs/TumbaConfig_" .. name .. ".json"
    if not isfile(fileName) then
        fileName = "TumbaConfig_" .. name .. ".json" -- Fallback to root directory
        if not isfile(fileName) then return false end
    end
    
    local success, json = pcall(readfile, fileName)
    if not success or not json then return false end
    
    local successDecode, decodedData = pcall(HttpService.JSONDecode, HttpService, json)
    if not successDecode or not decodedData then return false end
    
    local data = Mega.ConfigSystem.Reconstruct(decodedData)
    
    -- Safely merge loaded data into existing tables
    local function deepMerge(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" and not v._type then
                deepMerge(target[k], v)
            else
                target[k] = v
            end
        end
    end

    if data.Settings then deepMerge(Mega.Settings, data.Settings) end
    if data.States then deepMerge(Mega.States, data.States) end
    if data.Language and Mega.Localization then
        Mega.Localization.CurrentLanguage = data.Language
    end
    

    return true
end

function Mega.ConfigSystem.GetList()
    local list = {}
    if not listfiles then return list end

    local success, files = pcall(listfiles, "tumbaHub/configs")
    if not success then 
        success, files = pcall(listfiles, "") 
    end
    
    if not success then return list end
        
    for _, file in ipairs(files) do
        local filename = file:match("([^/\\]+)$") or file
        if filename:find("TumbaConfig_") and filename:find("%.json$") then
            local configName = filename:match("TumbaConfig_(.+)%.json")
            if configName then
                table.insert(list, configName)
            end
        end
    end
    
    return list
end
