local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "RG-9 Laser Cannon"
WEAPON.Author = "Borstel"

WEAPON.Sound = "rg9_cannon"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("red_tracer_fx")
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

sound.Add({
	name = "rg9_cannon",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 80,
	pitch = {90, 110},
	sound = "weapons/ywing_shoot.wav"
})

SWVR.Weapons:Register(WEAPON, "rg9_cannon")
