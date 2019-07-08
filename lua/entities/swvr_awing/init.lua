AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:OnInitialize()
  self:SetupDefaults()

  self:AddSeat("Pilot", Vector(-20), Angle(0, -90, 0))

  self:AddWeapon("Primary", "FrontL", Vector(50, -91.88, 6.196))
  self:AddWeapon("Primary", "FrontR", Vector(50, 91.88, 6.196))
end

function ENT:PrimaryAttack()
  if not self:CanPrimaryAttack() then return end

  self:SetNextPrimaryFire(CurTime() + 0.1)

  self:EmitSound( "AWING_FIRE1" )

  self:FireWeaponGroup("Primary")
end

function ENT:SecondaryAttack()
  if self:GetNextSecondaryFire() > CurTime() then return end

  self:SetNextSecondaryFire(CurTime() + 0.45)
end
