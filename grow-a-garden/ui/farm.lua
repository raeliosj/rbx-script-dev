local m = {}
local Core
local PlayerUtils
local FarmUtils
local Window

function m:Init(core, playerUtils, farmUtils, windowInstance)
    if not core then
        error("FarmUI:Init - Core module is required")
    end
    if not playerUtils then
        error("FarmUI:Init - PlayerUtils module is required")
    end
    if not farmUtils then
        error("FarmUI:Init - FarmUtils module is required")
    end
    if not windowInstance then
        error("FarmUI:Init - windowInstance is required")
    end
    Core = core
    PlayerUtils = playerUtils
    FarmUtils = farmUtils
    Window = windowInstance
end

function m:CreateFarmTab()
    local farmTab = Window:AddTab({
        Name = "Farm",
        Icon = "🌾",
    })

    -- Display Farm Center Button
    farmTab:AddButton(
        "Test",
        function()
            FarmUtils:SubmitAllEventPlants()
       end
   )

   self:CreateHarvestSection(farmTab)
end

function m:CreateHarvestSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Harvest",
        Icon = "🌿",
        Default = false,
    })
    accordion:AddLabel("Select plants to auto harvest:")
    accordion:AddSelectBox({
        Name = "Plants to Harvest",
        Flag = "PlantsToHarvest",
        MultiSelect = true,
        Placeholder = "Select plants...",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local plants = FarmUtils:GetPlantRegistry()
            local formattedPlants = {}
            for _, plantData in pairs(plants) do
                table.insert(formattedPlants, {
                    text = plantData.plant,
                    value = plantData.plant,
                })
            end
            updateOptions(formattedPlants)
        end,
    })
    
    accordion:AddToggle({
        Name = "Auto Harvest Plants 🌿",
        Default = false,
        Flag = "AutoHarvestPlants",
        Callback = function(Value)
            if Value then
                FarmUtils:StartAutoHarvest()
            else
                FarmUtils:StopAutoHarvest()
            end
        end,
    })
end

return m