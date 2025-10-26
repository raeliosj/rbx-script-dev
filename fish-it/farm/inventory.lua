local m = {}

local Window
local Core
local Webhook

local TierUtility
local ItemUtility
local Replion
local DataReplion
local Net

local FishCaughtConnection
local FishCount = 0

m.ListFish = {}

function m:Init(_window, _core, _webhook)
    Window = _window
    Core = _core
    Webhook = _webhook

    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    Net = require(Core.ReplicatedStorage.Packages.Net)

    DataReplion = Replion.Client:WaitReplion("Data")

    self.ListFish = self:ListFishItems()

    if Window:GetConfigValue("AutoSellFish") or Window:GetConfigValue("AutoFavoriteFish") then
		self:CreateConnections()
	end
end

function m:ListFishItems()
    local listFishs = {}
    local fishData = ItemUtility:GetFishes() or {}

    for fishName, fishInfo in pairs(fishData) do
        if not fishInfo.Data then
            continue
        end

        local tierIndex = fishInfo.Data.Tier or 100
        local tierDetail = TierUtility:GetTier(tierIndex)

        table.insert(listFishs, {
            Name = fishInfo.Data.Name or "Unknown",
            SellPrice = fishInfo.SellPrice or 0,
            Rarity = tierDetail and tierDetail.Name or "Unknown",
            RarityIndex = tierIndex,
        })
    end

    table.sort(listFishs, function(a, b)
        if a.RarityIndex == b.RarityIndex then
            return a.Name < b.Name
        else
            return a.RarityIndex < b.RarityIndex
        end
    end)

    return listFishs
end

function m:FindFishItemByName(fishName)
    for _, fishItem in pairs(self.ListFish) do
        if fishItem.Name == fishName then
            return fishItem
        end
    end

    return nil
end

function m:CreateConnections()
	if FishCaughtConnection then
		return
	end

	FishCaughtConnection = Net:RemoteEvent("ObtainedNewFishNotification").OnClientEvent:Connect(function(fishId, fishMetadata, fishInventoryItem)
        coroutine.wrap(function()
            self:InventoryController(fishId, fishMetadata, fishInventoryItem)
        end)()
	end)
end

function m:RemoveConnections()
	if FishCaughtConnection then
		FishCaughtConnection:Disconnect()
		FishCaughtConnection = nil
	end
end

function m:ListInventoryFishs()
    local inventory = DataReplion:GetExpect({ "Inventory" })
    local items = inventory and inventory["Items"] or {}
    local fishItems = {}

    for _, item in pairs(items) do
        local itemData = ItemUtility.GetItemDataFromItemType("Fishes", item.Id)
        if not item.Metadata then
            continue
        end

        if not itemData or not itemData.Data then
            continue
        end

        if  itemData.Data.Type ~= "Fishes" then
            continue
        end

        local tierIndex = itemData.Data.Tier or 100
        local tierDetail = TierUtility:GetTier(tierIndex)
        
        table.insert(fishItems, {
            UUID = item.UUID,
            Id = item.Id,
            Name = itemData.Data.Name or "Unknown",
            Favorited = item.Favorited or false,
            Metadata = item.Metadata or {},
            Type = itemData.Data.Type or "Unknown",
            Rarity = tierDetail and tierDetail.Name or "Unknown",
            RarityIndex = tierIndex,
        })
    end
    
    return fishItems
end

function m:InventoryController(fishId, fishMetadata, fishInventoryItem)
    if Window:GetConfigValue("EnableDiscordWebhook") then
        coroutine.wrap(function()
            Webhook:SendWebhook(fishId, fishMetadata)
        end)()
    end

    if Window:GetConfigValue("AutoFavoriteFish") then
        self:FavoriteFish(fishInventoryItem.InventoryItem)
    end
    
    if Window:GetConfigValue("AutoSellFish") then
        FishCount = FishCount + 1
        local autoSellThreshold = Window:GetConfigValue("AutoSellFishCount") or 50

        if FishCount <= autoSellThreshold then
            return
        end

        -- Count fish from inventory to ensure we have enough to sell
        local inventoryFishCount = 0
        for _, fishItem in pairs(self:ListInventoryFishs()) do
            if fishItem.Favorited then
                continue
            end

            inventoryFishCount = inventoryFishCount + 1
        end

        if inventoryFishCount < FishCount then
            FishCount = inventoryFishCount
            return
        end

        self:SellAllFish()
        FishCount = 0
    end
end

function m:FavoriteFish(fishInventoryItem)
    if not fishInventoryItem then
        return
    end
    local favoriteFishName = Window:GetConfigValue("FavoriteFishName") or {}
    local minRarityToFavorite = Window:GetConfigValue("FavoriteMinRarityFish") or 9999999999999999

    local fishData = ItemUtility.GetItemDataFromItemType("Fishes", fishInventoryItem.Id)
    if not fishData or not fishData.Data then
        warn("Inventory:FavoriteFish - Unable to find fish data for ID:", fishInventoryItem.Id)
        return
    end

    local fishName = fishData.Data.Name or "Unknown"
    local rarityIndex = fishData.Data.Tier or -999999999999

    if table.find(favoriteFishName, fishName) then
        self:FavoriteItemByUUID(fishInventoryItem.UUID)
        return
    end
    
    if rarityIndex > minRarityToFavorite then
        self:FavoriteItemByUUID(fishInventoryItem.UUID)
        return
    end

    return
end

function m:FavoriteItemByUUID(itemUUID)
    if not itemUUID then
        return
    end

    local success = Net:RemoteEvent("FavoriteItem"):FireServer(itemUUID)
    if success then
        print("Favorited item with UUID:", itemUUID)
    else
        warn("Failed to favorite item with UUID:", itemUUID)
    end
end

function m:SellAllFish()	
	local sellSuccess = Net:RemoteFunction("SellAllItems"):InvokeServer()
	if not sellSuccess then
		warn("Failed to sell all fish.")
	end
end

return m