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

    self:CreateServerTab()
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

    self:GameUpdateSection(tab)
end

function m:GameUpdateSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Game Updates",
        Icon = "📰",
        Default = false,
    })

    accordion:AddButton({Text = "Force Update", Callback = function()
        local listUpdate = Core.ReplicatedStorage.Modules.UpdateService
        local Workspace = game:GetService("Workspace")

        for _, v in pairs(listUpdate:GetChildren()) do
            v:Clone().Parent = Workspace
        end
        
    end})
end

return m