local DroneNet = require "drone.drone_net"
local Message = require("lib.net.msg")

--- @class InventoryService
--- @

local InventoryService = {}
InventoryService.__index = InventoryService

local itemsToDrop = {
    ["minecraft:flint"] = true,
    ["minecraft:deepslate"] = true
}

function InventoryService.dropSelectedItemsDown()
    local total = 0
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and itemsToDrop[detail.name] then
            turtle.select(slot)
            local count = turtle.getItemCount(slot)
            if count > 0 and turtle.dropDown(count) then
                total = total + count
            end
        end
    end
    turtle.select(1)
    return total
end

function InventoryService.dropAllItemsDown()
    local total = 0
    for slot = 1, 16 do
        turtle.select(slot)
        local count = turtle.getItemCount(slot)
        if count > 0 then
            if turtle.dropDown(count) then
                total = total + count
            end
        end
    end
    turtle.select(1)
    return total
end

--- @return integer
function InventoryService.countFreeChestSlots()
    local chest = peripheral.wrap("bottom")
    if not chest or not chest.list then
        error("Chest not found")
    end
    local total = chest.size() 
    local used = 0
    for _, _ in pairs(chest.list()) do
        used = used + 1
    end
    return total - used
end

function InventoryService.getFreeSlots()
    local free = 0
    for i=1,16 do
        if turtle.getItemCount(i) == 0 then free = free+1 end
    end
    return free
end


--- @param droneState DroneState
function InventoryService.requestUnloading(droneState)
    droneState:setWaitingForUnloading(true)
    DroneNet.send(droneState:getHubId(), Message.new("/hub/requests/drone/unload", "/drone/unload-approved", droneState:getId(), {}))
end

--- @param droneState DroneState
--- @param message Message
function InventoryService.unloadApproved(droneState, message)
    droneState:setTargetPosition(message.payload.unloadingPosition)
    droneState:setWaitingForUnloading(false)
end

--- @param droneState DroneState
function InventoryService.requestRefueling(droneState)
    droneState:setWaitingForRefueling(true)
    DroneNet.send(droneState:getHubId(), Message.new("/hub/requests/drone/refuel", "/drone/fuel-approved", droneState:getId(), {}))
end

--- @param droneState DroneState
--- @param message Message
function InventoryService.refuelApproved(droneState, message)
    droneState:setTargetPosition(message.payload.unloadingPosition)
    droneState:setWaitingForUnloading(false)
end

--- @param droneState DroneState
function InventoryService.processInventoryUnloadRelease(droneState)
    DroneNet.send(droneState:getHubId(), Message.new(
        "/hub/requests/drone/unload/release",
        "",
        droneState.id,
        {}
    ))
end

--- @param droneState DroneState
function InventoryService.processRefuelRelease(droneState)
    DroneNet.send(droneState:getHubId(), Message.new(
        "/hub/requests/drone/refuel/release",
        "",
        droneState.id,
        {}
    ))
end


--- @param minSlots integer
--- @return boolean
function InventoryService:hasEnoughSlots(minSlots)
    return InventoryService.getFreeSlots() >= (minSlots or 1)
end

return InventoryService