local m = {}

local Window
local Core

local Events
local EventUtility
local EventReplion
local TierUtility
local Net

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Events = require(Core.ReplicatedStorage.Events)
    EventUtility = require(Core.ReplicatedStorage.Shared.EventUtility)
    TierUtility = require(Core.ReplicatedStorage.Shared.TierUtility)
    Net = require(Core.ReplicatedStorage.Packages.Net)

    local replion = require(Core.ReplicatedStorage.Packages.Replion)
    EventReplion = replion.Client:WaitReplion("Events")

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyWeatherMachine")
    end, function()
        self:AutoBuyWeatherMachine()
    end)
end

function m:GetListWeathersMachine()
    local weatherList = {}

    for weather, _ in pairs(Events) do
        local event = EventUtility:GetEvent(weather)
        if not event then
            warning("Event not found: " .. weather)
            continue
        end

        if not event.WeatherMachine then
            continue
        end

        if not event.WeatherMachinePrice then
            continue
        end

        local tierIndex = event.Tier or 100
        local tierDetail = TierUtility:GetTier(tierIndex)

        table.insert(weatherList, {
            Name = event.Name,
            Price = event.WeatherMachinePrice,
            Description = event.Description or "No description available.",
            Tier = tierDetail and tierDetail.Name or "Unknown",
            TierIndex = tierIndex,
        })
    end

    table.sort(weatherList, function(a, b)
        if a.TierIndex == b.TierIndex then
            return a.Name < b.Name
        end
        return a.TierIndex < b.TierIndex
    end)

    return weatherList
end

function m:BuyWeatherMachine(weatherName)
    local buyEvent = Net:RemoteFunction("PurchaseWeatherEvent")

    buyEvent:InvokeServer(weatherName)
end

function m:AutoBuyWeatherMachine()
    if not Window:GetConfigValue("AutoBuyWeatherMachine") then
        return
    end
    local selectedWeathers = Window:GetConfigValue("WeatherMachineItem") or {}
    local currentWeather = EventReplion:GetExpect("Events") or {}
   
    local owned = {}
    for _, name in pairs(currentWeather) do
        owned[name] = true
    end

    for _, weatherName in ipairs(selectedWeathers) do
        if owned[weatherName] then
            continue
        end

        self:BuyWeatherMachine(weatherName)
    end
end

return m