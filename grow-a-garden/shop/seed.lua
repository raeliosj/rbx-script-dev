local m = {}

local Window
local Core
local Shop

local Connections
local ShopUI = "Seed_Shop"
local ShopItem = "Carrot"

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuySeeds")
    end, function()
        self:BuyAllSeeds()
    end)
end

function m:BuySeed(seedName)
    if not seedName or seedName == "" then
        warn("Invalid seed name")
        return
    end

    Core.GameEvents.BuySeedStock:FireServer("Tier 1", seedName)
end

function m:BuyAllSeeds()
    local items = Shop:GetAvailableItems(ShopUI)

    for seedName, stock in pairs(items) do
        if stock and stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuySeed(seedName)
            task.wait(0.1)
        end
    end
end

function m:StartSeedAutomation()
    if not Window:GetConfigValue("AutoBuySeeds") then
        return
    end

    self:BuyAllSeeds()

    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end

    Connections = {}
    for _, item in pairs(Shop:GetListItems(ShopUI)) do
        local conn = Shop:ConnectToStock(item, function()
            if Window:GetConfigValue("AutoBuySeeds") then
                return
            end

            self:BuyAllSeeds()
        end)
        table.insert(Connections, conn)
    end
end

function m:StopSeedAutomation()
    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end
end

return m