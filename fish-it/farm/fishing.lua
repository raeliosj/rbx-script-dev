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
            self:CatchFish()
        end,
        0.1
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

function m:CatchFish()
    while IsMinigameActive do
        FishingCompletedEvent:FireServer()
        task.wait(0.1)
    end
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
    local minCastPower = 0.9

    if isAutoPerfect then
        minCastPower = 0.95
    end

    -- Generate a random number between minCastPower and 0.9999
    local castPower = math.random() * (0.9999 - minCastPower) + minCastPower
    return castPower
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

            IsMinigameActive = true
            self:CatchFish()
        end)
    end

    if not FishCaughtConnection then
        FishCaughtConnection = Net:RemoteEvent("FishingStopped").OnClientEvent:Connect(function(fishName, fishData)
            IsMinigameActive = false
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
        local castPower = self:CalculateCastPower()
        local delayCast = math.max(Window:GetConfigValue("AutoInstantCatchDelay") or 1.30, 0.1)
        local chargeTime = workspace:GetServerTimeNow() - delayCast
        ChargeFishingRodRemote:InvokeServer(chargeTime)
        
        local success, currentMinigameData = RequestFishingMinigameStartedRemote:InvokeServer(raycastResult.Position.Y, castPower)
        if success then
            break
        end
        task.wait(0.1)
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
    
    self:SetIsFishingActive(false)
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
        self:SetIsFishingActive(true)
        if not raycastResult or not raycastResult.Instance then
            task.wait(0.1)
            raycastResult = self:GetRayCastPosition()
            continue
        end
        
        task.spawn(function()
            CancelFishingInputsRemote:InvokeServer()
            task.wait(0.1)
            
            local chargeTime = workspace:GetServerTimeNow()
            ChargeFishingRodRemote:InvokeServer(chargeTime)
            
            task.wait(0.1)
            coroutine.wrap(function()
                local castPower = self:CalculateCastPower()
                RequestFishingMinigameStartedRemote:InvokeServer(raycastResult.Position.Y, castPower)
            end)()
        end)
                
        local delayCast = math.max(Window:GetConfigValue("AutoInstantCatchDelay") or 1.30, 0.1)
        task.wait(delayCast)
    end
end

return m