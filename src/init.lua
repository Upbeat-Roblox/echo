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

if RunService:IsClient() then
    local client = require(script.environments.client)
    return client :: client.controller
else
    local server = require(script.environments.client)
    return server :: server.controller
end
