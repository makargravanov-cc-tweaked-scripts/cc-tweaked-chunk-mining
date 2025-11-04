
--- @class Router
--- @field routes table<string, function>
--- @field registerRoute fun(self: Router, path: string, handler: function)
--- @field dispatch fun(self: Router, path: string, message: Message)
--- @field new fun(): Router

local Router = {}
Router.__index = Router

function Router.new()
    local self = setmetatable({}, Router)
    self.routes = {}
    return self
end

--- @param path string
--- @param handler function
function Router:registerRoute(path, handler)
    self.routes[path] = handler
end

--- @param self Router
--- @param path string
--- @param message Message
function Router:dispatch(path, message)
    local handler = self.routes[path]
    if handler then
        handler(message)
    else
        print("No handler for path: " .. path)
    end
end

--- @param targetId integer
--- @param msg Message
function Router.send(targetId, msg)
    rednet.send(targetId, msg, "mining_drone_protocol")
end

function Router.sendNoTarget(msg)
    rednet.broadcast(msg, "mining_drone_protocol")
end

return Router