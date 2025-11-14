local m = {}

local Window
local Core
local Crafting
local Plant
local Cooking


function m:Init(_window, _core, _crafting, _plant, _cooking)
    Window = _window
    Core = _core
    Crafting = _crafting
    Plant = _plant
    Cooking = _cooking

    local tab = Window:AddTab({
        Name = "AutoMation",
        Icon = "🔧",
    })

    self:CraftingGearSection(tab)
    self:CraftingSeedSection(tab)
    self:CookingSection(tab)
end

function m:CraftingGearSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Crafting Gear",
        Icon = "⚙️",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Crafting Item ⚙️",
        Options = {"loading ..."},
        Placeholder = "Select Crafting Item",
        Flag = "CraftingGearItem",
        OnInit =  function(api, optionsData)
            local craftingItems = Crafting:GetAllCraftingItems(workspace.CraftingTables.EventCraftingWorkBench)

            optionsData.updateOptions(craftingItems)
        end
    })

    accordion:AddToggle({
        Name = "Auto Crafting Gear ⚙️",
        Default = false,
        Flag = "AutoCraftingGear",
    })
end

function m:CraftingSeedSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Crafting Seeds",
        Icon = "🌱",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Crafting Item 🌱",
        Options = {"loading ..."},
        Placeholder = "Select Crafting Item",
        Flag = "CraftingSeedItem",
        OnInit =  function(api, optionsData)
            local craftingItems = Crafting:GetAllCraftingItems(workspace.CraftingTables.SeedEventCraftingWorkBench)

            optionsData.updateOptions(craftingItems)
        end
    })

    accordion:AddToggle({
        Name = "Auto Crafting Seeds 🌱",
        Default = false,
        Flag = "AutoCraftingSeeds",
    })
end

function m:CookingSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Cooking",
        Icon = "🍳",
        Default = false,
    })

    local plantOptions = {}
    local plants = Plant:GetPlantRegistry()
    for _, plantData in pairs(plants) do
        table.insert(plantOptions, {
            text = plantData.plant,
            value = plantData.plant,
        })
    end

    accordion:AddSelectBox({
        Name = "Ingredient 1",
        Options = plantOptions or {"loading ..."},
        Placeholder = "Select Ingredient 1",
        Flag = "CookingIngredient1"
    })

    accordion:AddSelectBox({
        Name = "Ingredient 2",
        Options = plantOptions or {"loading ..."},
        Placeholder = "Select Ingredient 2",
        Flag = "CookingIngredient2"
    })

    accordion:AddSelectBox({
        Name = "Ingredient 3",
        Options = plantOptions or {"loading ..."},
        Placeholder = "Select Ingredient 3",
        Flag = "CookingIngredient3"
    })

    accordion:AddSelectBox({
        Name = "Ingredient 4",
        Options = plantOptions or {"loading ..."},
        Placeholder = "Select Ingredient 4",
        Flag = "CookingIngredient4"
    })

    accordion:AddSelectBox({
        Name = "Ingredient 5",
        Options = plantOptions or {"loading ..."},
        Placeholder = "Select Ingredient 5",
        Flag = "CookingIngredient5"
    })

    accordion:AddToggle({
        Name = "Auto Cooking 🍳",
        Default = false,
        Flag = "AutoCooking",
    })
end

return m