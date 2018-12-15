AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:OnInitialize()
  self:SetupDefaults()
end

function ENT:PrimaryAttack()
  if self:GetNextPrimaryFire() > CurTime() then return end

  self:SetNextPrimaryFire(CurTime() + 0.1)

  self:EmitSound( "AWING_FIRE1" )

  for i = 0,1 do
    self.MirrorPrimary = not self.MirrorPrimary

    local Mirror = self.MirrorPrimary and -1 or 1

    local bullet = {}
    bullet.Num 	= 1
    bullet.Src 	= self:LocalToWorld( Vector(50,91.88 * Mirror,6.196) )
    bullet.Dir 	= self:LocalToWorldAngles( Angle(0,0,0) ):Forward()
    bullet.Spread 	= Vector( 0.01,  0.01, 0 )
    bullet.Tracer	= 1
    bullet.TracerName	= "swvr_tracer_red"
    bullet.Force	= 100
    bullet.HullSize 	= 25
    bullet.Damage	= 40
    bullet.Attacker 	= self:GetPilot()
    bullet.AmmoType = "Pistol"
    bullet.Callback = function(att, tr, dmginfo)
      dmginfo:SetDamageType(DMG_AIRBOAT)
    end

    self:FireBullets( bullet )
  end
end

function ENT:SecondaryAttack()
  if self:GetNextSecondaryFire() > CurTime() then return end

  self:SetNextSecondaryFire(CurTime() + 0.45)
end
