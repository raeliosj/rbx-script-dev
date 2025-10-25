-- Main entry point
local EzUI = loadstring(game:HttpGet('https://github.com/alfin-efendy/ez-rbx-ui/releases/latest/download/ez-rbx-ui.lua'))()
-- Import local modules
local CoreModule = require('../module/core.lua')
local PlayerModule = require('../module/player.lua')
local Discord = require('../module/discord.lua')

-- Farm modules
local FishingModule = require('farm/fishing.lua')
local SellModule = require('farm/sell.lua')
local FarmUI = require('farm/ui.lua')

-- Teleport modules
local LockModule = require('teleport/lock.lua')
local SpotModule = require('teleport/spot.lua')
local TeleportEvent = require('teleport/event.lua')
local NPCModule = require('teleport/npc.lua')
local TeleportUI = require('teleport/ui.lua')

-- Auto modules
local EventsModule = require('auto/events.lua')
local AutoUI = require('auto/ui.lua')

-- Misc modules
local AnimationModule = require('misc/animation.lua')
local MiscUI = require('misc/ui.lua')

local configFolder = "EzHub/EzFish-It"

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
SellModule:Init(window, CoreModule)

-- Auto
EventsModule:Init(window, CoreModule)

-- Misc
AnimationModule:Init(window, CoreModule)

FarmUI:Init(window, CoreModule, FishingModule, SellModule)
TeleportUI:Init(window, CoreModule, PlayerModule, NPCModule, SpotModule, customPositionConfig, TeleportEvent)
AutoUI:Init(window, EventsModule)
MiscUI:Init(window, CoreModule, AnimationModule)