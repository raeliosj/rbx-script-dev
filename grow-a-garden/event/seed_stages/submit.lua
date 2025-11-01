local m = {}

local Window
local Core
local Player

local BackpackConnection

function m:Init(_window, _core, _player)
    Window = _window
    Core = _core
    Player = _player

    -- _core:MakeLoop(function()
    --     return Window:GetConfigValue("AutoSubmitSeedStagePlants")
    -- end, function()
    --     self:StartAutoSubmitEventPlants()
    -- end)

    BackpackConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
        self:StartAutoSubmitEventPlants()
    end)

    self:StartAutoSubmitEventPlants()
end

function m:StartAutoSubmitEventPlants()
    if not Window:GetConfigValue("AutoSubmitSeedStagePlants") then
        return
    end
    Core.ReplicatedStorage.GameEvents.TieredPlants.Submit:FireServer("All")
end

-- function m:SubmitEventPlant(tool)
--     if not tool or not tool:IsA("Tool") then
--         return false
--     end

--     local tasks = Player:GetTaskByTool(tool)
--     if tasks then
--         print("Tool", tool.Name, "already has pending tasks, skipping...")
--         return false
--     end

--     local isEvo = string.find(tool.Name, "Evo")
--     local isIV = string.find(tool.Name, "IV")
--     if tool:GetAttribute("b") ~= "j" or (not isEvo or isIV) then
--         return false
--     end

--     print("Queuing event plant for submission:", tool.Name)
    
--     local submitTask = function()
--         print("Submitting event plant:", tool.Name)
--         local success = pcall(function()
--             Core.ReplicatedStorage.GameEvents.TieredPlants.Submit:FireServer("Held")
--         end)
        
--         if success then
--             print("Successfully submitted:", tool.Name)
--         else
--             warn("Failed to submit:", tool.Name)
--         end
        
--         task.wait(0.15)
--     end

--     Player:AddToQueue(tool, 5, function()
--         submitTask()
--     end)
    
--     return true
-- end

-- function m:StartAutoSubmitEventPlants()
--     for _, Tool in next, Player:GetAllTools() do
--         self:SubmitEventPlant(Tool)
--     end
    
--     task.wait(2) -- Longer wait between cycles to avoid spam
-- end

function m:StopAutoSubmitEventPlants()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
end

return m