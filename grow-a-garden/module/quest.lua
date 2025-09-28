local m = {}
local Window
local FarmUtils
local PlayerUtils
local Core

function m:Init(windowInstance, farmUtilsInstance, playerUtilsInstance, coreInstance)
    Window = windowInstance
    FarmUtils = farmUtilsInstance
    PlayerUtils = playerUtilsInstance
    Core = coreInstance
end

return m