-- Main entry point
local EzUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/alfin-efendy/ez-rbx-ui/refs/heads/main/ui.lua'))()

-- Import local modules
local Core = require('../module/core.lua')
local PlayerUtils = require('../module/player.lua')

-- Import Farm
local FarmUtils = require('module/farm.lua')
local FarmUI = require('ui/farm.lua')

-- Import Pet
local PetUtils = require('module/pet.lua')
local PetUI = require('ui/pet.lua')

-- Import Shop
local ShopUtils = require('module/shop.lua')
local ShopUI = require('ui/shop.lua')

--- Import Quest
local QuestUtils = require('module/quest.lua')
local QuestUI = require('ui/quest.lua')

-- Import Event
local EventUtils = require('event/seed_stages/module.lua')
local EventUI = require('event/seed_stages/ui.lua')

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
    PlayerUtils:RemoveAntiAFK()
    
    -- Remove Auto Hatch connection
    PetUtils:RemoveAutoHatchConnection()

    -- Stop all Shop automation
    ShopUtils:StopAllAutomation()

    -- Stop all queued tasks
    PlayerUtils:ClearQueue()

    -- Stop all Farm automation
    FarmUtils:StopAllAutomation()

    -- Stop all Event automation
    EventUtils:StopAutoSubmitEventPlants()

	print("Cleanup completed!")
end)

-- Wait load config
wait(1) -- Ensure config is loaded

-- Initialize modules with dependencies
PlayerUtils:Init(Core)

-- Farm
FarmUtils:Init(Core, PlayerUtils, window)
FarmUI:Init(Core, PlayerUtils, FarmUtils, window)
FarmUI:CreateFarmTab()
print("Farm initialized")

-- Pet
PetUtils:Init(Core, PlayerUtils, FarmUtils, EzUI.NewConfig("PetTeamConfig"), window)
PetUI:Init(window, PetUtils, FarmUtils)
PetUI:CreatePetTab()
print("Pet initialized")

-- Shop
ShopUtils:Init(Core, PlayerUtils, window)
ShopUI:Init(window, ShopUtils)
ShopUI:CreateShopTab()
print("Shop initialized")


-- Event
EventUtils:Init(window, FarmUtils, PlayerUtils, Core)
EventUI:Init(window, EventUtils)
print("Event initialized")

-- Quest
QuestUtils:Init(window, FarmUtils, PlayerUtils, Core)
QuestUI:Init(window, QuestUtils, EventUI)
QuestUI:CreateQuestTab()

-- Create UI
print("All modules initialized and UI created.")