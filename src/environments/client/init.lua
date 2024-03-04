local baseEnvironment = require(script.Parent.base)
local queue = require(script.queue)
local types = require(script.Parent.Parent.types)
local warn = require(script.Parent.Parent.functions.warn)
local playEvent: RemoteEvent = script.Parent.Parent.events.play
local stopEvent: RemoteEvent = script.Parent.Parent.events.stop

--[[
    Controls the client.

    @public
]]
local controller = baseEnvironment
controller._started = false

export type controller = baseEnvironment.controller & {
    _started: boolean,
    start: (self: controller) -> never,
    play: (self: controller, properties: types.properties, id: string?, group: string?) -> Sound,
}

--[[
    Starts the client environment.

    @returns never
]]
function controller:start()
    if self._started then
        warn("alreadyStarted")
        return
    end

    self._started = true
    self:_start()
    queue:_start()

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
