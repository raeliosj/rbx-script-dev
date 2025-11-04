local m = {}

local Window
local Core
local Events
local Enchant
local Trade

local TierData

function m:Init(_window, _core, _events, _enchant, _trade)
    Window = _window
    Core = _core
    Events = _events
    Enchant = _enchant
    Trade = _trade

    TierData = require(Core.ReplicatedStorage.Tiers)

    local tab = Window:AddTab({
        Name = "AutoMation",
        Icon = "🤖",
    })

    self:HelloweenSection(tab)
    self:WeatherMachineSection(tab)
    self:EnchantSection(tab)
    self:TradeSection(tab)
end

function m:HelloweenSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Halloween",
        Icon = "🎃",
        Default = false,
    })

    accordion:AddToggle({
        Name = "Auto Trick Or Treat 🎃",
        Default = false,
        Flag = "AutoTrickOrTreat",
    })
end

function m:WeatherMachineSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Weather Machine",
        Icon = "☁️",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Weather Machine ☁️",
        Options = {"loading ..."},
        Placeholder = "Select Weather Machine",
        MultiSelect = true,
        Flag = "WeatherMachineItem",
        OnInit =  function(api, optionsData)
            local weatherMachines = Events:GetListWeathersMachine() or {}
            local formattedWeathers = {}
            for _, weatherData in pairs(weatherMachines) do
                table.insert(formattedWeathers, {
                    text = string.format("[%s] %s - %s Coins (%s)", weatherData.Tier, weatherData.Name, tostring(weatherData.Price):reverse():gsub("%d%d%d", "%1."):reverse():gsub("^%.", ""), weatherData.Description),
                    value = weatherData.Name
                })
            end
            optionsData.updateOptions(formattedWeathers)
        end
    })

    accordion:AddButton({
        Name = "Buy Selected Weather Machine ☁️",
        Callback = function()
            local selectedWeathers = Window:GetConfigValue("WeatherMachineItem") or {}
            for _, weatherName in pairs(selectedWeathers) do
                Events:BuyWeatherMachine(weatherName)
            end
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Weather Machine ☁️",
        Default = false,
        Flag = "AutoBuyWeatherMachine",
    })
end

function m:EnchantSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Auto Enchant",
        Icon = "✨",
        Default = false,
    })

    accordion:AddLabel("")
    accordion:AddLabel(function()
        local currentRod = Enchant:GetCurrentRodDetails()

        return string.format("Current Rod: %s\nEnchant 1: %s \nEnchant 2: %s", currentRod.Name or "N/A", currentRod.Enchant1 or "None", currentRod.Enchant2 or "None")
    end)
    accordion:AddLabel("")

    accordion:AddSeparator()

    accordion:AddLabel("Enchant 1")
    accordion:AddSelectBox({
        Name = "Select Target Enchant",
        Options = Enchant:GetListEnchant(),
        Placeholder = "Select Enchant...",
        MultiSelect = true,
        Flag = "TargetEnchant1",
        Default = "",
    })

    accordion:AddToggle({
        Name = "Auto Enchant",
        Default = false,
        Flag = "AutoEnchant1",
    })

    accordion:AddSeparator()

    accordion:AddLabel("Enchant 2")

    accordion:AddSelectBox({
        Name = "Select Secret Fish",
        Options = {"loading ..."},
        Placeholder = "Select Secret Fish For Convert To Transcended Stone...",
        MultiSelect = true,
        Flag = "SecretFishForTranscendedStone",
        OnInit = function(api, optionsData)
            local secretFish = Enchant:GetListSecretFish() or {}
            local formattedSecretFish = {}

            for _, fishData in pairs(secretFish) do
                table.insert(formattedSecretFish, {text = string.format("[%s] %s (%s) %s", fishData.Chance, fishData.Name, fishData.Mutations, fishData.IsFavorite and "❤️" or ""), value = fishData.UUID})
            end
            optionsData.updateOptions(formattedSecretFish)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local secretFish = Enchant:GetListSecretFish() or {}
            local formattedSecretFish = {}

            for _, fishData in pairs(secretFish) do
                table.insert(formattedSecretFish, {text = string.format("[%s] %s (%s) %s", fishData.Chance, fishData.Name, fishData.Mutations, fishData.IsFavorite and "❤️" or ""), value = fishData.UUID})
            end
            updateOptions(formattedSecretFish)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Target Enchant",
        Options = Enchant:GetListEnchant(),
        Placeholder = "Select Enchant...",
        MultiSelect = true,
        Flag = "TargetEnchant2",
        Default = "",
    })

    accordion:AddToggle({
        Name = "Auto Enchant",
        Default = false,
        Flag = "AutoEnchant2",
    })
end

function m:TradeSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Auto Trade",
        Icon = "🤝",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Player to Give",
        Options = {"loading ..."},
        Placeholder = "Select Player...",
        MultiSelect = false,
        Flag = "GiveToPlayer",
        OnDropdownOpen = function(currentOptions, updateOptions)
            local players = Core.Players:GetChildren()
            local formattedPlayers = {}

            for _, playerData in pairs(players) do
                if playerData == Core.LocalPlayer then
                    continue
                end
                table.insert(formattedPlayers, {text = playerData.Name, value = playerData.UserId})
            end

            table.sort(formattedPlayers, function(a, b)
                return a.text < b.text
            end)

            updateOptions(formattedPlayers)
        end
    })

    accordion:AddSelectBox({
        Name = "Select Item to Give",
        Options = {"loading ..."},
        Placeholder = "Select Item...",
        MultiSelect = true,
        Flag = "GiveItem",
        OnInit = function(api, optionsData)
            local itemData = Trade.TradeItems
            local formattedItems = {}

            for _, itemDetail in pairs(itemData) do
                table.insert(formattedItems, {
                    text = string.format("[%s] - %s [Type: %s]", itemDetail.Rarity, itemDetail.Name, itemDetail.Type),
                    value = itemDetail.Name,
                })
            end
            optionsData.updateOptions(formattedItems)
        end,
    })

    accordion:AddSelectBox({
        Name = "Or Minimum Rarity to Give",
        Options = {"loading ..."},
        Placeholder = "Select Minimum Rarity",
        MultiSelect = false,
        Flag = "GiveMinRarityItems",
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

    accordion:AddToggle({
        Name = "Don't Give Favorite Items",
        Default = false,
        Flag = "DontGiveFavoriteItems",
    })

    accordion:AddToggle({
        Name = "Auto Give Items",
        Default = false,
        Flag = "AutoGiveItems",
        OnToggle = function(value)
            if value then
                Trade:StartAutoGive()
            end
        end,
    })

    accordion:AddSeparator()

    accordion:AddToggle({
        Name = "Auto Accept Incoming Trades",
        Default = false,
        Flag = "AutoAcceptTrades",
    })
end

return m