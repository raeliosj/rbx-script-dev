local m = {}

local Window
local Core

local DataService

local CrateShopData
local CosmeticShopData
local CosmeticShopTabData

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)

    CrateShopData = require(Core.ReplicatedStorage.Data.CosmeticCrateShopData)
    CosmeticShopData = require(Core.ReplicatedStorage.Data.CosmeticItemShopData)
    CosmeticShopTabData = require(Core.ReplicatedStorage.Data.CosmeticShopTabData)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoBuyCosmeticItems")
    end, function()
        self:StartAutoBuyCosmeticItems()
    end)
end

function m:GetCrateItemRepository()
    return CrateShopData or {}
end

function m:GetCosmeticItemRepository()
    return CosmeticShopData or {}
end

function m:GetFenceItemRepository()
    local items = CosmeticShopTabData.Tabs["Fences"].Items or {}
    local fences = CosmeticShopTabData.Tabs["Fences"].Fences or {}
    local data = {}

    for k, v in pairs(items) do
        if k ~= "_name" then
            table.insert(data, k)
        end
    end

    for k, v in pairs(fences) do
        if k ~= "_name" then
            table.insert(data, k)
        end
    end

    table.sort(data)

    return data or {}
end

function m:GetAvailableItems()
    local data = DataService:GetData()
    local tabs = {"Cosmetics", "Fences"}
    local availableItems = {}

    for _, tabName in pairs(tabs) do
        local tabConfig = CosmeticShopTabData.Tabs[tabName]
        local stocks = data.CosmeticStock.TabStocks[tabName]
        if not tabConfig or not stocks then
            continue
        end

        -- Crates
        for crateId, stock in pairs(stocks.CrateStocks) do
            local crateData = tabConfig.Crates[crateId]
            if crateData and crateData.CosmeticName then
                availableItems[crateData.CosmeticName] = { Tab = tabName, Category= "Crates", Stock = stock.Stock }
            elseif crateData and crateData.CrateName then
                availableItems[crateData.CrateName] = { Tab = tabName, Category= "Crates", Stock = stock.Stock }
            else
                warn("Invalid crateData or missing CosmeticName for crateId:", crateId)
                for k, v in pairs(crateData or {}) do
                    warn(" -", k, v)
                end
                warn("----")

            end
        end

        -- Items
        for itemId, stock in pairs(stocks.ItemStocks) do
            local itemData = tabConfig.Items[itemId]
            if itemData then
                availableItems[itemData.CosmeticName] = { Tab = tabName, Category= "Items", Stock = stock.Stock }
            end
        end

        -- Fences
        for fenceId, stock in pairs(stocks.FenceStocks) do
            local fenceData = tabConfig.Fences[fenceId]
            if fenceData then
                availableItems[fenceData.FenceName] = { Tab = tabName, Category= "Fences", Stock = stock.Stock }
            end
        end
    end

    return availableItems or {}
end

function m:GetAllIgnoreItems()
    local ignoreCosmeticItems = Window:GetConfigValue("IgnoreCosmeticItems") or {}
    local ignoreCrateItems = Window:GetConfigValue("IgnoreCrateItems") or {}
    local ignoreFenceItems = Window:GetConfigValue("IgnoreFenceItems") or {}

    local allIgnoreItems = {}
    for _, itemName in pairs(ignoreCrateItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreCosmeticItems) do
        table.insert(allIgnoreItems, itemName)
    end
    for _, itemName in pairs(ignoreFenceItems) do
        table.insert(allIgnoreItems, itemName)
    end
    
    return allIgnoreItems
end

function m:StartAutoBuyCosmeticItems()
    if not Window:GetConfigValue("AutoBuyCosmeticItems") then
        return
    end
    local ignoreItems = self:GetAllIgnoreItems()

    for itemName, details in pairs(self:GetAvailableItems()) do
        if stock <= 0 or table.find(ignoreItems, itemName) then
            continue
        end

        for i = 1, details.Stock do
            if details.Category == "Fences" then
                Core.ReplicatedStorage.GameEvents.BuyCosmeticShopFence:FireServer(itemName, details.Tab)
            elseif details.Category == "Crates" then
                Core.ReplicatedStorage.GameEvents.BuyCosmeticCrate:FireServer(itemName, details.Tab)
            else
                Core.ReplicatedStorage.GameEvents.BuyCosmeticItem:FireServer(itemName, details.Tab)
            end
            task.wait(0.15)
        end
    end
end

return m