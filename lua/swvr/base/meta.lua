local ENTITY = FindMetaTable("Entity")

function ENTITY:Side()
	local allegiance = self.Allegiance

	return table.HasValue(SWVR.Sides.Light, allegiance) and "Light" or table.HasValue(SWVR.Sides.Dark, allegiance) and "Dark" or "Neutral"
end

function ENTITY:IsStarWarsVehicle(swvr)
	if swvr then return tobool(self.IsSWVRVehicle) end

	return tobool(self.IsSWVRVehicle) or tobool(self.IsSWVRVehicle)
end

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
