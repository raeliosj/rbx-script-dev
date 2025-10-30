local m = {}

-- Services
m.Players = game:GetService("Players")
m.ReplicatedStorage = game:GetService("ReplicatedStorage")
m.TeleportService = game:GetService("TeleportService")
m.UserInputService = game:GetService("UserInputService")
m.GuiService = game:GetService("GuiService")
m.Workspace = game:GetService("Workspace")
m.VirtualUser = game:GetService("VirtualUser")
m.MarketplaceService = game:GetService("MarketplaceService")
m.PlaceId = game.PlaceId
m.JobId = game.JobId
m.IsWindowOpen = false

-- Player reference
m.LocalPlayer = m.Players.LocalPlayer

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

-- Table to track active loops
local activeLoops = {}

function m:MakeLoop(_isEnableFunc, _func, _delay)
    local function resolveDelay()
        if type(_delay) == "function" then
            return _delay()
        end
        return _delay or 3 -- Ensure default delay is applied
    end

    local loop = coroutine.create(function()
        local lastCheck = 0
        local checkInterval = 5 -- Check config every 5 seconds instead of every 0.1 seconds

        while self.IsWindowOpen do
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
            end

            if not isEnabled then
                task.wait(5) -- Longer wait when disabled
                continue
            end

            _func()
            task.wait(resolveDelay()) -- Use resolved delay
        end
    end)

    table.insert(activeLoops, loop)
    coroutine.resume(loop)
    return loop
end

function m:StopAllLoops()
    for _, loop in ipairs(activeLoops) do
        if loop and coroutine.status(loop) ~= "dead" then
            coroutine.close(loop)
        end
    end
    table.clear(activeLoops)
end
return m