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

UI.CreateToggleWithSettings(TabFrame, "toggle_speed", "Player.Speed", nil, {
    UI.CreateSlider(nil, "slider_speed", "Player.SpeedValue", 16, 200)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fly", "Player.Fly", nil, {
    UI.CreateSlider(nil, "slider_fly_speed", "Player.FlySpeed", 1, 100),
    UI.CreateDropdown(nil, "dropdown_fly_mode", "Player.FlyMode", {"Velocity", "Default"}, function(val)
        Mega.States.Player.FlyMode = val
    end)
})


UI.CreateToggle(TabFrame, "toggle_inf_jump", "Player.InfiniteJump")
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
    UI.CreateToggle(nil, "toggle_scaffold_mobile_btn", "Player.Scaffold.MobileBtn", function(state)
        if Mega.MobileHUD then Mega.MobileHUD.SetVisible("scaffold", state) end
    end)
})

-- Register mobile button
if Mega.MobileHUD then
    Mega.MobileHUD.CreateActionButton("scaffold", "Scaffold", "rbxassetid://6034818379", function()
        local newState = not Mega.States.Player.Scaffold.Enabled
        if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_scaffold"] then
            Mega.Objects.Toggles["toggle_scaffold"](newState)
        end
    end, function() return Mega.States.Player.Scaffold.Enabled end)
    
    task.spawn(function()
        task.wait(1)
        Mega.MobileHUD.SetVisible("scaffold", Mega.States.Player.Scaffold.MobileBtn)
    end)
end
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
--#endregion


-- Simple player logic that can live here
local function onRenderStep()
    local char = Mega.Services.LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    if Mega.States.Player.Speed then
        humanoid.WalkSpeed = Mega.States.Player.SpeedValue
    else
        if humanoid.WalkSpeed == Mega.States.Player.SpeedValue then
             humanoid.WalkSpeed = 16 -- Default speed
        end
    end
end

Mega.Objects.Connections.PlayerTabSpeed = Mega.Services.RunService.RenderStepped:Connect(onRenderStep)

-- Подключаем Infinite Jump ровно один раз, чтобы избежать утечки памяти и лагов
if not Mega.Objects.Connections.InfiniteJump then
    Mega.Objects.Connections.InfiniteJump = Mega.Services.UserInputService.JumpRequest:Connect(function()
        if Mega.States.Player.InfiniteJump then
            local char = Mega.Services.LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end
