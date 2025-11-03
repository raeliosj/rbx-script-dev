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
        return
    end

    if TeleportEvent.IsOnEvent then
        return
    end

    local configLockPosition = Window:GetConfigValue("LockPlayerPosition")
    local lockAtPosition = nil

    if configLockPosition then
        lockAtPosition = Core:StringToCFrame(configLockPosition)

        if not lockAtPosition then
            Window:ShowWarning("Teleport", "Lock position is invalid.")
            return
        end
    else
        Window:ShowWarning("Teleport", "Lock position is not set.")
        return
    end

    local currentPosition = Player:GetPosition()
    if (currentPosition.Position - lockAtPosition.Position).Magnitude ~= 0 then
        Player:TeleportToPosition(lockAtPosition)
    end
end

return m