local m = {}

-- Load Core module with error handling
local Core
local AntiAFKConnection -- Store the connection reference
local ReconnectConnection

-- Queue system for tool equipping
local ToolQueue = {
    Queue = {},
    IsProcessing = false,
    CurrentTask = nil
}

function m:Init(_core)
    if not _core then
        error("Player:Init - Core module is required")
    end
    Core = _core

    -- Store the connection so we can disconnect it later
    AntiAFKConnection = Core.LocalPlayer.Idled:Connect(function()
        Core.VirtualUser:CaptureController()
        Core.VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK: Clicked to prevent idle kick")
    end)

    ReconnectConnection = Core.GuiService.ErrorMessageChanged:Connect(function()
        local IsSingle = #Core.Players:GetPlayers() <= 1

        --// Join a different server if the player is solo
        if IsSingle then
            Core:HopServer()
            return
        end

        Core:Rejoin()
    end)
    
    -- Initialize queue system
    ToolQueue.Queue = {}
    ToolQueue.IsProcessing = false
    ToolQueue.CurrentTask = nil
end

function m:RemoveAntiAFK()
    -- Disconnect the stored connection
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
        print("Anti-AFK: Disconnected idle connection")
    else
        print("Anti-AFK: No connection to disconnect")
    end
end

function m:RemoveReconnect()
    if ReconnectConnection then
        ReconnectConnection:Disconnect()
        ReconnectConnection = nil
        print("Reconnect: Disconnected error message connection")
    else
        print("Reconnect: No connection to disconnect")
    end
end

-- ===== QUEUE SYSTEM =====

-- Add task to queue
-- tool: Tool object to equip
-- priority: Number (lower = higher priority, default = 5)
-- taskFunction: Function to execute after tool is equipped (optional)
-- callback: Function to call when task is complete (optional)
function m:AddToQueue(_tool, _priority, _taskFunction, _callback)
    _priority = _priority or 5

    if not _tool or not _tool:IsA("Tool") then
        warn("Player:AddToQueue - Invalid tool provided")
        if _callback then _callback(false, "Invalid tool") end
        return false
    end
    
    local task = {
        Id = tick(), -- Unique identifier
        Tool = _tool,
        Priority = _priority,
        TaskFunction = _taskFunction,
        Callback = _callback,
        Timestamp = tick()
    }

    -- Insert task into queue
    table.insert(ToolQueue.Queue, task)

    print("🔧 Added tool to queue:", _tool.Name, "Priority:", _priority, "Queue size:", #ToolQueue.Queue)

    -- Start processing if not already processing
    if not ToolQueue.IsProcessing then
        print("🔧 Queue is already processing or empty, skipping...", self:GetQueueStatus())

        self:ProcessQueue()
    end
    
    return true
end

-- Process the queue
function m:ProcessQueue()
    if ToolQueue.IsProcessing or #ToolQueue.Queue == 0 then
        print("🔧 Queue is already processing or empty, skipping...", self:GetQueueStatus())
        return -- Already processing or queue is empty
    end

    ToolQueue.IsProcessing = true

    while #ToolQueue.Queue > 0 do
        -- Sort queue by priority and timestamp to ensure correct order
        table.sort(ToolQueue.Queue, function(a, b)
            if a.Priority == b.Priority then
                return a.Timestamp < b.Timestamp -- Earlier added first
            end
            return a.Priority < b.Priority -- Lower priority number first
        end)
        local currentTask = table.remove(ToolQueue.Queue, 1) -- Take first (highest priority) task
        ToolQueue.CurrentTask = currentTask

        print("🔧 Processing tool queue task:", currentTask.Tool.Name)
        
        -- Equip the tool, ensure it is equipped before proceeding
        if self:GetEquippedTool() ~= currentTask.Tool then
            self:EquipTool(currentTask.Tool)
            task.wait(0.5) -- Small delay to ensure tool is equipped
        end
       
        -- Execute task function if provided and wait for completion
        local success, result = pcall(function()
            return currentTask.TaskFunction()
        end)
        
        if currentTask.Callback then
            local callbackSuccess, callbackErr = pcall(currentTask.Callback, success, result)
            if not callbackSuccess then
                warn("Callback error for tool:", currentTask.Tool.Name, "Error:", callbackErr)
            end
        end
        
        print("Task execution finished")
        -- task.wait(0.5)
        self:UnequipTool() -- Unequip after task

        ToolQueue.CurrentTask = nil
        task.wait(0.1) -- Small delay between tasks
    end

    ToolQueue.IsProcessing = false
    print("🔧 Queue processing completed")
end

-- Get current queue status
function m:GetQueueStatus()
    return {
        queueSize = #ToolQueue.Queue,
        isProcessing = ToolQueue.IsProcessing,
        currentTask = ToolQueue.CurrentTask and ToolQueue.CurrentTask.Tool.Name or nil
    }
end

-- Clear the queue
function m:ClearQueue()
    ToolQueue.Queue = {}
    ToolQueue.IsProcessing = false
    ToolQueue.CurrentTask = nil
    print("🔧 Tool queue cleared")
end

-- Remove specific task from queue by tool name
function m:RemoveFromQueue(_toolName)
    if not _toolName then return false end

    for i = #ToolQueue.Queue, 1, -1 do
        if ToolQueue.Queue[i].Tool.Name == _toolName then
            table.remove(ToolQueue.Queue, i)
            print("🔧 Removed from queue:", _toolName)
            return true
        end
    end
    
    return false
end

function m:GetTaskByTool(_tool)
    local tasks = {}
    if not _tool then return nil end

    for _, task in ipairs(ToolQueue.Queue) do
        if task.Tool == _tool then
            table.insert(tasks, task)
        end
    end

    return #tasks > 0 and tasks or nil
end

function m:EquipTool(_tool)
    -- Validate inputs
    if not _tool or not _tool:IsA("Tool") then 
        warn("Player:EquipTool - Invalid tool provided")
        return false 
    end

    local humanoid = Core:GetHumanoid()
    local backpack = Core:GetBackpack()

    if not humanoid then
        warn("Player:EquipTool - Humanoid not found")
        return false
    end

    if not backpack then
        warn("Player:EquipTool - Backpack not found")
        return false
    end

    if _tool.Parent ~= backpack then
        warn("Player:EquipTool - Tool not in backpack")
        return false 
    end
    
    -- Try to equip with error handling
    local success, err = pcall(function()
        humanoid:EquipTool(_tool)
    end)
    
    if not success then
        warn("Player:EquipTool - Failed to equip:", err)
        return false
    end
    
    return true
end

function m:UnequipTool()    
    local humanoid = Core:GetHumanoid()
    if not humanoid then
        warn("Player:UnequipTool - Humanoid not found")
        return false
    end
    
    -- Try to unequip with error handling
    local success, err = pcall(function()
        humanoid:UnequipTools()
    end)
    
    if not success then
        warn("Player:UnequipTool - Failed to unequip:", err)
        return false
    end
    
    return true
end

function m:GetEquippedTool()
    local character = Core:GetCharacter()
    if not character then 
        warn("Player:GetEquippedTool - Character not found")
        return nil 
    end

    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
    
    return nil
end

function m:MoveToPosition(_position)
    local humanoid = Core:GetHumanoid()
    if humanoid then
        humanoid:MoveTo(_position)
    else
        warn("Player:MoveToPosition - Humanoid not found")
    end
end

function m:TeleportToPosition(_position)
    local hrp = Core:GetHumanoidRootPart()
    if hrp then
        hrp.CFrame = CFrame.new(_position)
        return true
    end
    return false
end

function m:GetPosition()
    local hrp = Core:GetHumanoidRootPart()
    return hrp and hrp.Position or Vector3.new(0, 0, 0)
end

function m:GetAllTools()
    local backpack = Core:GetBackpack()
    if not backpack then 
        warn("Player:GetAllTools - Backpack not found")
        return {} 
    end
    
    local tools = {}
    local success, err = pcall(function()
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end)
    
    if not success then
        warn("Player:GetAllTools - Error getting tools:", err)
        return {}
    end
    
    return tools
end

function m:GetTool(_toolName)
    if not _toolName or type(_toolName) ~= "string" then
        warn("Player:GetTool - Invalid tool name")
        return nil
    end
    
    local backpack = Core:GetBackpack()
    if not backpack then
        warn("Player:GetTool - Backpack not found")
        return nil 
    end
    
    local tool = nil
    local success, err = pcall(function()
        tool = backpack:FindFirstChild(_toolName)
        if tool and not tool:IsA("Tool") then
            tool = nil
        end
    end)
    
    if not success then
        warn("Player:GetTool - Error finding tool:", err)
        return nil
    end
    
    if not tool then
        warn("Player:GetTool - Tool not found:", _toolName)
    end
    
    return tool
end

return m