local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local generateAudioID = require(script.Parent.generateAudioID)

--[[
    Assigns defaults values to parameters if no value is provided.

    @param {number} audioID [The ID of the audio.]
    @param {Instance?} parent [The parent to be used for the audio instance.]
    @param {string?} group [The ID of the audio group.]
    @param {string?} id [The ID for accessing the audio through Echo.]
    @param {number?} position [The starting position of the audio.]
    @returns Instance, string, string, number
--]]
local function getPlayParameters(
    audioID: number,
    parent: Instance?,
    group: string?,
    id: string?,
    position: number?
): (Instance, string, string, number)
    if typeof(parent) ~= "Instance" then
        parent = if RunService:IsClient() then SoundService else workspace
    end

    if typeof(group) ~= "string" then
        group = "default"
    end

    if typeof(id) ~= "string" then
        id = generateAudioID(audioID)
    end

    if typeof(position) ~= "number" then
        position = 0
    end

    return parent :: Instance, group :: string, id :: string, position :: number
end

return getPlayParameters
