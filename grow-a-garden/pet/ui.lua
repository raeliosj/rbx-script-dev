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

    self:AddPetTeamsSection(tab)
    self:AddEggsSection(tab)
    self:AddSellSection(tab)
    self:BoostPetsSection(tab)
end

function m:AddPetTeamsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Pet Teams",
        Icon = "🛠️",
        Expanded = false,
    })

    local petTeamName = accordion:AddTextBox({
        Name = "Team Name",
        Placeholder = "Enter team name example: exp, hatch, sell, etc...",
        Default = "",
    })

    accordion:AddButton({Text = "Save Team", Callback = function()
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
    end})

    accordion:AddSeparator()

    local selectTeam = accordion:AddSelectBox({
        Name = "Select a pet team to set as core, change, or delete.",
        Options = PetTeam:GetAllPetTeams(),
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            print("Get total pet teams:", #listTeamPet)
            
            for _, team in pairs(listTeamPet) do
                print("Found pet team:", team)
                table.insert(currentOptionsSet, {text = team, value = team})
            end
                    
            updateOptions(currentOptionsSet)
        end
    })

    -- Declare labelCoreTeam variable first (forward declaration)
    local labelCoreTeam

    accordion:AddButton({Text = "Set Core Team", Callback = function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            Window:SetConfigValue("CorePetTeam", teamName)
            labelCoreTeam:SetText("Current Core Team: " .. teamName)
        end    
    end})

    -- Create the label after the button
    labelCoreTeam = accordion:AddLabel("Current Core Team: " .. (Window:GetConfigValue("CorePetTeam") or "None"))

    accordion:AddSeparator()

    accordion:AddButton({Text = "Change Team", Callback = function()
        local selectedTeam = selectTeam.GetSelected()
        if selectedTeam and #selectedTeam > 0 then
            local teamName = selectedTeam[1]
            print("Changing to pet team:", teamName)
            Pet:ChangeTeamPets(teamName)    
        end
    end})

    accordion:AddButton({
        Text = "Delete Selected Team",
        Variant = "danger",
        Callback = function()
            local selectedTeam = selectTeam.GetSelected()
            if selectedTeam and #selectedTeam > 0 then
                local teamName = selectedTeam[1]
                PetTeam:DeleteTeamPets(teamName)
                selectTeam.Clear()
            end
        end
    })
end

function m:AddEggsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Eggs",
        Icon = "🥚",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select an egg to place in your farm",
        Options = {"Loading..."},
        Placeholder = "Select Egg...",
        MultiSelect = false,
        Flag = "EggPlacing",
       OnInit = function(api, optionsData)
            local formattedEggs = {}

            local listdEggs = Egg:GetEggRegistry()
            for egg, _ in pairs(listdEggs) do
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

            optionsData.updateOptions(formattedEggs)
        end
    })

    accordion:AddNumberBox({
        Name = "Max Place Eggs",
        Placeholder = "Enter max eggs...",
        Default = 0,
        Min = 0,
        Max = 13,
        Increment = 1,
        Flag = "MaxPlaceEggs",
    })

    accordion:AddSelectBox({
        Name = "Position to Place Eggs",
        Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
        Default = "Random",
        MultiSelect = false,
        Placeholder = "Select position...",
        Flag = "PositionToPlaceEggs",
    })

    accordion:AddButton({Text = "Place Selected Egg", Callback = function()
        Egg:PlacingEgg()    
    end})

    accordion:AddSeparator()

    accordion:AddSelectBox({
        Name = "Select Pet Team for Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "HatchPetTeam",
        OnInit = function(api, optionsData)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            optionsData.updateOptions(currentOptionsSet)
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

    accordion:AddSelectBox({
        Name = "Select Special Pet",
        Options = {"Loading..."},
        Placeholder = "Select Special Pet...",
        MultiSelect = true,
        Flag = "SpecialHatchingPet",
       OnInit = function(api, optionsData)
            local specialPets = Pet:GetPetRegistry()
            optionsData.updateOptions(specialPets)
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

    accordion:AddSelectBox({
        Name = "Select Pet Team for Special Hatch",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SpecialHatchPetTeam",
        OnInit = function(api, optionsData)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}

            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            optionsData.updateOptions(currentOptionsSet)
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

    accordion:AddSelectBox({
        Name = "Select Pet to Sell",
        Options = {"Loading..."},
        Placeholder = "Select Pet...",
        MultiSelect = true,
        Flag = "PetToSell",
       OnInit = function(api, optionsData)
            local specialPets = Pet:GetPetRegistry()
            optionsData.updateOptions(specialPets)
        end,
    })

    accordion:AddNumberBox({
        Name = "And If Base Weight Is Less Than Or Equal",
        Placeholder = "Enter weight...",
        Default = 1.0,
        Min = 0.5,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "WeightThresholdSellPet",
    })

    accordion:AddNumberBox({
        Name = "And If Age Is Less Than Or Equal",
        Placeholder = "Enter age...",
        Default = 1,
        Min = 1,
        Max = 100,
        Increment = 1,
        Flag = "AgeThresholdSellPet",
    })

    accordion:AddSelectBox({
        Name = "Pet Team to Use for Selling",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = false,
        Flag = "SellPetTeam",
        OnInit = function(api, optionsData)
            local listTeamPet = PetTeam:GetAllPetTeams()
            local currentOptionsSet = {}
            for _, team in pairs(listTeamPet) do
                table.insert(currentOptionsSet, {text = team, value = team})
            end
            optionsData.updateOptions(currentOptionsSet)
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

    accordion:AddButton(
        {
            Text = "Sell Selected Pet",
            Variant = "warning",
            Callback = function()
                Pet:SellPet()
            end
        }
    )
end

function m:BoostPetsSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Boost Pets",
        Icon = "⚡",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Pets Use for Boosting",
        Options = {"Loading..."},
        Placeholder = "Select Pet Team...",
        MultiSelect = true,
        Flag = "BoostPets",
        OnInit = function(api, optionsData)
            local pets = Pet:GetAllMyPets()
            local currentOptionsSet = {}

            for _, pet in pairs(pets) do
                table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
            end
            optionsData.updateOptions(currentOptionsSet)
        end,
        OnDropdownOpen = function(currentOptions, updateOptions)
            local pets = Pet:GetAllMyPets()
            local currentOptionsSet = {}

            print("Total my pets:", #pets) -- Debug print

            for _, pet in pairs(pets) do
                print("Pet ID:", pet.ID) -- Debug print
                print("Type:", pet.Type, "Name:", pet.Name, "Age:", pet.Age, "Weight:", pet.BaseWeight, "Mutation:", pet.Mutation) -- Debug print
                print("-----")

                table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
            end
            updateOptions(currentOptionsSet)
        end
    })

    accordion:AddSelectBox({
        Name = "Boost Type",
        Options = {"Loading..."},
        Placeholder = "Select Boost Type...",
        MultiSelect = true,
        Flag = "BoostType",
        OnInit = function(api, optionsData)
            optionsData.updateOptions({
                {text = "Small Toy", value = "PASSIVE_BOOST-0.1"},
                {text = "Medium Toy", value = "PASSIVE_BOOST-0.2"},
            })
        end
    })

    accordion:AddButton({Text = "Boost Pets Now", Callback = function()
        Pet:BoostSelectedPets()
    end})

    accordion:AddToggle({
        Name = "Auto Boost Pets",
        Default = false,
        Flag = "AutoBoostPets",
        Callback = function(value)
            if value then
                Pet:AutoBoostSelectedPets()
            end
        end
    })
end

return m