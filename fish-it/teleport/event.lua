local m = {}

local Window
local Core
local Player

local Events
local EventUtility
local EventReplion
local Net

m.IsOnEvent = false

function m:Init(_window, _core, _player)
    Window = _window
    Core = _core
    Player = _player

    Events = require(Core.ReplicatedStorage.Events)
    EventUtility = require(Core.ReplicatedStorage.Shared.EventUtility)
    Net = require(Core.ReplicatedStorage.Packages.Net)

    local replion = require(Core.ReplicatedStorage.Packages.Replion)
    EventReplion = replion.Client:WaitReplion("Events")

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoTeleportToEvent")
        end,
        function()
            self:TeleportToEvent()
        end
    )
end

function m:GetListEvents()
    local eventList = {}

    for eventName, _ in pairs(Events) do
        local event = EventUtility:GetEvent(eventName)
        if not event then
            Window:ShowWarning("Event not found: " .. eventName)
            continue
        end

        if not event.Coordinates then
            continue
        end

        table.insert(eventList, {
            Name = event.Name,
            Description = event.Description or "No description available.",
            Coordinates = event.Coordinates,
        })
    end

    return eventList
end

function m:FindEventPosition(menuRings, selectedEvent)
    local props = {}
    for _, propsModel in pairs(menuRings) do
        if propsModel.Name ~= "Props" then
            continue
        end
        print("Adding props from model: " .. propsModel.Name)
        table.insert(props, table.unpack(propsModel:GetChildren()))
    end
    for _, prop in pairs(props) do
        if prop.Name ~= selectedEvent then
            continue
        end

        print("Found event prop: " .. prop.Name)
        local primaryPart = prop.PrimaryPart or nil
        if primaryPart then
            print("Using primary part: " .. primaryPart.Name)
            primaryPart.CanCollide = true
        end

        return prop:GetPivot().Position
    end
    return nil
end

function m:TeleportToEvent()
    if Window:GetConfigValue("AutoTeleportToEvent") == false then
        self.IsOnEvent = false
        return
    end

    local currentEvent = EventReplion:GetExpect("Events") or {}
    local selectedEvent = Window:GetConfigValue("TeleportEvent") or ""

    for _, event in pairs(currentEvent) do
        if event ~= selectedEvent then
            self.IsOnEvent = false
            continue
        end

        self.IsOnEvent = true

        local menuRings = Core.Workspace["!!! MENU RINGS"]:GetChildren()
        local eventPosition = self:FindEventPosition(menuRings, selectedEvent)
        if not eventPosition then
            self.IsOnEvent = false
            return
        end

        local currentPosition = Player:GetPosition().Position
        local flatCurrentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)
        local flatEventPosition = Vector3.new(eventPosition.X, 0, eventPosition.Z)
        if (flatCurrentPosition - flatEventPosition).Magnitude ~= 0 then
            Player:TeleportToPosition(eventPosition + Vector3.new(0, 50, 0))
        end

        return
    end

    self.IsOnEvent = false
end

return m