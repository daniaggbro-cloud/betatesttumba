-- library/ui_builder.lua
-- GUI element factory functions (CreateToggle, CreateSlider, etc.)

Mega.UI = {}

local GetText = Mega.GetText
local ShowNotification = Mega.ShowNotification
local TweenService = Mega.Services.TweenService
local UserInputService = Mega.Services.UserInputService

function Mega.UI.CreateSection(parent, titleKey)
    local Section = Instance.new("Frame")
    Section.Name = titleKey .. "Section"
    Section.Size = UDim2.new(0.95, 0, 0, 45)
    Section.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
    Section.BorderSizePixel = 1
    Section.BorderColor3 = Mega.Settings.Menu.SecondaryColor

    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 10)
    SectionCorner.Parent = Section
    
    local SectionGradient = Instance.new("UIGradient")
    SectionGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 30, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 35, 50))
    }
    SectionGradient.Rotation = 45
    SectionGradient.Parent = Section

    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "SectionTitle"
    SectionTitle.Size = UDim2.new(1, -20, 1, 0)
    SectionTitle.Position = UDim2.new(0, 15, 0, 0)
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Text = "💠 " .. GetText(titleKey)
    SectionTitle.TextColor3 = Mega.Settings.Menu.SecondaryColor
    SectionTitle.TextSize = 15
    SectionTitle.Font = Enum.Font.GothamBold
    SectionTitle.TextStrokeTransparency = 0.8
    SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SectionTitle.Parent = Section
    
    Section.Parent = parent
    return Section
end

function Mega.UI.CreateToggle(parent, textKey, statePath, callback)
    local translatedText = GetText(textKey)
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = textKey .. "Toggle"
    ToggleFrame.Size = UDim2.new(0.9, 0, 0, 35)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = parent

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "Label"
    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = " " .. translatedText
    ToggleLabel.TextColor3 = Mega.Settings.Menu.TextColor
    ToggleLabel.TextSize = 13
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame

    local function getState()
        local path = statePath
        local value = Mega.States
        for part in path:gmatch("[^%.]+") do
            value = value and value[part]
        end
        return value
    end

    local initialState = getState()

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0, 44, 0, 22)
    ToggleButton.Position = UDim2.new(1, -54, 0.5, -11)
    ToggleButton.BackgroundColor3 = initialState and Mega.Settings.Menu.AccentColor or Color3.fromRGB(60, 60, 80)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ToggleFrame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton

    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
    ToggleCircle.Position = initialState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.Parent = ToggleButton
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle

    local function SetState(newState)
        local path = statePath
        local tbl = Mega.States
        local key
        for part in path:gmatch("[^%.]+") do
            if tbl[part] == nil and part ~= path:match("([^%.]+)$") then
                tbl[part] = {}
            end
            key = part
            if part ~= path:match("([^%.]+)$") then
                tbl = tbl[part]
            end
        end
        tbl[key] = newState

        TweenService:Create(ToggleButton, TweenInfo.new(0.2), { BackgroundColor3 = newState and Mega.Settings.Menu.AccentColor or Color3.fromRGB(60, 60, 80) }):Play()
        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), { Position = newState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }):Play()
        
        if callback then pcall(callback, newState) end
        
        local statusText = newState and GetText("notify_enabled") or GetText("notify_disabled")
        ShowNotification(translatedText .. ": " .. statusText, 2)
    end
    
    Mega.Objects.Toggles[textKey] = SetState
    ToggleButton.MouseButton1Click:Connect(function() SetState(not getState()) end)

    if initialState and callback then
        task.spawn(callback, true)
    end

    return ToggleFrame
end

function Mega.UI.CreateButton(parent, textKey, callback)
    local Button = Instance.new("TextButton")
    Button.Name = textKey .. "Button"
    Button.Size = UDim2.new(0.9, 0, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Button.BorderSizePixel = 0
    Button.Text = GetText(textKey)
    Button.TextColor3 = Mega.Settings.Menu.TextColor
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamSemibold
    Button.AutoButtonColor = false
    Button.Parent = parent

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button

    Button.MouseEnter:Connect(function() TweenService:Create(Button, TweenInfo.new(0.2), { BackgroundColor3 = Mega.Settings.Menu.AccentColor }):Play() end)
    Button.MouseLeave:Connect(function() TweenService:Create(Button, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(40, 40, 55) }):Play() end)
    Button.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)

    return Button
end

function Mega.UI.CreateSlider(parent, textKey, statePath, min, max, callback)
    local translatedText = GetText(textKey)
    
    local function getState()
        local path = statePath
        local value = Mega.States
        for part in path:gmatch("[^%.]+") do
            value = value and value[part]
        end
        return value or min
    end

    local currentValue = getState()

    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = textKey .. "Slider"
    SliderFrame.Size = UDim2.new(0.9, 0, 0, 60)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Parent = parent

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Name = "Label"
    SliderLabel.Size = UDim2.new(1, 0, 0, 20)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = GetText("slider_label", translatedText, currentValue)
    SliderLabel.TextColor3 = Mega.Settings.Menu.TextColor
    SliderLabel.TextSize = 12
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame

    local SliderTrack = Instance.new("Frame")
    SliderTrack.Name = "Track"
    SliderTrack.Size = UDim2.new(1, 0, 0, 6)
    SliderTrack.Position = UDim2.new(0, 0, 0, 35)
    SliderTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = SliderFrame

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, 3)
    TrackCorner.Parent = SliderTrack

    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "Fill"
    SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Mega.Settings.Menu.AccentColor
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = SliderFill

    local SliderButton = Instance.new("TextButton")
    SliderButton.Name = "Button"
    SliderButton.Size = UDim2.new(0, 16, 0, 16)
    SliderButton.Position = UDim2.new(SliderFill.Size.X.Scale, -8, 0.5, -8)
    SliderButton.BackgroundColor3 = Mega.Settings.Menu.AccentColor
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""
    SliderButton.AutoButtonColor = false
    SliderButton.Parent = SliderTrack

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(1, 0)
    ButtonCorner.Parent = SliderButton

    local dragging = false
    SliderButton.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    Mega.Services.RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = SliderTrack.AbsolutePosition
            local frameSize = SliderTrack.AbsoluteSize
            local relativeX = math.clamp((mousePos.X - framePos.X) / frameSize.X, 0, 1)
            local newValue = math.floor(min + relativeX * (max - min) + 0.5)

            local path = statePath
            local tbl = Mega.States
            local key
            for part in path:gmatch("[^%.]+") do
                key = part
                if part ~= path:match("([^%.]+)$") then tbl = tbl[part] end
            end
            tbl[key] = newValue

            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            SliderButton.Position = UDim2.new(relativeX, -8, 0.5, -8)
            SliderLabel.Text = GetText("slider_label", translatedText, newValue)
            if callback then pcall(callback, newValue) end
        end
    end)

    return SliderFrame
end

function Mega.UI.CreateDropdown(parent, textKey, statePath, options, callback, optionsAreKeys)
    local function getState()
        local path = statePath
        local value = Mega.States
        for part in path:gmatch("[^%.]+") do
            value = value and value[part]
        end
        return value
    end
    
    local initialValue = getState()

    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = textKey .. "Dropdown"
    DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35)
    DropdownFrame.BackgroundTransparency = 1
    DropdownFrame.Parent = parent
    DropdownFrame.ZIndex = 2

    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = GetText("dropdown_label", GetText(textKey))
    DropdownLabel.TextColor3 = Mega.Settings.Menu.TextColor
    DropdownLabel.TextSize = 13
    DropdownLabel.Font = Enum.Font.Gotham
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = DropdownFrame

    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Size = UDim2.new(0.4, 0, 1, 0)
    DropdownButton.Position = UDim2.new(0.6, 0, 0, 0)
    DropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    DropdownButton.BorderSizePixel = 0
    DropdownButton.Text = optionsAreKeys and GetText(initialValue) or initialValue
    DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropdownButton.TextSize = 11
    DropdownButton.Font = Enum.Font.GothamBold
    DropdownButton.AutoButtonColor = false
    DropdownButton.Parent = DropdownFrame
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = DropdownButton

    local DropdownList = Instance.new("ScrollingFrame")
    DropdownList.Size = UDim2.new(0.4, 0, 0, 1)
    DropdownList.Position = UDim2.new(0.6, 0, 1, 5)
    DropdownList.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    DropdownList.BorderSizePixel = 0
    DropdownList.ScrollBarThickness = 4
    DropdownList.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
    DropdownList.Visible = false
    DropdownList.ZIndex = 3
    DropdownList.Parent = DropdownFrame

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = DropdownList
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.Padding = UDim.new(0, 1)

    local listHeight = 0
    for i, optionKey in ipairs(options) do
        local translatedOption = optionsAreKeys and GetText(optionKey) or optionKey
        local ListItem = Instance.new("TextButton")
        ListItem.Size = UDim2.new(1, -8, 0, 32)
        ListItem.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ListItem.Text = translatedOption or "???"
        ListItem.TextColor3 = Color3.fromRGB(255, 255, 255)
        ListItem.TextSize = 14
        ListItem.Font = Enum.Font.GothamBold
        ListItem.Parent = DropdownList
        listHeight = listHeight + 33

        ListItem.MouseButton1Click:Connect(function()
            DropdownButton.Text = translatedOption
            DropdownList.Visible = false
            
            local path = statePath
            local tbl = Mega.States
            local key
            for part in path:gmatch("[^%.]+") do
                key = part
                if part ~= path:match("([^%.]+)$") then tbl = tbl[part] end
            end
            tbl[key] = optionKey
            
            if callback then pcall(callback, optionKey) end
        end)
    end
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, listHeight)

    DropdownButton.MouseButton1Click:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
        if DropdownList.Visible then
            local height = math.min(listHeight, 132)
            TweenService:Create(DropdownList, TweenInfo.new(0.2), { Size = UDim2.new(0.4, 0, 0, height) }):Play()
        else
            TweenService:Create(DropdownList, TweenInfo.new(0.2), { Size = UDim2.new(0.4, 0, 0, 1) }):Play()
        end
    end)
    return DropdownFrame
end

function Mega.UI.CreateKeybindButton(parent, textKey, statePath, callback)
    local function getState()
        local path = statePath
        local value = Mega.States
        for part in path:gmatch("[^%.]+") do value = value and value[part] end
        return value
    end

    local currentKey = getState()

    local KeybindFrame = Instance.new("Frame")
    KeybindFrame.Size = UDim2.new(0.9, 0, 0, 35)
    KeybindFrame.BackgroundTransparency = 1
    KeybindFrame.Parent = parent

    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Text = " " .. GetText(textKey)
    KeybindLabel.TextColor3 = Mega.Settings.Menu.TextColor
    KeybindLabel.TextSize = 13
    KeybindLabel.Font = Enum.Font.Gotham
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeybindLabel.Parent = KeybindFrame

    local KeybindButton = Instance.new("TextButton")
    KeybindButton.Size = UDim2.new(0.3, 0, 0, 25)
    KeybindButton.Position = UDim2.new(0.65, 0, 0.5, -12.5)
    KeybindButton.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    KeybindButton.Text = currentKey or GetText("keybind_none")
    KeybindButton.TextColor3 = Mega.Settings.Menu.TextColor
    KeybindButton.TextSize = 11
    KeybindButton.Font = Enum.Font.GothamBold
    KeybindButton.Parent = KeybindFrame
    local KeybindCorner = Instance.new("UICorner")
    KeybindCorner.CornerRadius = UDim.new(0, 6)
    KeybindCorner.Parent = KeybindButton

    local listening = false
    KeybindButton.MouseButton1Click:Connect(function()
        if UserInputService.TouchEnabled then
            ShowNotification("📱 На телефоне лучше включи галочку 'Показывать на экране' в самом низу!", 5)
        end
        listening = true
        KeybindButton.Text = GetText("keybind_listening")
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not listening then return end
        local key = input.KeyCode.Name
        if key == "Unknown" then return end
        listening = false
        KeybindButton.Text = key
        
        local path = statePath
        local tbl = Mega.States
        for part in path:gmatch("[^%.]+") do
            if tbl[part] == nil and part ~= path:match("([^%.]+)$") then tbl[part] = {} end
            if part ~= path:match("([^%.]+)$") then tbl = tbl[part] else tbl[part] = key end
        end

        if callback then pcall(callback, key) end
        ShowNotification(GetText("notify_keybind_set", GetText(textKey), key), 3)
    end)
    return KeybindFrame
end

function Mega.UI.CreateToggleWithSettings(parent, textKey, statePath, callback, settingsElements)
    -- This is the main container for the whole component, its height will be animated
    local ComponentFrame = Instance.new("Frame")
    ComponentFrame.Name = textKey .. "Component"
    ComponentFrame.Size = UDim2.new(0.95, 0, 0, 40) -- Initial height
    ComponentFrame.BackgroundTransparency = 1
    ComponentFrame.ClipsDescendants = true
    ComponentFrame.Parent = parent
    
    local ComponentLayout = Instance.new("UIListLayout", ComponentFrame)
    ComponentLayout.Padding = UDim.new(0, 5)

    -- Frame for the main toggle bar
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Name = "ControlFrame"
    ControlFrame.Size = UDim2.new(1, 0, 0, 35)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = ComponentFrame

    -- The actual toggle from CreateToggle, but adapted
    local ToggleFrame = Mega.UI.CreateToggle(ControlFrame, textKey, statePath, callback)
    ToggleFrame.Size = UDim2.new(1, -50, 1, 0) -- Make space for settings button

    -- Settings Button (Gear Icon)
    local SettingsButton = Instance.new("TextButton")
    SettingsButton.Name = "SettingsButton"
    SettingsButton.Size = UDim2.new(0, 35, 0, 25)
    SettingsButton.Position = UDim2.new(1, -45, 0.5, -12.5)
    SettingsButton.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    SettingsButton.Text = "⚙️"
    SettingsButton.TextColor3 = Mega.Settings.Menu.TextColor
    SettingsButton.TextSize = 18
    SettingsButton.Font = Enum.Font.Gotham
    SettingsButton.Parent = ControlFrame
    Instance.new("UICorner", SettingsButton).CornerRadius = UDim.new(0, 6)
    
    -- Container for the collapsible settings
    local SettingsContainer = Instance.new("Frame")
    SettingsContainer.Name = "SettingsContainer"
    SettingsContainer.Size = UDim2.new(0.9, 0, 0, 0) -- Will be auto-sized
    SettingsContainer.Position = UDim2.new(0.5, 0, 0, 0)
    SettingsContainer.AnchorPoint = Vector2.new(0.5, 0)
    SettingsContainer.BackgroundTransparency = 1
    SettingsContainer.Parent = ComponentFrame
    
    local SettingsLayout = Instance.new("UIListLayout", SettingsContainer)
    SettingsLayout.Padding = UDim.new(0, 8)
    SettingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- This will make the container resize automatically based on its children
    SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Parent all the setting elements to the container
    for i, element in ipairs(settingsElements or {}) do
        element.LayoutOrder = i
        element.Parent = SettingsContainer
    end

    local isExpanded = false
    local initialHeight = ComponentFrame.AbsoluteSize.Y
    
    SettingsButton.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        
        -- Safe height calculation (UIListLayout AbsoluteContentSize handles AutomaticSize timing issues)
        local settingsHeight = SettingsLayout.AbsoluteContentSize.Y
        local targetHeight = isExpanded and (initialHeight + settingsHeight + ComponentLayout.Padding.Offset) or initialHeight
        
        local tween = TweenService:Create(ComponentFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(0.95, 0, 0, targetHeight) })
        tween:Play()
    end)
    return ComponentFrame
end

