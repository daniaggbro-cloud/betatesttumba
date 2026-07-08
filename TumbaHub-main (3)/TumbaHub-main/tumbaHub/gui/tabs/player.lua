-- gui/tabs/player.lua
-- Content for the "PLAYER" tab

local tabKey = "tab_player"
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
ContentLayout.Padding = UDim.new(0, 0) -- Padding is handled by the component frame now

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Movement
UI.CreateSection(TabFrame, "section_player_movement")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/speed.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_speed", "Player.Speed", function(state)
    Mega.States.Player.Speed = state
    if Mega.Features.Speed and Mega.Features.Speed.SetEnabled then Mega.Features.Speed.SetEnabled(state) end
end, {
    UI.CreateDropdown(nil, "dropdown_speed_mode", "Player.SpeedMode", {"Velocity", "Impulse", "CFrame", "TP", "WalkSpeed", "Pulse"}, function(val)
        Mega.States.Player.SpeedMode = val
    end),
    UI.CreateDropdown(nil, "dropdown_speed_move_mode", "Player.SpeedMoveMode", {"MoveDirection", "Direct"}, function(val)
        Mega.States.Player.SpeedMoveMode = val
    end),
    UI.CreateSlider(nil, "slider_speed", "Player.SpeedValue", 1, 150, function(val)
        Mega.States.Player.SpeedValue = val
    end),
    UI.CreateSlider(nil, "slider_speed_tp_frequency", "Player.SpeedTPFrequency", 0, 100, function(val)
        Mega.States.Player.SpeedTPFrequency = val / 100
    end),
    UI.CreateSlider(nil, "slider_speed_pulse_length", "Player.SpeedPulseLength", 0, 100, function(val)
        Mega.States.Player.SpeedPulseLength = val / 100
    end),
    UI.CreateSlider(nil, "slider_speed_pulse_delay", "Player.SpeedPulseDelay", 0, 100, function(val)
        Mega.States.Player.SpeedPulseDelay = val / 100
    end),
    UI.CreateToggle(nil, "toggle_speed_wall_check", "Player.SpeedWallCheck", function(state)
        Mega.States.Player.SpeedWallCheck = state
    end),
    UI.CreateToggle(nil, "toggle_speed_autojump", "Player.SpeedAutoJump", function(state)
        Mega.States.Player.SpeedAutoJump = state
    end),
    UI.CreateToggle(nil, "toggle_speed_customjump", "Player.SpeedCustomJump", function(state)
        Mega.States.Player.SpeedCustomJump = state
    end),
    UI.CreateSlider(nil, "slider_speed_jumppower", "Player.SpeedJumpPower", 1, 100, function(val)
        Mega.States.Player.SpeedJumpPower = val
    end)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fly", "Player.Fly", nil, {
    UI.CreateSlider(nil, "slider_fly_speed", "Player.FlySpeed", 1, 100),
    UI.CreateDropdown(nil, "dropdown_fly_mode", "Player.FlyMode", {"Velocity", "Default"}, function(val)
        Mega.States.Player.FlyMode = val
    end)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/freecam.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_freecam", "Player.Freecam.Enabled", function(state)
    Mega.States.Player.Freecam.Enabled = state
    if Mega.Features.Freecam and Mega.Features.Freecam.SetEnabled then 
        Mega.Features.Freecam.SetEnabled(state) 
    end
end, {
    UI.CreateSlider(nil, "slider_freecam_speed", "Player.Freecam.Speed", 1, 150, function(val)
        Mega.States.Player.Freecam.Speed = val
    end)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/swim.lua") end)
end)

UI.CreateToggle(TabFrame, "toggle_swim", "Player.Swim", function(state)
    Mega.States.Player.Swim = state
    if Mega.Features.Swim and Mega.Features.Swim.SetEnabled then 
        Mega.Features.Swim.SetEnabled(state) 
    end
end)

UI.CreateToggle(TabFrame, "toggle_inf_jump", "Player.InfiniteJump")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/high_jump.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_high_jump", "Player.HighJump", function(state)
    Mega.States.Player.HighJump = state
    if Mega.Features.HighJump and Mega.Features.HighJump.SetEnabled then Mega.Features.HighJump.SetEnabled(state) end
end, {
    UI.CreateDropdown(nil, "dropdown_high_jump_mode", "Player.HighJumpMode", {"Velocity", "CFrame"}, function(val)
        Mega.States.Player.HighJumpMode = val
    end),
    UI.CreateSlider(nil, "slider_high_jump_power", "Player.HighJumpPower", 10, 150),
    UI.CreateToggle(nil, "toggle_high_jump_autodisable", "Player.HighJumpAutoDisable", function(state)
        Mega.States.Player.HighJumpAutoDisable = state
    end)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/wall_hop.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_wall_hop", "Player.WallHop", function(state)
    Mega.States.Player.WallHop = state
    if Mega.Features.WallHop and Mega.Features.WallHop.SetEnabled then Mega.Features.WallHop.SetEnabled(state) end
end, {
    UI.CreateDropdown(nil, "dropdown_wall_hop_mode", "Player.WallHopMode", {"Flick", "Velocity"}, function(val)
        Mega.States.Player.WallHopMode = val
    end),
    UI.CreateSlider(nil, "slider_wall_hop_angle", "Player.WallHopAngle", 45, 120, function(val)
        Mega.States.Player.WallHopAngle = val
    end),
    UI.CreateSlider(nil, "slider_wall_hop_force", "Player.WallHopForce", 10, 100, function(val)
        Mega.States.Player.WallHopForce = val
    end),
    UI.CreateToggle(nil, "toggle_wall_hop_limit_fps", "Player.WallHopLimitFPS", function(state)
        Mega.States.Player.WallHopLimitFPS = state
        if Mega.Features.WallHop and Mega.Features.WallHop.UpdateFPSLimit then
            Mega.Features.WallHop.UpdateFPSLimit()
        end
    end),
    UI.CreateToggle(nil, "toggle_wall_hop_stabilize", "Player.WallHopStabilize", function(state)
        Mega.States.Player.WallHopStabilize = state
    end)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/long_jump.lua") end)
end)

if not Mega.States.Player.LongJumpKeybind then Mega.States.Player.LongJumpKeybind = "None" end

UI.CreateToggleWithSettings(TabFrame, "toggle_long_jump", "Player.LongJump", function(state)
    Mega.States.Player.LongJump = state
    if Mega.Features.LongJump and Mega.Features.LongJump.SetEnabled then Mega.Features.LongJump.SetEnabled(state) end
end, {
    UI.CreateDropdown(nil, "dropdown_long_jump_key", "Player.LongJumpKeybind", {"None", "X", "C", "V", "B", "Z", "R", "F", "G", "T", "Q", "E"}, function(val)
        Mega.States.Player.LongJumpKeybind = val
        if Mega.Features.LongJump and Mega.Features.LongJump.UpdateKeybind then
            Mega.Features.LongJump.UpdateKeybind()
        end
    end),
    UI.CreateSlider(nil, "slider_long_jump_speed", "Player.LongJumpSpeed", 1, 37),
    UI.CreateToggle(nil, "toggle_long_jump_camera", "Player.LongJumpCamera", function(state)
        Mega.States.Player.LongJumpCamera = state
    end)
})

UI.CreateToggle(TabFrame, "toggle_nofall", "Player.NoFall")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/antivoid.lua") end)
end)
UI.CreateToggleWithSettings(TabFrame, "toggle_antivoid", "Player.AntiVoid.Enabled", function(state)
    Mega.States.Player.AntiVoid.Enabled = state
    if Mega.Features.AntiVoid and Mega.Features.AntiVoid.SetEnabled then Mega.Features.AntiVoid.SetEnabled(state) end
end, {
    UI.CreateToggle(nil, "toggle_antivoid_autocalc", "Player.AntiVoid.AutoCalc", function(state)
        Mega.States.Player.AntiVoid.AutoCalc = state
        if Mega.Features.AntiVoid and Mega.Features.AntiVoid.SetAutoCalc then Mega.Features.AntiVoid.SetAutoCalc(state) end
    end),
    UI.CreateSlider(nil, "slider_antivoid_ylevel", "Player.AntiVoid.YLevel", -100, 100),
    UI.CreateToggle(nil, "toggle_antivoid_esp", "Player.AntiVoid.ESP", function(state)
        Mega.States.Player.AntiVoid.ESP = state
        if Mega.Features.AntiVoid and Mega.Features.AntiVoid.UpdateESP then Mega.Features.AntiVoid.UpdateESP() end
    end),
    UI.CreateSlider(nil, "slider_antivoid_esp_transparency", "Player.AntiVoid.ESPTransparency", 0, 100, function(val)
        Mega.States.Player.AntiVoid.ESPTransparency = val / 100
        if Mega.Features.AntiVoid and Mega.Features.AntiVoid.UpdateESP then Mega.Features.AntiVoid.UpdateESP() end
    end)
})
--#endregion

--#region -- Defense / Utility
UI.CreateSection(TabFrame, "section_player_defense")

UI.CreateToggle(TabFrame, "toggle_godmode", "Player.GodMode")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/noclip.lua") end)
end)
UI.CreateToggle(TabFrame, "toggle_noclip", "Player.NoClip", function(state)
    Mega.States.Player.NoClip = state
    if Mega.Features.NoClip and Mega.Features.NoClip.SetEnabled then Mega.Features.NoClip.SetEnabled(state) end
end)

task.spawn(function()
    pcall(function() Mega.LoadModule("features/antiknockback.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_antiknockback", "Player.AntiKnockback", function(state)
    Mega.States.Player.AntiKnockback = state
    if Mega.Features.AntiKnockback and Mega.Features.AntiKnockback.SetEnabled then Mega.Features.AntiKnockback.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_knockback_strength", "Player.KnockbackStrength", 0, 100)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/spider.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_spider", "Player.Spider", function(state)
    Mega.States.Player.Spider = state
    if Mega.Features.Spider and Mega.Features.Spider.SetEnabled then Mega.Features.Spider.SetEnabled(state) end
end, {
    UI.CreateDropdown(nil, "dropdown_spider_mode", "Player.SpiderMode", {"Velocity", "CFrame"}),
    UI.CreateSlider(nil, "slider_spider_speed", "Player.SpiderSpeed", 1, 100)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/scaffold.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_scaffold", "Player.Scaffold.Enabled", function(state)
    Mega.States.Player.Scaffold.Enabled = state
    if Mega.Features.Scaffold and Mega.Features.Scaffold.SetEnabled then Mega.Features.Scaffold.SetEnabled(state) end
end, {
    UI.CreateKeybindButton(nil, "keybind_scaffold", "Keybinds.Scaffold"),
    UI.CreateSlider(nil, "slider_scaffold_yoffset", "Player.Scaffold.YOffset", -100, 0, function(val) Mega.States.Player.Scaffold.YOffset = val / 10 end),
    UI.CreateSlider(nil, "slider_scaffold_predict", "Player.Scaffold.Predict", 0, 100, function(val) Mega.States.Player.Scaffold.Predict = val / 100 end),
})
-- Mobile button registration removed as requested
--#endregion

--#region -- Misc Movement
UI.CreateSection(TabFrame, "section_utils_fun") -- Using existing translation key

task.spawn(function()
    pcall(function() Mega.LoadModule("features/spinbot.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_spinbot", "Player.SpinBot", function(state)
    Mega.States.Player.SpinBot = state
    if Mega.Features.SpinBot and Mega.Features.SpinBot.SetEnabled then Mega.Features.SpinBot.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_spinspeed", "Player.SpinSpeed", 1, 100)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/fastbreak.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_fastbreak", "Player.FastBreak", function(state)
    Mega.States.Player.FastBreak = state
    if Mega.Features.FastBreak and Mega.Features.FastBreak.SetEnabled then Mega.Features.FastBreak.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_break_speed", "Player.BreakSpeed", 1, 10)
})
--#endregion

--#region -- Building
UI.CreateSection(TabFrame, "section_player_building")

task.spawn(function()
    pcall(function() Mega.LoadModule("features/build_reach.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_build_reach", "Player.BuildReach.Enabled", function(state)
    Mega.States.Player.BuildReach.Enabled = state
    if Mega.Features.BuildReach and Mega.Features.BuildReach.SetEnabled then Mega.Features.BuildReach.SetEnabled(state) end
end, {
    UI.CreateSlider(nil, "slider_build_reach_range", "Player.BuildReach.Range", 10, 500),
    UI.CreateSlider(nil, "slider_build_reach_delay", "Player.BuildReach.Delay", 50, 1000)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/bed_defend.lua") end)
end)

UI.CreateToggle(TabFrame, "toggle_bed_defend", "Player.BedDefend", function(state)
    Mega.States.Player.BedDefend = state
    if Mega.Features.BedDefend and Mega.Features.BedDefend.SetEnabled then Mega.Features.BedDefend.SetEnabled(state) end
end)
--#endregion


-- Removed old WalkSpeed loop to allow features/speed.lua to handle it properly.

local env = (getgenv and getgenv()) or shared
if env.TumbaInfJumpConnection then
    pcall(function() env.TumbaInfJumpConnection:Disconnect() end)
    env.TumbaInfJumpConnection = nil
end

env.TumbaInfJumpConnection = Mega.Services.UserInputService.JumpRequest:Connect(function()
    if Mega.States.Player.InfiniteJump then
        local char = Mega.Services.LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
Mega.Objects.Connections.InfiniteJump = env.TumbaInfJumpConnection
