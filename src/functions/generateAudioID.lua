--[[
    Generates a audio ID.

    @param {number} audioID [The ID of the audio.]
    @returns string
--]]
local function generateAudioID(audioID: number): string
	return `{tostring(audioID)}.{tostring(os.clock())}`
end

return generateAudioID