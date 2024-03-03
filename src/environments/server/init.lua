local baseEnvironment = require(script.Parent.base)
local queue = require(script.queue)
local generateAudioID = require(script.Parent.Parent.functions.generateAudioID)
local types = require(script.Parent.Parent.types)
local playEvent: RemoteEvent = script.Parent.Parent.events.play

--[[
    Controls the server.

    @public
]]
local controller = baseEnvironment
controller.queue = queue

export type controller = baseEnvironment.controller & {
    queue: queue.controller,
    start: (self: controller) -> never,
    play: (self: controller, properties: types.properties, id: string?, group: string?) -> string,
    playOnServer: (self: controller, properties: types.properties, id: string?, group: string?) -> Sound,
}

--[[
    Starts the server environment.

    @returns never
]]
function controller:start()
    self:_start()
    self.queue:_start()

    playEvent.OnServerEvent:Connect(function(player: Player)
        for id: string, audio: types.audio in pairs(self._audios) do
            if audio.replicates ~= true or audio.properties == nil then
                continue
            end

            -- Update the position so that the client is at the same position as all the others.
            local position: number = self:_getProperty(audio.properties, "Position", 0)
            local startTime: number = self:_getProperty(audio.metadata, "startTime", os.clock())
            audio.properties["Position"] = startTime - os.clock() + position

            playEvent:FireClient(player, audio.properties, id, audio.group)
        end
    end)
end

--[[
    Plays a audio on the clients.

    @param {types.properties} properties [The audio properties.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {string?} group [The ID of the audio group.]
    @returns string
]]
function controller:play(properties: types.properties, id: string?, group: string?): string
    if typeof(id) ~= "string" then
        id = generateAudioID(properties.audioID)
    end

    local persistent: boolean = self:_getProperty(properties, "persistent", false)

    if persistent then
        self._audios[id] = {
            instance = nil,
            group = group,
            replicates = true,
            properties = properties,
            metadata = {
                startTime = os.clock(),
            },
        }
    else
        id = `replicatedNotPersistent-{id}`
    end

    playEvent:FireAllClients(properties, id, group)

    return id :: string
end

--[[
    @extends baseEnvironment._play
]]
controller.playOnServer = controller._play

return (controller :: any) :: controller
