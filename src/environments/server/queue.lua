local baseQueue = require(script.Parent.Parent.base.queue)
local types = require(script.Parent.Parent.Parent.types)
local queueAddEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueAdd
local queueRemoveEvent: RemoteEvent = script.Parent.Parent.Parent.events.queueRemove

--[[
    Controls the server queue.

    @public
]]
local controller = baseQueue

export type controller = baseQueue.controller & {
    _start: () -> never,
}

--[[
    Starts the server environment.

    @private
    @returns never
]]
function controller:_start()
    baseQueue._start(self)
    self:createQueue("replicatedQueue")

    queueAddEvent.OnClientEvent:Connect(function(player: Player)
        for _index: string, audio: types.queueAudio in pairs(self:getQueue("replicatedQueue")) do
            queueAddEvent:FireClient(player, audio.id, audio.properties, audio.metadata)
        end
    end)

    self.audioAdded:Connect(function(audio: types.queueAudio, queue: string)
        if queue ~= "replicatedQueue" then
            return
        end

        queueAddEvent:FireAllClients(audio.id, audio.properties, audio.metadata)
    end)

    self.audioRemoved:Connect(function(index: number, _audio: types.queueAudio, queue: string)
        if queue ~= "replicatedQueue" then
            return
        end

        queueAddEvent:FireAllClients(index)
    end)
end

return (controller :: any) :: controller
