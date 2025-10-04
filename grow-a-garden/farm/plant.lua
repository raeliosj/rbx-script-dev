local m = {}
local Window
local Core
local Player
local Garden
local PlantsPhysical

function m:Init(_window, _core, _player, _garden)
    Window = _window
    Core = _core
    Player = _player
    Garden = _garden

    local myGarden = Garden:GetMyFarm()
    if not myGarden then
        warn("Failed to find player's garden")
        return
    end

    local important = myGarden:FindFirstChild("Important")
    PlantsPhysical = important:FindFirstChild("Plants_Physical")  

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
        table.insert(formattedSeeds, {
            seed = seedData.SeedName or seedName,
            plant = seedName,
            rarity = seedData.SeedRarity or "Unknown",
        })
    end
    
    -- Sort seeds alphabetically (ascending order) - Safe for all executors
    if #formattedSeeds > 0 then
        table.sort(formattedSeeds, function(a, b)
            if not a or not b or not a.plant or not b.plant then
                return false
            end
            return string.lower(tostring(a.plant)) < string.lower(tostring(b.plant))
        end)
    end
                
    return formattedSeeds
end

function m:PlantSeed(seedName, numToPlant)
    if not seedName or type(seedName) ~= "string" then
        warn("FarmUtils:PlantSeed - Invalid seed name")
        return false
    end

    if #PlantsPhysical:GetChildren() >= 800 then
        return false
    end

    local tool
    local toolQuantity = 0

    for _, t in next, Player:GetAllTools() do
        local toolType = t:GetAttribute("b")
        local toolSeed = t:GetAttribute("Seed")
        if toolType == "n" and toolSeed == seedName then
            tool = t
            toolQuantity = t:GetAttribute("Quantity") or 0
            break
        end
    end

    if toolQuantity < numToPlant then
        numToPlant = toolQuantity
    end
    
    if not tool then
        return false
    end

    local plantingPosition = Window:GetConfigValue("PlantingPosition") or "Random"
    local position = Garden:GetFarmRandomPosition()
    if plantingPosition == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif plantingPosition == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif plantingPosition == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif plantingPosition == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end
    if not position then
        warn("Failed to get farm position for planting")
        return false
    end

    local plantTask = function(numToPlant, seedName, position)
        for i = 1, numToPlant do
            if #PlantsPhysical:GetChildren() >= 800 then
                break
            end            
            Core.GameEvents.Plant_RE:FireServer(position, seedName)
            -- Small delay between planting actions
            task.wait(0.15)
        end
    end

    Player:AddToQueue(
        tool,       -- tool
        3,          -- priority (medium)
        function()
            plantTask(numToPlant, seedName, position)
        end
    )
end

function m:FindPlants(plantName)
    if not plantName or type(plantName) ~= "string" then
        warn("Invalid plant name")
        return nil
    end

    if not PlantsPhysical then
        warn("PlantsPhysical not found")
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

    -- Cache plant count once at the beginning
    if #PlantsPhysical:GetChildren() >= 800 then
        task.wait(30) -- Much longer wait when farm is full
        return
    end

    local plantsNeeded = false
    
    for _, seedName in pairs(seedsToPlant) do
        if #PlantsPhysical:GetChildren() >= 800 then
            break
        end
        local existingPlants = self:FindPlants(seedName) or {}
        local numExisting = #existingPlants
        local numToPlant = math.max(0, seedToPlantCount - numExisting)

        if numToPlant > 0 then
            self:PlantSeed(seedName, numToPlant)
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

    if wateringPosition == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif wateringPosition == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif wateringPosition == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif wateringPosition == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end
    
    for _, Tool in next, Player:GetAllTools() do
        local toolType = Tool:GetAttribute("b")
        if toolType == "o" then
            wateringCan = Tool
            break
        end
    end

    if not wateringCan then
        warn("No watering can found in inventory")
        return
    end

    if #self:GetAllGrowingPlants() < 1 then
        task.wait(10) -- Wait before checking again
        return
    end
    
    local tasks = Player:GetTaskByTool(wateringCan)
    if tasks and #tasks > 0 then
        task.wait(10)
        return
    end


    local wateringTask = function(position, each)
        local watered = 0
        
        for i = 1, each do
            local success = pcall(function()
                Core.GameEvents.Water_RE:FireServer(Vector3.new(position.X, 0, position.Z))
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
        if not self:EligibleToHarvest(plant) then
            table.insert(growingPlants, plant)
        end
    end

    return growingPlants
end

function m:IsMaxInventory()
    local character = Core.LocalPlayer
    local backpack = Core:GetBackpack()
    if not character or not backpack then
        warn("FarmUtils:IsMaxFruitInventory - Character or Backpack not found")
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

function m:StartAutoHarvesting()
    if Window:GetConfigValue("AutoHarvestPlants") ~= true then
        warn("Auto harvesting is disabled in config")
        return
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
    local maxHarvestPerCycle = 25 -- Limit harvests per cycle to reduce lag

    for _, plantName in pairs(plantsToHarvest) do
        if harvestedCount >= maxHarvestPerCycle then
            break
        end

        local plants = self:FindPlants(plantName) or {}
        local eligibleCount = 0
        
        -- Count eligible plants first (lighter operation)
        for _, plant in pairs(plants) do
            if self:EligibleToHarvest(plant) then
                eligibleCount = eligibleCount + 1
            end
        end

        -- Harvest with limits
        for _, plant in pairs(plants) do
            if self:IsMaxInventory() or harvestedCount >= maxHarvestPerCycle then
                break
            end

            if self:EligibleToHarvest(plant) then
                local success, err = pcall(function()
                    Core.GameEvents.Crops.Collect:FireServer({plant})
                end)

                if not success then
                    warn("Failed to harvest plant:", plant.Name, "Error:", err)
                end

                harvestedCount = harvestedCount + 1
                 -- Small delay between harvests
                task.wait(0.15) -- Small delay between harvests
            end
        end

        if self:IsMaxInventory() then
            break
        end
    end

    if harvestedCount > 0 then
        task.wait(8) -- Moderate wait after work
    else
        task.wait(15) -- Longer wait when nothing to do
    end
end


return m