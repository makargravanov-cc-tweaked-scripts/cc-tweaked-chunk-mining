

local Main = {}

function Main.run()
    local Drone = require("drone.drone")
    Drone.listenCommands()
end

return Main
