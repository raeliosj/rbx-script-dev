local m = {}

local Window
local Core

local Replion
local MarketItemData
local ItemUtility
local TierUtility
local PlayerStatsUtility
local InventoryMapping
local Net

local ReplionMerchant
local ReplionData

function m:Init(_window, _core)
    Window = _window
    Core = _core

    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
    MarketItemData = require(Core.ReplicatedStorage.Shared.MarketItemData)
    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    InventoryMapping = require(Core.ReplicatedStorage.Shared.InventoryMapping)
    PlayerStatsUtility = require(Core.ReplicatedStorage.Shared.PlayerStatsUtility)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    Net = require(Core.ReplicatedStorage.Packages.Net)

    ReplionMerchant = Replion.Client:WaitReplion("Merchant")
    ReplionData = Replion.Client:WaitReplion("Data")
end

function m:GetMarketDataFromId(itemId)
    for _, itemInfo in pairs(MarketItemData or {}) do
        if not itemInfo then
            continue
        end

        if itemInfo.Id == itemId then
            return itemInfo
        end
    end

    return nil
end

function m:OwnsLocalItem(itemData)
    if not itemData then
        return false
    end
    return PlayerStatsUtility:GetItemFromInventory(ReplionData, function(invItem)
        return invItem.Id == itemData.Data.Id
    end, InventoryMapping[itemData.Type or "Items"]) and true or false
end

function m:GetListItems()
    local items = ReplionMerchant:GetExpect("Items") or {}
    local listItems = {}

    for _, itemId in ipairs(items) do
        local itemInfo = self:GetMarketDataFromId(itemId)
        if not itemInfo then
            continue
        end

        print("Traveling Merchant Item:", itemInfo.Type, itemInfo.Identifier)
        local itemData = ItemUtility.GetItemDataFromItemType(itemInfo.Type, itemInfo.Identifier)
        if not itemData then
            warn("Item data not found for:", itemInfo.Type, itemInfo.Identifier)
            continue
        end
        local tierIndex = itemData and itemData.Data and itemData.Data.Tier or 1
        local tierDetail = TierUtility:GetTier(tierIndex) or TierUtility:GetTierFromRarity(0)
        local isOwned = self:OwnsLocalItem(itemData)

        table.insert(listItems, {
            Id = itemId,
            Name = itemData.Data.Name or "Unknown",
            Price = itemInfo.Price or 0,
            Rarity = tierDetail.Name or "Unknown",
            RarityIndex = tierIndex,
            IsOwned = isOwned,
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

function m:PurchaseItem(id)
    local success, response = Net:RemoteFunction("PurchaseMarketItem"):InvokeServer(id)

    return success, response
end

return m