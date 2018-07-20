ENT.Base = "swvr_base"
ENT.Category = "Star Wars Vehicles: Rebels"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.PrintName = "A-Wing New"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/awing/awing_bf2.mdl"
ENT.Vehicle = "AWingNew"
ENT.Allegiance = "Rebel Alliance"

list.Set("SWVRVehicles", ENT.PrintName, ENT)
util.PrecacheModel("models/awing/new_awing_cockpit.mdl") -- Precache clientside models please!
