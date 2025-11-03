local m = {}

local Window
local Core

function m:Init(_window, _core)
    Window = _window
    Core = _core

    self:DisableCatchFishAnimation()
    self:DisablePlayerName()
    self:DisableNotifications()
end

function m:DisableCatchFishAnimation()
    local isDisabled = Window:GetConfigValue("DisableCatchFishAnimation") or false
    local notification = Core.LocalPlayer.PlayerGui["Small Notification"].Display

    notification.Visible = not isDisabled
end

function m:DisablePlayerName()
    local isDisabled = Window:GetConfigValue("DisablePlayerName") or false
    Core:GetHumanoidRootPart().Overhead.Content.Header.Visible = not isDisabled
end

function m:DisableNotifications()
    local isDisabled = Window:GetConfigValue("DisableNotifications") or false
    local notification = Core.LocalPlayer.PlayerGui["Text Notifications"].Frame
    if notification then
        notification.Visible = not isDisabled
    end
end

return m