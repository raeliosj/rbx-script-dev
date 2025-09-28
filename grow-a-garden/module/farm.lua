local FarmUtils = {}
-- Load Core module with error handling
local Core
local PlayerUtils
local Window
local AutoHarvestThread
local AutoHarvesting = false

function FarmUtils:Init(core, playerUtils, windowInstance)
    if not core then
        error("FarmUtils:Init - Core module is required")
    end
    if not playerUtils then
        error("FarmUtils:Init - PlayerUtils module is required")
    end
    if not windowInstance then
        error("FarmUtils:Init - WindowInstance is required")
    end
    Core = core
    PlayerUtils = playerUtils
    Window = windowInstance

    local isEnabledAutoHarvest = Window:GetConfigValue("AutoHarvestPlants") or false
    print("AutoHarvestPlants is enabled:", isEnabledAutoHarvest)

    -- Connect to Backpack.ChildAdded to auto-submit event plants
    -- local backpack = Core:GetBackpack()
    -- if backpack then
    --     backpack.ChildAdded:Connect(function(child)
    --         if child and child:IsA("Tool") then
    --             if child:GetAttribute("b") == "j" and string.find(child.Name, "Evo") then
    --                 print("New event plant detected in backpack:", child.Name)
    --                 self:SubmitEventPlant(child)
    --             end
    --         end
    --     end)
    -- end

    -- -- Start Automation processes if enabled in config
    -- if isEnabledAutoHarvest then
    --     task.spawn(function()
    --         self:StartAutoHarvest()
    --     end)
    -- end
end

function FarmUtils:GetMyFarm()
	local Farms = Core.Workspace.Farm:GetChildren()

	for _, Farm in next, Farms do
    local Important = Farm.Important
    local Data = Important.Data
    local Owner = Data.Owner

		if Owner.Value == Core.LocalPlayer.Name then
			return Farm
		end
	end
    return
end

function FarmUtils:GetArea(Base: Part)
	local Center = Base:GetPivot()
	local Size = Base.Size

	-- Bottom left
	local X1 = math.ceil(Center.X - (Size.X/2))
	local Z1 = math.ceil(Center.Z - (Size.Z/2))

	-- Top right
	local X2 = math.floor(Center.X + (Size.X/2))
	local Z2 = math.floor(Center.Z + (Size.Z/2))

	return X1, Z1, X2, Z2
end

-- Get center CFrame point of the farm
function FarmUtils:GetFarmCenterCFrame()    
    local farm = FarmUtils:GetMyFarm()
    if not farm then
        warn("Farm not found for player:", Core.LocalPlayer.Name)
        return CFrame.new(0, 4, 0) -- Default position
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        warn("Important folder not found in farm")
        return CFrame.new(0, 4, 0) -- Default position
    end
    
    -- Try to find Plant_Locations first
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Calculate center from all farm parts
            local totalX, totalZ = 0, 0
            local totalY = 4 -- Default height for farm
            local partCount = 0
            
            for _, part in pairs(farmParts) do
                if part:IsA("BasePart") then
                    local pos = part.Position
                    totalX = totalX + pos.X
                    totalZ = totalZ + pos.Z
                    totalY = math.max(totalY, pos.Y + part.Size.Y/2) -- Use highest Y position
                    partCount = partCount + 1
                end
            end
            
            if partCount > 0 then
                local centerX = totalX / partCount
                local centerZ = totalZ / partCount
                return CFrame.new(centerX, totalY, centerZ)
            end
        end
    end
    
    -- Fallback: try to find any farm area parts
    local farmAreas = {"Farm_Area", "Dirt", "Farmland", "Ground"}
    for _, areaName in pairs(farmAreas) do
        local area = important:FindFirstChild(areaName, true)
        if area and area:IsA("BasePart") then
            local pos = area.Position
            return CFrame.new(pos.X, pos.Y + area.Size.Y/2 + 1, pos.Z)
        end
    end
    
    -- Final fallback: use farm folder position if available
    if farm.PrimaryPart then
        local pos = farm.PrimaryPart.Position
        return CFrame.new(pos.X, pos.Y + 4, pos.Z)
    end

    warn("Could not determine farm center for player:", Core.LocalPlayer.Name)
    return CFrame.new(0, 4, 0) -- Default position
end

-- Get random point within farm boundaries
-- ignorePoints: optional list of Vector3 positions to avoid
-- radius: optional minimum distance from ignore points (default: 5)
function FarmUtils:GetRandomFarmPoint(ignorePoints, radius)
    ignorePoints = ignorePoints or {}
    radius = radius or 5
    
    local farm = FarmUtils:GetMyFarm()
    if not farm then
        return Vector3.new(0, 4, 0)
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        return Vector3.new(0, 4, 0)
    end
    
    local function isValidPoint(point)
        -- Check if point is far enough from ignore points
        for _, ignorePoint in pairs(ignorePoints) do
            local distance = (point - ignorePoint).Magnitude
            if distance < radius then
                return false
            end
        end
        
        -- Check for eggs (telur) nearby using farm-based approach
        local myFarm = FarmUtils:GetMyFarm()
        if myFarm then
            local objectsPhysical = myFarm.Important.Objects_Physical
            if objectsPhysical then
                for _, egg in pairs(objectsPhysical:GetChildren()) do
                    pcall(function()
                        if egg.Name == "PetEgg" then
                            local owner = egg:GetAttribute("OWNER")
                            if owner == Core.LocalPlayer.Name then
                                local eggPosition = egg.Position
                                if eggPosition then
                                    local distance = (point - eggPosition).Magnitude
                                    if distance < radius then
                                        return false
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
        
        return true
    end
    
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Try up to 10 times to find a valid point
            for attempt = 1, 10 do
                -- Pick random farm part
                local randomPart = farmParts[math.random(1, #farmParts)]
                if randomPart:IsA("BasePart") then
                    local X1, Z1, X2, Z2 = FarmUtils:GetArea(randomPart)
                    local X = math.random(X1, X2)
                    local Z = math.random(Z1, Z2)
                    local point = Vector3.new(X, 4, Z)
                    
                    if isValidPoint(point) then
                        return point
                    end
                end
            end
        end
    end
    
    -- Fallback to center point (check if it's valid too)
    local centerCFrame = FarmUtils:GetFarmCenterCFrame()
    local centerPoint = centerCFrame and centerCFrame.Position or Vector3.new(0, 4, 0)
    
    if isValidPoint(centerPoint) then
        return centerPoint
    end
    
    -- If center point is also blocked, return it anyway as final fallback
    return centerPoint
end

function FarmUtils:GetBackCornerFarmPoint()
    local farm = FarmUtils:GetMyFarm()
    if not farm then
        return Vector3.new(0, 4, 0)
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        return Vector3.new(0, 4, 0)
    end
    
    local plantLocations = important:FindFirstChild("Plant_Locations")
    if plantLocations then
        local farmParts = plantLocations:GetChildren()
        if #farmParts > 0 then
            -- Pick random farm part
            local randomPart = farmParts[math.random(1, #farmParts)]
            if randomPart:IsA("BasePart") then
                local X1, Z1, X2, Z2 = FarmUtils:GetArea(randomPart)
                return Vector3.new(X1, 4, Z2) -- Back corner (X1,Z2)
            end
        end
    end
    
    -- Fallback to center point
    local centerCFrame = FarmUtils:GetFarmCenterCFrame()
    return centerCFrame and centerCFrame.Position or Vector3.new(0, 4, 0)
end

function FarmUtils:GetAllPlants()
    local farm = FarmUtils:GetMyFarm()
    if not farm then
        return {}
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        return {}
    end
    
    local plantLocations = important:FindFirstChild("Plants_Physical")
    if plantLocations then
        local pant = {}

        for _, plant in pairs(plantLocations:GetChildren()) do
            table.insert(pant, plant)
        end
        
        return pant
    end
    
    return {}    
end

function FarmUtils:FindPlants(plantName)
    if not plantName or type(plantName) ~= "string" then
        warn("FarmUtils:FindPlants - Invalid plant name")
        return nil
    end
    
    local allPlants = FarmUtils:GetAllPlants()
    local foundPlants = {}
    for _, plant in pairs(allPlants) do
        if plant.Name == plantName then
            table.insert(foundPlants, plant)
        else
            print("Plant does not match:", plant.Name, plantName)
        end
    end

    return #foundPlants > 0 and foundPlants or nil
end

function FarmUtils:HarvestPlant(plant)    
    local Prompt = plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    
    fireproximityprompt(Prompt)
end

function FarmUtils:IsMaxInventory()
    local character = Core.LocalPlayer
    local backpack = Core:GetBackpack()
    if not character or not backpack then
        warn("FarmUtils:IsMaxFruitInventory - Character or Backpack not found")
        return false
    end

    -- print all character attributes
    for _, attr in pairs(character:GetAttributes()) do
        print("Character Attribute:", _, attr)
    end

    local bonusBackpack = character:GetAttribute("BonusBackpackSize") or 0
    local maxCapacity = 200 + bonusBackpack
    local currentItems = 0

    for _, item in pairs(backpack:GetChildren()) do
        if item:GetAttribute("b") == "j" then
            currentItems = currentItems + 1
        end
    end

    print("Current Inventory:", currentItems, "/", maxCapacity)
    print("Is Max Inventory:", currentItems >= maxCapacity)

    return currentItems >= maxCapacity
end

function FarmUtils:StartAutoHarvest()
    if self.AutoHarvesting == true then
        warn("Auto harvesting is already running")
        return
    end

    self.AutoHarvesting = true
    self.AutoHarvestThread = coroutine.create(function()
        print("Auto harvesting started")
        while self.AutoHarvesting do
            local plantsToHarvest = Window:GetConfigValue("PlantsToHarvest") or {}
            if #plantsToHarvest == 0 then
                warn("No plants selected for auto harvest")
                task.wait(10)
                -- break out of this iteration, continue the while loop
            else
                if not self.AutoHarvesting then break end
                for _, plant in pairs(plantsToHarvest) do
                    print("Searching for plant:", plant)
                    local foundPlants = self:FindPlants(plant)
                    if foundPlants then
                        print("Found plants:", foundPlants, #foundPlants)
                        for _, foundPlant in pairs(foundPlants) do
                            print("Harvesting plant:", foundPlant.Name, foundPlant:GetFullName())
                            self:HarvestPlant(foundPlant)
                            -- task.wait(0.001) -- Small delay between harvests
                        end
                    end
                end
            end
            task.wait(5) -- Wait before next scan
        end
    end)
    coroutine.resume(self.AutoHarvestThread)
end

function FarmUtils:StopAutoHarvest()
    if not self.AutoHarvesting then
        warn("Auto harvesting is not running")
        return
    end

    self.AutoHarvesting = false
    if self.AutoHarvestThread then
        local status = coroutine.status(self.AutoHarvestThread)
        print("AutoHarvestThread status:", status)
        if status == "suspended" then
            coroutine.resume(self.AutoHarvestThread)
        end
        -- If coroutine is already dead or running, do not resume
        self.AutoHarvestThread = nil
    end
end

function FarmUtils:StopAllAutomation()
    self:StopAutoHarvest()
end

function FarmUtils:GetPlantRegistry()
    local success, seedRegistry = pcall(function()
        return require(Core.ReplicatedStorage.Data.SeedData)
    end)
    
    if success then           
        if seedRegistry then
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
        else
            warn("FarmUtils:GetPlantRegistry - SeedData is nil or not found")
            return {}
        end
    else
        warn("Failed to get seed registry:", seedRegistry)
        return {}
    end
end

function FarmUtils:FindSeedForPlant(plantName)
    if not plantName or type(plantName) ~= "string" then
        warn("FarmUtils:FindSeedForPlant - Invalid plant name")
        return nil
    end
    
    local plants = FarmUtils:GetPlantRegistry()
    for _, plantData in pairs(plants) do
        if plantData.plant == plantName then
            return plantData.seed
        end
    end
    
    return nil
end

-- function FarmUtils:SubmitEventPlant(toolPlant)
--     if not toolPlant or not toolPlant:IsA("Tool") then
--         warn("FarmUtils:SubmitEventPlant - Invalid tool plant name")
--         return
--     end

--     local submitTask = function()
--         wait(0.5) -- Small delay to ensure state is updated
--         Core.GameEvents.TieredPlants.Submit:FireServer("Held")
--         wait(0.5) -- Wait a bit to ensure submission is processed
--     end

--     PlayerUtils:AddToQueue(toolPlant, 5, submitTask)
-- end

-- function FarmUtils:SubmitAllEventPlants()
--     local backpack = Core:GetBackpack()
--     if not backpack then
--         warn("FarmUtils:SubmitAllEventPlants - Backpack not found")
--         return
--     end

--     for _, Tool in next, PlayerUtils:GetAllTools() do
--         if Tool:GetAttribute("b") == "j" and string.find(Tool.Name, "Evo")  then
--             print("Submitting event plant:", Tool.Name)
--             self:SubmitEventPlant(Tool)
--         end
--     end
-- end

return FarmUtils