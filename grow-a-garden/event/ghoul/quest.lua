local m = {}

local Window
local Core

local BackpackConnection
local LastSubmitTime

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Core.ReplicatedStorage.GameEvents.WitchesBrew.UpdateCauldronVisuals.OnClientEvent:Connect(function(param)
        if not param and not param.Percentage then
            return
        end

        if param.Percentage == 0 then
            self:StartAutoSubmitEventPlants()
        end
    end)
 
    self:StartAutoSubmitEventPlants()
end

function m:StartAutoSubmitEventPlants()
    if not Window:GetConfigValue("AutoSubmitGhoulQuest") then
        return
    end

    if not BackpackConnection then
        BackpackConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
            if not Window:GetConfigValue("AutoSubmitGhoulQuest") then
                return
            end

            -- Debounce to prevent multiple submissions in quick succession
            if tick() - (LastSubmitTime or 0) < 5 then
                return
            end
            
            if child:GetAttribute("b") ~= "j" then
                return
            end

            Core.ReplicatedStorage.GameEvents.WitchesBrew.SubmitItemToCauldron:InvokeServer("All")
            LastSubmitTime = tick()
        end)
    end

    Core.ReplicatedStorage.GameEvents.WitchesBrew.SubmitItemToCauldron:InvokeServer("All")
    LastSubmitTime = tick()
end

-- function m:StartAutoDigging()
--     local workspaceChildren = Core.Workspace:GetChildren()
--     local diggingPath = nil

--     for _, child in ipairs(workspaceChildren) do
--         if child.Name:match("_DiggingGrid$") then
--             diggingPath = child
--             break
--         end
--     end

--     if not diggingPath then
--         return
--     end

--     local treasure = {}
--     local digBlocks = {}

--     for _, child in ipairs(diggingPath:GetChildren()) do
--         if child.Name == "HalloweenIsland" then
--             continue
--         end

--         if child.Name == "DigBlock" then
--             table.insert(digBlocks, child)
--             continue
--         end

--         table.insert(treasure, child)
--     end

--     local halloweenIsland = diggingPath:FindFirstChild("HalloweenIsland")
--     if halloweenIsland then
--         for _, child in ipairs(halloweenIsland:GetChildren()) do
--             table.insert(allChildren, child)
--         end
--     end

--     workspace.kicung999_DiggingGrid
--     workspace.kicung999_DiggingGrid.HalloweenIsland
--     workspace.kicung999_DiggingGrid:GetChildren()[17]

--     game:GetService("ReplicatedStorage").GameEvents.DiggingMiniGame.DigRemoteEvent:FireServer(table.unpack({
--         [1] = 2,
--         [2] = 3,
--         [3] = CFrame.new(71.9720764, 10032.1885, 13.5591669, 1, -0, 0, 0, 0.528125048, 0.849166632, -0, -0.849166632, 0.528125048),
--     }))

--     game:GetService("ReplicatedStorage").GameEvents.DiggingMiniGame.DigRemoteEvent:FireServer(table.unpack({
--         [1] = 6,
--         [2] = 5,
--         [3] = CFrame.new(71.9720764, 10032.1885, 13.5591669, 1, -0, 0, 0, 0.528125048, 0.849166632, -0, -0.849166632, 0.528125048),
--     }))
-- end

function m:StopAutoSubmitEventPlants()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
end

return m