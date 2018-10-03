local CANNON = {}

CANNON.Base = "swvr_base_weapon"
CANNON.Type = "cannon"

DEFINE_BASECLASS("swvr_base_weapon")

AccessorFunc(CANNON, "Velocity", "Velocity", FORCE_NUMBER)
AccessorFunc(CANNON, "Damage", "Damage", FORCE_NUMBER)

function CANNON:Initialize()
	BaseClass.Initialize(self)
end

function CANNON:Fire()
	if not (IsValid(self.Owner) and IsValid(self.Parent) and IsValid(self.Entity)) then return end

	local dir = self.Owner:GetAngles():Forward()

	local proj = ents.Create("laser_bolt_swvr")
	proj:SetPos(self:GetPos())
	proj:SetOwner(self.Owner)
	proj:SetAngles(self.Owner:GetAngles())
	proj:SetDamage(self.Damage or 50)
	proj:SetColor(Color(255, 255, 0))
	proj:Spawn()
	proj:SetVelocity(dir * (self.Velocity or 5000))

	local phys = proj:GetPhysicsObject()

	if not IsValid(phys) then return end

	phys:SetVelocity(dir * (self.Velocity or 5000))
end

SWVR.Weapons:Register(CANNON, "proj_cannon")
