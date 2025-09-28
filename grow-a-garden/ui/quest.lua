local m = {}
local Window
local Quest
local Event

function m:Init(windowInstance, questInstance, eventInstance)
    Window = windowInstance
    Quest = questInstance
    Event = eventInstance
end

function m:CreateQuestTab()
    local questTab = Window:AddTab({
        Name = "Quests",
        Icon = "📜",
    })

   Event:CreateQuestSection(questTab)
end

return m