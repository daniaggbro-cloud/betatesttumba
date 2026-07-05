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

-- Removed Automation Section (Not Implemented)

--#region -- Aimbot & AutoShoot
UI.CreateSection(TabFrame, "tab_aim")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/aimbot.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_aimbot", "Combat.Aimbot.Enabled", function(state)
    Mega.States.Combat.Aimbot.Enabled = state
    if Mega.Features.Aimbot and Mega.Features.Aimbot.SetEnabled then Mega.Features.Aimbot.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_aim_fov", "Combat.Aimbot.FOV", 10, 1500, function(val) Mega.States.Combat.Aimbot.FOV = val end)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_autoshoot", "Combat.AutoShoot.Enabled", function(state)
    Mega.States.Combat.AutoShoot.Enabled = state
    if Mega.Features.Aimbot and Mega.Features.Aimbot.SetAutoShoot then Mega.Features.Aimbot.SetAutoShoot(state) end
end, {
    UI.CreateSlider(nil, "slider_autoshoot_delay", "Combat.AutoShoot.Delay", 0, 1000, function(val) Mega.States.Combat.AutoShoot.Delay = val end)
})
--#endregion

-- Removed Accuracy Section (Not Implemented)

--#region -- Killaura
UI.CreateSection(TabFrame, "section_combat_killaura")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/killaura.lua") end)
end)

-- Защита от старых кэшированных конфигов
if Mega.States.Combat.Killaura and type(Mega.States.Combat.Killaura.Range) == "number" and Mega.States.Combat.Killaura.Range > 25 then
    Mega.States.Combat.Killaura.Range = 25
end

UI.CreateToggleWithSettings(TabFrame, "toggle_killaura", "Combat.Killaura.Enabled", function(state)
    Mega.States.Combat.Killaura.Enabled = state
    if Mega.Features.Killaura and Mega.Features.Killaura.SetEnabled then Mega.Features.Killaura.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_killaura_range", "Combat.Killaura.Range", 5, 22),
    UI.CreateSlider(nil, "slider_killaura_delay", "Combat.Killaura.Delay", 0, 1000),
    UI.CreateKeybindButton(nil, "keybind_killaura", "Keybinds.Killaura"),
    UI.CreateToggle(nil, "toggle_killaura_wallcheck", "Combat.Killaura.WallCheck"),
    UI.CreateToggle(nil, "toggle_killaura_require_aim", "Combat.Killaura.RequireAim"),
    UI.CreateSlider(nil, "slider_killaura_aim_radius", "Combat.Killaura.AimRadius", 10, 500),
    UI.CreateToggle(nil, "toggle_killaura_only_on_click", "Combat.Killaura.OnlyOnClick"),
    UI.CreateToggle(nil, "toggle_killaura_autoclick", "Combat.Killaura.AutoClick"),
    
    (function()
        if not Mega.Localization.Strings["toggle_killaura_target_esp"] then
            Mega.Localization.Strings["toggle_killaura_target_esp"] = { ru = "Показывать цель", en = "Show Target Enemy" }
        end
        return UI.CreateToggle(nil, "toggle_killaura_target_esp", "Combat.Killaura.TargetESP")
    end)(),

    UI.CreateToggle(nil, "toggle_killaura_animation", "Combat.Killaura.AnimationEnabled"),
    UI.CreateDropdown(nil, "dropdown_killaura_animation_mode", "Combat.Killaura.AnimationMode", {"Normal", "Astral", "Smooth", "Exhibition", "Hamsterware", "Horizontal Spin"}, nil, false),
    UI.CreateSlider(nil, "slider_killaura_animation_speed", "Combat.Killaura.AnimationSpeed", 1, 40, function(val) Mega.States.Combat.Killaura.AnimationSpeed = val / 10 end),
})
-- Mobile button registration removed as requested
--#endregion

--#region -- Hit Boxes
UI.CreateSection(TabFrame, "section_combat_hitboxes")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/hitboxes.lua") end)
end)

local hitboxesSettings = {
    UI.CreateDropdown(nil, "dropdown_hitboxes_mode", "Combat.HitBoxes.Mode", {"Sword", "Player"}, function(val)
        Mega.States.Combat.HitBoxes.Mode = val
        if Mega.Features.HitBoxes and Mega.Features.HitBoxes.UpdateSettings then
            Mega.Features.HitBoxes.UpdateSettings()
        end
    end),
    UI.CreateSlider(nil, "slider_hitboxes_expand", "Combat.HitBoxes.ExpandAmount", 0, 15, function(val)
        Mega.States.Combat.HitBoxes.ExpandAmount = val
        if Mega.Features.HitBoxes and Mega.Features.HitBoxes.UpdateSettings then
            Mega.Features.HitBoxes.UpdateSettings()
        end
    end)
}

UI.CreateToggleWithSettings(TabFrame, "toggle_hitboxes", "Combat.HitBoxes.Enabled", function(state)
    Mega.States.Combat.HitBoxes.Enabled = state
    if Mega.Features.HitBoxes and Mega.Features.HitBoxes.SetEnabled then
        Mega.Features.HitBoxes.SetEnabled(state)
    end
end, hitboxesSettings)
--#endregion

--#region -- Bed Nuke
UI.CreateSection(TabFrame, "section_combat_bednuke")

local bedNukeSettings = {
    UI.CreateDropdown(nil, "dropdown_bednuke_sorting", "Combat.BedNuke.Sorting", {"Distance", "Health"}, function(val)
        Mega.States.Combat.BedNuke.Sorting = val
    end),
    UI.CreateSlider(nil, "slider_bednuke_range", "Combat.BedNuke.Range", 1, 30, function(val) 
        Mega.States.Combat.BedNuke.Range = val 
    end),
    UI.CreateSlider(nil, "slider_bednuke_break_speed", "Combat.BedNuke.BreakSpeed", 0, 30, function(val) 
        Mega.States.Combat.BedNuke.BreakSpeed = val / 100 
    end),
    UI.CreateSlider(nil, "slider_bednuke_update_rate", "Combat.BedNuke.UpdateRate", 1, 120, function(val) 
        Mega.States.Combat.BedNuke.UpdateRate = val 
    end),
    UI.CreateToggle(nil, "toggle_bednuke_break_bed", "Combat.BedNuke.BreakBed"),
    UI.CreateToggle(nil, "toggle_bednuke_break_tesla", "Combat.BedNuke.BreakTesla"),
    UI.CreateToggle(nil, "toggle_bednuke_break_hive", "Combat.BedNuke.BreakHive"),
    UI.CreateToggle(nil, "toggle_bednuke_break_lucky", "Combat.BedNuke.BreakLuckyBlock"),
    UI.CreateToggle(nil, "toggle_bednuke_break_iron", "Combat.BedNuke.BreakIronOre"),
    UI.CreateToggle(nil, "toggle_bednuke_self_break", "Combat.BedNuke.SelfBreak"),
    UI.CreateToggle(nil, "toggle_bednuke_instant", "Combat.BedNuke.InstantBreak")
}

UI.CreateToggleWithSettings(TabFrame, "toggle_bednuke", "Combat.BedNuke.Enabled", function(state)
    Mega.States.Combat.BedNuke.Enabled = state
    if Mega.Features.BedNuke and Mega.Features.BedNuke.SetEnabled then
        Mega.Features.BedNuke.SetEnabled(state)
    end
end, bedNukeSettings)
--#endregion

--#region -- Auto Heal
UI.CreateSection(TabFrame, "section_combat_autoheal")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/auto_heal.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_autoheal", "Combat.AutoHeal.Enabled", function(state)
    Mega.States.Combat.AutoHeal.Enabled = state
    if Mega.Features.AutoHeal and Mega.Features.AutoHeal.SetEnabled then
        Mega.Features.AutoHeal.SetEnabled(state)
    end
end, {
    UI.CreateSlider(nil, "slider_autoheal_threshold", "Combat.AutoHeal.Threshold", 1, 100, function(val)
        Mega.States.Combat.AutoHeal.Threshold = val
    end),
    UI.CreateSlider(nil, "slider_autoheal_delay", "Combat.AutoHeal.Delay", 200, 5000, function(val)
        Mega.States.Combat.AutoHeal.Delay = val
    end)
})
--#endregion

-- Removed Auto Buy Section (Not Implemented)
