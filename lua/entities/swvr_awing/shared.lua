ENT.Type = "anim"
ENT.Base = "swvr_base"

DEFINE_BASECLASS("swvr_base")

ENT.PrintName = "RZ-1 A-Wing"
ENT.Author = "Doctor Jew"
ENT.Information = ""
ENT.Category = "Republic"
ENT.Class = "Fighter"

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.Model = Model("models/diggerthings/awing/awing3.mdl")
ENT.SpawnHeight = 50

ENT.Mass = 2000
ENT.Inertia = Vector(150000, 150000, 150000)

ENT.Controls = {
  Elevator = Vector(-300),
  Rudder = Vector(-300),
  Wings = Vector(100),
  Thrust = Vector(40)
}

ENT.Handling = Vector(1200, 1500, 700)

ENT.MaxPower = 28000

ENT.MaxThrust = 2800
ENT.BoostThrust = 3000

ENT.MaxVelocity = 3000

ENT.MaxHealth = 600
ENT.MaxShield = 500

ENT.Engines = {
  Vector(-110, -50, 0),
  Vector(-110, 50, 0)
}

ENT.Settings = {
  Engine = {
    Sprite = "effects/muzzleflash2",
    Type = 2,
    Glow = true,
    Color = Color(255, 175, 0)
  }
}

ENT.Parts = {}

ENT.Sounds = {
  Engine = "YWING_ENGINE"
}

ENT.Gibs = {
  Model("models/DiggerThings/AWing/gib1.mdl"),
  Model("models/DiggerThings/AWing/gib2.mdl"),
  Model("models/DiggerThings/AWing/gib3.mdl"),
  Model("models/DiggerThings/AWing/gib4.mdl"),
  Model("models/DiggerThings/AWing/gib5.mdl"),
  Model("models/DiggerThings/AWing/gib6.mdl")
}

sound.Add({
  name = "AWING_FIRE1",
  channel = CHAN_WEAPON,
  volume = 1.0,
  level = 125,
  pitch = { 95, 105 },
  sound = "swvr/weapons/swvr_rg9_fire.wav"
})
