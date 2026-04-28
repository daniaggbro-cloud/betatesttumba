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
    Section.BackgroundColor3 = Mega.Settings.Menu.ElementColor
    Section.BackgroundTransparency = 0.45
    Section.BorderSizePixel = 0

    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 10)
    SectionCorner.Parent = Section
    
    local SectionStroke = Instance.new("UIStroke", Section)
    SectionStroke.Color = Mega.Settings.Menu.AccentColor
    SectionStroke.Thickness = 1
    SectionStroke.Transparency = 0.75
    
    local SectionGradient = Instance.new("UIGradient")
    local success = pcall(function()
        local grad1 = typeof(Mega.Settings.Menu.SectionGradient1) == "Color3" and Mega.Settings.Menu.SectionGradient1 or Color3.fromRGB(15, 15, 25)
        local grad2 = typeof(Mega.Settings.Menu.SectionGradient2) == "Color3" and Mega.Settings.Menu.SectionGradient2 or Color3.fromRGB(10, 10, 20)
        SectionGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, grad1),
            ColorSequenceKeypoint.new(1, grad2)
        }
    end)
    if not success then
        SectionGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
        }
    end
    SectionGradient.Rotation = 45
    SectionGradient.Parent = Section

    -- ✨ НОВОЕ: Левая вертикальная декоративная линия (accent color)
    local AccentLine = Instance.new("Frame", Section)
    AccentLine.Name = "AccentLine"
    AccentLine.Size = UDim2.new(0, 3, 0.6, 0)
    AccentLine.Position = UDim2.new(0, 0, 0.2, 0)
    AccentLine.BackgroundColor3 = Mega.Settings.Menu.AccentColor
    AccentLine.BorderSizePixel = 0
    AccentLine.ZIndex = 2
    Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1, 0)
    
    -- Pulse glow анимация на линии
    local LineGlow = Instance.new("UIStroke", AccentLine)
    LineGlow.Color = Mega.Settings.Menu.AccentColor
    LineGlow.Thickness = 2
    LineGlow.Transparency = 0.4
    task.spawn(function()
        while AccentLine.Parent do
            TweenService:Create(LineGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.0 }):Play()
            task.wait(1.2)
            TweenService:Create(LineGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.6 }):Play()
            task.wait(1.2)
        end
    end)

    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "SectionTitle"
    SectionTitle.Size = UDim2.new(1, -35, 1, 0)
    SectionTitle.Position = UDim2.new(0, 18, 0, 0) -- Сдвинуто правее для линии
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Text = GetText(titleKey)
    SectionTitle.TextColor3 = Mega.Settings.Menu.TextColor
    SectionTitle.TextSize = 13
    SectionTitle.Font = Enum.Font.GothamBold
    SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SectionTitle.Parent = Section
    
    Section.Parent = parent
    return Section
end

function Mega.UI.CreateToggle(parent, textKey, statePath, callback)
    local translatedText = GetText(textKey)
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = textKey .. "Toggle"
    ToggleFrame.Size = UDim2.new(0.9, 0, 0, 38)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = parent

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "Label"
    ToggleLabel.Size = UDim2.new(0.65, 0, 1, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = " " .. translatedText
    ToggleLabel.TextColor3 = Mega.Settings.Menu.TextColor
    ToggleLabel.TextSize = 13
    ToggleLabel.Font = Enum.Font.GothamSemibold
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

    -- ✨ НОВОЕ: Увеличенный toggle (50x26) с glow-эффектом
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0, 50, 0, 26)
    ToggleButton.Position = UDim2.new(1, -58, 0.5, -13)
    ToggleButton.BackgroundColor3 = initialState and Mega.Settings.Menu.AccentColor or Mega.Settings.Menu.ToggleOffColor
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ToggleFrame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton
    
    -- Glow stroke — виден только когда ON
    local ToggleGlow = Instance.new("UIStroke", ToggleButton)
    ToggleGlow.Color = Mega.Settings.Menu.AccentColor
    ToggleGlow.Thickness = 2.5
    ToggleGlow.Transparency = initialState and 0.3 or 1
    ToggleGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 20, 0, 20)
    ToggleCircle.Position = initialState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    ToggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    ToggleCircle.Parent = ToggleButton
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle
    
    -- Subtle circle shadow
    local CircleStroke = Instance.new("UIStroke", ToggleCircle)
    CircleStroke.Color = Color3.fromRGB(0, 0, 0)
    CircleStroke.Thickness = 1
    CircleStroke.Transparency = 0.6

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

        local accentCol = Mega.Settings.Menu.AccentColor
        TweenService:Create(ToggleButton, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { BackgroundColor3 = newState and accentCol or Color3.fromRGB(55, 55, 75) }):Play()
        TweenService:Create(ToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { Position = newState and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10) }):Play()
        -- Glow появляется при ON
        TweenService:Create(ToggleGlow, TweenInfo.new(0.25), { Transparency = newState and 0.3 or 1 }):Play()
        -- Метка слегка ярче когда ON
        TweenService:Create(ToggleLabel, TweenInfo.new(0.25), { TextColor3 = newState and Color3.new(1,1,1) or Mega.Settings.Menu.TextMutedColor }):Play()
        
        if callback then pcall(callback, newState) end
        
        local statusText = newState and GetText("notify_enabled") or GetText("notify_disabled")
        ShowNotification(translatedText .. ": " .. statusText, 2)
    end
    
    -- Hover эффект
    ToggleButton.MouseEnter:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.15), { Size = UDim2.new(0, 53, 0, 26) }):Play()
    end)
    ToggleButton.MouseLeave:Connect(function()
        TweenService:Create(ToggleButton, TweenInfo.new(0.15), { Size = UDim2.new(0, 50, 0, 26) }):Play()
    end)
    
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
    Button.BackgroundColor3 = Mega.Settings.Menu.ElementColor
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

    local ButtonStroke = Instance.new("UIStroke", Button)
    ButtonStroke.Color = Mega.Settings.Menu.AccentColor
    ButtonStroke.Thickness = 1
    ButtonStroke.Transparency = 0.8

    Button.MouseEnter:Connect(function() 
        TweenService:Create(Button, TweenInfo.new(0.3), { 
            BackgroundColor3 = Mega.Settings.Menu.AccentColor,
            BackgroundTransparency = 0.2
        }):Play() 
        TweenService:Create(ButtonStroke, TweenInfo.new(0.3), { Transparency = 0.4 }):Play()
    end)
    Button.MouseLeave:Connect(function() 
        TweenService:Create(Button, TweenInfo.new(0.3), { 
            BackgroundColor3 = Mega.Settings.Menu.ElementColor,
            BackgroundTransparency = 0
        }):Play() 
        TweenService:Create(ButtonStroke, TweenInfo.new(0.3), { Transparency = 0.8 }):Play()
    end)
    Button.MouseButton1Click:Connect(function() 
        pcall(function()
            local originalSize = Button.Size
            Button:TweenSize(UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset, originalSize.Y.Scale * 0.95, originalSize.Y.Offset), "Out", "Quad", 0.05, true)
            task.wait(0.05)
            Button:TweenSize(originalSize, "Out", "Quad", 0.05, true)
        end)
        if callback then pcall(callback) end 
    end)

    return Button
end

function Mega.UI.CreateSlider(parent, textKey, statePath, min, max, callback, decimals)
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

    -- Заголовок: название слева, значение справа (в цвете акцента)
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Name = "Label"
    SliderLabel.Size = UDim2.new(0.65, 0, 0, 20)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = translatedText
    SliderLabel.TextColor3 = Mega.Settings.Menu.TextColor
    SliderLabel.TextSize = 12
    SliderLabel.Font = Enum.Font.GothamSemibold
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "ValueLabel"
    ValueLabel.Size = UDim2.new(0.35, 0, 0, 20)
    ValueLabel.Position = UDim2.new(0.65, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(currentValue)
    ValueLabel.TextColor3 = Mega.Settings.Menu.AccentColor
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame

    -- Трек слайдера
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Name = "Track"
    SliderTrack.Size = UDim2.new(1, 0, 0, 8)
    SliderTrack.Position = UDim2.new(0, 0, 0, 33)
    SliderTrack.BackgroundColor3 = Mega.Settings.Menu.ToggleOffColor
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = SliderFrame
    Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

    -- ✨ Заполнение с gradient (AccentColor → светлее)
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "Fill"
    SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Mega.Settings.Menu.AccentColor
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    
    local FillGrad = Instance.new("UIGradient", SliderFill)
    FillGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Mega.Settings.Menu.AccentColor),
        ColorSequenceKeypoint.new(1, Mega.Settings.Menu.AccentColor:Lerp(Color3.new(1,1,1), 0.35))
    }

    -- ✨ Thumb (18px) с hover и drag glow
    local SliderButton = Instance.new("TextButton")
    SliderButton.Name = "Button"
    SliderButton.Size = UDim2.new(0, 18, 0, 18)
    SliderButton.Position = UDim2.new(SliderFill.Size.X.Scale, -9, 0.5, -9)
    SliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""
    SliderButton.AutoButtonColor = false
    SliderButton.ZIndex = 3
    SliderButton.Parent = SliderTrack
    Instance.new("UICorner", SliderButton).CornerRadius = UDim.new(1, 0)
    
    -- Glow stroke на thumb
    local ThumbGlow = Instance.new("UIStroke", SliderButton)
    ThumbGlow.Color = Mega.Settings.Menu.AccentColor
    ThumbGlow.Thickness = 2
    ThumbGlow.Transparency = 1
    ThumbGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    -- ✨ Laser на конце fill
    local FillLaser = Instance.new("Frame", SliderFill)
    FillLaser.Size = UDim2.new(0, 30, 3, 0)
    FillLaser.Position = UDim2.new(1, -10, 0.5, 0)
    FillLaser.AnchorPoint = Vector2.new(0.5, 0.5)
    FillLaser.BackgroundColor3 = Color3.new(1, 1, 1)
    FillLaser.BorderSizePixel = 0
    FillLaser.ZIndex = 2
    local LaserGrad = Instance.new("UIGradient", FillLaser)
    LaserGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 1)
    }

    -- Hover эффекты
    SliderButton.MouseEnter:Connect(function()
        TweenService:Create(SliderButton, TweenInfo.new(0.2), { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(SliderFill.Size.X.Scale, -11, 0.5, -11) }):Play()
        TweenService:Create(ThumbGlow, TweenInfo.new(0.2), { Transparency = 0.2 }):Play()
    end)
    SliderButton.MouseLeave:Connect(function()
        if not SliderButton:IsA("TextButton") then return end
        TweenService:Create(SliderButton, TweenInfo.new(0.2), { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(SliderFill.Size.X.Scale, -9, 0.5, -9) }):Play()
        TweenService:Create(ThumbGlow, TweenInfo.new(0.2), { Transparency = 1 }):Play()
    end)

    local dragging = false
    
    SliderButton.MouseButton1Down:Connect(function()
        dragging = true
        TweenService:Create(SliderButton, TweenInfo.new(0.15), { Size = UDim2.new(0, 20, 0, 20) }):Play()
        TweenService:Create(ThumbGlow, TweenInfo.new(0.15), { Transparency = 0.0, Thickness = 3 }):Play()
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            TweenService:Create(SliderButton, TweenInfo.new(0.15), { Size = UDim2.new(0, 18, 0, 18) }):Play()
            TweenService:Create(ThumbGlow, TweenInfo.new(0.2), { Transparency = 0.2, Thickness = 2 }):Play()
        end
    end)

    -- ✨ Клик по треку = прыжок к позиции
    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = SliderTrack.AbsolutePosition
            local frameSize = SliderTrack.AbsoluteSize
            local relativeX = math.clamp((mousePos.X - framePos.X) / frameSize.X, 0, 1)
            local newValue = min + relativeX * (max - min)
            if decimals and type(decimals) == "number" then
                local mult = 10 ^ decimals
                newValue = math.floor(newValue * mult + 0.5) / mult
            else
                newValue = math.floor(newValue + 0.5)
            end
            local path = statePath
            local tbl = Mega.States
            local key
            for part in path:gmatch("[^%.]+") do
                key = part
                if part ~= path:match("([^%.]+)$") then tbl = tbl[part] end
            end
            tbl[key] = newValue
            TweenService:Create(SliderFill, TweenInfo.new(0.15, Enum.EasingStyle.Quart), { Size = UDim2.new(relativeX, 0, 1, 0) }):Play()
            TweenService:Create(SliderButton, TweenInfo.new(0.15, Enum.EasingStyle.Quart), { Position = UDim2.new(relativeX, -9, 0.5, -9) }):Play()
            ValueLabel.Text = tostring(newValue)
            if callback then pcall(callback, newValue) end
            dragging = true
        end
    end)

    Mega.Services.RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = SliderTrack.AbsolutePosition
            local frameSize = SliderTrack.AbsoluteSize
            local relativeX = math.clamp((mousePos.X - framePos.X) / frameSize.X, 0, 1)
            local newValue = min + relativeX * (max - min)
            if decimals and type(decimals) == "number" then
                local mult = 10 ^ decimals
                newValue = math.floor(newValue * mult + 0.5) / mult
            else
                newValue = math.floor(newValue + 0.5)
            end

            local path = statePath
            local tbl = Mega.States
            local key
            for part in path:gmatch("[^%.]+") do
                key = part
                if part ~= path:match("([^%.]+)$") then tbl = tbl[part] end
            end
            tbl[key] = newValue

            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            SliderButton.Position = UDim2.new(relativeX, -9, 0.5, -9)
            ValueLabel.Text = tostring(newValue)
            if callback then pcall(callback, newValue) end
        end
    end)

    return SliderFrame
end

function Mega.UI.CreateDropdown(parent, textKey, statePath, options, callback, optionsAreKeys)
    local function getState()
        local path = statePath
        local value = Mega.States
        for part in path:gmatch("[^%.]+") do value = value and value[part] end
        return value
    end
    
    local initialValue = getState()

    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = textKey .. "Dropdown"
    DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35)
    DropdownFrame.BackgroundTransparency = 1
    DropdownFrame.ZIndex = 5
    DropdownFrame.Parent = parent

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
    DropdownButton.Size = UDim2.new(0, 200, 0, 30)
    DropdownButton.Position = UDim2.new(1, -200, 0.5, -15)
    DropdownButton.BackgroundColor3 = Mega.Settings.Menu.ElementColor:Lerp(Color3.new(1, 1, 1), 0.05)
    DropdownButton.BorderSizePixel = 0
    local displayText = (optionsAreKeys and GetText(initialValue)) or initialValue
    DropdownButton.Text = tostring(displayText or "")
    DropdownButton.TextColor3 = Mega.Settings.Menu.TextColor
    DropdownButton.TextSize = 11
    DropdownButton.Font = Enum.Font.GothamBold
    DropdownButton.AutoButtonColor = false
    DropdownButton.Parent = DropdownFrame
    
    Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 8)
    local ButtonStroke = Instance.new("UIStroke", DropdownButton)
    ButtonStroke.Color = Mega.Settings.Menu.AccentColor
    ButtonStroke.Transparency = 0.8

    local DropdownList = Instance.new("ScrollingFrame")
    DropdownList.Size = UDim2.new(0, 200, 0, 0)
    DropdownList.Position = UDim2.new(1, -200, 1, 5)
    DropdownList.BackgroundColor3 = Mega.Settings.Menu.SidebarColor
    DropdownList.BorderSizePixel = 0
    DropdownList.ScrollBarThickness = 2
    DropdownList.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
    DropdownList.Visible = false
    DropdownList.ClipsDescendants = true
    DropdownList.ZIndex = 500 -- Ensure it's on top
    DropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    DropdownList.Parent = DropdownFrame
    
    Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 8)
    local ListStroke = Instance.new("UIStroke", DropdownList)
    ListStroke.Color = Mega.Settings.Menu.AccentColor
    ListStroke.Transparency = 0.6

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.Parent = DropdownList

    for i, optionKey in ipairs(options) do
        local translatedOption = (optionsAreKeys and GetText(optionKey)) or optionKey
        local ListItem = Instance.new("TextButton")
        ListItem.Size = UDim2.new(1, -10, 0, 30)
        ListItem.BackgroundColor3 = Mega.Settings.Menu.ElementColor
        ListItem.BackgroundTransparency = 0.2
        ListItem.BorderSizePixel = 0
        ListItem.Text = tostring(translatedOption)
        ListItem.TextColor3 = Color3.new(1, 1, 1)
        ListItem.TextSize = 12
        ListItem.Font = Enum.Font.GothamSemibold
        ListItem.AutoButtonColor = false
        ListItem.LayoutOrder = i
        ListItem.ZIndex = 510
        ListItem.Parent = DropdownList
        
        Instance.new("UICorner", ListItem).CornerRadius = UDim.new(0, 6)

        ListItem.MouseEnter:Connect(function()
            TweenService:Create(ListItem, TweenInfo.new(0.2), {BackgroundColor3 = Mega.Settings.Menu.AccentColor, BackgroundTransparency = 0.5}):Play()
        end)
        ListItem.MouseLeave:Connect(function()
            TweenService:Create(ListItem, TweenInfo.new(0.2), {BackgroundColor3 = Mega.Settings.Menu.ElementColor, BackgroundTransparency = 0.2}):Play()
        end)

        ListItem.MouseButton1Click:Connect(function()
            DropdownButton.Text = translatedOption
            DropdownList.Visible = false
            DropdownList.Size = UDim2.new(0, 200, 0, 0)
            DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35)
            
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

    DropdownButton.MouseButton1Click:Connect(function()
        local isExpanding = not DropdownList.Visible
        
        if isExpanding then
            DropdownList.Visible = true
            local targetListHeight = math.min(#options * 32 + 10, 150)
            
            -- Smart Direction: Проверяем, сколько места осталось внизу
            local parentTab = parent:FindFirstAncestorOfClass("ScrollingFrame") or parent
            local screenHeight = parentTab.AbsoluteSize.Y
            local buttonPosInTab = DropdownButton.AbsolutePosition.Y - parentTab.AbsolutePosition.Y
            local spaceBelow = screenHeight - buttonPosInTab - 35
            
            local openUpwards = spaceBelow < (targetListHeight + 20)
            
            -- Устанавливаем позицию в зависимости от направления
            if openUpwards then
                DropdownList.Position = UDim2.new(1, -200, 0, -targetListHeight - 5)
                DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35) -- Не расширяем вниз, если открываемся вверх
            else
                DropdownList.Position = UDim2.new(1, -200, 1, 5)
                DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35 + targetListHeight + 5)
            end
            
            DropdownList.ZIndex = 500
            TweenService:Create(DropdownList, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0, 200, 0, targetListHeight) }):Play()
        else
            local t = TweenService:Create(DropdownList, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0, 200, 0, 0) })
            t:Play()
            t.Completed:Connect(function() 
                if not DropdownList.Visible then return end -- Avoid double-toggle issues
                DropdownList.Visible = false 
            end)
            DropdownFrame.Size = UDim2.new(0.9, 0, 0, 35)
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
    KeybindButton.BackgroundColor3 = Mega.Settings.Menu.ToggleOffColor
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
        
        -- Логика: если нажата та же клавиша, сбрасываем в None
        if key == currentKey then
            key = "None"
        end
        currentKey = key -- Обновляем текущий ключ для следующего сравнения

        KeybindButton.Text = key
        
        local path = statePath
        local tbl = Mega.States
        for part in path:gmatch("[^%.]+") do
            if tbl[part] == nil and part ~= path:match("([^%.]+)$") then tbl[part] = {} end
            if part ~= path:match("([^%.]+)$") then tbl = tbl[part] else tbl[part] = key end
        end

        if callback then pcall(callback, key) end
        
        local notifyText = (key == "None") and Mega.GetText("notify_keybind_removed", GetText(textKey)) or GetText("notify_keybind_set", GetText(textKey), key)
        ShowNotification(notifyText, 3)
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
    SettingsButton.BackgroundColor3 = Mega.Settings.Menu.ToggleOffColor
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
    
    SettingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isExpanded then
            local settingsHeight = SettingsLayout.AbsoluteContentSize.Y
            local targetHeight = initialHeight + settingsHeight + ComponentLayout.Padding.Offset
            ComponentFrame.Size = UDim2.new(0.95, 0, 0, targetHeight)
        end
    end)

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

function Mega.UI.CreateLabel(parent, textKey)
    local LabelFrame = Instance.new("Frame")
    LabelFrame.Name = textKey .. "LabelFrame"
    LabelFrame.Size = UDim2.new(0.9, 0, 0, 80)
    LabelFrame.BackgroundTransparency = 1
    LabelFrame.Parent = parent
    
    local LabelBackground = Instance.new("Frame", LabelFrame)
    LabelBackground.Size = UDim2.new(1, 0, 1, 0)
    LabelBackground.BackgroundColor3 = Mega.Settings.Menu.ElementColor
    LabelBackground.BackgroundTransparency = 0.6
    Instance.new("UICorner", LabelBackground).CornerRadius = UDim.new(0, 12)
    
    local LabelStroke = Instance.new("UIStroke", LabelBackground)
    LabelStroke.Color = Mega.Settings.Menu.AccentColor
    LabelStroke.Thickness = 1
    LabelStroke.Transparency = 0.5
    
    -- Decorative Animation
    task.spawn(function()
        while LabelStroke.Parent do
            TweenService:Create(LabelStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.2 }):Play()
            task.wait(2)
            TweenService:Create(LabelStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.7 }):Play()
            task.wait(2)
        end
    end)

    local Icon = Instance.new("TextLabel", LabelFrame)
    Icon.Size = UDim2.new(1, 0, 0, 40)
    Icon.Position = UDim2.new(0, 0, 0, 10)
    Icon.BackgroundTransparency = 1
    Icon.Text = "⏳"
    Icon.TextSize = 30
    Icon.Parent = LabelFrame

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 0, 30)
    TextLabel.Position = UDim2.new(0, 0, 0, 45)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = GetText(textKey)
    TextLabel.TextColor3 = Mega.Settings.Menu.TextColor
    TextLabel.TextSize = 16
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
    TextLabel.Parent = LabelFrame
    
    return LabelFrame
end
