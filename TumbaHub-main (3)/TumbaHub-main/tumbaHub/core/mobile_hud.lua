-- core/mobile_hud.lua
-- Handles creation of draggable, customizable quick-action buttons for mobile users

local Services = Mega.Services
local Settings = Mega.Settings
local States = Mega.States

Mega.MobileHUD = {}
Mega.Objects.MobileButtons = Mega.Objects.MobileButtons or {}

-- Initialize the container
if Services.CoreGui:FindFirstChild("TumbaMobileHUD") then
    Services.CoreGui.TumbaMobileHUD:Destroy()
end

local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "TumbaMobileHUD"
HUDGui.ResetOnSpawn = false
HUDGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
HUDGui.Parent = Services.CoreGui

Mega.Settings.MobileHUD = Mega.Settings.MobileHUD or {
    Positions = {} -- To save their locations if dragged
}

-- Create a single button
function Mega.MobileHUD.CreateActionButton(id, tooltip, imageId, toggleCallback, getStateFunc)
    if Mega.Objects.MobileButtons[id] then
        Mega.Objects.MobileButtons[id]:Destroy()
    end

    local btnSize = 55

    local Button = Instance.new("ImageButton", HUDGui)
    Button.Name = "MobileBtn_" .. id
    Button.Size = UDim2.new(0, btnSize, 0, btnSize)
    
    -- Load saved position or set default (we'll start them dynamically spaced)
    if Mega.Settings.MobileHUD.Positions[id] then
        Button.Position = Mega.Settings.MobileHUD.Positions[id]
    else
        local count = 0
        for _ in pairs(Mega.Objects.MobileButtons) do count = count + 1 end
        Button.Position = UDim2.new(1, -70, 0.5, (count * 65) - 100) -- Stacked on the right
    end
    
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Button.BackgroundTransparency = 0.2
    Button.Image = imageId or "rbxassetid://1316045217" -- Default empty circle or logo
    Button.ImageColor3 = Color3.new(1, 1, 1)
    Button.Active = true

    Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0) -- Circle

    local btnStroke = Instance.new("UIStroke", Button)
    btnStroke.Color = Settings.Menu.AccentColor
    btnStroke.Thickness = 2.5
    btnStroke.Transparency = 0.3

    local shadow = Instance.new("ImageLabel", Button)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Settings.Menu.AccentColor
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = -1

    -- Smooth Drag Logic
    local dragging, dragStart, startPos
    Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Button.Position
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local moveTween = Services.TweenService:Create(Button, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            })
            moveTween:Play()
            -- Save new position
            Mega.Settings.MobileHUD.Positions[id] = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            -- Safe save after drag
            if Mega.ConfigSystem and Mega.ConfigSystem.Save then
                task.spawn(function() Mega.ConfigSystem.Save("autosave") end)
            end
        end
    end)

    -- Click Logic
    local lastClick = 0
    Button.MouseButton1Click:Connect(function()
        if tick() - lastClick < 0.2 then return end -- anti-spam
        lastClick = tick()
        -- Use the user-provided callback
        if toggleCallback then toggleCallback() end
    end)

    -- Dynamic State Updater (glowing when enabled)
    Mega.Objects.Connections["MobileBtnUpdate_"..id] = Services.RunService.RenderStepped:Connect(function()
        if not Button or not Button.Parent then return end
        
        btnStroke.Color = Settings.Menu.AccentColor
        shadow.ImageColor3 = Settings.Menu.AccentColor
        
        -- Default to checking the function if it exists
        local isActive = false
        if getStateFunc then
            isActive = getStateFunc()
        end
        
        if isActive then
            btnStroke.Transparency = 0.1
            shadow.ImageTransparency = 0.4
            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        else
            btnStroke.Transparency = 0.5
            shadow.ImageTransparency = 0.8
            Button.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end)

    Mega.Objects.MobileButtons[id] = Button
    Button.Visible = false -- Hidden by default until activated through settings
    return Button
end

function Mega.MobileHUD.SetVisible(id, isVisible)
    if Mega.Objects.MobileButtons[id] then
        Mega.Objects.MobileButtons[id].Visible = isVisible
    end
end

print("📱 Mobile HUD Module loaded!")
