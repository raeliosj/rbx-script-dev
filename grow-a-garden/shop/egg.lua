local m = {}

local Window
local Core
local Shop

local Connections
local ShopUI = "PetShop_UI"
local ShopItem = "Common Egg"

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyEggs")
    end, function()
        self:BuyAllEggs()
    end)
end

function m:BuyEgg(eggName)
    if not eggName or eggName == "" then
        warn("Invalid egg name")
        return
    end

    Core.GameEvents.BuyPetEgg:FireServer(eggName)
end

function m:BuyAllEggs()
     local items = Shop:GetAvailableItems(ShopUI)

    for eggName, stock in pairs(items) do
        if stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuyEgg(eggName)
            task.wait(0.1) -- Small delay to avoid spamming
        end
    end
end

function m:StartEggAutomation()
    if not Window:GetConfigValue("AutoBuyEggs") then
        return
    end

    self:BuyAllEggs()

    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end

    Connections = {}
    for _, item in pairs(Shop:GetListItems(ShopUI)) do
        local conn = Shop:ConnectToStock(item, function()
            if not Window:GetConfigValue("AutoBuyEggs") then
                return
            end

            self:BuyAllEggs()
        end)
        table.insert(Connections, conn)
    end
end

function m:StopEggAutomation()
    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end
end

return m