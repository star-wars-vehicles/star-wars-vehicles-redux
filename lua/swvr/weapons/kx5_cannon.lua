local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "KX-5 Laser Cannon"
WEAPON.Author = "Taim & Bak"

WEAPON.Sound = "kx5_cannon"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("blue_tracer_fx")
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

sound.Add({
	name = "kx5_cannon",
	channel = CHAN_WEAPON,
	volume = 0.5,
	level = 80,
	pitch = { 95, 110 },
	sound = "swvr/weapons/swvr_kx12_fire.wav"
})

SWVR.Weapons:Register(WEAPON, "kx5_cannon")
