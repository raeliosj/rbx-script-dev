local m = {}
local HttpService = game:GetService("HttpService")

function m:SendMessage(webhookUrl, data)
    -- Mencari fungsi request yang tersedia dari berbagai executor
    local requestFunction = request or
                           (syn and syn.request) or
                           (http and http.request) or
                           (fluxus and fluxus.request) or
                           http_request

    -- Jika tidak ada fungsi request yang tersedia, keluar dari fungsi
    if not requestFunction then
        return
    end

    -- Mengubah data menjadi format JSON
    local jsonData = HttpService:JSONEncode(data)

    -- Menyiapkan headers untuk request
    local headers = {
        ['Content-Type'] = "application/json"
    }

    -- Mengirim POST request ke webhook
   task.spawn(requestFunction, {
        Url = webhookUrl,
        Body = jsonData,
        Method = 'POST',
        Headers = headers
    })
end

return m
