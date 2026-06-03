-- features/staff_detector.lua
-- Staff Detector module ported from Tumba V6 (Universal version)

if not Mega.Features then Mega.Features = {} end
Mega.Features.StaffDetector = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    StarterGui = game:GetService("StarterGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
    GroupService = game:GetService("GroupService"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States
local TeleportService = game:GetService("TeleportService")

if not States.Utility then States.Utility = {} end
if not States.Utility.StaffDetector then
    States.Utility.StaffDetector = {
        Enabled = false,
        Mode = "Notify",
        Group = "",
        Role = "",
        Profile = "default",
        Users = ""
    }
end

local connections = {}
local visited = {}
local attempted = {}
local cacheExpire, cache = 0, nil
local tpSwitch = false

local function notif(title, text, duration, icon)
    if Mega.ShowNotification then
        Mega.ShowNotification(title .. ": " .. text, duration or 5)
    end
end

local function serverHop(pointer, filter)
    visited = shared.tumbahubserverhoplist and shared.tumbahubserverhoplist:split('/') or {}
    if not table.find(visited, game.JobId) then
        table.insert(visited, game.JobId)
    end
    if not pointer then
        notif('TumbaHub', 'Searching for an available server.', 2)
    end

    local filterType = filter or 'Descending'
    local success, httpdata = pcall(function()
        return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filterType == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100'..(pointer and '&cursor='..pointer or '')) or cache
    end)
    local data = success and Services.HttpService:JSONDecode(httpdata) or nil
    if data and data.data then
        for _, v in ipairs(data.data) do
            if tonumber(v.playing) < Services.Players.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
                cacheExpire, cache = tick() + 60, httpdata
                table.insert(attempted, v.id)

                notif('TumbaHub', 'Found! Teleporting.', 5)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                return
            end
        end

        if data.nextPageCursor then
            serverHop(data.nextPageCursor, filterType)
        else
            notif('TumbaHub', 'Failed to find an available server.', 5, 'warning')
        end
    else
        notif('TumbaHub', 'Failed to grab servers. ('..(data and data.errors and data.errors[1] and data.errors[1].message or 'no data')..')', 5, 'warning')
    end
end

local function getRole(plr, id)
    local suc, res
    for _ = 1, 3 do
        suc, res = pcall(function()
            return plr:GetRankInGroup(id)
        end)
        if suc then break end
    end
    return suc and res or 0
end

local function getLowestStaffRole(roles)
    local highest = math.huge
    for _, v in ipairs(roles) do
        local low = v.Name:lower()
        if (low:find('admin') or low:find('mod') or low:find('dev')) and v.Rank < highest then
            highest = v.Rank
        end
    end
    return highest
end

local function playerAdded(plr)
    -- Wait until Mega systems are loaded
    if not Mega.Objects.Toggles then
        repeat task.wait() until Mega.Objects.Toggles
    end

    local customBlacklisted = false
    local customIdsString = States.Utility.StaffDetector.Users or ""
    for idStr in customIdsString:gmatch("[^,%s]+") do
        local id = tonumber(idStr)
        if id and plr.UserId == id then
            customBlacklisted = true
            break
        end
    end

    local groupVal = tonumber(States.Utility.StaffDetector.Group) or 0
    local roleVal = tonumber(States.Utility.StaffDetector.Role) or 1

    if customBlacklisted or getRole(plr, groupVal) >= roleVal then
        notif('StaffDetector', 'Staff Detected ('..(customBlacklisted and 'blacklisted_user' or 'staff_role')..'): '..plr.Name, 60, 'alert')

        local mode = States.Utility.StaffDetector.Mode or "Notify"
        if mode == 'Uninject' then
            task.spawn(function()
                -- Unload script/GUI
                Mega.Unloaded = true
                for _, c in ipairs(Mega.Objects.Connections) do pcall(c.Disconnect, c) end
                if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
                if Services.CoreGui:FindFirstChild("TumbaESP_Container") then Services.CoreGui.TumbaESP_Container:Destroy() end
                if Services.CoreGui:FindFirstChild("TumbaStatusIndicator") then Services.CoreGui.TumbaStatusIndicator:Destroy() end
            end)
            Services.StarterGui:SetCore('SendNotification', {
                Title = 'StaffDetector',
                Text = 'Staff Detected\n'..plr.Name,
                Duration = 60,
            })
        elseif mode == 'ServerHop' then
            serverHop()
        elseif mode == 'Profile' then
            if Mega.ConfigSystem and Mega.ConfigSystem.Load then
                local profileName = States.Utility.StaffDetector.Profile or "default"
                Mega.ConfigSystem.Load(profileName)
            end
        elseif mode == 'AutoConfig' then
            if Mega.Objects.Toggles then
                for key, setState in pairs(Mega.Objects.Toggles) do
                    if key ~= "toggle_staff_detector" then
                        pcall(setState, false)
                    end
                end
            end
        end
    end
end

function Mega.Features.StaffDetector.SetEnabled(state)
    States.Utility.StaffDetector.Enabled = state
    
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    if state then
        local groupVal = States.Utility.StaffDetector.Group or ""
        local roleVal = States.Utility.StaffDetector.Role or ""

        if groupVal == "" or roleVal == "" then
            task.spawn(function()
                local placeinfo
                local creatorGroup = tonumber(groupVal)
                if groupVal == "" then
                    local pSuccess, pInfo = pcall(function()
                        return Services.MarketplaceService:GetProductInfo(game.PlaceId)
                    end)
                    if pSuccess and pInfo then
                        if pInfo.Creator.CreatorType == 'Group' then
                            creatorGroup = pInfo.Creator.CreatorTargetId
                        else
                            local desc = pInfo.Description:split('\n')
                            for _, str in ipairs(desc) do
                                local _, begin = str:find('roblox.com/groups/')
                                if begin then
                                    local endof = str:find('/', begin + 1)
                                    creatorGroup = tonumber(str:sub(begin + 1, (endof or (#str + 1)) - 1))
                                    if creatorGroup then break end
                                end
                            end
                        end
                    end
                end

                if not creatorGroup then
                    notif('StaffDetector', 'Automatic Setup Failed (no group detected)', 5, 'warning')
                    return
                end

                local gSuccess, groupinfo = pcall(function()
                    return Services.GroupService:GetGroupInfoAsync(creatorGroup)
                end)

                if gSuccess and groupinfo and groupinfo.Roles then
                    local minRank = getLowestStaffRole(groupinfo.Roles)
                    States.Utility.StaffDetector.Group = tostring(creatorGroup)
                    States.Utility.StaffDetector.Role = tostring(minRank)
                    
                    -- Update text box elements if they are currently drawn
                    pcall(function()
                        if Mega.Objects.InputBoxes then
                            if Mega.Objects.InputBoxes["textbox_staff_detector_group"] then
                                Mega.Objects.InputBoxes["textbox_staff_detector_group"].Text = tostring(creatorGroup)
                            end
                            if Mega.Objects.InputBoxes["textbox_staff_detector_role"] then
                                Mega.Objects.InputBoxes["textbox_staff_detector_role"].Text = tostring(minRank)
                            end
                        end
                    end)
                else
                    notif('StaffDetector', 'Automatic Setup Failed (group info error)', 5, 'warning')
                    return
                end

                -- Continue enabling
                table.insert(connections, Services.Players.PlayerAdded:Connect(playerAdded))
                for _, v in ipairs(Services.Players:GetPlayers()) do
                    task.spawn(playerAdded, v)
                end
            end)
        else
            table.insert(connections, Services.Players.PlayerAdded:Connect(playerAdded))
            for _, v in ipairs(Services.Players:GetPlayers()) do
                task.spawn(playerAdded, v)
            end
        end
    else
        table.clear(joined)
    end
end

-- Teleport connect exactly like V6
local tpConn = LocalPlayer.OnTeleport:Connect(function()
    if not tpSwitch then
        tpSwitch = true
        pcall(function()
            queue_on_teleport("shared.tumbahubserverhoplist = '"..table.concat(visited, '/').."'\nshared.tumbahubserverhopprevious = '"..game.JobId.."'")
        end)
    end
end)
table.insert(connections, tpConn)

if States.Utility.StaffDetector.Enabled then
    Mega.Features.StaffDetector.SetEnabled(true)
end

-- Unload handler
if Mega.UnloadedSignal then
    table.insert(connections, Mega.UnloadedSignal:Connect(function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        if tpConn then pcall(function() tpConn:Disconnect() end) end
    end))
end

return Mega.Features.StaffDetector
