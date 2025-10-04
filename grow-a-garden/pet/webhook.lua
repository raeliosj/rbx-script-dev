local m = {}

local Window
local Core
local Discord

local PlayerName
local LastHatchTime = 0

function m:Init(_window, _core, _discord)
    Window = _window
    Core = _core
    Discord = _discord

    PlayerName = Core.LocalPlayer.Name or "Unknown"
    LastHatchTime = tick()
end

function m:HatchEgg(_petName, _eggName, _baseWeight)
    local url = Window:GetConfigValue("DiscordWebhookURL") or ""
    local pingId = Window:GetConfigValue("DiscordPingID") or ""
    if url == "" then
        return
    end

    local weightStatus = (
        (_baseWeight >= 9 and "Godly") or
        (_baseWeight >= 8 and _baseWeight < 9 and "Titanic") or
        (_baseWeight >= 3 and _baseWeight < 8 and "Huge") or
        "Small"
    )

    local message = {
        content = pingId ~= "" and ("<@"..pingId..">") or nil,
        embeds = {{
            title = "**EzGarden**",
            type = 'rich',
            color = tonumber("0xfa0c0c"),
            fields = {{
                name = '** -> Profile : ** \n',
                value = '> Username : ||'..PlayerName.."||",
                inline = false
            }, {
                name = "** -> Hatched : **",
                value = "> Pet Name: ``".._petName.."``"..
                       "\n> Hatched From: ``"..(_eggName or"N/A").."``"..
                       '\n> Weight: ``'..(tostring(_baseWeight).." KG" or 'N/A')..'``'..
                       "\n> Weight Status: ``"..weightStatus.."``",
                inline = false
            }}
        }}
    }

    Discord:SendMessage(url, message)
end

function m:Statistics(_eggName, _amount)
    local url = Window:GetConfigValue("DiscordWebhookURL") or ""
    if url == "" then
        return
    end

    local message = {
        content = "",
        embeds = {{
            title = "**EzGarden**",
            type = 'rich',
            color = tonumber("0xFFFF00"),
            fields = {{
                name = '** -> Profile : ** \n',
                value = '> Username : ||'..PlayerName.."||",
                inline = false
            }, {
                name = "** -> Hatch Statistics : **",
                value = "> Egg Name: ``"..(_eggName or"N/A").."``"..
                       '\n> Amount: ``'..(tostring(_amount) or 'N/A')..'``'..
                       '\n> Duration: ``'..string.format("%d Minutes %d Seconds", math.floor((tick() - LastHatchTime) / 60), math.floor((tick() - LastHatchTime) % 60))..'``',
                inline = false
            }}
        }}
    }

    LastHatchTime = tick()
    Discord:SendMessage(url, message)
end

return m