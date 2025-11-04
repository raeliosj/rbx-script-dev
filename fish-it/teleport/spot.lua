local m = {}

local Core

function m:Init(_core)
    Core = _core
end

local FishingSpots = {
    {
        Name = "Ancient Jungle",
        Position = CFrame.new(1472.82544, 7.62499952, -338.93396, -0.776614249, -3.74694631e-09, -0.629976451, -5.57512536e-10, 1, -5.26047295e-09, 0.629976451, -3.73413833e-09, -0.776614249),
    },
    {
        Name = "Coral Reefs",
        Position = CFrame.new(-3119.21997, 2.94513345, 2136.76221, 0.839347124, 6.66862547e-08, -0.543595791, -4.54390552e-08, 1, 5.25153396e-08, 0.543595791, -1.93781204e-08, 0.839347124),
    },
    {
        Name = "Crater Island",
        Position = CFrame.new(1079.42944, 3.05696344, 5087.74902, 0.152732253, 3.38155309e-10, 0.988267601, -6.79443772e-08, 1, 1.0158324e-08, -0.988267601, -6.86987249e-08, 0.152732253),
    },
    {
        Name = "Machine",
        Mapping = "Ocean",
        Position = CFrame.new(-1457.8512, 14.7337818, 1843.03955, 0.199816436, -8.31816536e-08, -0.979833364, 1.09653149e-08, 1, -8.26575288e-08, 0.979833364, 5.77215165e-09, 0.199816436),
    },
    {
        Name = "Sacred Temple",
        Position = CFrame.new(1505.19348, -30.1063519, -576.300659, 0.927700281, 5.32009992e-08, -0.373325825, -4.65768863e-08, 1, 2.67637734e-08, 0.373325825, -7.44040607e-09, 0.927700281),
    },
    {
        Name = "Sisyphus Statue",
        Position = CFrame.new(-3742.60962, -135.174316, -1013.46899, -0.989471078, -4.82439972e-08, -0.144730732, -5.28477671e-08, 1, 2.79646191e-08, 0.144730732, 3.53188803e-08, -0.989471078),
    },
    {
        Name = "Treasure Room",
        Position = CFrame.new(-3597.65625, -279.073761, -1586.88818, 0.992161453, -7.67678099e-09, -0.124962427, 5.8638383e-09, 1, -1.48757211e-08, 0.124962427, 1.40263579e-08, 0.992161453),
    },
    {
        Name = "Tropical Grove",
        Position = CFrame.new(-2166.33984, 2.84337163, 3639.77661, -0.350484759, 1.65289595e-08, -0.936568439, 2.19230123e-09, 1, 1.68280181e-08, 0.936568439, 3.84472365e-09, -0.350484759),
    },
    {
        Name = "Underground Cellar",
        Position = CFrame.new(2106.68066, -91.1976471, -724.831787, -0.602142394, 1.76590138e-08, -0.79838872, 3.69580135e-08, 1, -5.7553069e-09, 0.79838872, -3.29723733e-08, -0.602142394),
    },
    {
        Name = "Kohana Volcano",
        Position = CFrame.new(-552.865845, 17.2351856, 114.849068, 1, -3.87002039e-08, 1.16584761e-13, 3.87002039e-08, 1, -7.07843171e-08, -1.13845389e-13, 7.07843171e-08, 1),
    },
    {
        Name = "Mount Hallow",
        Position = CFrame.new(2166.75806, 80.541008, 3289.41211, -0.499248028, 7.93332902e-08, 0.866459131, 5.98914767e-08, 1, -5.70512668e-08, -0.866459131, 2.34107826e-08, -0.499248028),
    },
    {
        Name = "Crystal Cavern",
        Position = CFrame.new(-1772.97168, -421.792725, 7172.96924, 0.00778091652, -1.18147071e-07, 0.999969721, 5.14326999e-08, 1, 1.17750446e-07, -0.999969721, 5.05149345e-08, 0.00778091652),
    },
    {
        Name = "Crystal Falls",
        Position = CFrame.new(-2024.2417, -440.000519, 7428.7627, 0.861011028, 3.60083767e-08, -0.508586287, -2.72354619e-08, 1, 2.46926479e-08, 0.508586287, -7.40905914e-09, 0.861011028),
    }
}

function m:GetAllFishingSpots()
    local areas = require(Core.ReplicatedStorage.Areas)
    local spots = {}

    for _, spot in pairs(FishingSpots) do
        local areaName = spot.Mapping or spot.Name
        local areaDetail = areas[areaName]

        if not areaDetail then
            warn("Area detail not found for spot:", spot.Name)
            areaDetail = areas["Ocean"]
        end

        table.insert(spots, {
            Name = spot.Name,
            Position = spot.Position,
            BaseLuck = areaDetail and areaDetail.BaseLuck or 0,
            ClickPowerMultiplier = areaDetail and areaDetail.ClickPowerMultiplier or 0,
        })
    end


    return spots
end

function m:FindSpotByName(_name)
    for _, spot in pairs(FishingSpots) do
        if spot.Name == _name then
            return spot
        end
    end

    return nil
end

return m