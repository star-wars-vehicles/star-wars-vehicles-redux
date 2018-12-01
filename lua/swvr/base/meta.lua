
-- ENTITY META

local ENTITY = FindMetaTable("Entity")

function ENTITY:Side()
	local allegiance = self.Allegiance

	return table.HasValue(SWVR.Sides.Light, allegiance) and "Light" or table.HasValue(SWVR.Sides.Dark, allegiance) and "Dark" or "Neutral"
end

function ENTITY:IsStarWarsVehicle(swvr)
	if swvr then return tobool(self.IsSWVRVehicle) end

	return tobool(self.IsSWVRVehicle) or tobool(self.IsSWVRVehicle)
end

-- PLAYER META

local PLAYER = FindMetaTable("Player")

function PLAYER:ButtonDown(button)
	return self.Inputs[button]
end

function PLAYER:ButtonUp(button)
	return not self.Inputs[button]
end

function PLAYER:ControlDown(control)
	local key = self:GetInfoNum(control, KEY_NONE)
	return self:ButtonDown(key)
end

function PLAYER:ControlUp(control)
	local key = self:GetInfoNum(control, KEY_NONE)
	return self:ButtonUp(key)
end

function PLAYER:ControlSet(control)
	return self:GetInfoNum(control, KEY_NONE) ~= 0
end

-- GM HOOKS

hook.Add("PlayerButtonDown", "SWVRPlayerButtonDown", function(ply, button)
	ply.Inputs = ply.Inputs or {}

	ply.Inputs[button] = true
end)

hook.Add("PlayerButtonUp", "SWVRPlayerButtonUp", function(ply, button)
	ply.Inputs = ply.Inputs or {}

	ply.Inputs[button] = false
end)

hook.Add("PlayerInitialSpawn", "SWVRPlayerInitialSpawn", function(ply)
	ply.Inputs = ply.Inputs or {}
end)

hook.Add("OnSpawnMenuOpen", "SWVROnSpawnMenuOpen", function()
	if LocalPlayer():GetNWBool("Flying") and LocalPlayer():GetInfoNum("swvr_key_modifier", KEY_Q) == KEY_Q then return false end
end)

hook.Add("ContextMenuOpen", "SWVRContextMenuOpen", function()
	if LocalPlayer():GetNWBool("Flying") then return false end
end)

-- ENTITY HOOKS

hook.Add("OnEntityCreated", "SWVRSetupPlayer", function(ent)
	if ent:IsPlayer() then
		ent:SetNWEntity("Ship", nil)
		ent:SetNWEntity("Seat", nil)
		ent:SetNWBool("Flying", false)
		ent:SetNWBool("Pilot", false)
		ent:SetNWVector("ExitPos", Vector(0, 0, 0))
	end
end)

hook.Add("PlayerSpawnedSENT", "SWVRPlayerSpawnedSENT", function(ply, ent)
	if ent.IsSWVRVehicle then
		cleanup.Add(ply, "swvehicles", ent)
	end
end)
