-- gui/tabs/farm.lua
-- Content for the "KIT" (Farm) tab

local tabKey = "tab_farm"
local UI = Mega.UI

-- Ensure states exist to prevent errors (Fallback defaults)
if not Mega.States.Beekeeper then Mega.States.Beekeeper = { Enabled = false, ShowIcons = true, ShowHighlight = true, ShowHiveLevels = false, AutoCatch = false } end
if not Mega.States.Cletus then Mega.States.Cletus = { Enabled = false, Range = 20, AutoHarvest = false, ESP = false, ESPTransparency = 0.75 } end
if not Mega.States.Eldertree then Mega.States.Eldertree = { Enabled = false, Range = 30, ESP = false, AutoCollect = false } end
if not Mega.States.StarCollector then Mega.States.StarCollector = { Enabled = false, Range = 60, ESP = false, AutoCollect = false } end
if not Mega.States.Metal then Mega.States.Metal = { Enabled = false, ESP = true, AutoCollect = false, AutoCollectLegit = false, Range = 25 } end
if not Mega.States.Taliah then Mega.States.Taliah = { Enabled = false, ESP = false, ESPTransparency = 0.2, AutoCollect = false, AutoCollectLegit = false, CollectRadius = 5 } end
if not Mega.States.Fisherman then Mega.States.Fisherman = { Enabled = false } end
if not Mega.States.Noelle then Mega.States.Noelle = { Enabled = false, SaveBinds = false, Binds = {} } end
if not Mega.States.Lucia then Mega.States.Lucia = { Enabled = false, ESP = false, AutoDeposit = false, Range = 20, Legit = false } end
if not Mega.States.Misc then Mega.States.Misc = {} end
if not Mega.States.Misc.Adetunde then Mega.States.Misc.Adetunde = { Enabled = false, Range = 50, Delay = 0, TargetESP = true, Keybind = "None" } end
if not Mega.States.Misc.Alchemist then Mega.States.Misc.Alchemist = { Enabled = false, AutoCollect = true, ESP = true } end
if not Mega.States.Combat then Mega.States.Combat = {} end
if not Mega.States.Combat.AutoDavey then Mega.States.Combat.AutoDavey = { Enabled = false, JumpOnImpact = false, BreakOnImpact = false, LegitSwitch = false } end
if not Mega.States.RavenKit then Mega.States.RavenKit = { Enabled = false } end
if not Mega.States.RavenESP then Mega.States.RavenESP = { RemoveFog = true } elseif Mega.States.RavenESP.RemoveFog == nil then Mega.States.RavenESP.RemoveFog = true end
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
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)
TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)

Mega.Objects.TabFrames[tabKey] = TabFrame

local function notifyFeature(key, state)
    -- Handled automatically by ui_builder.lua
end



--#region -- Beekeeper
UI.CreateToggleWithSettings(TabFrame, "toggle_beekeeper", "Beekeeper.Enabled", function(state)
    if Mega.Features.Beekeeper then
        Mega.Features.Beekeeper.SetEnabled(state)
    end
    notifyFeature("toggle_beekeeper", state)
end, {
    UI.CreateToggle(nil, "toggle_bee_icons", "Beekeeper.ShowIcons", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_bee_highlight", "Beekeeper.ShowHighlight", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_hive_levels", "Beekeeper.ShowHiveLevels", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_auto_catch", "Beekeeper.AutoCatch")
}, "beekeeper")
--#endregion

--#region -- Cletus
UI.CreateToggleWithSettings(TabFrame, "toggle_cletus", "Cletus.Enabled", function(state)
    if Mega.Features.Cletus then
        Mega.Features.Cletus.SetEnabled(state)
    end
    notifyFeature("toggle_cletus", state)
end, {
    UI.CreateToggle(nil, "toggle_cletus_harvest", "Cletus.AutoHarvest"),
    UI.CreateToggle(nil, "toggle_cletus_autobuy", "Cletus.AutoBuyMelons"),
    UI.CreateSlider(nil, "slider_cletus_maxprice", "Cletus.MaxMelonPrice", 1, 10),
    UI.CreateSlider(nil, "slider_cletus_maxamount", "Cletus.AutoBuyMaxAmount", 1, 64),
    UI.CreateSlider(nil, "slider_cletus_autobuyspeed", "Cletus.AutoBuySpeed", 0.1, 5),
    UI.CreateToggle(nil, "toggle_cletus_esp", "Cletus.ESP", function() if Mega.Features.Cletus then Mega.Features.Cletus.RecreateESP() end end),
    UI.CreateSlider(nil, "slider_cletus_range", "Cletus.Range", 5, 100),
    UI.CreateSlider(nil, "slider_cletus_esp_transparency", "Cletus.ESPTransparency", 0, 100, function(v) Mega.States.Cletus.ESPTransparency = v/100; if Mega.Features.Cletus then Mega.Features.Cletus.UpdateVisuals() end end)
}, "cletus")
--#endregion

--#region -- Eldertree
task.spawn(function()
    pcall(function() Mega.LoadModule("features/eldertree.lua") end)
    pcall(function() Mega.LoadModule("eldertree.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_eldertree", "Eldertree.Enabled", function(state)
    Mega.States.Eldertree.Enabled = state
    if Mega.Features.Eldertree then
        Mega.Features.Eldertree.SetEnabled(state)
    end
    notifyFeature("toggle_eldertree", state)
end, {
    UI.CreateToggle(nil, "toggle_eldertree_autocollect", "Eldertree.AutoCollect", function(state)
        Mega.States.Eldertree.AutoCollect = state
        if Mega.Features.Eldertree and Mega.Features.Eldertree.SetAutoCollect then Mega.Features.Eldertree.SetAutoCollect(state) end
    end),
    UI.CreateToggle(nil, "toggle_eldertree_esp", "Eldertree.ESP", function(state)
        Mega.States.Eldertree.ESP = state
        if Mega.Features.Eldertree and Mega.Features.Eldertree.UpdateESP then Mega.Features.Eldertree.UpdateESP() end
    end),
    UI.CreateSlider(nil, "slider_eldertree_range", "Eldertree.Range", 5, 100, function(val)
        Mega.States.Eldertree.Range = val
    end)
}, "eldertree")
--#endregion

--#region -- Star Collector
task.spawn(function()
    pcall(function() Mega.LoadModule("features/stella_star_collector.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_star_collector", "StarCollector.Enabled", function(state)
    Mega.States.StarCollector.Enabled = state
    if Mega.Features.StarCollector then Mega.Features.StarCollector.SetEnabled(state) end
    notifyFeature("toggle_star_collector", state)
end, {
    UI.CreateToggle(nil, "toggle_star_collector_autocollect", "StarCollector.AutoCollect"),
    UI.CreateToggle(nil, "toggle_star_collector_esp", "StarCollector.ESP", function(state)
        Mega.States.StarCollector.ESP = state
        if Mega.Features.StarCollector then Mega.Features.StarCollector.UpdateESP() end
    end),
    UI.CreateSlider(nil, "slider_star_collector_range", "StarCollector.Range", 5, 100, function(val)
        Mega.States.StarCollector.Range = val
    end)
}, "star_collector")
--#endregion

--#region -- Metal Detector
task.spawn(function()
    pcall(function() Mega.LoadModule("features/metal_detector.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_metal", "Metal.Enabled", function(state)
    Mega.States.Metal.Enabled = state
    if Mega.Features.Metal then Mega.Features.Metal.SetEnabled(state) end
    notifyFeature("toggle_metal", state)
end, {
    UI.CreateToggle(nil, "toggle_metal_esp", "Metal.ESP", function(state)
        Mega.States.Metal.ESP = state
        if Mega.Features.Metal then Mega.Features.Metal.UpdateESP() end
    end),
    UI.CreateToggle(nil, "toggle_metal_collect", "Metal.AutoCollect"),
    UI.CreateToggle(nil, "toggle_metal_collect_legit", "Metal.AutoCollectLegit"),
    UI.CreateSlider(nil, "slider_metal_range", "Metal.Range", 5, 100)
}, "metal")
--#endregion

--#region -- Taliah
UI.CreateToggleWithSettings(TabFrame, "toggle_taliah", "Taliah.Enabled", function(state)
    Mega.States.Taliah.Enabled = state
    if Mega.Features.Taliah and Mega.Features.Taliah.SetEnabled then Mega.Features.Taliah.SetEnabled(state) end
    notifyFeature("toggle_taliah", state)
end, {
    UI.CreateToggle(nil, "toggle_taliah_esp", "Taliah.ESP"),
    UI.CreateToggle(nil, "toggle_taliah_collect", "Taliah.AutoCollect"),
    UI.CreateToggle(nil, "toggle_taliah_collect_legit", "Taliah.AutoCollectLegit"),
    UI.CreateSlider(nil, "slider_taliah_radius", "Taliah.CollectRadius", 5, 50),
    UI.CreateSlider(nil, "slider_taliah_esp_transparency", "Taliah.ESPTransparency", 0, 100, function(v) Mega.States.Taliah.ESPTransparency = v/100 end)
}, "taliah")
--#endregion

--#region -- Fisherman
UI.CreateToggle(TabFrame, "toggle_autofish", "Fisherman.Enabled", nil, "fisherman")
--#endregion



--#region -- Alchemist
task.spawn(function()
    pcall(function() Mega.LoadModule("features/alchemist.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_alchemist", "Misc.Alchemist.Enabled", function(state)
    if Mega.Features.Alchemist and Mega.Features.Alchemist.SetEnabled then
        Mega.Features.Alchemist.SetEnabled(state)
    end
    notifyFeature("toggle_alchemist", state)
end, {
    UI.CreateToggle(nil, "toggle_alchemist_esp", "Misc.Alchemist.ESP"),
    UI.CreateToggle(nil, "toggle_alchemist_autocollect", "Misc.Alchemist.AutoCollect")
})
--#endregion

--#region -- Noelle
local noelleContainer = Instance.new("Frame")
noelleContainer.Name = "NoelleContainer"
noelleContainer.Size = UDim2.new(1, 0, 0, 250)
noelleContainer.BackgroundTransparency = 1
Mega.Objects.NoelleContainer = noelleContainer

task.spawn(function()
    pcall(function() Mega.LoadModule("features/noelle.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_noelle", "Noelle.Enabled", function(state)
    Mega.States.Noelle.Enabled = state
    if Mega.Features.Noelle and Mega.Features.Noelle.SetEnabled then Mega.Features.Noelle.SetEnabled(state) end
    notifyFeature("toggle_noelle", state)
end, {
    UI.CreateToggle(nil, "toggle_noelle_save_binds", "Noelle.SaveBinds"),
    noelleContainer
}, "noelle")
--#endregion

--#region -- Lani

local laniContainer = Instance.new("Frame")
laniContainer.Name = "LaniContainer"
laniContainer.Size = UDim2.new(1, 0, 0, 200)
laniContainer.BackgroundTransparency = 1
Mega.Objects.LaniContainer = laniContainer

task.spawn(function()
    pcall(function() Mega.LoadModule("features/lani.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_lani", "Misc.Lani.Enabled", function(state)
    Mega.States.Misc.Lani.Enabled = state
    if Mega.Features.Lani and Mega.Features.Lani.RefreshPlayers then Mega.Features.Lani.RefreshPlayers() end
    notifyFeature("toggle_lani", state)
end, {
    UI.CreateKeybindButton(nil, "keybind_lani", "Misc.Lani.Keybind", function(key)
        Mega.States.Misc.Lani.Keybind = key
        if Mega.Features.Lani and Mega.Features.Lani.UpdateKeybind then
            Mega.Features.Lani.UpdateKeybind()
        end
    end),
    laniContainer
})
--#endregion

--#region -- Lucia (Pinata)
task.spawn(function()
    pcall(function() Mega.LoadModule("features/lucia.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_lucia", "Lucia.Enabled", function(state)
    Mega.States.Lucia.Enabled = state
    if Mega.Features.Lucia and Mega.Features.Lucia.SetEnabled then Mega.Features.Lucia.SetEnabled(state) end
    notifyFeature("toggle_lucia", state)
end, {
    UI.CreateToggle(nil, "toggle_lucia_esp", "Lucia.ESP"),
    UI.CreateToggle(nil, "toggle_lucia_deposit", "Lucia.AutoDeposit"),
    UI.CreateToggle(nil, "toggle_lucia_legit", "Lucia.Legit"),
    UI.CreateSlider(nil, "slider_lucia_range", "Lucia.Range", 5, 50)
}, "lucia")
--#endregion

--#region -- Auto Davey
task.spawn(function()
    pcall(function() Mega.LoadModule("features/auto_davey.lua") end)
end)

UI.CreateToggleWithSettings(TabFrame, "toggle_autodavey", "Combat.AutoDavey.Enabled", function(state)
    Mega.States.Combat.AutoDavey.Enabled = state
    if Mega.Features.AutoDavey and Mega.Features.AutoDavey.SetEnabled then Mega.Features.AutoDavey.SetEnabled(state) end
    notifyFeature("toggle_autodavey", state)
end, {
    UI.CreateToggle(nil, "toggle_autodavey_jump", "Combat.AutoDavey.JumpOnImpact"),
    UI.CreateToggle(nil, "toggle_autodavey_break", "Combat.AutoDavey.BreakOnImpact"),
    UI.CreateToggle(nil, "toggle_autodavey_legitswitch", "Combat.AutoDavey.LegitSwitch")
}, "piratedavey")
--#endregion

--#region -- Raven
do
    local loc = Mega.Localization.Strings
    if not loc["section_raven_farm"] then
        loc["section_raven_farm"] = { ru = "Raven", en = "Raven" }
        loc["toggle_raven_kit"] = { ru = "Raven", en = "Raven" }
        loc["toggle_raven_antifog"] = { ru = "Убрать чёрный туман", en = "Remove Black Fog" }
    end
    
    UI.CreateToggleWithSettings(TabFrame, "toggle_raven_kit", "RavenKit.Enabled", function(state)
        Mega.States.RavenKit.Enabled = state
        -- When the kit is enabled, if AntiFog is on, we make sure it's active.
        -- But AntiFog itself reacts to its own toggle as well.
        if state and Mega.States.RavenESP.RemoveFog then
            if not Mega.Features.RavenAntiFog then
                Mega.LoadModule("features/raven_antifog.lua")
            end
            if Mega.Features.RavenAntiFog and Mega.Features.RavenAntiFog.SetEnabled then
                Mega.Features.RavenAntiFog.SetEnabled(true)
            end
        elseif not state then
            -- Disable anti-fog when kit is disabled? Up to preference, but let's do it
            if Mega.Features.RavenAntiFog and Mega.Features.RavenAntiFog.SetEnabled then
                Mega.Features.RavenAntiFog.SetEnabled(false)
            end
        end
    end, {
        UI.CreateToggle(nil, "toggle_raven_antifog", "RavenESP.RemoveFog", function(state)
            if not Mega.States.RavenKit.Enabled then return end
            if not Mega.Features.RavenAntiFog then
                Mega.LoadModule("features/raven_antifog.lua")
            end
            if Mega.Features.RavenAntiFog and Mega.Features.RavenAntiFog.SetEnabled then
                Mega.Features.RavenAntiFog.SetEnabled(state)
            end
        end)
    }, "raven")
end
--#endregion
