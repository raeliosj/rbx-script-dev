local m = {}

local Window
local Core
local Plant
local Player

function m:Init(_window, _core, _plant, _player)
    Window = _window
    Core = _core
    Plant = _plant
    Player = _player

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

    local frame = UI:FindFirstChild("Frame")
    if not frame then
        warn("Frame not found in RebirthConfirmation UI")
        return nil
    end

    local rebirthSubmitTime = frame.Frame:FindFirstChild("AscensionTimer")

    local questDetail = frame.Display.RebirthDetails:FindFirstChild("RequiredItemTemplate")
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
    local isEligibleToSubmit = not rebirthSubmitTime.Visible
    local nextRebirthSubmitTime = 0
    if rebirthSubmitTime.Visible then
        local text = rebirthSubmitTime.Text
        local hours = tonumber(text:match("(%d+)h")) or 0
        local minutes = tonumber(text:match("(%d+)m")) or 0
        local seconds = tonumber(text:match("(%d+)s")) or 0
        local totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        nextRebirthSubmitTime = tick() + totalSeconds
    end
    
    return {
        Name = parsedName,
        Amount = parsedAmount,
        Mutations = parsedMutations,
        IsEligibleToSubmit = isEligibleToSubmit,
        NextRebirthSubmitTime = nextRebirthSubmitTime
    }
end

function m:IsQuestFruit(_fruit)
    local isEligible = false
    
    if not _fruit:IsA("Tool") then
        return isEligible
    end

    if _fruit:GetAttribute("b") ~= "j" then
        return isEligible
    end

    local quest = self:GetQuestDetail()
    if not quest then
        return isEligible
    end

    if _fruit:GetAttribute("f") ~= quest.Name then
        return isEligible
    end

    if not quest.Mutations or quest.Mutations == "" or quest.Mutations == "N/A" then
        return true
    end

    for attributeName, attributeValue in pairs(_fruit:GetAttributes()) do
        if attributeValue == true and attributeName == quest.Mutations then
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
    local quest = self:GetQuestDetail()
    if not quest or not quest.IsEligibleToSubmit then
        task.wait(quest.NextRebirthSubmitTime - tick() + 1)
    end

    local rebirthTask = function()
        Core.GameEvents.BuyRebirth:FireServer()

        wait(1)
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
        
        Plant:PlantSeed(quest.Name, quest.Amount - #plants, plantingPosition)
        return
    end

    local plantToHarvest = {}
    for _, plant in pairs(plants) do
        if #plantToHarvest >= quest.Amount then
            break
        end
        if plant.name ~= quest.Name then
            continue
        end

        -- Get mutation name from attributes (key with value = true)
        local plantDetail = Plant:GetPlantDetail(plant)
        if not plantDetail or #plantDetail.fruits == 0 then
            continue
        end
        for _, fruit in pairs(plantDetail.fruits) do
            if not fruit.isEligibleToHarvest then
                continue
            end

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
        return
    end

    -- Harvesting fruits
    local harvestedCount = 0
    for _, fruit in pairs(plantToHarvest) do
        if harvestedCount >= quest.Amount then
            break
        end

        local success = Plant:HarvestFruit(fruit)
        if success then
            harvestedCount = harvestedCount + 1
            task.wait(0.15) -- Small delay between harvests
        end
    end
end

return m