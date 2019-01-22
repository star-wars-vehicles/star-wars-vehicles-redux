AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, tr, ClassName)
  if not tr.Hit then return end

  local ent = ents.Create(ClassName)
  ent:SetPos(tr.HitPos + tr.HitNormal * 20)
  ent:Spawn()
  ent:Activate()

  return ent
end

function ENT:BlindFire()
  if self:GetDisabled() then return end

  local phys = self:GetPhysicsObject()

  if not IsValid(phys) then return end

  phys:SetVelocityInstantaneous(self:GetForward() * (self:GetStartVelocity() + 3000))
end

function ENT:FollowTarget(followent)
  local speed = (self:GetStartVelocity() + 3000)
  local rate = self:GetCleanMissile() and 55 or 45
  local target = followent:LocalToWorld(followent:OBBCenter())

  if isfunction(followent.GetMissileOffset) then
    local offset = followent:GetMissileOffset()

    if isvector(offset) then
      target = followent:LocalToWorld(offset)
    end
  end

  local pos = target + followent:GetVelocity() * 0.25
  local phys = self:GetPhysicsObject()

  if IsValid(phys) and not self:GetDisabled() then
    local dir = (pos - self:GetPos()):GetNormalized():Angle()
    local AF = self:WorldToLocalAngles(dir)
    AF.p = math.Clamp(AF.p * 400, -rate, rate)
    AF.y = math.Clamp(AF.y * 400, -rate, rate)
    AF.r = math.Clamp(AF.r * 400, -rate, rate)

    phys:AddAngleVelocity(Vector(AF.r, AF.p, AF.y) - phys:GetAngleVelocity())
    phys:SetVelocityInstantaneous(self:GetForward() * speed)
  end
end

function ENT:Initialize()
  self:SetModel("models/weapons/w_missile_launch.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetRenderMode(RENDERMODE_TRANSALPHA)
  self:PhysWake()

  local phys = self:GetPhysicsObject()

  if IsValid(phys) then
    phys:EnableGravity(false)
    phys:SetMass(1)
  end

  self.SpawnTime = CurTime()
end

function ENT:Think()
  local Target = self:GetLockOn()

  if IsValid(Target) then
    self:FollowTarget(Target)
  else
    self:BlindFire()
  end

  if (self.SpawnTime + 12) < CurTime() then
    self:Remove()
  end

  self:NextThink(CurTime())

  return true
end

function ENT:PhysicsCollide(data)
  if self:GetDisabled() then
    SafeRemoveEntityDelayed(self, 0)
  else
    util.BlastDamage(IsValid(self:GetInflictor()) and self:GetInflictor() or Entity(0), IsValid(self:GetAttacker()) and self:GetAttacker() or Entity(0), self:GetPos(), 500, 200)
    SafeRemoveEntityDelayed(self, 0)
  end
end

function ENT:OnTakeDamage(dmginfo)
  if dmginfo:GetDamageType() ~= DMG_AIRBOAT then return end
  if self:GetAttacker() == dmginfo:GetAttacker() then return end

  if not self:GetDisabled() then
    self:SetDisabled(true)
    local phys = self:GetPhysicsObject()

    if IsValid(phys) then
      phys:EnableGravity(true)
      self:PhysWake()
      self:EmitSound("Missile.ShotDown")
    end
  end
end
