local m = {}

local Window
local Core
local Crafting


function m:Init(_window, _core, _crafting)
    Window = _window
    Core = _core
    Crafting = _crafting

    local tab = Window:AddTab({
        Name = "AutoMation",
        Icon = "🔧",
    })

    self:CraftingGearSection(tab)
    self:CraftingSeedSection(tab)
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
            local craftingItems = Crafting:GetAllCraftingItems(Crafting.StationRepository.GearEventWorkbench)

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
            local craftingItems = Crafting:GetAllCraftingItems(Crafting.StationRepository.SeedEventCraftingWorkBench)

            optionsData.updateOptions(craftingItems)
        end
    })

    accordion:AddToggle({
        Name = "Auto Crafting Seeds 🌱",
        Default = false,
        Flag = "AutoCraftingSeeds",
    })
end

return m