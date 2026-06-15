-- gui/tabs/aim.lua
-- Content for the "AIM" tab

local tabKey = "tab_aim"
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

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Main Aim Settings
UI.CreateSection(TabFrame, "section_aim_main")

UI.CreateToggle(TabFrame, "toggle_aim", "AimAssist.Enabled", function(state)
    -- The actual aimbot logic will be in features/aimbot.lua
    -- and will be controlled by this state change.
    if Mega.Features.Aimbot and Mega.Features.Aimbot.SetAimAssistEnabled then
        Mega.Features.Aimbot.SetAimAssistEnabled(state)
    end
end)
--#endregion

--#region -- Parameter Settings
UI.CreateSection(TabFrame, "section_aim_settings")

UI.CreateToggle(TabFrame, "toggle_aim_show_fov", "AimAssist.ShowFOV")
UI.CreateToggle(TabFrame, "toggle_aim_silent", "AimAssist.SilentAim")
UI.CreateToggle(TabFrame, "toggle_aim_prediction", "AimAssist.Prediction")
UI.CreateToggle(TabFrame, "toggle_aim_target_hud", "AimAssist.TargetHUD")
UI.CreateToggle(TabFrame, "toggle_aim_toggle_mode", "AimAssist.ToggleMode")

-- Tumba V6 Toggles
UI.CreateToggle(TabFrame, "toggle_aim_click", "AimAssist.ClickAim")
UI.CreateToggle(TabFrame, "toggle_aim_mousedown", "AimAssist.RequireMouseDown")
UI.CreateToggle(TabFrame, "toggle_aim_strafe", "AimAssist.StrafeIncrease")
UI.CreateToggle(TabFrame, "toggle_aim_blockbreak", "AimAssist.BlockBreak")
UI.CreateToggle(TabFrame, "toggle_aim_killaura", "AimAssist.KillauraTarget")
UI.CreateToggle(TabFrame, "toggle_aim_limit", "AimAssist.LimitToItems")

UI.CreateSlider(TabFrame, "slider_aim_fov", "AimAssist.FOV", 10, 1500)
UI.CreateSlider(TabFrame, "slider_aim_range", "AimAssist.Range", 10, 1000)
UI.CreateSlider(TabFrame, "slider_aim_speed", "AimAssist.AimSpeed", 1, 20)
UI.CreateSlider(TabFrame, "slider_aim_shake", "AimAssist.Shake", 0, 100)
UI.CreateSlider(TabFrame, "slider_aim_max_angle", "AimAssist.MaxAngle", 1, 360)

UI.CreateDropdown(TabFrame, "dropdown_aim_mode", "AimAssist.Mode", {
    "Simple",
    "Adaptive"
}, function(val)
    Mega.States.AimAssist.Mode = val or "Simple"
end, false)

UI.CreateDropdown(TabFrame, "dropdown_aim_area", "AimAssist.AimArea", {
    "dropdown_aim_area_center",
    "dropdown_aim_area_closest"
}, function(val)
    local areaMap = {
        dropdown_aim_area_center = "Center",
        dropdown_aim_area_closest = "Closest"
    }
    Mega.States.AimAssist.AimArea = areaMap[val] or "Center"
end, true)

UI.CreateDropdown(TabFrame, "dropdown_aim_target", "AimAssist.TargetPart", {
    "dropdown_aim_target_head",
    "dropdown_aim_target_upper",
    "dropdown_aim_target_lower",
    "dropdown_aim_target_root"
}, function(val)
    local partMap = {
        dropdown_aim_target_head = "Head",
        dropdown_aim_target_upper = "UpperTorso",
        dropdown_aim_target_lower = "LowerTorso",
        dropdown_aim_target_root = "HumanoidRootPart"
    }
    Mega.States.AimAssist.TargetPart = partMap[val] or "Head"
end, true)
--#endregion

--#region -- Aim Keybind
UI.CreateSection(TabFrame, "section_aim_key")
UI.CreateKeybindButton(TabFrame, "keybind_aim", "Keybinds.AimAssist")
UI.CreateToggle(TabFrame, "toggle_aim_mobile_btn", "AimAssist.MobileBtn", function(state)
    if Mega.MobileHUD then Mega.MobileHUD.SetVisible("aimassist", state) end
end)

-- Register mobile button
if Mega.MobileHUD then
    Mega.MobileHUD.CreateActionButton("aimassist", "Aim", "rbxassetid://6031215966", function()
        if Mega.States.AimAssist.Enabled then
            Mega.States.AimAssist.Active = not Mega.States.AimAssist.Active
        else
            if Mega.ShowNotification then
                Mega.ShowNotification("Enable Aim Assist first!", 2, Color3.fromRGB(255, 100, 100))
            end
        end
    end, function() return Mega.States.AimAssist.Active and Mega.States.AimAssist.Enabled end)
    
    task.spawn(function()
        task.wait(1)
        Mega.MobileHUD.SetVisible("aimassist", Mega.States.AimAssist.MobileBtn)
    end)
end
--#endregion

