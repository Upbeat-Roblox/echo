local baseEnvironment = require(script.Parent.Parent.base)
local baseQueue = require(script.Parent.Parent.base.queue)
local queueAddEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueAdd
local queueRemoveEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueRemove
local queueResetEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueReset

--[[
    Controls the client queue.

    @public
]]
local controller = {}

export type controller = {
    _start: (self: controller) -> never,
}

--[[
    Starts the client environment.

    @private
    @returns never
]]
function controller:_start()
    baseQueue:_start(baseEnvironment)
    baseQueue:createQueue("replicatedQueue")

    -- Request the current queue.
    queueAddEvent:FireServer()

    queueAddEvent.OnClientEvent:Connect(function(...)
        baseQueue:addToQueue("replicatedQueue", ...)
    end)

    queueRemoveEvent.OnClientEvent:Connect(function(...)
        baseQueue:removeFromQueue("replicatedQueue", ...)
    end)

    queueResetEvent.OnClientEvent:Connect(function()
        baseQueue:resetQueue("replicatedQueue")
    end)
end

return (controller :: any) :: controller
