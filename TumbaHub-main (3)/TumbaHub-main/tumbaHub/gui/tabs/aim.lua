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

UI.CreateToggle(TabFrame, "toggle_aim_prediction", "AimAssist.Prediction")
UI.CreateToggle(TabFrame, "toggle_aim_toggle_mode", "AimAssist.ToggleMode")

UI.CreateSlider(TabFrame, "slider_aim_range", "AimAssist.Range", 10, 1000)
UI.CreateSlider(TabFrame, "slider_aim_speed", "AimAssist.AimSpeed", 1, 100)

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
-- Mobile button registration removed as requested
--#endregion

