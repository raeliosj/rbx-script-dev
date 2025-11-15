local m = {}

local Window
local Core

local ShopData
local DataService
local DailyDealsData

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    ShopData = require(Core.ReplicatedStorage.Data.SeedShopData)
    DailyDealsData = require(Core.ReplicatedStorage.Data.DailySeedShopData)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuySeeds")
    end, function()
        self:StartAutoBuySeeds()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyDailyDeals")
    end, function()
        self:StartAutoBuyDailyDeals()
    end)
end

function m:GetItemRepository()
    return ShopData or {}
end

function m:GetItemRepositoryDailyDeals()
    return DailyDealsData or {}
end

function m:GetStock(shopName, itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        return stock
    end

    stock = shopData.SeedStocks[shopName].Stocks[itemName] or 0

    if type(stock) ~= "number" then
        return stock.Stock or 0
    end

    return stock
end

function m:GetAvailableItems(shopName)
    local availableItems = {}
    local items = {}

    if shopName == "Shop" then
        items = self:GetItemRepository()
    elseif shopName == "Daily Deals" then
        items = self:GetItemRepositoryDailyDeals()
    end

    for itemName, _ in pairs(items) do
        local stock = self:GetStock(shopName, itemName)
        availableItems[itemName] = stock
    end

    return availableItems
end

function m:StartAutoBuySeeds()
    if not Window:GetConfigValue("AutoBuySeeds") then
        return
    end

    local ignoreItems = Window:GetConfigValue("IgnoreSeedItems") or {}

    for itemName, stock in pairs(self:GetAvailableItems("Shop")) do
        if stock <= 0 or table.find(ignoreItems, itemName) then
            continue
        end
        
        for i=1, stock do
            Core.ReplicatedStorage.GameEvents.BuySeedStock:FireServer("Shop", itemName)
        end
    end
end

function m:StartAutoBuyDailyDeals()
    if not Window:GetConfigValue("AutoBuyDailyDeals") then
        return
    end

    for itemName, stock in pairs(self:GetAvailableItems("Daily Deals")) do
        if stock <= 0 then
            continue
        end
        
        for i=1, stock do
            Core.ReplicatedStorage.GameEvents.BuyDailySeedShopStock:FireServer(itemName)
            task.wait(0.15)
        end
    end
end

return m