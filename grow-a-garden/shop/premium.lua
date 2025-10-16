local m ={}

local Window
local Core

function m:Init(_window, _core)
    Window = _window
    Core = _core
end

m.ListOfItems = {
    { text = "[4th July Event 2025] Liberty Lily", value = 3322972631 },
    { text = "[4th July Event 2025] Firework Flower", value = 3322974839 },
    { text = "[4th July Event 2025] Firework", value = 3322978636 },
    { text = "[4th July Event 2025] Bald Eagle", value = 3322970897 },
    { text = "[4th July Event 2025] July 4th Crate", value = 3322970196 },
    { text = "[Halloween Event] Bloodred Mushroom", value = 3426534747 },
    { text = "[Halloween Event] Jack O Lantern", value = 3426535112 },
    { text = "[Halloween Event] Ghoul Root", value = 3426535875 },
    { text = "[Halloween Event] Chicken Feed", value = 3426536221 },
    { text = "[Halloween Event] Seer Vine", value = 3426536516 },
    { text = "[Halloween Event] Poison Apple", value = 3426537228 },
    { text = "[Halloween Event] Spooky Egg", value = 3426500875 },
    { text = "[Halloween Event] Pumpkin Rat", value = 3426530616 },
    { text = "[Halloween Event] Ghost Bear", value = 3426533454 },
    { text = "[Halloween Event] Wolf", value = 3426533989 },
    { text = "[Halloween Event] Reaper", value = 3426534351 },
    { text = "[Halloween Event] Pumpkin Crate", value = 3426537997 },
    { text = "[Halloween Event] Ghost Lantern", value = 3426539369 },
    { text = "[Halloween Event] Tombstones", value = 3426539598 },
    { text = "[Halloween Event] Casket", value = 3426540158 },
    { text = "[Halloween Event] Skull Chain", value = 3426540522 },
}

function m:BuyItemWithRobux()
    print("Attempting to purchase item from Premium Shop...")
    local premiumItem = Window:GetConfigValue("PremiumShopItem")
    local premiumProductID = tonumber(Window:GetConfigValue("PremiumShopProductID"))

    if not premiumProductID then
        premiumProductID = premiumItem
    end

    if not premiumItem then
        warn("Please select a valid item to purchase.")
        return
    end
    
    if not premiumProductID or premiumProductID <= 0 then
        warn("Please enter a valid Product ID.")
        return
    end
    
    Core.MarketplaceService:PromptProductPurchase(Core.LocalPlayer, premiumProductID)
end

return m