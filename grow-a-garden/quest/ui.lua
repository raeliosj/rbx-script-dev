local m = {}
local Window
local Core
local Ascension
local ChubbyChipmunkUI

function m:Init(_window, _core, _ascension, _chubbyChipmunkUI)
    Window = _window
    Core = _core
    Ascension = _ascension
    ChubbyChipmunkUI = _chubbyChipmunkUI
end

function m:CreateQuestTab()
    local tab = Window:AddTab({
        Name = "Quests",
        Icon = "📜",
    })

    -- Chubby Chipmunk Event
    ChubbyChipmunkUI:AddQuestSection(tab)

    -- Ascension
    self:AscensionSection(tab)
end

function m:AscensionSection(tab)
    local accordion = tab:AddAccordion({
        Name = "Ascension",
        Icon = "🪙",
        Expanded = false,
    })

    accordion:AddLabel("Current Ascension Quest:")
    accordion:AddLabel(" - Item: " .. (Ascension.AscensionItem.Name or "N/A"))
    accordion:AddLabel(" - Amount: " .. (Ascension.AscensionItem.Amount or "N/A"))
    accordion:AddLabel(" - Mutations: " .. (Ascension.AscensionItem.Mutations or "N/A"))

    accordion:AddLabel("Position planting seeds:")
    accordion:AddSelectBox({
        Name = "Planting Position",
        Flag = "PlantingAscensionPosition",
        Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Random",
        MultiSelect = false,
        Placeholder = "Select position...",
    })

    accordion:AddToggle({
        Name = "Auto Ascend",
        Default = false,
        Flag = "AutoAscend",
        Tooltip = "Automatically ascend when the option is available.",
    })
end

return m