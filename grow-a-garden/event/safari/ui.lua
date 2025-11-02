local m = {}

local Window
local Core
local Quest
local Shop

function m:Init(_window, _core, _quest, _shop)
    Window = _window
    Core = _core
    Quest = _quest
    Shop = _shop

    local tab = Window:AddTab({
        Name = "Safari Event",
        Icon = "🐘",
    })

    self:SafariQuestSection(tab)
    self:ShopSection(tab)
end

function m:SafariQuestSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Safari Quest",
        Icon = "📜",
        Default = false,
    })

    accordion:AddLabel(function()
        return string.format("Current Quest Plant Type: %s", Quest:GetQuestPlantType())
    end)

    accordion:AddToggle({
        Name = "Auto Harvest Safari Quest Plants",
        Default = false,
        Flag = "AutoHarvestSafariQuest",
    })

    accordion:AddToggle({
        Name = "Auto Submit Safari Quest Plants",
        Default = false,
        Flag = "AutoSubmitSafariQuest",
        Callback = function(Value)
            if Value then
                Quest:StartAutoSubmitEventPlants()
            else
                Quest:StopAutoSubmitEventPlants()
            end
        end,
    })

    accordion:AddToggle({
        Name = "Sell All Fruits If Inventory Full",
        Default = false,
        Flag = "SafariSellFruitsIfInventoryFull",
    })
end

function m:ShopSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Safari Shop",
        Icon = "🛒",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Ignore Safari Merchant Items",
        Options = {"loading ..."},
        MultiSelect = true,
        Flag = "IgnoreSafariMerchantItems",
        OnInit = function(api, optionsData)
            local items = Shop:GetItemRepository("Safari Shop")

            local itemNames = {}
            for itemName, _ in pairs(items) do
                table.insert(itemNames, itemName)
            end

            optionsData.updateOptions(itemNames)
        end,
    })

    accordion:AddToggle({
        Name = "Auto Buy Safari Merchant Items",
        Default = false,
        Flag = "AutoBuySafariMerchant",
        Callback = function(Value)
            if Value then
                Shop:StartAutoBuySafariMerchant()
            end
        end,
    })
end

return m