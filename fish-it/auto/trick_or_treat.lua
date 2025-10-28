local m = {}
local Window
local Core
local NPC

local Net
local CurrentDelayTime = 0

function m:Init(_window, _core, _npc)
    Window = _window
    Core = _core
    NPC = _npc

    Net = require(Core.ReplicatedStorage.Packages.Net)

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoTrickOrTreat")
        end,
        function()
            self:StartAutoTrickOrTreat()
        end
    )
end

function m:StartAutoTrickOrTreat()
    if not Window:GetConfigValue("AutoTrickOrTreat") then
        return
    end

    local npcData = NPC:ListNPCRepository()
    
    for _, npc in pairs(npcData) do
        Net:RemoteFunction("SpecialDialogueEvent"):InvokeServer(
            npc.Name,
            "TrickOrTreat"
        )
    end
    CurrentDelayTime = 7200

    while CurrentDelayTime > 0 and Window:GetConfigValue("AutoTrickOrTreat") do
        task.wait(1)
        CurrentDelayTime = CurrentDelayTime - 1
    end
end

return m