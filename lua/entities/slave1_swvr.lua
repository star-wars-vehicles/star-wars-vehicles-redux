ENT.Base = "swvr_base"

ENT.Category = "Independent"
ENT.Class = "Transport"

ENT.PrintName = "Slave I"
ENT.Author = "Doctor Jew"

if SERVER then
  AddCSLuaFile()

  function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then
      return
    end

    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + Vector(0, 0, 175))
    ent:SetAngles(Angle(-90, ply:GetAimVector():Angle().Yaw - 180, 0))
    ent:Spawn()
    ent:Activate()

    return ent
  end

  function ENT:Initialize()
    self:Setup({
      Model = "models/firespray/firespray1.mdl",
      Health = 1500,
      Shields = 500,
      Speed = 1500,
      BoostSpeed = 3000,
      VerticalSpeed = 600,
      Acceleration = 10,
      Roll = true,
      TakeOffVector = Vector(0, 0, 300),
      LandAngles = Angle(-90, 0, 0)
    })

    self:AddWeaponGroup("Pilot", "gn40_cannon", {
      Delay = 0.2,
      Damage = 75,
      CanOverheat = true,
      MaxOverheat = 20
    })

    self:AddWeapon("Pilot", "Left", Vector(60, -40, 70))
    self:AddWeapon("Pilot", "Right", Vector(60, 40, 70))

    self:AddWeaponGroup("Seismic", "v7_seismic", {
      Delay = 10
    })

    self:AddWeapon("Seismic", "Back", Vector(-180, 0, 375))

    self:AddPilot(nil, nil, {
      FPVPos = Vector(10, 0, 400),
      Weapons = { "Pilot", "Seismic" },
      ExitPos = Vector(-100, 0, 0)
    })

    self.BaseClass.Initialize(self)

    self:SetSkin(1)
  end
end

if CLIENT then
  function ENT:Initialize()
    self:Setup({
      EngineSound = "vehicles/slave1_fly_loop.wav",
      ViewDistance = 1000,
      ViewHeight = 500
    })

    self:SetupDefaults()

    local Engine = {
      StartSize = 30,
      EndSize = 22.5,
      Lifetime = 2.7,
      Color = Color(255, 255, 255),
      Sprite = "sprites/orangecore1"
    }

    for i = 1, 5 do
      self:AddEngine(Vector(-152.5, i * 10, 407.5), Engine)
      self:AddEngine(Vector(-152.5, i * -10, 407.5), Engine)
    end

    self:AddEngine(Vector(-152.5, 45, 315), {
      StartSize = 39,
      EndSize = 29,
      Lifetime = 2.7,
      Color = Color(255, 255, 255),
      Sprite = "sprites/orangecore1"
    })

    self:AddEngine(Vector(-152.5, -45, 316), {
      StartSize = 39,
      EndSize = 29,
      Lifetime = 2.7,
      Color = Color(255, 255, 255),
      Sprite = "sprites/orangecore1"
    })

    self.BaseClass.Initialize(self)
  end
end
