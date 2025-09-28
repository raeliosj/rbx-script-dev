local Player = {}

-- Load Core module with error handling
local Core
local antiAFKConnection -- Store the connection reference

-- Queue system for tool equipping
local ToolQueue = {
    queue = {},
    isProcessing = false,
    currentTask = nil
}

function Player:Init(core)
    if not core then
        error("Player:Init - Core module is required")
    end
    Core = core

    -- Store the connection so we can disconnect it later
    antiAFKConnection = Core.LocalPlayer.Idled:Connect(function()
        Core.VirtualUser:CaptureController()
        Core.VirtualUser:ClickButton2(Vector2.new())
        print("Anti-AFK: Clicked to prevent idle kick")
    end)
    
    -- Initialize queue system
    ToolQueue.queue = {}
    ToolQueue.isProcessing = false
    ToolQueue.currentTask = nil
end

function Player:RemoveAntiAFK()
    -- Disconnect the stored connection
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
        print("Anti-AFK: Disconnected idle connection")
    else
        print("Anti-AFK: No connection to disconnect")
    end
end

function Player:EquipTool(Tool)
    -- Validate inputs
    if not Tool or not Tool:IsA("Tool") then 
        warn("Player:EquipTool - Invalid tool provided")
        return false 
    end
    
    local Character = Core:GetCharacter()
    if not Character then 
        warn("Player:EquipTool - Character not found")
        return false 
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    local Backpack = Core:GetBackpack()
    
    if not Humanoid then
        warn("Player:EquipTool - Humanoid not found")
        return false
    end
    
    if not Backpack then
        warn("Player:EquipTool - Backpack not found")
        return false
    end
    
    if Tool.Parent ~= Backpack then 
        warn("Player:EquipTool - Tool not in backpack")
        return false 
    end
    
    -- Try to equip with error handling
    local success, err = pcall(function()
        Humanoid:EquipTool(Tool)
    end)
    
    if not success then
        warn("Player:EquipTool - Failed to equip:", err)
        return false
    end
    
    return true
end

-- ===== QUEUE SYSTEM =====

-- Add task to queue
-- tool: Tool object to equip
-- priority: Number (lower = higher priority, default = 5)
-- taskFunction: Function to execute after tool is equipped (optional)
-- callback: Function to call when task is complete (optional)
function Player:AddToQueue(tool, priority, taskFunction, callback)
    priority = priority or 5
    
    if not tool or not tool:IsA("Tool") then
        warn("Player:AddToQueue - Invalid tool provided")
        if callback then callback(false, "Invalid tool") end
        return false
    end
    
    local task = {
        id = tick(), -- Unique identifier
        tool = tool,
        priority = priority,
        taskFunction = taskFunction,
        callback = callback,
        timestamp = tick()
    }
    
    -- Insert task in priority order (lower priority number = higher priority)
    local inserted = false
    for i, existingTask in ipairs(ToolQueue.queue) do
        if priority < existingTask.priority then
            table.insert(ToolQueue.queue, i, task)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(ToolQueue.queue, task)
    end
    
    print("🔧 Added tool to queue:", tool.Name, "Priority:", priority, "Queue size:", #ToolQueue.queue)
    
    -- Start processing if not already processing
    if not ToolQueue.isProcessing then
        self:ProcessQueue()
    end
    
    return true
end

-- Process the queue
function Player:ProcessQueue()
    if ToolQueue.isProcessing then
        return -- Already processing
    end
    
    if #ToolQueue.queue == 0 then
        return -- Queue is empty
    end
    
    ToolQueue.isProcessing = true
    
    task.spawn(function()
        while #ToolQueue.queue > 0 do
            local currentTask = table.remove(ToolQueue.queue, 1) -- Take first (highest priority) task
            ToolQueue.currentTask = currentTask
            
            print("🔧 Processing tool queue task:", currentTask.tool.Name)
            
            -- Equip the tool
            local success, err = pcall(function()
                local equipSuccess = self:EquipTool(currentTask.tool)
                if not equipSuccess then
                    error("Failed to equip tool")
                end
                
                -- Execute task function if provided
                if currentTask.taskFunction then
                    wait(0.1) -- Small delay to ensure tool is equipped
                    local taskSuccess, taskErr = pcall(currentTask.taskFunction)
                    if not taskSuccess then
                        warn("Task function failed:", taskErr)
                    end
                end
            end)

            self:UnequipTool() -- Unequip after task
            
            -- Call callback if provided
            if currentTask.callback then
                task.spawn(function()
                    local callbackSuccess, callbackErr = pcall(currentTask.callback, success, err)
                    if not callbackSuccess then
                        warn("Callback function failed:", callbackErr)
                    end
                end)
            end
            
            if not success then
                warn("🔧 Queue task failed:", err)
            else
                print("✅ Queue task completed:", currentTask.tool.Name)
            end
            
            ToolQueue.currentTask = nil
            wait(0.1) -- Small delay between tasks
        end
        
        ToolQueue.isProcessing = false
        print("🔧 Queue processing completed")
    end)
end

-- Get current queue status
function Player:GetQueueStatus()
    return {
        queueSize = #ToolQueue.queue,
        isProcessing = ToolQueue.isProcessing,
        currentTask = ToolQueue.currentTask and ToolQueue.currentTask.tool.Name or nil
    }
end

-- Clear the queue
function Player:ClearQueue()
    ToolQueue.queue = {}
    ToolQueue.isProcessing = false
    ToolQueue.currentTask = nil
    print("🔧 Tool queue cleared")
end

-- Remove specific task from queue by tool name
function Player:RemoveFromQueue(toolName)
    if not toolName then return false end
    
    for i = #ToolQueue.queue, 1, -1 do
        if ToolQueue.queue[i].tool.Name == toolName then
            table.remove(ToolQueue.queue, i)
            print("🔧 Removed from queue:", toolName)
            return true
        end
    end
    
    return false
end

function Player:UnequipTool()
    local Character = Core:GetCharacter()
    if not Character then 
        warn("Player:UnequipTool - Character not found")
        return false 
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then
        warn("Player:UnequipTool - Humanoid not found")
        return false
    end
    
    -- Try to unequip with error handling
    local success, err = pcall(function()
        Humanoid:UnequipTools()
    end)
    
    if not success then
        warn("Player:UnequipTool - Failed to unequip:", err)
        return false
    end
    
    return true
end

function Player:GetEquippedTool()
    local workspace = Core.Workspace
    local player

    for _, item in ipairs(workspace:GetChildren()) do
        if item.Name == Core.LocalPlayer.Name and item:FindFirstChildOfClass("Tool") then
            player = item
            break
        end
    end

    if not player then
        warn("Player:GetEquippedTool - Player model not found in workspace")
        return nil
    end

    for _, item in ipairs(player:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end

    warn("Player:GetEquippedTool - No tool equipped")
    return nil
end

function Player:TeleportToPosition(Position)
    local HRP = Core:GetHumanoidRootPart()
    if HRP then
        HRP.CFrame = CFrame.new(Position)
        return true
    end
    return false
end

function Player:GetPosition()
    local HRP = Core:GetHumanoidRootPart()
    return HRP and HRP.Position or Vector3.new(0, 0, 0)
end

function Player:GetAllTools()
    self:UnequipTool() -- Ensure no tool is equipped before fetching
    wait(0.5) -- Small delay to ensure state is updated
    local Backpack = Core:GetBackpack()
    if not Backpack then 
        warn("Player:GetAllTools - Backpack not found")
        return {} 
    end
    
    local tools = {}
    local success, err = pcall(function()
        for _, item in ipairs(Backpack:GetChildren()) do
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

function Player:GetTool(toolName)
    if not toolName or type(toolName) ~= "string" then
        warn("Player:GetTool - Invalid tool name")
        return nil
    end
    
    local Backpack = Core:GetBackpack()
    if not Backpack then 
        warn("Player:GetTool - Backpack not found")
        return nil 
    end
    
    local tool = nil
    local success, err = pcall(function()
        tool = Backpack:FindFirstChild(toolName)
        if tool and not tool:IsA("Tool") then
            tool = nil
        end
    end)
    
    if not success then
        warn("Player:GetTool - Error finding tool:", err)
        return nil
    end
    
    if not tool then
        warn("Player:GetTool - Tool not found:", toolName)
    end
    
    return tool
end

return Player