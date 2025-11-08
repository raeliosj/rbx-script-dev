local m = {}

local Core
local Player
local Window
local PetConfig
local Garden

function m:Init(_core, _player, _window, _petConfig, _garden)
    Core = _core
    Player = _player
    Window = _window
    PetConfig = _petConfig
    Garden = _garden
end

function m:SaveTeamPets(_teamName, _listPets)
    PetConfig:SetValue(_teamName, _listPets)
end

function m:GetAllPetTeams()
    local allKeys = PetConfig:GetAllKeys()

    return allKeys
end

function m:FindPetTeam(_teamName)
    return PetConfig:GetValue(_teamName)
end

function m:DeleteTeamPets(_teamName)
    PetConfig:DeleteKey(_teamName)
end

return m