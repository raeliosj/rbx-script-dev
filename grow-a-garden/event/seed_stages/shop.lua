local m = {}

local Window
local Core
local Shop

local Connections
local ShopUI = "EventShop_UI"
local ShopItems = {"Evo Beetroot I", "Evo Pumpkin I", "Evo Mushroom I", "Evo Blueberry I"}

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop

    local shopGui = Core:GetPlayerGui():FindFirstChild(ShopUI)
    
    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyEventItems")
    end, function()
        self:BuyAllEventItems()
    end)
end

function m:BuyEventItem(itemName)
    if not itemName or itemName == "" then
        warn("Invalid event item name")
        return
    end

    Core.GameEvents.BuyEventShopStock:FireServer(itemName, 1)
end

function m:BuyAllEventItems()
    local items = Shop:GetAvailableItems(ShopUI)

    if not items or #items == 0 then
        items = {} -- Initialize empty table first
        for _, itemName in ipairs(ShopItems) do
            items[itemName] = 5
        end
    end
    
    for itemName, stock in pairs(items) do
        if stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuyEventItem(itemName)
            task.wait(0.1) -- Small delay to avoid spamming
        end
    end
end

return m