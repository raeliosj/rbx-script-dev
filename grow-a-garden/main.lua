-- Main entry point
local EzUI = loadstring(game:HttpGet('https://github.com/alfin-efendy/ez-rbx-ui/releases/latest/download/ez-rbx-ui.lua'))()
-- Import local modules
local CoreModule = require('../module/core.lua')
local PlayerModule = require('../module/player.lua')
local Discord = require('../module/discord.lua')
local ServerUI = require('server/ui.lua')

-- Farm modules
local GardenModule = require('farm/garden.lua')
local PlantModule = require('farm/plant.lua')
local FarmUI = require('farm/ui.lua')

-- Quest module
local AscensionModule = require('quest/ascension.lua')
local QuestUI = require('quest/ui.lua')

-- Shop modules
local ShopModule = require('shop/shop.lua')
local ShopSeedModule = require('shop/seed.lua')
local ShopGearModule = require('shop/gear.lua')
local ShopEggModule = require('shop/egg.lua')
local ShopSeasonPassModule = require('shop/season_pass.lua')
local TravelingShop = require('shop/traveling.lua')
local ShopUI = require('shop/ui.lua')

-- -- Pet modules
local PetTeamModule = require('pet/team.lua')
local PetWebhook = require('pet/webhook.lua')
local EggModule = require('pet/egg.lua')
local PetModule = require('pet/pet.lua')
local PetUI = require('pet/ui.lua')

-- Automation modules
local CraftingModule = require('auto/crafting.lua')
local AutoUI = require('auto/ui.lua')

-- Inventory modules
local InventoryModule = require('inventory/inventory.lua')
local InventoryUI = require('inventory/ui.lua')

-- Event modules
local GhoulQuest = require('event/ghoul/quest.lua')
local GhoulShop = require('event/ghoul/shop.lua')
local GhoulUI = require('event/ghoul/ui.lua')

-- Notification module
local NotificationUI = require('notification/ui.lua')

local configFolder = "EzHub/EzGarden"

-- Initialize window
local window = EzUI:CreateNew({
    Title = "EzGarden",
    Width = 700,
    Height = 400,
    Opacity = 0.9,
    AutoAdapt = true,
    AutoShow = false,
    FolderName = configFolder,
    FileName = "settings",
})

-- Update window close callback
window:SetCloseCallback(function()
    print("window is closing! Performing cleanup...")

    -- Remove Anti-AFK connections
    PlayerModule:RemoveAntiAFK()

    -- Stop all queued tasks
    PlayerModule:ClearQueue()

    -- Stop all active loops
    CoreModule:StopAllLoops()

    print("Cleanup completed!")
end)

petTeamsConfig = EzUI:NewConfig({
    FolderName = configFolder,
    FileName = "PetTeams",
})

petTeamsConfig:Load()

-- Wait load config
task.wait(1) -- Ensure config is loaded

-- Player
PlayerModule:Init(CoreModule)

-- Farm
GardenModule:Init(window, CoreModule, PlayerModule)
PlantModule:Init(window, CoreModule, PlayerModule, GardenModule)
FarmUI:init(window, PlayerModule, GardenModule, PlantModule)
FarmUI:CreateFarmTab()
print("Farm initialized")

-- -- Pet
PetTeamModule:Init(CoreModule, PlayerModule, window, petTeamsConfig, GardenModule)
PetWebhook:Init(window, CoreModule, Discord)
PetModule:Init(CoreModule, PlayerModule, window, GardenModule, PetTeamModule)
EggModule:Init(CoreModule, PlayerModule, window, GardenModule, PetModule, PetWebhook)
PetUI:Init(window, PetTeamModule, EggModule, PetModule, GardenModule, PlayerModule)
PetUI:CreatePetTab()
print("Pet initialized")

-- Automation
CraftingModule:Init(window, CoreModule, PlantModule)
AutoUI:Init(window, CoreModule, CraftingModule)
print("Automation initialized")

-- Shop
ShopModule:Init(CoreModule)
ShopSeedModule:Init(window, CoreModule, ShopModule)
ShopGearModule:Init(window, CoreModule, ShopModule)
ShopEggModule:Init(window, CoreModule, ShopModule)
TravelingShop:Init(window, CoreModule, ShopModule)
ShopSeasonPassModule:Init(window, CoreModule, ShopModule)
ShopUI:Init(window, ShopEggModule, ShopSeedModule, ShopGearModule, ShopSeasonPassModule, TravelingShop)
ShopUI:CreateShopTab()
print("Shop initialized")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  

-- Quest
AscensionModule:Init(window, CoreModule, PlantModule, PlayerModule)
QuestUI:Init(window, CoreModule, AscensionModule)
QuestUI:CreateQuestTab()
print("Quest initialized")

-- Inventory
InventoryModule:Init(CoreModule, PlayerModule, window)
InventoryUI:Init(window, InventoryModule, PetModule)
InventoryUI:CreateTab()
print("Inventory initialized")

-- Event
GhoulQuest:Init(window, CoreModule)
GhoulShop:Init(window, CoreModule, ShopModule)
GhoulUI:Init(window, GhoulQuest, GhoulShop)

-- Server
ServerUI:Init(window, CoreModule, PlayerModule, GardenModule)
ServerUI:CreateServerTab()
print("Server initialized")

-- -- Notification
NotificationUI:Init(window, PetWebhook)
NotificationUI:CreateNotificationTab()