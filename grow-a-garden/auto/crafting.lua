local m = {}

-- Claim from Event Crafting Table
game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService:FireServer(table.unpack({
    [1] = "Claim",
    [2] = workspace.CraftingTables.EventCraftingWorkBench,
    [3] = "GearEventWorkbench",
    [4] = 1,
}))

-- Set Recipe tool
game:GetService("ReplicatedStorage").GameEvents.CraftingGlobalObjectService:FireServer(table.unpack({
    [1] = "SetRecipe",
    [2] = workspace.CraftingTables.EventCraftingWorkBench,
    [3] = "GearEventWorkbench",
    [4] = "Small Toy",
}))

return m