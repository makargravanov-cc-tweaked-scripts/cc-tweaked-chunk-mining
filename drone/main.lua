

local Main = {}

function Main.run()
    local Drone = require("drone")
    Drone.listenCommands()
end

return Main
