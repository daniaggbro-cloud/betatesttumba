-- gui/tabs/utils.lua
-- Content for the "UTILITIES" tab

local tabKey = "tab_utils"
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
ContentLayout.Padding = UDim.new(0, 0)

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- General Tools
UI.CreateSection(TabFrame, "section_utils_tools")

UI.CreateButton(TabFrame, "button_clear_chat", function()
    for i = 1, 50 do
        Mega.Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(string.rep(" ", i), "All")
    end
    Mega.ShowNotification(Mega.GetText("notify_chat_cleared"), 2)
end)

UI.CreateButton(TabFrame, "button_screenshot", function() Mega.ShowNotification("Not implemented yet", 2) end)
UI.CreateButton(TabFrame, "button_server_info", function() Mega.ShowNotification("Not implemented yet", 2) end)

local kitBanContainer = Instance.new("Frame")
kitBanContainer.Name = "KitBanContainer"
kitBanContainer.Size = UDim2.new(1, 0, 0, 300)
kitBanContainer.BackgroundTransparency = 1
Mega.Objects.KitBanContainer = kitBanContainer

if not Mega.States.Misc.KitBan then Mega.States.Misc.KitBan = {} end
Mega.States.Misc.KitBan.Enabled = false

UI.CreateToggleWithSettings(TabFrame, "toggle_kit_ban", "Misc.KitBan.Enabled", function(state)
    Mega.States.Misc.KitBan.Enabled = state
    if state then
        if Mega.Features.KitBan and Mega.Features.KitBan.ExecuteBan then
            Mega.Features.KitBan.ExecuteBan()
        end
        
        task.spawn(function()
            task.wait(0.2)
            Mega.States.Misc.KitBan.Enabled = false
            if Mega.Objects.Toggles and Mega.Objects.Toggles["toggle_kit_ban"] then
                Mega.Objects.Toggles["toggle_kit_ban"](false)
            end
            notifyFeature("toggle_kit_ban", false)
        end)
    else
        notifyFeature("toggle_kit_ban", false)
    end
end, {
    kitBanContainer
})

UI.CreateButton(TabFrame, "button_reload_script", function()
    Mega.ShowNotification(Mega.GetText("notify_reload"), 2)
    if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
    Mega.LoadModule("gui/main_window.lua")
end)
--#endregion

--#region -- Fun / Misc
UI.CreateSection(TabFrame, "section_utils_fun")

UI.CreateToggle(TabFrame, "toggle_fame_spam", "Misc.FameSpam")
UI.CreateToggle(TabFrame, "toggle_fames_mom", "Misc.FamesMom")
--#endregion

--#region -- Auto-Honor
task.spawn(function()
    pcall(function() Mega.LoadModule("features/auto_honor.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_auto_honor", "Misc.AutoHonor.Enabled", function(state)
    Mega.States.Misc.AutoHonor.Enabled = state
    if Mega.Features.AutoHonor and Mega.Features.AutoHonor.SetEnabled then Mega.Features.AutoHonor.SetEnabled(state) end
    if Mega.ShowNotification then
        Mega.ShowNotification((Mega.GetText("toggle_auto_honor") or "Auto Honor") .. ": " .. (state and Mega.GetText("notify_enabled") or Mega.GetText("notify_disabled")), 2)
    end
end, {
    UI.CreateDropdown(nil, "dropdown_auto_honor_target", "Misc.AutoHonor.Target", {"Teammate", "Enemy"}, function(val) Mega.States.Misc.AutoHonor.Target = val end)
})
--#endregion

--#region -- Auto-Loot

task.spawn(function()
    pcall(function() Mega.LoadModule("features/chest_steal.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_chest_steal", "Misc.ChestSteal.Enabled", function(state)
    Mega.States.Misc.ChestSteal.Enabled = state
    if Mega.Features.ChestSteal and Mega.Features.ChestSteal.SetEnabled then Mega.Features.ChestSteal.SetEnabled(state) end
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("toggle_chest_steal") .. ": " .. (state and Mega.GetText("notify_enabled") or Mega.GetText("notify_disabled")), 2)
    end
end, {
    UI.CreateSlider(nil, "slider_chest_steal_range", "Misc.ChestSteal.Range", 5, 50)
})

task.spawn(function()
    pcall(function() Mega.LoadModule("features/chest_esp.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_chest_esp", "Misc.ChestESP.Enabled", function(state)
    Mega.States.Misc.ChestESP.Enabled = state
    if Mega.Features.ChestESP and Mega.Features.ChestESP.SetEnabled then Mega.Features.ChestESP.SetEnabled(state) end
    if Mega.ShowNotification then
        Mega.ShowNotification((Mega.GetText("toggle_chest_esp") or "Chest ESP") .. ": " .. (state and Mega.GetText("notify_enabled") or Mega.GetText("notify_disabled")), 2)
    end
end, {
    UI.CreateSlider(nil, "slider_chest_esp_range", "Misc.ChestESP.MaxDistance", 50, 1000)
})
--#endregion

--#region -- Auto-Deposit

task.spawn(function()
    pcall(function() Mega.LoadModule("features/auto_deposit.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_auto_deposit", "Misc.AutoDeposit.Enabled", function(state)
    Mega.States.Misc.AutoDeposit.Enabled = state
    if Mega.Features.AutoDeposit and Mega.Features.AutoDeposit.SetEnabled then Mega.Features.AutoDeposit.SetEnabled(state) end
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("toggle_auto_deposit") .. ": " .. (state and Mega.GetText("notify_enabled") or Mega.GetText("notify_disabled")), 2)
    end
end, {
    UI.CreateSlider(nil, "slider_auto_deposit_range", "Misc.AutoDeposit.Range", 5, 50),
    UI.CreateSection(nil, "section_deposit_resources"),
    UI.CreateToggle(nil, "toggle_deposit_iron", "Misc.AutoDeposit.Resources.iron"),
    UI.CreateToggle(nil, "toggle_deposit_diamond", "Misc.AutoDeposit.Resources.diamond"),
    UI.CreateToggle(nil, "toggle_deposit_emerald", "Misc.AutoDeposit.Resources.emerald"),
    UI.CreateToggle(nil, "toggle_deposit_gold", "Misc.AutoDeposit.Resources.gold"),
    UI.CreateToggle(nil, "toggle_deposit_void_crystal", "Misc.AutoDeposit.Resources.void_crystal"),
    UI.CreateToggle(nil, "toggle_deposit_wood", "Misc.AutoDeposit.Resources.wood"),
    UI.CreateToggle(nil, "toggle_deposit_stone", "Misc.AutoDeposit.Resources.stone")
})
--#endregion
