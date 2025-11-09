local m = {}
local Window
local Core
local Player
local Garden
local Plant

function m:init(_window, _core, _player, _garden, _plant)
    Window = _window
    Core = _core
    Player = _player
    Garden = _garden
    Plant = _plant

    self:CreateFarmTab()
end

function m:CreateFarmTab()
    local tab = Window:AddTab({
        Name = "Farm",
        Icon = "🌾",
    })

    self:AddPlantingSection(tab)
    self:AddWateringSection(tab)
    self:AddSprinklerSection(tab)
    self:AddHarvestingSection(tab)
    self:AddMovingSection(tab)
    self:AddShovelSection(tab)
    self:AddReclaimPlantSection(tab)
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
            local seeds = Plant:GetListSeedsAtInventory()
            local formattedSeeds = {}
            for _, seedData in pairs(seeds) do
                table.insert(formattedSeeds, {
                    text = string.format("[%s] %s (%s) Type: %s", seedData.rarity, seedData.plant, Core:FormatNumber(seedData.quantity), seedData.types),
                    value = seedData.plant
                })
            end
            optionsData.updateOptions(formattedSeeds)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local seeds = Plant:GetListSeedsAtInventory()
            local formattedSeeds = {}
            for _, seedData in pairs(seeds) do
                table.insert(formattedSeeds, {
                    text = string.format("[%s] %s (%s) Type: %s", seedData.rarity, seedData.plant, Core:FormatNumber(seedData.quantity), seedData.types),
                    value = seedData.plant
                })
            end
            updateOptions(formattedSeeds)
        end
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

    accordion:AddButton({Text = "Manual Planting", Callback = function()
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

function m:AddSprinklerSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Sprinkler",
        Icon = "💦",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select sprinklers to auto place",
        Options = {"Loading..."},
        Placeholder = "Select sprinklers...",
        MultiSelect = true,
        Flag = "SprinklersToPlace",
        OnInit = function(api, optionsData)
            local sprinklers = Plant:GetSprinklersRegistry()
            local formattedSprinklers = {}
            for _, sprinklerData in pairs(sprinklers) do
                table.insert(formattedSprinklers, {
                    text = string.format("%s (%s)", sprinklerData.name, Core:FormatNumber(sprinklerData.quantity)),
                    value = sprinklerData.name
                })
            end
            optionsData.updateOptions(formattedSprinklers)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local sprinklers = Plant:GetSprinklersRegistry()
            local formattedSprinklers = {}
            for _, sprinklerData in pairs(sprinklers) do
                table.insert(formattedSprinklers, {
                    text = string.format("%s (%s)", sprinklerData.name, Core:FormatNumber(sprinklerData.quantity)),
                    value = sprinklerData.name
                })
            end
            updateOptions(formattedSprinklers)
        end
    })

    accordion:AddSelectBox({
        Name = "Position placing sprinklers",
        Flag = "SprinklerPlacingPosition",
        Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Random",
        MultiSelect = false,
        Placeholder = "Select position...",
    })

    accordion:AddToggle({
        Name = "Enable Auto Place Sprinklers",
        Flag = "AutoPlaceSprinklers",
        Default = false,
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
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end
            optionsData.updateOptions(formattedPlants)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end

            updateOptions(formattedPlants)
        end
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

    accordion:AddToggle({
        Name = "Auto Sell Fruits If Inventory Full 🛒",
        Default = false,
        Flag = "AutoSellFruits",
    })
end

function m:AddMovingSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Move Plants",
        Icon = "🚜",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select plant to move",
        Flag = "PlantToMove",
        MultiSelect = false,
        Placeholder = "Select plant...",
        OnInit = function(api, optionsData)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end
            optionsData.updateOptions(formattedPlants)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end

            updateOptions(formattedPlants)
        end
    })

    accordion:AddSelectBox({
        Name = "Select destination",
        Flag = "MoveDestination",
        Options = {"Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Front Right",
        MultiSelect = false,
        Placeholder = "Select destination...",
    })

    accordion:AddButton({Text = "Move Plant", Callback = function()
        Plant:MovePlant()
    end})
end

function m:AddShovelSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Shovel Plants",
        Icon = "🪓",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select plant to shovel",
        Flag = "PlantToShovel",
        Placeholder = "Select plant...",
        OnInit = function(api, optionsData)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end
            optionsData.updateOptions(formattedPlants)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end

            updateOptions(formattedPlants)
        end
    })

    accordion:AddNumberBox({
        Name = "Set the number of plants to shovel",
        Placeholder = "Enter number of plants...",
        Flag = "PlantsToShovelCount",
        Min = 0,
        Max = 800,
        Default = 1,
        Increment = 1,
    })

    accordion:AddButton({Text = "Shovel Selected Plant", Callback = function()
        Plant:ShovelSelectedPlants()
    end})
end

function m:AddReclaimPlantSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Reclaim Plant",
        Icon = "♻️",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select plant to reclaim",
        Flag = "PlantToReclaim",
        Placeholder = "Select plant...",
        OnInit = function(api, optionsData)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end
            optionsData.updateOptions(formattedPlants)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local plants = Plant:GetListGardenPlants()
            local formattedPlants = {}
            for _, dataPlant in pairs(plants) do
                table.insert(formattedPlants, {
                    text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                    value = dataPlant.plant,
                })
            end

            updateOptions(formattedPlants)
        end
    })

    accordion:AddNumberBox({
        Name = "Set the number of plants to reclaim",
        Placeholder = "Enter number of plants...",
        Flag = "PlantsToReclaimCount",
        Min = 0,
        Max = 800,
        Default = 1,
        Increment = 1,
    })

    accordion:AddButton({Text = "Reclaim Selected Plant", Callback = function()
        Plant:ReclaimSelectedPlants()
    end})
end

return m