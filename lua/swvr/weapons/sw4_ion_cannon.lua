local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "SW-4 Ion Cannon"
WEAPON.Author = "ArMek"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("blue_tracer_fx")

	self.Bullet:SetCallback(function(attacker, tr, dmgInfo)
		(self.Bullet:GetCallback())(attacker, tr, dmgInfo)

		if not IsValid(tr.Entity) or not tr.Entity.IsSWVRVehicle then return end

		local ent = tr.Entity

		print("Ye")
	end)
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end


SWVR.Weapons:Register(WEAPON, "sw4_ion_cannon")