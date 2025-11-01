local m = {}

local Window
local Core
local Disable

function m:Init(_window, _core, _disable)
    Window = _window
    Core = _core
    Disable = _disable

    local tab = Window:AddTab({
        Name = "Misc",
        Icon = "🛠️",
    })

    self:DisableSection(tab)
    self:ServerSection(tab)
end

function m:DisableSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Remove",
        Icon = "❌",
        Default = false,
    })
    
    accordion:AddToggle({
        Name = "Remove Catch Fish Animation 🎣",
        Default = false,
        Flag = "DisableCatchFishAnimation",
        Callback = function(value)
            Disable:DisableCatchFishAnimation()
        end
    })

    accordion:AddToggle({
        Name = "Remove Player Name",
        Default = false,
        Flag = "DisablePlayerName",
        Callback = function(value)
            Disable:DisablePlayerName()
        end
    })

    accordion:AddToggle({
        Name = "Remove Notifications 🔕",
        Default = false,
        Flag = "DisableNotifications",
        Callback = function(value)
            Disable:DisableNotifications()
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