SWVR.Modules = SWVR.Modules or {}

local BaseClasses = {
	["movement"] = "swvr_module_movement",
	["health"] = "swvr_module_health",
	["damage"] = "swvr_module_damage",
	["weapon"] = "swvr_module_weapon"
}

function SWVR:RegisterModule(module, base)
	local Base = module.Base
	if not Base then Base = BaseClasses[string.lower(module.Type)] end

	if not module.Name then error("SWVR: Cannot register unnamed module!") end

	local tab = {}

	tab.type 		= module.Type
	tab.t 	 		= module
	tab.isBaseType  = true
	tab.Base 		= Base
	tab.t.ClassName = module.Name

	if not Base then
		error("SWVR: Registered module '" .. module.Name .. "' has an invalid base!")
	end

	self.Modules[module.Name] = tab

	list.Set("SWVRModules", module.Name, {
		Name = module.Name,
		Type = module.Type
	})
end
