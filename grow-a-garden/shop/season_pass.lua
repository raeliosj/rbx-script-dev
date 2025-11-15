local m = {}

local Window
local Core

local ShopData
local DataService
local CurrentSeason

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    ShopData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassShopData)
    local seasonPassData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassData)
    CurrentSeason = seasonPassData.CurrentSeason or ""

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuySeasonPasses")
    end, function()
        self:StartBuySeasonPassItems()
    end)
end

function m:GetItemRepository()
    return ShopData.ShopItems or {}
end

function m:GetStock(itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        return stock
    end

    stock = shopData.SeasonPass[CurrentSeason].Stocks[itemName] or 0

    if type(stock) ~= "number" then
        return stock.Stock or 0
    end

    return stock
end

function m:GetAvailableSeasonPassesItems()
    local availableItems = {}
    local items = self:GetItemRepository()

    for itemName, _ in pairs(items) do
        local stock = self:GetStock(itemName)
        availableItems[itemName] = stock
    end

    return availableItems
end

function m:StartBuySeasonPassItems()
    if not Window:GetConfigValue("AutoBuySeasonPasses") then
        return
    end
    
    local ignoreItems = Window:GetConfigValue("IgnoreSeasonPassItems") or {}

    for itemName, stock in pairs(self:GetAvailableSeasonPassesItems()) do
        if stock <= 0 or table.find(ignoreItems, itemName) then
            continue
        end

        for i=1, stock do
            Core.ReplicatedStorage.GameEvents.SeasonPass.BuySeasonPassStock:FireServer(itemName)
            task.wait(0.15)
        end
    end
end

return m