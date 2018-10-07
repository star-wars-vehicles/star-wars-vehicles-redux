local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "GN-40 Laser Cannon"
WEAPON.Author = "Brush Galactic Defense"

WEAPON.Sound = "gn40_cannon"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("red_tracer_fx")
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

sound.Add({
	name = "gn40_cannon",
	channel = CHAN_AUTO,
	volume = 0.5,
	level = 80,
	pitch = { 95, 110 },
	sound = "swvr/weapons/swvr_gn40_fire.wav"
})

SWVR.Weapons:Register(WEAPON, "gn40_cannon")
