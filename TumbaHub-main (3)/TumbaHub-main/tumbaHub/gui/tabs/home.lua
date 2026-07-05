-- gui/tabs/home.lua
-- Content for the "HOME" tab

local tabKey = "tab_home"
local UI = Mega.UI
local GetText = Mega.GetText

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

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Updates Section
UI.CreateSection(TabFrame, "section_updates_list")

local UpdateText = Instance.new("TextLabel")
UpdateText.Size = UDim2.new(0.9, 0, 0, 80)
UpdateText.BackgroundTransparency = 1
UpdateText.Text = GetText("update_text_v5_1") .. "\n• [Система] Код полностью реструктурирован для обхода лимита переменных."
UpdateText.TextColor3 = Mega.Settings.Menu.TextColor
UpdateText.TextSize = 13
UpdateText.Font = Enum.Font.Gotham
UpdateText.TextXAlignment = Enum.TextXAlignment.Left
UpdateText.TextYAlignment = Enum.TextYAlignment.Top
UpdateText.TextWrapped = true
UpdateText.Parent = TabFrame
--#endregion

--#region -- Status Section
UI.CreateSection(TabFrame, "section_status")

if not Mega.States.System then Mega.States.System = {} end
if Mega.States.System.AutoSave == nil then Mega.States.System.AutoSave = Mega.Settings.System.AutoSave end
if Mega.States.System.PerformanceMode == nil then Mega.States.System.PerformanceMode = Mega.Settings.System.PerformanceMode end
if Mega.States.System.ShowStatusIndicator == nil then Mega.States.System.ShowStatusIndicator = Mega.Settings.System.ShowStatusIndicator end

UI.CreateToggle(TabFrame, "toggle_autosave", "System.AutoSave", function(state)
    Mega.Settings.System.AutoSave = state
end)
UI.CreateToggle(TabFrame, "toggle_perf_mode", "System.PerformanceMode", function(state)
    Mega.Settings.System.PerformanceMode = state
end)
UI.CreateToggle(TabFrame, "toggle_status_indicator", "System.ShowStatusIndicator", function(state)
    Mega.Settings.System.ShowStatusIndicator = state
    if Mega.UpdateStatus then Mega.UpdateStatus() end
end)
--#endregion

--#region -- Quick Access
UI.CreateSection(TabFrame, "section_quick_access")

UI.CreateButton(TabFrame, "button_esp_toggle", function()
    -- This calls the function created by the toggle in the ESP tab
    if Mega.Objects.Toggles["toggle_esp"] then
        Mega.Objects.Toggles["toggle_esp"](not Mega.States.ESP.Enabled)
    end
end)
UI.CreateButton(TabFrame, "button_aim_toggle", function()
    if Mega.Objects.Toggles["toggle_aim"] then
        Mega.Objects.Toggles["toggle_aim"](not Mega.States.AimAssist.Enabled)
    end
end)
UI.CreateButton(TabFrame, "button_speed_toggle", function()
    if Mega.Objects.Toggles["toggle_speed"] then
        Mega.Objects.Toggles["toggle_speed"](not Mega.States.Player.Speed)
    end
end)
--#endregion

--#region -- Stats
UI.CreateSection(TabFrame, "section_stats")

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(0.9, 0, 0, 100)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Mega.Settings.Menu.TextColor
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Parent = TabFrame

local lastStatsUpdate = 0
Mega.Objects.Connections.HomeStatsUpdate = Mega.Services.RunService.Stepped:Connect(function()
    if TabFrame.Visible then
        local now = tick()
        if now - lastStatsUpdate >= 1 then
            lastStatsUpdate = now
            StatsLabel.Text = GetText("stats_label", 
                Mega.Database.Stats.Kills, 
                Mega.Database.Stats.Deaths, 
                math.floor(Mega.Database.Stats.PlayTime / 60)
            )
        end
    end
    end
end)
--#endregion

--#region -- Discord Section
local loc = Mega.Localization.Strings
if not loc["section_discord"] then
    loc["section_discord"] = { ru = "Наш Discord", en = "Our Discord" }
    loc["btn_copy"] = { ru = "Копировать", en = "Copy" }
    loc["btn_open"] = { ru = "Открыть", en = "Open" }
end

UI.CreateSection(TabFrame, "section_discord")

local DiscordFrame = Instance.new("Frame")
DiscordFrame.Size = UDim2.new(0.95, 0, 0, 40)
DiscordFrame.BackgroundTransparency = 1
DiscordFrame.Parent = TabFrame

local DiscordLayout = Instance.new("UIListLayout", DiscordFrame)
DiscordLayout.FillDirection = Enum.FillDirection.Horizontal
DiscordLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DiscordLayout.VerticalAlignment = Enum.VerticalAlignment.Center
DiscordLayout.Padding = UDim.new(0, 10)

local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(0, 200, 0, 30)
LinkBox.BackgroundColor3 = Mega.Settings.Menu.ElementColor
LinkBox.Text = "https://discord.gg/PE3YB6Dqtc"
LinkBox.TextColor3 = Mega.Settings.Menu.TextColor
LinkBox.Font = Enum.Font.Gotham
LinkBox.TextSize = 13
LinkBox.TextEditable = false
LinkBox.ClearTextOnFocus = false
Instance.new("UICorner", LinkBox).CornerRadius = UDim.new(0, 6)
LinkBox.Parent = DiscordFrame

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 100, 0, 30)
CopyBtn.BackgroundColor3 = Mega.Settings.Menu.AccentColor
CopyBtn.Text = GetText("btn_copy") or "Copy"
CopyBtn.TextColor3 = Color3.new(1,1,1)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 13
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)
CopyBtn.Parent = DiscordFrame
CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then 
        setclipboard("https://discord.gg/PE3YB6Dqtc") 
        if Mega.ShowNotification then Mega.ShowNotification("Скопировано!", 2) end
    else
        if Mega.ShowNotification then Mega.ShowNotification("Твой экзекутор не поддерживает копирование.", 2) end
    end
end)

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 100, 0, 30)
OpenBtn.BackgroundColor3 = Mega.Settings.Menu.AccentColor
OpenBtn.Text = GetText("btn_open") or "Open"
OpenBtn.TextColor3 = Color3.new(1,1,1)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 13
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)
OpenBtn.Parent = DiscordFrame
OpenBtn.MouseButton1Click:Connect(function()
    local req = request or (syn and syn.request) or (http and http.request)
    if req then
        req({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
            Body = game:GetService("HttpService"):JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = "PE3YB6Dqtc" },
                nonce = game:GetService("HttpService"):GenerateGUID(false)
            })
        })
        if Mega.ShowNotification then Mega.ShowNotification("Открываем Discord...", 2) end
    else
        if Mega.ShowNotification then Mega.ShowNotification("Твой экзекутор не поддерживает HTTP запросы.", 2) end
    end
end)
--#endregion
