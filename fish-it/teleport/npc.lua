local m = {}

local Window
local Core

function m:Init(_window, _core)
    Window = _window
    Core = _core
end

function m:ListNPCRepository()
    local listNpc = {}
    
    for _, npc in pairs(Core.ReplicatedStorage.NPC:GetChildren()) do
        if npc:IsA("Model") then
            local npcRoot = npc:WaitForChild("HumanoidRootPart")
            local forward = npcRoot.CFrame.LookVector

            -- Adjust target position to be in front of the NPC
            local targetPos = npcRoot.Position + (forward * 5)
            table.insert(listNpc, {
                Name = npc.Name,
                Position = CFrame.lookAt(targetPos, npcRoot.Position),
            })
        end
    end

    return listNpc
end

function m:FindNPCByName(_name)
    local listNpc = self:ListNPCRepository()
    for _, npc in pairs(listNpc) do
        if npc.Name == _name then
            return npc
        end
    end

    return nil
end

return m