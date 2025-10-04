local m = {}

local Window
local Core

function m:Init(_window, _core)
    Window = _window
    Core = _core

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuySeasonPasses")
    end, function()
        self:BuyAllSeasonPassItems()
    end)
end

function m:GetAvailableSeasonPassesItems()
    local availableItems = {}

    local shopUI = Core:GetPlayerGui():FindFirstChild("SeasonPassUI", true)
    if not shopUI then
        return availableItems
    end

    local items = shopUI.SeasonPassFrame.Main.Store.ScrollingFrame.Content:GetChildren()
    for _, Item in pairs(items) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+"))
        
        availableItems[Item.Name] = StockCount
    end

    return availableItems
end

function m:BuySeasonPassItem(itemName)
    if not itemName or itemName == "" then
        warn("Invalid item name")
        return
    end

    Core.GameEvents.SeasonPass.BuySeasonPassStock:FireServer(itemName)
end

function m:BuyAllSeasonPassItems()
    local items = self:GetAvailableSeasonPassesItems()

    for itemName, stock in pairs(items) do
        if stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuySeasonPassItem(itemName)
            task.wait(0.1) -- Small delay to avoid spamming
        end
    end
end

return m