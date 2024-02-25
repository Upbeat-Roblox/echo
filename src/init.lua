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

local environment: ModuleScript

if RunService:IsClient() then
    environment = script.client
else
    environment = script.server
end

return require(environment)
