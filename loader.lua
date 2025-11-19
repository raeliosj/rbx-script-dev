-- Memastikan game dan lingkungan CoreGui siap
repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

-- Konfigurasi Repositori GitHub
local OWNER = "raeliosj"
local REPO = "rbx-script-dev"
local BRANCH = "main" 

local HttpService = game:GetService("HttpService")

-- Fungsi Notifikasi RazuHUB
local function notify(text)
    -- Memastikan ada CoreGui sebelum mencoba SendNotification
    if game.StarterGui and game.StarterGui:FindFirstChild("CoreGui") then
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "RaeliosHUB",
                Text = text,
                Duration = 5
            }
        )
    end
end

-- Fungsi Pemetaan Game ke Nama File (Berdasarkan PlaceId)
local function getFileNameForGame()
    local games = {
        [126884695634066] = "gag.lua",        -- Grow a Garden
        [91867617264223] = "gag.lua",         -- Grow a Garden 1
        [124977557560410] = "gag.lua",        -- Grow a Garden 3
        [121864768012064] = "fish-it.lua",    -- Fish It
    }
    return games[game.PlaceId]
end

-- Fungsi Utama untuk Mengunduh dan Menjalankan Skrip
local function main()
    local fileName = getFileNameForGame()
    
    if not fileName then
        notify("Game ini tidak didukung oleh RaeliosHUB.")
        return
    end

    -- Mendapatkan nama folder (misalnya: 'fish-it' dari 'fish-it.lua')
    local FOLDER_NAME = fileName:match("([%w-]+)%.lua") 
    
    -- Membangun URL RAW GitHub (https://raw.githubusercontent.com/...)
    local RAW_URL = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s/%s", 
        OWNER, 
        REPO, 
        BRANCH, 
        FOLDER_NAME,
        fileName
    )

    notify("Loaded: " .. fileName .. " ...")

    -- 1. Proses Pengunduhan (Menggunakan pcall untuk menghindari crash)
    local success, content = pcall(function()
        return game:HttpGet(RAW_URL)
    end)

    if not success or not content or content == "" then
        notify("Failed Load Script! " .. tostring(content))
        return
    end
    
    -- 2. Proses Eksekusi (Menggunakan loadstring dan pcall)
    local executionSuccess, executionResult = pcall(function()
        return loadstring(content)()
    end)
    
    if executionSuccess then
        notify(fileName .. " Succes Loaded Script!")
    else
        notify("Execute Scrpit " .. fileName .. " Failed! " .. tostring(executionResult))
    end
end

main()
