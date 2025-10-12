local m = {}

local Window
local Quest
local Shop

function m:Init(_window, _quest, _shop)
    Window = _window
    Quest = _quest
    Shop = _shop


    local tab = Window:AddTab({
        Name = "Ghoul Event",
        Icon = "👻",
    })
    self:GhoulSection(tab)
    self:SeedShopSection(tab)
    self:CreepyCrittersSection(tab)
    self:DevilishDecorSection(tab)
end

function m:GhoulSection(tab)
    local eventAccordion = tab:AddAccordion({
        Title = "Ghoul Event",
        Icon = "👻",
        Default = false,
    })

    eventAccordion:AddToggle({
        Name = "Auto Submit Ghoul Quest Items 👻",
        Default = false,
        Flag = "AutoSubmitGhoulQuest",
        Callback = function(Value)
            if Value then
                Quest:StartAutoSubmitEventPlants()
            end
        end,
    })
end

function m:SeedShopSection(tab)
    local merchant = "Spooky Seeds"
    local accordion = tab:AddAccordion({
        Title = "Spooky Seeds Shop",
        Icon = "🎃",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Item to Buy 🛒",
        Options = {"loading ..."},
        Placeholder = "Select Item",
        MultiSelect = true,
        Flag = "SpookyShopItem",
        OnInit =  function(api, optionsData)
            local items = Shop:GetItemRepository(merchant)

            local itemNames = {}
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddButton({
        Name = "Debug",
        Callback = function()
            local itemNames = Window:GetConfigValue("SpookyShopItem")
            for _, itemName in ipairs(itemNames) do
                local itemDetails = Shop:GetDetailItem(merchant, itemName)
                print("Item Details for:", itemName)
                for key, value in pairs(itemDetails) do
                    if type(value) == "table" then
                        value = table.concat(value, ", ")
                    end
                    print(key, value)
                end
                local stock = Shop:GetStock(merchant, itemName)
                print("-----")

                print("Current Stock for", itemName, "is:", stock)
            end
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Spooky Shop Items 🛒",
        Default = false,
        Flag = "AutoBuySpookyShop",
        Callback = function(Value)
            if Value then
                Quest:StartAutoBuyEventItems()
            end
        end,
    })
end

function m:CreepyCrittersSection(tab)
    local merchant = "Creepy Critters"
    local accordion = tab:AddAccordion({
        Title = "Creepy Critters Shop",
        Icon = "🦇",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Item to Buy 🛒",
        Options = {"loading ..."},
        Placeholder = "Select Item",
        MultiSelect = true,
        Flag = "CreepyShopItem",
        OnInit =  function(api, optionsData)
            local items = Shop:GetItemRepository(merchant)

            local itemNames = {}
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddButton({
        Name = "Debug",
        Callback = function()
            local itemNames = Window:GetConfigValue("CreepyShopItem")
            for _, itemName in ipairs(itemNames) do
                local itemDetails = Shop:GetDetailItem(merchant, itemName)
                print("Item Details for:", itemName)
                for key, value in pairs(itemDetails) do
                    if type(value) == "table" then
                        value = table.concat(value, ", ")
                    end
                    print(key, value)
                end
                local stock = Shop:GetStock(merchant, itemName)
                print("-----")

                print("Current Stock for", itemName, "is:", stock)
            end
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Creepy Shop Items 🛒",
        Default = false,
        Flag = "AutoBuyCreepyShop",
        Callback = function(Value)
            if Value then
                Quest:StartAutoBuyEventItems()
            end
        end,
    })
end

function m:DevilishDecorSection(tab)
    local merchant = "Devilish Decor"
    local accordion = tab:AddAccordion({
        Title = "Devilish Decor Shop",
        Icon = "🕸️",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Item to Buy 🛒",
        Options = {"loading ..."},
        Placeholder = "Select Item",
        MultiSelect = true,
        Flag = "DevilishShopItem",
        OnInit =  function(api, optionsData)
            local items = Shop:GetItemRepository(merchant)

            local itemNames = {}
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end
    })

    accordion:AddButton({
        Name = "Debug",
        Callback = function()
            local itemNames = Window:GetConfigValue("DevilishShopItem")
            for _, itemName in ipairs(itemNames) do
                local itemDetails = Shop:GetDetailItem(merchant, itemName)
                print("Item Details for:", itemName)
                for key, value in pairs(itemDetails) do
                    if type(value) == "table" then
                        value = table.concat(value, ", ")
                    end

                    print(key, value)
                end
                local stock = Shop:GetStock(merchant, itemName)
                print("-----")

                print("Current Stock for", itemName, "is:", stock)
            end
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Devilish Shop Items 🛒",
        Default = false,
        Flag = "AutoBuyDevilishShop",
        Callback = function(Value)
            if Value then
                Quest:StartAutoBuyEventItems()
            end
        end,
    })
end

return m