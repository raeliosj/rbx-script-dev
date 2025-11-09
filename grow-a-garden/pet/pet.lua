local m = {}

local Core
local Player
local Window
local Garden
local PetTeam
local Webhook
local Rarity
m.CurrentPetTeam = "core"

function m:Init(_core, _player, _window, _garden, _petTeam, _webhook, _rarity)
    Core = _core
    Player = _player
    Window = _window
    Garden = _garden
    PetTeam = _petTeam
    Webhook = _webhook
    Rarity = _rarity

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBoostPets")
    end, function()
        self:AutoBoostSelectedPets()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoNightmareMutation")
    end, function()
        self:AutoNightmareMutation()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoLevelingPets")
    end, function()
        self:StartAutoLeveling()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBulkingPets")
    end, function()
        self:StartAutoBulking()
    end)
end

function m:GetPetReplicationData()
    local replicationClass = require(Core.ReplicatedStorage.Modules.ReplicationClass)
    local activePetsReplicator = replicationClass.new("ActivePetsService_Replicator")
    return activePetsReplicator:YieldUntilData().Table
end

function m:GetAllActivePets()
    local success, replicationData = pcall(function()
        return self:GetPetReplicationData()
    end)
    
    if not success then
        return nil
    end
    
    if not replicationData or not replicationData.ActivePetStates then
        return nil
    end
    
    local activePetStates = replicationData.ActivePetStates
    local playerName = Core.LocalPlayer.Name
    local playerId = tostring(Core.LocalPlayer.UserId)
    
    local playerPets = activePetStates[playerName] 
                    or activePetStates[playerId]
                    or activePetStates[tonumber(playerId)]
    
    if not playerPets then
        Window:ShowWarning("Pet Data","No active pets found for player: " .. playerName)
        return nil
    end
    
    return playerPets
end

function m:GetPlayerPetData()
    local success, replicationData = pcall(self.GetPetReplicationData, self)
    if not success then
        Window:ShowWarning("Pet Data","Failed to get replication data:" .. tostring(replicationData))
        return nil
    end
    
    if not replicationData or not replicationData.PlayerPetData then
        Window:ShowWarning("Pet Data","Invalid PlayerPetData structure")
        return nil
    end
    
    local playerPetData = replicationData.PlayerPetData
    local playerName = Core.LocalPlayer.Name
    local playerId = tostring(Core.LocalPlayer.UserId)
    
    -- Try multiple ways to find player's data
    local playerData = playerPetData[playerName] 
                    or playerPetData[playerId]
                    or playerPetData[tonumber(playerId)]
    
    if not playerData then
        Window:ShowWarning("Pet Data", "No pet data found for player:" .. playerName)
        return nil
    end
    
    return playerData
end

function m:GetPetData(_petID)
    local playerData = self:GetPlayerPetData()
    if playerData and playerData.PetInventory then
        return playerData.PetInventory.Data[_petID]
    end
    return nil
end

function m:EquipPet(_petID)
    if not _petID then
        Window:ShowWarning("Equip Pet", "Invalid pet ID provided")
        return false
    end
    
    local success = pcall(function()
        local position = CFrame.new(Garden:GetFarmCenterPosition())
        if not position then
            Window:ShowWarning("Equip Pet","Failed to get farm center position")
        end
        
        Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
            "EquipPet",
            _petID,
            position
        )
    end)
    
    if not success then
        Window:ShowWarning("Equip Pet","Failed to equip pet:" .. _petID)
        return false
    end
    
    return true
end

function m:UnequipPet(_petID)
    if not _petID then
        Window:ShowWarning("Unequip Pet","Invalid pet ID provided")
        return false
    end
    
    local success = pcall(function()
        Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
            "UnequipPet",
            _petID
        )
    end)
    
    if not success then
        Window:ShowWarning("Unequip Pet","Failed to unequip pet:" .. _petID)
        return false
    end
    
    return true
end

function m:GetCurrentPetTeam()
    return self.CurrentPetTeam
end

function m:ChangeTeamPets(_teamName, _teamType)
    if not _teamName or _teamName == "" then
        return false
    end
    
    local pets = PetTeam:FindPetTeam(_teamName)

    if not pets or #pets == 0 then
        Window:ShowWarning("Change Team Pet","No pets found in the team:" .. _teamName)
        return false
    end

    -- Deactivate all current active pets
    local activePets = self:GetAllActivePets() or {}
    
    if not activePets then
        Window:ShowWarning("Change Team Pet","No active pets to unequip")
    end

    for petID, _ in pairs(activePets) do
        local success = pcall(function()
            self:UnequipPet(petID)
        end)
        
        if not success then
            Window:ShowWarning("Change Team Pet","Failed to unequip pet:" .. petID)
        end
        
        task.wait(0.25) -- Longer delay to ensure server processes
    end
    
    -- Wait for unequip to complete
    task.wait(1)

    -- Activate pets in the selected team
    for _, petID in pairs(pets) do
        local success = pcall(function()
            self:EquipPet(petID)
        end)
        
        if not success then
            Window:ShowWarning("Change Team Pet","Failed to equip pet:" .. petID)
        end
        
        task.wait(0.25) -- Longer delay between equips
    end

    -- Final wait to ensure all equips are processed
    task.wait(1)

    self.CurrentPetTeam = _teamType

    return true
end

function m:BoostPet(_petID)
    Core.ReplicatedStorage.GameEvents.PetBoostService:FireServer(
        "ApplyBoost",
        _petID
    )
end

function m:EligiblePetUseBoost(_petID, _boostType, _boostAmount)
    local petData = self:GetPetData(_petID)
    local isEligible = true

    if not petData or not petData.PetData then
        return false
    end

    for key, value in pairs(petData.PetData) do
        if type(value) ~= "table" then
            continue
        end
        if key ~= "Boosts" and #value < 1 then
            continue
        end
        
        for i, boostInfo in ipairs(value) do
            local currentBoostType = boostInfo.BoostType
            local currentBoostAmount = boostInfo.BoostAmount

            if currentBoostType == _boostType and currentBoostAmount == _boostAmount then
                isEligible = false
            end
        end
    end
    return isEligible
end

function m:BoostSelectedPets()
    local petIDs = Window:GetConfigValue("BoostPets") or {}
    if #petIDs == 0 then
        Window:ShowWarning("Boost Pets","No pets selected for boosting.")
        return
    end

    local boostTypes = Window:GetConfigValue("BoostType") or {}
    if #boostTypes == 0 then
        Window:ShowWarning("Boost Pets", "No boost types selected.")
        return
    end

    for _, boostType in pairs(boostTypes) do
        local extractedType = {}
        for match in string.gmatch(boostType, "([^%-]+)") do
            table.insert(extractedType, match)
        end

        if #extractedType ~= 2 then
            Window:ShowWarning("Boost Pets", "Invalid boost type format:" .. boostType)
            continue
        end

        local toolType = extractedType[1]
        local toolAmount = tonumber(extractedType[2])
        local boostTool = nil

        for _, tool in next, Player:GetAllTools() do
            local tType = tool:GetAttribute("q")
            local tAmount = tool:GetAttribute("o")

            if tType == toolType and tAmount == toolAmount then
                boostTool = tool or nil
                break
            end
        end

        if not boostTool then
            Window:ShowWarning("Boost Pets", "No boost tool found for type:" .. boostType)
            return
        end

        local boostingPetTask = function(_petIDs, _boostType, _boostAmount, _boostTool)
            for _, petID in pairs(_petIDs) do
                local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                if not isEligible then
                    continue
                end

                self:BoostPet(petID)
                task.wait(0.15)
            end
        end

        Player:AddToQueue(
            boostTool,               -- tool
            10,                  -- priority (high)
            function()
                boostingPetTask(petIDs, toolType, toolAmount, boostTool)
            end    -- task function
        )
    end
end

function m:AutoBoostSelectedPets()
    local autoBoost = Window:GetConfigValue("AutoBoostPets") or false
    if not autoBoost then
        return
    end

    local petIDs = Window:GetConfigValue("BoostPets") or {}
    if #petIDs == 0 then
        Window:ShowWarning("Boost Pets", "No pets selected for boosting.")
        return
    end

    local boostTypes = Window:GetConfigValue("BoostType") or {}
    if #boostTypes == 0 then
        Window:ShowWarning("Boost Pets", "No boost types selected.")
        return
    end

    local hasEligiblePet = false
    for _, petID in pairs(petIDs) do
        for _, boostType in pairs(boostTypes) do
            local extractedType = {}
            for match in string.gmatch(boostType, "([^%-]+)") do
                table.insert(extractedType, match)
            end
            if #extractedType ~= 2 then
                continue
            end

            local toolType = extractedType[1]
            local toolAmount = tonumber(extractedType[2])
            local isEligible = self:EligiblePetUseBoost(petID, toolType, toolAmount)
            if isEligible then
                hasEligiblePet = true
                break
            end
        end
        if hasEligiblePet then
            break
        end
    end

    if not hasEligiblePet then
        return
    end

    self:BoostSelectedPets()
end

function m:BoostAllActivePets()
    local boostTool = {}

    for _, tool in next, Player:GetAllTools() do
        local toolType = tool:GetAttribute("q")

        if toolType == "PASSIVE_BOOST" then
            table.insert(boostTool, tool)
        end
    end
    
    if #boostTool == 0 then
        Window:ShowWarning("Boost Pets", "No boost tool found in inventory.")
        return
    end
    
    for _, tool in next, boostTool do
        local boostType = tool:GetAttribute("q")
        local boostAmount = tool:GetAttribute("o")
        local isTaskCompleted = false

        local boostingPetTask = function(_boostType, _boostAmount)
            Window:ShowInfo("Boost Pets", "Starting boost task for tool: " .. tool.Name)
            for petID, _ in pairs(self:GetAllActivePets()) do
                local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                if not isEligible then
                    continue
                end
                
                Window:ShowInfo("Boost Pets", "Boosting pet: " .. petID .. " with " .. _boostType .. " amount: " .. _boostAmount)
                self:BoostPet(petID)
                task.wait(0.15)
            end
        end

        local boostingPetCallback = function()
            isTaskCompleted = true
        end
        
        Player:AddToQueue(
            tool,               -- tool
            1,                  -- priority (high)
            function()
                boostingPetTask(boostType, boostAmount)
            end,    -- task function
            function()
                boostingPetCallback()
            end     -- callback function
        )

        -- Wait until task is completed
        while isTaskCompleted == false do
            task.wait(1)
        end
    end
end

function m:GetAllOwnedPets()
    local myPets = {}
    
    for _, tool in next, Player:GetAllTools() do
        local toolType = tool:GetAttribute("b")
        toolType = toolType or ""
        if toolType == "l" then
            table.insert(myPets, tool)
        end
    end

    return myPets
end

function m:GetPetDetail(_petID)
    local petMutationRegistry = require(Core.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)

    local petData = self:GetPetData(_petID)
    if not petData then
        Window:ShowWarning("Pet Details", "Pet data not found for UUID:" .. _petID)
        return nil
    end

    local petDetail = petData.PetData

    if not petDetail then
        Window:ShowWarning("Pet Details", "Pet detail is nil for UUID:" .. _petID)
        return nil
    end

    local isActive = false
    local activePets = self:GetAllActivePets() or {}
    for petID, _ in pairs(activePets) do
        if petID == _petID then
            isActive = true
            break
        end
    end

    local mutationType = petDetail.MutationType or ""
    local mutation = ""
        if petMutationRegistry and petMutationRegistry.EnumToPetMutation then
        mutation = petMutationRegistry.EnumToPetMutation[mutationType] or ""
    end

    return {
        ID = _petID,
        Name = petDetail.Name or "Unnamed",
        Type = petData.PetType or "Unknown",
        BaseWeight = petDetail.BaseWeight or 1,
        Age = petDetail.Level or 0,
        IsFavorited = petDetail.IsFavorited or false,
        IsActive = isActive,
        Mutation = mutation
    }
end

function m:GetAllMyPets()
    local myPets = {}
    local pets = {}

    for _, tool in pairs(self:GetAllOwnedPets()) do
        local petID = tool:GetAttribute("PET_UUID")
        if not petID then
            Window:ShowWarning("Pet Details", "Pet tool missing PET_UUID attribute:" .. tool.Name)
            continue
        end

        table.insert(pets, {
            ID = petID,
            IsActive = false
        })
    end

    for petID, _ in pairs(self:GetAllActivePets()) do
        if not petID then
            Window:ShowWarning("Pet Details", "Active pet entry missing PET_UUID")
            continue
        end
        
        table.insert(pets, {
            ID = petID,
            IsActive = true
        })
    end

    for _, pet in pairs(pets) do
        local petDetail = self:GetPetDetail(pet.ID)
        if not petDetail  then
            Window:ShowWarning("Pet Details", "Pet detail not found for UUID:" .. pet.ID)
            continue
        end

        table.insert(myPets, {
            ID = petDetail.ID,
            Name = petDetail.Name,
            Type = petDetail.Type,
            BaseWeight = petDetail.BaseWeight,
            Age = petDetail.Age,
            IsActive = pet.IsActive,
            IsFavorited = petDetail.IsFavorited,
            Mutation = petDetail.Mutation
        })
    end

    -- Sort by active status first, then by type, then by age descending
    table.sort(myPets, function(a, b)
        if a.IsActive ~= b.IsActive then
            return a.IsActive -- Active pets first
        elseif a.Type ~= b.Type then
            return a.Type < b.Type -- Alphabetical by type
        else
            return a.Age > b.Age -- Older pets first
        end
    end)

    return myPets
end

function m:SerializePet(pet)
    if not pet then return "" end
    local weight = tonumber(pet.BaseWeight) or 0
    local age = tonumber(pet.Age) or 0
    local mutationPrefix = (pet.Mutation and pet.Mutation ~= "") and ("[" .. pet.Mutation .. "] ") or ""
    local activeSuffix = pet.IsActive and " (Active)" or ""
    return string.format("%s%s %.2f KG (age %d) - %s%s",
        mutationPrefix,
        pet.Type or "Unknown",
        weight,
        age,
        pet.Name or "Unnamed",
        activeSuffix
    )
end

function m:FindEggByPetName(petName)
    local PetEggs = require(Core.ReplicatedStorage.Data.PetRegistry.PetEggs)
    
    -- List of eggs to exclude (fake/test eggs)
    local excludedEggs = {
        ["Fake Egg"] = true,
        -- Add other test/fake eggs here if needed
    }
    
    -- Iterate through all eggs
    for eggName, eggData in pairs(PetEggs) do
        -- Skip excluded eggs
        if excludedEggs[eggName] then
            continue
        end
        
        -- Check if RarityData and Items exist
        if eggData.RarityData and eggData.RarityData.Items then
            -- Check if the pet exists in this egg
            if eggData.RarityData.Items[petName] then
                return eggName -- Return the egg name
            end
        end
    end

    return "Fake Egg" -- Pet not found in any egg
end

function m:GetPetRegistry()
    local success, petRegistry = pcall(function()
        return require(Core.ReplicatedStorage.Data.PetRegistry)
    end)

    if not success then
        Window:ShowWarning("Pet Registry", "Failed to get pet registry:" .. petRegistry)
        return {}
    end

    local petList = petRegistry.PetList
    if not petList then
        Window:ShowWarning("Pet Registry", "PetList is nil or not found")
        return {}
    end

    -- Convert PetList to UI format {text = ..., value = ...}
    local listPets = {}
    for petName, petData in pairs(petList) do
        local eggName = self:FindEggByPetName(petName)
        table.insert(listPets, {
            Name = petName,
            Rarity = petData.Rarity or "Unknown",
            Egg = eggName
        })
    end
    
    if #listPets < 1 then
        return {}
    end

    -- Sort pets alphabetically (ascending order)
    table.sort(listPets, function(a, b)
        local eggA = a.Egg or "Unknown"
        local eggB = b.Egg or "Unknown"
        if eggA ~= eggB then
            return string.lower(tostring(eggA)) < string.lower(tostring(eggB))
        end

        local rarityA = Rarity.RarityOrder[a.Rarity] or 99
        local rarityB = Rarity.RarityOrder[b.Rarity] or 99
        if rarityA ~= rarityB then
            return rarityA < rarityB
        end

        return string.lower(tostring(a.Name)) < string.lower(tostring(b.Name))
    end)
                
    return listPets
end

function m:SellPet()
    local petNames = Window:GetConfigValue("PetToSell") or {}
    local weighLessThan = Window:GetConfigValue("WeightThresholdSellPet") or 1
    local ageLessThan = Window:GetConfigValue("AgeThresholdSellPet") or 1
    local sellPetTeam = Window:GetConfigValue("SellPetTeam") or nil
    local boostBeforeSelling = Window:GetConfigValue("AutoBoostBeforeSelling") or false
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil

    if #petNames == 0 then
        Window:ShowWarning("Sell Pets","No pet names selected for selling.")
        if corePetTeam then
            Window:ShowInfo("Sell Pets", "Reverting to Core Pet Team: " .. corePetTeam)
            self:ChangeTeamPets(corePetTeam, "core")
        end
        return
    end

    -- Favorite pets should not be sold
    for _, tool in pairs(self:GetAllOwnedPets()) do
        local isFavorited = tool:GetAttribute("d") or false
        if isFavorited then
            continue
        end

        local petID = tool:GetAttribute("PET_UUID")
        local petData = self:GetPetData(petID)
        if not petData then
            Window:ShowWarning("Sell Pets","Pet data not found for UUID: " .. tostring(petID))
            continue
        end

        local petName = petData.PetType or "Unknown"
        local petDetail = petData.PetData
        local petWeight = petDetail.BaseWeight or 20
        local petAge = petDetail.Level or math.huge

        local isPetNameMatched = false
        for _, selectedPet in ipairs(petNames) do
            if petName == selectedPet then
                isPetNameMatched = true
                break
            end
        end

        if petWeight >= weighLessThan or petAge >= ageLessThan or not isPetNameMatched then
            print("Favoriting pet:", petName, "| Weight:", petWeight, "| Age:", petAge, "| Is Name Matched:", tostring(isPetNameMatched))

            Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
            task.wait(0.15)
        end
    end
    
    task.wait(0.5) -- Wait for favorites to process
    
    if sellPetTeam then
        Window:ShowInfo("Sell Pets", "Switching to Sell Pet Team: " .. sellPetTeam)
        self:ChangeTeamPets(sellPetTeam, "sell")
        task.wait(2)
        if boostBeforeSelling then
            Window:ShowInfo("Sell Pets", "Boosting all active pets before selling")
            self:BoostAllActivePets()
        end
    end

    task.wait(1) -- Wait before selling
    Window:ShowInfo("Sell Pets", "Selling all unequipped pets...")
    Core.ReplicatedStorage.GameEvents.SellAllPets_RE:FireServer()
    task.wait(1) -- Wait for selling to process
    
    if corePetTeam then
        Window:ShowInfo("Sell Pets", "Reverting to Core Pet Team: " .. corePetTeam)
        self:ChangeTeamPets(corePetTeam, "core")
    end
end

function m:GetModelPet(_petID)
    if not _petID then
        Window:ShowWarning("Get Model Pet","Invalid pet ID provided")
        return nil
    end

    -- Cari di semua descendant
    for _, petMover in ipairs(workspace.PetsPhysical:GetChildren()) do
        local modelPet = petMover:FindFirstChild(_petID)
        if modelPet then
            return modelPet
        end
    end

    Window:ShowWarning("Get Model Pet", "Model not found")
    return nil
end

function m:CleansingMutation(_petID)
    Window:ShowInfo("Cleansing Mutation", "Cleansing mutation for pet ID: " .. _petID)
    if not _petID then
        Window:ShowWarning("Cleansing Mutation", "Invalid pet ID provided")
        return false
    end

    local cleansingTool
    for _, tool in next, Player:GetAllTools() do
        local toolName = tool:GetAttribute("u")

        if toolName == "Cleansing Pet Shard" then
            cleansingTool = tool or nil
            break
        end
    end

    if not cleansingTool then
        Window:ShowWarning("Cleansing Mutation", "No cleansing tool found")
        return false
    end

    local isTaskCompleted = false
    local cleansingTask = function(_petID)
        local petMover = self:GetModelPet(_petID)
        if not petMover then
            Window:ShowWarning("Cleansing Mutation", "PetMover not found for pet ID: " .. _petID)
            return
        end
        
        Window:ShowInfo("Cleansing Mutation", "Applying cleansing shard to pet ID: " .. _petID)
        local success, error = pcall(function()
            Core.ReplicatedStorage.GameEvents.PetShardService_RE:FireServer(
                "ApplyShard",
                petMover
            )
        end)

        if not success then
            Window:ShowWarning("Cleansing Mutation", "Failed to apply cleansing shard: " .. error)
        end
        task.wait(1) -- Wait to ensure server processes the shard application
    end

    local cleansingCallback = function()
        isTaskCompleted = true
    end

    Player:AddToQueue(
        cleansingTool,               -- tool
        10,                  -- priority (high)
        function()
            cleansingTask(_petID)
        end,    -- task function
        function()
            cleansingCallback()
        end -- callback function
    )

    return true
end

function m:AutoNightmareMutation()
    if not Window:GetConfigValue("AutoNightmareMutation") then
        return
    end

    local nightMarePetTeam = Window:GetConfigValue("NightmareMutationPetTeam") or nil
    if not nightMarePetTeam then
        Window:ShowWarning("Nightmare Mutation", "No Nightmare Mutation Pet Team selected.")
        return
    end

    local petIDs = Window:GetConfigValue("NightmareMutationPets") or {}
    if #petIDs == 0 then
        Window:ShowWarning("Nightmare Mutation","No pets selected for Nightmare Mutation.")
        return
    end

    local isPetIDAlreadyNightmare = ""
    local isNoActivePet = true

    for _, petID in pairs(petIDs) do
        local petDetail = self:GetPetDetail(petID)
        if not petDetail then
            Window:ShowWarning("Nightmare Mutation","Pet detail not found for UUID: " .. petID)
            continue
        end

        if not petDetail.IsActive then
            print("Pet is not active, skipping Nightmare Mutation:", petDetail.Name)
            continue
        end

        isNoActivePet = false
        
        if petDetail.Mutation == "" then
            print("Pet has no mutation, skipping Cleansing Mutation:", petDetail.Name)
            continue
        end

        if petDetail.Mutation == "Nightmare" then
            Window:ShowWarning("Nightmare Mutation","Pet already has Nightmare mutation :", petDetail.Name)
            task.spawn(function() 
                Webhook:NightmareMutation(petDetail.Type, #petIDs - 1)
            end)

            isPetIDAlreadyNightmare = petID
            break
        end

        Window:ShowInfo("Nightmare Mutation","Starting Cleansing Mutation for pet: " .. petDetail.Name)
        local success = self:CleansingMutation(petID)
        if not success then
            Window:ShowWarning("Nightmare Mutation","Failed to cleanse mutation for pet:", petDetail.Name)
            continue
        end
    end

    if isPetIDAlreadyNightmare ~= "" then
        self:UnequipPet(isPetIDAlreadyNightmare)
        task.wait(1)

        -- Remove from selected pets to avoid reprocessing
        for index, id in ipairs(petIDs) do
            if id == isPetIDAlreadyNightmare then
                table.remove(petIDs, index)
                break
            end
        end

        Window:SetConfigValue("NightmareMutationPets", petIDs)
        isNoActivePet = true
    end
    
    if not isNoActivePet then
        return
    end

    while m.CurrentPetTeam ~= "core" do
        Window:ShowInfo("Nightmare Mutation","Waiting to switch back to Core Pet Team...")
        task.wait(1)
    end

    Window:ShowInfo("Nightmare Mutation", "Starting Nightmare Mutation New Target Pet")
    self:ChangeTeamPets(nightMarePetTeam, "core")
    self:EquipPet(petIDs[1])
end

function m:StartAutoLeveling()
    local autoLeveling = Window:GetConfigValue("AutoLevelingPets") or false
    local levelToReach = Window:GetConfigValue("LevelToReach") or 100
    local levelingPetTeam = Window:GetConfigValue("LevelingPetTeam") or nil
    
    if not autoLeveling then
        return
    end

    if levelToReach < 1 then
        Window:ShowWarning("Auto Leveling", "Invalid level to reach for Auto Leveling: " .. levelToReach)
        return
    end

    if not levelingPetTeam then
        Window:ShowWarning("Auto Leveling", "No Leveling Pet Team selected.")
        return
    end

    local petIDs = Window:GetConfigValue("LevelingPets") or {}
    if #petIDs == 0 then
        Window:ShowWarning("Auto Leveling", "No pets selected for Auto Leveling.")
        return
    end

    local isPetIDAlreadyAtTargetLevel = ""
    local isNoActivePet = true

    for _, petID in pairs(petIDs) do
        local petDetail = self:GetPetDetail(petID)
        if not petDetail then
            Window:ShowWarning("Auto Leveling"," Pet detail not found for UUID: " .. petID)
            continue
        end

        if not petDetail.IsActive then
            continue
        end

        isNoActivePet = false
        if petDetail.Age >= levelToReach then
            Window:ShowInfo("Auto Leveling", "Pet already reached the target level: " .. petDetail.Name)
            task.spawn(function() 
                Webhook:Leveling(petDetail.Type, petDetail.Age, #petIDs - 1)
            end)
            
            isPetIDAlreadyAtTargetLevel = petID
            break
        end
    end

    if isPetIDAlreadyAtTargetLevel ~= "" then
        self:UnequipPet(isPetIDAlreadyAtTargetLevel)
        task.wait(1)

        -- Remove from selected pets to avoid reprocessing
        for index, id in ipairs(petIDs) do
            if id == isPetIDAlreadyAtTargetLevel then
                table.remove(petIDs, index)
                break
            end
        end

        Window:SetConfigValue("AutoLevelingPets", petIDs)

        isNoActivePet = true
    end

    if not isNoActivePet then
        return
    end

    while m.CurrentPetTeam ~= "core" do
        print("Waiting to switch back to Core Pet Team...")
        task.wait(1)
    end

    Window:ShowInfo("Auto Leveling", "Starting Auto Leveling New Target Pet")
    self:ChangeTeamPets(levelingPetTeam, "core")
    self:EquipPet(petIDs[1])
end

function m:StartAutoBulking()
    local autoBulking = Window:GetConfigValue("AutoBulkingPets") or false
    local bulkingPetTeam = Window:GetConfigValue("BulkingPetTeam") or nil
    local petIDs = Window:GetConfigValue("BulkingPets") or {}
    local bulkToReach = Window:GetConfigValue("BulkingToWeight") or 1

    if not autoBulking then
        return
    end

    if not bulkingPetTeam then
        Window:ShowWarning("Auto Bulking", "No Bulking Pet Team selected.")
        return
    end

    if #petIDs == 0 then
        Window:ShowWarning("Auto Bulking", "No pets selected for Auto Bulking.")
        return
    end

    local isPetIDAlreadyAtTargetWeight = ""
    local isNoActivePet = true

    for _, petID in pairs(petIDs) do
        local petDetail = self:GetPetDetail(petID)
        if not petDetail then
            Window:ShowWarning("Auto Bulking", "Pet detail not found for UUID: " .. petID)
            continue
        end

        if not petDetail.IsActive then
            continue
        end

        isNoActivePet = false
        if petDetail.BaseWeight >= bulkToReach then
            Window:ShowInfo("Auto Bulking", "Pet already reached the target weight: " .. petDetail.Name)
            task.spawn(function() 
                Webhook:Bulking(petDetail.Type, petDetail.BaseWeight, #petIDs - 1)
            end)

            isPetIDAlreadyAtTargetWeight = petID
            break
        end
    end

    if isPetIDAlreadyAtTargetWeight ~= "" then
        self:UnequipPet(isPetIDAlreadyAtTargetWeight)
        task.wait(1)

        -- Remove from selected pets to avoid reprocessing
        for index, id in ipairs(petIDs) do
            if id == isPetIDAlreadyAtTargetWeight then
                table.remove(petIDs, index)
                break
            end
        end

        Window:SetConfigValue("BulkingPets", petIDs)

        isNoActivePet = true
    end

    if not isNoActivePet then
        return
    end

    while m.CurrentPetTeam ~= "core" do
        Window:ShowInfo("Auto Bulking", "Waiting to switch back to Core Pet Team...")
        task.wait(1)
    end

    Window:ShowInfo("Auto Bulking", "Starting Auto Bulking New Target Pet")
    self:ChangeTeamPets(bulkingPetTeam, "core")
    self:EquipPet(petIDs[1])
end

return m