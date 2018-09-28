local CANNON = {}

CANNON.Base = "swvr_base_weapon"
CANNON.Type = "cannon"
CANNON.Bullet = {}

DEFINE_BASECLASS("swvr_base_weapon")

AccessorFunc(CANNON, "Bullet", "Bullet")
AccessorFunc(CANNON.Bullet, "TracerName", "Tracer", FORCE_STRING)
AccessorFunc(CANNON.Bullet, "Damage", "Damage", FORCE_NUMBER)
AccessorFunc(CANNON.Bullet, "Callback", "Callback")

function CANNON:Initialize()
	self.Bullet:SetCallback(function(attacker, tr, dmgInfo)
		local ship = dmgInfo:GetInflictor():GetParent()

		util.Decal("fadingscorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

		local fx = EffectData()
		fx:SetOrigin(tr.HitPos)
		fx:SetNormal(tr.HitNormal)

		util.Effect("StunstickImpact", fx, true)

		if IsValid(ship) and ship ~= tr.Entity then
			if self.Bullet.splash then
				util.BlastDamage(ship, ship.Pilot or ship, tr.HitPos, self.Bullet.Damage * 1.5, self.Bullet.Damage * 0.66)
			end

			if self.Ion and tr.Entity.IsSWVRVehicle then
				tr.Entity.IonShots = tr.Entity.IonShots + 1
			end
		end
	end)

	if not self.Bullet:GetTracer() then
		self.Bullet:SetTracer("blue_tracer_fx")
	end

	BaseClass.Initialize(self)
end

function CANNON:SetDamage(d)
	self.Damage = d

	self:GetBullet():SetDamage(d)
end

function CANNON:SetTracer(name)
	self.Tracer = name

	self:GetBullet():SetTracer(name)
end

function CANNON:Fire()
	if not (IsValid(self.Owner) and IsValid(self.Parent) and IsValid(self.Entity)) then return end

	local tr = util.TraceLine({
		start = self.Parent:GetPos(),
		endpos = self.Parent:GetPos() + self.Parent:GetForward() * 10000,
		filter = { self.Parent }
	})

	local dir = tr.HitPos - self.Entity:GetPos()

	if self:GetIsTracking() and IsValid(self.Player) then
		dir = self.Player:GetAimVector():Angle():Forward()
	end

	if self:GetCanLock() and IsValid(self.Target) then
		local lock = util.TraceLine({
			start = self.Entity:GetPos(),
			endpos = self.Target:GetPos(),
			filter = { self.Parent }
		})

		if not lock.HitWorld then
			dir = (self.Target:GetPos() + self.Target:GetUp() * (self.Target:GetModelRadius() / 3)) - self.Entity:GetPos()
		end
	end

	local bullet = table.Copy(self.Bullet)
	bullet.IgnoreEntity = self.Parent
	bullet.Src = self.Entity:GetPos()
	bullet.Attacker = self.Owner
	bullet.Spread = Vector(1, 1, 1) * (self.Owner.Velocity.x / 1000)
	bullet.Dir = dir

	self.Entity:FireBullets(bullet)
end

SWVR.Weapons:Register(CANNON, "swvr_base_cannon")
