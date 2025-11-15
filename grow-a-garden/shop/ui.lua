local m = {}

local Window
local Core
local EggShop
local SeedShop
local GearShop
local SeasonPassShop
local TravelingShop
local PremiumShop
local PetTeam
local Rarity
local CosmeticShop

function m:Init(_window, _core, _eggShop, _seedShop, _gearShop, _seasonPassShop, _travelingShop, _premiumShop, _petTeam, _rarity, _cosmeticShop)
    Window = _window
    Core = _core
    EggShop = _eggShop
    SeedShop = _seedShop
    GearShop = _gearShop
    SeasonPassShop = _seasonPassShop
    TravelingShop = _travelingShop
    PremiumShop = _premiumShop
    PetTeam = _petTeam
    Rarity = _rarity
    CosmeticShop = _cosmeticShop

    self:CreateShopTab()
end

function m:CreateShopTab()
    local tab = Window:AddTab({
        Name = "Shop",
        Icon = "🛍️",
    })

    tab:AddSelectBox({
        Name = "Pet Team to Use While Buying Pet Items",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "ShopPetTeam",
        OnInit = function(api, optionsData)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            optionsData.updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    tab:AddLabel("")
    tab:AddSeparator()

    self:SeedShopSection(tab)
    self:CosmeticShopSection(tab)
    self:GearShopSection(tab)
    self:EggShopSection(tab)
    self:TravelingMerchantSection(tab)
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
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.Seed.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.Seed.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)
            
            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text = "[" .. data.Seed.SeedRarity .. "] " .. data._name, value = data._name})
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

function m:CosmeticShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Cosmetic Shop",
        Icon = "🎨",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Cosmetic Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Cosmetic Items",
        MultiSelect = true,
        Flag = "IgnoreCosmeticItems",
        OnInit =  function(api, optionsData)
            local items = CosmeticShop:GetCosmeticItemRepository()
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                return a._name < b._name
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, data._name)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Crate Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Crate Items",
        MultiSelect = true,
        Flag = "IgnoreCrateItems",
        OnInit =  function(api, optionsData)
            local items = CosmeticShop:GetCrateItemRepository()
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                return a._name < b._name
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, data._name)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Fence Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Fence Items",
        MultiSelect = true,
        Flag = "IgnoreFenceItems",
        OnInit =  function(api, optionsData)
            local items = CosmeticShop:GetFenceItemRepository()

            optionsData.updateOptions(items)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Cosmetic Items",
        Default = false,
        Flag = "AutoBuyCosmeticItems",
        Callback = function(Value)
            if Value then
                CosmeticShop:StartAutoBuyCosmeticItems()
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
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.Gear.GearRarity] or 99
                local rarityB = Rarity.RarityOrder[b.Gear.GearRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a.Gear.GearName < b.Gear.GearName
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text = "[" .. data.Gear.GearRarity .. "] " .. data._name, value = data._name})
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
            local sortedList = {}
            local itemNames = {}

            for _, data in pairs(items) do
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.EggRarity] or 99
                local rarityB = Rarity.RarityOrder[b.EggRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a.EggName < b.EggName
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.EggRarity .. "] " .. data.EggName, value=data.EggName})
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

function m:TravelingMerchantSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Traveling Merchant Shop",
        Icon = "🧳",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select Fall Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreFallMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("FallMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Gnome Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreGnomeMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("GnomeMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Honey Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreHoneyMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("HoneyMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Sky Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreSkyMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("SkyMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Spray Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreSprayMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("SprayMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Sprinkler Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreSprinklerMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("SprinklerMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Summer Merchant Items to Ignore Buying",
        Options = {"loading ..."},
        Placeholder = "Select Items",
        MultiSelect = true,
        Flag = "IgnoreSummerMerchantItems",
        OnInit =  function(api, optionsData)
            local items = TravelingShop:GetItemRepository("SummerMerchant")
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
            end
            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Traveling Merchant Items",
        Default = false,
        Flag = "AutoBuyTravelingMerchant",
        Callback = function(Value)
            if Value then
                TravelingShop:StartBuyTravelingItems()
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
            local sortedList = {}
            local itemNames = {}

            for itemName, data in pairs(items) do
                data._name = itemName
                table.insert(sortedList, data)
            end

            table.sort(sortedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.Rarity] or 99
                local rarityB = Rarity.RarityOrder[b.Rarity] or 99

                if rarityA == rarityB then
                    if a.LayoutOrder == b.LayoutOrder then
                        return a._name < b._name
                    else
                        return a.LayoutOrder < b.LayoutOrder
                    end
                end

                return rarityA < rarityB
            end)

            for _, data in pairs(sortedList) do
                local rarity = data.Rarity or "Unknown"
                local name = data._name or "Unnamed"
                table.insert(itemNames, {text= "[" .. rarity .. "] " .. name, value=name})
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