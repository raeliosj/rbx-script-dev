local m = {}

local Window
local Core
local Player
local Plant

local CookingPotUtils

function m:Init(_window, _core, _player, _plant)
    Window = _window
    Core = _core
    Player = _player
    Plant = _plant

    CookingPotUtils = require(Core.ReplicatedStorage.Modules.CookingPotClientUtils)

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoCooking")
        end, 
        function()
            self:StartAutoCooking()
        end
    )
end

function m:CombineIngredientsConfig()
    local Ingredient1 = Window:GetConfigValue("CookingIngredient1") or ""
    local Ingredient2 = Window:GetConfigValue("CookingIngredient2") or ""
    local Ingredient3 = Window:GetConfigValue("CookingIngredient3") or ""
    local Ingredient4 = Window:GetConfigValue("CookingIngredient4") or ""
    local Ingredient5 = Window:GetConfigValue("CookingIngredient5") or ""

    local ingredients = {}
    if Ingredient1 ~= "" then table.insert(ingredients, Ingredient1) end
    if Ingredient2 ~= "" then table.insert(ingredients, Ingredient2) end
    if Ingredient3 ~= "" then table.insert(ingredients, Ingredient3) end
    if Ingredient4 ~= "" then table.insert(ingredients, Ingredient4) end
    if Ingredient5 ~= "" then table.insert(ingredients, Ingredient5) end
    
    return ingredients
end

function m:CompareIngredients(submittedIngredients)
    local configIngredients = self:CombineIngredientsConfig()
    local unsubmittedItems = {}
    local hasWrongItems = false

    -- Find unsubmitted ingredients
    for _, ingredient in ipairs(configIngredients) do
        if not table.find(submittedIngredients, ingredient) then
            table.insert(unsubmittedItems, ingredient)
        end
    end

    -- Check for wrong submitted ingredients
    for _, ingredient in ipairs(submittedIngredients) do
        if not table.find(configIngredients, ingredient) then
            hasWrongItems = true
            break
        end
    end

    return unsubmittedItems, hasWrongItems
end

function m:FindIngredientInInventory(ingredientName)
    local foundItem = nil

    for _, item in pairs(Core:GetBackpack():GetChildren()) do
        if not item:IsA("Tool") then
            continue
        end

        if item:GetAttribute("b") ~= "j" then
            continue
        end

        if item:GetAttribute("f") == ingredientName then
            foundItem = item
            break
        end
    end
    return foundItem
end

function m:FindIngredientInFarm(ingredientName)
    local foundItem = nil
    local plants = Plant:FindPlants(ingredientName) or {}
    local plantToHarvest = {}

    if not plants or #plants == 0 then
        return foundItem
    end
    
    for _, plant in pairs(plants) do
        local plantDetail = Plant:GetPlantDetail(plant)
        if not plantDetail or #plantDetail.fruits == 0 then
            continue
        end

        for _, fruit in pairs(plantDetail.fruits) do
            if fruit.isEligibleToHarvest then
                table.insert(plantToHarvest, plant)
                break
            end
        end
    end

    for _, plant in pairs(plantToHarvest) do
        local successHarvest = Plant:HarvestFruit(plant) or false
        
        if successHarvest then
            break
        end
    end
    
    -- After harvesting, check inventory for the ingredient
    foundItem = self:FindIngredientInInventory(ingredientName)
    return foundItem
end

function m:StartCooking(cookingPotUUID, ingredients)
    local taskCompleted = false

    local cookingTask = function(_cookingPotUUID, _ingredients)
        for _, ingredientTool in pairs(_ingredients) do
            local currentlyEquipped = Player:GetEquippedTool()

            warn("Currently Equipped Tool: " .. tostring(currentlyEquipped.Name))

            if currentlyEquipped == nil or currentlyEquipped ~= ingredientTool then
                Player:EquipTool(ingredientTool)
                task.wait(0.5)
            end

            -- Submit Ingredient
            Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("SubmitHeldPlant", _cookingPotUUID)
            task.wait(0.5)
        end

        -- Start Cooking
        Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("CookBest", _cookingPotUUID)
    end

    local cookingCallback = function()
            isTaskCompleted = true
        end

    Player:AddToQueue(
        ingredients[1],
        20,
        function()
            cookingTask(cookingPotUUID, ingredients)
        end,
        function()
            cookingCallback()
        end
    )

    while not taskCompleted do
        task.wait(1)
    end
end

function m:StartAutoCooking()
    if not Window:GetConfigValue("AutoCooking") then
        return
    end

    local cookingKit = CookingPotUtils:GetAllCookingPotUUIDs(Core.LocalPlayer)
    if #cookingKit == 0 then
        return
    end

    local cookingPotUUIDs = {}
    for _, v in ipairs(cookingKit) do
        local uuid = v.Parent:GetAttribute("CosmeticUUID")
        table.insert(cookingPotUUIDs, uuid)
    end

    local cookingPotData = CookingPotUtils:GetCookingPotData(Core.LocalPlayer, cookingPotUUIDs[1])
    if not cookingPotData then
        return
    end
    
    if cookingPotData.IsCooking then
        local totalTime = cookingPotData.CookTimeTotal or 0

        warn("AutoCooking: Cooking in progress. Waiting for " .. tostring(totalTime + 1) .. " seconds.")

        task.wait(totalTime + 1)
    end

    if cookingPotData.FinishedFoodRawData and not cookingPotData.CookingEndTime then
        Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("GetFoodFromPot", cookingPotUUIDs[1])
        return
    end

    local submittedIngredients = {}
    for _, ingredient in pairs(cookingPotData.SubmittedIngredients) do
        local itemName = ingredient.ItemData and ingredient.ItemData.ItemName or ""
        
        if itemName == "" then
            continue
        end

        table.insert(submittedIngredients, itemName)
    end

    local unsubmittedItems, hasWrongItems = self:CompareIngredients(submittedIngredients)
    if hasWrongItems then
        -- Clear Ingredients
        Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("EmptyPot", cookingPotUUIDs[1])
        task.wait(1)

        unsubmittedItems = self:CombineIngredientsConfig()
    end

    local ingredientTools = {}
    for _, ingredientName in pairs(unsubmittedItems) do
        local ingredientTool = self:FindIngredientInInventory(ingredientName)
        if not ingredientTool then
            ingredientTool = self:FindIngredientInFarm(ingredientName)
        end
        if ingredientTool then
            table.insert(ingredientTools, ingredientTool)
        else
            warn("AutoCooking: Unable to find ingredient '" .. ingredientName .. "' in inventory or farm.")
        end
    end

    if #ingredientTools ~= #unsubmittedItems then
        warn("AutoCooking: Not all required ingredients are available. Aborting cooking process.")
        return
    end

    -- Start Cooking
    self:StartCooking(cookingPotUUIDs[1], ingredientTools)
end

return m