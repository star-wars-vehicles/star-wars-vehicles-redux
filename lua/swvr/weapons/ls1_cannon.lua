local WEAPON = {}

DEFINE_BASECLASS("swvr_base_cannon")

WEAPON.Base = "swvr_base_cannon"
WEAPON.Type = "cannon"

WEAPON.Name = "LS-1 Laser Cannon"
WEAPON.Author = "Sienar Fleet Systems"

WEAPON.Sound = "ls1_cannon"

function WEAPON:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("red_tracer_fx")
end

function WEAPON:Fire()
	BaseClass.Fire(self)
end

sound.Add({
	name = "ls1_cannon",
	channel = CHAN_AUTO,
	volume = 0.5,
	level = 80,
	pitch = { 95, 110 },
	sound = "swvr/weapons/swvr_ls1_fire.wav"
})

SWVR.Weapons:Register(WEAPON, "ls1_cannon")
