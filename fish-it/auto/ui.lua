local m = {}

local Window
local Events

function m:Init(_window, _events)
    Window = _window
    Events = _events

    local tab = Window:AddTab({
        Name = "AutoMation",
        Icon = "🤖",
    })

    self:WeatherMachineSection(tab)
end

function m:WeatherMachineSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Weather Machine",
        Icon = "☁️",
        Default = false,
    })

    accordion:AddSelectBox({
        Name = "Weather Machine ☁️",
        Options = {"loading ..."},
        Placeholder = "Select Weather Machine",
        MultiSelect = true,
        Flag = "WeatherMachineItem",
        OnInit =  function(api, optionsData)
            local weatherMachines = Events:GetListWeathersMachine() or {}
            local formattedWeathers = {}
            for _, weatherData in pairs(weatherMachines) do
                table.insert(formattedWeathers, {
                    text = string.format("[%s] %s - %s Coins (%s)", weatherData.Tier, weatherData.Name, tostring(weatherData.Price):reverse():gsub("%d%d%d", "%1."):reverse():gsub("^%.", ""), weatherData.Description),
                    value = weatherData.Name
                })
            end
            optionsData.updateOptions(formattedWeathers)
        end
    })

    accordion:AddButton({
        Name = "Buy Selected Weather Machine ☁️",
        Callback = function()
            local selectedWeathers = Window:GetConfigValue("WeatherMachineItem") or {}
            for _, weatherName in pairs(selectedWeathers) do
                Events:BuyWeatherMachine(weatherName)
            end
        end
    })

    accordion:AddToggle({
        Name = "Auto Buy Weather Machine ☁️",
        Default = false,
        Flag = "AutoBuyWeatherMachine",
    })
end

return m