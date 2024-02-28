--[[
    Generates a audio ID.

    @param {string} audioID [The ID of the audio.]
    @returns string
--]]
local function generateAudioID(audioID: string): string
	return `{audioID}.{tostring(os.clock())}`
end

return generateAudioID