-- features/staff_detector.lua
-- Adapted Staff Detector for TumbaHub

if not Mega.Features then Mega.Features = {} end
Mega.Features.StaffDetector = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    StarterGui = game:GetService("StarterGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
    GroupService = game:GetService("GroupService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Utility then States.Utility = {} end
if not States.Utility.StaffDetector then
    States.Utility.StaffDetector = {
        Enabled = false,
        Mode = "Notify",
        Clans = true,
        LeaveParty = false,
        Group = "",
        Role = "",
        Profile = "default",
        Users = ""
    }
end

local blacklistedclans = {"gg", "gg2"}
local blacklisteduserids = {
    1502104539, 3826146717, 4531785383, 1049767300, 
    4926350670, 653085195, 184655415, 2752307430, 
    5087196317, 5744061325, 1536265275
}
local joined = {}
local connections = {}

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
        if (low:find("admin") or low:find("mod") or low:find("dev")) and v.Rank < highest then
            highest = v.Rank
        end
    end
    return highest
end

local function hasPermission(plr)
    pcall(function()
        repeat task.wait() until plr:GetAttribute("PlayerConnected")
    end)
    local tags = plr:FindFirstChild("Tags")
    if not tags then
        tags = plr:WaitForChild("Tags", 5)
        task.wait(2)
    end

    if tags then
        for _, v in ipairs(tags:GetChildren()) do
            local text = tostring(v:GetAttribute("Text") or ""):lower()
            if (text:find("mod") and #text > 5) or text:find("artist") then
                warn("Mod Tag:", text)
                return true
            end
        end
    end

    return false
end

local function leaveMatch()
    local paths = {
        "events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events",
        "events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"
    }
    
    for _, path in ipairs(paths) do
        local folder = Services.ReplicatedStorage:FindFirstChild(path)
        if folder then
            local remote = folder:FindFirstChild("leaveMatch")
            if remote then
                remote:FireServer()
                return true
            end
        end
    end
    return false
end

local function staffFunction(plr, checktype)
    local notifyText = "Staff Detected (" .. checktype .. "): " .. plr.Name .. " (" .. tostring(plr.UserId) .. ")"
    if Mega.ShowNotification then
        Mega.ShowNotification(notifyText, 10)
    end
    
    -- Try to leave party if requested (Bedwars specific check)
    if States.Utility.StaffDetector.LeaveParty and not checktype:find("clan") then
        pcall(function()
            local Knit = getgenv().Knit or shared.Knit
            local partyController = Knit and Knit.Controllers and Knit.Controllers.PartyController
            if partyController and partyController.leaveParty then
                partyController:leaveParty()
            end
        end)
    end

    local mode = States.Utility.StaffDetector.Mode or "Notify"
    if mode == "Uninject" then
        Mega.Unloaded = true
        for _, c in ipairs(Mega.Objects.Connections) do pcall(c.Disconnect, c) end
        if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
        if Services.CoreGui:FindFirstChild("TumbaESP_Container") then Services.CoreGui.TumbaESP_Container:Destroy() end
        if Services.CoreGui:FindFirstChild("TumbaStatusIndicator") then Services.CoreGui.TumbaStatusIndicator:Destroy() end
        Services.StarterGui:SetCore("SendNotification", {
            Title = "StaffDetector",
            Text = "Staff Detected (" .. checktype .. ")\n" .. plr.Name,
            Duration = 60
        })
    elseif mode == "Requeue" then
        leaveMatch()
        task.spawn(function()
            task.wait(2)
            -- Attempt queue join
            local joinQueueRemote = Services.ReplicatedStorage:FindFirstChild("events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events")
                and Services.ReplicatedStorage["events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events"]:FindFirstChild("joinQueue")
            if joinQueueRemote then
                -- Fallback to default queue winstreak_1v1 or bedwars_16v16
                joinQueueRemote:FireServer({ queueType = "winstreak_1v1" })
            end
        end)
    elseif mode == "Profile" then
        if Mega.ConfigSystem and Mega.ConfigSystem.Load then
            local profileName = States.Utility.StaffDetector.Profile or "default"
            Mega.ConfigSystem.Load(profileName)
        end
    elseif mode == "AutoConfig" then
        -- Disable all UI toggles
        if Mega.Objects.Toggles then
            for key, setState in pairs(Mega.Objects.Toggles) do
                if key ~= "toggle_staff_detector" then
                    pcall(setState, false)
                end
            end
        end
    elseif mode == "Leave" then
        game:Shutdown()
    elseif mode == "Lobby" then
        leaveMatch()
    end
end

local function checkFriends(list)
    for _, v in ipairs(list) do
        if joined[v] then
            return joined[v]
        end
    end
    return nil
end

local function checkJoin(plr, connection)
    -- Check if spectator joined impossible
    local isSpectator = plr:GetAttribute("Spectator")
    local team = plr:GetAttribute("Team")
    local customMatch = false
    
    pcall(function()
        local storeModule = getgenv().store
        customMatch = storeModule and storeModule.customMatch or false
    end)

    if not team and isSpectator and not customMatch then
        if connection then connection:Disconnect() end
        
        local tab = {}
        local success, pages = pcall(function()
            return Services.Players:GetFriendsAsync(plr.UserId)
        end)
        
        if success and pages then
            pcall(function()
                for _ = 1, 70 do
                    for _, v in ipairs(pages:GetCurrentPage()) do
                        table.insert(tab, v.Id)
                    end
                    if pages.IsFinished then break end
                    pages:AdvanceToNextPageAsync()
                end
            end)
        end

        local friend = checkFriends(tab)
        if not friend then
            staffFunction(plr, "impossible_join")
            return true
        else
            if Mega.ShowNotification then
                Mega.ShowNotification(string.format("Spectator %s joined from %s", plr.Name, friend), 5)
            end
        end
    end
    return nil
end

local function playerAdded(plr)
    joined[plr.UserId] = plr.Name
    if plr == LocalPlayer then return end

    -- Parse custom blacklist user IDs from state string (e.g. "123, 456")
    local customBlacklisted = false
    local customIdsString = States.Utility.StaffDetector.Users or ""
    for idStr in customIdsString:gmatch("[^,%s]+") do
        local id = tonumber(idStr)
        if id and plr.UserId == id then
            customBlacklisted = true
            break
        end
    end

    if table.find(blacklisteduserids, plr.UserId) or customBlacklisted then
        staffFunction(plr, "blacklisted_user")
        return
    end

    -- Roblox Group Check
    local customGroup = tonumber(States.Utility.StaffDetector.Group)
    local customRole = tonumber(States.Utility.StaffDetector.Role)
    if customGroup and customRole then
        if getRole(plr, customGroup) >= customRole then
            staffFunction(plr, "staff_group_role")
            return
        end
    end

    -- Bedwars Group / Tags Check
    local groupRole = getRole(plr, 5774246)
    if groupRole >= 100 or hasPermission(plr) then
        staffFunction(plr, hasPermission(plr) and "staff_permission" or "staff_role")
        return
    end

    -- Spectator Join check
    local connection
    connection = plr:GetAttributeChangedSignal("Spectator"):Connect(function()
        checkJoin(plr, connection)
    end)
    table.insert(connections, connection)

    if checkJoin(plr, connection) then
        return
    end

    -- Clan tag checks
    task.spawn(function()
        if not plr:GetAttribute("ClanTag") then
            pcall(function()
                plr:GetAttributeChangedSignal("ClanTag"):Wait()
            end)
        end
        if States.Utility.StaffDetector.Clans and table.find(blacklistedclans, plr:GetAttribute("ClanTag")) then
            if connection then connection:Disconnect() end
            staffFunction(plr, "blacklisted_clan_" .. tostring(plr:GetAttribute("ClanTag") or ""))
        end
    end)
end

function Mega.Features.StaffDetector.SetEnabled(state)
    States.Utility.StaffDetector.Enabled = state
    
    -- Disconnect old connections
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    if state then
        -- Automatically discover Group lowest staff role if ID is provided but role rank is blank
        local groupVal = States.Utility.StaffDetector.Group or ""
        local roleVal = States.Utility.StaffDetector.Role or ""
        if groupVal ~= "" and roleVal == "" then
            task.spawn(function()
                local groupId = tonumber(groupVal)
                if groupId then
                    local success, groupInfo = pcall(function()
                        return Services.GroupService:GetGroupInfoAsync(groupId)
                    end)
                    if success and groupInfo and groupInfo.Roles then
                        local minRank = getLowestStaffRole(groupInfo.Roles)
                        States.Utility.StaffDetector.Role = tostring(minRank)
                        -- Update the UI textbox if exists
                        pcall(function()
                            if Mega.Objects.InputBoxes and Mega.Objects.InputBoxes["textbox_staff_detector_role"] then
                                Mega.Objects.InputBoxes["textbox_staff_detector_role"].Text = tostring(minRank)
                            end
                        end)
                    end
                end
            end)
        end

        table.insert(connections, Services.Players.PlayerAdded:Connect(playerAdded))
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            task.spawn(playerAdded, plr)
        end
    else
        table.clear(joined)
    end
end

-- Initialize on load if enabled
if States.Utility.StaffDetector.Enabled then
    Mega.Features.StaffDetector.SetEnabled(true)
end

-- Unload handler
if Mega.UnloadedSignal then
    table.insert(connections, Mega.UnloadedSignal:Connect(function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end))
end

return Mega.Features.StaffDetector
