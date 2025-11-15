-- Main entry point
local EzUI = loadstring(game:HttpGet('https://github.com/alfin-efendy/ez-rbx-ui/releases/latest/download/ez-rbx-ui.lua'))()
-- Import local modules
local CoreModule = require('../module/core.lua')
local PlayerModule = require('../module/player.lua')
local Discord = require('../module/discord.lua')
local ServerUI = require('server/ui.lua')
local Rarity = require('rarity.lua')

-- Farm modules
local GardenModule = require('farm/garden.lua')
local PlantModule = require('farm/plant.lua')
local FarmUI = require('farm/ui.lua')

-- Quest module
local AscensionModule = require('quest/ascension.lua')
local SeasonPassModule = require('quest/season_pass.lua')
local QuestUI = require('quest/ui.lua')

-- Shop modules
local ShopSeedModule = require('shop/seed.lua')
local ShopGearModule = require('shop/gear.lua')
local ShopEggModule = require('shop/egg.lua')
local ShopSeasonPassModule = require('shop/season_pass.lua')
local ShopTravelingModule = require('shop/traveling.lua')
local ShopPremiumModule = require('shop/premium.lua')
local ShopCosmeticModule = require('shop/cosmetic.lua')
local ShopUI = require('shop/ui.lua')

-- -- Pet modules
local PetTeamModule = require('pet/team.lua')
local PetWebhook = require('pet/webhook.lua')
local EggModule = require('pet/egg.lua')
local PetModule = require('pet/pet.lua')
local PetUI = require('pet/ui.lua')

-- Automation modules
local CraftingModule = require('auto/crafting.lua')
local CookingModule = require('auto/cooking.lua')
local AutoUI = require('auto/ui.lua')

-- Inventory modules
local InventoryModule = require('inventory/inventory.lua')
local InventoryUI = require('inventory/ui.lua')

-- Event modules
local SmithQuestModule = require('event/smith/quest.lua')
local SmithCraftingModule = require('event/smith/crafting.lua')
local SmithUI = require('event/smith/ui.lua')

-- Notification module
local NotificationUI = require('notification/ui.lua')
local playerName = CoreModule.LocalPlayer.Name or "Unknown"
local configFolder = string.format("EzHub/%s/EzGarden", playerName)

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
    CoreModule.IsWindowOpen = false

    -- Remove Anti-AFK connections
    PlayerModule:RemoveAntiAFK()

    -- Stop all queued tasks
    PlayerModule:ClearQueue()

    -- Stop all active loops
    CoreModule:StopAllLoops()

    -- Safari Event
    SafariQuestModule:StopAutoSubmitEventPlants()
end)

petTeamsConfig = EzUI:NewConfig({
    FolderName = configFolder,
    FileName = "PetTeams",
})

petTeamsConfig:Load()

-- Wait load config
task.wait(1) -- Ensure config is loaded

-- Core
CoreModule.IsWindowOpen = true
-- Player
PlayerModule:Init(CoreModule)

-- Farm
GardenModule:Init(window, CoreModule, PlayerModule)
PlantModule:Init(window, CoreModule, PlayerModule, GardenModule, Rarity)
FarmUI:init(window, CoreModule, PlayerModule, GardenModule, PlantModule)

-- -- Pet
PetTeamModule:Init(CoreModule, PlayerModule, window, petTeamsConfig, GardenModule)
PetWebhook:Init(window, CoreModule, Discord)
PetModule:Init(CoreModule, PlayerModule, window, GardenModule, PetTeamModule, PetWebhook, Rarity)
EggModule:Init(CoreModule, PlayerModule, window, GardenModule, PetModule, PetWebhook)
PetUI:Init(window, PetTeamModule, EggModule, PetModule, GardenModule, PlayerModule)

-- Automation
CraftingModule:Init(window, CoreModule, PlantModule)
CookingModule:Init(window, CoreModule, PlayerModule, PlantModule)
AutoUI:Init(window, CoreModule, CraftingModule, PlantModule, CookingModule)

-- Shop
ShopSeedModule:Init(window, CoreModule)
ShopCosmeticModule:Init(window, CoreModule)
ShopGearModule:Init(window, CoreModule)
ShopEggModule:Init(window, CoreModule)
ShopTravelingModule:Init(window, CoreModule, PetModule)
ShopSeasonPassModule:Init(window, CoreModule)
ShopPremiumModule:Init(window, CoreModule)
ShopUI:Init(window, CoreModule, ShopEggModule, ShopSeedModule, ShopGearModule, ShopSeasonPassModule, ShopTravelingModule, ShopPremiumModule, PetTeamModule, Rarity, ShopCosmeticModule)

-- Quest
AscensionModule:Init(window, CoreModule, PlantModule, PlayerModule)
SeasonPassModule:Init(window, CoreModule)
QuestUI:Init(window, CoreModule, AscensionModule)

-- Inventory
InventoryModule:Init(CoreModule, PlayerModule, window)
InventoryUI:Init(window, InventoryModule, PetModule)

-- Event
SmithQuestModule:Init(window, CoreModule)
SmithCraftingModule:Init(window, CoreModule, CraftingModule)
SmithUI:Init(window, CoreModule, SmithQuestModule, SmithCraftingModule, PlantModule, PetModule)

-- Server
ServerUI:Init(window, CoreModule, PlayerModule, GardenModule)

-- -- Notification
NotificationUI:Init(window, PetWebhook)
NotificationUI:CreateNotificationTab()