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
    return require(script.environments.client)
else
    return require(script.environments.server)
end
