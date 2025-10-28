local m = {}

local Window
local Core
local Fishing
local Inventory

local TierData

function m:Init(_window, _core, _fishing, _inventory)
    Window = _window
    Core = _core
    Fishing = _fishing
    Inventory = _inventory

    local tab = Window:AddTab({
        Name = "Farm",
        Icon = "💵",
    })

    TierData = require(Core.ReplicatedStorage.Tiers)

    self:FishingSection(tab)
    self:SellSection(tab)
    self:FavoriteSection(tab)
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
        Default = false,
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
    })

    accordion:AddButton({
        Name = "Sell All Fish Now",
        Variant = "warning",
        Callback = function()
            Inventory:SellAllFish()
        end
    })
end

function m:FavoriteSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Favorite",
        Icon = "⭐",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Minimum Rarity to Favorite",
        Options = {"Loading ..."},
        Placeholder = "Select Minimum Rarity",
        MultiSelect = false,
        Flag = "FavoriteMinRarityFish",
        OnInit = function(api, optionsData)
            local formattedTiers = {}

            for _, tierDetail in pairs(TierData) do
                table.insert(formattedTiers, {
                    text = tierDetail.Name,
                    value = tierDetail.Tier,
                })
            end

            optionsData.updateOptions(formattedTiers)
        end,
    })

    accordion:AddSelectBox({
        Name = "Or Fish Name",
        Options = {"Loading ..."},
        Placeholder = "Select Fish Name",
        MultiSelect = true,
        Flag = "FavoriteFishName",
        OnInit = function(api, optionsData)
            local fishData = Inventory.ListFish
            local formattedFish = {}

            for _, fishDetail in pairs(fishData) do
                table.insert(formattedFish, {
                    text = string.format("[%s] - %s [Base Price: %s]", fishDetail.Rarity, fishDetail.Name, string.format("%0.2f", fishDetail.SellPrice):gsub("%.", ".")),
                    value = fishDetail.Name,
                })
            end
            optionsData.updateOptions(formattedFish)
        end,
    })

    accordion:AddToggle({
        Name = "Auto Favorite Fish",
        Default = false,
        Flag = "AutoFavoriteFish"
    })

end

return m