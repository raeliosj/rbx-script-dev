local m = {}

local Window
local Core
local Plant

local BackpackConnection
local LastSubmitTime

function m:Init(_window, _core, _plant)
    Window = _window
    Core = _core
    Plant = _plant
    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoHarvestSafariQuest")
    end, function()
        self:StartAutoHarvest()
    end)

    task.spawn(function()
        self:StartAutoSubmitEventPlants()
    end)
end

function m:GetQuestPlantType()
    local questText = Core.Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"].Head.BubblePart.SafariTraitBillboard.BG.TraitTextLabel.Text
    local plantType = string.match(questText, "<font.-%>(.-)</font>")

    -- Remove wording Plants
    if plantType then
        plantType = plantType:gsub(" Plants", "")
    end

    return plantType or ""
end

function m:GetListPlantsByType(plantType)
    local plantsData = require(Core.ReplicatedStorage.Modules.PlantTraitsData)
    local plantTraits = plantsData.Traits or {}

    if not plantType or plantType == "" then
        return {}
    end

    return plantTraits[plantType] or {}
end

function m:StartAutoHarvest()
    if not Window:GetConfigValue("AutoHarvestSafariQuest") then
        return
    end

    local questPlantType = self:GetQuestPlantType()
    if not questPlantType or questPlantType == "" then
        Window:ShowWarning("Safari Quest", "Could not find quest plant type.")
        task.wait(5)
        return
    end

    local questPlants = self:GetListPlantsByType(questPlantType)
    if not questPlants or #questPlants == 0 then
        Window:ShowWarning("Safari Quest", "Could not find quest data for plant: " .. questPlantType)
        task.wait(5)
        return
    end

    local plants = {}
    for _, plant in ipairs(questPlants) do
        local foundPlants = Plant:FindPlants(plant) or {}
        if not foundPlants or #foundPlants == 0 then
            continue
        end
        table.insert(plants, foundPlants)
    end

    if not plants or #plants == 0 then
        Window:ShowWarning("Safari Quest", "No plants found for quest: " .. questPlantType)
        task.wait(5)
        return
    end

    local plantToHarvest = {}
    for _, plantGroup in pairs(plants) do
        for _, plantModel in pairs(plantGroup) do
            local plantDetail = Plant:GetPlantDetail(plantModel)
            if not plantDetail or #plantDetail.fruits == 0 then
                continue
            end
            
            for _, fruit in pairs(plantDetail.fruits) do
                if plantDetail.isGrowing then
                    continue
                end

                if not fruit.isEligibleToHarvest then
                    continue
                end

                table.insert(plantToHarvest, fruit.model)
            end
        end
    end

    if not plantToHarvest or #plantToHarvest == 0 then
        Window:ShowWarning("Safari Quest", "No eligible plants to harvest for quest: " .. questPlantType)
        task.wait(5)
        return
    end

    Window:ShowInfo("Safari Quest", "Auto harvesting " .. tostring(#plantToHarvest) .. " fruits for quest: " .. questPlantType)

    for _, plantModel in pairs(plantToHarvest) do
        if Plant:IsMaxInventory() and Window:GetConfigValue("SafariSellFruitsIfInventoryFull") then
            Plant:SellAllFruits()
        end
        
        if Plant:IsMaxInventory() then
            Core.ReplicatedStorage.GameEvents.SafariEvent.Safari_SubmitAllRE:FireServer(Core.LocalPlayer)
        end

        if questPlantType ~= self:GetQuestPlantType() then
            Window:ShowWarning("Safari Quest", "Quest plant type changed during harvesting. Stopping.")
            break
        end
        
        Plant:HarvestFruit(plantModel)
        task.wait(0.15)
    end
end

function m:StartAutoSubmitEventPlants()
    if not Window:GetConfigValue("AutoSubmitSafariQuest") then
        return
    end

    if not BackpackConnection then
        BackpackConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
            -- Debounce to prevent multiple submissions in quick succession
            if tick() - (LastSubmitTime or 0) < 5 then
                return
            end
            
            if child:GetAttribute("b") ~= "j" then
                return
            end

            Core.ReplicatedStorage.GameEvents.SafariEvent.Safari_SubmitAllRE:FireServer(Core.LocalPlayer)
            LastSubmitTime = tick()
        end)
    end

    Core.ReplicatedStorage.GameEvents.SafariEvent.Safari_SubmitAllRE:FireServer(Core.LocalPlayer)
    LastSubmitTime = tick()
end

function m:StopAutoSubmitEventPlants()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
end

return m