local m = {}
local Window
local Core
local Player
local AutoHarvestThread
local AutoHarvesting = false
local BackpackConnection
local PlantConnection
local WateringConnection
local PlantsLocation
m.MailboxPosition = Vector3.new(0, 0, 0)

function m:Init(_window, _core, _player)
    Window = _window
    Core = _core
    Player = _player

    local important = self:GetMyFarm():FindFirstChild("Important")
    PlantsLocation = important:FindFirstChild("Plant_Locations")

    local mailbox = self:GetMyFarm():FindFirstChild("Mailbox")
    if mailbox then
        m.MailboxPosition = mailbox:GetPivot().Position
    end

end

function m:GetMyFarm()
	local farms = Core.Workspace.Farm:GetChildren()

	for _, farm in next, farms do
        local important = farm.Important
        local data = important.Data
        local owner = data.Owner

		if owner.Value == Core.LocalPlayer.Name then
			return farm
		end
	end
end

function m:GetArea(_base)
    local center = _base:GetPivot()
	local size = _base.Size

	-- Bottom left
	local x1 = math.ceil(center.X - (size.X/2))
	local z1 = math.ceil(center.Z - (size.Z/2))

	-- Top right
	local x2 = math.floor(center.X + (size.X/2))
	local z2 = math.floor(center.Z + (size.Z/2))

	return x1, z1, x2, z2
end

function m:GetFarmCenterPosition()
    local farmParts = PlantsLocation:GetChildren()
    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end
    
    -- Calculate center from all farm parts
    local totalX, totalZ = 0, 0
    local totalY = 4 -- Default height for farm
    local partCount = 0
    
    for _, part in pairs(farmParts) do
        if part:IsA("BasePart") then
            local pos = part.Position
            totalX = totalX + pos.X
            totalZ = totalZ + pos.Z
            totalY = math.max(totalY, pos.Y + part.Size.Y/2) -- Use highest Y position
            partCount = partCount + 1
        end
    end
    
    if partCount > 0 then
        local centerX = totalX / partCount
        local centerZ = totalZ / partCount
        return Vector3.new(centerX, totalY, centerZ)
    end
end

function m:GetFarmFrontRightPosition()
    local farmParts = PlantsLocation:GetChildren()

    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end
    
    local farmLand = farmParts[1]
    if  m.MailboxPosition.Z > 0 then
        if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    else
        if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    end

    local x1, z1, x2, z2 = self:GetArea(farmLand)
    
    local x = math.max(x1, x2)
    local z = math.max(z1, z2)

    if m.MailboxPosition.Z > 0 then
        x = math.min(x1, x2)
        z = math.min(z1, z2)
    end

    return Vector3.new(x, 4, z)
end

function m:GetFarmFrontLeftPosition()
    local farmParts = PlantsLocation:GetChildren()
    
    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end

    local farmLand = farmParts[1]
    if  m.MailboxPosition.Z > 0 then
        if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    else
        if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    end
    
    local x1, z1, x2, z2 = self:GetArea(farmLand)

    local x = math.min(x1, x2)
    local z = math.max(z1, z2)

    if m.MailboxPosition.Z > 0 then
        x = math.max(x1, x2)
        z = math.min(z1, z2)
    end
    
    return Vector3.new(x, 4, z)
end

function m:GetFarmBackRightPosition()
    local farmParts = PlantsLocation:GetChildren()
    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end

    local farmLand = farmParts[1]
    if  m.MailboxPosition.Z > 0 then
        if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    else
        if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    end

    local x1, z1, x2, z2 = self:GetArea(farmLand)

    local x = math.max(x1, x2)
    local z = math.min(z1, z2)

    if m.MailboxPosition.Z > 0 then
        x = math.min(x1, x2)
        z = math.max(z1, z2)
    end

    return Vector3.new(x, 4, z)
end

function m:GetFarmBackLeftPosition()
    local farmParts = PlantsLocation:GetChildren()
    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end

    local farmLand = farmParts[1]
    if  m.MailboxPosition.Z > 0 then
        if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    else
        if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
            farmLand = farmParts[2]
        end
    end

    local x1, z1, x2, z2 = self:GetArea(farmLand)

    local x = math.min(x1, x2)
    local z = math.min(z1, z2)

    if m.MailboxPosition.Z > 0 then
        x = math.max(x1, x2)
        z = math.max(z1, z2)
    end

    return Vector3.new(x, 4, z)
end

function m:GetFarmRandomPosition()
    local farmParts = PlantsLocation:GetChildren()

    if #farmParts < 1 then
        return Vector3.new(0, 4, 0)
    end

    local FarmLand = farmParts[math.random(1, #farmParts)]

    local x1, z1, x2, z2 = self:GetArea(FarmLand)
    local x = math.random(x1, x2)
    local z = math.random(z1, z2)

    return Vector3.new(x, 4, z)
end

return m