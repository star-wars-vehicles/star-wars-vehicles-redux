local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "RG-9 Laser Cannon"
WEAPON.Author = "Borstel"

function WEAPON:Initialize()
	self.Bullet:SetTracer("red_tracer_fx")

	BaseClass.Initialize(self)
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

SWVR.Weapons:Register(WEAPON, "rg9_cannon")
