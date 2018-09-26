-- many code, much wow
if SERVER then
	include("swvr/sv_init.lua")
end

if CLIENT then
	include("swvr/cl_init.lua")
end
