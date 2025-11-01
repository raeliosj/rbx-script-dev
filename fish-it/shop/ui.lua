local m = {}

local Window
local Core
local TravelingMerchant

function m:Init(_window, _core, _travelingMerchant)
    Window = _window
    Core = _core
    TravelingMerchant = _travelingMerchant

    local tab = Window:AddTab({
        Name = "Shop",
        Icon = "🛒",
    })
    self:TravelingMerchantSection(tab)
end

function m:TravelingMerchantSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Traveling Merchant",
        Icon = "🚚",
        Default = false,
    })

    local selecteditem = accordion:AddSelectBox({
        Name = "Items",
        Options = {"loading ..."},
        Placeholder = "Select Items to Buy",
        MultiSelect = false,
        OnDropdownOpen =  function(currentOptions, updateOptions)
            local listItems = TravelingMerchant:GetListItems() or {}
            local formattedItems = {}

            for _, itemInfo in pairs(listItems) do
                table.insert(formattedItems, {text = string.format("[%s] %s - %s Coins %s", itemInfo.Rarity, itemInfo.Name, Core:FormatNumber(itemInfo.Price or 0), itemInfo.IsOwned and "(Owned)" or "(Not Owned)"), value = itemInfo.Id})
            end

            updateOptions(formattedItems)
        end
    })

    accordion:AddButton({
        Name = "Purchase Selected Item",
        Description = "Purchase the selected item from the Traveling Merchant.",
        Callback = function()
            local itemId = selecteditem:GetSelected()[1]
            if not itemId then
                Window:ShowError(
                    "Traveling Merchant",
                    "Please select an item to purchase.",
                    5000
                )
                return
            end

            local success, response = TravelingMerchant:PurchaseItem(itemId)
            if success then
                Window:ShowInfo(
                    "Traveling Merchant",
                    "Successfully purchased the item!",
                    5000
                )
            else
                Window:ShowWarning(
                    "Traveling Merchant",
                    "Failed to purchase the item: " .. tostring(response),
                    5000
                )
            end
        end
    })
end

return m