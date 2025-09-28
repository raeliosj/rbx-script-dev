local m = {}
local Window
local PlayerUtils
local Core
local BackpackConnnection

function m:Init(windowInstance, farmUtilsInstance, playerUtilsInstance, coreInstance)
    Window = windowInstance
    PlayerUtils = playerUtilsInstance
    Core = coreInstance

    task.spawn(function()
        self:StartAutoSubmitEventPlants()
    end)
end

function m:SubmitEventPlant(tool)
    if not tool or not tool:IsA("Tool") then
        warn("SubmitEventPlant: Invalid tool provided")
        return
    end

    if tool:GetAttribute("b") ~= "j" or not string.find(tool.Name, "Evo") then
        warn("SubmitEventPlant: Tool is not an event plant")
        return
    end

    local submitTask = function()
        wait(1) -- Small delay to ensure state is updated
        Core.GameEvents.TieredPlants.Submit:FireServer("Held")
        wait(1) -- Wait a bit to ensure submission is processed
    end

    PlayerUtils:AddToQueue(tool, 5, submitTask)
    return
end

function m:StartAutoSubmitEventPlants()
    local isEnabledAutoSubmit = Window:GetConfigValue("AutoSubmitSeedStagePlants") or false
    
    if not isEnabledAutoSubmit then
        return
    end

    for _, Tool in next, PlayerUtils:GetAllTools() do
        self:SubmitEventPlant(Tool)
    end

    BackpackConnnection =  Core:GetBackpack().ChildAdded:Connect(function(child)
        local isEnabledAutoSubmit = Window:GetConfigValue("AutoSubmitSeedStagePlants") or false
        
        if not isEnabledAutoSubmit then
            return
        end
        
        self:SubmitEventPlant(child)
    end)
end

function m:StopAutoSubmitEventPlants()
    if BackpackConnnection then
        BackpackConnnection:Disconnect()
        BackpackConnnection = nil
    end
end


return m