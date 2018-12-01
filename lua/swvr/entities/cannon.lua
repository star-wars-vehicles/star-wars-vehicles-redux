local ENT = {}

DEFINE_BASECLASS("swvr_weapon")

ENT.Base = "swvr_weapon"

ENT.Bullet = {}

AccessorFunc(ENT, "Bullet", "Bullet")

AccessorFunc(ENT.Bullet, "TracerName", "Tracer", FORCE_STRING)
AccessorFunc(ENT.Bullet, "Damage", "Damage", FORCE_NUMBER)
AccessorFunc(ENT.Bullet, "Callback", "Callback")
AccessorFunc(ENT.Bullet, "Velocity", "Velocity", FORCE_NUMBER)
AccessorFunc(ENT.Bullet, "Hitscan", "Hitscan", FORCE_BOOL)

AccessorFunc(ENT, "Projectile", "Projectile", FORCE_BOOL)
AccessorBool(ENT, "Projectile", "Is")

function ENT:Initialize()
	self:GetBullet():SetCallback(function(attacker, tr, dmgInfo)
		local ship = dmgInfo:GetInflictor():GetParent()

		util.Decal("fadingscorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

		local fx = EffectData()
		fx:SetOrigin(tr.HitPos)
		fx:SetNormal(tr.HitNormal)

		util.Effect("StunstickImpact", fx, true)

		if not IsValid(ship) or ship == tr.Entity then return end

		if self:GetBullet().splash then
			util.BlastDamage(ship, ship.Pilot or ship, tr.HitPos, self:GetBullet():GetDamage() * 1.5, self:GetBullet():GetDamage() * 0.66)
		end
	end)

	if not self:GetBullet():GetTracer() then
		self:GetBullet():SetTracer("blue_tracer_fx")
	end

	BaseClass.Initialize(self)
end

function ENT:IsHitscan()
	return self:GetBullet():IsHitscan()
end

function ENT:FireWeapon()
	if not IsValid(self:GetParent()) then return end

	local parent = self:GetParent() or self

	if not self:IsProjectile() then
		local tr = util.TraceLine({
			start = parent:GetPos(),
			endpos = parent:GetPos() + parent:GetForward() * 10000,
			filter = { parent }
		})

		local dir = tr.HitPos - self:GetPos()

		if self:IsTracking() and IsValid(self:GetOwner()) then
			dir = self:GetOwner():GetAimVector():Angle():Forward()
		end

		if self:CanLock() and IsValid(self:GetTarget()) then
			local lock = util.TraceLine({
				start = self:GetPos(),
				endpos = self:GetTarget(),
				filter = { self:GetParent() }
			})

			if not lock.HitWorld then
				dir = (self:GetTarget():GetPos() + self:GetTarget():GetUp() * (self:GetTarget():GetModelRadius() / 10)) - self:GetPos()
			end
		end

		local bullet = table.Copy(self:GetBullet())
		bullet.IgnoreEntity = parent
		bullet.Src = self:GetPos()
		bullet.Attacker = self:GetOwner()
		bullet.Spread = Vector(1, 1, 1) * self:GetOwner().Velocity.x / 1000
		bullet.Dir = dir

		self:FireBullets(bullet)
	else
		local dir = self:GetOwner():GetAngles():Forward()
		local bullet = self:GetBullet()

		local proj = ents.Create("laser_bolt_swvr")
		proj:SetPos(self:GetPos())
		proj:SetOwner(self:GetOwner() or self)
		proj:SetAngles((self:GetOwner() or self):GetAngles())
		proj:SetDamage(bullet:GetDamage())
		proj:SetTracer(bullet:GetTracer())
		proj:SetColor(self:GetColor())
		proj:Spawn()
		proj:SetVelocity(bullet:GetVelocity() or Vector(5000, 0, 0))

		local phys = proj:GetPhysicsObject()

		if not IsValid(phys) then return end

		phys:SetVelocity(dir * (bullet:GetVelocity() or 5000))
	end

	BaseClass.FireWeapon(self)
end

scripted_ents.Register(ENT, "swvr_cannon")
