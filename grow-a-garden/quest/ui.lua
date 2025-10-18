local m = {}
local Window
local Core
local Ascension


local AscensionItem = {
    Name = "N/A",
    Amount = 0,
    Mutations = "N/A",
    IsEligibleToSubmit = false,
    NextRebirthSubmitTime = 0
}

function m:Init(_window, _core, _ascension)
    Window = _window
    Core = _core
    Ascension = _ascension

    AscensionItem = Ascension:GetQuestDetail()
    self:CreateQuestTab()
end

function m:CreateQuestTab()
    local tab = Window:AddTab({
        Name = "Quests",
        Icon = "📜",
    })

    self:AscensionSection(tab)
    self:SeasonPassSection(tab)
end

local function getTimeRemaining()
    if not AscensionItem.NextRebirthSubmitTime then
        return "N/A"
    end

    if AscensionItem.IsEligibleToSubmit then
        return "Ready"
    end

    local remainingSeconds = AscensionItem.NextRebirthSubmitTime - tick()
    if remainingSeconds <= 0 then
        return "Ready"
    end

    local hours = math.floor(remainingSeconds / 3600)
    local minutes = math.floor((remainingSeconds % 3600) / 60)
    local seconds = remainingSeconds % 60
    local parseTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

    return parseTime
end

function m:AscensionSection(tab)
    local accordion = tab:AddAccordion({
        Name = "Ascension",
        Icon = "🔃",
        Expanded = false,
        Callback = function(isExpanded)
            if not isExpanded then
                return
            end

            local ascensionItem = Ascension:GetQuestDetail()

            if not ascensionItem then
                return
            end

            if ascensionItem.Name ~= AscensionItem.Name or
               ascensionItem.Mutations ~= AscensionItem.Mutations then
                AscensionItem = ascensionItem
            end
        end,
    })

    accordion:AddLabel(function()
        return "Current Quest: ".. AscensionItem.Amount .. " " .. AscensionItem.Name .. " (" .. (AscensionItem.Mutations ~= "" and AscensionItem.Mutations or "No Mutation") .. ")"
    end)
    accordion:AddLabel(function()
        return "Next Rebirth Submit Time: " .. getTimeRemaining()
    end)
    
    accordion:AddSelectBox({
        Name = "Position planting seeds",
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

function m:SeasonPassSection(tab)
    local accordion = tab:AddAccordion({
        Name = "Season Pass",
        Icon = "🎟️",
        Expanded = false,
    })

    accordion:AddToggle({
        Name = "Auto Claim Infinity Rewards",
        Default = false,
        Flag = "AutoClaimSeasonPassInfinityRewards",
        Tooltip = "Automatically claim season pass infinity rewards.",
    })

    accordion:AddToggle({
        Name = "Auto Claim Completed Quests",
        Default = false,
        Flag = "AutoClaimSeasonPassQuest",
        Tooltip = "Automatically claim completed season pass quests.",
    })
end

return m