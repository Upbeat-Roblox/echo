local errors = require(script.Parent.Parent.errors)

--[[
    Warns using a error message.

    @param {string} errorID [The ID of the error.]
    @param {any} ... [The format strings.]
    @returns never
--]]
local function customWarn(errorID: string, ...)
    warn(`[Echo] {string.format(errors[errorID], ...)}`)
end

return customWarn
