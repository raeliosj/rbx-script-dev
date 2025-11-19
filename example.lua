-- Import library
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()
local Player = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/rbx-script-dev/refs/heads/main/module/player.lua'))()

local window = EzUI.CreateWindow({
	Name = "RaeliosHUB", -- Name of the window
	Width = 700, -- Optional: Override default calculated width
	Height = 400, -- Optional: Override default calculated height
	Opacity = 0.9,  -- 0.1 to 1.0 (10% to 100%)
	AutoAdapt = true, -- Optional: Auto-resize on viewport changes (default true)
	AutoShow = false, -- Start hidden, can be shown later
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "RaeliosHUB", -- Name of the window -- Custom folder name
		FileName = "settings", -- Custom file name
		AutoLoad = true, -- Auto-load on window creation
		AutoSave = true, -- Auto-save on window close
	},
})

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

    accordion:AddNumberBox({
        Name = "Cancel Delay",
        Placeholder = "Cancel Delay...",
        Default = 1.3,
        Min = 0.1,
        Max = 20.0,
        Increment = 0.001,
        Decimals = 3,
        Flag = "CancelDelay",
    })

    accordion:AddNumberBox({
        Name = "Complete Delay",
        Placeholder = "Complete Delay...",
        Default = 1.7,
        Min = 0.1,
        Max = 20.0,
        Increment = 0.001,
        Decimals = 3,
        Flag = "CompleteDelay",
    })
    
    accordion:AddSeparator()

    accordion:AddSelectBox({
        Name = "Charge Fishing Method ⚡",
        Options = {"Toggle Auto", "Use Delay", "None"},
        Default = "Auto Charge",
        Placeholder = "Select Charge Fishing Method",
        MultiSelect = false,
        Flag = "ChargeFishingMethod",
    })

    accordion:AddSelectBox({
        Name = "Complete Fishing Method ✅",
        Options = {"Looping", "Use Delay"},
        Default = "Use Delay",
        Placeholder = "Select Complete Fishing Method",
        MultiSelect = false,
        Flag = "CompleteFishingMethod",
    })

    accordion:AddSelectBox({
        Name = "Fishing Method to Use 🎣",
        Options = {"Fast", "Instant"},
        Default = "",
        Placeholder = "Select Fishing Method",
        MultiSelect = false,
        Flag = "AutoFishingMethod",
    })

    accordion:AddSeparator()
    
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

    accordion:AddButton({
        Name = "Stop Auto Fishing Now 🛑",
        Variant = "warning",
        Callback = function()
            Fishing:StopAutoFishing()
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

local m = {}

local Window
local Core
local Webhook

local TierData

function m:Init(_window, _core, _webhook)
    Window = _window
    Core = _core
    Webhook = _webhook

    TierData = require(Core.ReplicatedStorage.Tiers)

    local tab = Window:AddTab({
        Name = "Notifications",
        Icon = "🔔",
    })

    self:DiscordSection(tab)
end

function m:DiscordSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Discord Webhook",
        Icon = "🌐",
        Default = true,
    })

    accordion:AddTextBox({
        Name = "Discord Webhook URL (for notifications)",
        Default = "",
        Flag = "DiscordWebhookURL",
        Placeholder = "https://discord.com/api/webhooks/...",
        MaxLength = 500,
    })

    accordion:AddTextBox({
        Name = "Discord Ping ID (optional)",
        Default = "",
        Flag = "DiscordPingID",
        Placeholder = "123456789012345678",
        MaxLength = 50,
    })

    accordion:AddButton({
        Text = "Test Notification",
        Callback = function()
            task.spawn(function()
                Webhook:TestWebhook()
            end)
        end
    })

    accordion:AddSelectBox({
        Name = "Minimum Rarity for Notifications",
        Options = {"Loading ..."},
        Placeholder = "Select Minimum Rarity",
        Flag = "NotificationMinRarity",
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
        Name = "Enable Discord Webhook 🔔",
        Default = false,
        Flag = "EnableDiscordWebhook",
    })
end

return m

local m = {}

local Window
local Core
local TravelingMerchant

function m:Init(_window, _core, _travelingMerchant)
    Window = _window
    Core = _core
    TravelingMerchant = _travelingMerchant

    local tab = Window:AddTab({
        Name = "Shop",
        Icon = "🛒",
    })
    self:TravelingMerchantSection(tab)
end

function m:TravelingMerchantSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Traveling Merchant",
        Icon = "🚚",
        Default = false,
    })

    local selecteditem = accordion:AddSelectBox({
        Name = "Items",
        Options = {"loading ..."},
        Placeholder = "Select Items to Buy",
        MultiSelect = false,
        OnDropdownOpen =  function(currentOptions, updateOptions)
            local listItems = TravelingMerchant:GetListItems() or {}
            local formattedItems = {}

            for _, itemInfo in pairs(listItems) do
                table.insert(formattedItems, {text = string.format("[%s] %s - %s Coins %s", itemInfo.Rarity, itemInfo.Name, Core:FormatNumber(itemInfo.Price or 0), itemInfo.IsOwned and "(Owned)" or "(Not Owned)"), value = itemInfo.Id})
            end

            updateOptions(formattedItems)
        end
    })

    accordion:AddButton({
        Name = "Purchase Selected Item",
        Description = "Purchase the selected item from the Traveling Merchant.",
        Callback = function()
            local itemId = selecteditem:GetSelected()[1]
            if not itemId then
                Window:ShowError(
                    "Traveling Merchant",
                    "Please select an item to purchase.",
                    5000
                )
                return
            end

            local success, response = TravelingMerchant:PurchaseItem(itemId)
            if success then
                Window:ShowInfo(
                    "Traveling Merchant",
                    "Successfully purchased the item!",
                    5000
                )
            else
                Window:ShowWarning(
                    "Traveling Merchant",
                    "Failed to purchase the item: " .. tostring(response),
                    5000
                )
            end
        end
    })
end

return m

local m = {}

local Window
local Core
local Player
local NPC
local Spot
local CustomPositionConfig
local TeleportEvent

function m:Init(_window, _core, _player, _npc, _spot, _customPositionConfig, _teleportEvent)
    Window = _window
    Core = _core
    Player = _player
    NPC = _npc
    Spot = _spot
    CustomPositionConfig = _customPositionConfig
    TeleportEvent = _teleportEvent

    local tab = Window:AddTab({
        Name = "Teleport",
        Icon = "📍",
    })

    self:LockPositionSection(tab)
    self:EventSection(tab)
    self:FishingSpotsSection(tab)
    self:PlayerSection(tab)
    self:NPCSection(tab)
    self:CustomSection(tab)
end

function m:LockPositionSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Lock Position",
        Icon = "📌",
        Default = false,
    })

    local textBoxLockPotision = accordion:AddTextBox({
        Name = "Lock Position",
        Default = "",
        Placeholder = "Enter position...",
        Flag = "LockPlayerPosition",
        MaxLength = 200,
    })

    accordion:AddButton({
        Name = "Get Current Position",
        Callback = function()
            local position = Player:GetPosition()
            textBoxLockPotision:SetText(tostring(position))
        end
    })

    accordion:AddToggle({
        Name = "Lock Player 📌",
        Default = false,
        Flag = "LockPlayer",
    })
end

function m:FishingSpotsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Fishing Spots",
        Icon = "🎣",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Fishing Spot to Teleport",
        Options = {"Loading..."},
        Placeholder = "Select Fishing Spot...",
        MultiSelect = false,
        Flag = "TeleportToFishingSpot",
        OnInit = function(api, optionsData)
            local fishingSpots = Spot:GetAllFishingSpots()
            local formattedSpots = {}
            for _, spotData in pairs(fishingSpots) do
                table.insert(formattedSpots, {text = string.format("%s - [Base Luck: %.2f] [Power: %.2f]", spotData.Name, spotData.BaseLuck or 0, spotData.ClickPowerMultiplier or 0), value = spotData.Name})
            end

            table.sort(formattedSpots, function(a, b)
                return a.value < b.value
            end)
            optionsData.updateOptions(formattedSpots)
        end
    })

    accordion:AddButton({
        Name = "Teleport to Selected Fishing Spot",
        Callback = function()
            local selectedSpots = Window:GetConfigValue("TeleportToFishingSpot")
            if not selectedSpots then
                return
            end

            local spotData = Spot:FindSpotByName(selectedSpots)
            if not spotData then
                return
            end
            Player:TeleportToPosition(spotData.Position)
        end
    })
end

function m:EventSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Event Teleport",
        Icon = "🎉",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Event to Teleport",
        Options = {"Loading..."},
        Placeholder = "Select Event...",
        MultiSelect = false,
        Flag = "TeleportEvent",
        OnInit = function(api, optionsData)
            local events = TeleportEvent:GetListEvents()
            local formattedEvents = {}
            for _, eventData in pairs(events) do
                table.insert(formattedEvents, eventData.Name)
            end

            table.sort(formattedEvents)
            optionsData.updateOptions(formattedEvents)
        end
    })

    accordion:AddToggle({
        Name = "Auto Teleport to Event",
        Default = false,
        Flag = "AutoTeleportToEvent",
        Callback = function(value)
            TeleportEvent.IsOnEvent = value
            if value then
                TeleportEvent:TeleportToEvent()
            end
        end
    })
end

function m:PlayerSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Player",
        Icon = "🧑",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select Player to Teleport",
        Options = {"Loading..."},
        Placeholder = "Select Player...",
        MultiSelect = false,
        Flag = "TeleportToPlayerUsername",
        OnDropdownOpen = function(currentOptions, updateOptions)
            local players = Core.Players:GetChildren()
            local formattedPlayers = {}

            for _, playerData in pairs(players) do
                if playerData == Core.LocalPlayer then
                    continue
                end
                table.insert(formattedPlayers, playerData.Name)
            end

            table.sort(formattedPlayers)
            
            updateOptions(formattedPlayers)
        end
    })

    accordion:AddButton({
        Name = "Teleport to Player",
        Callback = function()
            local username = Window:GetConfigValue("TeleportToPlayerUsername")
            local players = Core.Players:GetChildren()

            if not username or username == "" then
                return
            end

            for _, playerData in pairs(players) do
                if playerData.Name == username then
                    local character = playerData.Character
                    if not character then
                        return
                    end

                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        return
                    end

                    Player:TeleportToPosition(hrp.CFrame)
                    return
                end
            end
        end
    })
end

function m:NPCSection(tab)
    local accordion = tab:AddAccordion({
        Title = "NPC",
        Icon = "👨‍👩‍👧‍👦",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Select NPC to Teleport",
        Options = {"Loading..."},
        Placeholder = "Select NPC...",
        MultiSelect = false,
        Flag = "TeleportToNPC",
        OnInit = function(api, optionsData)
            local npcs = NPC:ListNPCRepository()
            local formattedNpcs = {}
            for _, npcData in pairs(npcs) do
                table.insert(formattedNpcs, npcData.Name)
            end

            table.sort(formattedNpcs)
            optionsData.updateOptions(formattedNpcs)
        end
    })

    accordion:AddButton({
        Name = "Teleport to Selected NPC",
        Callback = function()
            local selectedNpcs = Window:GetConfigValue("TeleportToNPC")
            if not selectedNpcs then
                return
            end

            local npcData = NPC:FindNPCByName(selectedNpcs)
            if not npcData then
                return
            end
            Player:TeleportToPosition(Vector3.new(npcData.Position.X, npcData.Position.Y + 5, npcData.Position.Z))
        end
    })
end

function m:CustomSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Custom Teleport",
        Icon = "🛠️",
        Default = false,
    })

    local textBoxPosition = accordion:AddTextBox({
        Name = "Custom Position",
        Default = "",
        Placeholder = "Enter position...",
        Flag = "CustomTeleportPosition",
        MaxLength = 200,
    })

    accordion:AddButton({
        Name = "Get Current Position",
        Callback = function()
            local position = Player:GetPosition()
            textBoxPosition:SetText(tostring(position))
        end
    })

    local textBoxPositionName = accordion:AddTextBox({
        Name = "Position Name",
        Default = "",
        Placeholder = "Enter a name for this position...",
        MaxLength = 50,
    })

    accordion:AddButton({
        Name = "Save Custom Position",
        Callback = function()
            local position = textBoxPosition:GetText()
            local positionName = textBoxPositionName:GetText()
            if not position or positionName == "" then
                return
            end

            CustomPositionConfig:SetValue(positionName, position)
            
            position.Clear()
            positionName.Clear()
        end
    })

    accordion:AddSeparator()

    accordion:AddSelectBox({
        Name = "Select Custom Position to Teleport",
        Options = {"Loading..."},
        Placeholder = "Select Custom Position...",
        MultiSelect = false,
        Flag = "TeleportToCustomPosition",
        OnDropdownOpen = function(currentOptions, updateOptions)
            local customPositions = CustomPositionConfig:GetAllKeys()
            table.sort(customPositions)
            updateOptions(customPositions)
        end
    })

    accordion:AddButton({
        Name = "Teleport to Selected Custom Position",
        Callback = function()
            local selectedPositionName = Window:GetConfigValue("TeleportToCustomPosition")
            if not selectedPositionName then
                return
            end

            local positionString = CustomPositionConfig:GetValue(selectedPositionName)
            if not positionString then
                return
            end

            local position = load("return " .. positionString)()
            if not position then
                return
            end

            Player:TeleportToPosition(position)
        end
    })

    accordion:AddButton({
        Name = "Delete Selected Custom Position",
        variant = "danger",
        Callback = function()
            local selectedPositionName = Window:GetConfigValue("TeleportToCustomPosition")
            if not selectedPositionName then
                return
            end

            CustomPositionConfig:DeleteKey(selectedPositionName)
        end
    })
end

return m
