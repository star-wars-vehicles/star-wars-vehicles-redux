local MISSILE = { }

MISSILE.Base = "swvr_base_weapon"
MISSILE.Type = "missile"

DEFINE_BASECLASS("swvr_base_weapon")

function MISSILE:Initialize()
	BaseClass.Initialize(self)
end

function MISSILE:Fire()
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

SWVR.Weapons:Register(MISSILE, "swvr_base_missile")