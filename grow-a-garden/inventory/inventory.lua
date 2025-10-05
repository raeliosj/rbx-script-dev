local m = {}

local Core
local Player
local Window

local InventoryConnection

function m:Init(_core, _player, _window)
    Core = _core
    Player = _player
    Window = _window

    InventoryConnection = Core:GetBackpack().ChildAdded:Connect(function(child)
        self:AutoFavoritePet(child)
    end)
end

function m:GetAllPets()
    local myPets = {}
    
    for _, tool in next, Player:GetAllTools() do
        local toolType = tool:GetAttribute("b")
        toolType = toolType and string.lower(toolType) or ""
        if toolType == "l" then
            table.insert(myPets, tool)
        end
    end

    return myPets
end

function m:FavoriteItem(item)
    Core.GameEvents.Favorite_Item:FireServer(item)
    task.wait(0.15)
end

function m:AutoFavoritePet(item)
    if not item or not item:IsA("Tool") then
        return
    end 

    local isAutoFavoriting = Window:GetConfigValue("AutoFavoritePets") or false
    if not isAutoFavoriting then return end
    
    local petType = item:GetAttribute("b")
    if not petType or string.lower(petType) ~= "l" then
        return
    end

    local isFavorited = item:GetAttribute("d") or false
    if isFavorited then
        return
    end

    local petNames = Window:GetConfigValue("AutoFavoritePetName") or {}
    local weightThreshold = Window:GetConfigValue("AutoFavoritePetWeight") or 0.0
    local ageThreshold = Window:GetConfigValue("AutoFavoritePetAge") or 0

    -- Parse pet name, weight, and age from item.Name
    -- Example format: "Golden Goose [2.19 KG] [Age 2]"
    local petName, weightStr, ageStr = item.Name:match("^(.-)%s*%[(.-)%s*KG%]%s*%[Age%s*(%d+)%]")
        
    if not petName then
        -- Fallback if parsing fails
        petName = item.Name
        weightStr = nil
        ageStr = nil
    end

    local weight = weightStr and tonumber(weightStr:match("%d+%.?%d*")) or 0
    local age = ageStr and tonumber(ageStr) or 0

    print(string.format("Checking pet: %s | Weight: %.2f | Age: %d", petName, weight, age))

    for _, name in ipairs(petNames) do
        if petName == name then
            print("Auto-favoriting pet by name:", petName)
            self:FavoriteItem(item)
            return
        end
    end

    if weight >= weightThreshold or age >= ageThreshold then
        self:FavoriteItem(item)
    end
end

function m:FavoriteAllPets()
    for _, tool in pairs(self:GetAllPets()) do
        self:AutoFavoritePet(tool)
    end
end

return m