local m = {}

local Window
local Core
local EggShop
local SeedShop
local GearShop
local SeasonPassShop
local TravelingShop
local PremiumShop

function m:Init(_window, _core, _eggShop, _seedShop, _gearShop, _seasonPassShop, _travelingShop, _premiumShop)
    Window = _window
    Core = _core
    EggShop = _eggShop
    SeedShop = _seedShop
    GearShop = _gearShop
    SeasonPassShop = _seasonPassShop
    TravelingShop = _travelingShop
    PremiumShop = _premiumShop
end

function m:CreateShopTab()
    local tab = Window:AddTab({
        Name = "Shop",
        Icon = "🛍️",
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

    self:SeedShopSection(tab)
    self:PremiumShopSection(tab)
end

function m:SeedShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Seed Shop 🌱",
        Icon = "🌱",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Seeds to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Seeds",
        MultiSelect = true,
        Flag = "IgnoreSeedItems",
        OnInit =  function(api, optionsData)
            local items = SeedShop:GetItemRepository()
            local itemNames = {}
            
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Seeds 🛒",
        Default = false,
        Flag = "AutoBuySeeds",
        Callback = function(Value)
            if Value then
                SeedShop:StartAutoBuySeeds()
            end
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Daily Deals 🛒",
        Default = false,
        Flag = "AutoBuyDailyDeals",
        Callback = function(Value)
            if Value then
                SeedShop:StartAutoBuyDailyDeals()
            end
        end,
    })
end

function m:PremiumShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Premium Shop ",
        Icon = "💎",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Item to Buy 🛒",
        Options = PremiumShop.ListOfItems,
        Placeholder = "Select Item",
        MultiSelect = false,
        Flag = "PremiumShopItem"
    })

    accordion:AddTextBox({
        Name = "Product ID (for custom item)",
        Default = "",
        Flag = "PremiumShopProductID",
        Placeholder = "example: 3322970897",
        MaxLength = 50,
        Buttons = {
            {
                Text = "Paste 📋",
                Variant = "primary", 
                Callback = function(text, textBox)
                    print("Pasting from clipboard...")
                    -- text.text = tostring(Core.ClipboardService:GetClipboard())
                end
            },
            {
                Text = "Clear ✖️",
                Variant = "destructive", 
                Callback = function(text, textBox)
                    text.text = ""
                end
            }
        }
    })

    accordion:AddButton({
        Name = "Purchase Item 🛒",
        Callback = function()
            PremiumShop:BuyItemWithRobux()
        end
    })
end

return m