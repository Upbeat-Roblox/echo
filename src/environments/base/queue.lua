local Signal = require(script.Parent.Parent.Parent.Packages.Signal)

local BLACKLISTED_QUEUE_IDS: { string } = { "default", "replicatedQueue" }

local types = require(script.Parent.Parent.Parent.types)
local warn = require(script.Parent.Parent.Parent.functions.warn)

--[[
    Controls the queue.

    @public
]]
local controller = {}
controller.audioAdded = Signal.new()
controller.audioRemoved = Signal.new()
controller.audioPlaying = Signal.new()
controller.queueReset = Signal.new()
controller.queueStop = Signal.new()
controller._currentIndexInQueue = 0
controller._currentQueue = "default"
controller._queues = {}

type Signal = typeof(Signal.new())

export type controller = {
    audioAdded: Signal,
    audioRemoved: Signal,
    audioPlaying: Signal,
    queueReset: Signal,
    queueStop: Signal,
    _currentIndexInQueue: number,
    _currentQueue: string,
    _queues: { [string]: types.queue },
    _controller: any,
    currentQueue: (self: controller) -> string,
    createQueue: (self: controller, queue: string) -> never,
    destroyQueue: (self: controller, queue: string) -> never,
    setQueue: (self: controller, queue: string) -> never,
    addToQueue: (
        self: controller,
        queue: string,
        id: string,
        properties: types.properties,
        metadata: types.metadata?
    ) -> number,
    add: (self: controller, id: string, properties: types.properties, metadata: types.metadata?) -> number,
    removeFromQueue: (self: controller, queue: string, id: number | string) -> never,
    remove: (self: controller, id: number | string) -> never,
    resetQueue: (self: controller, queue: string) -> never,
    isPlaying: (self: controller) -> boolean,
    getQueue: (self: controller, queue: string?) -> { types.queueAudio },
    play: (self: controller) -> never,
    pause: (self: controller) -> never,
    next: (self: controller) -> never,
    back: (self: controller) -> never,
    restart: (self: controller) -> never,
    getCurrentAudioMetadata: (self: controller) -> types.metadata,
    skipTo: (self: controller, id: number | string) -> never,
    _start: (self: controller, controller: any) -> never,
    _playIndex: (self: controller, index: number) -> never,
    _findIndexByID: (self: controller, id: string) -> number?,
}

--[[
    Returns the current queue.

    @returns string
]]
function controller:currentQueue(): string
    return self._currentQueue
end

--[[
    Creates a new queue.

    @param {string} queue [The ID of the queue.]
    @returns never
]]
function controller:createQueue(queue: string)
    if self._queues[queue] then
        warn("queueCreateIDError", queue)
        return
    end

    self._queues[queue] = {
        playing = false,
        audios = {},
    }
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

    self._queues[queue] = nil
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

    local queueWasPlaying: boolean = self._queues[self._currentQueue].playing
    self:pause()

    self._currentQueue = queue
    self:restart()

    if queueWasPlaying then
        self:play()
    end
end

--[[
    Adds a song to the queue.

    @param {string} queue [The ID of the queue.]
    @param {string} id [The ID for accessing the audio through Echo.]
    @param {types.properties} properties [The audio properties.]
    @param {types.metadata?} metadata [The audio metadata.]
    @returns number
]]
function controller:addToQueue(
    queue: string,
    id: string,
    properties: types.properties,
    metadata: types.metadata?
): number
    if self._queues[queue] == nil then
        warn("queueDoesNotExist", queue)
        return 0
    end

    local audio: types.queueAudio = {
        id = id,
        properties = properties,
        metadata = metadata,
    }

    self.audioAdded:Fire(audio, queue)
    table.insert(self._queues[queue].audios, audio)

    local index: number = #self._queues[queue].audios

    -- If the current queue is playing but this is the first song in the queue then
    -- it must played.
    if self._currentQueue == queue and self:isPlaying() and index == 1 then
        self:_playIndex(index)
    end

    return index
end

--[[
    Adds a song to the current queue.

    @param {string} id [The ID for accessing the audio through Echo.]
    @param {types.properties} properties [The audio properties.]
    @param {types.metadata?} metadata [The audio metadata.]
    @returns number
]]
function controller:add(...): number
    return self:addToQueue(self._currentQueue, ...)
end

--[[
    Removes a song from a queue.

    @param {string} queue [The ID of the queue.]
    @param {number | string} id [The index or ID of the audio.]
    @returns never
]]
function controller:removeFromQueue(queue: string, id: number | string)
    if self._queues[queue] == nil then
        warn("queueDoesNotExist", queue)
        return
    end

    local index: number? = if typeof(id) == "string" then self:_findIndexByID(id) else id

    if typeof(index) ~= "number" then
        warn("audioIDDoesNotExist", id)
        return
    end

    if self._currentQueue == queue and self._currentIndexInQueue == index then
        self:next()
    end

    self.audioRemoved:Fire(index, self._queues[queue].audios[index], queue)
    table.remove(self._queues[queue].audios, index)
end

--[[
    Removes a song to the current queue.

    @param {number | string} id [The index or ID of the audio.]
    @returns never
]]
function controller:remove(...)
    return self:removeFromQueue(self._currentQueue, ...)
end

--[[
    Resets a queue.

    @param {string} queue [The ID of the queue.]
    @returns never
]]
function controller:resetQueue(queue: string)
    if self._queues[queue] == nil then
        warn("queueDoesNotExist", queue)
        return
    end

    if self._currentQueue == queue then
        self._controller:stop("replicatedQueue")
    end

    self._queues[queue].audios = {}
    self.queueReset:Fire(queue)
end

--[[
    Resets and stops the current queue.

    @returns never
]]
function controller:reset()
    self:pause()
    self:resetQueue(self._currentQueue)
end

--[[
    Returns if the current queue is playing.

    @returns boolean
]]
function controller:isPlaying(): boolean
    return self._queues[self._currentQueue].playing
end

--[[
    Returns the audio queue.

    @param {string?} queue [The ID of the queue.]
    @returns { types.queueAudio }
]]
function controller:getQueue(queue: string?): { types.queueAudio }
    if typeof(queue) == "string" then
        if self._queues[queue] == nil then
            warn("queueDoesNotExist", queue)
            return {}
        end

        return self._queues[queue].audios
    else
        return self._queues[self._currentQueue].audios
    end
end

--[[
    Plays the current queue.

    @returns never
]]
function controller:play()
    if self._queues[self._currentQueue].playing then
        return
    end

    self._queues[self._currentQueue].playing = true
    self:_playIndex(self._currentIndexInQueue)
end

--[[
    Pauses the current queue.

    @returns never
]]
function controller:pause()
    if self._queues[self._currentQueue].playing ~= true then
        return
    end

    self._queues[self._currentQueue].playing = false
    self._controller:stop("replicatedQueue")
    self.queuePause:Fire()
end

--[[
    Plays the next song in the queue.

    @returns never
]]
function controller:next()
    if #self._queues[self._currentQueue].audios <= 0 then
        return
    end

    if self._currentIndexInQueue >= #self._queues[self._currentQueue].audios then
        self._currentIndexInQueue = 0
    end

    self:_playIndex(self._currentIndexInQueue + 1)
end

--[[
    Plays the previous song in the queue.

    @returns never
]]
function controller:back()
    if #self._queues[self._currentQueue].audios <= 0 then
        return
    end

    if self._currentIndexInQueue <= 0 then
        self._currentIndexInQueue = #self._queues[self._currentQueue].audios
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
    return self._queues[self._currentQueue].audios[self._currentIndexInQueue].metadata
end

--[[
    Skips to a song in queue.

    @param {number | string} id [The index or ID of the audio.]
    @returns never
]]
function controller:skipTo(id: number | string)
    local index: number? = if typeof(id) == "string" then self:_findIndexByID(id) else id

    if typeof(index) ~= "number" then
        warn("audioIDDoesNotExist", id)
        return
    end

    if index > #self._queues[self._currentQueue].audios then
        self._currentIndexInQueue = #self._queues[self._currentQueue].audios
    end

    if index < 0 then
        self._currentIndexInQueue = 0
    end

    self:_playIndex(index)
end

--[[
    Starts the environment.

    @private
    @param {any} controller [The Echo controller.]
    @returns never
]]
function controller:_start(controller)
    controller:setVolume(1, "queue")
    self._controller = controller

    self:createQueue("default")
    self:setQueue("default")
    self:createQueue("replicatedQueue")
end

--[[
    Plays a audio from the current queue using the index.

    @private
    @param {number} index [The index of the audio in the queue.]
    @returns never
]]
function controller:_playIndex(index: number)
    self._currentIndexInQueue = index

    local queue: types.queue = self._queues[self._currentQueue]

    if queue.playing ~= true then
        return
    end

    self._controller:stop("replicatedQueue")

    local audio: types.queueAudio = queue.audios[index]

    if audio == nil then
        return
    end

    self.audioPlaying:Fire(audio, self._currentQueue)

    local audioInstance: Sound = self._controller:_play(audio.properties, "replicatedQueue", "queue")
    audioInstance.Ended:Once(function()
        self:next()
    end)
end

--[[
    Returns the index of a audio via the ID.

    @private
    @param {string} id [The ID for accessing the audio through Echo.]
    @returns number?
]]
function controller:_findIndexByID(id: string): number?
    local audioIndex: number

    for index: number, audio: types.queueAudio in ipairs(self._queues[self._currentQueue].audios) do
        if audio.id ~= id then
            continue
        end

        audioIndex = index
    end

    return if typeof(audioIndex) == "number" then audioIndex else nil
end

return (controller :: any) :: controller
