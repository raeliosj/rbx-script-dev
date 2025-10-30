repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

-- Main entry point
local EzUI = loadstring(game:HttpGet('https://github.com/alfin-efendy/ez-rbx-ui/releases/latest/download/ez-rbx-ui.lua'))()
-- Import local modules
local CoreModule = require('../module/core.lua')
local PlayerModule = require('../module/player.lua')
local Discord = require('../module/discord.lua')

-- Farm modules
local FishingModule = require('farm/fishing.lua')
local WebhookFarmModule = require('farm/webhook.lua')
local InventoryModule = require('farm/inventory.lua')
local FarmUI = require('farm/ui.lua')

-- Teleport modules
local LockModule = require('teleport/lock.lua')
local SpotModule = require('teleport/spot.lua')
local TeleportEvent = require('teleport/event.lua')
local NPCModule = require('teleport/npc.lua')
local TeleportUI = require('teleport/ui.lua')

-- Auto modules
local TrickOrTreatModule = require('auto/trick_or_treat.lua')
local EventsModule = require('auto/events.lua')
local EnchantModule = require('auto/enchant.lua')
local TradeModule = require('auto/trade.lua')
local AutoUI = require('auto/ui.lua')

-- Notification modules
local WebhookNotificationModule = require('notification/webhook.lua')
local NotificationUI = require('notification/ui.lua')

-- Misc modules
local DisableModule = require('misc/disable.lua')
local MiscUI = require('misc/ui.lua')

local playerName = CoreModule.LocalPlayer.Name or "Unknown"
local configFolder = string.format("EzHub/%s/EzFish-It", playerName)

-- Initialize window
local window = EzUI:CreateNew({
    Title = "EzFish-It",
    Width = 700,
    Height = 400,
    Opacity = 0.9,
    AutoAdapt = true,
    AutoShow = false,
    FolderName = configFolder,
    FileName = "settings",
})

window:SetCloseCallback(function()
    CoreModule.IsWindowOpen = false

    -- Remove Anti-AFK connections
    PlayerModule:RemoveAntiAFK()

    -- Stop all queued tasks
    PlayerModule:ClearQueue()

    -- Stop all active loops
    CoreModule:StopAllLoops()

    FishingModule:StopAutoFishing()
end)

customPositionConfig = EzUI:NewConfig({
    FolderName = configFolder,
    FileName = "CustomPositions",
})

customPositionConfig:Load()

-- Wait load config
task.wait(1) -- Ensure config is loaded

-- Core
CoreModule.IsWindowOpen = true
-- Player
PlayerModule:Init(CoreModule)

-- Teleport
TeleportEvent:Init(window, CoreModule, PlayerModule)
LockModule:Init(window, CoreModule, PlayerModule, TeleportEvent)
SpotModule:Init(CoreModule)
NPCModule:Init(window, CoreModule)

-- Farm
FishingModule:Init(window, CoreModule)
WebhookFarmModule:Init(window, CoreModule, Discord)
InventoryModule:Init(window, CoreModule, WebhookFarmModule)

-- Auto
TrickOrTreatModule:Init(window, CoreModule, NPCModule)
EventsModule:Init(window, CoreModule)
TradeModule:Init(window, CoreModule)
EnchantModule:Init(window, CoreModule, PlayerModule)

-- Notification
WebhookNotificationModule:Init(window, CoreModule, Discord)

-- Misc
DisableModule:Init(window, CoreModule)

FarmUI:Init(window, CoreModule, FishingModule, InventoryModule)
TeleportUI:Init(window, CoreModule, PlayerModule, NPCModule, SpotModule, customPositionConfig, TeleportEvent)
AutoUI:Init(window, CoreModule, EventsModule, EnchantModule, TradeModule)
NotificationUI:Init(window, CoreModule, WebhookNotificationModule)
MiscUI:Init(window, CoreModule, DisableModule)