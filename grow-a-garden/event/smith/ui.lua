local m = {}

local Window
local Core
local Crafting
local Quest
local Plant
local Pet

function m:Init(_window, _core, _quest, _crafting, _plant, _pet)
    Window = _window
    Core = _core
    Quest = _quest
    Crafting = _crafting
    Plant = _plant
    Pet = _pet

    local tab = Window:AddTab({
        Name = "Smith Event",
        Icon = "⚒️",
    })

    self:QuestSection(tab)
    self:CraftingGearSection(tab)
    self:CraftingSeedSection(tab)
    self:CraftingCosmeticSection(tab)
end

function m:QuestSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Smith Event Quests",
        Icon = "📜",
        Default = false,
    })

    accordion:AddLabel(function()
        local currentQuest, _ = Quest:GetQuestSubmitEvent()
        return string.format("Current Quest Type: %s", currentQuest)
    end)

    accordion:AddSelectBox({
        Name = "Select Plant to Submit",
        Options = {"loading ..."},
        Placeholder = "Select Plant",
        Flag = "SmithEventQuestPlantToSubmit",
        MultiSelect = true,
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
        end,
    })

    accordion:AddSelectBox({
        Name = "Select Pet to Submit",
        Options = {"loading ..."},
        Placeholder = "Select Pet",
        Flag = "SmithEventQuestPetToSubmit",
        MultiSelect = true,
        OnInit = function(api, optionsData)
            local pets = Pet:GetAllMyPets()
            local currentOptionsSet = {}

            for _, pet in pairs(pets) do
                table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
            end
            optionsData.updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local pets = Pet:GetAllMyPets()
            local currentOptionsSet = {}

            for _, pet in pairs(pets) do
                table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
            end
            updateOptions(currentOptionsSet)
        end,
    })

end

function m:CraftingGearSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Crafting Gear",
        Icon = "⚙️",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Crafting Item",
        Options = {"loading ..."},
        Placeholder = "Select Crafting Item",
        Flag = "SmithEventCraftingGearItem",
        OnInit =  function(api, optionsData)
            local craftingItems = Crafting:GetAllCraftingItems("SmithingEventGearWorkbench")
            local craftingItemsList = {}
            
            for itemName, _ in pairs(craftingItems) do
                table.insert(craftingItemsList, itemName)
            end

            optionsData.updateOptions(craftingItemsList)
        end
    })


    accordion:AddToggle({
        Name = "Auto Crafting Gear",
        Default = false,
        Flag = "AutoSmithEventCraftingGear",
    })
end

function m:CraftingSeedSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Crafting Seeds",
        Icon = "🌱",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Crafting Seed Item",
        Options = {"loading ..."},
        Placeholder = "Select Crafting Seed Item",
        Flag = "SmithEventCraftingSeedItem",
        OnInit =  function(api, optionsData)
            local craftingItems = Crafting:GetAllCraftingItems("SmithingEventSeedWorkbench")
            local craftingItemsList = {}
            for itemName, _ in pairs(craftingItems) do
                table.insert(craftingItemsList, itemName)
            end

            optionsData.updateOptions(craftingItemsList)
        end
    })

    accordion:AddToggle({
        Name = "Auto Crafting Seeds",
        Default = false,
        Flag = "AutoSmithEventCraftingSeeds",
    })
end

function m:CraftingCosmeticSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Crafting Cosmetics",
        Icon = "🎨",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Crafting Cosmetic Item",
        Options = {"loading ..."},
        Placeholder = "Select Crafting Cosmetic Item",
        Flag = "SmithEventCraftingCosmeticItem",
        OnInit =  function(api, optionsData)
            local craftingItems = Crafting:GetAllCraftingItems("SmithingEventCosmeticWorkbench")
            local craftingItemsList = {}

            for itemName, _ in pairs(craftingItems) do
                table.insert(craftingItemsList, itemName)
            end

            optionsData.updateOptions(craftingItemsList)
        end
    })

    accordion:AddToggle({
        Name = "Auto Crafting Cosmetics",
        Default = false,
        Flag = "AutoSmithEventCraftingCosmetics",
    })
end

return m