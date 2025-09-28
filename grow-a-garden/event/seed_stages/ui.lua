local m = {}

function m:Init(windowInstance, seedStagesModuleInstance)
    Window = windowInstance
    SeedStagesModule = seedStagesModuleInstance
end

function m:CreateQuestSection(tab)
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

-- function m:CreateShopSection(tab)
--     local shopAccordion = tab:AddAccordion({
--         Title = "Event Seed Stages Shop",
--         Icon = "🛍️",
--         Default = false,
--     })

--     shopAccordion:AddToggle({
--         Name = "Auto Buy Event Seed Stage Seeds 🌱",
--         Default = false,
--         Flag = "AutoBuyEventSeedStageSeeds",
--         Callback = function(Value)
--             if Value then
--                 SeedStagesModule:StartSeedStageSeedAutomation()
--             else
--                 SeedStagesModule:StopSeedStageSeedAutomation()
--             end
--         end,
--     })
-- end

return m