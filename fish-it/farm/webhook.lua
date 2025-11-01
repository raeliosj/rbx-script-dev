local m = {}

local Window
local Core
local Discord

local PlayerName

local TierUtility
local ItemUtility

function m:Init(_window, _core, _discord)
    Window = _window
    Core = _core
    Discord = _discord

    PlayerName = Core.LocalPlayer.Name or "Unknown"

    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    ItemUtility = require(Core.ReplicatedStorage.Shared.ItemUtility)
end

function m:SendWebhook(_fishId, _fishDetails)
    if not Window:GetConfigValue("EnableDiscordWebhook") then
        return
    end

    local url = Window:GetConfigValue("DiscordWebhookURL") or ""
    local pingId = Window:GetConfigValue("DiscordPingID") or ""
    if url == "" then
        warn("Webhook:SendWebhook - Webhook URL not set")
        return
    end

    local minRarity = Window:GetConfigValue("NotificationMinRarity") or 0
    if minRarity == 0 then
        warn("Webhook:SendWebhook - Minimum rarity not set")
        return
    end

    local fishData = ItemUtility.GetItemDataFromItemType("Fish", _fishId)
    if not fishData or not fishData.Data then
        return
    end

    local tierIndex = fishData.Data.Tier or -999999999999
    if tierIndex < minRarity then
        return
    end

    local tierDetail = TierUtility:GetTier(tierIndex)
    local rarity = tierDetail and tierDetail.Name or "Unknown"
    local weight = 0
    local mutations = {}

    for k, v in pairs(_fishDetails or {}) do
        if k == "Weight" then
            weight = v
        elseif k == "Shiny" and v == true then
            table.insert(mutations, "Shiny")
        elseif k == "VariantId" then
            table.insert(mutations, v)
        end
    end

    local mutationsString = #mutations > 0 and table.concat(mutations, ", ") or "None"
    
    local message = {
        content = pingId ~= "" and ("<@"..pingId..">") or nil,
        embeds = {{
            title = "**EzFish-It**",
            type = 'rich',
            color = tonumber("0xfa0c0c"),
            fields = {
                {
                    name = '**Profile : ** \n',
                    value = '> Username : ||'..PlayerName.."||",
                    inline = false
                },
                {
                    name = '**You have caught a fish!**',
                    value = '> Fish Name: ``'..(fishData.Data.Name or "N/A")..'``'..
                            '\n> Rarity: ``'..(rarity or "N/A")..'``'..
                            '\n> Weight: ``'..(tostring(weight).." KG" or 'N/A')..'``'..
                            '\n> Mutation: ``'..mutationsString..'``',
                    inline = false
                }
            }
        }}
    }

    Discord:SendMessage(url, message)
end

return m