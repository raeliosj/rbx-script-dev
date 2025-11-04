local m = {}

local Window
local Core

local ItemData
local ItemUtility
local TierUtility
local Replion
local DataReplion
local Net
local Promise
local RemoteAwaitTradeResponse
local PromptEvent
local Constants

m.TradeItems = {}

function m:Init(_window, _core)
    Window = _window
    Core = _core

    ItemData = require(Core.ReplicatedStorage.Items)
    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    Net = require(Core.ReplicatedStorage.Packages.Net)
    Promise = require(Core.ReplicatedStorage.Packages.Promise)
    Constants = require(Core.ReplicatedStorage.Shared.Constants)

    RemoteAwaitTradeResponse = Net:RemoteFunction("AwaitTradeResponse")

    DataReplion = Replion.Client:WaitReplion("Data")
    self.TradeItems = self:GetListItemsToTrade()
    
    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoGiveItems")
        end,
        function()
            self:StartAutoGive()
        end
    )

    PromptEvent = Instance.new("BindableEvent")
    RemoteAwaitTradeResponse.OnClientInvoke = function(itemType, itemData, sender)
        return self:AcceptTrade(itemType, itemData, sender)
    end
end

function m:GetListItemsToTrade()
    local listItems = {}

    for _, itemInfo in pairs(ItemData or {}) do
        local itemData = itemInfo.Data
        if not itemData then
            continue
        end

        local itemType = itemData.Type or "Unknown"
        if not table.find(Constants.TradableItemTypes, itemType) then
            continue
        end

        if table.find(Constants.PaidTradableItemTypes, itemType) then
            continue
        end

        local tierIndex = itemData.Tier or 100
        local tierDetail = TierUtility:GetTier(tierIndex)

        table.insert(listItems, {
            Id = itemData.Id,
            Name = itemData.Name or "Unknown",
            Type = itemType,
            Description = itemData.Description or "No Description",
            Rarity = tierDetail and tierDetail.Name or "Unknown",
            RarityIndex = tierIndex,
        })
    end

    table.sort(listItems, function(a, b)
        if a.RarityIndex == b.RarityIndex then
            return a.Name < b.Name
        else
            return a.RarityIndex < b.RarityIndex
        end
    end)

    return listItems
end

function m:FindItemById(itemId)
    for _, itemDetail in pairs(self.TradeItems) do
        if itemDetail.Id == itemId then
            return itemDetail
        end
    end
    return nil
end

function m:GetListInventoryItems()
    local inventoryItems = {}
    local inventory = DataReplion:GetExpect({ "Inventory" })
    local items = inventory and inventory["Items"] or {}

    for _, item in pairs(items) do
        if not item.Id then
            warn("Item ID not found")
            continue
        end

        if not item.UUID then
            warn("Item UUID not found for item ID:", item.Id)
            continue
        end

        local itemData = self:FindItemById(item.Id)
        if not itemData then
            warn("Item data not found for item ID:", item.Id)
            continue
        end

        table.insert(inventoryItems, {
            UUID = item.UUID,
            Id = item.Id,
            Name = itemData.Name or "Unknown",
            Type = itemData.Type or "Unknown",
            Description = itemData.Description or "No Description",
            Rarity = itemData.Rarity or "Unknown",
            RarityIndex = itemData.RarityIndex or 100,
            Favorited = item.Favorited or false,
            Metadata = item.Metadata or {},
        })
    end

    return inventoryItems
end

function m:StartAutoGive()
    if not Window:GetConfigValue("AutoGiveItems") then
        warn("Auto Give Items: Feature is disabled.")
        return
    end

    local userId = Window:GetConfigValue("GiveToPlayer") or 0
    if userId == 0 then
        Window:ShowWarning("Trade", "No UserId specified to give items to.")
        return
    end

    local itemName = Window:GetConfigValue("GiveItem") or {}
    local minRarity = Window:GetConfigValue("GiveMinRarityItems") or nil
    local dontGiveFavorite = Window:GetConfigValue("DontGiveFavoriteItems") or false
    
    if #itemName == 0 and not minRarity then
        Window:ShowWarning("Trade", "No items or minimum rarity specified to give.")
        return
    end

    local inventoryItems = self:GetListInventoryItems()
    local itemsToGive = {}

    print(string.format("Found %d tradable items in inventory.", #inventoryItems))
    for _, itemDetail in pairs(inventoryItems) do
        if dontGiveFavorite and itemDetail.Favorited then
            continue
        end

        if table.find(itemName, itemDetail.Name) then
            table.insert(itemsToGive, itemDetail)
            continue
        end

        if itemDetail.Type ~= "Fish" then
            continue
        end

        if itemDetail.RarityIndex and minRarity and itemDetail.RarityIndex >= minRarity then
            table.insert(itemsToGive, itemDetail)
            continue
        end
    end

    Window:ShowInfo("Trade", string.format("Preparing to give %d items to UserId: %d", #itemsToGive, userId))
    
    local currentIndex = 1
    local retryCount = 0
    local maxRetries = 3

    while Window:GetConfigValue("AutoGiveItems") and #itemsToGive > 0 do
        if currentIndex > #itemsToGive then
            break
        end
        
        if itemsToGive[currentIndex].UUID == nil then
            Window:ShowWarning("Trade", "Item UUID is nil, skipping item.")
            currentIndex = currentIndex + 1
            continue
        end

        local success, data = Net:RemoteFunction("InitiateTrade"):InvokeServer(
            userId,
            itemsToGive[currentIndex].UUID
        )

        if success then
            Window:ShowInfo("Trade", string.format("Successfully gave item: %s", itemsToGive[currentIndex].Name))
            currentIndex = currentIndex + 1
        else
            Window:ShowWarning("Trade", string.format("Failed to give item: %s", itemsToGive[currentIndex].Name))
            
            retryCount = retryCount + 1
            if retryCount >= maxRetries then
                Window:ShowWarning("Trade", "Max retries reached for current item, moving to next item.")
                currentIndex = currentIndex + 1
                retryCount = 0
            end
        end

        if data then
            Window:ShowInfo("Trade", string.format("Server Response: %s", data))
        end

        task.wait(4)  -- Small delay to prevent spamming the server
    end
end

function m:AcceptTrade(itemType, itemData, sender)
    if not Window:GetConfigValue("AutoAcceptTrades") then
        print("Auto Accept Trades is disabled. Ignoring trade response.")
        Window:ShowWarning("Trade", "Trade request received but Auto Accept Trades is disabled.")
        return false
    end
    Window:ShowInfo("Trade", string.format("Automatically accepting trade from %s for item type %s.", tostring(sender), tostring(itemType)))
    
    task.wait(1)
    PromptEvent:Fire(true)
    task.wait(1)

    return true
end

return m