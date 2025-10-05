local m = {}

local Window
local Quest

function m:Init(_window, _quest)
    Window = _window
    Quest = _quest
end

function m:AddQuestSection(tab)
    local eventAccordion = tab:AddAccordion({
        Title = "Chubby Chipmunk Event",
        Icon = "🐿️",
        Default = false,
    })

    eventAccordion:AddToggle({
        Name = "Auto Submit Chipmunk Fruit 🥜",
        Default = false,
        Flag = "AutoSubmitSeedStagePlants",
        Callback = function(Value)
            if Value then
                Quest:StartAutoSubmitEventPlants()
            else
                Quest:StopAutoSubmitEventPlants()
            end
        end,
    })
end

return m