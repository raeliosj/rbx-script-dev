local m = {}

local Window
local Inventory
local Pet

function m:Init(_window, _inventory, _pet)
    Window = _window
    Inventory = _inventory
    Pet = _pet

    self:CreateTab()
end

function m:CreateTab()
    local tab = Window:AddTab({
        Name = "Inventory",
        Icon = "🎒"
    })

    self:AddPetSection(tab)
end

function m:AddPetSection(tab)
    local accordion = tab:AddAccordion({
        Title = "Pets",
        Icon = "🐶",
        Expanded = false,
    })

    accordion:AddSelectBox({
        Name = "Select pet name for auto favorite",
        Options = {"Loading..."},
        Placeholder = "Select a pet",
        MultiSelect = true,
        Flag = "AutoFavoritePetName",
       OnInit = function(api, optionsData)
            local specialPets = Pet:GetPetRegistry()
            optionsData.updateOptions(specialPets)
        end
    })

    accordion:AddNumberBox({
        Name = "Or If Weight Is Higher Than Or Equal To",
        Placeholder = "Enter weight...",
        Default = 0.0,
        Min = 0.0,
        Max = 20.0,
        Increment = 1.0,
        Decimals = 2,
        Flag = "AutoFavoritePetWeight",
    })

    accordion:AddNumberBox({
        Name = "Or If Age Is Higher Than Or Equal To",
        Placeholder = "Enter age...",
        Default = 0,
        Min = 0,
        Max = 100,
        Increment = 1,
        Flag = "AutoFavoritePetAge",
    })

    accordion:AddToggle({
        Name = "Auto Favorite Pets",
        Flag = "AutoFavoritePets",
        Default = false,
        Callback = function(value)
            if value then
                Inventory:FavoriteAllPets()
            end
        end
    })
end

return m