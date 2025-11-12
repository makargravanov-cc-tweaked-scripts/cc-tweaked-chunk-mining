
local Main = {}

function Main.run()
    local hubState = require("hub.hub_state").new()
    local droneService = require("hub/services/drone_service").new(hubState)
    local hub = require("hub.hub").new(hubState, droneService)
    
    parallel.waitForAll(
        function() 
            os.sleep(1)
            hub:initialize()
        end,
        function() hub:listenCommands() end,
        function() hub:processQueue() end,
        function() hub:consoleLoop() end
    )
end

return Main
