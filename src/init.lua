--[[
     ____            __                
    /\  _`\         /\ \               
    \ \ \L\_\    ___\ \ \___     ___   
     \ \  _\L   /'___\ \  _ `\  / __`\ 
      \ \ \L\ \/\ \__/\ \ \ \ \/\ \L\ \
       \ \____/\ \____\\ \_\ \_\ \____/
        \/___/  \/____/ \/_/\/_/\/___/ 

    Github: https://github.com/monke-mob/echo
]]

local RunService = game:GetService("RunService")

if RunService:IsServer() then
    local client: ModuleScript = script.environments:FindFirstChild("client")

    if RunService:IsRunning() and client then
        client:Destroy()
    end

    local server = require(script.environments.server)
    return server :: server.controller
else
    local server: ModuleScript = script.environments:FindFirstChild("server")

    if RunService:IsRunning() and server then
        server:Destroy()
    end

    local client = require(script.environments.client)
    return client :: client.controller
end
