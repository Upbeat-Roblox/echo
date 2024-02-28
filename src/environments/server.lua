local baseEnvironment = require(script.Parent.base)
local createAudio = require(script.Parent.Parent.functions.createAudio)
local generateAudioID = require(script.Parent.Parent.functions.generateAudioID)
local getPlayParameters = require(script.Parent.Parent.functions.getPlayParameters)
local playEvent: RemoteEvent = script.Parent.Parent.events.play
local stopEvent: RemoteEvent = script.Parent.Parent.events.stop

type audio = baseEnvironment.audio & {
    instance: Sound?,
    replicate: boolean,
    replicateData: {
        startTime: number,
        audioID: string,
        parent: Instance?,
        position: number?,
    }?,
}

--[[
    Controls the server.

    @public
]]
local server = baseEnvironment

--[[
    Starts the server environment.

    @returns never
]]
function server:start()
    self:baseStart()

    playEvent.OnServerEvent:Connect(function(player: Player)
        for id: string, audio: audio in pairs(self._audios) do
            if audio.replicate ~= true or audio.replicateData == nil then
                continue
            end

            playEvent:FireClient(
                player,
                audio.replicateData.audioID,
                audio.replicateData.parent,
                audio.group,
                id,
                audio.replicateData.startTime - os.clock() + (audio.replicateData.position or 0)
            )
        end
    end)
end

--[[
    Plays a audio on the clients.

    @param {string} audioID [The ID of the audio.]
    @param {Instance?} parent [The parent to be used for the audio instance.]
    @param {string?} group [The ID of the audio group.]
    @param {boolean?} persistent [Stores the audio in a group. WARNING: The audio will not be cleaned up automatically.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {number?} position [The starting position of the audio.]
    @returns string
]]
function server:play(
    audioID: string,
    parent: Instance?,
    group: string?,
    persistent: boolean?,
    id: string?,
    position: number?
): string
    if typeof(id) ~= "string" then
        id = generateAudioID(audioID)
    end

    if persistent == true then
        self._audios[id] = {
            instance = nil,
            group = group,
            replicate = true,
            replicateData = {
                startTime = os.clock(),
                audioID = audioID,
                parent = parent,
                position = position,
            },
        }
    end

    playEvent:FireAllClients(audioID, parent, group, id, position)
    return id :: string
end

--[[
    Plays a audio on the server.

    @param {string} audioID [The ID of the audio.]
    @param {Instance?} parent [The parent to be used for the audio instance.]
    @param {string?} group [The ID of the audio group.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {number?} position [The starting position of the audio.]
    @returns Sound
]]
function server:playOnServer(audioID: string, parent: Instance?, group: string?, id: string?, position: number?): Sound
    parent, group, id, position = getPlayParameters(audioID, parent, group, id, position)

    local audioInstance: Sound =
        createAudio(audioID, parent :: Instance, group :: string, id :: string, position :: number)
    audioInstance.Volume = self:getVolume(group)
    audioInstance:Play()

    audioInstance.Ended:Once(function()
        self:stop(id)
    end)

    self._audios[id] = {
        instance = audioInstance,
        group = group,
    }

    return audioInstance
end

--[[
    Stops and removes a audio.

    @param {string} id [The ID for accessing the audio through Echo.]
    @returns never
]]
function server:stop(id: string)
    local audio: audio? = self._audios[id]

    if audio == nil then
        stopEvent:FireAllClients(id)
        return
    end

    if audio.replicate then
        stopEvent:FireAllClients(id)
        self._audios[id] = nil
    end

    audio.instance:Destroy()
    self._audios[id] = nil
end

return server
