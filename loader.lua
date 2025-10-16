repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

local GITHUB_TOKEN = key or ""
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
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["User-Agent"] = "RobloxScript",
                ["X-GitHub-Api-Version"] = "2022-11-28",
                ["Host"] = "api.github.com",
                ["Accept"] = "application/vnd.github+json"
            }
        })
    end)

    if not success then
        warn("Failed to fetch latest release:", response)
        return nil
    end

	local body = response.Body or response.body or response.data
    if not body then
        warn("No response body received")
        return nil
    end

    return HttpService:JSONDecode(body)
end

local function downloadAsset(assetUrl: string)
	local headers = {
		["Authorization"] = "Bearer " .. GITHUB_TOKEN,
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
		warn("Failed to download asset:", result)
		return nil
	end

	return result.Body or result.body or result.data
end

local games = {
    [126884695634066] = "gag.lua", -- Grow a Garden
    [91867617264223] = "gag.lua", -- Grow a Garden 1
    [124977557560410] = "gag.lua" -- Grow a Garden 3
}
local fileName = games[game.PlaceId]

if not fileName then
    return warn("This game is not supported.")
end

local release = getLatestRelease()

if not release or not release.assets then
    for key, value in pairs(release) do
        print(key, value)
    end
    return warn("Failed to get latest release information.")
end

for _, asset in ipairs(release.assets) do
    if asset.name ~= fileName then
        continue
    end

    print("Found asset:", asset.name)
    local code = downloadAsset(asset.url)
    
    if code then
        print("Running script from release:", release.tag_name)
        loadstring(code)()
    else
        warn("Failed to load asset " .. fileName)
    end
    
    break
end