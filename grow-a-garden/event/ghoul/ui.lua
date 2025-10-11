local m = {}

local Window
local Quest

function m:Init(_window, _quest)
    Window = _window
    Quest = _quest

    self:GhoulSection(Window:AddTab({
        Name = "Event",
        Icon = "🎊",
    }))
end

function m:GhoulSection(tab)
    local eventAccordion = tab:AddAccordion({
        Title = "Ghoul Event",
        Icon = "👻",
        Default = false,
    })

    eventAccordion:AddToggle({
        Name = "Auto Submit Ghoul Quest Items 👻",
        Default = false,
        Flag = "AutoSubmitGhoulQuest",
        Callback = function(Value)
            if Value then
                Quest:StartAutoSubmitEventPlants()
            end
        end,
    })
end

return m