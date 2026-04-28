-- features/kit_ban.lua
-- Logic for Kit Ban functionality (Ranked)

if not Mega.Features then Mega.Features = {} end
Mega.Features.KitBan = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService")
}
local States = Mega.States

if not Mega.Objects.KitBanConnections then Mega.Objects.KitBanConnections = {} end
local connections = Mega.Objects.KitBanConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local allKits = {
    {id = "aery", name = "Aery", icon = "rbxassetid://9155463221"},
    {id = "agni", name = "Agni", icon = "rbxassetid://17024640133"},
    {id = "airbender", name = "Ramil", icon = "rbxassetid://74712750354593"},
    {id = "alchemist", name = "Alchemist", icon = "rbxassetid://9155462512"},
    {id = "angel", name = "Trinity", icon = "rbxassetid://9166208240"},
    {id = "archer", name = "Archer", icon = "rbxassetid://9224796984"},
    {id = "axolotl", name = "Axolotl Amy", icon = "rbxassetid://9155466713"},
    {id = "baker", name = "Baker", icon = "rbxassetid://9155463919"},
    {id = "barbarian", name = "Barbarian", icon = "rbxassetid://9166207628"},
    {id = "battery", name = "Cobalt", icon = "rbxassetid://10159166528"},
    {id = "beast", name = "Crocowolf", icon = "rbxassetid://9155465124"},
    {id = "beekeeper", name = "Beekeeper Beatrix", icon = "rbxassetid://9312831285"},
    {id = "berserker", name = "Ragnar", icon = "rbxassetid://90258047545241"},
    {id = "bigman", name = "Eldertree", icon = "rbxassetid://9155467211"},
    {id = "black_market_trader", name = "Wren", icon = "rbxassetid://18922642482"},
    {id = "block_kicker", name = "Terra", icon = "rbxassetid://15382536098"},
    {id = "blood_assassin", name = "Caitlyn", icon = "rbxassetid://12520290159"},
    {id = "bounty_hunter", name = "Bounty Hunter", icon = "rbxassetid://9166208649"},
    {id = "builder", name = "Builder", icon = "rbxassetid://9155463708"},
    {id = "cactus", name = "Martin", icon = "rbxassetid://104436517801089"},
    {id = "card", name = "Fortuna", icon = "rbxassetid://13841410580"},
    {id = "cat", name = "Yamini", icon = "rbxassetid://15350740470"},
    {id = "cowgirl", name = "Lassy", icon = "rbxassetid://9155462968"},
    {id = "cyber", name = "Cyber", icon = "rbxassetid://9507126891"},
    {id = "dasher", name = "Yuzi", icon = "rbxassetid://9155467645"},
    {id = "davey", name = "Pirate Davey", icon = "rbxassetid://9155464612"},
    {id = "defender", name = "Marcel", icon = "rbxassetid://116567110607862"},
    {id = "dino_tamer", name = "Dino Tamer Dom", icon = "rbxassetid://9872357009"},
    {id = "disruptor", name = "Zenith", icon = "rbxassetid://11596993583"},
    {id = "dragon_slayer", name = "Kaliyah", icon = "rbxassetid://10982192175"},
    {id = "dragon_sword", name = "Lian", icon = "rbxassetid://16215630104"},
    {id = "drill", name = "Drill", icon = "rbxassetid://12955100280"},
    {id = "elektra", name = "Elektra", icon = "rbxassetid://13841413050"},
    {id = "elk_master", name = "Sigrid", icon = "rbxassetid://15714972287"},
    {id = "ember", name = "Ember", icon = "rbxassetid://9630017904"},
    {id = "falconer", name = "Bekzat", icon = "rbxassetid://17022941869"},
    {id = "farmer_cletus", name = "Farmer Cletus", icon = "rbxassetid://9155466936"},
    {id = "fisherman", name = "Fisherman", icon = "rbxassetid://9166208359"},
    {id = "flower_bee", name = "Lyla", icon = "rbxassetid://101569742252812"},
    {id = "frost_hammer_kit", name = "Adetunde", icon = "rbxassetid://11838567073"},
    {id = "frosty", name = "Frosty", icon = "rbxassetid://9166208762"},
    {id = "ghost_catcher", name = "Gompy", icon = "rbxassetid://9224802656"},
    {id = "gingerbread_man", name = "Gingerbread Man", icon = "rbxassetid://9155464364"},
    {id = "glacial_skater", name = "Krystal", icon = "rbxassetid://84628060516931"},
    {id = "grim_reaper", name = "Grim Reaper", icon = "rbxassetid://9155467410"},
    {id = "gun_blade", name = "Zarrah", icon = "rbxassetid://138231219644853"},
    {id = "hannah", name = "Hannah", icon = "rbxassetid://10726577232"},
    {id = "harpoon", name = "Triton", icon = "rbxassetid://18250634847"},
    {id = "hatter", name = "Umbra", icon = "rbxassetid://12509388633"},
    {id = "ice_queen", name = "Freiya", icon = "rbxassetid://9155466204"},
    {id = "ignis", name = "Ignis", icon = "rbxassetid://13835258938"},
    {id = "jade", name = "Jade", icon = "rbxassetid://9166306816"},
    {id = "jailor", name = "Warden", icon = "rbxassetid://11664116980"},
    {id = "jellyfish", name = "Marina", icon = "rbxassetid://18129974852"},
    {id = "lumen", name = "Lumen", icon = "rbxassetid://9630018371"},
    {id = "mage", name = "Whim", icon = "rbxassetid://10982191792"},
    {id = "melody", name = "Melody", icon = "rbxassetid://9155464915"},
    {id = "merchant", name = "Merchant Marco", icon = "rbxassetid://9872356790"},
    {id = "metal_detector", name = "Metal Detector", icon = "rbxassetid://9378298061"},
    {id = "midnight", name = "Nyx", icon = "rbxassetid://9155462763"},
    {id = "mimic", name = "Milo", icon = "rbxassetid://14783283296"},
    {id = "miner", name = "Miner", icon = "rbxassetid://9166208461"},
    {id = "nazar", name = "Nazar", icon = "rbxassetid://18926951849"},
    {id = "necromancer", name = "Crypt", icon = "rbxassetid://11343458097"},
    {id = "ninja", name = "Umeko", icon = "rbxassetid://15517037848"},
    {id = "none", name = "None", icon = "rbxassetid://16493320215"},
    {id = "nyoka", name = "Nyoka", icon = "rbxassetid://17022941410"},
    {id = "oasis", name = "Nahla", icon = "rbxassetid://120283205213823"},
    {id = "oil_man", name = "Jack", icon = "rbxassetid://9166206259"},
    {id = "owl", name = "Whisper", icon = "rbxassetid://12509401147"},
    {id = "paladin", name = "Lani", icon = "rbxassetid://11202785737"},
    {id = "pinata", name = "Lucia", icon = "rbxassetid://10011261147"},
    {id = "pyro", name = "Pyro", icon = "rbxassetid://9155464770"},
    {id = "queen_bee", name = "Flora", icon = "rbxassetid://12671498918"},
    {id = "random", name = "Random", icon = "rbxassetid://79773209697352"},
    {id = "raven", name = "Raven", icon = "rbxassetid://9166206554"},
    {id = "rebellion_leader", name = "Silas", icon = "rbxassetid://18926409564"},
    {id = "regent", name = "Void Regent", icon = "rbxassetid://9166208904"},
    {id = "santa", name = "Santa", icon = "rbxassetid://9166206101"},
    {id = "scarab", name = "Abaddon", icon = "rbxassetid://137137517627492"},
    {id = "seahorse", name = "Sheila", icon = "rbxassetid://11902552560"},
    {id = "sheep_herder", name = "Sheep Herder", icon = "rbxassetid://9155465730"},
    {id = "shielder", name = "Infernal Shielder", icon = "rbxassetid://9155464114"},
    {id = "skeleton", name = "Marrow", icon = "rbxassetid://120123419412119"},
    {id = "slime_tamer", name = "Noelle", icon = "rbxassetid://15379766168"},
    {id = "smoke", name = "Smoke", icon = "rbxassetid://9155462247"},
    {id = "sorcerer", name = "Death Adder", icon = "rbxassetid://97940108361528"},
    {id = "spearman", name = "Ares", icon = "rbxassetid://9166207341"},
    {id = "spider_queen", name = "Arachne", icon = "rbxassetid://95237509752482"},
    {id = "spirit_assassin", name = "Evelynn", icon = "rbxassetid://10406002412"},
    {id = "spirit_catcher", name = "Spirit Catcher", icon = "rbxassetid://9166207943"},
    {id = "spirit_gardener", name = "Grove", icon = "rbxassetid://132108376114488"},
    {id = "spirit_summoner", name = "Uma", icon = "rbxassetid://95760990786863"},
    {id = "star_collector", name = "Star Collector Stella", icon = "rbxassetid://9872356516"},
    {id = "steam_engineer", name = "Cogsworth", icon = "rbxassetid://15380413567"},
    {id = "styx", name = "Styx", icon = "rbxassetid://17014536631"},
    {id = "summoner", name = "Kaida", icon = "rbxassetid://18922378956"},
    {id = "sword_shield", name = "Isabel", icon = "rbxassetid://131690429591874"},
    {id = "taliyah", name = "Taliyah", icon = "rbxassetid://13989437601"},
    {id = "tinker", name = "Hephaestus", icon = "rbxassetid://17025762404"},
    {id = "trapper", name = "Trapper", icon = "rbxassetid://9166206875"},
    {id = "triple_shot", name = "Vanessa", icon = "rbxassetid://9166208149"},
    {id = "vesta", name = "Conqueror", icon = "rbxassetid://9568930198"},
    {id = "void_dragon", name = "Xu'rot", icon = "rbxassetid://10982192753"},
    {id = "void_hunter", name = "Skoll", icon = "rbxassetid://122370766273698"},
    {id = "void_knight", name = "Void Knight", icon = "rbxassetid://73636326782144"},
    {id = "void_walker", name = "Trixie", icon = "rbxassetid://78915127961078"},
    {id = "vulcan", name = "Vulcan", icon = "rbxassetid://9155465543"},
    {id = "warlock", name = "Eldric", icon = "rbxassetid://15186338366"},
    {id = "warrior", name = "Warrior", icon = "rbxassetid://9166207008"},
    {id = "wind_walker", name = "Zephyr", icon = "rbxassetid://9872355499"},
    {id = "wizard", name = "Zeno (Wizard)", icon = "rbxassetid://13353923546"},
    {id = "yeti", name = "Yeti", icon = "rbxassetid://9166205917"}
}

table.sort(allKits, function(a, b)
    return a.name < b.name
end)

local banKitRemote
task.spawn(function()
    pcall(function()
        local netManaged = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10)
            :WaitForChild("node_modules")
            :WaitForChild("@rbxts")
            :WaitForChild("net")
            :WaitForChild("out")
            :WaitForChild("_NetManaged")
        banKitRemote = netManaged:WaitForChild("BanKit")
    end)
end)

local function banKit(kitId)
    if not banKitRemote then return false end
    
    local success, err = pcall(function()
        banKitRemote:InvokeServer(kitId, 0)
        banKitRemote:InvokeServer(kitId, 1)
    end)
    return success
end

function Mega.Features.KitBan.ExecuteBan()
    if not States.Misc.KitBan.TargetKits then return end
    
    local count = 0
    local successCount = 0
    
    for kitId, isSelected in pairs(States.Misc.KitBan.TargetKits) do
        if isSelected then
            count = count + 1
            if banKit(kitId) then
                successCount = successCount + 1
            end
        end
    end
    
    if Mega.ShowNotification then
        if count > 0 then
            if successCount > 0 then
                Mega.ShowNotification(Mega.GetText("banned_kit_success") or ("ЗАБАНЕНЫ! Успешно: " .. successCount .. "/" .. count), 3)
            else
                Mega.ShowNotification(Mega.GetText("banned_kit_fail") or "ОШИБКА! Ни один кит не забанен.", 3)
            end
        else
            Mega.ShowNotification("Нет выбранных китов для бана!", 2)
        end
    end
end

local function InitializeKitBanUI()
    local container = Mega.Objects.KitBanContainer
    if not container then return end
    
    container:ClearAllChildren()

    local elemColor = Mega.Settings.Menu.ElementColor or Color3.fromRGB(40, 40, 45)
    local textColor = Mega.Settings.Menu.TextColor or Color3.fromRGB(255, 255, 255)
    local accentColor = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 150, 50)

    -- Remove target label completely
    -- Target Label code removed

    -- Search Box
    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(0.95, 0, 0, 30)
    SearchBox.Position = UDim2.new(0.025, 0, 0, 10)
    SearchBox.BackgroundColor3 = elemColor
    SearchBox.TextColor3 = textColor
    SearchBox.PlaceholderText = Mega.GetText("search_kit_ban") or "🔍 Поиск кита..."
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 13
    SearchBox.Text = ""
    Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
    SearchBox.Parent = container

    -- Scroll List
    local KitList = Instance.new("ScrollingFrame")
    KitList.Size = UDim2.new(1, 0, 1, -50)
    KitList.Position = UDim2.new(0, 0, 0, 50)
    KitList.BackgroundTransparency = 1
    KitList.BorderSizePixel = 0
    KitList.ScrollBarThickness = 4
    KitList.Parent = container
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = KitList
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5)

    local function RefreshKitList(filter)
        for _, v in pairs(KitList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        
        filter = string.lower(filter or "")
        
        for _, kitData in ipairs(allKits) do
            if filter ~= "" and not string.find(string.lower(kitData.name), filter) and not string.find(string.lower(kitData.id), filter) then
                continue
            end

            if type(States.Misc.KitBan.TargetKits) ~= "table" then States.Misc.KitBan.TargetKits = {} end
            local isSelected = States.Misc.KitBan.TargetKits[kitData.id] or false
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 200, 100) or elemColor
            
            btn.Text = kitData.name
            btn.TextColor3 = textColor
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.Parent = KitList
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            local Padding = Instance.new("UIPadding")
            Padding.Parent = btn
            Padding.PaddingLeft = UDim.new(0, 36)
            
            local KitIcon = Instance.new("ImageLabel")
            KitIcon.Parent = btn
            KitIcon.BackgroundTransparency = 1
            KitIcon.Position = UDim2.new(0, -30, 0.5, -12)
            KitIcon.Size = UDim2.new(0, 24, 0, 24)
            KitIcon.Image = kitData.icon or ""
            
            btn.MouseButton1Click:Connect(function()
                if States.Misc.KitBan.TargetKits[kitData.id] then
                    States.Misc.KitBan.TargetKits[kitData.id] = nil
                    btn.BackgroundColor3 = elemColor
                else
                    States.Misc.KitBan.TargetKits[kitData.id] = true
                    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                end
            end)
        end
        
        task.spawn(function()
            task.wait()
            if KitList and ListLayout then
                KitList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
            end
        end)
    end

    RefreshKitList("")

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RefreshKitList(SearchBox.Text)
    end)
end

task.spawn(function()
    while not Mega.Objects.KitBanContainer do task.wait(0.1) end
    InitializeKitBanUI()
end)
