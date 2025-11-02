repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

local OWNER = "alfin-efendy"
local REPO = "rbx-script-dev"

local HttpService = game:GetService("HttpService")
local requestFunction = request or
                        (syn and syn.request) or
                        (http and http.request) or
                        (fluxus and fluxus.request) or
                        http_request

local function notify(text)
    game.StarterGui:SetCore(
        "SendNotification",
        {
            Title = "EzHub",
            Text = text,
            Duration = 5
        }
    )
end

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
        notify("Failed to fetch latest release: " .. tostring(response))
        return nil
    end

	local body = response.Body or response.body or response.data
    if not body then
        notify("Failed to fetch latest release: Empty response body")
        return nil
    end

    return HttpService:JSONDecode(body)
end

local function getFileNameForGame()
    local games = {
        [126884695634066] = "gag.lua", -- Grow a Garden
        [91867617264223] = "gag.lua", -- Grow a Garden 1
        [124977557560410] = "gag.lua", -- Grow a Garden 3
        [121864768012064] = "fish-it.lua", -- Fish It
    }
    local fileName = games[game.PlaceId]

    return fileName
end

local function main()
    local fileName = getFileNameForGame()
    if not fileName then
        notify("This game is not supported by EzHub.")
        return
    end

    local release = getLatestRelease()

    if not release or not release.assets then
        for key, value in pairs(release) do
            print(key, value)
        end

        notify("Failed to get latest release information.")
        
        return
    end

    local url = string.format("https://github.com/%s/%s/releases/latest/download/%s", OWNER, REPO, fileName)

    notify("Loaded " .. fileName .. " from release: " .. release.tag_name or "unknown")

    loadstring(url)()
end

main()