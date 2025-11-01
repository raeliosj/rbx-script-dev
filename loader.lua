repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

local OWNER = "alfin-efendy"
local REPO = "rbx-script-dev"

local HttpService = game:GetService("HttpService")
local requestFunction = request or
                        (syn and syn.request) or
                        (http and http.request) or
                        (fluxus and fluxus.request) or
                        http_request

local function getLatestRelease()
	local url = string.format("https://api.github.com/repos/%s/%s/releases/latest", OWNER, REPO)

    local success, response = pcall(function()
        return requestFunction({
            Url = url,
            Method = 'GET',
            Headers = {
                ["User-Agent"] = "RobloxScript",
                ["X-GitHub-Api-Version"] = "2022-11-28",
                ["Host"] = "api.github.com",
                ["Accept"] = "application/vnd.github+json"
            }
        })
    end)

    if not success then
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "EzHub",
                Text = "Failed to fetch latest release:" ... response,
                Duration = 5
            }
        )
        return nil
    end

	local body = response.Body or response.body or response.data
    if not body then
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "EzHub",
                Text = "Failed to fetch latest release: Empty response body",
                Duration = 5
            }
        )
        return nil
    end

    return HttpService:JSONDecode(body)
end

local function downloadAsset(assetUrl: string)
	local headers = {
		["User-Agent"] = "RobloxScript",
        ["X-GitHub-Api-Version"] = "2022-11-28",
        ["Host"] = "api.github.com",
		["Accept"] = "application/octet-stream",
	}

	local success, result = pcall(function()
		return requestFunction({
            Url = assetUrl,
            Method = 'GET',
            Headers = headers
        })
	end)

	if not success then
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "EzHub",
                Text = "Failed to download asset: " .. tostring(result),
                Duration = 5
            }
        )
		return nil
	end

	return result.Body or result.body or result.data
end

local function getFileNameForGame()
    local games = {
        [126884695634066] = "gag.lua", -- Grow a Garden
        [91867617264223] = "gag.lua", -- Grow a Garden 1
        [124977557560410] = "gag.lua" -- Grow a Garden 3
        [121864768012064] = "fish-it.lua" -- Fish It
    }
    local fileName = games[game.PlaceId]

    return fileName
end

local function main()
    local fileName = getFileNameForGame()
    if not fileName then
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "EzHub",
                Text = "This game is not supported.",
                Duration = 5
            }
        )
        return
    end

    local release = getLatestRelease()

    if not release or not release.assets then
        for key, value in pairs(release) do
            print(key, value)
        end
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "EzHub",
                Text = "Failed to get latest release information.",
                Duration = 5
            }
        )
        return
    end

    for _, asset in ipairs(release.assets) do
        if asset.name ~= fileName then
            continue
        end

        local code = downloadAsset(asset.url)
        
        if code then
            game.StarterGui:SetCore(
                "SendNotification",
                {
                    Title = "EzHub",
                    Text = "Loaded " .. fileName .. " from release: " .. release.tag_name,
                    Duration = 5
                }
            )
            print("Running script from release:", release.tag_name)
            loadstring(code)()
        else
            game.StarterGui:SetCore(
                "SendNotification",
                {
                    Title = "EzHub",
                    Text = "Failed to load asset " .. fileName,
                    Duration = 5
                }
            )
        end
        
        break
    end
end

main()