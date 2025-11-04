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

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoEnchant2")
        end,
        function()
            self:StartAutoEnchant2()
        end
    )
end

function m:ListInventoryEnchantStones(name)
    local inventory = DataReplion:GetExpect({ "Inventory" })
    local items = inventory and inventory["Items"] or {}
    local enchantStones = {}

    if not items then
        warn("No items found in inventory.")
        return enchantStones
    end

    for _, item in pairs(items) do
        local itemData = ItemUtility.GetItemDataFromItemType("Enchant Stones", item.Id)
        if not itemData or not itemData.Data then
            warn("Item data not found for item ID:", item.Id)
            continue
        end

        
        if itemData.Data.Type ~= "Enchant Stones" then
            continue
        end

        if name and itemData.Data.Name ~= name then
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

function m:EquipEnchantStone(unequipItemUUID, name)
    local enchantStones = self:ListInventoryEnchantStones(name)
    if #enchantStones == 0 then
        return false
    end

    Net:RemoteEvent("UnequipItem"):FireServer(unequipItemUUID)
    task.wait(0.15)
    Net:RemoteEvent("EquipItem"):FireServer(enchantStones[1].UUID, enchantStones[1].Type)
    
    return true
end

function m:GetCurrentRodDetails()
    local equippedItem = DataReplion:GetExpect("EquippedItems")
    local inventoryItem = PlayerStatsUtility:GetItemFromInventory(DataReplion, function(item)
        return item.UUID == equippedItem[1]
    end)
    
    if not inventoryItem then
        Window:ShowWarning("No item equipped in the first slot.")
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

    local enchant1 = "None"
    local enchant2 = "None"

    for k, v in pairs(inventoryItem.Metadata or {}) do
        local enchantData = ItemUtility:GetEnchantData(v)

        if k == "EnchantId" then
            enchant1 = enchantData.Data.Name
        elseif k == "EnchantId2" then
            enchant2 = enchantData.Data.Name
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
        Enchant1 = enchant1,
        Enchant2 = enchant2,
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

    local targetEnchant = Window:GetConfigValue("TargetEnchant1") or {}
    local currentRod = self:GetCurrentRodDetails()
    if not currentRod then
        Window:ShowWarning("No fishing rod equipped.")
        return
    end

    if table.find(targetEnchant, currentRod.Enchant1) then
        Window:ShowInfo("Enchant", "Target enchant already applied: " .. tostring(currentRod.Enchant1))
        return
    end

    local altarPosition = CFrame.new(3234.55444, -1302.85486, 1400.52197, 0.354458153, -3.30675043e-08, -0.935071886, -2.43329872e-08, 1, -4.45875159e-08, 0.935071886, 3.85574985e-08, 0.354458153)
    local currentPosition = Player:GetPosition().Position
    local flatCurrentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)
    local flatAltarPosition = Vector3.new(altarPosition.X, 0, altarPosition.Z)

    if (flatCurrentPosition - flatAltarPosition).Magnitude ~= 0 then
        Window:ShowInfo("Enchant", "Teleporting to enchanting altar...")
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

        if itemData.Data.Type == "Enchant Stones" then
            Window:ShowInfo("Enchant", "Found enchant stone on hotbar " .. tostring(k))
            hotBarIndex = k
            break
        end
    end

    if not hotBarIndex then
        if not self:EquipEnchantStone(equippedItem[#equippedItem], "Enchant Stone") then
            Window:ShowWarning("Enchant", "No enchant stones found in inventory.")
            return
        end
        
        if #equippedItem == 1 then
            hotBarIndex = 2
        else
            hotBarIndex = #equippedItem
        end
    end
    
    Net:RemoteEvent("EquipToolFromHotbar"):FireServer(hotBarIndex)
    wait(0.15)
    Net:RemoteEvent("ActivateEnchantingAltar"):FireServer()
    task.wait(1)
end

function m:GetListSecretFish()
    local inventory = DataReplion:GetExpect({ "Inventory" })
    local items = inventory and inventory["Items"] or {}
    local secretFish = {}

    if not items then
        return secretFish
    end

    for _, item in pairs(items) do
        local itemData = ItemUtility.GetItemDataFromItemType("Fish", item.Id)
        if not itemData or not itemData.Data then
            continue
        end
        
        if itemData.Data.Type ~= "Fish" then
            continue
        end

        if itemData.Data.Tier ~= 7 then
            continue
        end
        local mutations = {}

        for k, v in pairs(item.Metadata or {}) do
            if k == "Shiny" and v == true then
                table.insert(mutations, "Shiny")
            end
        end

        local mutationsString = #mutations > 0 and table.concat(mutations, ", ") or "None"
        local chance = itemData.Probability and itemData.Probability.Chance or 0
        local chanceString = Core:FormatChance(chance)

        table.insert(secretFish, {
            UUID = item.UUID,
            Id = item.Id,
            Name = itemData.Data.Name or "Unknown",
            Type = itemData.Data.Type or "Unknown",
            IsFavorite = item.Favorited or false,
            Weight = item.Metadata and item.Metadata.Weight or 0,
            Mutations = mutationsString,
            Chance = chanceString,
            ChanceValue = chance,
        })
    end

    table.sort(secretFish, function(a, b)
        return a.ChanceValue > b.ChanceValue or (a.ChanceValue == b.ChanceValue and a.Name < b.Name)
    end)

    return secretFish
end

function m:ConvertSecretFishToTranscendedStone(secretFishUUID)
    local equippedItem = DataReplion:GetExpect("EquippedItems")

    Net:RemoteEvent("UnequipItem"):FireServer(equippedItem[#equippedItem])
    task.wait(0.15)
    Net:RemoteEvent("EquipItem"):FireServer(secretFishUUID, "Fish")
    task.wait(0.15)
    local hotBarIndex = nil

    if #equippedItem == 1 then
        hotBarIndex = 2
    else
        hotBarIndex = #equippedItem
    end

    Net:RemoteEvent("EquipToolFromHotbar"):FireServer(hotBarIndex)
    wait(0.15)

    local res = Net:RemoteFunction("CreateTranscendedStone"):InvokeServer()
    
    if not res then
        Window:ShowWarning("Enchant", "Failed to convert secret fish to transcended stone.")
        return false
    end
    
    Window:ShowInfo("Enchant", "Converted secret fish to transcended stone." .. tostring(res))
    return true
end

function m:StartAutoEnchant2()
    if not Window:GetConfigValue("AutoEnchant2") then
        return
    end

    local targetEnchant = Window:GetConfigValue("TargetEnchant2") or {}
    local currentRod = self:GetCurrentRodDetails()
    if not currentRod then
        Window:ShowWarning("No fishing rod equipped.")
        return
    end

    if table.find(targetEnchant, currentRod.Enchant2) then
        Window:ShowInfo("Enchant", "Target enchant already applied: " .. tostring(currentRod.Enchant2))
        return
    end

    local altarPosition = CFrame.new(1480.79028, 127.624985, -594.058899, 0.978317201, 1.97698089e-08, 0.207112238, -2.4821631e-08, 1, 2.17931149e-08, -0.207112238, -2.64614428e-08, 0.978317201)
    local currentPosition = Player:GetPosition().Position
    local flatCurrentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)
    local flatAltarPosition = Vector3.new(altarPosition.X, 0, altarPosition.Z)

    if (flatCurrentPosition - flatAltarPosition).Magnitude ~= 0 then
        Window:ShowInfo("Enchant", "Teleporting to enchanting altar...")
        Player:TeleportToPosition(altarPosition)
        wait(1)
    end

    local equippedItem = DataReplion:GetExpect("EquippedItems")
    local hotBarIndex = nil

    if not self:EquipEnchantStone(equippedItem[#equippedItem], "Transcended Stone") then
        Window:ShowWarning("Enchant", "No transcended stones found in inventory.")
    else
        if #equippedItem == 1 then
            hotBarIndex = 2
        else
            hotBarIndex = #equippedItem
        end
    end

    local secretFish = Window:GetConfigValue("SecretFishForTranscendedStone") or {}

    if not hotBarIndex and not secretFish then
        Window:ShowWarning("Enchant", "No transcended stones and not secret fish selected.")
        return
    elseif not hotBarIndex and secretFish then
        for i, fishUUID in pairs(secretFish) do
            local res = self:ConvertSecretFishToTranscendedStone(fishUUID)
            if res then
                table.remove(secretFish, i)
                break
            end
        end
        Window:SetConfigValue("SecretFishForTranscendedStone", secretFish)
        return
    end

    Net:RemoteEvent("EquipToolFromHotbar"):FireServer(hotBarIndex)
    wait(0.15)
    Net:RemoteEvent("ActivateSecondEnchantingAltar"):FireServer()
    task.wait(1)
end

return m