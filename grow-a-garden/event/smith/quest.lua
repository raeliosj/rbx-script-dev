local m = {}

local Window
local Core

local DataService
local GameEvents

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    GameEvents = Core.ReplicatedStorage.GameEvents

    self:GetQuestSubmitEvent()
end

function m:GetQuestSubmitEvent()
    if not DataService then
        warn("DataService not found")
        return
    end
    
    local questData = DataService:GetData()
    if not questData then
        warn("No quest data found")
        return
    end

    local smithingEventData = questData.SmithingEventData

    for key, value in pairs(smithingEventData) do
        print(key, value)
    end

    if smithingEventData.SubmittedFruit then
        print("Submitting fruit quest")
        return "Fruit", GameEvents.SmithingEvent.Smithing_SubmitFruitRE
    elseif smithingEventData.SubmittedGear then
        print("Submitting gear quest")
        return "Gear", GameEvents.SmithingEvent.Smithing_SubmitGearRE
    elseif smithingEventData.SubmittedPet then
        print("Submitting pet quest")
        return "Pet", GameEvents.SmithingEvent.Smithing_SubmitPetRE
    else
        warn("No quest type found")
        return "None", nil
    end
end



return m