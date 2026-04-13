-- gui/tabs/users.lua
-- Content for the "PLAYERS" tab

local tabKey = "tab_users"
local UI = Mega.UI
local Services = Mega.Services

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

Mega.Objects.TabFrames[tabKey] = TabFrame

task.spawn(function()
    pcall(function() Mega.LoadModule("features/spectate_players.lua") end)
end)

--#region -- Player List
UI.CreateSection(TabFrame, "section_player_list")

UI.CreateButton(TabFrame, "button_stop_spectate", function()
    if Mega.Features.SpectatePlayers and Mega.Features.SpectatePlayers.StopSpectate then
        Mega.Features.SpectatePlayers.StopSpectate()
    else
        Mega.States.Player.SpectateTarget = nil
        Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        if Mega.ShowNotification then
            Mega.ShowNotification(Mega.GetText("notify_spectate_stop"))
        end
    end
end)

local PlayerListHeader = Instance.new("Frame")
PlayerListHeader.Name = "PlayerListHeader"
PlayerListHeader.Size = UDim2.new(0.95, 0, 0, 30)
PlayerListHeader.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
PlayerListHeader.BorderSizePixel = 0
PlayerListHeader.Parent = TabFrame

local HeaderLayout = Instance.new("UIListLayout")
HeaderLayout.Parent = PlayerListHeader
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HeaderLayout.Padding = UDim.new(0, 5)
HeaderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 5)
HeaderCorner.Parent = PlayerListHeader

local HeaderName = Instance.new("TextLabel")
HeaderName.Name = "HeaderName"
HeaderName.Size = UDim2.new(0.25, 0, 1, 0)
HeaderName.BackgroundTransparency = 1
HeaderName.TextColor3 = Mega.Settings.Menu.SecondaryColor
HeaderName.TextSize = 13
HeaderName.Font = Enum.Font.GothamBold
HeaderName.TextXAlignment = Enum.TextXAlignment.Left
HeaderName.Position = UDim2.new(0, 10, 0, 0)
HeaderName.Text = "  " .. Mega.GetText("playerlist_name")
HeaderName.Parent = PlayerListHeader

local HeaderTeam = HeaderName:Clone(); HeaderTeam.Name = "HeaderTeam"; HeaderTeam.Text = Mega.GetText("playerlist_team"); HeaderTeam.Parent = PlayerListHeader
local HeaderHP = HeaderName:Clone(); HeaderHP.Name = "HeaderHP"; HeaderHP.Size = UDim2.new(0.2, 0, 1, 0); HeaderHP.Text = Mega.GetText("playerlist_hp"); HeaderHP.Parent = PlayerListHeader
local HeaderDist = HeaderName:Clone(); HeaderDist.Name = "HeaderDist"; HeaderDist.Size = UDim2.new(0.25, 0, 1, 0); HeaderDist.Text = Mega.GetText("playerlist_dist"); HeaderDist.Parent = PlayerListHeader

local PlayerListContainer = Instance.new("ScrollingFrame")
PlayerListContainer.Name = "PlayersList"
PlayerListContainer.Size = UDim2.new(0.95, 0, 1, -140) 
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.BorderSizePixel = 0
PlayerListContainer.ScrollBarThickness = 4
PlayerListContainer.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
PlayerListContainer.Parent = TabFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = PlayerListContainer
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding = UDim.new(0, 5)

local PlayerItemTemplate = Instance.new("TextButton") 
PlayerItemTemplate.Name = "PlayerItemTemplate"
PlayerItemTemplate.Size = UDim2.new(1, 0, 0, 35)
PlayerItemTemplate.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
PlayerItemTemplate.BorderSizePixel = 0
PlayerItemTemplate.Visible = false
PlayerItemTemplate.Text = "" 
PlayerItemTemplate.AutoButtonColor = false

local ItemLayout = Instance.new("UIListLayout")
ItemLayout.Parent = PlayerItemTemplate
ItemLayout.FillDirection = Enum.FillDirection.Horizontal
ItemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ItemLayout.Padding = UDim.new(0, 5)
ItemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local ItemCorner = Instance.new("UICorner")
ItemCorner.CornerRadius = UDim.new(0, 5)
ItemCorner.Parent = PlayerItemTemplate

local NameLabel = Instance.new("TextLabel")
NameLabel.Name = "Name"
NameLabel.Size = UDim2.new(0.25, 0, 1, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.TextColor3 = Mega.Settings.Menu.TextColor
NameLabel.TextSize = 12
NameLabel.Font = Enum.Font.GothamSemibold
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Position = UDim2.new(0, 5, 0, 0)
NameLabel.Text = Mega.GetText("playerlist_name")
NameLabel.Parent = PlayerItemTemplate

local TeamLabel = NameLabel:Clone()
TeamLabel.Name = "Team"
TeamLabel.Size = UDim2.new(0.25, 0, 1, 0)
TeamLabel.Text = Mega.GetText("playerlist_team")
TeamLabel.Parent = PlayerItemTemplate

local HPLabel = NameLabel:Clone()
HPLabel.Name = "HP"
HPLabel.Size = UDim2.new(0.2, 0, 1, 0)
HPLabel.Text = Mega.GetText("playerlist_hp")
HPLabel.Parent = PlayerItemTemplate

local DistanceLabel = NameLabel:Clone()
DistanceLabel.Name = "Distance"
DistanceLabel.Size = UDim2.new(0.25, 0, 1, 0)
DistanceLabel.Text = Mega.GetText("playerlist_dist")
DistanceLabel.Parent = PlayerItemTemplate

local function StartSpectate(player)
    if player == Services.LocalPlayer then return end
    Mega.States.Player.SpectateTarget = player
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("notify_spectate_start", player.Name))
    end
end

local function updatePlayerList()
    if not TabFrame.Visible then return end

    local localHRP = Services.LocalPlayer.Character and Services.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not Mega.Objects.PlayerListItems then Mega.Objects.PlayerListItems = {} end

    for player, item in pairs(Mega.Objects.PlayerListItems) do
        if not player or not player.Parent then
            item:Destroy()
            Mega.Objects.PlayerListItems[player] = nil
        end
    end

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Services.LocalPlayer then
            local item = Mega.Objects.PlayerListItems[player]

            if not item then
                item = PlayerItemTemplate:Clone()
                item.Name = player.Name .. "Item"
                item.Visible = true
                item.Parent = PlayerListContainer
                Mega.Objects.PlayerListItems[player] = item

                local p = player 
                item.MouseButton1Click:Connect(function()
                    StartSpectate(p)
                end)
            end

            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            local nameLabel = item:FindFirstChild("Name")
            local teamLabel = item:FindFirstChild("Team")
            local hpLabel = item:FindFirstChild("HP")
            local distLabel = item:FindFirstChild("Distance")

            if Mega.States.Player.SpectateTarget == player then
                item.BackgroundColor3 = Mega.Settings.Menu.AccentColor
            else
                item.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
            end

            if nameLabel then
                nameLabel.Text = player.Name
            end

            if teamLabel then
                teamLabel.Text = (player.Team and player.Team.Name) or Mega.GetText("playerlist_team_none")
                if player.Team and player.Team.TeamColor then
                    teamLabel.TextColor3 = player.Team.TeamColor.Color
                else
                    teamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end

            if hpLabel and humanoid then
                hpLabel.Text = Mega.GetText("playerlist_hp_format", math.floor(humanoid.Health))
                hpLabel.TextColor3 = humanoid.Health > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            elseif hpLabel then
                hpLabel.Text = Mega.GetText("playerlist_hp_dead")
                hpLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end

            if distLabel and localHRP and hrp then
                local distance = (localHRP.Position - hrp.Position).Magnitude
                distLabel.Text = Mega.GetText("playerlist_dist_format", math.floor(distance))
            elseif distLabel then
                distLabel.Text = Mega.GetText("playerlist_dist_none")
            end
        end
    end

    PlayerListContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
end

-- Update list smoothly every 0.5s when visible
local timer = 0
Services.RunService.Heartbeat:Connect(function(step)
    if not TabFrame.Visible then return end
    timer = timer + step
    if timer >= 0.5 then
        timer = 0
        pcall(updatePlayerList)
    end
end)
--#endregion
