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

local CurrentMinigameData = nil

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
    
    self:CreateConnections()

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
        local localPlayerCharacter = Core:GetCharacter()
        if not localPlayerCharacter then return end

        local attachTo = data.TextData and data.TextData.AttachTo
        local container = data.Container

        if attachTo ~= localPlayerCharacter.Head and container ~= localPlayerCharacter.Head then
            return
        end

        if not CurrentMinigameData then
            self:SetIsFishingActive(false)
            warn("No current minigame data available for text effect.")
            return
        end

        local delayClick = math.max(Window:GetConfigValue("AutoInstantCatchDelayPerClickPower") or 0.25, 0.1)
        local clickProgress = 0
        local currentFishingPower = CurrentMinigameData.FishingClickPower or 0.1
        
        while clickProgress < 1 do
            self:SetIsFishingActive(true)
            clickProgress = clickProgress + currentFishingPower
            
            task.wait(delayClick)
        end

        if Window:GetConfigValue("AutoTeleportToFishingSpot") then
            local configLockPosition = Window:GetConfigValue("LockPlayerPosition")
            local lockAtPosition = CFrame.new(0.0, 0.0, 0.0)

            local values = string.split(configLockPosition, ",")
            for i, v in ipairs(values) do
                values[i] = tonumber(v)
            end

            if #values == 3 then
                lockAtPosition = CFrame.new(Vector3.new(values[1], values[2], values[3]))
            elseif #values == 12 then
                lockAtPosition = CFrame.new(
                    values[1], values[2], values[3],
                    values[4], values[5], values[6],
                    values[7], values[8], values[9],
                    values[10], values[11], values[12]
                )
            else
                warn("Lock position string is invalid.")
                return
            end

            Player:TeleportToPosition(lockAtPosition)
        end

        pcall(function()
            FishingCompletedEvent:FireServer()
        end)
        -- Wait server to process fishing completion
        task.wait(0.05)
        
        if not IsFishingActive then
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
    if Window:GetConfigValue("AutoTeleportToFishingSpot") then
        currentFishingPosition = Player:GetPosition()
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

    local totalRetry = 0
    local raycastResult = self:GetRayCastPosition()
    local fishingPosition = raycastResult and raycastResult.Position and raycastResult.Position.Y or 0


    while Window:GetConfigValue("AutoFishing") and Core.IsWindowOpen do
        self:SetIsFishingActive(true)
        
        self:SetServerAutoFishing(true)
        CancelFishingInputsRemote:InvokeServer()
        
        if totalRetry >= 10 then
            Window:ShowError("Max retries reached for fishing.", "Auto Fishing Stopped")
            self:SetIsFishingActive(false)
            break
        end

        local chargeTime = workspace:GetServerTimeNow()
        local success = ChargeFishingRodRemote:InvokeServer(chargeTime)
        if not success then
            warn(string.format("Retrying... %s", tostring(totalRetry)), "Failed to charge fishing rod")
            totalRetry = totalRetry + 1
            continue
        end

        local castPower = 0.5
        local startTime = workspace:GetServerTimeNow()
        local success, minigameResult = RequestFishingMinigameStartedRemote:InvokeServer(fishingPosition, castPower, startTime)

        self:SetServerAutoFishing(false)
        if minigameResult == "Already fishing!" then
            break
        end
        
        if minigameResult == "No fishing rod equipped!" then
            EquipToolFromHotbar:FireServer(1)
            continue
        end
        
        if not success then
            totalRetry = totalRetry + 1
            warn(string.format("Retrying... %s", tostring(totalRetry)), string.format("Failed to start fishing minigame, %s", tostring(minigameResult)))
            continue
        end
        
        if type(minigameResult) == "table" and minigameResult.FishingClickPower then
            CurrentMinigameData = minigameResult
        end
        
        break
    end

    if Window:GetConfigValue("AutoTeleportToFishingSpot") then
        local configLockPosition = Window:GetConfigValue("LockPlayerPosition")
        local lockAtPosition = CFrame.new(0.0, 0.0, 0.0)

        local values = string.split(configLockPosition, ",")
        for i, v in ipairs(values) do
            values[i] = tonumber(v)
        end

        if #values == 3 then
            lockAtPosition = CFrame.new(Vector3.new(values[1], values[2], values[3]))
        elseif #values == 12 then
            lockAtPosition = CFrame.new(
                values[1], values[2], values[3],
                values[4], values[5], values[6],
                values[7], values[8], values[9],
                values[10], values[11], values[12]
            )
        else
            warn("Lock position string is invalid.")
            return
        end

        Player:TeleportToPosition(lockAtPosition)
    end
end

function m:StartAutoFastFishing()
    if not Window:GetConfigValue("AutoFishing") then
        Window:ShowWarning("Auto Fishing has been disabled.")
        return
    end

    if Window:GetConfigValue("AutoFishingMethod") ~= "Fast" then
        Window:ShowWarning("Invalid fishing method selected.")
        return
    end

    if self:GetIsFishingActive() then
        warn("You must not be actively fishing to use Fast Catch.")
        return
    end

    self:CreateConnections()
    self:FishingUI(false)

    local coroutineFishingLoop = coroutine.create(function()
        self:CreateFishingLoop()
    end)

    coroutine.resume(coroutineFishingLoop)
end

function m:StartAutoInstantFishing()
    if not Window:GetConfigValue("AutoFishing") then
        Window:ShowWarning("Auto Fishing has been disabled.")
        return
    end

    if Window:GetConfigValue("AutoFishingMethod") ~= "Instant" then
        Window:ShowWarning("Invalid fishing method selected.")
        return
    end

    if self:GetIsFishingActive() then
        warn("You must not be actively fishing to use Instant Catch.")
        return
    end

    self:FishingUI(false)
    self:CreateConnections()

    if DataReplion:GetExpect("EquippedType") ~= "Fishing Rods" then
        EquipToolFromHotbar:FireServer(1)
        return
    end

    local raycastResult = self:GetRayCastPosition()
    while Window:GetConfigValue("AutoFishing") and Core.IsWindowOpen and Window:GetConfigValue("AutoFishingMethod") == "Instant" do
        self:SetIsFishingActive(true)

        local coroutineFishingLoop = coroutine.create(function()
            self:CreateFishingLoop()
        end)
        coroutine.resume(coroutineFishingLoop)

        local delayRetry = math.max(Window:GetConfigValue("AutoInstantCatchDelay") or 1.70, 0.1)
        task.wait(delayRetry)
    end

    self:StopAutoFishing()
end

function m:StartAutoFishing()
    if Window:GetConfigValue("AutoFishingMethod") == "Fast" then
        self:StartAutoFastFishing()
    elseif Window:GetConfigValue("AutoFishingMethod") == "Instant" then
        self:StartAutoInstantFishing()
    else
        Window:ShowWarning("Please select a valid fishing method!")
    end
end

function m:StopAutoFishing()
    self:SetServerAutoFishing(false)
    self:SetIsFishingActive(false)

    CancelFishingInputsRemote:InvokeServer()

    if TextEffectConnection then
        TextEffectConnection:Disconnect()
        TextEffectConnection = nil
    end

    CurrentMinigameData = nil
    self:FishingUI(true)
end

return m