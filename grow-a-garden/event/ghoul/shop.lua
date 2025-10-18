local m = {}

local Window
local Core
local PetModule

local ShopData
local DataService

local ShopStockConnection

m.Merchant = {
    "Spooky Seeds",
    "Creepy Critters",
    "Devilish Decor",
}

function m:Init(_window, _core, _petModule)
    Window = _window
    Core = _core
    PetModule = _petModule

    ShopData = require(Core.ReplicatedStorage.Data.EventShopData)
    DataService = require(Core.ReplicatedStorage.Modules.DataService)

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoBuySpookyShop")
        end, 
        function()
            self:StartAutoBuySpookySeeds()
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoBuyCreepyShop")
        end, 
        function()
            self:StartAutoBuyCreepyCritters()
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoBuyDevilishShop")
        end, 
        function()
            self:StartAutoBuyDevilishDecor()
        end
    )
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

function m:GetAvailableItems(merchant)
    local items = self:GetItemRepository(merchant)
    local availableItems = {}

    for itemName, _ in pairs(items) do
        local stock = self:GetStock(merchant, itemName) or 0 or 0
        if stock > 0 then
            table.insert(availableItems, itemName)
        end
    end

    return availableItems
end

function m:StartAutoBuySpookySeeds()
    if not Window:GetConfigValue("AutoBuySpookyShop") then
        return
    end

    local merchant = "Spooky Seeds"
    local itemNames = Window:GetConfigValue("SpookyShopItem")
    if not itemNames or #itemNames == 0 then
        warn("No items selected for auto-buy")
        return
    end

    for _, itemName in ipairs(itemNames) do
        local stock = self:GetStock(merchant, itemName) or 0

        if stock <= 0 then
            continue
        end

        for i = 1, stock do
            Core.GameEvents.BuyEventShopStock:FireServer(itemName, merchant)
        end
    end
end

function m:StartAutoBuyCreepyCritters()
    if not Window:GetConfigValue("AutoBuyCreepyShop") then
        return
    end

    local merchant = "Creepy Critters"
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or ""
    local shopPetTeam = Window:GetConfigValue("ShopPetTeam") or ""
    local itemNames = Window:GetConfigValue("CreepyShopItem")
    local petItems = {}
    if not itemNames or #itemNames == 0 then
        warn("No items selected for auto-buy")
        return
    end

    for _, itemName in ipairs(itemNames) do
        local stock = self:GetStock(merchant, itemName) or 0

        if stock <= 0 then
            continue
        end

        local itemDetail = self:GetDetailItem(itemName)
        if itemDetail and itemDetail.ItemType == "Pet" and shopPetTeam ~= "" and corePetTeam ~= "" then
            petItems[itemName] = stock
            continue
        end

        for i = 1, stock do
            Core.GameEvents.BuyEventShopStock:FireServer(itemName, merchant)
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
        for i = 1, stock do
            Core.GameEvents.BuyEventShopStock:FireServer(itemName, merchant)
        end
    end
    PetModule:ChangeTeamPets(corePetTeam, "core")
end

function m:StartAutoBuyDevilishDecor()
    if not Window:GetConfigValue("AutoBuyDevilishShop") then
        return
    end

    local merchant = "Devilish Decor"
    local itemNames = Window:GetConfigValue("DevilishShopItem")
    if not itemNames or #itemNames == 0 then
        warn("No items selected for auto-buy")
        return
    end

    for _, itemName in ipairs(itemNames) do
        local stock = self:GetStock(merchant, itemName) or 0

        if stock <= 0 then
            continue
        end

        for i = 1, stock do
            Core.GameEvents.BuyEventShopStock:FireServer(itemName, merchant)
        end
    end
end

return m