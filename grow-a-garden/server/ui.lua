local m = {}
local Window
local Core
local Player
local Garden

function m:Init(_window, _core, _player, _garden)
    Window = _window
    Core = _core
    Player = _player
    Garden = _garden
end

function m:CreateServerTab()
    local tab = Window:AddTab({
        Name = "Server",
        Icon = "🌐",
    })

    tab:AddButton({Text = "Rejoin Server 🔄", Callback = function()
        Core:Rejoin()
    end})

    tab:AddButton({Text = "Hop Server 🚀", Callback = function()
        Core:HopServer()
    end})
end

return m