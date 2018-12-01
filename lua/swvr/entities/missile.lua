local ENT = {}

ENT.Base = "swvr_weapon"

DEFINE_BASECLASS("swvr_weapon")

function ENT:Initialize()
	BaseClass.Initialize(self)
end

function ENT:Fire()
	local e = ents.Create("proton_torpedo")
	e:SetPos(self:GetPos())
	e:SetAngles(self.Parent:GetAngles())

	e:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	e:Prepare(self.Owner, {
		Damage = 600,
		Color = Color(255, 255, 255),
		StartSize = 20,
		EndSize = 15,
		Ion = false
	})

	e.Ang = self.Parent:GetAngles()

	if (IsValid(self:GetTarget())) then
		e.Target = target
		e.Targetting = true
	end

	e:Spawn()
	e:Activate()
	constraint.NoCollide(self.Owner, e, 0, 0)

	BaseClass.Fire(self)
end

scripted_ents.Register(ENT, "swvr_missile")
