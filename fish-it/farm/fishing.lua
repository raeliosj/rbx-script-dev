local m = {}

local Window
local Core
local Player
local Spot

local Net
local ChargeFishingRodRemote
local FishingCompletedEvent
local Replion
local Constants
local RaycastUtility
local RequestFishingMinigameStartedRemote
local CancelFishingInputsRemote
local EquipToolFromHotbar

local TextEffectConnection
local DataReplion
local IsFishingActive = false
local LastFishingActivityTime = tick()

function m:Init(_window, _core, _player, _spot)
    Window = _window
    Core = _core
    Player = _player
    Spot = _spot

    Constants = require(Core.ReplicatedStorage.Shared.Constants)
    RaycastUtility = require(Core.ReplicatedStorage.Shared.RaycastUtility)
    Net = require(Core.ReplicatedStorage.Packages.Net)
    Replion = require(Core.ReplicatedStorage.Packages.Replion)
    
    DataReplion = Replion.Client:WaitReplion("Data")

    ChargeFishingRodRemote = Net:RemoteFunction("ChargeFishingRod")
    FishingCompletedEvent = Net:RemoteEvent("FishingCompleted")
    RequestFishingMinigameStartedRemote = Net:RemoteFunction("RequestFishingMinigameStarted")
    CancelFishingInputsRemote = Net:RemoteFunction("CancelFishingInputs")
    EquipToolFromHotbar = Net:RemoteEvent("EquipToolFromHotbar")
    
    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoFishing")
        end, 
        function()
            self:StartAutoFishing()
        end
    )
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
    if TextEffectConnection then
        return
    end

    TextEffectConnection = Net:RemoteEvent("ReplicateTextEffect").OnClientEvent:Connect(function(data)
        if Window:GetConfigValue("CompleteFishingMethod") == "Looping" then
            return
        end
        
        local localPlayerCharacter = Core:GetCharacter()
        if not localPlayerCharacter then return end

        local attachTo = data.TextData and data.TextData.AttachTo
        local container = data.Container

        if attachTo ~= localPlayerCharacter.Head and container ~= localPlayerCharacter.Head then
            return
        end

        local completeRetry = math.max(Window:GetConfigValue("CompleteDelay") or 1.7, 0.1)
        local countDelay = 0

        while countDelay <= completeRetry do
            task.wait(0.1)
            countDelay = countDelay + 0.1
            self:SetIsFishingActive(true)
        end

        FishingCompletedEvent:FireServer()

        if not IsFishingActive then
            info("Auto Fishing is not active.")
            return
        end

        self:SetIsFishingActive(false)
        if Window:GetConfigValue("AutoFishingMethod") == "Fast" then
            task.wait(0.1)
            self:StartAutoFastFishing()
        end
    end)
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

function m:FishingUI(enabled)
    Core.LocalPlayer.PlayerGui.Charge.Main.Visible = enabled
    Core.LocalPlayer.PlayerGui.Fishing.Main.Visible = enabled
end

function m:SetServerAutoFishing(enabled)
    if enabled and not DataReplion:GetExpect("AutoFishing") then
        coroutine.wrap(function()
            Net:RemoteFunction("UpdateAutoFishingState"):InvokeServer(true)
        end)()
    elseif not enabled and DataReplion:GetExpect("AutoFishing") then
        coroutine.wrap(function()
            Net:RemoteFunction("UpdateAutoFishingState"):InvokeServer(false)
        end)()
    end
end

function m:CreateFishingLoop()
    local totalRetry = 0
    local raycastResult = self:GetRayCastPosition()
    local fishingPosition = raycastResult and raycastResult.Position and raycastResult.Position.Y or -31

    while Window:GetConfigValue("AutoFishing") and Core.IsWindowOpen do
        self:SetIsFishingActive(true)
        
        if Window:GetConfigValue("ChargeFishingMethod") == "Toggle Auto" then
            self:SetServerAutoFishing(true)
        end

        coroutine.wrap(function()
            CancelFishingInputsRemote:InvokeServer()
        end)()
        
        if totalRetry >= 10 then
            Window:ShowError("Fishing", "Max retries reached for fishing.")
            self:SetIsFishingActive(false)
            break
        end

        local chargeTime = workspace:GetServerTimeNow()
        local success = ChargeFishingRodRemote:InvokeServer(chargeTime)
        if not success then
            totalRetry = totalRetry + 1
            continue
        end

        if Window:GetConfigValue("ChargeFishingMethod") == "Use Delay" then
            task.wait(0.2)
        end

        local startTime = workspace:GetServerTimeNow()
        local castPower = Constants:GetPower(chargeTime - startTime)
        local success, minigameResult = RequestFishingMinigameStartedRemote:InvokeServer(fishingPosition, castPower, startTime)
        
        if Window:GetConfigValue("ChargeFishingMethod") == "Toggle Auto" then
            self:SetServerAutoFishing(false)
        end

        if minigameResult == "Already fishing!" then
            break
        end
        
        if minigameResult == "No fishing rod equipped!" then
            EquipToolFromHotbar:FireServer(1)
            continue
        end
        
        if not success then
            totalRetry = totalRetry + 1
            continue
        end
        
        break
    end
end

function m:StartAutoFastFishing()
    if not Window:GetConfigValue("AutoFishing") then
        Window:ShowWarning("Fishing", "Auto Fishing has been disabled.")
        return
    end

    if Window:GetConfigValue("AutoFishingMethod") ~= "Fast" then
        Window:ShowWarning("Fishing", "Invalid fishing method selected.")
        return
    end

    if self:GetIsFishingActive() then
        info("Auto Fast Fishing is already active.")
        return
    end

    self:SetIsFishingActive(true)

    local coroutineFishingLoop = coroutine.create(function()
        self:CreateFishingLoop()
    end)

    coroutine.resume(coroutineFishingLoop)
end

function m:StartAutoInstantFishing()
    while Window:GetConfigValue("AutoFishing") and
        Core.IsWindowOpen and
        Window:GetConfigValue("AutoFishingMethod") == "Instant" do
        self:SetIsFishingActive(true)

        local coroutineFishingLoop = coroutine.create(function()
            self:CreateFishingLoop()
        end)
        coroutine.resume(coroutineFishingLoop)

        local delayRetry = math.max(Window:GetConfigValue("CancelDelay") or 1.7, 0.1)
        task.wait(delayRetry)
    end

    self:StopAutoFishing()
end

function m:StartAutoComplete()
    while Window:GetConfigValue("AutoFishing") and 
        Core.IsWindowOpen and
        Window:GetConfigValue("CompleteFishingMethod") == "Looping" do
        
        FishingCompletedEvent:FireServer()

        local delayRetry = math.max(Window:GetConfigValue("CompleteDelay") or 1.70, 0.1)
        task.wait(delayRetry)
    end
end

function m:StartAutoFishing()
    if self:GetIsFishingActive() then
        return
    end

    self:FishingUI(false)
    
    if Window:GetConfigValue("CompleteFishingMethod") == "Looping" then
        task.spawn(function()
            self:StartAutoComplete()
        end)
    else
        self:CreateConnections()
    end

    if DataReplion:GetExpect("EquippedType") ~= "Fishing Rods" then
        EquipToolFromHotbar:FireServer(1)
    end

    if Window:GetConfigValue("AutoFishingMethod") == "Fast" then
        self:StartAutoFastFishing()
    elseif Window:GetConfigValue("AutoFishingMethod") == "Instant" then
        self:StartAutoInstantFishing()
    else
        Window:ShowWarning("Fishing", "Please select a valid fishing method!")
    end
end

function m:StopAutoFishing()
    self:SetServerAutoFishing(false)
    self:SetIsFishingActive(false)

    CancelFishingInputsRemote:InvokeServer()
    Net:RemoteEvent("UnequipToolFromHotbar"):FireServer()

    if TextEffectConnection then
        TextEffectConnection:Disconnect()
        TextEffectConnection = nil
    end

    self:FishingUI(true)
end

return m