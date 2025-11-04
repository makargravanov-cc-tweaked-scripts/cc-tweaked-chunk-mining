
local Main = {}

function Main.run()
    local hubState = require("hub/hub_state").new()
    local droneService = require("hub/services/drone_service").new(hubState)
    local hub = require("hub.hub").new(hubState, droneService)
    
    -- Run initialize in a separate thread, main thread handles listening
    parallel.waitForAll(
        function()
            hub:initialize()
        end,
        function()
            hub:listenCommands()
        end
    )
end

return Main
