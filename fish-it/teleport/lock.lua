local m = {}

local Window
local Core
local Player
local TeleportEvent

function m:Init(_window, _core, _player, _teleportEvent)
    Window = _window
    Core = _core
    Player = _player
    TeleportEvent = _teleportEvent

    print("Initializing Lock Module...")

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("LockPlayer")
        end, 
        function()
            self:StartLockPlayer()
        end
    )
end

function m:StartLockPlayer()
    if not Window:GetConfigValue("LockPlayer") then
        warn("Lock Player is disabled.")
        return
    end

    if TeleportEvent.IsOnEvent then
        warn("Skipping lock position while on event.")
        return
    end

    local configLockPosition = Window:GetConfigValue("LockPlayerPosition")
    local lockAtPosition

    if configLockPosition then
        if typeof(configLockPosition) == "string" then
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
        elseif typeof(configLockPosition) == "Vector3" then
            lockAtPosition = CFrame.new(configLockPosition)
        elseif typeof(configLockPosition) == "CFrame" then
            lockAtPosition = configLockPosition
        else
            warn("Lock position is invalid or not set properly.")
            return
        end
    else
        warn("Lock position is not set.")
        return
    end

    local currentPosition = Player:GetPosition()
    if (currentPosition.Position - lockAtPosition.Position).Magnitude ~= 0 then
        Player:TeleportToPosition(lockAtPosition)
    end
end

return m