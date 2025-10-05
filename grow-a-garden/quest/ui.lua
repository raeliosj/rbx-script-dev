local m = {}
local Window

function m:Init(_window)
    Window = _window
end

function m:CreateQuestTab()
    local tab = Window:AddTab({
        Name = "Quests",
        Icon = "📜",
    })
end

return m