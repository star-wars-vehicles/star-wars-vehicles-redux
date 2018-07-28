ENT.Base = "swvr_base"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.PrintName = "ARC-170 BF2 New"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/arc170/arc170_bf2.mdl"
ENT.FlightModel = "models/arc170/arc170_bf2_wings.mdl"
ENT.Vehicle = "Arc170BF2"
ENT.Allegiance = "Republic"

list.Set("SWVRVehicles", ENT.PrintName, ENT)
util.PrecacheModel("models/arc170/arc170_bf2_cockpit.mdl") -- Precache clientside models please!
