local m = {}

local Window
local Core

local Net
local FishCaughtConnection
local FishCount = 0

function m:Init(_window, _core)
    Window = _window
    Core = _core

    Net = require(Core.ReplicatedStorage.Packages.Net)
	if Window:GetConfigValue("AutoSellFish") then
		self:CreateConnections()
	end
end

function m:AutoSellCheck()
	FishCount = FishCount + 1
	local autoSellThreshold = Window:GetConfigValue("AutoSellFishCount") or 50

	if Window:GetConfigValue("AutoSellFish") and FishCount >= autoSellThreshold then
		self:SellAllFish()
		FishCount = 0
	end
end

function m:CreateConnections()
	if FishCaughtConnection then
		return
	end

	FishCaughtConnection = Net:RemoteEvent("FishCaught").OnClientEvent:Connect(function(fishName, fishData)
		self:AutoSellCheck()
	end)
end

function m:RemoveConnections()
	if FishCaughtConnection then
		FishCaughtConnection:Disconnect()
		FishCaughtConnection = nil
	end
end

function m:SellAllFish()
    print("Selling all fish...")
    local sellAllRemote = Net:RemoteFunction("SellAllItems")
	if not sellAllRemote then
		isAutoSelling = false
		return false
	end
	
	local sellSuccess = sellAllRemote:InvokeServer()
	if sellSuccess then
		print("All fish sold successfully!")
	else
		warn("Failed to sell all fish.")
	end
end


return m