export type audio = {
    instance: Sound,
    group: string,
}

--[[
    Controls the base environment.

    @public
]]
local base = {}
base._volume = {}
base._audios = {}

--[[
    Starts the environment.

    @returns never
]]
function base:baseStart()
    self:setVolume(1)
end

--[[
    Sets the volume of a audio group.

    @param {number} volume [The new volume.]
    @param {string?} group [The ID of the audio group.]
    @returns never
]]
function base:setVolume(volume: number, group: string?)
    if typeof(group) ~= "string" then
        group = "default"
    end

    self._volume[group] = volume

    for _id: string, audio: audio in pairs(self._audios) do
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
function base:getVolume(group: string?): number
    if typeof(group) ~= "string" then
        group = "default"
    end

    return self._volume[group] or 0
end

return base
