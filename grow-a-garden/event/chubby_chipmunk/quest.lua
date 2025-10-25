local m = {}

local Window
local Core

local BackpackConnection
local LastSubmitTime

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Core.ReplicatedStorage.GameEvents.SpecialEventStarted.OnClientEvent:Connect(function(weather)
        self:StopAutoSubmitEventPlants()
        task.wait(300)
        self:StartAutoSubmitEventPlants()
    end)

    task.spawn(function()
        self:StartAutoSubmitEventPlants()
    end)
end

function m:StartAutoSubmitEventPlants()
    if not Window:GetConfigValue("AutoSubmitSeedStagePlants") then
        return
    end

    if not BackpackConnection then
        BackpackConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
            -- Debounce to prevent multiple submissions in quick succession
            if tick() - (LastSubmitTime or 0) < 5 then
                return
            end
            
            if child:GetAttribute("b") ~= "j" then
                return
            end

            Core.ReplicatedStorage.GameEvents.SubmitChipmunkFruit:FireServer("All")
            LastSubmitTime = tick()
        end)
    end

    Core.ReplicatedStorage.GameEvents.SubmitChipmunkFruit:FireServer("All")
    LastSubmitTime = tick()
end

function m:StopAutoSubmitEventPlants()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
end

return m