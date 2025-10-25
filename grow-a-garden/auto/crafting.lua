local m = {}

local Window
local Core

local MachineTypes = {}
local CraftingRecipeRegistry
local Recipes
local CraftingUtil
local Plant

m.StationRepository = {
    GearEventWorkbench = workspace.CraftingTables.EventCraftingWorkBench,
    SeedEventCraftingWorkBench = workspace.CraftingTables.SeedEventCraftingWorkBench,
}

function m:Init(window, core, plant)
    Window = window
    Core = core
    Plant = plant

    CraftingRecipeRegistry = require(Core.ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
    Recipes = CraftingRecipeRegistry.ItemRecipes
    CraftingUtil = require(Core.ReplicatedStorage.Modules.CraftingService.CraftingGlobalObjectService)

    self:InitCraftingRecipes()
    
    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoCraftingGear")
        end, 
        function()
            self:CraftingController( 
                self.StationRepository.GearEventWorkbench,
                Window:GetConfigValue("CraftingGearItem")
            )
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoCraftingSeeds")
        end, 
        function()
            self:CraftingController( 
                self.StationRepository.SeedEventCraftingWorkBench,
                Window:GetConfigValue("CraftingSeedItem")
            )
        end
    )
end

function m:GetCraftingObjectType(craftingStation)
    return craftingStation:GetAttribute("CraftingObjectType")
end 

function m:InitCraftingRecipes()
    if #MachineTypes > 0 then
        return MachineTypes
    end

    MachineTypes = CraftingRecipeRegistry.RecipiesSortedByMachineType or {}

    return MachineTypes
end

function m:GetMachineTypes()
    local machineTypes =  {}
    
    for machineType, _ in pairs(MachineTypes) do
        table.insert(machineTypes, machineType)
    end

    return machineTypes
end

function m:GetAllCraftingItems(craftingStation)
    local machineType = self:GetCraftingObjectType(craftingStation)
    local craftingItems = {}

    for item, _ in pairs(MachineTypes[machineType] or {}) do
        table.insert(craftingItems, item)
    end

    -- Sort the crafting items alphabetically
    table.sort(craftingItems)

    return craftingItems
end

function m:GetCraftingData(craftingStation, craftingItem)
    local machineType = self:GetCraftingObjectType(craftingStation)
    local data = {}

    for items, detail in pairs(MachineTypes[machineType] or {}) do
        if items == craftingItem then
            table.insert(data, detail)
            break
        end
    end

    return data
end

function m:GetCraftingRecipes(craftingStation, craftingItem)
    local craftingData = self:GetCraftingData(craftingStation, craftingItem)
    local craftingInputs = {}
    local recipes = {}

    if #craftingData == 0 then
        return recipes
    end

    for _, detail in pairs(craftingData) do
        if type(detail) == "table" and detail.Inputs then
            for _, input in pairs(detail.Inputs) do
                table.insert(craftingInputs, input)
            end
            continue
        end
    end

    for i, input in pairs(craftingInputs) do
        local dataItems
        table.insert(recipes, input)
    end

    return recipes
end

function m:GetCraftingStationStatus(craftingStation)
    local data = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))
    if not data or not data.RecipeId then
        return "Idle"
    end

    local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)
    if #unsubmittedItems > 0 then
        return "Waiting for Item"
    end

    local craftingItem = data.CraftingItems and data.CraftingItems[1]
    if craftingItem then
        if craftingItem.IsDone then
            return "Ready to Claim"
        else
            return "On Progress"
        end
    end

    return "Ready to Start"
end

function m:SetRecipe(craftingStation, craftingItem)
    if not craftingStation or not craftingItem then
        return
    end

    Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
        "SetRecipe",
        craftingStation,
        self:GetCraftingObjectType(craftingStation),
        craftingItem
    )
end

function m:SubmitCraftingRequest(craftingStation)
    local craftingHandler = require(Core.ReplicatedStorage.Modules.CraftingStationHandler)

    local success, error = pcall(function() 
        craftingHandler:SubmitAllRequiredItems(craftingStation) 
    end)

    if not success then
        warn("Error submitting crafting request:", error)
        return
    end

    local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)

    if #unsubmittedItems == 0 then
        return
    end

    local needFruits = {}
    for _, item in pairs(unsubmittedItems) do
        if item.ItemType == "Holdable" then
            table.insert(needFruits, item.ItemData.ItemName)
        end
    end

    if #needFruits == 0 then
        return
    end

    for _, fruit in pairs(needFruits) do
        local plants = Plant:FindPlants(fruit) or {}

        if #plants == 0 then
            continue
        end

        for _, plant in pairs(plants) do
            local plantDetail = Plant:GetPlantDetail(plant)
            local successHarvest
            if not plantDetail or #plantDetail.fruits == 0 then
                continue
            end

            for _, harvestingFruit in pairs(plantDetail.fruits) do
                if not harvestingFruit.isEligibleToHarvest then
                    continue
                end

                successHarvest = pcall(function()
                    Plant:HarvestFruit(harvestingFruit.model)
                end)
            end

            if successHarvest then
                break
            end
        end
    end
end

function m:StartCrafting(craftingStation)
    local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)
    
    if #unsubmittedItems > 0 then
        return
    end

    local OpenRecipeEvent = Core.ReplicatedStorage.GameEvents.OpenRecipeBindableEvent

    local success, error = pcall(function()
        Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "Craft",
            craftingStation,
            self:GetCraftingObjectType(craftingStation)
        )
    end)

    if not success then
        warn("Error starting crafting:", error)
        return
    end
end

function m:CraftingController(craftingStation, craftingItem)
    if not craftingStation or not craftingItem then
        return
    end

    if self:GetCraftingStationStatus(craftingStation) == "Idle" then
        self:SetRecipe(craftingStation, craftingItem)
        task.wait(0.5) -- Wait for 0.5 seconds to allow the station to update its status
    end

    while self:GetCraftingStationStatus(craftingStation) == "Waiting for Item" do
        self:SubmitCraftingRequest(craftingStation)
        
        wait(5) -- Wait for 5 seconds before checking again
    end

    if  self:GetCraftingStationStatus(craftingStation) == "Ready to Start" then
        self:StartCrafting(craftingStation)
        task.wait(0.5) -- Wait for 0.5 seconds to allow the crafting process to start
    end
    
    while self:GetCraftingStationStatus(craftingStation) == "On Progress" do
        wait(5) -- Wait for 5 seconds before checking again
    end

    if self:GetCraftingStationStatus(craftingStation) == "Ready to Claim" then
        local success, error = pcall(function()
            Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
                "Claim",
                craftingStation,
                self:GetCraftingObjectType(craftingStation),
                1
            )
        end)

        if not success then
            warn("Error claiming crafted item:", error)
            return
        end

        task.wait(0.5) -- Wait for 0.5 seconds to allow the
    end
end

function m:GetSubmittedItems(craftingStation)
	local machineData = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))
    local submittedItems = {}
	
    if not (machineData and machineData.RecipeId) then
		return submittedItems
	end
	 
    if not Recipes[machineData.RecipeId] then
		return submittedItems
	end
	
    for item, _ in machineData.InputItems do
		submittedItems[tostring(item)] = true
	end

    return submittedItems
end

function m:GetUnsubmittedItems(craftingStation)
    local submitted = self:GetSubmittedItems(craftingStation)
    local machineData = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))
    
    local recipe = machineData and machineData.RecipeId and Recipes[machineData.RecipeId]
    local result = {}
    
    if recipe then
        for id, input in pairs(recipe.Inputs) do
            if not submitted[tostring(id)] then
                table.insert(result, input)
            end
        end
    end
    
    return result
end

return m