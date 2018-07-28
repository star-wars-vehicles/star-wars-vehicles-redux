AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:StartMotionController()
    self:SetUseType(SIMPLE_USE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(255, 255, 255, 1))

    self.Damage = self.Damage or 1000
    self.Lifetime = self.Lifetime and CurTime() + self.Lifetime or -1

    local phys = self:GetPhysicsObject()
    phys:SetMass(50)
    phys:EnableGravity(false)
    phys:Wake()
end

function ENT:Prepare(parent, pos, options)
  options = options or {}
  local color = options.color and Vector(options.color.r / 255, options.color.g / 255, options.color.b / 255) or Vector(1, 1, 1)

  self:SetNWVector("Color", color)
  self:SetNWFloat("StartSize", options.startsize or 20)
  self:SetNWFloat("EndSize", options.endsize or 5)
  self:SetNWBool("IsWhite", Either(isbool(options.white), options.white, true))

  self.Damage = options.damage or 1000
  self.Lifetime = options.lifetime or nil
  self.Target = options.target or NULL
  self.Velocity = options.velocity or 500
  self.Shooter = parent
end

function ENT:Think()
    if not self.Targetting then return end

    if (self.Lifetime ~= -1 and self.Lifetime < CurTime()) then
      self:Bang()
    end

    if not IsValid(self.Target) then
        self.Targetting = false
    else
        self:SetAngles((self.Target:GetPos() - self:GetPos()):Angle())
    end
end

local FlightPhys = {
  secondstoarrive	= 1,
  maxangular		= 50000,
  maxangulardamp	= 10000000,
  maxspeed			= 100000000,
  maxspeeddamp		= 10,
  dampfactor		= 0.1,
  teleportdistance	= 5000
}

function ENT:PhysicsSimulate(phys, deltatime)
    local ang = self.Ang or self:GetForward():Angle()

    if (self.Targetting) then
        if (IsValid(self.Target)) then
            ang = (self.Target:GetPos() - self:GetPos()):Angle()
        else
            self.Targetting = false
        end
    end

    FlightPhys.angle = ang
    FlightPhys.pos = self:GetPos() + self:GetForward() * self.Velocity
    FlightPhys.deltatime = deltatime

    phys:ComputeShadowControl(FlightPhys)
end

function ENT:Bang()
  local pos = self:GetPos()
  local fx = EffectData()
  fx:SetOrigin(pos)

  util.Effect("HelicopterMegaBomb", fx, true, true)

  self:EmitSound("vehicles/shared/swvr_proton_torpedo.wav", 511)

  SafeRemoveEntityDelayed(self, 0.01)
end

function ENT:PhysicsCollide(colData, collider)
  if IsValid(self.Shooter) and IsValid(colData.HitEntity) and colData.HitEntity == self.Shooter then return end



  local e = colData.HitEntity
  if (IsValid(e) and e.IsSWVRVehicle) then
    if (self.Ion) then
      e:SetIon(e:GetIon() + 10)
    end

    e:TakeDamage(self.Damage)
  end

  self:Bang()
end

