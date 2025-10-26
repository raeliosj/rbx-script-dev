local m = {}

local Window
local Core
local Webhook

local TierData

function m:Init(_window, _core, _webhook)
    Window = _window
    Core = _core
    Webhook = _webhook

    TierData = require(Core.ReplicatedStorage.Tiers)

    local tab = Window:AddTab({
        Name = "Notifications",
        Icon = "🔔",
    })

    self:DiscordSection(tab)
end

function m:DiscordSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Discord Webhook",
        Icon = "🌐",
        Default = true,
    })

    accordion:AddTextBox({
        Name = "Discord Webhook URL (for notifications)",
        Default = "",
        Flag = "DiscordWebhookURL",
        Placeholder = "https://discord.com/api/webhooks/...",
        MaxLength = 500,
    })

    accordion:AddTextBox({
        Name = "Discord Ping ID (optional)",
        Default = "",
        Flag = "DiscordPingID",
        Placeholder = "123456789012345678",
        MaxLength = 50,
    })

    accordion:AddButton({
        Text = "Test Notification",
        Callback = function()
            task.spawn(function()
                Webhook:TestWebhook()
            end)
        end
    })

    accordion:AddSelectBox({
        Name = "Minimum Rarity for Notifications",
        Options = {"Loading ..."},
        Placeholder = "Select Minimum Rarity",
        Flag = "NotificationMinRarity",
        OnInit = function(api, optionsData)
            local formattedTiers = {}

            for _, tierDetail in pairs(TierData) do
                table.insert(formattedTiers, {
                    text = tierDetail.Name,
                    value = tierDetail.Tier,
                })
            end

            optionsData.updateOptions(formattedTiers)
        end,
    })

    accordion:AddToggle({
        Name = "Enable Discord Webhook 🔔",
        Default = false,
        Flag = "EnableDiscordWebhook",
    })
end

return m