local m = {}

local Window
local Core
local Fishing
local Sell

function m:Init(_window, _core, _fishing, _sell)
    Window = _window
    Core = _core
    Fishing = _fishing
    Sell = _sell

    local tab = Window:AddTab({
        Name = "Farm",
        Icon = "💵",
    })

    self:FishingSection(tab)
    self:SellSection(tab)
end

function m:FishingSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Fishing",
        Icon = "🎣",
        Default = false,
    })

    accordion:AddToggle({
        Name = "Auto Equip Fishing Rod 🎣",
        Default = false,
        Flag = "AutoEquipFishingRod",
    })

    accordion:AddToggle({
        Name = "Auto Perfect Cast 🎯",
        Default = true,
        Flag = "AutoPerfectCast",
    })

    accordion:AddToggle({
        Name = "Auto Fishing 🎣",
        Default = false,
        Flag = "AutoFishing",
        Callback = function(value)
            if value then
                Fishing:StartAutoFishing()
            else
                Fishing:StopAutoFishing()
            end
        end
    })

    accordion:AddSeparator()

    accordion:AddNumberBox({
        Name = "Delay between casts ⛵",
        Placeholder = "Delay between casts...",
        Default = 1.30,
        Min = 0.1,
        Max = 20.0,
        Increment = 0.01,
        Decimals = 2,
        Flag = "AutoInstantCatchDelay",
    })

    accordion:AddToggle({
        Name = "Auto Instant Catch 🐟",
        Default = false,    
        Flag = "AutoInstantCatch",
        Callback = function(value)
            if value then
                Fishing:StartAutoCharge()
            else
                Fishing:StopAutoFishing()
            end
        end
    })


end

function m:SellSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Sell",
        Icon = "💰",
        Default = false,
    })

    accordion:AddNumberBox({
        Name = "Auto Sell Fish Count",
        Placeholder = "Number of fish to auto sell at...",
        Default = 50,
        Min = 1,
        Max = 1000,
        Increment = 1,
        Decimals = 0,
        Flag = "AutoSellFishCount",
    })

    accordion:AddToggle({
        Name = "Automatically sell all fish",
        Default = false,
        Flag = "AutoSellFish",
        Callback = function(value)
            if value then
                Sell:CreateConnections()
            else
                Sell:RemoveConnections()
            end
        end
    })

    accordion:AddButton({
        Name = "Sell All Fish Now",
        Variant = "warning",
        Callback = function()
            Sell:SellAllFish()
        end
    })
end

return m