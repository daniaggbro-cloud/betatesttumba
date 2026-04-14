-- gui/tabs/combat.lua
-- Content for the "COMBAT" tab

local tabKey = "tab_combat"
local UI = Mega.UI

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

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)
end)
TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Automation
UI.CreateSection(TabFrame, "section_combat_auto")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/aimbot.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_aimbot", "Combat.Aimbot.Enabled", function(state)
    Mega.States.Combat.Aimbot.Enabled = state
    if Mega.Features.Aimbot and Mega.Features.Aimbot.SetEnabled then Mega.Features.Aimbot.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_aimbot_fov", "Combat.Aimbot.FOV", 50, 1000)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_autoshoot", "Combat.AutoShoot.Enabled", function(state)
    Mega.States.Combat.AutoShoot.Enabled = state
    if Mega.Features.Aimbot and Mega.Features.Aimbot.SetAutoShoot then Mega.Features.Aimbot.SetAutoShoot(state) end
end, {
    UI.CreateSlider(nil, "slider_autoshoot_delay", "Combat.AutoShoot.Delay", 0, 1000)
})

UI.CreateToggle(TabFrame, "toggle_triggerbot", "Combat.TriggerBot")
UI.CreateToggle(TabFrame, "toggle_rapidfire", "Combat.RapidFire")
--#endregion

--#region -- Accuracy
UI.CreateSection(TabFrame, "section_combat_accuracy")

UI.CreateToggle(TabFrame, "toggle_norecoil", "Combat.NoRecoil")
UI.CreateToggle(TabFrame, "toggle_nospread", "Combat.NoSpread")
--#endregion

--#region -- Killaura
UI.CreateSection(TabFrame, "section_combat_killaura")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/killaura.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_killaura", "Combat.Killaura.Enabled", function(state)
    Mega.States.Combat.Killaura.Enabled = state
    if Mega.Features.Killaura and Mega.Features.Killaura.SetEnabled then Mega.Features.Killaura.SetEnabled(state) end
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("toggle_killaura") .. ": " .. (state and Mega.GetText("notify_enabled") or Mega.GetText("notify_disabled")), 2)
    end
end, {
    UI.CreateToggle(nil, "toggle_killaura_target_esp", "Combat.Killaura.TargetESP"),
    UI.CreateSlider(nil, "slider_killaura_range", "Combat.Killaura.Range", 5, 100),
    UI.CreateSlider(nil, "slider_killaura_delay", "Combat.Killaura.Delay", 0, 1000),
    UI.CreateKeybindButton(nil, "keybind_killaura", "Keybinds.Killaura")
})

UI.CreateToggle(TabFrame, "toggle_killaura_autoclick", "Combat.Killaura.AutoClick")
UI.CreateSlider(TabFrame, "slider_killaura_autoclick_cps", "Combat.Killaura.AutoClickCPS", 1, 50)
--#endregion

--#region -- Bed Nuke
UI.CreateSection(TabFrame, "section_combat_bednuke")

local bedNukeSettings = {
    -- Максимальная дистанция
    UI.CreateSlider(nil, "slider_bednuke_range", "Combat.BedNuke.Range", 5, 50, function(val) 
        Mega.States.Combat.BedNuke.Range = val 
    end),
    
    -- Минимальная дистанция (чтобы не ломать блоки прямо под собой)
    UI.CreateSlider(nil, "slider_bednuke_min_range", "Combat.BedNuke.MinRange", 1, 15, function(val) 
        Mega.States.Combat.BedNuke.MinRange = val 
    end),
    
    UI.CreateToggle(nil, "toggle_bednuke_bypass", "Combat.BedNuke.Bypass"),
    
    -- Задержка (мс) - Скорость ломания
    UI.CreateSlider(nil, "slider_bednuke_delay", "Combat.BedNuke.Delay", 0, 1000, function(val) 
        Mega.States.Combat.BedNuke.Delay = val 
    end),
    
    -- Пакетов за тик (мощность нюка)
    UI.CreateSlider(nil, "slider_bednuke_packets", "Combat.BedNuke.PacketsPerTick", 1, 10, function(val) 
        Mega.States.Combat.BedNuke.PacketsPerTick = val 
    end)
}

UI.CreateToggleWithSettings(TabFrame, "toggle_bednuke", "Combat.BedNuke.Enabled", function(state)
    Mega.States.Combat.BedNuke.Enabled = state
    if Mega.Features.BedNuke and Mega.Features.BedNuke.SetEnabled then
        Mega.Features.BedNuke.SetEnabled(state)
    end
end, bedNukeSettings)
--#endregion
