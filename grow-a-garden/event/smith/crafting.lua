local m = {}

local Window
local Core
local Crafting

local CraftingRecipeRegistry

local MachineTypes = {
    SmithingEventSeedWorkbench = "SmithingEventSeedWorkbench",
    SmithingEventGearWorkbench = "SmithingEventGearWorkbench",
    SmithingEventCosmeticWorkbench = "SmithingEventCosmeticWorkbench",
}

function m:Init(_window, _core, _crafting)
    Window = _window
    Core = _core
    Crafting = _crafting

    CraftingRecipeRegistry = require(Core.ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
    

    local gearModel = self:GetWorkbenchModel("SmithingEventGearWorkbench")
    local seedModel = self:GetWorkbenchModel("SmithingEventSeedWorkbench")
    local cosmeticModel = self:GetWorkbenchModel("SmithingEventCosmeticWorkbench")

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoSmithEventCraftingGear")
        end, 
        function()
            print("Starting Auto Smith Event Crafting Gear")
            Crafting:CraftingController( 
                gearModel,
                Window:GetConfigValue("SmithEventCraftingGearItem")
            )
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoSmithEventCraftingSeeds")
        end, 
        function()
            print("Starting Auto Smith Event Crafting Seeds")
            Crafting:CraftingController( 
                seedModel,
                Window:GetConfigValue("SmithEventCraftingSeedItem")
            )
        end
    )

    Core:MakeLoop(
        function()
            return Window:GetConfigValue("AutoSmithEventCraftingCosmetics")
        end, 
        function()
            print("Starting Auto Smith Event Crafting Cosmetics")
            Crafting:CraftingController( 
                cosmeticModel,
                Window:GetConfigValue("SmithEventCraftingCosmeticItem")
            )
        end
    )
end

function m:GetAllCraftingItems(machineType)
    local items = CraftingRecipeRegistry["RecipiesSortedByMachineType"][machineType] or {}

    return items
end

function m:GetWorkbenchModel(machineType)
    local workbenchModel = nil

    -- Mapping machine types to workbench names
    local workbenchNames = {
        SmithingEventSeedWorkbench = "SmithingSeedWorkBench",
        SmithingEventGearWorkbench = "SmithingGearWorkBench",
        SmithingEventCosmeticWorkbench = "SmithingCosmeticWorkBench",
    }

    local targetWorkbenchName = workbenchNames[machineType]
    if not targetWorkbenchName then
        warn("Unknown machine type: " .. machineType)
        return nil
    end

    -- Check if SmithingEvent exists in Workspace
    local smithingEvent = Core.Workspace:FindFirstChild("SmithingEvent")
    if not smithingEvent then
        warn("SmithingEvent not found in Workspace")
        return nil
    end

    local smithingPlatform = smithingEvent:FindFirstChild("SmithingPlatform")
    if not smithingPlatform then
        warn("SmithingPlatform not found in SmithingEvent")
        return nil
    end

    -- Recursive function to search for workbench
    local function findWorkbench(parent, depth)
        if depth > 3 then return nil end -- Limit recursion depth
        
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == targetWorkbenchName then
                return child
            end
            
            -- Search deeper if it's a Model or Folder
            if child:IsA("Model") or child:IsA("Folder") then
                local found = findWorkbench(child, depth + 1)
                if found then
                    return found
                end
            end
        end
        
        return nil
    end

    -- Search through all children in SmithingPlatform recursively
    workbenchModel = findWorkbench(smithingPlatform, 0)

    if not workbenchModel then
        warn("Workbench not found for machine type: " .. machineType)
    else
        print("Found workbench model for " .. machineType .. ": " .. tostring(workbenchModel))
    end

    return workbenchModel
end

return m