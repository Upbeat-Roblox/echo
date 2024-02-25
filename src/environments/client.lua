local baseEnvironment = require(script.Parent.base)
local createAudio = require(script.Parent.Parent.functions.createAudio)
local getPlayParameters = require(script.Parent.Parent.functions.getPlayParameters)
local playEvent: RemoteEvent = script.Parent.Parent.events.play
local stopEvent: RemoteEvent = script.Parent.Parent.events.stop

--[[
    Controls the client.

    @public
]]
local client = baseEnvironment

--[[
    Starts the client environment.

    @returns never
]]
function client:start()
    self:baseStart()

    playEvent.OnClientEvent:Connect(function(...)
        self:play(...)
    end)

    stopEvent.OnClientEvent:Connect(function(...)
        self:stop(...)
    end)
end

--[[
    Plays a audio.

    @param {number} audioID [The ID of the audio.]
    @param {Instance?} parent [The parent to be used for the audio instance.]
    @param {string?} group [The ID of the audio group.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {number?} position [The starting position of the audio.]
    @returns Sound
]]
function client:play(audioID: number, parent: Instance?, group: string?, id: string?, position: number?)
    parent, group, id, position = getPlayParameters(audioID, parent, group, id, position)

    local audioInstance: Sound =
        createAudio(audioID, parent :: Instance, group :: string, id :: string, position :: number)
    audioInstance.Volume = self:getVolume(group)

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
function client:stop(id: string)
    local audio: baseEnvironment.audio? = self._audios[id]

    if audio == nil then
        return
    end

    audio.instance:Destroy()
    self._audios[id] = nil
end

return client
