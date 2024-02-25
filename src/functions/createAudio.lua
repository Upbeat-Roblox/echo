--[[
    Creates an audio.

    @param {number} audioID [The ID of the audio.]
    @param {Instance} parent [The parent to be used for the audio instance.]
    @param {string} group [The ID of the audio group.]
    @param {string} id [The ID for accessing the audio through Echo.]
    @param {number} position [The starting position of the audio.]
    @returns Sound
]]
local function createAudio(audioID: number, parent: Instance, group: string, id: string, position: number): Sound
    local audioInstance: Sound = Instance.new("Sound")
    audioInstance.Parent = parent
    audioInstance.TimePosition = position :: number
    return audioInstance
end

return createAudio
