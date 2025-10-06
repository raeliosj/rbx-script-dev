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
        toolType = toolType and string.lower(toolType) or ""
        if toolType == "l" then
            table.insert(myPets, tool)
        end
    end

    return myPets
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