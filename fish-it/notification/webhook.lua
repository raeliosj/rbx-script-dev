local m = {}

local Window
local Core
local Discord

local PlayerName

function m:Init(_window, _core, _discord)
    Window = _window
    Core = _core
    Discord = _discord

    PlayerName = Core.LocalPlayer.Name or "Unknown"
end

function m:TestWebhook()
    local url = Window:GetConfigValue("DiscordWebhookURL") or ""
    local pingId = Window:GetConfigValue("DiscordPingID") or ""
    if url == "" then
        return
    end

    local message = {
        content = pingId ~= "" and ("<@"..pingId..">") or nil,
        embeds = {{
            title = "**EzFish-It**",
            type = 'rich',
            color = tonumber("0x00FF00"),
            fields = {{
                name = '**Profile : ** \n',
                value = '> Username : ||'..PlayerName.."||",
                inline = false
            }, {
                name = '**Notification Test**',
                value = '> This is a test notification from EzFish-It.',
                inline = false
            }}
        }}
    }

    Discord:SendMessage(url, message)
end

return m