local m = {}

local Window
local EggShop
local SeedShop
local GearShop
local EventShopUI
local SeasonPassShop
local TravelingShop

function m:Init(_window, _eggShop, _seedShop, _gearShop, _eventShopUI, _seasonPassShop, _travelingShop)
    Window = _window
    EggShop = _eggShop
    SeedShop = _seedShop
    GearShop = _gearShop
    EventShopUI = _eventShopUI
    SeasonPassShop = _seasonPassShop
    TravelingShop = _travelingShop
end

function m:CreateShopTab()
    local tab = Window:AddTab({
        Name = "Shop",
        Icon = "🛍️",
    })

    -- Seed Automation
    tab:AddToggle({
        Name = "Auto Buy Seeds 🌱",
        Default = false,
        Flag = "AutoBuySeeds",
        Callback = function(Value)
            if Value then
                SeedShop:BuyAllSeeds()
            end
        end,
    })

    -- Gear Automation
    tab:AddToggle({
        Name = "Auto Buy Gear 🛠️",
        Default = false,
        Flag = "AutoBuyGear",
        Callback = function(Value)
            if Value then
                GearShop:BuyAllGear()
            end
        end,
    })

    -- Egg Automation
    tab:AddToggle({
        Name = "Auto Buy Eggs 🥚",
        Default = false,
        Flag = "AutoBuyEggs",
        Callback = function(Value)
            if Value then
                EggShop:BuyAllEggs()
            end
        end,
    })

    tab:AddToggle({
        Name = "Auto Buy Traveling Items 🧳",
        Default = false,
        Flag = "AutoBuyTravelingMerchant",
        Callback = function(Value)
            if Value then
                TravelingShop:BuyAllTravelingItems()
            end
        end,
    })

    -- Season Pass Automation
    tab:AddToggle({
        Name = "Auto Buy Season Pass Items 🎟️",
        Default = false,
        Flag = "AutoBuySeasonPasses",
        Callback = function(Value)
            if Value then
                SeasonPassShop:BuyAllSeasonPassItems()
            end
        end,
    })
    
    -- Event Seed Stages Automation 
    EventShopUI:AddShopEventToggles(tab)
end

return m