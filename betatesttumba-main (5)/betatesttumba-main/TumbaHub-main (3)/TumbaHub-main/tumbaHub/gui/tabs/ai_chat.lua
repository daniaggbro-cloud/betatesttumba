-- gui/tabs/ai_chat.lua
-- Content for the "AI CHAT" tab
-- Stylized for TumbaHub Premium

local tabKey = "tab_ai_chat"
local UI = Mega.UI
local Settings = Mega.Settings
local GetText = Mega.GetText
local TweenService = Mega.Services.TweenService

-- Create the container frame for this tab (Non-scrolling, we want fixed input at bottom)
local TabFrame = Instance.new("Frame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

-- Logic and Knowledge Initialization
task.spawn(function()
    if not Mega.Features.AIChat then
        pcall(function() Mega.LoadModule("features/ai_chat.lua") end)
    end
end)

-- --- UI ELEMENTS ---

-- 1. Chat Area (Scrolling)
local ChatHistory = Instance.new("ScrollingFrame")
ChatHistory.Name = "ChatHistory"
ChatHistory.Size = UDim2.new(1, -20, 1, -110)
ChatHistory.Position = UDim2.new(0, 10, 0, 10)
ChatHistory.BackgroundTransparency = 0.5
ChatHistory.BackgroundColor3 = Settings.Menu.ElementColor
ChatHistory.BorderSizePixel = 0
ChatHistory.ScrollBarThickness = 2
ChatHistory.ScrollBarImageColor3 = Settings.Menu.AccentColor
ChatHistory.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatHistory.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChatHistory.Parent = TabFrame

local HistoryPadding = Instance.new("UIPadding", ChatHistory)
HistoryPadding.PaddingLeft = UDim.new(0, 10)
HistoryPadding.PaddingRight = UDim.new(0, 10)
HistoryPadding.PaddingTop = UDim.new(0, 10)
HistoryPadding.PaddingBottom = UDim.new(0, 10)

local HistoryLayout = Instance.new("UIListLayout", ChatHistory)
HistoryLayout.Padding = UDim.new(0, 8)
HistoryLayout.SortOrder = Enum.SortOrder.LayoutOrder

Instance.new("UICorner", ChatHistory).CornerRadius = UDim.new(0, 12)
local HistoryStroke = Instance.new("UIStroke", ChatHistory)
HistoryStroke.Color = Settings.Menu.AccentColor
HistoryStroke.Thickness = 1
HistoryStroke.Transparency = 0.7

-- 2. Input Bar
local InputFrame = Instance.new("Frame")
InputFrame.Name = "InputBar"
InputFrame.Size = UDim2.new(1, -20, 0, 80)
InputFrame.Position = UDim2.new(0, 10, 1, -90)
InputFrame.BackgroundColor3 = Settings.Menu.ElementColor
InputFrame.BackgroundTransparency = 0.3
InputFrame.Parent = TabFrame
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 12)

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -100, 1, -20)
TextBox.Position = UDim2.new(0, 15, 0, 10)
TextBox.BackgroundTransparency = 1
TextBox.Text = ""
TextBox.PlaceholderText = GetText("ai_chat_placeholder")
TextBox.PlaceholderColor3 = Settings.Menu.TextMutedColor
TextBox.TextColor3 = Settings.Menu.TextColor
TextBox.TextSize = 14
TextBox.Font = Enum.Font.GothamSemibold
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextWrapped = true
TextBox.ClearTextOnFocus = false
TextBox.Parent = InputFrame

local SendButton = Instance.new("TextButton")
SendButton.Name = "SendButton"
SendButton.Size = UDim2.new(0, 70, 0, 40)
SendButton.Position = UDim2.new(1, -85, 0.5, -20)
SendButton.BackgroundColor3 = Settings.Menu.AccentColor
SendButton.Text = GetText("ai_chat_send")
SendButton.TextColor3 = Color3.new(1, 1, 1)
SendButton.Font = Enum.Font.GothamBold
SendButton.TextSize = 12
SendButton.Parent = InputFrame
Instance.new("UICorner", SendButton).CornerRadius = UDim.new(0, 8)

-- --- FUNCTIONS ---

local function CreateMessageBubble(text, isAI)
    local Bubble = Instance.new("Frame")
    Bubble.Size = UDim2.new(0.9, 0, 0, 0)
    Bubble.AutomaticSize = Enum.AutomaticSize.Y
    Bubble.BackgroundTransparency = 0.4
    Bubble.BackgroundColor3 = isAI and Settings.Menu.AccentColor or Color3.fromRGB(40, 40, 55)
    
    local BubblePadding = Instance.new("UIPadding", Bubble)
    BubblePadding.PaddingLeft = UDim.new(0, 10)
    BubblePadding.PaddingRight = UDim.new(0, 10)
    BubblePadding.PaddingTop = UDim.new(0, 8)
    BubblePadding.PaddingBottom = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = isAI and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    Label.TextWrapped = true
    Label.RichText = true
    Label.Parent = Bubble
    
    Instance.new("UICorner", Bubble).CornerRadius = UDim.new(0, 10)
    
    -- Alignment
    local Alignment = Instance.new("UIListLayout", Bubble) -- Internal for padding
    Bubble.Parent = ChatHistory
    
    -- Scroll to bottom
    task.wait(0.05)
    ChatHistory.CanvasPosition = Vector2.new(0, ChatHistory.AbsoluteCanvasSize.Y)
    
    -- Fade in
    Bubble.BackgroundTransparency = 1
    TweenService:Create(Bubble, TweenInfo.new(0.3), { BackgroundTransparency = isAI and 0.4 or 0.6 }):Play()
end

local function OnSendMessage()
    local text = TextBox.Text
    if text == "" or (Mega.Features.AIChat and Mega.Features.AIChat.IsProcessing) then return end
    
    TextBox.Text = ""
    CreateMessageBubble(text, false)
    
    if Mega.Features.AIChat then
        SendButton.Text = "..."
        SendButton.AutoButtonColor = false
        
        Mega.Features.AIChat.SendMessage(text, function(response)
            SendButton.Text = GetText("ai_chat_send")
            SendButton.AutoButtonColor = true
            CreateMessageBubble(response, true)
        end, function(err)
            SendButton.Text = GetText("ai_chat_send")
            SendButton.AutoButtonColor = true
            CreateMessageBubble(err, true)
        end)
    else
        CreateMessageBubble("⚠️ ИИ еще загружается, подожди секунду...", true)
    end
end

SendButton.MouseButton1Click:Connect(OnSendMessage)
TextBox.FocusLost:Connect(function(enterPressed) if enterPressed then OnSendMessage() end end)

-- Initial Welcome
task.spawn(function()
    task.wait(1.5)
    CreateMessageBubble("Привет! Я твой ИИ-ассистент TumbaHub. Чем могу помочь?", true)
end)
