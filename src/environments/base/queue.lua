local RunService = game:GetService("RunService")

local BLACKLISTED_QUEUE_IDS: { string } = { "default", "replicatedQueue" }

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
    setQueue: (self: controller, queue: string) -> never,
    addToQueue: (self: controller, queue: string, id: string, properties: types.properties, metadata: types.metadata?) -> number,
    add: (self: controller, id: string, properties: types.properties, metadata: types.metadata?) -> number,
    removeFromQueue: (self: controller, queue: string, id: number | string) -> never,
    remove: (self: controller, id: number | string) -> never,
    play: (self: controller) -> never,
    stop: (self: controller) -> never,
    next: (self: controller) -> never,
    back: (self: controller) -> never,
    restart: (self: controller) -> never,
    getCurrentAudioMetadata: (self: controller) -> types.metadata,
    skipTo: (self: controller, id: number | string) -> never,
    _start: (self: controller) -> never,
    _playIndex: (self: controller, index: number) -> never,
    _findIndexByID: (self: controller, id: string) -> number?,
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

    table.insert(self._queues[queue].audios, {
        id = id,
        properties = properties,
        metadata = metadata,
    })

    return #self._queues[queue]
end

--[[
    Adds a song to the default queue.

    @param {string} id [The ID for accessing the audio through Echo.]
    @param {types.properties} properties [The audio properties.]
    @param {types.metadata?} metadata [The audio metadata.]
    @returns number
]]
function controller:add(...): number
    return self:addToQueue("default", ...)
end

--[[
    Removes a song from the queue.

    @param {string} queue [The ID of the queue.]
    @param {number | string} id [The index or ID of the audio.]
    @returns never
]]
function controller:removeFromQueue(queue: string, id: number | string)
    local index: number? = if typeof(id) == "string" then self:_findIndexByID(id) else id

    if typeof(index) ~= "number" then
        warn("audioIDDoesNotExist", id)
        return
    end

    if self._currentQueue == queue and self._currentIndexInQueue == index then
        self:next()
    end

    table.remove(self._queues[self._currentQueue].audios, index)
end

--[[
    Removes a song to the default queue.

    @param {number | string} id [The index or ID of the audio.]
    @returns never
]]
function controller:remove(...)
    return self:removeFromQueue("default", ...)
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
    environmentController:stop("queue")
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
    return self._queues[self._currentQueue].audios[self._currentIndexInQueue]
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

    local queue: types.queue = self._queues[self._currentQueue]

    if queue.playing ~= true then
        return
    end

    local audio: types.queueAudio = queue.audios[index]

    if audio == nil then
        return
    end

    environmentController:play(audio.properties, audio.id, "queue")
end

--[[
    Returns the index of a audio via the id.

    @private
    @param {string} id [The ID for accessing the audio through Echo.]
    @returns number?
]]
function controller:_findIndexByID(id: string): number?
    local audioIndex: number

    for index: number, audio: types.queueAudio in ipairs(self._queues[self._currentQueue]) do
        if audio.id ~= id then
            continue
        end

        audioIndex = index
    end

    return if typeof(audioIndex) == "number" then audioIndex else nil
end

return (controller :: any) :: controller
