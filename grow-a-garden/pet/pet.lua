local m = {}

local Core
local Player
local Window
local Garden
local PetTeam

function m:Init(_core, _player, _window, _garden, _petTeam)
    Core = _core
    Player = _player
    Window = _window
    Garden = _garden
    PetTeam = _petTeam

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBoostPets")
    end, function()
        self:AutoBoostSelectedPets()
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
        warn("🐾 [GET ACTIVE] Failed to get replication data:", replicationData)
        return nil
    end
    
    if not replicationData or not replicationData.ActivePetStates then
        warn("🐾 [GET ACTIVE] Invalid replication data structure")
        return nil
    end
    
    local activePetStates = replicationData.ActivePetStates
    local playerName = Core.LocalPlayer.Name
    local playerId = tostring(Core.LocalPlayer.UserId)
    
    -- Try multiple ways to find player's pets
    local playerPets = activePetStates[playerName] 
                    or activePetStates[playerId]
                    or activePetStates[tonumber(playerId)]
    
    if not playerPets then
        print("🐾 [GET ACTIVE] No active pets found for player:", playerName)
        -- Debug: Show available keys
        print("🐾 [GET ACTIVE] Available keys in ActivePetStates:")
        for key, _ in pairs(activePetStates) do
            print("  - Key:", key, "Type:", type(key))
        end
    end
    
    return playerPets
end

function m:GetPlayerPetData()
    local success, replicationData = pcall(self.GetPetReplicationData, self)
    if not success then
        warn("🐾 [GET DATA] Failed to get replication data:", replicationData)
        return nil
    end
    
    if not replicationData or not replicationData.PlayerPetData then
        warn("🐾 [GET DATA] Invalid PlayerPetData structure")
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
        print("🐾 [GET DATA] No pet data found for player:", playerName)
        -- Debug: Show available keys
        print("🐾 [GET DATA] Available keys in PlayerPetData:")
        for key, _ in pairs(playerPetData) do
            print("  - Key:", key, "Type:", type(key))
        end
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
        warn("🐾 [EQUIP] Invalid pet ID provided")
        return false
    end
    
    local success = pcall(function()
        local position = CFrame.new(Garden:GetFarmCenterPosition())
        if not position then
            error("Failed to get farm center position")
        end
        
        Core.GameEvents.PetsService:FireServer(
            "EquipPet",
            _petID,
            position
        )
    end)
    
    if not success then
        warn("🐾 [EQUIP] Failed to equip pet:", _petID)
        return false
    end
    
    return true
end

function m:UnequipPet(_petID)
    if not _petID then
        warn("🐾 [UNEQUIP] Invalid pet ID provided")
        return false
    end
    
    local success = pcall(function()
        Core.GameEvents.PetsService:FireServer(
            "UnequipPet",
            _petID
        )
    end)
    
    if not success then
        warn("🐾 [UNEQUIP] Failed to unequip pet:", _petID)
        return false
    end
    
    return true
end


function m:ChangeTeamPets(_teamName)
    if not _teamName or _teamName == "" then
        return false
    end
    
    local pets = PetTeam:FindPetTeam(_teamName)

    if not pets or #pets == 0 then
        warn("🐾 [CHANGE TEAM] No pets found in the team:", _teamName)
        return false
    end

    -- Deactivate all current active pets
    local activePets = self:GetAllActivePets() or {}
    
    if not activePets then
        print("🐾 [CHANGE TEAM] No active pets to unequip")
    end

    for petID, _ in pairs(activePets) do
        local success = pcall(function()
            self:UnequipPet(petID)
        end)
        
        if not success then
            warn("🐾 [CHANGE TEAM] Failed to unequip pet:", petID)
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
            warn("🐾 [CHANGE TEAM] Failed to equip pet:", petID)
        end
        
        task.wait(0.25) -- Longer delay between equips
    end

    -- Final wait to ensure all equips are processed
    task.wait(1)
    
    return true
end

function m:BoostPet(_petID)
    Core.GameEvents.PetBoostService:FireServer(
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
        print("No pets selected for boosting.")
        return
    end

    local boostTypes = Window:GetConfigValue("BoostType") or {}
    if #boostTypes == 0 then
        print("No boost types selected.")
        return
    end

    for _, boostType in pairs(boostTypes) do
        local extractedType = {}
        for match in string.gmatch(boostType, "([^%-]+)") do
            table.insert(extractedType, match)
        end

        if #extractedType ~= 2 then
            warn("Invalid boost type format:", boostType)
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
            warn("No boost tool found for type:", boostType)
            return
        end

        local boostingPetTask = function(_petIDs, _boostType, _boostAmount, _boostTool)
            print("🚀 Starting boost task for tool:", _boostTool.Name)
            for _, petID in pairs(_petIDs) do
                local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                if not isEligible then
                    print("🐾 Skipping pet (not eligible for boost):", petID)
                    continue
                end

                print("🐾 Boosting pet:", petID, "with", _boostType, "amount:", _boostAmount)
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
        print("No pets selected for boosting.")
        return
    end

    local boostTypes = Window:GetConfigValue("BoostType") or {}
    if #boostTypes == 0 then
        print("No boost types selected.")
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
        print("No eligible pets found for boosting.")
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
        print("No boost tool found in inventory.")
        return
    end
    
    for _, tool in next, boostTool do
        local boostType = tool:GetAttribute("q")
        local boostAmount = tool:GetAttribute("o")
        local isTaskCompleted = false

        local boostingPetTask = function(_boostType, _boostAmount)
            print("🚀 Starting boost task for tool:", tool.Name)
            for petID, _ in pairs(self:GetAllActivePets()) do
                local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                if not isEligible then
                    continue
                end

                print("🐾 Boosting pet:", petID, "with", _boostType, "amount:", _boostAmount)
                self:BoostPet(petID)
                task.wait(0.15)
            end
        end

        local boostingPetCallback = function()
            print("🚀 Boost task completed for tool:", tool.Name)
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
            print("⏳ Waiting for boost task to complete...")
            task.wait(2)
        end
        print("✅ Boost task finished, moving to next tool")
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
        warn("Pet data not found for UUID:", _petID)
        return nil
    end

    local petDetail = petData.PetData

    if not petDetail then
        warn("Pet detail is nil for UUID:", _petID)
        return nil
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
        Mutation = mutation
    }
end

function m:GetAllMyPets()
    local myPets = {}
    local pets = {}

    for _, tool in pairs(self:GetAllOwnedPets()) do
        local petID = tool:GetAttribute("PET_UUID")
        if not petID then
            warn("Pet tool missing PET_UUID attribute:", tool.Name)
            continue
        end

        table.insert(pets, {
            ID = petID,
            IsActive = false
        })
    end

    for petID, _ in pairs(self:GetAllActivePets()) do
        if not petID then
            warn("Active pet entry missing PET_UUID")
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
            warn("Pet detail not found for UUID:", pet.ID)
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

function m:GetPetRegistry()
    local success, petRegistry = pcall(function()
        return require(Core.ReplicatedStorage.Data.PetRegistry)
    end)
    
    if not success then           
        warn("Failed to get pet registry:", petRegistry)
        return {}
    end

    local petList = petRegistry.PetList
    if not petList then
        warn("PetList is nil or not found")
        return {}
    end

    -- Convert PetList to UI format {text = ..., value = ...}
    local formattedPets = {}
    for petName, petData in pairs(petList) do
        table.insert(formattedPets, {
            text = petName,
            value = petName
        })
    end
    
    if #formattedPets < 1 then
        return {}
    end

    -- Sort pets alphabetically (ascending order)
    table.sort(formattedPets, function(a, b)
        if not a or not b or not a.text or not b.text then
            return false
        end
        return string.lower(tostring(a.text)) < string.lower(tostring(b.text))
    end)
                
    return formattedPets
end

function m:SellPet()
    local petNames = Window:GetConfigValue("PetToSell") or {}
    local weighLessThan = Window:GetConfigValue("WeightThresholdSellPet") or 1
    local ageLessThan = Window:GetConfigValue("AgeThresholdSellPet") or 1
    local sellPetTeam = Window:GetConfigValue("SellPetTeam") or nil
    local boostBeforeSelling = Window:GetConfigValue("AutoBoostBeforeSelling") or false
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil

    if #petNames == 0 then
        print("No pet selected for selling.")
        if corePetTeam then
            print("Reverting to Core Pet Team:", corePetTeam)
            self:ChangeTeamPets(corePetTeam)
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
            warn("Pet data not found for UUID:", petID)
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
            print("Skipping pet (does not meet sell criteria):", petName, "| Weight:", petWeight, "| Age:", petAge, "| Is Name Matched:", tostring(isPetNameMatched))

            Core.GameEvents.Favorite_Item:FireServer(tool)
            task.wait(0.15)
        end
    end
    
    task.wait(0.5) -- Wait for favorites to process
    
    if sellPetTeam then
        self:ChangeTeamPets(sellPetTeam)
        task.wait(2)
        if boostBeforeSelling then
            self:BoostAllActivePets()
        end
    end

    task.wait(1) -- Wait before selling

    Core.GameEvents.SellAllPets_RE:FireServer()
    task.wait(1) -- Wait for selling to process
    
    if corePetTeam then
        self:ChangeTeamPets(corePetTeam)
    end
end

return m