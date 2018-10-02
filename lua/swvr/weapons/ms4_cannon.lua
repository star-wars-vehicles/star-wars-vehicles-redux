local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "MS-4 Twin Blaster Cannon"
WEAPON.Author = "Taim & Bak"

WEAPON.Sound = "ms4_cannon"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("green_tracer_fx")
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

sound.Add({
	name = "ms4_cannon",
	channel = CHAN_WEAPON,
	volume = 0.5,
	level = 80,
	pitch = { 95, 110 },
	sound = "swvr/weapons/swvr_ms4_fire.wav"
})

SWVR.Weapons:Register(WEAPON, "ms4_cannon")
