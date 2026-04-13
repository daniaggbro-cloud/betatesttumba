-- features/esp.lua
-- All logic for Player ESP and Kit ESP.

Mega.Features.ESP = {}

local Services = Mega.Services
local States = Mega.States
local Settings = Mega.Settings

local espFolder = Instance.new("Folder", Services.CoreGui)
espFolder.Name = "TumbaESP_Container"

local kitEspFolder = Instance.new("Folder", espFolder)
kitEspFolder.Name = "TumbaKitESP_Container"

local playerEspConnections = {}
local kitEspConnections = {}
local kitEspObjects = {}

local function getAsset(name, url)
    if not isfile or not writefile or not getcustomasset or not game:GetService("HttpService") then return url end
    
    local path = "TumbaHub/assets/" .. name .. ".png"
    if not isfolder("TumbaHub/assets") then makefolder("TumbaHub/assets") end
    
    if not isfile(path) and url:find("http") then
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            writefile(path, result)
        else
            return url -- Fallback to URL if download fails
        end
    end
    
    return getcustomasset(path)
end

local ICONS = {
    ["iron"] = "rbxassetid://6850537969",
    ["bee"] = "rbxassetid://7343272839",
    ["natures_essence_1"] = "rbxassetid://11003449842",
    ["thorns"] = "rbxassetid://9134549615",
    ["mushrooms"] = "rbxassetid://9134534696",
    ["wild_flower"] = "rbxassetid://9134545166",
    ["crit_star"] = "rbxassetid://9866757805",
    ["vitality_star"] = "rbxassetid://9866757969",
    ["alchemy_crystal"] = "rbxassetid://9134545166",
    ["death_adder_crystal"] = {name = "death_adder_crystal", url = "https://raw.githubusercontent.com/I-S-1/TumbaHub-Assets/main/death_adder_crystal.png"},
    ["sheep_herder"] = {name = "sheep_herder", url = "https://raw.githubusercontent.com/I-S-1/TumbaHub-Assets/main/sheep_herder.png"}
}

local function isShopItem(v)
    if not v then return false end
    if not v:IsDescendantOf(Services.Workspace) then return true end
    if v:FindFirstAncestorOfClass("ViewportFrame") then return true end
    
    local pg = Services.LocalPlayer:FindFirstChild("PlayerGui")
    if pg and v:IsDescendantOf(pg) then return true end
    
    -- Bedwars specific shop containers
    local map = Services.Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Shops") and v:IsDescendantOf(map.Shops) then
        return true
    end
    
    return false
end

--#region Kit ESP Logic
local function espadd(v, icon)
    if not v or isShopItem(v) then return end
    
    local adornee = v
    if v:IsA("Model") then
        adornee = v.PrimaryPart
    elseif not v:IsA("BasePart") then
        adornee = v:FindFirstChildWhichIsA("BasePart")
    end
    if not adornee then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adornee
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(32, 32)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
    billboard.Parent = kitEspFolder

    local image = Instance.new("ImageLabel", billboard)
    image.BackgroundTransparency = 1
    image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    
    local iconData = ICONS[icon]
    if typeof(iconData) == "table" then
        image.Image = getAsset(iconData.name, iconData.url)
    else
        image.Image = iconData or ""
    end
    
    image.Size = UDim2.fromScale(1, 1)
    Instance.new("UICorner", image).CornerRadius = UDim.new(0, 4)

    kitEspObjects[v] = billboard

    local conn
    conn = v.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if kitEspObjects[v] == billboard then kitEspObjects[v] = nil end
            billboard:Destroy()
            if conn then conn:Disconnect() end
        end
    end)
    billboard.Destroying:Connect(function()
        if conn then conn:Disconnect() end
        if kitEspObjects[v] == billboard then kitEspObjects[v] = nil end
    end)
end

local function addKit(tag, icon, isCustom)
    local function processInstance(v)
        if isCustom then
            if v.Name == tag and v:IsA("Model") then espadd(v, icon) end
        else
            if v:HasTag(tag) then espadd(v, icon) end
        end
    end

    table.insert(kitEspConnections, Services.CollectionService:GetInstanceAddedSignal(tag):Connect(function(v) 
        if not isShopItem(v) then
            espadd(v, icon) 
        end
    end))
    table.insert(kitEspConnections, Services.CollectionService:GetInstanceRemovedSignal(tag):Connect(function(v) 
        if kitEspObjects[v] then 
            kitEspObjects[v]:Destroy() 
            kitEspObjects[v] = nil 
        end 
    end))
    
    if isCustom then
        table.insert(kitEspConnections, Services.Workspace.ChildAdded:Connect(function(v)
            if not isShopItem(v) then processInstance(v) end
        end))
        for _, child in ipairs(Services.Workspace:GetChildren()) do 
            if not isShopItem(child) then processInstance(child) end 
        end
    else
        for _, instance in ipairs(Services.CollectionService:GetTagged(tag)) do 
            if not isShopItem(instance) then processInstance(instance) end 
        end
    end
end

function Mega.Features.ESP.RecreateKitESP()
    for _, v in pairs(kitEspConnections) do v:Disconnect() end
    table.clear(kitEspConnections)
    kitEspFolder:ClearAllChildren()
    table.clear(kitEspObjects)

    if not States.KitESP.Enabled then return end

    local filters = States.KitESP.Filters
    if filters.Iron then addKit("hidden-metal", "iron") end
    if filters.Bee then addKit("bee", "bee") end
    if filters.Thorns then addKit("Thorns", "thorns", true) end
    if filters.Mushrooms then addKit("Mushrooms", "mushrooms", true) end
    if filters.Sorcerer then addKit("alchemy_crystal", "alchemy_crystal") end
    
    -- New Kits
    if filters.Stella then
        addKit("CritStar", "crit_star", true)
        addKit("VitalityStar", "vitality_star", true)
    end
    if filters.Eldertree then addKit("treeOrb", "treeOrb") end
    if filters.Lucia then addKit("piggy-bank", "piggy-bank") end -- Need to ensure piggy-bank icon exists or fallback
    if filters.Cletus then addKit("Crop", "mushrooms") end -- Use mushrooms icon for crops as placeholder
    if filters.DeathAdder then 
        addKit("snake_crystal", "death_adder_crystal") 
        addKit("crystal", "death_adder_crystal") -- Fallback for generic crystal models
    end
    if filters.SheepHerder then addKit("sheep", "sheep_herder") end
end
end

function Mega.Features.ESP.SetKitEnabled(state)
    kitEspFolder.Enabled = state
    Mega.Features.ESP.RecreateKitESP()
end
--#endregion

--#region Player ESP Logic
if not Mega.Objects.ESP then Mega.Objects.ESP = {} end

local function CreateESP(player)
    if player == Services.Players.LocalPlayer then return end

    local esp = {
        boxOutline = Drawing.new("Square"),
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        toolText = Drawing.new("Text"),
        healthBarBack = Drawing.new("Square"),
        healthBarFront = Drawing.new("Square"),
        healthText = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        skeleton = {},
        chams = Instance.new("Highlight")
    }

    esp.chams.Name = player.Name .. "_Chams"
    esp.chams.Parent = espFolder
    esp.chams.Enabled = false
    esp.chams.FillTransparency = 0.5
    esp.chams.OutlineTransparency = 0.2

    local skeletonLinks = {"Head_Torso", "Torso_LeftArm", "Torso_RightArm", "Torso_LeftLeg", "Torso_RightLeg", "LeftArm_LeftHand", "RightArm_RightHand", "LeftLeg_LeftFoot", "RightLeg_RightFoot"}
    for _, linkName in ipairs(skeletonLinks) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.5
        line.ZIndex = 2
        esp.skeleton[linkName] = line
    end

    esp.boxOutline.Visible = false
    esp.boxOutline.Thickness = 4
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)
    esp.boxOutline.ZIndex = 0

    esp.box.Visible = false
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.box.ZIndex = 1

    esp.name.Visible = false
    esp.name.Size = 14
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.ZIndex = 1

    esp.distance.Visible = false
    esp.distance.Size = 12
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.ZIndex = 1
    
    esp.toolText.Visible = false
    esp.toolText.Size = 12
    esp.toolText.Center = true
    esp.toolText.Outline = true
    esp.toolText.ZIndex = 1

    esp.healthBarBack.Visible = false
    esp.healthBarBack.Thickness = 1
    esp.healthBarBack.Color = Color3.fromRGB(0, 0, 0)
    esp.healthBarBack.Filled = true

    esp.healthBarFront.Visible = false
    esp.healthBarFront.Thickness = 1
    esp.healthBarFront.Filled = true
    
    esp.healthText.Visible = false
    esp.healthText.Size = 10
    esp.healthText.Center = false
    esp.healthText.Outline = true
    esp.healthText.ZIndex = 1

    esp.tracer.Visible = false
    esp.tracer.Thickness = 1
    esp.tracer.ZIndex = 1

    Mega.Objects.ESP[player] = esp
end

local function RemoveESP(player)
    if Mega.Objects.ESP[player] then
        for k, drawing in pairs(Mega.Objects.ESP[player]) do
            if k == "skeleton" then
                for _, line in pairs(drawing) do line:Remove() end
            elseif k == "chams" then
                drawing:Destroy()
            else
                drawing:Remove()
            end
        end
        Mega.Objects.ESP[player] = nil
    end
end

local function UpdateESPColors()
    local lp = Services.Players.LocalPlayer
    for player, esp in pairs(Mega.Objects.ESP) do
        if player and player.Parent and player.Character then
            local isTeam = lp and player.Team and lp.Team and (player.Team == lp.Team)
            local color = States.ESP.EnemyColor
            
            if States.ESP.UseTeamColor and player.Team and player.Team.TeamColor then
                color = player.Team.TeamColor.Color
            elseif isTeam then
                color = States.ESP.TeamColor
            else
                color = States.ESP.EnemyColor
            end

            esp.box.Color = color
            esp.name.Color = color
            esp.distance.Color = color
            esp.toolText.Color = color
            esp.tracer.Color = color
            esp.chams.FillColor = color
            esp.chams.OutlineColor = color
            for _, line in pairs(esp.skeleton) do
                line.Color = color
            end
        end
    end
end

local function setESPVisibility(esp, visible)
    esp.boxOutline.Visible = visible
    esp.box.Visible = visible
    esp.name.Visible = visible
    esp.distance.Visible = visible
    esp.toolText.Visible = visible
    esp.healthBarBack.Visible = visible
    esp.healthBarFront.Visible = visible
    esp.healthText.Visible = visible
    esp.tracer.Visible = visible
    esp.chams.Enabled = false
    for _, line in pairs(esp.skeleton) do line.Visible = false end
end

local function drawSkeleton(esp, char, camera, isVisible)
    if not isVisible then 
        for _, line in pairs(esp.skeleton) do line.Visible = false end
        return 
    end
    
    local parts = {
        Head = char:FindFirstChild("Head"),
        Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
        LeftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),
        RightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),
        LeftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),
        RightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"),
        LeftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"),
        RightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"),
        LeftFoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg"),
        RightFoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg"),
    }
    
    local function drawLine(part1, part2, lineObj)
        if part1 and part2 then
            local pos1, vis1 = camera:WorldToViewportPoint(part1.Position)
            local pos2, vis2 = camera:WorldToViewportPoint(part2.Position)
            if vis1 or vis2 then
                lineObj.Visible = true
                lineObj.From = Vector2.new(pos1.X, pos1.Y)
                lineObj.To = Vector2.new(pos2.X, pos2.Y)
            else
                lineObj.Visible = false
            end
        else
            lineObj.Visible = false
        end
    end

    drawLine(parts.Head, parts.Torso, esp.skeleton["Head_Torso"])
    drawLine(parts.Torso, parts.LeftArm, esp.skeleton["Torso_LeftArm"])
    drawLine(parts.Torso, parts.RightArm, esp.skeleton["Torso_RightArm"])
    drawLine(parts.Torso, parts.LeftLeg, esp.skeleton["Torso_LeftLeg"])
    drawLine(parts.Torso, parts.RightLeg, esp.skeleton["Torso_RightLeg"])
    drawLine(parts.LeftArm, parts.LeftHand, esp.skeleton["LeftArm_LeftHand"])
    drawLine(parts.RightArm, parts.RightHand, esp.skeleton["RightArm_RightHand"])
    drawLine(parts.LeftLeg, parts.LeftFoot, esp.skeleton["LeftLeg_LeftFoot"])
    drawLine(parts.RightLeg, parts.RightFoot, esp.skeleton["RightLeg_RightFoot"])
end

local function UpdateESP()
    local camera = Services.Workspace.CurrentCamera
    if not camera then return end
    
    local vp = camera.ViewportSize
    local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)
    local screenBottom = Vector2.new(vp.X / 2, vp.Y)
    local screenTop = Vector2.new(vp.X / 2, 0)
    
    local lp = Services.Players.LocalPlayer
    local localChar = lp and lp.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for player, esp in pairs(Mega.Objects.ESP) do
        if player == lp then
            RemoveESP(player)
        else
            local isVisible = false
            if player and player.Parent and player.Character and localRoot then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                local humanoid = player.Character:FindFirstChild("Humanoid")

                if rootPart and head and humanoid and humanoid.Health > 0 then
                    local isTeammate = lp and player.Team and lp.Team and (player.Team == lp.Team)
                    if not (isTeammate and not States.ESP.ShowTeam) then
                        local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                        local distance = (localRoot.Position - rootPart.Position).Magnitude

                        local health = humanoid.Health
                        if health ~= health then health = 0 end
                        local maxHealth = humanoid.MaxHealth
                        if maxHealth <= 0 or maxHealth ~= maxHealth then maxHealth = 100 end

                        if onScreen and distance <= States.ESP.MaxDistance and distance > 0.1 then
                            isVisible = true
                            local scale = 1000 / distance
                            local width = scale * 2
                            local height = scale * 3
                            
                            -- Tracer Origin
                            local tOrigin = screenBottom
                            if States.ESP.TracerOrigin == "Top" then tOrigin = screenTop
                            elseif States.ESP.TracerOrigin == "Center" then tOrigin = screenCenter
                            elseif States.ESP.TracerOrigin == "Mouse" then 
                                local mp = Services.UserInputService:GetMouseLocation()
                                tOrigin = Vector2.new(mp.X, mp.Y)
                            end

                            if States.ESP.Boxes then
                                esp.box.Visible = States.ESP.Enabled
                                esp.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                                esp.box.Size = Vector2.new(width, height)
                                
                                esp.boxOutline.Visible = States.ESP.Enabled and States.ESP.Outline
                                esp.boxOutline.Position = esp.box.Position
                                esp.boxOutline.Size = esp.box.Size
                            else
                                esp.box.Visible = false
                                esp.boxOutline.Visible = false
                            end

                            if States.ESP.Names then
                                esp.name.Visible = States.ESP.Enabled
                                esp.name.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 20)
                                esp.name.Text = player.Name
                            else
                                esp.name.Visible = false
                            end

                            local textOffset = 10
                            if States.ESP.Distance then
                                esp.distance.Visible = States.ESP.Enabled
                                esp.distance.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + textOffset)
                                esp.distance.Text = Mega.GetText("esp_studs", math.floor(distance))
                                textOffset = textOffset + 14
                            else
                                esp.distance.Visible = false
                            end
                            
                            if States.ESP.HeldItem then
                                local tool = player.Character:FindFirstChildOfClass("Tool")
                                if tool then
                                    esp.toolText.Visible = States.ESP.Enabled
                                    esp.toolText.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + textOffset)
                                    esp.toolText.Text = tool.Name
                                    textOffset = textOffset + 14
                                else
                                    esp.toolText.Visible = false
                                end
                            else
                                esp.toolText.Visible = false
                            end

                            if States.ESP.Health then
                                local healthPercent = math.clamp(health / maxHealth, 0, 1)
                                local barHeight = height * healthPercent
                                local barColor = Color3.fromHSV(0.33 * healthPercent, 1, 1)

                                esp.healthBarBack.Visible = States.ESP.Enabled
                                esp.healthBarBack.Position = Vector2.new(screenPos.X - width / 2 - 7, screenPos.Y - height / 2)
                                esp.healthBarBack.Size = Vector2.new(4, height)

                                esp.healthBarFront.Visible = States.ESP.Enabled
                                esp.healthBarFront.Color = barColor
                                esp.healthBarFront.Position = Vector2.new(screenPos.X - width / 2 - 7, screenPos.Y - height / 2 + (height - barHeight))
                                esp.healthBarFront.Size = Vector2.new(4, barHeight)
                                
                                if States.ESP.HealthText then
                                    esp.healthText.Visible = States.ESP.Enabled
                                    esp.healthText.Position = Vector2.new(screenPos.X - width / 2 - 28, screenPos.Y - height / 2 + (height - barHeight) - 6)
                                    esp.healthText.Text = tostring(math.floor(health))
                                    esp.healthText.Color = barColor
                                else
                                    esp.healthText.Visible = false
                                end
                            else
                                esp.healthBarBack.Visible = false
                                esp.healthBarFront.Visible = false
                                esp.healthText.Visible = false
                            end

                            if States.ESP.Tracers then
                                esp.tracer.Visible = States.ESP.Enabled
                                esp.tracer.From = Vector2.new(screenPos.X, screenPos.Y + height / 2)
                                esp.tracer.To = tOrigin
                            else
                                esp.tracer.Visible = false
                            end
                            
                            if States.ESP.Chams then
                                esp.chams.Adornee = player.Character
                                -- Important: if head/root present, char is rendered
                                esp.chams.Enabled = States.ESP.Enabled
                            else
                                esp.chams.Enabled = false
                            end
                        end
                    end
                end
            end
            
            drawSkeleton(esp, player.Character, camera, isVisible and States.ESP.Skeleton and States.ESP.Enabled)

            if not isVisible then
                setESPVisibility(esp, false)
            end
        end
    end
end

-- Initialize ESP for all players
for _, player in pairs(Services.Players:GetPlayers()) do
    CreateESP(player)
end

table.insert(playerEspConnections, Services.Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end))

table.insert(playerEspConnections, Services.Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end))

function Mega.Features.ESP.SetEnabled(state)
    States.ESP.Enabled = state
    if state then
        if not Mega.Objects.ESPRenderConnection then
            Mega.Objects.ESPRenderConnection = Services.RunService.RenderStepped:Connect(function()
                UpdateESP()
                UpdateESPColors()
            end)
        end
    else
        if Mega.Objects.ESPRenderConnection then
            Mega.Objects.ESPRenderConnection:Disconnect()
            Mega.Objects.ESPRenderConnection = nil
        end
        for player, esp in pairs(Mega.Objects.ESP) do
            setESPVisibility(esp, false)
        end
    end
end
--#endregion

