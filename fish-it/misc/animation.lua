local m = {}

local Window
local Core

function m:Init(_window, _core)
    Window = _window
    Core = _core

    self:DisableCatchFishAnimation()
end

function m:DisableCatchFishAnimation()
    local isDisabled = Window:GetConfigValue("DisableCatchFishAnimation") or false
    local notification = Core.LocalPlayer.PlayerGui["Small Notification"].Display

    print("Display name:", notification.Name)
    print("Currnent visibility:", notification.Visible)

    notification.Visible = not isDisabled
end

return m