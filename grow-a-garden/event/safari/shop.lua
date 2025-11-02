local m = {}

local Window
local Core

local ShopData
local DataService


function m:Init(_window, _core)
    Window = _window
    Core = _core

    ShopData = require(Core.ReplicatedStorage.Data.EventShopData)
    DataService = require(Core.ReplicatedStorage.Modules.DataService)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuySafariMerchant")
    end, function()
        self:StartAutoBuySafariMerchant()
    end)
end

function m:GetItemRepository(merchant)
    return ShopData[merchant] or {}
end

function m:GetDetailItem(merchant, itemName)
    local items = self:GetItemRepository(merchant)
    return items[itemName] or nil
end

function m:GetStock(shopName, itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        return stock
    end

    stock = shopData.EventShopStock[shopName].Stocks[itemName] or 0

    if type(stock) ~= "number" then
        return stock.Stock or 0
    end

    return stock
end

function m:StartAutoBuySafariMerchant()
    if not Window:GetConfigValue("AutoBuySafariMerchant") then
        return
    end

    local MerchantName = "Safari Shop"
    local ignoreItemToBuy = Window:GetConfigValue("IgnoreSafariMerchantItems") or {}
    local itemsToBuy = self:GetItemRepository("Safari Shop")

    for itemName, _ in pairs(itemsToBuy) do
        if table.find(ignoreItemToBuy, itemName) then
            continue
        end

        local stock = self:GetStock(MerchantName, itemName)
        if stock <= 0 then
            continue
        end

        for i = 1, stock do
            Window:ShowInfo("Safari Merchant", "Buying item: " .. itemName .. " from " .. MerchantName)
            Core.ReplicatedStorage.GameEvents.BuyEventShopStock:FireServer(itemName, MerchantName)
            task.wait(0.15)
        end
    end
end


return m