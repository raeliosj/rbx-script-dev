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
        -- if not table.find(Constants.TradableItemTypes, itemType) then
        --     warning("Item type not tradable for item ID:")
        --     continue
        -- end

        -- if table.find(Constants.PaidTradableItemTypes, itemType) then
        --     warning("Item ID is in non-tradable list:")
        --     continue
        -- end

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
    print("Fetching inventory data...")
    local inventory = DataReplion:GetExpect({ "Inventory" })

    if not inventory or #inventory == 0 then
        warning("No inventory data found")
        return inventoryItems
    end

    print("Listing inventory items...")
    for _, v in pairs(inventory) do
        print("Processing item type:", _, "with", #v, "items")
        for _, items in pairs(v) do
            if not items.Id then
                warning("Item ID not found")
                continue
            end

            if not items.UUID then
                warning("Item UUID not found for item ID:", items.Id)
                continue
            end

            local itemData = self:FindItemById(items.Id)
            if not itemData then
                warning("Item data not found for item ID:", items.Id)
                continue
            end

            table.insert(inventoryItems, {
                UUID = items.UUID,
                Id = items.Id,
                Name = itemData.Name or "Unknown",
                Type = itemData.Type or "Unknown",
                Description = itemData.Description or "No Description",
                Rarity = itemData.Rarity or "Unknown",
                RarityIndex = itemData.RarityIndex or 100,
                Favorited = items.Favorited or false,
                Metadata = items.Metadata or {},
            })
        end
    end

    return inventoryItems
end

function m:StartAutoGive()
    print("Starting Auto Give Items...")
    if not Window:GetConfigValue("AutoGiveItems") then
        warn("Auto Give Items: Feature is disabled.")
        return
    end

    print("Preparing to start Auto Give Items...")
    local userId = Window:GetConfigValue("GiveToPlayer") or 0
    if userId == 0 then
        warn("Auto Give Items: No UserId specified to give items to.")
        return
    end

    print(string.format("Auto Give Items: Giving items to UserId: %d", userId))
    local itemName = Window:GetConfigValue("GiveItem") or {}
    local minRarity = Window:GetConfigValue("GiveMinRarityItems") or nil
    local dontGiveFavorite = Window:GetConfigValue("DontGiveFavoriteItems") or false
    
    if #itemName == 0 and not minRarity then
        warn("Auto Give Items: No items or minimum rarity specified to give.")
        return
    end

    --TODO: Bug fixing here (Proccess stop in here)
    print("Starting Auto Give Items...")
    local inventoryItems = self:GetListInventoryItems()
    local itemsToGive = {}

    print(string.format("Found %d tradable items in inventory.", #inventoryItems))
    for _, itemDetail in pairs(inventoryItems) do
        if dontGiveFavorite and itemDetail.Favorited then
            print(string.format("Skipping favorite item: %s", itemDetail.Name))
            continue
        end

        if table.find(itemName, itemDetail.Name) then
            print(string.format("Giving item by name: %s", itemDetail.Name))
            table.insert(itemsToGive, itemDetail)
            continue
        end

        if itemDetail.Type ~= "Fishes" then
            continue
        end

        if itemDetail.RarityIndex and minRarity and itemDetail.RarityIndex >= minRarity then
            print(string.format("Giving item by minimum rarity: %s", itemDetail.Name))
            table.insert(itemsToGive, itemDetail)
            continue
        end
    end

    print(string.format("Total items to give: %d", #itemsToGive))
    while Window:GetConfigValue("AutoGiveItems") and #itemsToGive > 0 do
        print(string.format("Giving item: %s (UUID: %s)", itemDetail.Name, itemDetail.UUID))
        local success, data = Net:RemoteFunction("InitiateTrade"):InvokeServer(
            userId,
            itemDetail.UUID
        )

        if success then
            local itemDetail = table.remove(itemsToGive, 1)

            print(string.format("Successfully gave item: %s", itemDetail.Name))
        else
            warn(string.format("Failed to give item: %s", itemDetail.Name))
        end

        if data then
            print("Server Response:", data)
        end

        task.wait(2)  -- Small delay to prevent spamming the server
    end
end

function m:AcceptTrade(itemType, itemData, sender)
    if Window:GetConfigValue("AutoGiveItems") then
        print("Auto Give Items is disabled. Ignoring trade response.")
        return false
    end
    print(string.format("Trade Response Received: ItemType=%s, ItemData=%s, Sender=%s", tostring(itemType), tostring(itemData), tostring(sender)))

    task.wait(1)
    PromptEvent:Fire(true)
    print("Trade Response Processed.")
    task.wait(1)

    return true
end

return m