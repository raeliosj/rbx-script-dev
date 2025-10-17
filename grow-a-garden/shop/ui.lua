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

    self:SeedShopSection(tab)
    self:GearShopSection(tab)
    self:EggShopSection(tab)
    self:SeasonPassShopSection(tab)
    self:PremiumShopSection(tab)
end

function m:SeedShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Seed Shop",
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
        Name = "Auto Buy Seeds",
        Default = false,
        Flag = "AutoBuySeeds",
        Callback = function(Value)
            if Value then
                SeedShop:StartAutoBuySeeds()
            end
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Daily Deals",
        Default = false,
        Flag = "AutoBuyDailyDeals",
        Callback = function(Value)
            if Value then
                SeedShop:StartAutoBuyDailyDeals()
            end
        end,
    })
end

function m:GearShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Gear Shop",
        Icon = "🛠️",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Gear to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Gear",
        MultiSelect = true,
        Flag = "IgnoreGearItems",
        OnInit =  function(api, optionsData)
            local items = GearShop:GetItemRepository()
            local itemNames = {}
            
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Gear",
        Default = false,
        Flag = "AutoBuyGear",
        Callback = function(Value)
            if Value then
                GearShop:StartAutoBuyGear()
            end
        end,
    })
end

function m:EggShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Egg Shop",
        Icon = "🥚",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Eggs to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Eggs",
        MultiSelect = true,
        Flag = "IgnoreEggItems",
        OnInit =  function(api, optionsData)
            local items = EggShop:GetItemRepository()
            local itemNames = {}
            
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Eggs",
        Default = false,
        Flag = "AutoBuyEggs",
        Callback = function(Value)
            if Value then
                EggShop:StartBuyEgg()
            end
        end,
    })
end

function m:SeasonPassShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Season Pass Shop",
        Icon = "🎟️",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Season Pass Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreSeasonPassItems",
        OnInit =  function(api, optionsData)
            local items = SeasonPassShop:GetItemRepository()
            local itemNames = {}
            
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Season Pass Items",
        Default = false,
        Flag = "AutoBuySeasonPasses",
        Callback = function(Value)
            if Value then
                SeasonPassShop:StartBuySeasonPassItems()
            end
        end,
    })
end

function m:PremiumShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Premium Shop",
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