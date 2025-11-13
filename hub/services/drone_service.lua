
--- @class DroneService
--- @field hubState HubState
--- @field new fun(hubState: HubState): DroneService
--- @field searchForDrones fun(self: DroneService)
--- @field registerDrone fun(self: DroneService, droneId: integer)
--- @field unregisterDrone fun(self: DroneService, droneId: integer)
--- @field processInventoryUnload fun(self: DroneService, msg: Message)
--- @field processFuelLoad fun(self: DroneService, msg: Message)
--- @field processInventoryUnloadRelease fun(self: DroneService, msg: Message)
--- @field processRefuelRelease fun(self: DroneService, msg: Message)
--- @field runPodProcessor fun(self: DroneService)
--- @field checkUnloadingQueue fun(self: DroneService)
--- @field checkFuelQueue fun(self: DroneService)
--- @
--- @field processStartUp fun(self: DroneService, msg: Message)
--- @field processFinishUp fun(self: DroneService, msg: Message)
--- @field processFinishHorizontal fun(self: DroneService, msg: Message)
--- @field processFinishDown fun(self: DroneService, msg: Message)

local HubState = require("hub.hub_state")
local HubNetwork = require("hub.hub_net")
local Message = require("lib.net.msg")
local Vec     = require("lib.vec")

local EMoveState = require("lib.move_status_enum").EMoveState
local ECurrentDirection = require("lib.move_status_enum").ECurrentDirection


local msg = require("lib.net.msg")
local DroneService = {}
DroneService.__index = DroneService

--- @param hubState HubState
--- @return DroneService
function DroneService.new(hubState)
    local self = setmetatable({}, DroneService)
    self.hubState = hubState
    return self
end

---@param self DroneService
---@param msg Message
function DroneService:processInventoryUnloadRelease(msg)
    self.hubState:unsubscribeDroneFromCargoPod(msg.callbackId)
end

---@param self DroneService
---@param msg Message
function DroneService:processRefuelRelease(msg)
    self.hubState:unsubscribeDroneFromFuelPod(msg.callbackId)
end

---@param self DroneService
---@param msg Message
function DroneService:processInventoryUnload(msg)
    local unloadingPosition = self.hubState:subscribeDroneToCargoPod(msg.callbackId)
    if unloadingPosition then
        local copy = Vec.copy(unloadingPosition)
        copy.y = copy.y + 1
        local unloadMsg = Message.new("/drone/unload-approved",
        "",
        self.hubState.id, {
            unloadingPosition = copy
        })
        HubNetwork.send(msg.callbackId, unloadMsg)
    else
        -- Add to queue for later processing
        self.hubState.cargoQueue:push(msg)
        print("Drone " .. msg.callbackId .. " added to unloading queue")
    end
end

--- Check the unloading queue and process any pending requests
--- @param self DroneService
function DroneService:checkUnloadingQueue()
    while not self.hubState.cargoQueue:isEmpty() do
        local queuedMsg = self.hubState.cargoQueue:read()
        if queuedMsg then
            local unloadingPosition = self.hubState:subscribeDroneToCargoPod(queuedMsg.callbackId)
            if unloadingPosition then
                local copy = Vec.copy(unloadingPosition)
                copy.y = copy.y + 1
                self.hubState.cargoQueue:pull()
                local unloadMsg = Message.new("/drone/unload-approved",
                "",
                self.hubState.id, {
                    unloadingPosition = copy
                })
                HubNetwork.send(queuedMsg.callbackId, unloadMsg)
                print("Processed queued unloading request for drone " .. queuedMsg.callbackId)
            else
                -- Still no available cargo pod, break and try again later
                break
            end
        end
        os.sleep(1)
    end
end

---@param self DroneService
---@param msg Message
function DroneService:processFuelLoad(msg)
    local fuelPosition = self.hubState:subscribeDroneToFuelPod(msg.callbackId)
    print("fuelPosition", fuelPosition, " for drone ", msg.callbackId)
    if fuelPosition then
        local copy = Vec.copy(fuelPosition)
        copy.y = copy.y + 1
        local unloadMsg = Message.new("/drone/fuel-approved",
        "",
        self.hubState.id, {
            fuelPosition = copy
        })
        HubNetwork.send(msg.callbackId, unloadMsg)
    else
        -- Add to queue for later processing
        self.hubState.fuelQueue:push(msg)
        print("Drone " .. msg.callbackId .. " added to unloading queue")
    end
end

--- Check the fuel queue and process any pending requests
--- @param self DroneService
function DroneService:checkFuelQueue()
    while not self.hubState.fuelQueue:isEmpty() do
        local queuedMsg = self.hubState.fuelQueue:read()
        if queuedMsg then
            local fuelPosition = self.hubState:subscribeDroneToFuelPod(queuedMsg.callbackId)
            if fuelPosition then
                local copy = Vec.copy(fuelPosition)
                copy.y = copy.y + 1
                self.hubState.fuelQueue:pull()
                local unloadMsg = Message.new("/drone/fuel-approved",
                "",
                self.hubState.id, {
                    fuelPosition = copy
                })
                HubNetwork.send(queuedMsg.callbackId, unloadMsg)
                print("Processed queued fuel request for drone " .. queuedMsg.callbackId)
            else
                -- Still no available fuel pod, break and try again later
                break
            end
        end
        os.sleep(1)
    end
end

--- @param self DroneService
function DroneService:runPodProcessor()
    parallel.waitForAll(
        function ()
            while true do
                self:checkUnloadingQueue()
                os.sleep(1)
            end
        end,
        function ()
            while true do
                self:checkFuelQueue()
                os.sleep(1)
            end
        end
    )
end

--- @param self DroneService
function DroneService:searchForDrones()
    local discoveryMsg = msg.new("/drone/discovery",
    "/hub/responses/drone/discovery",
    self.hubState.id, {
        position = self.hubState.position,
        distance = 32
    })
    print("search for drones...")
    HubNetwork.sendNoTarget(discoveryMsg)
    print("sended")
end

--- comment
--- @param self DroneService
--- @param msg Message
function DroneService:registerDrone(msg)
    print("registerDrone()")
    ---@type integer
    local droneId = msg.payload.droneId
    ---@type boolean
    local registered = msg.payload.registered
    ---@type boolean
    local distanceCheck = msg.payload.distanceCheck

    if not registered and distanceCheck then
        local delta = self.hubState:registerDrone(droneId)
        local responseMsg = Message.new("/drone/register","", self.hubState.id, {
            hubId    = self.hubState.id,
            baseY    = self.hubState.baseY,
            highYDig = self.hubState.highYDig,
            lowYDig  = self.hubState.lowYDig,
            delta    = delta,
            droneId  = droneId
        })
        HubNetwork.send(droneId, responseMsg)
        print("Registered drone with ID: "..droneId)
    end
end

function DroneService:unregisterDrone(droneId)
    -- Implementation for unregistering a drone
end

--- @param self DroneService
--- @param message Message
function DroneService:processStartUp(message)
    print("processStartUp")
    print("currentDirection: " .. self.hubState.currentDirection)
    local result = self.hubState:tryStartMoveUp(message.callbackId)
    print("currentDirection: " .. self.hubState.currentDirection)
    local state
    if result then
        state = EMoveState.MOVE
        print("MOVE")
    else
        state = EMoveState.WAIT
        print("WAIT")
    end
    HubNetwork.send(message.callbackId, Message.new(
        "/drone/move/start/up/status",
        "",
        self.hubState.id,
        {
            state = state,
            direction = self.hubState.currentDirection
        }
    ))
end

--- @param self DroneService
--- @param message Message
function DroneService:processFinishUp(message)
    print("processFinishUp")
    print("currentDirection: " .. self.hubState.currentDirection)
    local result = self.hubState:finishMoveUp(message.callbackId)
    print("currentDirection: " .. self.hubState.currentDirection)
    if result then
        for i, status in pairs(result) do
           print("status: " .. status .. " id: " .. i)
           HubNetwork.send(i, Message.new(
               "/drone/move/finish/update",
               "",
               self.hubState.id,
               {
                   state = status,
                   direction = self.hubState.currentDirection
               }
           ))
        end
    end
end

--- @param self DroneService
--- @param message Message
function DroneService:processFinishHorizontal(message)
    print("processFinishHorizontal")
    print("currentDirection: " .. self.hubState.currentDirection)
    local result = self.hubState:finishMoveHorizontal(message.callbackId)
    print("currentDirection: " .. self.hubState.currentDirection)
    if result then
        for i, status in pairs(result) do
           print("status: " .. status .. " id: " .. i)
           HubNetwork.send(i, Message.new(
               "/drone/move/finish/update",
               "",
               self.hubState.id,
               {
                   state = status,
                   direction = self.hubState.currentDirection
               }
           ))
        end
    end
end

--- @param self DroneService
--- @param message Message
function DroneService:processFinishDown(message)
    print("processFinishDown")
    print("currentDirection: " .. self.hubState.currentDirection)
    local result = self.hubState:finishMoveDown(message.callbackId)
    print("currentDirection: " .. self.hubState.currentDirection)
    if result then
        for i, status in pairs(result) do
           print("status: " .. status .. " id: " .. i)
           HubNetwork.send(i, Message.new(
               "/drone/move/finish/update",
               "",
               self.hubState.id,
               {
                   state = status,
                   direction = self.hubState.currentDirection
               }
           ))
        end
    end
end


return DroneService