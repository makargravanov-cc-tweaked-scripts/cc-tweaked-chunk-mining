

local Main = {}

function Main.run()
    local drone = require("drone.drone").new()
    parallel.waitForAll(
        function() drone:listenCommands() end,
        function() drone:processQueue() end
    )
end

return Main
