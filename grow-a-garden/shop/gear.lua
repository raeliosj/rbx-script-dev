local m = {}

local Window
local Core
local Shop

local Connections
local ShopUI = "Gear_Shop"
local ShopItem = "Watering Can"

function m:Init(_window, _core, _shop)
    Window = _window
    Core = _core
    Shop = _shop

    _core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyGear")
    end, function()
        self:BuyAllGear()
    end)
end

function m:BuyGear(gearName)
    if not gearName or gearName == "" then
        warn("Invalid gear name")
        return
    end

    Core.GameEvents.BuyGearStock:FireServer(gearName)
end

function m:BuyAllGear()
    local items = Shop:GetAvailableItems(ShopUI)

    for gearName, stock in pairs(items) do
        if stock < 1 then
            continue
        end

        for i = 1, stock do
            self:BuyGear(gearName)
            task.wait(0.1)
        end
    end
end

function m:StartGearAutomation()
    if not Window:GetConfigValue("AutoBuyGear") then
        return
    end

    self:BuyAllGear()

    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end

    Connections = {}
    for _, item in pairs(Shop:GetListItems(ShopUI)) do
        local conn = Shop:ConnectToStock(item, function()
            if not Window:GetConfigValue("AutoBuyGear") then
                return
            end

            self:BuyAllGear()
        end)
        table.insert(Connections, conn)
    end
end

function m:StopGearAutomation()
    if Connections then
        for _, conn in pairs(Connections) do
            conn:Disconnect()
        end
        Connections = nil
    end
end

return m