local m = {}

local Window
local Core

local ShopData
local DataService

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    ShopData = require(Core.ReplicatedStorage.Data.GearShopData)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyGear")
    end, function()
        self:StartAutoBuyGear()
    end)
end

function m:GetItemRepository()
    return ShopData.Gear or {}
end

function m:GetStock(itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        return stock
    end

    stock = shopData.GearStock.Stocks[itemName] or 0

    if type(stock) ~= "number" then
        return stock.Stock or 0
    end

    return stock
end

function m:GetAvailableItems()
    local availableItems = {}
    local items = self:GetItemRepository()

    for itemName, _ in pairs(items) do
        local stock = self:GetStock(itemName)
        availableItems[itemName] = stock
    end

    return availableItems
end

function m:StartAutoBuyGear()
    if not Window:GetConfigValue("AutoBuyGear") then
        return
    end

    local ignoreItems = Window:GetConfigValue("IgnoreGearItems") or {}

    for gearName, stock in pairs(self:GetAvailableItems()) do
        if stock <= 0 or table.find(ignoreItems, gearName) then
            continue
        end
        
        for i=1, stock do
            Core.GameEvents.BuyGearStock:FireServer(gearName)
             task.wait(0.15)
        end
    end
end

return m