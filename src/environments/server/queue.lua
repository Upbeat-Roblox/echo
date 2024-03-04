local baseEnvironment = require(script.Parent.Parent.base)
local baseQueue = require(script.Parent.Parent.base.queue)
local types = require(script.Parent.Parent.Parent.types)
local queueAddEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueAdd
local queueRemoveEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueRemove
local queueResetEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueReset

--[[
    Controls the server queue.

    @public
]]
local controller = {}

export type controller = {
    _start: (self: controller) -> never,
}

--[[
    Starts the server environment.

    @private
    @returns never
]]
function controller:_start()
    baseQueue:_start(baseEnvironment)
    baseQueue:createQueue("replicatedQueue")

    queueAddEvent.OnClientEvent:Connect(function(player: Player)
        for _index: number, audio: types.queueAudio in ipairs(baseQueue:getQueue("replicatedQueue")) do
            queueAddEvent:FireClient(player, audio.id, audio.properties, audio.metadata)
        end
    end)

    baseQueue.audioAdded:Connect(function(audio: types.queueAudio, queue: string)
        if queue ~= "replicatedQueue" then
            return
        end

        queueAddEvent:FireAllClients(audio.id, audio.properties, audio.metadata)
    end)

    baseQueue.audioRemoved:Connect(function(index: number, _audio: types.queueAudio, queue: string)
        if queue ~= "replicatedQueue" then
            return
        end

        queueRemoveEvent:FireAllClients(index)
    end)

    baseQueue.queueReset:Connect(function(queue: string)
        if queue ~= "replicatedQueue" then
            return
        end

        queueResetEvent:FireAllClients()
    end)
end

return (controller :: any) :: controller
