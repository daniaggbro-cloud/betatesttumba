-- features/kit_display.lua
-- Kit Display functionality from TumbaV6

if not Mega.Features then Mega.Features = {} end
Mega.Features.KitDisplay = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Render then States.Render = {} end
if States.Render.KitDisplay == nil or type(States.Render.KitDisplay) ~= "boolean" then
    States.Render.KitDisplay = false
end

local connections = {}

-- Utility to get kit image from BedwarsKitMeta
local function getKitMeta(player)
    local kit = player:GetAttribute("PlayingAsKits") or player:GetAttribute("PlayingAsKit") or "none"
    
    local success, meta = pcall(function()
        local TS = Services.ReplicatedStorage:FindFirstChild("TS")
        local games = TS and TS:FindFirstChild("games")
        local bedwarsFolder = games and games:FindFirstChild("bedwars")
        local kitFolder = bedwarsFolder and bedwarsFolder:FindFirstChild("kit")
        local kitMeta = kitFolder and kitFolder:FindFirstChild("bedwars-kit-meta")
        if kitMeta then
            return require(kitMeta).BedwarsKitMeta
        end
    end)
    
    if success and meta and meta[kit] then
        return meta[kit]
    end
    
    -- Fallback: lookup in UI
    local ui = LocalPlayer.PlayerGui:FindFirstChild("MatchDraftApp")
    if ui and kit ~= "none" then
        local search = kit:gsub("_", " "):lower()
        for _, lbl in ipairs(ui:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text:lower() == search then
                local btn = lbl.Parent
                for _ = 1, 4 do
                    if btn and btn:IsA("ImageButton") then
                        local imgContainer = btn:FindFirstChildOfClass("Frame")
                        local img = imgContainer and imgContainer:FindFirstChildOfClass("ImageLabel")
                        if img and img.Image ~= "" then
                            return { renderImage = img.Image }
                        end
                    end
                    btn = btn and btn.Parent
                end
            end
        end
    end
    
    return { renderImage = "rbxassetid://13388222306" }
end

local function getPlayerFromDraft(render, name)
    local id = render and render:match("id=(%d+)")
    if id then
        local player = Services.Players:GetPlayerByUserId(tonumber(id))
        if player then return player end
    end
    
    for _, v in ipairs(Services.Players:GetPlayers()) do
        if name and v.Name == name then return v end
    end
    return nil
end

local function callbackCard(card)
    if not card then return end
    local render = card:FindFirstChild("PlayerRender", true)
    local textbar = card:FindFirstChild("TextBackgroundBar")
    local nameLabel = textbar and textbar:FindFirstChild("PlayerName") or card:FindFirstChild("PlayerName", true)
    local nameStr = nameLabel and nameLabel.Text or ""
    
    local player = getPlayerFromDraft(render and render.Image, nameStr)
    if not player then return end

    local function update()
        if not States.Render.KitDisplay then return end
        local kitMeta = getKitMeta(player)
        
        local roact = card:FindFirstChild("KitImage_Tumba")
        if not roact then
            roact = Instance.new("ImageLabel")
            roact.Name = "KitImage_Tumba"
            roact.BackgroundTransparency = 1
            roact.Size = UDim2.fromScale(0.4, 0.4) -- 40% size to fit on card without clipping issues
            roact.Position = UDim2.fromScale(0.05, 0.05)
            roact.ZIndex = 10
            roact.ScaleType = Enum.ScaleType.Fit
            roact.Parent = card
        end
        roact.Image = kitMeta.renderImage
    end

    update()
    table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKits"):Connect(update))
    table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKit"):Connect(update))
end

local function setupDraftApp(DraftApp)
    task.spawn(function()
        local bg = DraftApp:WaitForChild("DraftAppBackground", 5)
        local frame1 = bg and bg:WaitForChild("1", 5)
        local body = frame1 and frame1:WaitForChild("BodyContainer", 5)
        
        if body then
            local function hookColumn(colName)
                local col = body:WaitForChild(colName, 2)
                if not col then return end
                
                local function onRowAdded(row)
                    task.spawn(function()
                        local card = row:FindFirstChild("MatchDraftPlayerCard", true)
                        if card then
                            task.delay(0.2, function() callbackCard(card) end)
                        else
                            local conn
                            conn = row.DescendantAdded:Connect(function(desc)
                                if desc.Name == "MatchDraftPlayerCard" then
                                    if conn then conn:Disconnect() conn = nil end
                                    task.delay(0.2, function() callbackCard(desc) end)
                                end
                            end)
                            -- Timeout after 3 seconds to prevent memory leak
                            task.delay(3, function()
                                if conn then conn:Disconnect() conn = nil end
                            end)
                        end
                    end)
                end
                
                for _, row in ipairs(col:GetChildren()) do
                    if row:IsA("Frame") then onRowAdded(row) end
                end
                table.insert(connections, col.ChildAdded:Connect(function(child)
                    if child:IsA("Frame") then onRowAdded(child) end
                end))
            end
            
            hookColumn("Team1Column")
            hookColumn("Team2Column")
        else
            -- Squads or alternate layout fallback
            local function onDescendant(child)
                if child:IsA("TextLabel") and child.Name == "PlayerName" then
                    task.delay(0.2, function()
                        local container = child.Parent
                        for _ = 1, 3 do container = container and container.Parent end
                        if container and container.Name:find("Card") then
                            callbackCard(container)
                        end
                    end)
                end
            end
            for _, child in ipairs(DraftApp:GetDescendants()) do onDescendant(child) end
            table.insert(connections, DraftApp.DescendantAdded:Connect(onDescendant))
        end
    end)
end

function Mega.Features.KitDisplay.SetEnabled(state)
    States.Render.KitDisplay = state
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    
    if state then
        -- Check existing
        local existing = LocalPlayer.PlayerGui:FindFirstChild("MatchDraftApp")
        if existing then setupDraftApp(existing) end
        
        -- Hook future
        table.insert(connections, LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            if child.Name == "MatchDraftApp" then
                setupDraftApp(child)
            end
        end))
    end
end

if States.Render.KitDisplay then
    Mega.Features.KitDisplay.SetEnabled(true)
end

return Mega.Features.KitDisplay
