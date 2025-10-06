local m = {}

local Window
local Core
local Plant
local Player

m.AscensionItem = {
    Name = "N/A",
    Amount = 0,
    Mutations = "N/A"
}

function m:Init(_window, _core, _plant, _player)
    Window = _window
    Core = _core
    Plant = _plant
    Player = _player

    task.spawn(function()
        m.AscensionItem = self:GetQuestDetail()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoAscend")
    end, function()
        self:AutoSubmitQuest()
    end)
end

function m:GetQuestDetail()
    local UI = Core:GetPlayerGui():FindFirstChild("RebirthConfirmation")
    if not UI then
        warn("RebirthConfirmation UI not found")
        return nil
    end

    local questDetail = UI.Frame.Display.RebirthDetails:FindFirstChild("RequiredItemTemplate")
    if not questDetail then
        warn("RequiredItemTemplate not found")
        return nil
    end

    local itemName = questDetail:FindFirstChild("ItemName")
    if not itemName then
        warn("ItemName not found")
        return nil
    end

    local itemAmount = questDetail:FindFirstChild("ItemAmount")
    if not itemAmount then
        warn("ItemAmount not found")
        return nil
    end

    local itemMutations = questDetail:FindFirstChild("ItemMutations")
    if not itemMutations then
        warn("ItemMutations not found")
        return nil
    end

    -- Parse text with color tags
    local function parseText(text)
        if not text then return "" end
        -- Remove color tags like <font color="#6cb8ff">Frozen</font>
        return text:gsub('<font[^>]*>', ''):gsub('</font>', '')
    end
    
    local parsedName = itemName.Text
    local parsedAmount = tonumber(itemAmount.Text:match("%d+"))
    local parsedMutations = parseText(itemMutations.Text)

    m.AscensionItem = {
        Name = parsedName,
        Amount = parsedAmount,
        Mutations = parsedMutations
    }
    
    return {
        Name = parsedName,
        Amount = parsedAmount,
        Mutations = parsedMutations
    }
end

function m:IsQuestFruit(_fruit)
    local isEligible = false
    
    if not _fruit:IsA("Tool") then
        print("Not a tool:", _fruit.Name)
        return isEligible
    end

    if _fruit:GetAttribute("b") ~= "j" then
        print("Not a fruit (attribute b != j):", _fruit.Name, _fruit:GetAttribute("b"))
        return isEligible
    end

    if _fruit:GetAttribute("f") ~= self.AscensionItem.Name then
        print("Fruit name does not match quest:", _fruit:GetAttribute("f"), "vs", self.AscensionItem.Name)
        return isEligible
    end

    if not self.AscensionItem.Mutations or self.AscensionItem.Mutations == "" or self.AscensionItem.Mutations == "N/A" then
        print("No specific mutation required for quest, any fruit of this type is eligible.")
        return true
    end

    for attributeName, attributeValue in pairs(_fruit:GetAttributes()) do
        print("Fruit Attribute:", attributeName, attributeValue)
        if attributeValue == true and attributeName == self.AscensionItem.Mutations then
            isEligible = true
            break
        end
    end

    return isEligible
end

function m:GetAllOwnedFruitsQuest()
    local myFruits = {}

    for _, fruit in pairs(Core:GetBackpack():GetChildren()) do
        if self:IsQuestFruit(fruit) then
            table.insert(myFruits, fruit)
        end
    end

    return myFruits
end

function m:SubmitRebirth(fruit)
    local rebirthTask = function()
        Core.GameEvents.BuyRebirth:FireServer()

        wait(1)

        self.AscensionItem = self:GetQuestDetail()
    end

    Player:AddToQueue(fruit, 10, function()
        rebirthTask()
    end)
end

function m:AutoSubmitQuest()
    local quest = self:GetQuestDetail()
    if not quest then
        return
    end

    local ownedFruits = self:GetAllOwnedFruitsQuest()
    if ownedFruits and #ownedFruits >= quest.Amount then
        self:SubmitRebirth(ownedFruits[1])
    end

    local plants = Plant:FindPlants(quest.Name) or {}
    if not plants or #plants < quest.Amount then
        warn("Not enough plants found for quest:", quest.Name)

        local plantingPosition = Window:GetConfigValue("PlantingAscensionPosition") or "Random"
        
        print("Planting more seeds:", quest.Name, "to reach", quest.Amount, "positions:", plantingPosition)
        Plant:PlantSeed(quest.Name, quest.Amount - #plants, plantingPosition)
        return
    end

    local plantToHarvest = {}
    for _, plant in pairs(plants) do
        if #plantToHarvest >= quest.Amount then
            print("Collected enough plants to harvest for the quest.")
            break
        end
        if plant.name ~= quest.Name then
            print("Skipping plant due to name mismatch:", plant.name, "vs", quest.Name)
            continue
        end

        -- Get mutation name from attributes (key with value = true)
        local plantDetail = Plant:GetPlantDetail(plant)
        print("Checking plant:", plant.name)
        if not plantDetail or #plantDetail.fruits == 0 then
            continue
        end
        for _, fruit in pairs(plantDetail.fruits) do
            if not fruit.isEligibleToHarvest then
                continue
            end


            print("Found matching fruit:", fruit.name)
            print("Required mutation:", quest.Mutations)
            print("Fruit mutations:", table.concat(fruit.mutations, ", "))
            if not quest.Mutations or quest.Mutations == "" or quest.Mutations == "N/A" then
                table.insert(plantToHarvest, fruit.model)
                break
            end

            for _, mutation in pairs(fruit.mutations) do
                if mutation == quest.Mutations then
                    table.insert(plantToHarvest, fruit.model)
                    break
                end
            end
        end
    end

    if not plantToHarvest or #plantToHarvest == 0 then
        warn("No suitable plants found to submit for the quest.")
        return
    end

    -- Harvesting fruits
    local harvestedCount = 0
    for _, fruit in pairs(plantToHarvest) do
        if harvestedCount >= quest.Amount then
            break
        end

        print("Harvesting fruit:", fruit.Name)
        local success = Plant:HarvestFruit(fruit)
        if success then
            harvestedCount = harvestedCount + 1
            task.wait(0.15) -- Small delay between harvests
        end
    end
end

return m