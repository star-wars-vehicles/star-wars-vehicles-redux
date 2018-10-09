ENT.Base = "swvr_base"

ENT.Category = "Republic"
ENT.Class = "Bomber"

ENT.PrintName = "Y-Wing BTL-B"
ENT.Author = "Doctor Jew"

if SERVER then
  AddCSLuaFile()

  function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 5)
    ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
    ent:Spawn()
    ent:Activate()

    return ent
  end

  function ENT:Initialize()
    -- MUST call setup to initialize ship limitations
    self:Setup({
      Model = "models/ywing/ywing_btlb_test.mdl",
      Health = 1000,
      Speed = 1500,
      Shields = 800,
      VerticalSpeed = 550,
      Acceleration = 6,
      Back = true,
      Freelook = true,
      Roll = false
    })

    -- Adding a weapon group. Must be done BEFORE weapons are added to it.
    self:AddWeaponGroup("Pilot", "rg9_cannon", {
      CanOverheat = true,
      Damage = 80,
      Tracer = "blue_tracer_fx",
      Delay = 0.15
    })

    -- Adding weapons
    self:AddWeapon("Pilot", "Right", Vector(520, 25, 40))
    self:AddWeapon("Pilot", "Left", Vector(520, -25, 40))

    -- self:AddWeaponGroup("Torpedo", "proton_torpedo", {
    -- })
    -- self:AddWeapon("Torpedo", "Front", Vector(530, 0, -40))
    self:AddPilot(Vector(300, 0, 60), nil, {
      ExitPos = Vector(-400, 0, 0),
      FPVPos = Vector(300, 0, 95),
      Weapons = { "Pilot" } --[[, "Torpedo"]]
    })

    -- Adding a parent with a custom callback, the callback gets called every tick to update the part's position and angles
    self:AddPart("TurretGuard", "models/ywing/ywing_btlb_turret.mdl", Vector(256, 0, 105), nil, {
      Seat = "Back",
      Callback = function(ship, part, ply)
        local aim = ply:GetAimVector():Angle()

        return nil, Angle(ship:GetAngles().p, aim.y + 180, ship:GetAngles().r)
      end
    })

    -- Adding a part with a parent that is another part, by default the parent is the ship
    self:AddPart("Turret", "models/ywing/ywing_btlb_guns.mdl", Vector(242, 0, 114), nil, {
      Parent = "TurretGuard",
      Seat = "Back",
      Callback = function(ship, part, ply)
        local aim = ply:GetAimVector():Angle()
        local p = aim.p * -1

        return nil, Angle(p, aim.y + 180, 0)
      end
    })

    self:AddWeaponGroup("Back", "rg9_cannon", {
      Parent = "Turret",
      Damage = 75,
      Tracer = "blue_tracer_fx",
      Delay = 0.2,
      IsTracking = true
    })

    self:AddWeapon("Back", "TurretRight", Vector(195, 18, 120))
    self:AddWeapon("Back", "TurretLeft", Vector(195, -18, 120))

    -- Adding a seat.
    self:AddSeat("Back", Vector(255, 0, 85), self:GetAngles() + Angle(0, 90, 0), {
      Visible = false,
      ExitPos = Vector(0, 35, -20),
      Weapons = { "Back" }
    })

    -- Initialize the base, do not remove.
    self.BaseClass.Initialize(self)
  end
end

if CLIENT then
  function ENT:Initialize()
    self:Setup({
      ViewDistance = 1200,
      ViewHeight = 375,
      Cockpit = {
        Path = "models/ywing/ywing_btlb_test_cockpit.mdl"
      },
      EngineSound = "vehicles/ywing_eng_loop2.wav"
    })

    self:SetupDefaults()

    local engineOptions = {
      StartSize = 65,
      EndSize = 40,
      Lifetime = 2.7,
      Color = Color(255, 0, 0),
      Sprite = "sprites/bluecore"
    }

    -- Adding engine effects
    self:AddEngine(Vector(-630, 240, 60), engineOptions)
    self:AddEngine(Vector(-630, -240, 60), engineOptions)

    self:AddLight(Vector(-630, 240, 60), {
      Size = 100
    })

    -- Initialize the base, do not remove.
    self.BaseClass.Initialize(self)
  end
end