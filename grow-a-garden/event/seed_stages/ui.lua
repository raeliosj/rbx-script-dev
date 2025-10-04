local m = {}

local Window
local SeedStagesModule
local SeedStageShop

local BackpackConnection

function m:Init(_window, _seedStagesModule, _shop)
    Window = _window
    SeedStagesModule = _seedStagesModule
    SeedStageShop = _shop
end

function m:AddQuestSection(tab)
    local eventAccordion = tab:AddAccordion({
        Title = "Event Seed Stages",
        Icon = "🎉",
        Default = false,
    })

    eventAccordion:AddToggle({
        Name = "Auto Submit Seed Stage Plants 🚜",
        Default = false,
        Flag = "AutoSubmitSeedStagePlants",
        Callback = function(Value)
            if Value then
                SeedStagesModule:StartAutoSubmitEventPlants()
            else
                SeedStagesModule:StopAutoSubmitEventPlants()
            end
        end,
    })
end

function m:AddShopEventToggles(tab)
    tab:AddToggle({
        Name = "Auto Buy Event Items 🎉",
        Default = false,
        Flag = "AutoBuyEventItems",
        Callback = function(Value)
            if Value then
                SeedStageShop:BuyAllEventItems()
            end
        end,
    })
end


return m