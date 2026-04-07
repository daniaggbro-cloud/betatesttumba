-- features/shop_manager.lua
-- Logic for Iron collection and Shop interaction

if not Mega.Features then Mega.Features = {} end
Mega.Features.ShopManager = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Имена предметов в Bedwars
local ITEM_IRON = "iron"
local ITEM_WOOL = "wool_white"

-- Функция для подсчета ресурсов в инвентаре
local function getItemCount(itemName)
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item.Name == itemName then
                -- В Bedwars количество обычно в атрибуте или Amount
                local amount = item:GetAttribute("Amount") or (item:IsA("Tool") and 1) or 0
                count = count + (tonumber(amount) or 0)
            end
        end
    end
    
    scan(backpack)
    scan(character)
    return count
end

-- Функция покупки через твой Remote
local purchaseRemote
local function purchaseBlocks()
    if not purchaseRemote then
        pcall(function()
            purchaseRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BedwarsPurchaseItem")
        end)
    end
    
    if purchaseRemote then
        local args = {
            {
                shopItem = {
                    currency = "iron",
                    itemType = ITEM_WOOL,
                    amount = 16,
                    price = 8,
                    disabledInQueue = { "mine_wars" },
                    category = "Blocks"
                },
                shopId = "1_item_shop"
            }
        }
        pcall(function()
            print("[TumbaHub] Purchasing wool...")
            purchaseRemote:InvokeServer(unpack(args))
        end)
    end
end

local shopConnection
function Mega.Features.ShopManager.SetEnabled(state)
    States.Bot.AutoShop.Enabled = state
    
    if state then
        if shopConnection then shopConnection:Disconnect() end
        shopConnection = Services.RunService.Heartbeat:Connect(function()
            if not States.Bot.AutoShop.Enabled then return end
            
            local ironCount = getItemCount(ITEM_IRON)
            
            -- Логика: если железа >= лимита (напр. 24) - покупаем
            if ironCount >= (States.Bot.AutoShop.TargetIron or 24) then
                purchaseBlocks()
                task.wait(1) -- Задержка после закупки
            end
        end)
    else
        if shopConnection then
            shopConnection:Disconnect()
            shopConnection = nil
        end
    end
end

-- Внешние геттеры для основного бота
function Mega.Features.ShopManager.NeedsBlocks()
    if not States.Bot.AutoShop.Enabled then return false end
    return getItemCount(ITEM_WOOL) < (States.Bot.AutoShop.MinBlocks or 16)
end

function Mega.Features.ShopManager.GetIronCount()
    return getItemCount(ITEM_IRON)
end

if States.Bot.AutoShop.Enabled then
    Mega.Features.ShopManager.SetEnabled(true)
end
