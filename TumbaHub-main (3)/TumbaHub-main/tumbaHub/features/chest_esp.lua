-- features/chest_esp.lua
-- Logic for Chest ESP (Items visibility)

if not Mega.Features then Mega.Features = {} end
Mega.Features.ChestESP = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Misc then States.Misc = {} end
if not States.Misc.ChestESP then
    States.Misc.ChestESP = { Enabled = false, MaxDistance = 300 }
end

if not Mega.Objects.ChestESPConnections then Mega.Objects.ChestESPConnections = {} end
local connections = Mega.Objects.ChestESPConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local function isShopItem(v)
    if not v then return false end
    if not v:IsDescendantOf(Services.Workspace) then return true end
    if v:FindFirstAncestorOfClass("ViewportFrame") then return true end
    
    local pg = Services.LocalPlayer:FindFirstChild("PlayerGui")
    if pg and v:IsDescendantOf(pg) then return true end
    
    local map = Services.Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Shops") and v:IsDescendantOf(map.Shops) then
        return true
    end
    
    return false
end

local ItemMeta = {}
pcall(function()
    ItemMeta = require(Services.ReplicatedStorage.TS.item["item-meta"]).items
end)

for _, name in ipairs({"TumbaChestESP", "TumbaChestESP_V2", "TumbaChestESP_V3", "TumbaChestESP_V4", "TumbaChestESP_V5"}) do
    local old = Services.CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local espFolder = Instance.new("Folder")
espFolder.Name = "TumbaChestESP_V5"
espFolder.Parent = Services.CoreGui

local chestGuis = {}

local itemWeights = {
    ["emerald"] = 100, ["diamond"] = 90, ["iron"] = 50, ["gold"] = 40,
    ["sword"] = 30, ["armor"] = 30, ["bow"] = 20, ["stone"] = 5,
    ["wood"] = 1, ["wool"] = 0
}

local colorMap = {
    ["emerald"] = Color3.fromRGB(80, 255, 120), ["diamond"] = Color3.fromRGB(80, 200, 255),
    ["iron"] = Color3.fromRGB(220, 220, 220), ["gold"] = Color3.fromRGB(255, 215, 50),
    ["sword"] = Color3.fromRGB(255, 80, 80), ["armor"] = Color3.fromRGB(150, 150, 255),
    ["wood"] = Color3.fromRGB(180, 120, 70), ["stone"] = Color3.fromRGB(150, 150, 150)
}

local function formatItem(rawName)
    local lowerName = rawName:lower()
    local color = Color3.fromRGB(255, 255, 255) 
    local weight = 0
    for key, c in pairs(colorMap) do if lowerName:find(key) then color = c end end
    for key, w in pairs(itemWeights) do if lowerName:find(key) then weight = w end end
    local meta = ItemMeta[rawName]
    local image = (meta and meta.image) or ""
    local displayName = rawName:gsub("_", " ")
    return displayName, color, image, weight
end

local function StartESP()
    if connections.ESP then connections.ESP:Disconnect() end
    
    connections.ESP = Services.RunService.Heartbeat:Connect(function()
        if not States.Misc.ChestESP.Enabled then return end
        
        local allChests = Services.CollectionService:GetTagged("chest")
        local activeChests = {}
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local maxDist = (States.Misc and States.Misc.ChestESP and States.Misc.ChestESP.MaxDistance) or 300
        
        for _, chest in pairs(allChests) do
            if chest:IsA("BasePart") and not isShopItem(chest) then
                local chestPos = chest.Position
                local dist = hrp and math.floor((hrp.Position - chestPos).Magnitude) or 0
                
                if dist <= maxDist then
                    activeChests[chest] = true
                    
                    local chestFolderValue = chest:FindFirstChild("ChestFolderValue")
                    local itemsFolder = chestFolderValue and chestFolderValue.Value
                    
                    local gui = chestGuis[chest]
                    if not gui then
                        gui = Instance.new("BillboardGui")
                        gui.Name = "ChestESP"
                        gui.Size = UDim2.new(0, 160, 0, 180)
                        gui.StudsOffset = Vector3.new(0, 0.5, 0)
                        gui.AlwaysOnTop = true
                        gui.MaxDistance = maxDist
                        
                        local mainFrame = Instance.new("Frame", gui)
                        mainFrame.Name = "MainFrame"
                        mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                        mainFrame.BackgroundTransparency = 0.25
                        mainFrame.Size = UDim2.new(1, 0, 0, 0)
                        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                        mainFrame.AutomaticSize = Enum.AutomaticSize.Y
                        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
                        
                        local uiScale = Instance.new("UIScale", mainFrame)
                        uiScale.Name = "UIScale"
                        
                        local stroke = Instance.new("UIStroke", mainFrame)
                        stroke.Color = Color3.fromRGB(50, 50, 60)
                        stroke.Thickness = 1.5
                        stroke.Transparency = 0.3
                        
                        local listFrame = Instance.new("Frame", mainFrame)
                        listFrame.Name = "ListFrame"
                        listFrame.BackgroundTransparency = 1
                        listFrame.Size = UDim2.new(1, 0, 0, 0)
                        listFrame.AutomaticSize = Enum.AutomaticSize.Y
                        
                        local layout = Instance.new("UIListLayout", listFrame)
                        layout.SortOrder = Enum.SortOrder.LayoutOrder
                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                        layout.VerticalAlignment = Enum.VerticalAlignment.Center
                        layout.Padding = UDim.new(0, 3)
                        Instance.new("UIPadding", listFrame).PaddingBottom = UDim.new(0, 5)
                        Instance.new("UIPadding", listFrame).PaddingTop = UDim.new(0, 5)

                        gui.Parent = espFolder
                        gui.Adornee = chest
                        chestGuis[chest] = gui
                    end
                    
                    gui.MaxDistance = maxDist
                    
                    local mainFrame = gui:FindFirstChild("MainFrame")
                    local listFrame = mainFrame and mainFrame:FindFirstChild("ListFrame")
                    local uiScale = mainFrame and mainFrame:FindFirstChild("UIScale")
                    
                    if uiScale then
                        local scaleFactor = math.clamp(1 - (dist / 350), 0.35, 1)
                        uiScale.Scale = scaleFactor
                    end
                    
                    if itemsFolder and listFrame then
                        for _, child in pairs(listFrame:GetChildren()) do
                            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
                        end
                        
                        local contents = itemsFolder:GetChildren()
                        if #contents > 0 then
                            local itemCounts = {}
                            for _, item in pairs(contents) do
                                if item:IsA("Accessory") or item:IsA("Tool") then
                                    local amount = item:GetAttribute("Amount")
                                    if not amount and item:FindFirstChild("Amount") then amount = item.Amount.Value end
                                    amount = amount or 1
                                    itemCounts[item.Name] = (itemCounts[item.Name] or 0) + amount
                                end
                            end
                            
                            local sortedItems = {}
                            for name, count in pairs(itemCounts) do
                                local clName, color, image, weight = formatItem(name)
                                table.insert(sortedItems, {rawName = name, cleanName = clName, count = count, color = color, image = image, weight = weight})
                            end
                            
                            table.sort(sortedItems, function(a, b) return a.weight > b.weight end)
                            
                            for i, data in ipairs(sortedItems) do
                                local itemContainer = Instance.new("Frame")
                                itemContainer.BackgroundTransparency = 1
                                itemContainer.Size = UDim2.new(1, 0, 0, 18)
                                itemContainer.LayoutOrder = i
                                itemContainer.Parent = listFrame
                                
                                local hLayout = Instance.new("UIListLayout", itemContainer)
                                hLayout.FillDirection = Enum.FillDirection.Horizontal
                                hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                                hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                                hLayout.Padding = UDim.new(0, 5)
                                Instance.new("UIPadding", itemContainer).PaddingLeft = UDim.new(0, 10)
                                
                                if data.image and data.image ~= "" then
                                    local icon = Instance.new("ImageLabel", itemContainer)
                                    icon.BackgroundTransparency = 1
                                    icon.Size = UDim2.new(0, 16, 0, 16)
                                    icon.Image = data.image
                                    icon.ScaleType = Enum.ScaleType.Fit
                                end
                                
                                local label = Instance.new("TextLabel", itemContainer)
                                label.BackgroundTransparency = 1
                                label.Size = UDim2.new(0, 0, 1, 0)
                                label.AutomaticSize = Enum.AutomaticSize.X
                                label.Text = data.count .. "x " .. data.cleanName
                                label.TextColor3 = data.color
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 12
                            end
                            
                            mainFrame.UIStroke.Color = Color3.fromRGB(100, 150, 255) 
                            mainFrame.Visible = true
                        else
                            mainFrame.Visible = false
                        end
                    end
                end
             end
         end
         
         for chest, gui in pairs(chestGuis) do
             if not activeChests[chest] or not chest.Parent then
                 gui:Destroy()
                 chestGuis[chest] = nil
             end
         end
     end)
 end
 
 -- Public API
 function Mega.Features.ChestESP.SetEnabled(state)
     States.Misc.ChestESP.Enabled = state
     if state then
         StartESP()
     else
         if connections.ESP then
             connections.ESP:Disconnect()
             connections.ESP = nil
         end
         -- Очистка существующих ESP при выключении
         for chest, gui in pairs(chestGuis) do
             if gui then gui:Destroy() end
         end
         table.clear(chestGuis)
     end
 end
 
 -- Initialize if enabled on startup
 if States.Misc.ChestESP.Enabled then
     Mega.Features.ChestESP.SetEnabled(true)
 end
