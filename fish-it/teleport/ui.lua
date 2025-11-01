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