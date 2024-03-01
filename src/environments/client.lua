local baseEnvironment = require(script.Parent.base)
local types = require(script.Parent.Parent.types)
local playEvent: RemoteEvent = script.Parent.Parent.events.play
local stopEvent: RemoteEvent = script.Parent.Parent.events.stop

--[[
    Controls the client.

    @public
]]
local controller = baseEnvironment

export type controller = baseEnvironment.controller & {
    start: () -> never,
    play: (properties: types.properties, id: string?, group: string?) -> Sound,
}

--[[
    Starts the client environment.

    @returns never
]]
function controller:start()
    self:_start()

    -- Request the persistent audios that are already being played.
    playEvent:FireServer()

    playEvent.OnClientEvent:Connect(function(...)
        self:_play(...)
    end)

    stopEvent.OnClientEvent:Connect(function(...)
        self:stop(...)
    end)
end

--[[
    @extends baseEnvironment._play
]]
controller.play = controller._play

return (controller :: any) :: controller
