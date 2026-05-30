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
if not States.Render.KitDisplay then
    States.Render.KitDisplay = { Enabled = false }
end

local connections = {}

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
    
    if success and meta then
        return meta[kit] or meta.none
    end
    
    return { renderImage = "rbxassetid://13388222306" }
end

local function getPlayerFromDraft(render, name)
    local id = render and render:match("id=(%d+)")
    if id then
        local player = Services.Players:GetPlayerByUserId(tonumber(id))
        if player then
            return player
        end
    end

    for _, v in ipairs(Services.Players:GetPlayers()) do
        if render and render:find("id=" .. v.UserId, 1, true) then
            return v
        end

        if name and (v.Name == name or v.DisplayName == name or v:GetAttribute("DisguiseDisplayName") == name) then
            return v
        end

        local displayName
        pcall(function()
            local TS = Services.ReplicatedStorage:FindFirstChild("TS")
            local controllers = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("controllers")
            local globalFolder = controllers and controllers:FindFirstChild("global")
            local streamerMode = globalFolder and globalFolder:FindFirstChild("streamer-mode")
            local controller = streamerMode and streamerMode:FindFirstChild("streamer-mode-controller")
            if controller then
                displayName = require(controller).StreamerModeController:getDisplayName(v)
            end
        end)
        if name and displayName == name then
            return v
        end
    end
    return nil
end

local waitForChild = function(start, ...)
    local parent = start
    for _, v in ipairs({...}) do
        parent = parent and parent:WaitForChild(v, 5)
        if not parent then
            break
        end
    end
    return parent
end

local function removeTags(str)
    if not str then return "" end
    str = str:gsub("<br%s*/>", "\n")
    return (str:gsub("<[^<>]->", ""))
end

local function getPlayerName(card)
    local textbar = card and card:FindFirstChild("TextBackgroundBar")
    local label = textbar and textbar:FindFirstChild("PlayerName") or card and card:FindFirstChild("PlayerName", true)
    local text = label and label.Text or ""
    return removeTags(text)
end

local function getDraftCard(container)
    if not container then return end
    return container.Name == "MatchDraftPlayerCard" and container or container:FindFirstChild("MatchDraftPlayerCard", true)
end

local function callback5v5(v, plr)
    if not v then return end
    local render = v:FindFirstChild("PlayerRender", true)
    local player = plr or getPlayerFromDraft(render and render.Image or "", getPlayerName(v))

    if player then
        local kitImage = getKitMeta(player)
        local roact = v:FindFirstChild("KitImage")

        if not roact then
            roact = Instance.new("ImageLabel", v)
            roact.BackgroundTransparency = 1
            roact.AnchorPoint = Vector2.new(1, 0.5)
            roact.Position = UDim2.fromScale(1.05, 0.5)
            roact.Name = "KitImage"
            roact.Size = UDim2.fromScale(1.5, 1.5)
            roact.ZIndex = 1
            roact.ImageTransparency = 0.4
            roact.SliceCenter = Rect.new(0, 0, 0, 0)
            roact.SliceScale = 1
            roact.ScaleType = Enum.ScaleType.Crop

            local ratio = Instance.new("UIAspectRatioConstraint", roact)
            ratio.Name = "1"
            ratio.AspectRatio = 1
            ratio.AspectType = Enum.AspectType.FitWithinMaxSize
            ratio.DominantAxis = Enum.DominantAxis.Width
        end

        roact.Image = kitImage.renderImage
        roact.Position = UDim2.fromScale(1.05, 0)
        Services.TweenService:Create(roact, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(1.05, 0.4)
        }):Play()

        local function update()
            kitImage = getKitMeta(player)
            roact.Image = kitImage.renderImage
        end

        table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKits"):Connect(update))
        table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKit"):Connect(update))
    end
end

local function callbacksquad(v)
    if not v then return end
    local render = v:FindFirstChild("PlayerRender", true)
    local player = render and getPlayerFromDraft(render.Image, "") or nil

    if player then 
        local kitImage = getKitMeta(player)
        local Roact = v:FindFirstChild("Kitcvrender")

        if not Roact then
            local base = v:FindFirstChild("3") or v:WaitForChild("3", 5)
            if not base then return end
            Roact = base:Clone()
            Roact.Parent = v
            Roact.Name = "Kitcvrender"
        end

        Roact.Image = kitImage.renderImage

        table.insert(connections, render:GetPropertyChangedSignal("Image"):Connect(function()
            local newplayer = getPlayerFromDraft(render.Image, "")
            if newplayer then
                player = newplayer
                kitImage = getKitMeta(player)
                Roact.Image = kitImage.renderImage
            end
        end))

        local function update()
            kitImage = getKitMeta(player)
            Roact.Image = kitImage.renderImage
        end

        table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKits"):Connect(update))
        table.insert(connections, player:GetAttributeChangedSignal("PlayingAsKit"):Connect(update))
    end
end

local function setup5v5(DraftApp)
    local Background = DraftApp:FindFirstChild("DraftAppBackground")
    local BodyContainer = Background and Background:FindFirstChild("1") and Background["1"]:FindFirstChild("BodyContainer")
    local hooked = false

    for i = 1, 2 do
        local dtc = BodyContainer and BodyContainer:FindFirstChild("Team" .. i .. "Column")
        if dtc then
            hooked = true
            table.insert(connections, dtc.ChildAdded:Connect(function(child)
                task.delay(0.2, function()
                    if States.Render.KitDisplay.Enabled then
                        callback5v5(getDraftCard(child))
                    end
                end)
            end))

            for _, v in ipairs(dtc:GetChildren()) do
                if v:IsA("Frame") then
                    callback5v5(getDraftCard(v))
                end
            end
        end
    end

    if not hooked then
        for _, label in ipairs(DraftApp:GetDescendants()) do
            if label:IsA("TextLabel") and label.Name == "PlayerName" then
                local container = label.Parent
                for _ = 1, 3 do
                    container = container and container.Parent
                end
                if container then
                    callback5v5(getDraftCard(container))
                end
            end
        end

        table.insert(connections, DraftApp.DescendantAdded:Connect(function(child)
            if child:IsA("TextLabel") and child.Name == "PlayerName" then
                task.delay(0.2, function()
                    local container = child.Parent
                    for _ = 1, 3 do
                        container = container and container.Parent
                    end
                    if States.Render.KitDisplay.Enabled and container then
                        callback5v5(getDraftCard(container))
                    end
                end)
            end
        end))
    end

    return hooked
end

local function setupSquad(DraftApp)
    local Background = DraftApp:FindFirstChild("DraftAppBackground")
    local BodyContainer = Background and Background:FindFirstChild("1") and Background["1"]:FindFirstChild("BodyContainer")
    local TeamsColumn = BodyContainer and BodyContainer:FindFirstChild("TeamsColumn")
    if not TeamsColumn then return end

    for _, v in ipairs(TeamsColumn:GetChildren()) do
        if v:IsA("Frame") then
            local plrframe = waitForChild(v, "1", "2", "4")
            if plrframe then
                for _, plr in ipairs(plrframe:GetChildren()) do
                    callbacksquad(plr)
                end

                table.insert(connections, plrframe.ChildAdded:Connect(function(plr)
                    task.delay(1, callbacksquad, plr)
                end))
            end
        end
    end
end

function Mega.Features.KitDisplay.SetEnabled(state)
    States.Render.KitDisplay.Enabled = state
    
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    
    if state then
        task.spawn(function()
            local DraftApp = LocalPlayer.PlayerGui:WaitForChild("MatchDraftApp", 9e9)
            if DraftApp then
                setup5v5(DraftApp)
                setupSquad(DraftApp)
            end
        end)
    end
end

-- Initialize if enabled in config
if States.Render.KitDisplay.Enabled then
    Mega.Features.KitDisplay.SetEnabled(true)
end

return Mega.Features.KitDisplay
