

local Main = {}

function Main.run()
    local drone = require("drone.drone").new()
    parallel.waitForAll(
        function() drone:listenCommands() end,
        function() drone:processQueue() end,
        function() drone:processCurrentAction() end
    )
end

return Main
