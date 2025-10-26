local m = {}

local Window
local Core
local Player

local Net
local Replion
local PlayerStatsUtility 
local ItemUtility
local TierUtility

local DataReplion

function m:Init(_window, _core, _player)
    Window = _window
    Core = _core
    Player = _player

    Net = require(Core.ReplicatedStorage.Packages.Net)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    PlayerStatsUtility = require(Core.ReplicatedStorage.Shared.PlayerStatsUtility)
    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    
    DataReplion = Replion.Client:WaitReplion("Data")

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoEnchant1")
        end,
        function()
            self:StartAutoEnchant1()
        end
    )
end

function m:ListInventoryEnchantStones()
    local inventory = DataReplion:GetExpect({ "Inventory" })
    local items = inventory and inventory["Items"] or {}
    local enchantStones = {}

    if not items then
        return enchantStones
    end

    for _, item in pairs(items) do
        local itemData = ItemUtility.GetItemDataFromItemType("EnchantStones", item.Id)
        if not itemData or not itemData.Data then
            continue
        end
        
        if itemData.Data.Type ~= "EnchantStones" then
            continue
        end

        table.insert(enchantStones, {
            UUID = item.UUID,
            Id = item.Id,
            Name = itemData.Data.Name or "Unknown",
            Type = itemData.Data.Type or "Unknown",
        })
    end

    return enchantStones
end

function m:EquipEnchantStone(unequipItemUUID)
    local enchantStones = self:ListInventoryEnchantStones()
    if #enchantStones == 0 then
        warning("No enchant stones found in inventory.")
        return
    end

    Net:RemoteEvent("UnequipItem"):FireServer(unequipItemUUID)
    task.wait(0.15)
    Net:RemoteEvent("EquipItem"):FireServer(enchantStones[1].UUID, enchantStones[1].Type)
end

function m:GetCurrentRodDetails()
    local equippedItem = DataReplion:GetExpect("EquippedItems")
    local inventoryItem = PlayerStatsUtility:GetItemFromInventory(DataReplion, function(item)
        return item.UUID == equippedItem[1]
    end)
    
    if not inventoryItem then
        warning("No item equipped in the first slot.")
        return nil
    end

    local inventory = DataReplion:GetExpect({ "Inventory" })
    local inventoryFisihingRods = inventory["Fishing Rods"] or {}
    local metadata = nil
    for _, item in pairs(inventoryFisihingRods) do
        if item.UUID == inventoryItem.UUID then
            metadata = item.Metadata
            break
        end
    end

    local enchants = {}
    if metadata ~= nil then
        for _, v in {metadata.EnchantId, metadata.EnchantId2} do
            local enchantData = ItemUtility:GetEnchantData(v)
            if enchantData then
                table.insert(enchants, enchantData.Data.Name)
            end
        end
    end

    local equippedItemData = ItemUtility.GetItemDataFromItemType("Fishing Rods", inventoryItem.Id)
    local tierIndex = equippedItemData.Data.Tier or 100
    local tierDetail = TierUtility:GetTier(tierIndex)
    return {
        UUID = inventoryItem.UUID,
        Id = inventoryItem.Id,
        Name = equippedItemData.Data.Name or "Unknown",
        Tier = tierDetail.Name or "Unknown",
        TierIndex = tierIndex,
        Power = equippedItemData.ClickPower or 0,
        MaxWeight = equippedItemData.MaxWeight or 0,
        Resilience = equippedItemData.Resilience or 0,
        Luck = equippedItemData.Data.BaseLuck or 0,
        Enchants = enchants,
    }
end

function m:GetListEnchant()
    local enchantList = {}
    local enchantData = require(Core.ReplicatedStorage.Enchants)

    for _, v in pairs(enchantData) do
        table.insert(enchantList,  v.Data.Name)
    end
    
    table.sort(enchantList)

    return enchantList
end

function m:StartAutoEnchant1()
    if not Window:GetConfigValue("AutoEnchant1") then
        return
    end

    local targetEnchant = Window:GetConfigValue("TargetEnchant1")
    local currentRod = self:GetCurrentRodDetails()
    if not currentRod then
        warning("No fishing rod equipped.")
        return
    end

    if table.find(currentRod.Enchants, targetEnchant) then
        print("Target enchant already applied to the current rod.")
        return
    end

    local altarPosition = CFrame.new(3234.55444, -1302.85486, 1400.52197, 0.354458153, -3.30675043e-08, -0.935071886, -2.43329872e-08, 1, -4.45875159e-08, 0.935071886, 3.85574985e-08, 0.354458153)
    local currentPosition = Player:GetPosition().Position
    local flatCurrentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)
    local flatAltarPosition = Vector3.new(altarPosition.X, 0, altarPosition.Z)

    if (flatCurrentPosition - flatAltarPosition).Magnitude ~= 0 then
        Player:TeleportToPosition(altarPosition)
        wait(1)
    end

    local equippedItem = DataReplion:GetExpect("EquippedItems")
    local hotBarIndex = nil
    for k, v in pairs(equippedItem) do
        local inventoryItem = PlayerStatsUtility:GetItemFromInventory(DataReplion, function(item)
            return item.UUID == v
        end)

        if not inventoryItem then
            continue
        end

        local itemData = ItemUtility:GetItemData(inventoryItem.Id)

        print("Item Type: " .. tostring(itemData.Data.Type))
        if itemData.Data.Type == "EnchantStones" then
            hotBarIndex = k
            break
        end
    end

    if not hotBarIndex then
        self:EquipEnchantStone(equippedItem[#equippedItem])
        hotBarIndex = #equippedItem
    end

    Net:RemoteEvent("EquipToolFromHotbar"):FireServer(hotBarIndex)
    wait(0.15)
    Net:RemoteEvent("ActivateEnchantingAltar"):FireServer()
end

return m