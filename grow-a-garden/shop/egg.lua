local m = {}

local Window
local Core

local ShopData
local DataService

function m:Init(_window, _core)
    Window = _window
    Core = _core
    

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    ShopData = require(Core.ReplicatedStorage.Data.PetEggData)

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyEggs")
    end, function()
        self:StartBuyEgg()
    end)
end

function m:GetItemRepository()
    return ShopData or {}
end

function m:GetStock(itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        warn("No shop data found")
        return stock
    end

    for _, data in shopData.PetEggStock.Stocks do
        if data.EggName == itemName then
            stock = stock + data.Stock
        end
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

function m:StartBuyEgg()
    if not Window:GetConfigValue("AutoBuyEggs") then
        return
    end

    local ignoreItems = Window:GetConfigValue("IgnoreEggItems") or {}
    for eggName, stock in pairs(self:GetAvailableItems()) do
        if stock <= 0 or table.find(ignoreItems, eggName) then
            continue
        end
        for i=1, stock do
             Core.ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(eggName)
             task.wait(0.15)
        end
    end
end

return m