local baseQueue = require(script.Parent.Parent.base.queue)
local queueAddEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueAdd
local queueRemoveEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueRemove
local queueResetEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueReset

--[[
    Controls the client queue.

    @public
]]
local controller = baseQueue

export type controller = baseQueue.controller & {
    _start: () -> never,
}

--[[
    Starts the client environment.

    @private
    @returns never
]]
function controller:_start()
    baseQueue._start(self)
    self:createQueue("replicatedQueue")

    -- Request the current queue.
    queueAddEvent:FireServer()

    queueAddEvent.OnClientEvent:Connect(function(...)
        self:addToQueue("replicatedQueue", ...)
    end)

    queueRemoveEvent.OnClientEvent:Connect(function(...)
        self:removeFromQueue("replicatedQueue", ...)
    end)

    queueResetEvent.OnClientEvent:Connect(function()
        self:resetQueue("replicatedQueue")
    end)
end

return (controller :: any) :: controller
