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

return require(if RunService:IsClient() then script.environments.client else script.environments.server)
