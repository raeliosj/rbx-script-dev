local m = {}

local Core
local Player
local Window
local Garden
local Pet
local Webhook

local AutoHatchConnection
local IsHatchingInProgress = false

function m:Init(_core, _player, _window, _garden, _pet, _webhook)
    Core = _core
    Player = _player
    Window = _window
    Garden = _garden
    Pet = _pet
    Webhook = _webhook

    local EggReadyToHatchRemote = Core.GameEvents.EggReadyToHatch_RE
    AutoHatchConnection = EggReadyToHatchRemote.OnClientEvent:Connect(function()
        self:StartAutoHatching()
    end)

    task.spawn(function()
        self:StartAutoHatching()
    end)
end

function m:StartAutoHatching()
    if not Window:GetConfigValue("AutoHatchEggs") then
        return
    end
    
    -- If already processing, don't start another process
    if IsHatchingInProgress then
        warn("Hatching already in progress, waiting...")
        return
    end

    IsHatchingInProgress = true

    -- Execute hatch
    self:HatchEgg()

    task.wait(1)
    IsHatchingInProgress = false
end

function m:StopAutoHatching()
    if AutoHatchConnection then
        AutoHatchConnection:Disconnect()
        AutoHatchConnection = nil
    end
end

function m:GetEggRegistry()
    local success, petRegistry = pcall(function()
        return require(Core.ReplicatedStorage.Data.PetRegistry)
    end)
    
    if not success then           
        warn("Failed to get pet registry:", petRegistry)
        return {}
    end
    
    local eggList = petRegistry.PetEggs
    if not eggList then
        warn("PetEggs is nil or not found")
        return {}
    end

    -- Return the eggList as-is for PetEggRenderer compatibility
    return eggList
end

function m:GetAllOwnedEggs()
    local myEggs = {}

    for _, tool in next, Player:GetAllTools() do
        local toolType = tool:GetAttribute("b")
        toolType = toolType and string.lower(toolType) or ""

        if toolType == "c" then
            table.insert(myEggs, tool)
        end
    end

    return myEggs
end

function m:FindEggOwnedEgg(eggName)
    for _, tool in next, self:GetAllOwnedEggs() do
        local toolName = tool:GetAttribute("h")

        if toolName == eggName then
            return tool
        end
    end
    return nil
end

function m:GetAllPlacedEggs()
    local placedEggs = {}
    local MyFarm = Garden:GetMyFarm()

    if not MyFarm then
        warn("My farm not found!")
        return placedEggs
    end
    
    local objectsPhysical = MyFarm.Important.Objects_Physical
    if not objectsPhysical then
        warn("Objects_Physical not found!")
        return placedEggs
    end
    
    for _, egg in pairs(objectsPhysical:GetChildren()) do
        if egg.Name ~= "PetEgg" then
            continue
        end

        local owner = egg:GetAttribute("OWNER")
        if owner == Core.LocalPlayer.Name then
            table.insert(placedEggs, egg)
        end
    end
    
    return placedEggs
end

function m:GetPlacedEggDetail(_eggID)
    local success, dataService = pcall(function()
        return require(Core.ReplicatedStorage.Modules.DataService)
    end)
    if not success or not dataService then
        warn("Failed to get DataService:", dataService)
        return nil
    end

    local allData = dataService:GetData()
    if not allData then
        warn("No data available from DataService")
        return nil
    end
    
    local saveSlots = allData.SaveSlots
    if not saveSlots then
        warn("SaveSlots not found in data")
        return nil
    end
    
    local savedObjects = saveSlots.AllSlots[saveSlots.SelectedSlot].SavedObjects
    
    if savedObjects and _eggID and savedObjects[_eggID] then
        return savedObjects[_eggID].Data
    end
    
    -- Fallback method
    warn("Falling back to ReplicationClass method")
    local ReplicationClass = Core.ReplicatedStorage.Modules.ReplicationClass
    local DataStreamReplicator = ReplicationClass.new("DataStreamReplicator")
    DataStreamReplicator:YieldUntilData()
    
    local replicationData = DataStreamReplicator:YieldUntilData().Table
    local playerData = replicationData[Core.LocalPlayer.Name] or replicationData[tostring(Core.LocalPlayer.UserId)]
    
    if playerData and playerData[_eggID] then
        return playerData[_eggID].Data
    end
    
    return nil
end

function m:PlacingEgg()
    local eggName = Window:GetConfigValue("EggPlacing") or ""
    local maxEggs = Window:GetConfigValue("MaxPlaceEggs") or 0
    local positionType = Window:GetConfigValue("PositionToPlaceEggs") or "Random"
    local position = Garden:GetFarmRandomPosition()

    if positionType == "Front Right" then
        position = Garden:GetFarmFrontRightPosition()
    elseif positionType == "Front Left" then
        position = Garden:GetFarmFrontLeftPosition()
    elseif positionType == "Back Right" then
        position = Garden:GetFarmBackRightPosition()
    elseif positionType == "Back Left" then
        position = Garden:GetFarmBackLeftPosition()
    end

    if eggName == "" then
        return
    end

    if maxEggs < 1 then
        return
    end
        
    local eggOwnedName = self:FindEggOwnedEgg(eggName)

    if not eggOwnedName then
        return
    end

    local totalOwnedEggs = eggOwnedName:GetAttribute("e") or 0
    local maxEggCanPlace = math.min(totalOwnedEggs, maxEggs)
    print("🥚 Total egg will be placed:", maxEggCanPlace)

    local placeEggTask = function(_maxEggCanPlace, _eggTool, _position, _positionType)
        print("🥚 Starting egg placement using queue system... already placed:", #self:GetAllPlacedEggs(), "Total to place:", _maxEggCanPlace)
        print("🔍 Debug - Function parameters:", _maxEggCanPlace, _eggTool and _eggTool.Name or "nil", _position, _positionType)

        local attemptCount = 0

        while #self:GetAllPlacedEggs() < _maxEggCanPlace do
            print("🔄 While loop iteration:", attemptCount, "Current eggs placed:", #self:GetAllPlacedEggs(), "Target:", _maxEggCanPlace)
            if Player:GetEquippedTool() ~= _eggTool then
                Player:EquipTool(_eggTool)
                task.wait(0.5) -- Small delay to ensure tool is equipped
            end

            local newPosition = Garden:GetFarmRandomPosition()

            local success, err = pcall(function()
                if string.find(_positionType, "Front") then
                    local zPosition = _position.Z - (attemptCount * 5)
                    if Garden.MailboxPosition.Z > 0 then
                        zPosition = _position.Z + (attemptCount * 5)
                    end

                    newPosition = Vector3.new(_position.X, _position.Y, zPosition)
                elseif string.find(_positionType, "Back") then
                    local zPosition = _position.Z + (attemptCount * 5)
                    if Garden.MailboxPosition.Z < 0 then
                        zPosition = _position.Z - (attemptCount * 5)
                    end

                    newPosition = Vector3.new(_position.X, _position.Y, zPosition)
                end
            end)

            print("🔍 Debug - New position calculation:", success, err or "No error", newPosition)
            print("🥚 Placing egg at:", newPosition)
            Core.GameEvents.PetEggService:FireServer("CreateEgg", newPosition)
            task.wait(0.5) -- Small delay to avoid spamming
            
            attemptCount = attemptCount + 1
        end
    end
    
    -- Add to queue with high priority (1)
    Player:AddToQueue(
        eggOwnedName,           -- tool
        1,                      -- priority (high)
        function()
            placeEggTask(maxEggCanPlace, eggOwnedName, position, positionType)
        end
    )
    
    print("🎉 Egg placement completed! Total eggs:", #self:GetAllPlacedEggs())
end

function m:HatchEgg()
    print("Hatching eggs...")
    if #self:GetAllPlacedEggs() == 0 then
        self:PlacingEgg()
        while #self:GetAllPlacedEggs() < 1 do
            task.wait(1)
        end
    end

    -- Wait for eggs to be ready using while loop
    print("⏳ Waiting for eggs to be ready to hatch...")
    while true do
        local readyCount = 0
        local maxTimeToHatch = 0
        
        for _, egg in pairs(self:GetAllPlacedEggs()) do
            if not egg or not egg.Parent then -- Check if egg still exists
                continue
            end

            local timeToHatch = egg:GetAttribute("TimeToHatch") or 0
            if timeToHatch > 0 then
                maxTimeToHatch = math.max(maxTimeToHatch, timeToHatch)
            else
                readyCount = readyCount + 1
            end
        end
        
        print("🥚 Ready eggs:", readyCount, "/", #self:GetAllPlacedEggs())

        if readyCount == #self:GetAllPlacedEggs() then
            print("✅ All eggs are ready to hatch!")
            break
        end

        task.wait(math.min(maxTimeToHatch, 5)) -- Check every second
    end

    local hatchPetTeam = Window:GetConfigValue("HatchPetTeam") or nil
    local specialHatchPetTeam = Window:GetConfigValue("SpecialHatchPetTeam") or nil
    local specialHatchingPets = Window:GetConfigValue("SpecialHatchingPet") or {}
    local weightThresholdSpecialHatching = Window:GetConfigValue("WeightThresholdSpecialHatching") or math.huge
    local boostBeforeHatch = Window:GetConfigValue("AutoBoostBeforeHatch") or false
    local boostBeforeSpecialHatch = Window:GetConfigValue("AutoBoostBeforeSpecialHatch") or false

    if hatchPetTeam then
        Pet:ChangeTeamPets(hatchPetTeam)
        task.wait(2)
        if boostBeforeHatch then
            Pet:BoostAllActivePets()
        end
    end

    local specialHatchingEgg = {}
    for _, egg in pairs(self:GetAllPlacedEggs()) do
        local eggUUID = egg:GetAttribute("OBJECT_UUID")
        local eggData = self:GetPlacedEggDetail(eggUUID)
        local baseWeight = eggData and eggData.BaseWeight or 1
        local petName = eggData and eggData.Type or "Unknown"

        local isSpecialPet = false
        for _, specialPet in ipairs(specialHatchingPets) do
            if petName == specialPet then
                table.insert(specialHatchingEgg, egg)
                isSpecialPet = true
                break
            end
        end

        if isSpecialPet then
            continue
        end

        if baseWeight > weightThresholdSpecialHatching then
            table.insert(specialHatchingEgg, egg)
            continue
        end
        Core.GameEvents.PetEggService:FireServer("HatchPet", egg)
    end

    task.wait(1)

    if specialHatchPetTeam and #specialHatchingEgg > 0 then
        Pet:ChangeTeamPets(specialHatchPetTeam)
        task.wait(2)
        if boostBeforeSpecialHatch then
            Pet:BoostAllActivePets()
        end
    end

    for _, egg in pairs(specialHatchingEgg) do
        local eggUUID = egg:GetAttribute("OBJECT_UUID")
        local eggData = self:GetPlacedEggDetail(eggUUID)
        local baseWeight = eggData and eggData.BaseWeight or 1
        local petName = eggData and eggData.Type or "Unknown"
        print("Hatching special Pet:", petName, "Weight:", baseWeight)
        Core.GameEvents.PetEggService:FireServer("HatchPet", egg)
        task.wait(0.15) -- Small delay to avoid spamming

        task.spawn(function() 
            Webhook:HatchEgg(petName, egg:GetAttribute("EggName") or "Unknown", baseWeight)
        end)
    end

    if #specialHatchingEgg > 0 then
        task.wait(1)
    end


    local isAutoSellAfterHatch = Window:GetConfigValue("AutoSellPetsAfterHatching") or false
    local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil

    if isAutoSellAfterHatch then
        Pet:SellPet()
    else
        Pet:ChangeTeamPets(corePetTeam)
    end

    self:PlacingEgg()

    task.spawn(function()
        local eggName = Window:GetConfigValue("EggPlacing") or "N/A"
        local tooolEgg = self:FindEggOwnedEgg(eggName)
        local totalOwnedEggs = tooolEgg and (tooolEgg:GetAttribute("e") or 0) or 0
        
        Webhook:Statistics(eggName, totalOwnedEggs)
    end)
end

return m