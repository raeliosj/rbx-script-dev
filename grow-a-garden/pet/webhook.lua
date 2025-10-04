local m = {}

local Window
local Core
local Discord

function m:Init(_window, _core, _discord)
    Window = _window
    Core = _core
    Discord = _discord
end

function m:HatchEgg(_petName, _eggName, _baseWeight)
    local url = Window:GetConfigValue("DiscordWebhookURL") or ""
    local playerName = Core.LocalPlayer.Name or "Unknown"

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
        content = "",
        embeds = {{
            title = "**EzGarden**",
            type = 'rich',
            color = tonumber("0xfa0c0c"),
            fields = {{
                name = '** -> Profile : ** \n',
                value = '> Username : ||'..playerName.."||",
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


return m