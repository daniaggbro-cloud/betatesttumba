-- gui/tabs/updates.lua
-- Content for the "UPDATES" tab

local tabKey = "tab_updates"
local UI = Mega.UI
local GetText = Mega.GetText

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

local loc = Mega.Localization.Strings
if not loc["section_latest_updates"] then
    loc["section_latest_updates"] = { ru = "Последние обновления", en = "Latest Updates" }
end

UI.CreateSection(TabFrame, "section_latest_updates")

local UpdateContainer = Instance.new("Frame")
UpdateContainer.Size = UDim2.new(0.95, 0, 0, 400) -- Will adjust based on content
UpdateContainer.BackgroundTransparency = 1
UpdateContainer.Parent = TabFrame

local UpdateLayout = Instance.new("UIListLayout", UpdateContainer)
UpdateLayout.SortOrder = Enum.SortOrder.LayoutOrder
UpdateLayout.Padding = UDim.new(0, 12)

local function CreateUpdateItem(title, description, color)
    local ItemFrame = Instance.new("Frame")
    ItemFrame.Size = UDim2.new(1, 0, 0, 0)
    ItemFrame.AutomaticSize = Enum.AutomaticSize.Y
    ItemFrame.BackgroundColor3 = Mega.Settings.Menu.ElementColor
    ItemFrame.BackgroundTransparency = 0.5
    ItemFrame.BorderSizePixel = 0
    Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 8)
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 4, 1, -16)
    Indicator.Position = UDim2.new(0, 8, 0, 8)
    Indicator.BackgroundColor3 = color or Mega.Settings.Menu.AccentColor
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 4)
    Indicator.Parent = ItemFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -24, 0, 20)
    TitleLabel.Position = UDim2.new(0, 20, 0, 8)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = color or Mega.Settings.Menu.AccentColor
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = ItemFrame
    
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -24, 0, 0)
    DescLabel.Position = UDim2.new(0, 20, 0, 30)
    DescLabel.AutomaticSize = Enum.AutomaticSize.Y
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = description
    DescLabel.TextColor3 = Mega.Settings.Menu.TextColor
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 13
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextWrapped = true
    DescLabel.Parent = ItemFrame
    
    -- Add some bottom padding for the desc
    local Padding = Instance.new("UIPadding")
    Padding.PaddingBottom = UDim.new(0, 12)
    Padding.Parent = ItemFrame
    
    ItemFrame.Parent = UpdateContainer
    return ItemFrame
end

local language = Mega.Settings.Menu.Language or "ru"
local isRu = (language == "ru")

-- Update Items
CreateUpdateItem(
    isRu and "✨ Умный Status Indicator" or "✨ Smart Status Indicator",
    isRu and "Индикатор статуса был полностью переписан! Теперь он динамически подхватывает все активированные функции, автоматически переводит их названия и выдает каждой уникальный цвет."
       or "The Status Indicator has been completely rewritten! It now dynamically tracks active features, automatically translates them, and assigns each a unique color.",
    Color3.fromRGB(150, 50, 255)
)

CreateUpdateItem(
    isRu and "⚔️ Фикс Killaura" or "⚔️ Killaura Fix",
    isRu and "Мы восстановили оригинальную, стабильную логику таргетинга. Теперь Киллаура снова работает безупречно и атакует без сбоев."
       or "Restored the original, stable targeting logic. Killaura now works flawlessly and attacks without breaking.",
    Color3.fromRGB(255, 50, 50)
)

CreateUpdateItem(
    isRu and "🎨 Улучшение интерфейса (UI Scaling)" or "🎨 UI Scaling & Polish",
    isRu and "Иконки китов и классов стали в 2 раза больше! Меню теперь выглядит намного чище, приятнее и премиальнее."
       or "Kit and Class icons are now 2x larger! The menu looks much cleaner, more pleasant, and premium.",
    Color3.fromRGB(50, 200, 255)
)

CreateUpdateItem(
    isRu and "🧪 Новые Киты" or "🧪 New Kits",
    isRu and "Добавлена поддержка, иконки и автоматизация для китов Алхимик (Alchemist) и Рыбак (Fisherman)!"
       or "Added support, icons, and automation for Alchemist and Fisherman kits!",
    Color3.fromRGB(50, 255, 100)
)

CreateUpdateItem(
    isRu and "💬 Интеграция Discord" or "💬 Discord Integration",
    isRu and "Добавлена новая удобная панель Discord на главной вкладке с кнопками быстрого копирования и входа на сервер."
       or "Added a convenient new Discord panel on the Home tab with quick copy and join buttons.",
    Color3.fromRGB(88, 101, 242)
)

CreateUpdateItem(
    isRu and "🧹 Чистка локализации" or "🧹 Localization Cleanup",
    isRu and "Убран лишний текст (например, слово 'Включить') из переключателей ESP для более минималистичного вида."
       or "Removed redundant text (like 'Enable') from ESP toggles for a more minimalist look.",
    Color3.fromRGB(255, 170, 0)
)

-- Adjust container height automatically when layout changes
UpdateLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    UpdateContainer.Size = UDim2.new(0.95, 0, 0, UpdateLayout.AbsoluteContentSize.Y)
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, UpdateLayout.AbsoluteContentSize.Y + 100)
end)
