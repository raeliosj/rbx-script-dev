local m = {}

local Window
local Test

function m:Init(_window, _test)
    Window = _window
    Test = _test
end

function m:CreateNotificationTab()
    local tab = Window:AddTab({
        Name = "Notifications",
        Icon = "🔔",
    })

    tab:AddTextBox({
        Name = "Discord Webhook URL (for notifications)",
        Default = "",
        Flag = "DiscordWebhookURL",
        Placeholder = "https://discord.com/api/webhooks/...",
        MaxLength = 500,
    })

    tab:AddTextBox({
        Name = "Discord Ping ID (optional)",
        Default = "",
        Flag = "DiscordPingID",
        Placeholder = "123456789012345678",
        MaxLength = 50,
    })

    tab:AddButton(
        {Text = "Test Notification", 
        Callback = function()
            task.spawn(function()
                Test:HatchEgg("Test Pet", "Test Egg", 10)
                task.wait(0.15)
                Test:Statistics("Test Egg", 99, 123)
            end)
    end})
end

return m