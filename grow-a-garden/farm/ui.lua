local m = {}
local Window
local Player
local Garden
local Plant

function m:init(_window, _player, _garden, _plant)
    Window = _window
    Player = _player
    Garden = _garden
    Plant = _plant
end

function m:CreateFarmTab()
    local tab = Window:AddTab({
        Name = "Farm",
        Icon = "🌾",
    })

    self:AddPlantingSection(tab)
    self:AddWateringSection(tab)
    self:AddHarvestingSection(tab)
end

function m:AddPlantingSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Planting",
        Icon = "🌱",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select seeds to auto plant",
        Options = {"Loading..."},
        Placeholder = "Select seeds...",
        MultiSelect = true,
        Flag = "SeedsToPlant",
       OnInit = function(api, optionsData)
            local seeds = Plant:GetPlantRegistry()
            local formattedSeeds = {}
            for _, seedData in pairs(seeds) do
                table.insert(formattedSeeds, {
                    text = seedData.plant,
                    value = seedData.plant
                })
            end
            optionsData.updateOptions(formattedSeeds)
        end,
    })

    accordion:AddNumberBox({
        Name = "Set the number of seeds to plant",
        Placeholder = "Enter number of seeds...",
        Flag = "SeedsToPlantCount",
        Min = 0,
        Max = 800,
        Default = 1,
        Increment = 1,
    })

    accordion:AddSelectBox({
        Name = "Position planting seeds",
        Flag = "PlantingPosition",
        Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Random",
        MultiSelect = false,
        Placeholder = "Select position...",
    })

    accordion:AddButton({Text = "Save Planting Settings", Callback = function()
        local selectedSeeds = Window:GetConfigValue("SeedsToPlant") or {}
        local seedsToPlantCount = Window:GetConfigValue("SeedsToPlantCount") or 1

        print("Selected Seeds:", selectedSeeds)
        print("Number of Seeds to Plant:", seedsToPlantCount)

        Plant:PlantSeed(selectedSeeds[1], seedsToPlantCount)
    end})

    accordion:AddToggle({
        Name = "Enable Auto Planting",
        Flag = "AutoPlantSeeds",
        Default = false,
        Callback = function(state)
           if state then
                print("Auto Planting Enabled:", state)
                Plant:StartAutoPlanting()
            else
                print("Auto Planting Disabled:", state)
            end
        end,
    })
end

function m:AddWateringSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Watering",
        Icon = "💧",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Watering Position",
        Flag = "WateringPosition",
        Options = {"Growing Plants", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Front Right",
        MultiSelect = false,
        Placeholder = "Select position...",
    })

    accordion:AddNumberBox({
        Name = "Set the Each Watering",
        Placeholder = "Enter number of waterings...",
        Flag = "WateringEach",
        Min = 1,
        Max = 100,
        Default = 1,
        Increment = 1,
    })

    accordion:AddNumberBox({
        Name = "Set the number of waterings delay",
        Placeholder = "Enter watering delay...",
        Flag = "WateringDelay",
        Min = 0,
        Max = 800,
        Default = 1,
        Increment = 1,
    })

    accordion:AddToggle({
        Name = "Enable Auto Watering",
        Flag = "AutoWateringPlants",
        Default = false,
        Callback = function(state)
           if state then
                print("Auto Watering Enabled:", state)
                Plant:AutoWateringPlants()
            else
                print("Auto Watering Disabled:", state)
            end
        end,
    })
end

function m:AddHarvestingSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Harvest",
        Icon = "🌿",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select plants to auto harvest",
        Flag = "PlantsToHarvest",
        MultiSelect = true,
        Placeholder = "Select plants...",
       OnInit = function(api, optionsData)
            local plants = Plant:GetPlantRegistry()
            local formattedPlants = {}
            for _, plantData in pairs(plants) do
                table.insert(formattedPlants, {
                    text = plantData.plant,
                    value = plantData.plant,
                })
            end
            optionsData.updateOptions(formattedPlants)
        end,
    })
    
    accordion:AddToggle({
        Name = "Auto Harvest Plants 🌿",
        Default = false,
        Flag = "AutoHarvestPlants",
        Callback = function(Value)
            if Value then
                Plant:StartAutoHarvesting()
            end
        end,
    })
end

return m