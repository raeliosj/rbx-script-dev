local m = {}
local Window
local Quest
local Event

function m:Init(_window, _quest, _event)
    Window = _window
    Quest = _quest
    Event = _event
end

function m:CreateQuestTab()
    local tab = Window:AddTab({
        Name = "Quests",
        Icon = "📜",
    })

   Event:AddQuestSection(tab)
end

return m