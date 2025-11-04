
local Main = {}

function Main.run()
    local hubState = require("hub/hub_state").new()
    local droneService = require("hub/services/drone_service").new(hubState)
    local hub = require("hub.hub").new(hubState, droneService)
    hub:initialize()
    
    hub:listenCommands()
    
end

return Main
