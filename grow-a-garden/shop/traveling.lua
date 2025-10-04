local m = {}

local Window
local Core
local Shop

local Connections
local ShopUI = "TravelingMerchantShop_UI"

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyTravelingMerchant")
    end, function()
        self:BuyAllTravelingItems()
    end)
end

function m:BuyTravelingItem(itemName)
    if not itemName or itemName == "" then
        warn("Invalid traveling item name")
        return
    end

    Core.GameEvents.BuyTravelingMerchantShopStock:FireServer(itemName, 5)
end

function m:BuyAllTravelingItems()
    local items = Shop:GetAvailableItems(ShopUI)

    for itemName, stock in pairs(items) do
        if stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuyTravelingItem(itemName)
            task.wait(0.1) -- Small delay to avoid spamming
        end
    end
end


return m