local m = {}

local Core

function m:Init(_core)
    Core = _core
end

function m:ConnectToStock(item, buyFunction)
     task.wait(0.1)
    local mainFrame = item:FindFirstChild("Main_Frame")
    if not mainFrame then return end
    
    local stockText = mainFrame:FindFirstChild("Stock_Text")
    if not stockText then return end

    print("Connecting to stock changes for", item.Name)

    local connection = stockText:GetPropertyChangedSignal("Text"):Connect(function()
        print("Stock changed for", item.Name, "New stock:", stockText.Text)
        local stock = tonumber(stockText.Text:match("%d+"))
        if stock and stock > 0 then
            pcall(buyFunction)
        end
    end)

    return connection
end

function m:GetListItems(_shopUI)
    local shopUI = Core:GetPlayerGui():FindFirstChild(_shopUI)
    if not shopUI then
        warn("Shop UI not found")
        return nil
    end
    
    local Items = shopUI.Frame.ScrollingFrame:GetChildren()
    if not Items then
        warn("Item frame not found in Shop")
        return nil
    end

    local listItems = {}
    for _, item in pairs(Items) do
        if item:FindFirstChild("Main_Frame") then
            table.insert(listItems, item)
        end
    end

    return listItems
end

function m:GetItemDetail(_item)
    if not _item then
        warn("Invalid item")
        return nil
    end

    local mainFrame = _item:FindFirstChild("Main_Frame")
    if not mainFrame then
        warn("Main frame not found in item")
        return nil
    end

    local priceText = mainFrame:FindFirstChild("Price_Text")
    if not priceText then
        warn("Price text not found in item")
        return nil
    end

    local stockText = mainFrame:FindFirstChild("Stock_Text")
    if not stockText then
        warn("Stock text not found in item")
        return nil
    end

    local name = _item.Name
    local price = tonumber(priceText.Text:match("%d+"))
    local stock = tonumber(stockText.Text:match("%d+"))

    return {
        Name = name,
        Price = price,
        Stock = stock
    }
end

function m:GetUIItem(_shopUI, _itemName)
   local shopUI = Core:GetPlayerGui():FindFirstChild(_shopUI)
    if not shopUI then
        warn("Shop UI not found")
        return nil
    end

    local Item = shopUI:FindFirstChild(_itemName, true)
    if not Item then
        warn("Item frame not found in Shop")
        return nil
    end

    return Item
end

function m:GetAvailableItems(_shopUI)
    local availableItems = {}
    if not _shopUI then
        warn("Invalid shop UI")
        return availableItems
    end
    
    local shopUI = Core:GetPlayerGui():FindFirstChild(_shopUI)
    if not shopUI then
        warn("Shop UI not found")
        return availableItems
    end

    local items = shopUI.Frame.ScrollingFrame:GetChildren()
    if not items then
        warn("No items found in the shop UI")
        return availableItems
    end

    for _, Item in pairs(items) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+"))
        
        availableItems[Item.Name] = StockCount
    end

    return availableItems
end

return m