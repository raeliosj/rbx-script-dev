local m = {}
local Window
local Core
local Player
local Garden

function m:Init(_window, _core, _player, _garden)
    Window = _window
    Core = _core
    Player = _player
    Garden = _garden
end

function m:CreateServerTab()
    local tab = Window:AddTab({
        Name = "Server",
        Icon = "🌐",
    })

    tab:AddButton("Rejoin Server 🔄", function()
        Core:Rejoin()
    end)

    tab:AddButton("Hop Server 🚀", function()
        Core:HopServer()
    end)

    tab:AddSeparator()

    tab:AddButton("Debug Status Queue 🔍", function()
        local queueStatus = Player:GetQueueStatus()
        warn("Queue size:", queueStatus.queueSize, "Current Task:", queueStatus.currentTask)
    end)

    tab:AddSeparator()

    tab:AddButton("Front Right", function() 
        local position = Garden:GetFarmFrontRightPosition()
        
        if not position then
            warn("Failed to get Front Right position")
            return
        end
        
        for i = 1, 10 do
            local z = position.Z - (i * 3)

            -- Safe check for MailboxPosition
            if Garden.MailboxPosition and Garden.MailboxPosition.Z and Garden.MailboxPosition.Z > 0 then
                warn("Revert")
                z = position.Z + (i * 3)
            end

            Player:TeleportToPosition(Vector3.new(position.X, position.Y, z))
            task.wait(.1)
        end
    end)

    tab:AddButton("Back Right", function() 
        local position = Garden:GetFarmBackRightPosition()
        
        if not position then
            warn("Failed to get Back Right position")
            return
        end
        
        for i = 1, 10 do
            local z = position.Z + (i * 3)

            -- Safe check for MailboxPosition
            if Garden.MailboxPosition and Garden.MailboxPosition.Z and Garden.MailboxPosition.Z > 0 then
                warn("Revert")
                z = position.Z - (i * 3)
            end

            Player:TeleportToPosition(Vector3.new(position.X, position.Y, z))
            task.wait(.1)
        end
    end)

    tab:AddButton("Front Left", function() 
        local position = Garden:GetFarmFrontLeftPosition()
        
        if not position then
            warn("Failed to get Front Left position")
            return
        end
        
        for i = 1, 10 do
            local z = position.Z - (i * 3)

            -- Safe check for MailboxPosition
            if Garden.MailboxPosition and Garden.MailboxPosition.Z and Garden.MailboxPosition.Z > 0 then
                warn("Revert")
                z = position.Z + (i * 3)
            end

            Player:TeleportToPosition(Vector3.new(position.X, position.Y, z))
            task.wait(.1)
        end
    end)

    tab:AddButton("Back Left", function() 
        local position = Garden:GetFarmBackLeftPosition()
        
        if not position then
            warn("Failed to get Back Left position")
            return
        end
        
        for i = 1, 10 do
            local z = position.Z + (i * 3)

            -- Safe check for MailboxPosition
            if Garden.MailboxPosition and Garden.MailboxPosition.Z and Garden.MailboxPosition.Z > 0 then
                warn("Revert")
                z = position.Z - (i * 3)
            end

            Player:TeleportToPosition(Vector3.new(position.X, position.Y, z))
            task.wait(.1)
        end
    end)
end

return m