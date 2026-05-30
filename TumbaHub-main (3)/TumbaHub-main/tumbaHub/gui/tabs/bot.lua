-- gui/tabs/bot.lua
-- Content for the "BOT" tab

local tabKey = "tab_bot"
local UI = Mega.UI

-- Предварительная настройка состояний для предотвращения ошибки "got nil"
if not Mega.States.Bot then Mega.States.Bot = {} end
if not Mega.States.Bot.AutoPlay then
    Mega.States.Bot.AutoPlay = { Enabled = false, Mode = "queue_16v16" }
end
if not Mega.States.Bot.AutoLobby then
    Mega.States.Bot.AutoLobby = { Enabled = false }
end
if not Mega.States.Bot.AutoShop then
    Mega.States.Bot.AutoShop = { 
        Enabled = false, 
        TargetIron = 24,
        MinBlocks = 16
    }
end

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

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)
end)
TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Main Bot
UI.CreateSection(TabFrame, "section_bot_main")
UI.CreateToggle(TabFrame, "toggle_bot", "Bot.Enabled", function(state)
    Mega.States.Bot.Enabled = state
    if Mega.Features.Bot and Mega.Features.Bot.SetEnabled then 
        Mega.Features.Bot.SetEnabled(state) 
    end
end)

UI.CreateSection(TabFrame, "section_bot_targets")
UI.CreateToggle(TabFrame, "toggle_bot_beds", "Bot.TargetBeds")
UI.CreateToggle(TabFrame, "toggle_bot_players", "Bot.TargetPlayers")
UI.CreateToggle(TabFrame, "toggle_bot_pathfinding", "Bot.Pathfinding")

UI.CreateSection(TabFrame, "section_bot_modules")

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_killaura", "Bot.AutoKillaura", nil, {
    UI.CreateToggle(nil, "toggle_killaura_target_esp", "Combat.Killaura.TargetESP"),
    UI.CreateSlider(nil, "slider_killaura_range", "Combat.Killaura.Range", 5, 100),
    UI.CreateSlider(nil, "slider_killaura_delay", "Combat.Killaura.Delay", 0, 1000)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_scaffold", "Bot.AutoScaffold", nil, {
    UI.CreateSlider(nil, "slider_scaffold_yoffset", "Player.Scaffold.YOffset", -100, 0, function(val) Mega.States.Player.Scaffold.YOffset = val / 10 end),
    UI.CreateSlider(nil, "slider_scaffold_predict", "Player.Scaffold.Predict", 0, 100, function(val) Mega.States.Player.Scaffold.Predict = val / 100 end)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_bednuke", "Bot.AutoBedNuke", nil, {
    UI.CreateSlider(nil, "slider_bednuke_range", "Combat.BedNuke.Range", 5, 50, function(val) Mega.States.Combat.BedNuke.Range = val end),
    UI.CreateSlider(nil, "slider_bednuke_min_range", "Combat.BedNuke.MinRange", 1, 15, function(val) Mega.States.Combat.BedNuke.MinRange = val end),
    UI.CreateToggle(nil, "toggle_bednuke_bypass", "Combat.BedNuke.Bypass"),
    UI.CreateSlider(nil, "slider_bednuke_delay", "Combat.BedNuke.Delay", 0, 1000, function(val) Mega.States.Combat.BedNuke.Delay = val end),
    UI.CreateSlider(nil, "slider_bednuke_packets", "Combat.BedNuke.PacketsPerTick", 1, 10, function(val) Mega.States.Combat.BedNuke.PacketsPerTick = val end)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_antivoid", "Bot.AutoAntiVoid", nil, {
    UI.CreateSlider(nil, "slider_antivoid_ylevel", "Player.AntiVoid.YLevel", -100, 100),
    UI.CreateToggle(nil, "toggle_antivoid_esp", "Player.AntiVoid.ESP", function(state) Mega.States.Player.AntiVoid.ESP = state; if Mega.Features.AntiVoid and Mega.Features.AntiVoid.UpdateESP then Mega.Features.AntiVoid.UpdateESP() end end),
    UI.CreateSlider(nil, "slider_antivoid_esp_transparency", "Player.AntiVoid.ESPTransparency", 0, 100, function(val) Mega.States.Player.AntiVoid.ESPTransparency = val / 100; if Mega.Features.AntiVoid and Mega.Features.AntiVoid.UpdateESP then Mega.Features.AntiVoid.UpdateESP() end end)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_spider", "Bot.AutoSpider", nil, {
    UI.CreateDropdown(nil, "dropdown_spider_mode", "Player.SpiderMode", {"Velocity", "CFrame"}),
    UI.CreateSlider(nil, "slider_spider_speed", "Player.SpiderSpeed", 1, 100)
})

--#region -- Resources & Shop
UI.CreateSection(TabFrame, "section_bot_resources")

UI.CreateToggleWithSettings(TabFrame, "toggle_bot_autoshop", "Bot.AutoShop.Enabled", function(state)
    if Mega.Features.ShopManager then
        Mega.Features.ShopManager.SetEnabled(state)
    end
end, {
    UI.CreateSlider(nil, "slider_bot_target_iron", "Bot.AutoShop.TargetIron", 8, 100),
    UI.CreateSlider(nil, "slider_bot_min_blocks", "Bot.AutoShop.MinBlocks", 0, 64)
})
--#endregion

--#region -- Auto Play (Lobby)
UI.CreateSection(TabFrame, "section_bot_autoplay")

local queueNames = {
    "queue_16v16", "queue_to4", "queue_to2", "queue_to1", "queue_5v5", "queue_skywars"
}

UI.CreateToggle(TabFrame, "toggle_bot_autoplay", "Bot.AutoPlay.Enabled", function(state)
    Mega.States.Bot.AutoPlay.Enabled = state
    if Mega.Features.AutoPlay and Mega.Features.AutoPlay.SetEnabled then
        Mega.Features.AutoPlay.SetEnabled(state)
    end
end)

UI.CreateDropdown(TabFrame, "dropdown_bot_autoplay_mode", "Bot.AutoPlay.Mode", queueNames, nil, true)

UI.CreateToggle(TabFrame, "label_bot_autolobby", "Bot.AutoLobby.Enabled", function(state)
    if Mega.Features.AutoLobby then
        Mega.Features.AutoLobby.SetEnabled(state)
    end
end)

task.spawn(function()
    pcall(function() Mega.LoadModule("features/autoplay.lua") end)
    pcall(function() Mega.LoadModule("features/autolobby.lua") end)
    pcall(function() Mega.LoadModule("features/shop_manager.lua") end)
    pcall(function() Mega.LoadModule("features/bot.lua") end)
end)
--#endregion

return TabFrame
