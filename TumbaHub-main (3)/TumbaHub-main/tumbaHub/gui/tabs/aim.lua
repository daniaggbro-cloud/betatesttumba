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
    if Mega.Features.Aimbot then
        Mega.Features.Aimbot.SetEnabled(state)
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

UI.CreateSlider(TabFrame, "slider_aim_fov", "AimAssist.FOV", 10, 1500)
UI.CreateSlider(TabFrame, "slider_aim_smooth", "AimAssist.Smoothness", 0, 100, function(val)
    Mega.States.AimAssist.Smoothness = val / 100 -- Convert from 0-100 to 0-1
end)
UI.CreateSlider(TabFrame, "slider_aim_range", "AimAssist.Range", 10, 1000)

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
end, true) -- true indicates options are localization keys

UI.CreateButton(TabFrame, "button_aim_fov_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end)
--#endregion

--#region -- Aim Keybind
UI.CreateSection(TabFrame, "section_aim_key")
UI.CreateKeybindButton(TabFrame, "keybind_aim", "Keybinds.AimAssist")
--#endregion

