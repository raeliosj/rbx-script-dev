-- Main entry point
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()
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

-- Event modules
local ChubbyChipmunkQuest = require('event/chubby_chipmunk/quest.lua')
local ChubbyChipmunkUI = require('event/chubby_chipmunk/ui.lua')

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

-- Inventory modules
local InventoryModule = require('inventory/inventory.lua')
local InventoryUI = require('inventory/ui.lua')

-- Notification module
local NotificationUI = require('notification/ui.lua')

-- Initialize window
local window = EzUI.CreateWindow({
    Name = "EzGarden",
    Width = 700,
    Height = 400,
    Opacity = 0.9,
    AutoAdapt = true,
    AutoShow = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EzGarden",
        FileName = "settings",
        AutoLoad = true,
        AutoSave = true,
    },
})

window:SetCloseCallback(function()
	print("window is closing! Performing cleanup...")
	
    -- Remove Anti-AFK connections
    PlayerModule:RemoveAntiAFK()
    
    -- Stop all queued tasks
    PlayerModule:ClearQueue()

	print("Cleanup completed!")
end)

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
PetTeamModule:Init(CoreModule, PlayerModule, window, EzUI.NewConfig("PetTeamConfig"), GardenModule)
PetWebhook:Init(window, CoreModule, Discord)
PetModule:Init(CoreModule, PlayerModule, window, GardenModule, PetTeamModule)
EggModule:Init(CoreModule, PlayerModule, window, GardenModule, PetModule, PetWebhook)
PetUI:Init(window, PetTeamModule, EggModule, PetModule, GardenModule, PlayerModule)
PetUI:CreatePetTab()
print("Pet initialized")

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

-- Event
ChubbyChipmunkQuest:Init(window, CoreModule)
ChubbyChipmunkUI:Init(window, ChubbyChipmunkQuest)

-- Quest
AscensionModule:Init(window, CoreModule, PlantModule, PlayerModule)
QuestUI:Init(window, CoreModule, AscensionModule, ChubbyChipmunkUI)
QuestUI:CreateQuestTab()
print("Quest initialized")

-- Inventory
InventoryModule:Init(CoreModule, PlayerModule, window)
InventoryUI:Init(window, InventoryModule, PetModule)
InventoryUI:CreateTab()
print("Inventory initialized")

-- Server
ServerUI:Init(window, CoreModule, PlayerModule, GardenModule)
ServerUI:CreateServerTab()
print("Server initialized")

-- -- Notification
NotificationUI:Init(window, PetWebhook)
NotificationUI:CreateNotificationTab()