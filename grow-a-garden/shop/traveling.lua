local m = {}

local Window
local Core
local PetModule

local DataService
local FallMerchantShopData
local GnomeMerchantShopData
local HoneyMerchantShopData
local SkyMerchantShopData
local SprayMerchantShopData
local SprinklerMerchantShopData
local SummerMerchantShopData

function m:Init(_window, _core, _petModule)
    Window = _window
    Core = _core
    PetModule = _petModule

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    FallMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.FallMerchantShopData)
    GnomeMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.GnomeMerchantShopData)
    HoneyMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.HoneyMerchantShopData)
    SkyMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SkyMerchantShopData)
    SprayMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SprayMerchantShopData)
    SprinklerMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SprinklerMerchantShopData)
    SummerMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SummerMerchantShopData)

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyTravelingMerchant")
    end, function()
        self:StartBuyTravelingItems()
    end)
end

function m:GetItemRepository(shopName)
    if shopName == "FallMerchant" then
        return FallMerchantShopData or {}
    elseif shopName == "GnomeMerchant" then
        return GnomeMerchantShopData or {}
    elseif shopName == "HoneyMerchant" then
        return HoneyMerchantShopData or {}
    elseif shopName == "SkyMerchant" then
        return SkyMerchantShopData or {}
    elseif shopName == "SprayMerchant" then
        return SprayMerchantShopData or {}
    elseif shopName == "SprinklerMerchant" then
        return SprinklerMerchantShopData or {}
    elseif shopName == "SummerMerchant" then
        return SummerMerchantShopData or {}
    end

    return {}
end

function m:GetAllItemsRepository()
    local allItems = {}

    local shops = {
        "FallMerchant",
        "GnomeMerchant",
        "HoneyMerchant",
        "SkyMerchant",
        "SprayMerchant",
        "SprinklerMerchant",
        "SummerMerchant"
    }

    for _, shopName in pairs(shops) do
        local items = self:GetItemRepository(shopName)
        for itemName, _ in pairs(items) do
            allItems[itemName] = shopName
        end
    end

    return allItems
end

function m:GetDetailItem(itemName)
    local allItems = self:GetAllItemsRepository()
    local shopName = allItems[itemName]
    if not shopName then
        return nil
    end

    local items = self:GetItemRepository(shopName)
    return items[itemName] or nil
end

function m:GetStock(itemName)
    local shopData = DataService:GetData()
    local stock = 0
    if not shopData then
        return stock
    end

    stock = shopData.TravelingMerchantShopStock.Stocks[itemName] or 0

    if type(stock) ~= "number" then
        return stock.Stock or 0
    end

    return stock
end

function m:GetAvailableItems()
    local availableItems = {}
    local items = self:GetAllItemsRepository()

    for itemName, _ in pairs(items) do
        local stock = self:GetStock(itemName)
        availableItems[itemName] = stock
    end

    return availableItems
end

function m:GetAllIgnoreItems()
    local ignoreFallItems = Window:GetConfigValue("IgnoreFallMerchantItems") or {}
    local ignoreGnomeItems = Window:GetConfigValue("IgnoreGnomeMerchantItems") or {}
    local ignoreHoneyItems = Window:GetConfigValue("IgnoreHoneyMerchantItems") or {}
    local ignoreSkyItems = Window:GetConfigValue("IgnoreSkyMerchantItems") or {}
    local ignoreSprayItems = Window:GetConfigValue("IgnoreSprayMerchantItems") or {}
    local ignoreSprinklerItems = Window:GetConfigValue("IgnoreSprinklerMerchantItems") or {}
    local ignoreSummerItems = Window:GetConfigValue("IgnoreSummerMerchantItems") or {}
    
    local allIgnoreItems = {}
    for _, itemName in pairs(ignoreFallItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreGnomeItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreHoneyItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreSkyItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreSprayItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreSprinklerItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreSummerItems) do
        table.insert(allIgnoreItems, itemName)
    end

    return allIgnoreItems
end

function m:StartBuyTravelingItems()
    if not Window:GetConfigValue("AutoBuyTravelingMerchant") then
        return
    end

    local corePetTeam = Window:GetConfigValue("CorePetTeam") or ""
    local shopPetTeam = Window:GetConfigValue("ShopPetTeam") or ""
    local ignoreItems = self:GetAllIgnoreItems()
    local petItems = {}

    for itemName, stock in pairs(self:GetAvailableItems()) do
        if stock <= 0 or table.find(ignoreItems, itemName) then
            continue
        end
        
        local itemDetail = self:GetDetailItem(itemName)
        if itemDetail and itemDetail.ItemType == "Pet" and shopPetTeam ~= "" and corePetTeam ~= "" then
            petItems[itemName] = stock
            continue
        end

        for i=1, stock do
            Core.GameEvents.BuyTravelingMerchantShopStock:FireServer(itemName, 5)
            task.wait(0.15)
        end
    end

    if #petItems == 0 then
        return
    end

    while PetModule:GetCurrentPetTeam() ~= "core" do
        task.wait(1)
    end

    PetModule:ChangeTeamPets(shopPetTeam, "shop")

    for itemName, stock in pairs(petItems) do
        for i=1, stock do
            Core.GameEvents.BuyTravelingMerchantShopStock:FireServer(itemName, 5)
            task.wait(0.15)
        end
    end

    PetModule:ChangeTeamPets(corePetTeam, "core")
end


return m