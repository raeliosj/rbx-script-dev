local m = {}

local Window
local Core

local BackpackConnection
local LastSubmitTime

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Core.GameEvents.WitchesBrew.UpdateCauldronVisuals.OnClientEvent:Connect(function(param)
        if not param and not param.Percentage then
            return
        end

        if param.Percentage == 0 then
            self:StartAutoSubmitEventPlants()
        end
    end)
 
    self:StartAutoSubmitEventPlants()
end

function m:StartAutoSubmitEventPlants()
    if not Window:GetConfigValue("AutoSubmitGhoulQuest") then
        return
    end

    if not BackpackConnection then
        BackpackConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
            if not Window:GetConfigValue("AutoSubmitGhoulQuest") then
                return
            end

            -- Debounce to prevent multiple submissions in quick succession
            if tick() - (LastSubmitTime or 0) < 5 then
                return
            end
            
            if child:GetAttribute("b") ~= "j" then
                return
            end

            Core.GameEvents.WitchesBrew.SubmitItemToCauldron:InvokeServer("All")
            LastSubmitTime = tick()
        end)
    end

    Core.GameEvents.WitchesBrew.SubmitItemToCauldron:InvokeServer("All")
    LastSubmitTime = tick()
end

function m:StopAutoSubmitEventPlants()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
end

return m