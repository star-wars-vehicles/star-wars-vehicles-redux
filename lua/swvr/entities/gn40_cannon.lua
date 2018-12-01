local ENT = {}

DEFINE_BASECLASS("swvr_cannon")

ENT.Base = "swvr_cannon"

ENT.Name = "GN-40 Laser Cannon"
ENT.Author = "Brush Galactic Defense"

ENT.Sound = "gn40_cannon"

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Bullet:SetTracer("red_tracer_fx")
end

sound.Add({
	name = "gn40_cannon",
	channel = CHAN_AUTO,
	volume = 0.5,
	level = 80,
	pitch = { 95, 110 },
	sound = "swvr/weapons/swvr_gn40_fire.wav"
})

scripted_ents.Register(ENT, "gn40_cannon")
