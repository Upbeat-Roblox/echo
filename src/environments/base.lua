local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local PROPERTY_BLACKLIST: { string } = { "audioID", "handleCleanup", "Parent", "Volume", "Name" }

local generateAudioID = require(script.Parent.Parent.functions.generateAudioID)
local types = require(script.Parent.Parent.types)
local stopEvent: RemoteEvent = script.Parent.Parent.events.stop

--[[
    Controls the base environment.

    @private
]]
local controller = {}
controller._groups = {}
controller._audios = {}

export type controller = {
    _groups: { [string]: number },
    _audios: { [string]: types.audio },
    setVolume: (volume: number, group: string?) -> never,
    getVolume: (group: string?) -> number,
    _start: () -> never,
    _play: (properties: types.properties, id: string?, group: string?) -> Sound,
    _getProperty: (properties: types.properties, property: string, default: types.property) -> types.property,
}

--[[
    Stops and destroys an audio.

    @param {string?} id [The ID for accessing the audio through Echo.]
    @returns never
]]
function controller:stop(id: string)
    local audio: types.audio? = self._audios[id]

    if audio == nil then
        return
    elseif audio.instance then
        audio.instance:Destroy()
    elseif RunService:IsServer() and audio.replicates then
        stopEvent:FireAllClients(id)
    end

    self._audios[id] = nil
end

--[[
    Sets the volume of a audio group.

    @param {number} volume [The new volume.]
    @param {string?} group [The ID of the audio group.]
    @returns never
]]
function controller:setVolume(volume: number, group: string?)
    if typeof(group) ~= "string" then
        group = "default"
    end

    self._groups[group] = volume

    for _id: string, audio: types.audio in pairs(self._audios) do
        if audio.group ~= group then
            continue
        end

        audio.instance.Volume = volume
    end
end

--[[
    Gets the volume of a audio group.

    @param {string?} group [The ID of the audio group.]
    @returns number
]]
function controller:getVolume(group: string?): number
    if typeof(group) ~= "string" then
        group = "default"
    end

    return self._groups[group] or 0
end

--[[
    Starts the environment.

    @returns never
]]
function controller:_start()
    self:setVolume(1)
end

--[[
    Plays a audio.

    @private
    @param {types.properties} properties [The audio properties.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {string?} group [The ID of the audio group.]
    @returns Sound
]]
function controller:_play(properties: types.properties, id: string?, group: string?): Sound
    if typeof(id) ~= "string" then
        id = generateAudioID(properties.audioID)
    end

    local audioInstance: Sound = Instance.new("Sound")
    audioInstance.Name = self:_getProperty(properties, "Name", id)
    audioInstance.SoundId = properties.audioID
    audioInstance.Parent =
        self:_getProperty(properties, "Parent", if RunService:IsClient() then SoundService else workspace)
    audioInstance.Volume = self:_getProperty(properties, "Volume", self:getVolume(group))

    for property: string, value: types.property in pairs(properties) do
        -- Some properties should not be set via this loop, so we skip those.
        if table.find(PROPERTY_BLACKLIST, property) or audioInstance[property] == nil then
            continue
        end

        audioInstance[property] = value
    end

    local destroyOnEnded: boolean = self:_getProperty(properties, "destroyOnEnded", true)

    -- If the audio is on loop then the Ended signal will never be called.
    if destroyOnEnded and audioInstance.Looped ~= true then
        audioInstance.Ended:Once(function()
            self:stop(id)
        end)
    else
        -- The audio will not be destroyed by Echo automatically so in case the developer does not use
        -- the stop method then a connection to the Destroying signal is needed so that the audio can be
        -- removed internally.
        audioInstance.Destroying:Connect(function()
            self:stop(id)
        end)

        if destroyOnEnded and audioInstance.Looped then
            -- Warn the developer of the error to make it more clear on the issue.
            warn(
                "[Echo] destroyOnEnded property was set true but the audio was also looped. If you wish for Echo to handle cleanup of the audio then set looped to false."
            )
        end
    end

    self._audios[id] = {
        instance = audioInstance,
        group = group,
        replicates = false,
    }

    return audioInstance
end

--[[
    Returns a user passed property value or returns its default value.

    @private
    @param {types.properties} properties [The audio properties.]
    @param {string} property [The property name.]
    @param {types.property} default [The default property value.]
    @returns types.property
]]
function controller:_getProperty(
    properties: types.properties,
    property: string,
    default: types.property
): types.property
    return if properties[property] then properties[property] else default
end

return (controller :: any) :: controller
