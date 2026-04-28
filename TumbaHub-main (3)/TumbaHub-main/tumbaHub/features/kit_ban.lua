-- features/kit_ban.lua
-- Encapsulated script from message.txt for Kit Ban functionality

Mega.Features = Mega.Features or {}
Mega.Features.KitBan = {}

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
    {id = "infected", name = "Infected", icon = "rbxassetid://11104063651"},
    {id = "infected_disruptor", name = "Infected Disruptor", icon = "rbxassetid://11104063651"},
    {id = "infected_prowler", name = "Infected Prowler", icon = "rbxassetid://11104063651"},
    {id = "infected_rush", name = "Infected Rush", icon = "rbxassetid://11104063651"},
    {id = "infected_tank", name = "Infected Tank", icon = "rbxassetid://11104063651"},
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
    {id = "super_infected", name = "Super Infected", icon = "rbxassetid://11527394782"},
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

local function getBanKitRemote()
    local success, netManaged = pcall(function()
        return ReplicatedStorage:WaitForChild("rbxts_include", 2)
            :WaitForChild("node_modules", 2)
            :WaitForChild("@rbxts", 2)
            :WaitForChild("net", 2)
            :WaitForChild("out", 2)
            :WaitForChild("_NetManaged", 2)
    end)
    
    if success and netManaged then
        return netManaged:WaitForChild("BanKit", 2)
    end
    return nil
end

local function banKit(kitName)
    local banKitRemote = getBanKitRemote()
    if not banKitRemote then return false end
    
    local success, err = pcall(function()
        banKitRemote:InvokeServer(kitName, 0)
        banKitRemote:InvokeServer(kitName, 1)
    end)
    return success
end

function Mega.Features.KitBan.OpenMenu()
    if CoreGui:FindFirstChild("TumbaKitBanMenu") then
        CoreGui.TumbaKitBanMenu:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TumbaKitBanMenu"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Получаем цвета из текущей темы Mega.Settings.Menu
    local bgColor = Mega.Settings.Menu.BackgroundColor or Color3.fromRGB(25, 25, 30)
    local elemColor = Mega.Settings.Menu.ElementColor or Color3.fromRGB(40, 40, 45)
    local accentColor = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 150, 50)
    local textColor = Mega.Settings.Menu.TextColor or Color3.fromRGB(255, 255, 255)
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = bgColor
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 250, 0, 350)
    MainFrame.Active = true
    MainFrame.Draggable = true

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Parent = MainFrame
    MainStroke.Color = accentColor
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.5

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Font = Enum.Font.GothamBold
    Title.Text = " " .. (Mega.GetText("title_kit_ban") or "ВЫБЕРИТЕ КИТ ДЛЯ БАНА")
    Title.TextColor3 = textColor
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = MainFrame
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -35, 0, 0)
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = textColor
    CloseBtn.TextSize = 14

    local SearchBox = Instance.new("TextBox")
    SearchBox.Parent = MainFrame
    SearchBox.BackgroundColor3 = elemColor
    SearchBox.Position = UDim2.new(0.05, 0, 0, 40)
    SearchBox.Size = UDim2.new(0.9, 0, 0, 30)
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = Mega.GetText("search_kit_ban") or "🔍 Поиск кита..."
    SearchBox.Text = ""
    SearchBox.TextColor3 = textColor
    SearchBox.TextSize = 13
    Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
    
    local SearchStroke = Instance.new("UIStroke")
    SearchStroke.Parent = SearchBox
    SearchStroke.Color = accentColor
    SearchStroke.Thickness = 1
    SearchStroke.Transparency = 0.7

    local ScrollList = Instance.new("ScrollingFrame")
    ScrollList.Parent = MainFrame
    ScrollList.BackgroundColor3 = bgColor
    ScrollList.BackgroundTransparency = 1
    ScrollList.Position = UDim2.new(0.05, 0, 0, 80)
    ScrollList.Size = UDim2.new(0.9, 0, 1, -90)
    ScrollList.ScrollBarThickness = 4
    ScrollList.ScrollBarImageColor3 = accentColor
    ScrollList.BorderSizePixel = 0

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = ScrollList
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    local buttonPool = {}

    local function loadKits(filter)
        for _, btn in pairs(buttonPool) do
            btn:Destroy()
        end
        table.clear(buttonPool)
        
        local ySize = 0
        filter = string.lower(filter or "")
        
        for _, kitData in ipairs(allKits) do
            local kitId = kitData.id
            local niceName = kitData.name
            local iconId = kitData.icon
            
            if filter ~= "" and not string.find(string.lower(niceName), filter) and not string.find(string.lower(kitId), filter) then
                continue
            end

            local KitBtn = Instance.new("TextButton")
            KitBtn.Parent = ScrollList
            KitBtn.BackgroundColor3 = elemColor
            KitBtn.Size = UDim2.new(1, -10, 0, 36)
            KitBtn.Font = Enum.Font.GothamSemibold
            KitBtn.Text = niceName
            KitBtn.TextColor3 = textColor
            KitBtn.TextSize = 13
            KitBtn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", KitBtn).CornerRadius = UDim.new(0, 6)
            
            local Padding = Instance.new("UIPadding")
            Padding.Parent = KitBtn
            Padding.PaddingLeft = UDim.new(0, 36)
            
            local KitIcon = Instance.new("ImageLabel")
            KitIcon.Parent = KitBtn
            KitIcon.BackgroundTransparency = 1
            KitIcon.Position = UDim2.new(0, -30, 0.5, -12)
            KitIcon.Size = UDim2.new(0, 24, 0, 24)
            KitIcon.Image = iconId or ""
            
            KitBtn.MouseButton1Click:Connect(function()
                local originalText = KitBtn.Text
                KitBtn.Text = (Mega.GetText("banning_kit") or "БАН: ") .. originalText .. "..."
                KitBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
                
                local isSuccess = banKit(kitId)
                
                if isSuccess then
                    KitBtn.Text = Mega.GetText("banned_kit_success") or "ЗАБАНЕН!"
                    KitBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                else
                    KitBtn.Text = Mega.GetText("banned_kit_fail") or "ОШИБКА!"
                    KitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                end
                
                task.spawn(function()
                    task.wait(1.5)
                    if KitBtn and KitBtn.Parent then
                        KitBtn.Text = originalText
                        KitBtn.BackgroundColor3 = elemColor
                    end
                end)
            end)
            
            table.insert(buttonPool, KitBtn)
            ySize = ySize + 41
        end
        
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, ySize)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        loadKits(SearchBox.Text)
    end)

    loadKits("")
end
