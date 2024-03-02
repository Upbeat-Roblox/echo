local RunService = game:GetService("RunService")

local BLACKLISTED_QUEUE_IDS: {string} = {"default"}

local environmentController =
    require(if RunService:IsClient() then script.Parent.Parent.client else script.Parent.Parent.server)
local types = require(script.Parent.Parent.Parent.types)
local warn = require(script.Parent.Parent.Parent.functions.warn)

--[[
    Controls the queue.

    @public
]]
local controller = {}
controller._currentIndexInQueue = 0
controller._currentQueue = nil
controller._queues = {}

export type controller = {
    _currentIndexInQueue: number,
    _currentQueue: string,
    _queues: { [string]: types.queue },
    createQueue: (queue: string) -> never,
    destroyQueue: (queue: string) -> never,
    setQueue: (queue: string) -> never,
    next: () -> never,
    back: () -> never,
    restart: () -> never,
    getCurrentAudioMetadata: () -> types.metadata,
    skipTo: (index: number) -> never,
    _start: () -> never,
    _playIndex: (index: number) -> never,
}

--[[
    Creates a new queue.

    @param {string} queue [The ID of the queue.]
    @returns never
]]
function controller:createQueue(queue: string)
    if table.find(BLACKLISTED_QUEUE_IDS, queue) then
        warn("blacklistedQueueID", queue, "createQueue")
        return
    end

    if self._queues[queue] then
        warn("queueCreateIDError", queue)
        return
    end

    self._currentQueue = queue
    self:restart()
end

--[[
    Destroys a queue.

    @param {string} queue [The ID of the queue.]
    @returns never
]]
function controller:destroyQueue(queue: string)
    if table.find(BLACKLISTED_QUEUE_IDS, queue) then
        warn("blacklistedQueueID", queue, "destroyQueue")
        return
    end

    if self._queues[queue] == nil then
        warn("queueDoesNotExist", queue)
        return
    end

    if queue == self._currentQueue then
        self:setQueue("default")
    end

    self._currentQueue = queue
    self:restart()
end

--[[
    Sets the current queue.

    @param {string} queue [The ID of the queue.]
    @returns never
]]
function controller:setQueue(queue: string)
    if self._queues[queue] == nil then
        warn("queueDoesNotExist", queue)
        return
    end

    if queue == self._currentQueue then
        return
    end

    self._currentQueue = queue
    self:restart()
end

--[[
    Plays the next song in the queue.

    @returns never
]]
function controller:next()
    if self._currentIndexInQueue >= #self._queues[self._currentQueue] then
        self._currentIndexInQueue = 0
    end

    self:_playIndex(self._currentIndexInQueue + 1)
end

--[[
    Plays the previous song in the queue.

    @returns never
]]
function controller:back()
    if self._currentIndexInQueue <= 0 then
        self._currentIndexInQueue = #self._queues[self._currentQueue]
    end

    self:_playIndex(self._currentIndexInQueue - 1)
end

--[[
    Restarts the queue.

    @returns never
]]
function controller:restart()
    self:_playIndex(0)
end

--[[
    Gets the metadata for the current song.

    @returns types.metadata
]]
function controller:getCurrentAudioMetadata(): types.metadata
    return self._queues[self._currentQueue][self._currentIndexInQueue]
end

--[[
    Skips to a song in queue.

    @param {number} index [The index of the audio in the queue.]
    @returns never
]]
function controller:skipTo(index: number)
    if index > #self._queues[self._currentQueue] then
        self._currentIndexInQueue = #self._queues[self._currentQueue]
    end

    if index < 0 then
        self._currentIndexInQueue = 0
    end

    self:_playIndex(index)
end

--[[
    Starts the environment.

    @private
    @returns never
]]
function controller:_start()
    self:setQueue("default")
    environmentController:setVolume("queue", 1)
end

--[[
    Plays a audio from the current queue using the index.

    @private
    @param {number} index [The index of the audio in the queue.]
    @returns never
]]
function controller:_playIndex(index: number)
    self._currentIndexInQueue = index

    local audio: types.queueAudio = self._queues[self._currentQueue][index]

    if audio == nil then
        return
    end

    environmentController:play(audio.properties, audio.id, "queue")
end

return (controller :: any) :: controller
