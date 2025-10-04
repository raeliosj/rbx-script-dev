local m = {}
local Window
local PetTeam
local Egg
local Pet
local Garden
local Player

function m:Init(_window, _petTeam, _egg, _pet, _garden, _player)
    Window = _window
    PetTeam = _petTeam
    Egg = _egg
    Pet = _pet
    Garden = _garden
    Player = _player
end

function m:CreatePetTab()
    local tab = Window:AddTab({
        Name = "Pet",
        Icon = "😺",
    })

    tab:AddButton("Boost All Active Pets 💪", function()
        Pet:BoostAllActivePets()
    end)

    self:AddPetTeamsSection(tab)
    self:AddEggsSection(tab)
    self:AddSellSection(tab)
end

function m:AddPetTeamsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Pet Teams",
        Icon = "🛠️",
        Expanded = false,
    })

    accordion:AddLabel("Create and manage pet teams for different tasks.")
    local petTeamName = accordion:AddTextBox({
        Name = "Team Name",
        Placeholder = "Enter team name example: exp, hatch, sell, etc...",
        Default = "",
    })

    accordion:AddButton("Save Team", function()
        local teamName = petTeamName.GetText()
        if teamName and teamName ~= "" then
            print("Please enter a valid team name.")
        end

        local activePets = Pet:GetAllActivePets()
        if not activePets then
            print("No active pets found.")
            return
        end

        local listActivePets = {}
        for petID, petState in pairs(activePets) do
            table.insert(listActivePets, petID)
        end

        print("Creating pet team:", teamName)
        PetTeam:SaveTeamPets(teamName, listActivePets)
        petTeamName.Clear()
    end)

    accordion:AddSeparator()

    accordion:AddLabel("Select a pet team to set as core, change, or delete.")
    
    local selectTeam = accordion:AddSelectBox({
        Name = "Select Pet Team",
        Options = PetTeam:GetAllPetTeams(),
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    -- Declare labelCoreTeam variable first (forward declaration)
    local labelCoreTeam

    accordion:AddButton("Set Core Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            Window:SetConfigValue("CorePetTeam", teamName)
            labelCoreTeam.SetText("Current Core Team: " .. teamName)
        end    
    end)

    -- Create the label after the button
    labelCoreTeam = accordion:AddLabel("Current Core Team: " .. (Window:GetConfigValue("CorePetTeam") or "None"))

    accordion:AddSeparator()

    
    accordion:AddButton("Change Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            print("Changing to pet team:", teamName)
            Pet:ChangeTeamPets(teamName)    
        end
    end)

    accordion:AddButton("Delete Selected Team", function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            PetTeam:DeleteTeamPets(teamName)
            selectTeam.Clear()
        end
    end)
end

function m:AddEggsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Eggs",
        Icon = "🥚",
        Expanded = false,
    })

    accordion:AddLabel("Select an egg to place in your farm.")
    accordion:AddSelectBox({
        Name = "Select Egg",
        Options = {"Loading..."},
        Placeholder = "Select Egg...",
        MultiSelect = false,
        Flag = "EggPlacing",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local formattedEggs = {}

            local OwnedEggs = Egg:GetEggRegistry()
            for egg, _ in pairs(OwnedEggs) do
                table.insert(formattedEggs, {text = egg, value = egg})
            end

            -- Sort eggs alphabetically (ascending order)
            if #formattedEggs > 0 then
                table.sort(formattedEggs, function(a, b)
                    if not a or not b or not a.text or not b.text then
                        return false
                    end
                    return string.lower(tostring(a.text)) < string.lower(tostring(b.text))
                end)
            end

            updateOptions(formattedEggs)
        end
    })

    accordion:AddLabel("Max Place Eggs")
    accordion:AddNumberBox({
        Name = "Max Place Eggs",
        Placeholder = "Enter max eggs...",
        Default = 0,
        Min = 0,
        Max = 13,
        Increment = 1,
        Flag = "MaxPlaceEggs",
    })

    accordion:AddLabel("Position to Place Eggs")
    accordion:AddSelectBox({
        Name = "Position to Place Eggs",
        Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Random",
        MultiSelect = false,
        Placeholder = "Select position...",
        Flag = "PositionToPlaceEggs",
    })

    accordion:AddButton("Place Selected Egg", function()
        Egg:PlacingEgg()    
    end)

    accordion:AddSeparator()

    accordion:AddLabel("Team for Hatching Eggs")

    accordion:AddSelectBox({
        Name = "Select Pet Team for Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "HatchPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    accordion:AddToggle({
        Name = "Auto Boost Pets Before Hatching",
        Default = false,
        Flag = "AutoBoostBeforeHatch",
    })

    accordion:AddSeparator()

    accordion:AddLabel("Select Hatching Special Pet")
    accordion:AddSelectBox({
        Name = "Select Special Pet",
        Options = {"Loading..."},
        Placeholder = "Select Special Pet...",
        MultiSelect = true,
        Flag = "SpecialHatchingPet",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local specialPets = Pet:GetPetRegistry()
            updateOptions(specialPets)
        end
    })
    
    accordion:AddLabel("Or If Weight is Higher Than")
    accordion:AddNumberBox({
        Name = "Weight Threshold",
        Placeholder = "Enter weight...",
        Default = 0.0,
        Min = 0.0,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "WeightThresholdSpecialHatching",
    })

    accordion:AddLabel("Select Team for Special Hatching")
    accordion:AddSelectBox({
        Name = "Select Pet Team for Special Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SpecialHatchPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end
    })

    accordion:AddToggle({
        Name = "Auto Boost Pets Before Special Hatching",
        Default = false,
        Flag = "AutoBoostBeforeSpecialHatch",
    })

    accordion:AddSeparator()

    accordion:AddToggle({
        Name = "Auto Hatch Eggs",
        Default = false,
        Flag = "AutoHatchEggs",
        Callback = function(value)
            if value then
                Egg:StartAutoHatching()
            end
        end
    })
end

function m:AddSellSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Sell Pets",
        Icon = "💰",
        Expanded = false,
    })

    accordion:AddLabel("Select a pet to sell.")
    accordion:AddSelectBox({
        Name = "Select Pet to Sell",
        Options = {"Loading..."},
        Placeholder = "Select Pet...",
        MultiSelect = true,
        Flag = "PetToSell",
        OnInit = function(currentOptions, updateOptions, selectBoxAPI)
            local specialPets = Pet:GetPetRegistry()
            updateOptions(specialPets)
        end,
    })

    accordion:AddLabel("And If Base Weight Is Less Than Or Equal")
    accordion:AddNumberBox({
        Name = "Weight Threshold",
        Placeholder = "Enter weight...",
        Default = 1.0,
        Min = 0.5,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "WeightThresholdSellPet",
    })

    accordion:AddLabel("And If Age Is Less Than Or Equal")
    accordion:AddNumberBox({
        Name = "Age Threshold (in days)",
        Placeholder = "Enter age...",
        Default = 1,
        Min = 1,
        Max = 100,
        Increment = 1,
        Flag = "AgeThresholdSellPet",
    })

    accordion:AddLabel("Pet Team to Use for Selling")
    accordion:AddSelectBox({
        Name = "Select Pet Team for Sell",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SellPetTeam",
        OnInit = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })
    accordion:AddToggle({
        Name = "Auto Boost Pets Before Selling",
        Default = false,
        Flag = "AutoBoostBeforeSelling",
    })

    accordion:AddToggle({
        Name = "Auto Sell Pets After Hatching",
        Default = false,
        Flag = "AutoSellPetsAfterHatching",
    })

    accordion:AddButton("Sell Selected Pet", function()
        Pet:SellPet()
    end)
end

return m