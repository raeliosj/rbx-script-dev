local m = {}

-- Services
m.Players = game:GetService("Players")
m.ReplicatedStorage = game:GetService("ReplicatedStorage")
m.TeleportService = game:GetService("TeleportService")
m.UserInputService = game:GetService("UserInputService")
m.GuiService = game:GetService("GuiService")
m.Workspace = game:GetService("Workspace")
m.VirtualUser = game:GetService("VirtualUser")
m.PlaceId = game.PlaceId
m.JobId = game.JobId

-- Player reference
m.LocalPlayer = m.Players.LocalPlayer

-- References
m.GameEvents = m.ReplicatedStorage.GameEvents

-- Dynamic getters
function m:GetCharacter()
    return self.LocalPlayer.Character
end

function m:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

function m:GetHumanoidRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

function m:GetBackpack()
    return self.LocalPlayer:FindFirstChild("Backpack")
end

function m:GetPlayerGui()
    return self.LocalPlayer:FindFirstChild("PlayerGui")
end

function m:Rejoin()
    if self.PlaceId and self.JobId then
        self.TeleportService:TeleportToPlaceInstance(self.PlaceId, self.JobId, self.LocalPlayer)
    else
        warn("Core:Rejoin - PlaceId or JobId is nil, cannot rejoin.")
    end
end

function m:HopServer()
    if self.PlaceId then
        self.TeleportService:Teleport(self.PlaceId, self.LocalPlayer)
    else
        warn("Core:HopServer - PlaceId is nil, cannot hop server.")
    end
end

function m:MakeLoop(_isEnableFunc, _func)
    coroutine.wrap(function()
        local lastCheck = 0
        local checkInterval = 5 -- Check config every 5 seconds instead of every 0.1 seconds
        
		while true do
            local currentTime = tick()
            local isEnabled = false
            
            -- Only check config periodically to reduce overhead
            if currentTime - lastCheck >= checkInterval then
                -- Handle both function and direct value
                if type(_isEnableFunc) == "function" then
                    isEnabled = _isEnableFunc()
                else
                    isEnabled = _isEnableFunc
                end
                lastCheck = currentTime
            else
                -- Use cached value between checks
                if type(_isEnableFunc) == "function" then
                    isEnabled = _isEnableFunc()
                else
                    isEnabled = _isEnableFunc
                end
            end
            
			if not isEnabled then
                task.wait(5) -- Longer wait when disabled
                continue 
            end
            
			_func()
            task.wait(3) -- Longer wait between executions (was 0.1, now 3 seconds)
		end
	end)()
end
return m