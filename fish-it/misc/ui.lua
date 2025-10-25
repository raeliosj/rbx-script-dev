local m = {}

local Window
local Core
local Animation

function m:Init(_window, _core, _animation)
    Window = _window
    Core = _core
    Animation = _animation

    local tab = Window:AddTab({
        Name = "Misc",
        Icon = "🛠️",
    })

    self:AnimationSection(tab)
    self:ServerSection(tab)
end

function m:AnimationSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Animations",
        Icon = "🎬",
        Default = false,
    })

    accordion:AddToggle({
        Name = "Disable Catch Fish Animation 🎣",
        Default = false,
        Flag = "DisableCatchFishAnimation",
        Callback = function(value)
            Animation:DisableCatchFishAnimation()
        end
    })
end

function m:ServerSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Server",
        Icon = "🌐",
        Default = false,
    })

    accordion:AddButton({Text = "Rejoin Server 🔄", Callback = function()
        Core:Rejoin()
    end})

    accordion:AddButton({Text = "Hop Server 🚀", Callback = function()
        Core:HopServer()
    end})
end

return m