local m = {}

local Window
local Core

local Camera
local UserInputService
local FishingController
local Net
local Signal
local GuiControl
local ChargeFishingRodRemote
local FishingCompletedEvent
local ClickHook
local Replion
local Constants
local RaycastUtility
local RequestFishingMinigameStartedRemote
local CancelFishingInputsRemote
local PlayerStatsUtility 
local EquipToolFromHotbar
local ItemUtility

local MinigameProgressSignal
local FishCaughtConnection
local FishingMinigameChangedConnection
local TextEffectConnection
local DataReplion
local IsMinigameActive = false
local IsFishingActive = false
local LastFishingActivityTime = 0
local Areas = {}

local CurrentMinigameData = nil

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Camera = Core.Workspace.CurrentCamera
    FishingController = require(Core.ReplicatedStorage.Controllers.FishingController)
    Constants = require(Core.ReplicatedStorage.Shared.Constants)
    GuiControl = require(Core.ReplicatedStorage.Modules.GuiControl)
    RaycastUtility = require(Core.ReplicatedStorage.Shared.RaycastUtility)
    Net = require(Core.ReplicatedStorage.Packages.Net)
    Signal = require(Core.ReplicatedStorage.Packages.Signal)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    PlayerStatsUtility = require(Core.ReplicatedStorage.Shared.PlayerStatsUtility)
    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
    Areas = require(Core.ReplicatedStorage.Areas)

    UserInputService = game:GetService("UserInputService")
    ClickHook = GuiControl:Hook("Click")
    MinigameProgressSignal = Signal.new()
    DataReplion = Replion.Client:WaitReplion("Data")

    ChargeFishingRodRemote = Net:RemoteFunction("ChargeFishingRod")
    FishingCompletedEvent = Net:RemoteEvent("FishingCompleted")
    RequestFishingMinigameStartedRemote = Net:RemoteFunction("RequestFishingMinigameStarted")
    CancelFishingInputsRemote = Net:RemoteFunction("CancelFishingInputs")
    EquipToolFromHotbar = Net:RemoteEvent("EquipToolFromHotbar")
    
    self:CreateConnections()

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoFishing")
        end, 
        function()
            self:StartAutoFishing()
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoInstantCatch")
        end, 
        function()
            self:StartAutoCharge()
        end
    )
end

function m:IsMaxInventory()
    if DataReplion:GetExpect("EquippedType") ~= "Fishing Rods" then
        warn("No fishing rod equipped!")
        IsFishingActive = false
        return
    end
    return Constants:CountInventorySize(DataReplion) >= Constants.MaxInventorySize
end

function m:isRodEquipped()
    local equippedId = DataReplion:GetExpect("EquippedId")
    local autoEquip = Window:GetConfigValue("AutoEquipFishingRod") or false
    
    if not equippedId then
        warn("No item is currently equipped.")
        return false
    end
	
    local inventoryItem = PlayerStatsUtility:GetItemFromInventory(DataReplion, function(item)
        return item.UUID == equippedId
    end)

    if not inventoryItem then
        warn("Equipped item not found in inventory.")
        return false
    end
    
    local equippedItemData = ItemUtility:GetItemData(inventoryItem.Id)

	if equippedItemData and equippedItemData.Data.Type == "Fishing Rods" then
        return true
	end
    if autoEquip then
        EquipToolFromHotbar:FireServer(1)
        return true
    end

    warn("Equipped item is not a fishing rod.")
    return true
end

function m:CalculateCastPower()
    local isAutoPerfect = Window:GetConfigValue("AutoPerfectCast") or true
    local minCastPower = 0.5

    if isAutoPerfect then
        minCastPower = 0.95
    end

    -- Generate a random number between minCastPower and 0.9999
    local castPower = math.random() * (0.9999 - minCastPower) + minCastPower
    return castPower
end

function m:GetElapsedFromPower(seedTime, castPower)
    local frequency = Random.new(seedTime):NextInteger(4, 10)

	castPower = math.clamp(castPower, 0, 1)

	if castPower == 1 then
		return math.pi / frequency
	elseif castPower == 0 then
		return 0
	end

	local theta = math.asin(1 - 2 * castPower)
	local elapsed = (theta - math.pi / 2) / frequency

	if elapsed < 0 then
		elapsed = elapsed + (2 * math.pi) / frequency
	end

	return elapsed
end

function m:GetElapsedFromPowerV2(seedTime, castPower)
    castPower = math.clamp(castPower or 0, 0, 1)

    local frequency = Random.new(seedTime):NextNumber(4, 10)

    if castPower >= 1 then
        local elapsedPeak = math.pi / frequency
        return elapsedPeak, seedTime + elapsedPeak
    end

    if castPower <= 0 then
        return 0, seedTime
    end

    local sinArg = 1 - 2 * castPower

    if sinArg > 1 then sinArg = 1 end
    if sinArg < -1 then sinArg = -1 end

    local theta = math.asin(sinArg)

    local baseElapsed = (theta - (math.pi / 2)) / frequency

    if baseElapsed < 0 then
        baseElapsed = baseElapsed + (2 * math.pi) / frequency
    end

    local timeAtPower = seedTime + baseElapsed
    return baseElapsed, timeAtPower
end

function m:GetIsFishingActive()
    if tick() - LastFishingActivityTime > 3 then
        IsFishingActive = false
    end
    return IsFishingActive
end

function m:SetIsFishingActive(value)
    if value then
        LastFishingActivityTime = tick()
    end
    IsFishingActive = value
end

function m:CreateConnections()
    if not TextEffectConnection then
        TextEffectConnection = Net:RemoteEvent("ReplicateTextEffect").OnClientEvent:Connect(function(data)
            local localPlayerCharacter = Core:GetCharacter()
            if not localPlayerCharacter then return end

            local attachTo = data.TextData and data.TextData.AttachTo
            local container = data.Container

            if attachTo ~= localPlayerCharacter.Head and container ~= localPlayerCharacter.Head then
                return
            end

            if not CurrentMinigameData then
                warn("No current minigame data available for text effect.")
                return
            end

            local clickProgress = 0
            local delayClick = math.max(Window:GetConfigValue("AutoInstantCatchDelayPerClickPower") or 0.25, 0.05)
            while clickProgress < 1 do
                task.wait(delayClick)
                self:SetIsFishingActive(true)
                clickProgress = clickProgress + (CurrentMinigameData.FishingClickPower)
            end

            FishingCompletedEvent:FireServer()
        end)
    end

    if not FishCaughtConnection then
        FishCaughtConnection = Net:RemoteEvent("ObtainedNewFishNotification").OnClientEvent:Connect(function(...)
            -- IsMinigameActive = false
            if not IsFishingActive then
                return
            end
            self:SetIsFishingActive(false)
            self:StartAutoFishing()
        end)
    end
end

function m:GetRayCastPosition()
    local rootPart = Core:GetHumanoidRootPart()
    if not rootPart then
        warn("HumanoidRootPart not found!")
        self:SetIsFishingActive(false)
        return
    end
    local rootCFrame = rootPart.CFrame
    local castPosition = rootCFrame + rootCFrame.LookVector * 12
    local rayOrigin = castPosition.Position
    local rayDirection = Vector3.new(0, -Constants.FishingDistance, 0)
    local filteredTargets = RaycastUtility:getFilteredTargets(Core.LocalPlayer)
    
    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = true
    raycastParams.RespectCanCollide = false
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = filteredTargets
    
    local raycastResult = workspace:Spherecast(rayOrigin, 2, rayDirection, raycastParams)
    return raycastResult
end

function m:StartAutoFishing()
    if not Window:GetConfigValue("AutoFishing") or self:GetIsFishingActive() then
        return
    end

    self:CreateConnections()
    local autoEquip = Window:GetConfigValue("AutoEquipFishingRod") or false

    if autoEquip and not self:isRodEquipped() then
        EquipToolFromHotbar:FireServer(1)
        return
    end

    if not self:isRodEquipped() then
        warn("No fishing rod equipped!")
        self:SetIsFishingActive(false)
        return
    end

    local autoSell = Window:GetConfigValue("AutoSellFish") or false
    if self:IsMaxInventory() and autoSell == true then
        FishingController:NoInventorySpace()
    end
    
    if self:IsMaxInventory() then
        warn("Inventory full, cannot fish!")
        self:SetIsFishingActive(false)
        return        
    end
    
    local raycastResult = self:GetRayCastPosition()
    if not raycastResult or not raycastResult.Instance then
        warn("Failed rod cast!")

        self:SetIsFishingActive(false)
        return
    end

    
    while Window:GetConfigValue("AutoFishing") and Core.IsWindowOpen do
        self:SetIsFishingActive(true)
        local chargeTime = workspace:GetServerTimeNow()
        local castPower = self:CalculateCastPower()
        local delayCast = self:GetElapsedFromPower(chargeTime, castPower)
        ChargeFishingRodRemote:InvokeServer(chargeTime - delayCast)

        if Window:GetConfigValue("AutoPerfectCast") then
            -- task.wait(delayCast)
            task.wait(0.2)
        end

        local startTime = workspace:GetServerTimeNow()
        local success, minigameData = RequestFishingMinigameStartedRemote:InvokeServer(raycastResult.Position.Y, castPower, startTime)
        if success then
            CurrentMinigameData = minigameData
            break
        end
        CancelFishingInputsRemote:InvokeServer()
    end
end

function m:StopAutoFishing()
    IsMinigameActive = false
    self:SetIsFishingActive(false)

    CancelFishingInputsRemote:InvokeServer()
    
    if FishCaughtConnection then
        FishCaughtConnection:Disconnect()
        FishCaughtConnection = nil
    end

    if TextEffectConnection then
        TextEffectConnection:Disconnect()
        TextEffectConnection = nil
    end
end

function m:GetNormalizedDelay(baseDelay, power)
	return baseDelay / power
end

function m:StartAutoCharge()
    if not Window:GetConfigValue("AutoInstantCatch") or self:GetIsFishingActive() then
        return
    end

    self:CreateConnections()

    local autoEquip = Window:GetConfigValue("AutoEquipFishingRod") or false
    if autoEquip and not self:isRodEquipped() then
        EquipToolFromHotbar:FireServer(1)
        return
    end

    if not self:isRodEquipped() then
        warn("No fishing rod equipped!")
        self:SetIsFishingActive(false)
        return
    end

    local raycastResult = self:GetRayCastPosition()
    while Window:GetConfigValue("AutoInstantCatch") and Core.IsWindowOpen do
        if not raycastResult or not raycastResult.Instance then
            task.wait(1)
            raycastResult = self:GetRayCastPosition()
            continue
        end

        local AutoInstantCatchLoop = coroutine.create(function()
            while Window:GetConfigValue("AutoInstantCatch") and Core.IsWindowOpen do
                CancelFishingInputsRemote:InvokeServer()
                local castPower = self:CalculateCastPower()
                
                local chargeTime = workspace:GetServerTimeNow()
                local success = ChargeFishingRodRemote:InvokeServer(chargeTime)
                if not success then
                    print("AutoInstantCatch: Failed to charge fishing rod, retrying...")
                    continue
                end
                
                if Window:GetConfigValue("AutoPerfectCast") then
                    task.wait(0.2)
                end
                
                local startTime = workspace:GetServerTimeNow()
                local success, minigameResult = RequestFishingMinigameStartedRemote:InvokeServer(raycastResult.Position.Y, castPower, startTime)
                
                if minigameResult == "Already fishing!" then
                    break
                end

                if minigameResult == "No fishing rod equipped!" then
                    EquipToolFromHotbar:FireServer(1)
                    continue
                end
                
                if not success then
                    print("AutoInstantCatch: Failed to start fishing minigame, retrying...", minigameResult)
                    continue
                end

                if minigameResult.FishingClickPower then
                    CurrentMinigameData = minigameResult
                end
                
                break
            end
        end)

        coroutine.resume(AutoInstantCatchLoop)

        local fishingArea = Core.LocalPlayer.PlayerGui.Events.Frame.Location.Label.Text or "Ocean"
        local areaData = Areas[fishingArea]
        local areaPowerBonus = areaData and areaData.ClickPowerMultiplier or 0
        
        local randomJitter = math.random(-5, 5) * 0.005

        local delayRetry = math.max(Window:GetConfigValue("AutoInstantCatchDelay") or 1.70, 0.1)
        if Window:GetConfigValue("AutoPerfectCast") then
            delayRetry = delayRetry + 0.2
        end

        task.wait(delayRetry)
    end

    self:StopAutoFishing()
end

return m