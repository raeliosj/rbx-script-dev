local m = {}
local Window
local Core
local Player
local Garden
local PlantsPhysical
local ObjectsPhysical
local Rarity

function m:Init(_window, _core, _player, _garden, _rarity)
    Window = _window
    Core = _core
    Player = _player
    Garden = _garden
    Rarity = _rarity

    local myGarden = Garden:GetMyFarm()
    if not myGarden then
        warn("Failed to find player's garden")
        return
    end

    local important = myGarden:FindFirstChild("Important")
    PlantsPhysical = important:FindFirstChild("Plants_Physical")  
    ObjectsPhysical = important:FindFirstChild("Objects_Physical")

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoPlantSeeds")
    end, function()
        self:StartAutoPlanting()
    end)

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoWateringPlants")
    end, function()
        self:AutoWateringPlants()
    end)

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoHarvestPlants")
    end, function()
        self:StartAutoHarvesting()
    end)

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoPlaceSprinklers")
    end, function()
        self:AutoPlaceSprinklers()
    end)
end

function m:GetPlantRegistry()
    local success, seedRegistry = pcall(function()
        return require(Core.ReplicatedStorage.Data.SeedData)
    end)

    if not success then
        warn("Failed to get seed registry:", seedRegistry)
        return {}
    end

    if not seedRegistry then
        warn("SeedData is nil or not found")
        return {}
    end

   -- Convert SeedData to UI format {text = ..., value = ...}
    local formattedSeeds = {}
    for seedName, seedData in pairs(seedRegistry) do
        local plantTypes = self:FindPlantTypeByName(seedName)

        table.insert(formattedSeeds, {
            seed = seedData.SeedName or seedName,
            plant = seedName,
            rarity = seedData.SeedRarity or "Unknown",
            types = plantTypes and table.concat(plantTypes, ", ") or "Unknown",
        })
    end
    
    -- Sort seeds alphabetically (ascending order) - Safe for all executors
    if #formattedSeeds > 0 then
        table.sort(formattedSeeds, function(a, b)
            local rarityA = Rarity.RarityOrder[a.rarity] or 99
            local rarityB = Rarity.RarityOrder[b.rarity] or 99

            if rarityA == rarityB then
                return a.plant < b.plant
            end

            return rarityA < rarityB
        end)
    end
                
    return formattedSeeds
end

function m:FindPlantRegistryByName(plantName)
    local plants = self:GetPlantRegistry()
    for _, plantData in pairs(plants) do
        if plantData.plant == plantName then
            return plantData
        end
    end

    return nil
end

function m:FindPlantRegistryByName(plantName)
    local plants = self:GetPlantRegistry()
    for _, plantData in pairs(plants) do
        if plantData.plant == plantName then
            return plantData
        end
    end

    return nil
end

function m:FindPlantTypeByName(plantName)
    local plantsData = require(Core.ReplicatedStorage.Modules.PlantTraitsData)
    local plantTraits = plantsData.Traits or {}
    local listPlantType = {}

    for plantType, plants in pairs(plantTraits) do
        for _, plant in ipairs(plants) do
            if plant == plantName then
                table.insert(listPlantType, plantType)
                break
            end
        end
    end

    return listPlantType
end

function m:GetListSeedsAtInventory()
    local seedList = {}
    for _, tool in pairs(Player:GetAllTools()) do
        local toolType = tool:GetAttribute("b")
        if toolType == "n" then
            local seedName = tool:GetAttribute("Seed") or ""
            local seedQty = tool:GetAttribute("Quantity") or 0
            local seedData = self:FindPlantRegistryByName(seedName)
            local plantTypes = self:FindPlantTypeByName(seedName)

            table.insert(seedList, {
                seed = seedData and seedData.seed or "Unknown",
                plant = seedData and seedData.plant or seedName,
                quantity = seedQty,
                rarity = seedData and seedData.rarity or "Unknown",
                types = plantTypes and table.concat(plantTypes, ", ") or "Unknown",
            })
        end
    end

    -- Sort seeds by rarity and then alphabetically
    if #seedList > 0 then
        table.sort(seedList, function(a, b)
            local rarityA = Rarity.RarityOrder[a.rarity] or 99
            local rarityB = Rarity.RarityOrder[b.rarity] or 99

            if rarityA == rarityB then
                return a.plant < b.plant
            end

            return rarityA < rarityB
        end)
    end

    return seedList
end

function m:PlantSeed(_seedName, _numToPlant, _plantingPosition)
    if not _seedName or type(_seedName) ~= "string" then
        Window:ShowWarning("Auto Planting", "Invalid seed name")
        return false
    end

    if #PlantsPhysical:GetChildren() >= 800 then
        Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
        return false
    end

    local tool
    local toolQuantity = 0

    for _, t in next, Player:GetAllTools() do
        local toolType = t:GetAttribute("b")
        local toolSeed = t:GetAttribute("Seed")
        if toolType == "n" and toolSeed == _seedName then
            tool = t
            toolQuantity = t:GetAttribute("Quantity") or 0
            break
        end
    end

    if toolQuantity < _numToPlant then
        _numToPlant = toolQuantity
    end
    
    if not tool then
        Window:ShowWarning("Auto Planting", "No seed for: " .. _seedName)

        return false
    end
    
    local position = Garden:GetFarmRandomPosition()
    if _plantingPosition == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif _plantingPosition == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif _plantingPosition == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif _plantingPosition == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end
    if not position then
        Window:ShowWarning("Auto Planting", "Failed to get farm position for planting")
        return false
    end

    local plantTask = function(_numToPlant, _seedName, _position)
        for i = 1, _numToPlant do
            if #PlantsPhysical:GetChildren() >= 800 then
                Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
                break
            end            
            Core.ReplicatedStorage.GameEvents.Plant_RE:FireServer(_position, _seedName)
            -- Small delay between planting actions
            task.wait(0.15)
        end
    end

    Player:AddToQueue(
        tool,       -- tool
        3,          -- priority (medium)
        function()
            plantTask(_numToPlant, _seedName, position)
        end
    )
end

function m:FindPlants(plantName)
    if not plantName or type(plantName) ~= "string" then
        Window:ShowWarning("Planting", "Invalid plant name")
        return nil
    end

    if not PlantsPhysical then
        Window:ShowWarning("Planting", "PlantsPhysical not found")
        return nil
    end

    local foundPlants = {}
    for _, plant in pairs(PlantsPhysical:GetChildren()) do
        if plant.Name == plantName then
            table.insert(foundPlants, plant)
        end
    end

    return #foundPlants > 0 and foundPlants or nil
end

function m:StartAutoPlanting()
    local seedsToPlant = Window:GetConfigValue("SeedsToPlant") or {}
    local seedToPlantCount = Window:GetConfigValue("SeedsToPlantCount") or 1
    local plantingPosition = Window:GetConfigValue("PlantingPosition") or "Random"

    -- Cache plant count once at the beginning
    if #PlantsPhysical:GetChildren() >= 800 then
        Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
        task.wait(30) -- Much longer wait when farm is full
        return
    end

    local plantsNeeded = false
    
    for _, seedName in pairs(seedsToPlant) do
        if #PlantsPhysical:GetChildren() >= 800 then
            Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
            break
        end
        local existingPlants = self:FindPlants(seedName) or {}
        local numExisting = #existingPlants
        local numToPlant = math.max(0, seedToPlantCount - numExisting)

        Window:ShowInfo("Auto Planting", "Planting " .. tostring(numToPlant) .. " of " .. seedName)
        if numToPlant > 0 then
            self:PlantSeed(seedName, numToPlant, plantingPosition)
            plantsNeeded = true
        end
    end

    if not plantsNeeded then
        task.wait(60) -- Much longer wait when nothing to do
    else
        task.wait(15) -- Moderate wait when work was done
    end
end

function m:AutoWateringPlants()
    local wateringCan
    local wateringDelay = Window:GetConfigValue("WateringDelay") or 2
    local wateringEach = Window:GetConfigValue("WateringEach") or 5
    local wateringPosition = Window:GetConfigValue("WateringPosition") or "Front Right"
    local position = Garden:GetFarmRandomPosition()
    
    for _, Tool in next, Player:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        if toolType == "o" then
            wateringCan = Tool
            break
        end
    end

    if not wateringCan then
        Window:ShowWarning("Auto Watering", "No watering can found in inventory")
        return
    end

    local growingPlants = self:GetAllGrowingPlants()
    if #growingPlants < 1 then
        Window:ShowInfo("Auto Watering", "No growing plants found to water.")
        task.wait(10) -- Wait before checking again
        return
    end
    
    local tasks = Player:GetTaskByTool(wateringCan)
    if tasks and #tasks > 0 then
        task.wait(10)
        return
    end

    if wateringPosition == "Growing Plants" then
        position = growingPlants[1]:GetPivot().Position
    elseif wateringPosition == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif wateringPosition == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif wateringPosition == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif wateringPosition == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end

    local wateringTask = function(position, each)
        local watered = 0
        if wateringPosition == "Growing Plants" then
            Window:ShowInfo("Auto Watering", "Watering ".. tostring(#growingPlants) .. " growing plants. (" .. growingPlants[1].Name .. ")")
        else
            Window:ShowInfo("Auto Watering", "Watering " .. tostring(each) .. " times at position: " .. tostring(wateringPosition))
        end

        for i = 1, each do
            local success = pcall(function()
                Core.ReplicatedStorage.GameEvents.Water_RE:FireServer(Vector3.new(position.X, 0, position.Z))
            end)
            
            if success then
                watered = watered + 1
            end
            
            task.wait(1.5) -- Slightly longer delay to reduce server load
        end
        
        task.wait(0.5) -- Longer final wait
    end


    Player:AddToQueue(
        wateringCan,   -- tool
        99,             -- priority (very low)
        function()
            wateringTask(position, wateringEach)
        end
    )
    task.wait(math.max(wateringDelay, 5)) -- Minimum 5 second delay
end

function m:EligibleToHarvest(plant)    
    local Prompt = plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return false end
    if not Prompt.Enabled then return false end

    return true
end

function m:GetAllGrowingPlants()
    if not PlantsPhysical then
        warn("PlantsPhysical not found")
        return {}
    end

    local growingPlants = {}
    for _, plant in pairs(PlantsPhysical:GetChildren()) do
        local prompt = plant:FindFirstChild("ProximityPrompt", true)
        if not prompt then
            table.insert(growingPlants, plant)
        end
    end

    return growingPlants
end

function m:IsMaxInventory()
    local character = Core.LocalPlayer
    local backpack = Core:GetBackpack()
    if not character or not backpack then
        Window:ShowWarning("Inventory Check", "Character or Backpack not found")
        return false
    end

    local bonusBackpack = character:GetAttribute("BonusBackpackSize") or 0
    local maxCapacity = 200 + bonusBackpack
    local currentItems = 0

    for _, item in pairs(backpack:GetChildren()) do
        if item:GetAttribute("b") == "j" then
            currentItems = currentItems + 1
        end
    end

    return currentItems >= maxCapacity
end

function m:GetFruitPlant(plan)
    local fruits = {}
    
    for _, child in pairs(plan.Fruits:GetChildren()) do
        table.insert(fruits, child)
    end
    
    return fruits
end

function m:GetPlantDetail(_plant)
    if not _plant or not _plant:IsA("Model") then
        warn("Invalid plant")
        return nil
    end

    local prompt = _plant:FindFirstChild("ProximityPrompt", true)
    local parentFruit = prompt and prompt.Parent.Parent.Parent
    local fruits = {}

    if not prompt or not parentFruit then
        -- No prompt means not ready to harvest, so no fruits
        fruits = {}
    elseif parentFruit and parentFruit.Name == "Fruits" then
        for _, fruit in pairs(parentFruit:GetChildren()) do
            table.insert(fruits, fruit)
        end
    else
        fruits = { _plant }
    end

    local doneGrowTime = _plant:GetAttribute("DoneGrowTime") or math.huge

    local detail = {
        name = _plant.Name or "Unknown",
        position = _plant:GetPivot().Position or Vector3.new(0,0,0),
        isGrowing = not prompt or false,
        fruits = {},
    }

    for _, fruit in pairs(fruits) do
        local mutations = {}

        for attributeName, attributeValue in pairs(fruit:GetAttributes()) do
            if attributeValue == true then
                table.insert(mutations, attributeName)
            end
        end

        table.insert(detail.fruits, {
            isEligibleToHarvest = self:EligibleToHarvest(fruit),
            mutations = mutations,
            model = fruit,
        })
    end

    return detail
end

function m:HarvestFruit(_fruit)
    if not _fruit or not _fruit:IsA("Model") then
        warn("Invalid plant or fruit")
        return false
    end

    if not self:EligibleToHarvest(_fruit) then
        return false
    end

    if self:IsMaxInventory() then
        return false
    end

    local success, err = pcall(function()
        Core.ReplicatedStorage.GameEvents.Crops.Collect:FireServer({_fruit})
    end)

    if not success then
        warn("Failed to harvest item:", _fruit.Name, "Error:", err)
        return false
    end

    return true
end

function m:SellAllFruits()
    local lastPosition = Player:GetPosition()
    Player:TeleportToPosition(Core.Workspace.Tutorial_Points.Tutorial_Point_2.CFrame.Position)
    task.wait(0.5) -- Wait before checking again
    Core.ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
    task.wait(0.5) -- Wait before checking again
    Player:TeleportToPosition(lastPosition)
end

function m:StartAutoHarvesting()
    if Window:GetConfigValue("AutoHarvestPlants") ~= true then
        warn("Auto harvesting is disabled in config")
        return
    end

    if self:IsMaxInventory() and Window:GetConfigValue("AutoSellFruits") == true then
        self:SellAllFruits()
    end

    if self:IsMaxInventory() then
        task.wait(10) -- Wait before checking again
        return
    end

    local plantsToHarvest = Window:GetConfigValue("PlantsToHarvest") or {}
    if #plantsToHarvest == 0 then
        warn("No plants selected for auto harvesting")
        task.wait(10) -- Wait before checking again
        return
    end

    local harvestedCount = 0
    local shouldBreak = false

    for _, plantName in pairs(plantsToHarvest) do
        if shouldBreak then break end

        local plants = self:FindPlants(plantName) or {}

        -- Harvest with limits
        for _, plant in pairs(plants) do
            if shouldBreak then break end

            local plantDetail = self:GetPlantDetail(plant)
            if not plantDetail or plantDetail.isGrowing then
                continue
            end

            for _, fruitDetail in pairs(plantDetail.fruits) do
                if self:IsMaxInventory() then
                    shouldBreak = true
                    break
                end

                if not fruitDetail.isEligibleToHarvest then
                    continue
                end

                local success = self:HarvestFruit(fruitDetail.model)
                if success then
                    harvestedCount = harvestedCount + 1
                    task.wait(0.15) -- Small delay between harvests
                end
            end
        end
    end

    if harvestedCount > 0 then
        task.wait(0.5) -- Moderate wait after work
    else
        task.wait(15) -- Longer wait when nothing to do
    end
end

function m:MovePlant()
    local plantToMove = Window:GetConfigValue("PlantToMove")
    if not plantToMove or type(plantToMove) ~= "string" then
        Window:ShowWarning("Plant Mover", "No plant selected to move.")
        return
    end
    local moveDestination = Window:GetConfigValue("MoveDestination")
    if not moveDestination or type(moveDestination) ~= "string" then
        Window:ShowWarning("Plant Mover", "Invalid move destination selected.")
        return
    end

    local plants = self:FindPlants(plantToMove) or {}

    if #plants == 0 then
        Window:ShowWarning("Plant Mover", "No plants found to move.")
        return
    end

    local position = Garden:GetFarmRandomPosition()
    if moveDestination == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif moveDestination == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif moveDestination == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif moveDestination == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end
    if not position then
        Window:ShowWarning("Plant Mover", "Failed to get farm position for moving")
        return
    end

    local flatPosition = Vector3.new(position.X, 0, position.Z)

    local trowel
    for _, Tool in next, Player:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        if toolType == "b" then
            trowel = Tool
            break
        end
    end
    if not trowel then
        Window:ShowWarning("Plant Mover", "No trowel found in inventory")
        return
    end


    local moveTask = function(plants, position)
        for _, plant in pairs(plants) do
            if not plant or not plant:IsA("Model") then
                continue
            end

            local flatPlantPosition = Vector3.new(plant:GetPivot().Position.X, 0, plant:GetPivot().Position.Z)
            local magnitudePlant = (flatPlantPosition - flatPosition).Magnitude
            if magnitudePlant > -5 and magnitudePlant < 5 then
                continue
            end

            local success = pcall(function()
                Core.ReplicatedStorage.GameEvents.TrowelRemote:InvokeServer(
                    "Pickup",
                    trowel,
                    plant
                )
            end)

            if success then
                task.wait(0.5) -- Small delay between moves
            end

            local successPlace = pcall(function()
                Core.ReplicatedStorage.GameEvents.TrowelRemote:InvokeServer(
                    "Place",
                    trowel,
                    plant,
                    CFrame.new(position.X, 0.5, position.Z)
                )
            end)

            if not successPlace then
                Window:ShowWarning("Plant Mover", "Failed to place plant: " .. plant.Name)
            end
        end
    end

    Player:AddToQueue(
        trowel,     -- tool
        10,          -- priority (high)
        function()
            moveTask(plants, position)
        end
    )
end

function m:GetListGardenPlants()
    local plantList = {}
    if not PlantsPhysical then
        warn("PlantsPhysical not found")
        return plantList
    end

    for _, plant in pairs(PlantsPhysical:GetChildren()) do
        if not plantList[plant.Name] then
            plantList[plant.Name] = 1
        else
            plantList[plant.Name] = plantList[plant.Name] + 1
        end
    end

    local formattedPlantList = {}
    for plantName, count in pairs(plantList) do
        local plantData = self:FindPlantRegistryByName(plantName)
        table.insert(formattedPlantList, {
            plant = plantName,
            quantity = count,
            types = plantData.types or "Unknown",
            rarity = plantData and plantData.rarity or "Unknown",
            seed = plantData and plantData.seed or "Unknown",
        })
    end

    -- Sort plants by rarity and then alphabetically
    if #formattedPlantList > 0 then
        table.sort(formattedPlantList, function(a, b)
            local rarityA = Rarity.RarityOrder[a.rarity] or 99
            local rarityB = Rarity.RarityOrder[b.rarity] or 99
            if rarityA == rarityB then
                return a.plant < b.plant
            end
            return rarityA < rarityB
        end)
    end

    return formattedPlantList
end

function m:ShovelSelectedPlants()
    local plantToShovel = Window:GetConfigValue("PlantToShovel") or ""
    if not plantToShovel then
        Window:ShowWarning("Plant Shoveler", "No plants selected to shovel.")
        return
    end

    local shovel
    for _, Tool in next, Player:GetAllTools() do
        local uuid = Tool:GetAttribute("UUID")
        if uuid == "SHOVEL" then
            shovel = Tool
            break
        end
    end
    if not shovel then
        Window:ShowWarning("Plant Shoveler", "No shovel found in inventory")
        return
    end


    local shovelTask = function(plantToShovel)
        local maxPlantsToShovel = Window:GetConfigValue("PlantsToShovelCount") or 1
        local totalShoveled = 0

        local plants = self:FindPlants(plantToShovel) or {}
        if plants == 0 then
            Window:ShowWarning("Plant Shoveler", "No plants found to shovel.")
            return
        end

        Window:ShowInfo("Plant Shoveler", "Shoveling up to " .. tostring(maxPlantsToShovel) .. "/" .. tostring(#plants) .. " of " .. plantToShovel)

        for _, plant in pairs(plants) do
            if totalShoveled >= maxPlantsToShovel then
                Window:ShowInfo("Plant Shoveler", "Finished shoveling " .. tostring(totalShoveled) .. " plants of " .. plantToShovel)
                return
            end
            if not plant or not plant:IsA("Model") then
                continue
            end

            local success, result = pcall(function()
                local primaryPart = plant.PrimaryPart
                Core.ReplicatedStorage.GameEvents.Remove_Item:FireServer(plant[primaryPart.Name])
            end)

            if not success then
                Window:ShowWarning("Plant Shoveler", "Failed to shovel plant: " .. plant.Name .. " Error: " .. tostring(result))
                continue
            end
            task.wait(0.5) -- Small delay between shovels
            totalShoveled = totalShoveled + 1
        end
    end

    Player:AddToQueue(
        shovel,     -- tool
        20,          -- priority (medium-high)
        function()
            shovelTask(plantToShovel)
        end
    )
end

function m:ReclaimSelectedPlants()
    local plantToReclaim = Window:GetConfigValue("PlantToReclaim") or ""
    if not plantToReclaim then
        Window:ShowWarning("Plant Reclaimer", "No plants selected to reclaim.")
        return
    end

    local reclaimTool
    for _, tool in next, Player:GetAllTools() do
        if tool.Name:match("Reclaimer") then
            reclaimTool = tool
            break
        end
    end
    if not reclaimTool then
        Window:ShowWarning("Plant Reclaimer", "No reclaimer found in inventory")
        return
    end

    local reclaimTask = function(plantToReclaim)
        local plants = self:FindPlants(plantToReclaim) or {}

        if plants == 0 then
            Window:ShowWarning("Plant Reclaimer", "No plants found to reclaim.")
            return
        end
        
        Window:ShowInfo("Plant Reclaimer", "Reclaiming " .. tostring(#plants) .. " of " .. plantToReclaim)

        local maxPlantsToReclaim = Window:GetConfigValue("PlantsToReclaimCount") or 1
        local totalReclaimed = 0
        for _, plant in pairs(plants) do
            if totalReclaimed >= maxPlantsToReclaim then
                Window:ShowInfo("Plant Reclaimer", "Finished reclaiming " .. tostring(totalReclaimed) .. " plants of " .. plantToReclaim)
                return
            end

            if not plant or not plant:IsA("Model") then
                continue
            end

            local success, result = pcall(function()
                Core.ReplicatedStorage.GameEvents.ReclaimerService_RE:FireServer(
                    "TryReclaim",
                    plant
                )
            end)

            if not success then
                Window:ShowWarning("Plant Reclaimer", "Failed to reclaim plant: " .. plant.Name .. " Error: " .. tostring(result))
                continue
            end
            task.wait(0.5) -- Small delay between reclaims
            totalReclaimed = totalReclaimed + 1
        end
    end

    Player:AddToQueue(
        reclaimTool,
        20,         -- priority (low)
        function()
            reclaimTask(plantToReclaim)
        end
    )
end

function m:GetSprinklersRegistry()
    local sprinklers = {}
    local sprinklerData = require(Core.ReplicatedStorage.Data.SprinklerData)
    for sprinklerName, _ in pairs(sprinklerData.SprinklerDurations) do
        sprinklers[sprinklerName] = 0
    end

    for _, tool in next, Player:GetAllTools() do
        if tool:GetAttribute("b") ~= "d" then
            continue
        end

        local sprinklerName = tool:GetAttribute("f")
        if sprinklers[sprinklerName] then
            sprinklers[sprinklerName] = tool:GetAttribute("e") or 0
        end
    end

    local listSprinklers = {}
    for sprinklerName, quantity in pairs(sprinklers) do
        table.insert(listSprinklers, {
            name = sprinklerName,
            quantity = quantity,
        })
    end

    table.sort(listSprinklers, function(a, b)
        return a.name < b.name
    end)

    return listSprinklers
end

function m:AutoPlaceSprinklers()
    if not Window:GetConfigValue("AutoPlaceSprinklers") then
        return
    end

    local selectedSprinkler = Window:GetConfigValue("SprinklersToPlace") or {}
    if not selectedSprinkler then
        Window:ShowWarning("Auto Sprinkler", "No sprinkler type selected")
        return
    end

    local placedSprinklers = {}
    for _, obj in pairs(ObjectsPhysical:GetChildren()) do
        local lifetime = obj:GetAttribute("Lifetime") or 0
        if lifetime <= 0 then
            continue
        end
        placedSprinklers[obj.Name] = lifetime
    end

    local sprinklerNotPlaced = {}
    for _, sprinklerName in pairs(selectedSprinkler) do
        if not placedSprinklers[sprinklerName] then
            table.insert(sprinklerNotPlaced, sprinklerName)
        end
    end

    if #sprinklerNotPlaced == 0 then
        -- Get faster lifetime sprinkler to wait for
        local minLifetime = math.huge -- Initialize with a very large number
        for _, lifetime in pairs(placedSprinklers) do
            if lifetime < minLifetime then
                minLifetime = lifetime
            end
        end
        
        -- If no valid lifetime found, default to 30 seconds
        if minLifetime == math.huge then
            minLifetime = 30
        end
        
        Window:ShowInfo("Auto Sprinkler", "Waiting " .. tostring(math.floor(minLifetime)) .. "s for next sprinkler.")
        task.wait(minLifetime + 0.1) -- Wait a bit longer than the minimum lifetime
        return
    end

    local sprinkleTools = {}
    for _, tool in next, Player:GetAllTools() do
        if tool:GetAttribute("b") ~= "d" then
            continue
        end

        if table.find(sprinklerNotPlaced, tool:GetAttribute("f")) then
            table.insert(sprinkleTools, tool)
        end
    end
    
    if #sprinkleTools == 0 then
        Window:ShowWarning("Auto Sprinkler", "No sprinkler found in inventory")
        return
    end

    local selectedSprinklerPosition = Window:GetConfigValue("SprinklerPlacingPosition") or "Random"
    local position = Garden:GetFarmRandomPosition()
    if selectedSprinklerPosition == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif selectedSprinklerPosition == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif selectedSprinklerPosition == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif selectedSprinklerPosition == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end

    if not position then
        Window:ShowWarning("Auto Sprinkler", "Failed to get farm position for sprinkler")
        return
    end

    -- Generate a random rotation for natural placement
    local function getRandomCFrame(pos)
        local randomAngle = math.rad(math.random(0, 360))
        return CFrame.new(pos.X, 0.5, pos.Z) * CFrame.Angles(0, randomAngle, 0)
    end

    for _, tool in pairs(sprinkleTools) do
        local tasks = Player:GetTaskByTool(tool)
        if tasks and #tasks > 0 then
            continue
        end

        Player:AddToQueue(
            tool,
            20,         -- priority (low)
            function()
                local cframe = getRandomCFrame(position)
                Core.ReplicatedStorage.GameEvents.SprinklerService:FireServer(
                    "Create",
                    cframe
                )
                task.wait(0.5) -- Add delay between placements
            end)
    end
end

return m