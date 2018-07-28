AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, tr, ClassName)
  if not tr.Hit then
    return
  end

  local ent = ents.Create(ClassName)
  ent:SetPos(tr.HitPos + tr.HitNormal * 5)
  ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
  ent:Spawn()
  ent:Activate()

  return ent
end

function ENT:Initialize()
  -- Call setup to initialize ship limitations
  self:Setup({
    health = 1000,
    shields = 600,
    speed = 1500,
    verticalspeed = 550,
    acceleration = 7,
    back = false,
    roll = true,
    freelook = true
  })

  -- Adding a weapon group. Must be done BEFORE weapons are added to it.
  self:AddWeaponGroup("Pilot", "weapons/rz2_shoot.wav", self:InitBullet{
    damage = 50,
    color = "red",
    delay = 0.12,
    overheatAmount = 40
  })

  -- Adding weapons
  self:AddWeapon("Pilot", "Right", Vector(120, 87, 45))
  self:AddWeapon("Pilot", "Left", Vector(120, -87, 45))

  -- Please note, if you are adding a seat/pilot with weapon groups, those groups must be added BEFORE (the weapons can be added to the groups whenever)

  -- Setting up the pilot seat.
  --- self:AddPilot(exitpos, fpvpos, pilotpos, pilotang, weapon(s)...)
  self:AddPilot(Vector(-20, 0, 35), nil, {
    exitpos = Vector(-180, 0, 0),
    fpvpos = Vector(-15, 0, 75),
    weapons = {"Pilot"}
  })

  self:AddEvent("OnCritical", function()
    self:EmitSound("startrek/ships/kelvin/torpedo/hit0" .. tostring( math.Round( math.random( 1, 4 ) ) ) .. ".wav", 500, 255, 1, CHAN_AUTO)
  end, false)

  -- Initialize the base, do not remove.
  self.BaseClass.Initialize(self)
end
