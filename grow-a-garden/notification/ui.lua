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

    tab:AddLabel("Discord Webhook URL (for notifications)")
    tab:AddTextBox({
        Name = "Discord Webhook URL",
        Default = "",
        Flag = "DiscordWebhookURL",
        Placeholder = "https://discord.com/api/webhooks/...",
        MaxLength = 500,
    })

    tab:AddButton("Test Notification", function()
        Test:HatchEgg("Test Pet", "Test Egg", 10)
    end)
end

return m