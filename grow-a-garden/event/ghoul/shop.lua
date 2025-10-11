local m = {}

local Window
local Core
local Shop
local ShopUI = "EventShop_UI"

local SpookySeeds = {
    "Bloodred Mushroom",
    "Jack O Lantern",
    "Ghoul Root",
    "Chicken Feed",
    "Seer Vine",
    "Poison Apple",
}
local CreepyCritters = {
    "Spooky Egg",
    "Pumpin Rat",
    "Wolf",
    "Ghost Bear",
    "Reaper",
}
local DevillishDecor = {
    "Pumkin Crate",
    "Ghost Lantern",
    "Thombstones",
    "Casket",
    "Skull Chain",
}

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop
end

function m:BuyEventItem(itemName, shopName)
    if not itemName or itemName == "" then
        warn("Invalid event item name")
        return
    end

    if not shopName or shopName == "" then
        warn("Invalid shop name")
        return
    end

    Core.GameEvents.BuyEventShopStock:FireServer(itemName, shopName)
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