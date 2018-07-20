ENT.Base = "swvr_base"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.PrintName = "Y-Wing BTL-B"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/ywing/ywing_btlb_test.mdl"
ENT.Vehicle = "YWingBtlB"
ENT.Allegiance = "Republic"

list.Set("SWVRVehicles", ENT.PrintName, ENT)
util.PrecacheModel("models/ywing/ywing_btlb_test_cockpit.mdl")
