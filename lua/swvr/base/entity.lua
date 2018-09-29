local ENTITY = FindMetaTable("Entity")

function ENTITY:Side()
	local allegiance = self.Allegiance
	return table.HasValue(SWVR.Sides.Light, allegiance) and "Light" or table.HasValue(SWVR.Sides.Dark, allegiance) and "Dark" or "Neutral"
end

function ENTITY:IsStarWarsVehicle(swvr)
	if swvr then
		return tobool(self.IsSWVRVehicle)
	end

	return tobool(self.IsSWVRVehicle) or tobool(self.IsSWVRVehicle)
end