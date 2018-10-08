local CANNON = {}

CANNON.Base = "swvr_base_weapon"
CANNON.Type = "cannon"
CANNON.Bullet = {}

DEFINE_BASECLASS("swvr_base_weapon")

AccessorFunc(CANNON, "Velocity", "Velocity", FORCE_NUMBER)
AccessorFunc(CANNON, "Projectile", "Projectile", FORCE_BOOL)

AccessorFunc(CANNON, "Color", "Color")

AccessorFunc(CANNON, "Bullet", "Bullet")
AccessorFunc(CANNON.Bullet, "TracerName", "Tracer", FORCE_STRING)
AccessorFunc(CANNON.Bullet, "Damage", "Damage", FORCE_NUMBER)
AccessorFunc(CANNON.Bullet, "Callback", "Callback")

local TRACERS = {
	"RED", "WHITE", "YELLOW", "PURPLE", "GREEN", "BLUE"
}

function CANNON:Initialize()
	self.Bullet:SetCallback(function(attacker, tr, dmgInfo)
		local ship = dmgInfo:GetInflictor():GetParent()

		util.Decal("fadingscorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

		local fx = EffectData()
		fx:SetOrigin(tr.HitPos)
		fx:SetNormal(tr.HitNormal)

		util.Effect("StunstickImpact", fx, true)

		if not IsValid(ship) or ship == tr.Entity then return end

		if self.Bullet.splash then
			util.BlastDamage(ship, ship.Pilot or ship, tr.HitPos, self.Bullet.Damage * 1.5, self.Bullet.Damage * 0.66)
		end
	end)

	if not self.Bullet:GetTracer() then
		self.Bullet:SetTracer("blue_tracer_fx")
	end

	BaseClass.Initialize(self)
end

function CANNON:SetColor(col)
	if isstring(col) and table.HasValue(TRACERS, string.upper(col)) then
		self.Color = Color(255, 255, 255)
		self.Tracer = string.upper(col)
	else
		self.Color = col
		self.Tracer = "WHITE"
	end
end

function CANNON:SetDamage(d)
	self.Damage = d

	self:GetBullet():SetDamage(d)
end

function CANNON:SetTracer(name)
	self.Tracer = name

	self:GetBullet():SetTracer(name)
end

function CANNON:GetTracer()
	return self.Tracer
end

function CANNON:Fire()
	if not (IsValid(self.Owner) and IsValid(self.Parent) and IsValid(self.Entity)) then return end

	if not self:GetProjectile() then
		local tr = util.TraceLine({
			start = self.Parent:GetPos(),
			endpos = self.Parent:GetPos() + self.Parent:GetForward() * 10000,
			filter = { self.Parent }
		})

		local dir = tr.HitPos - self.Entity:GetPos()

		if self:GetIsTracking() and IsValid(self.Player) then
			dir = self.Player:GetAimVector():Angle():Forward()
		end

		if (self:GetCanLock() or true) and IsValid(self.Target) then
			local lock = util.TraceLine({
				start = self.Entity:GetPos(),
				endpos = self.Target:GetPos(),
				filter = { self.Parent }
			})

			if not lock.HitWorld then
				dir = (self.Target:GetPos() + self.Target:GetUp() * (self.Target:GetModelRadius() / 10)) - self.Entity:GetPos()
			end
		end

		local bullet = table.Copy(self.Bullet)
		bullet.IgnoreEntity = self.Parent
		bullet.Src = self.Entity:GetPos()
		bullet.Attacker = self.Owner
		bullet.Spread = Vector(1, 1, 1) * (self.Owner.Velocity.x / 1000)
		bullet.Dir = dir

		self.Entity:FireBullets(bullet)
	else
		local dir = self.Owner:GetAngles():Forward()

		local proj = ents.Create("laser_bolt_swvr")
		proj:SetPos(self:GetPos())
		proj:SetOwner(self.Owner)
		proj:SetAngles(self.Owner:GetAngles())
		proj:SetDamage(self.Damage or 50)
		proj:SetTracer(self.Tracer or "WHITE")
		proj:SetColor(self:GetColor())
		proj:Spawn()
		proj:SetVelocity(dir * (self.Velocity or 5000))

		local phys = proj:GetPhysicsObject()

		if not IsValid(phys) then return end

		phys:SetVelocity(dir * (self.Velocity or 5000))
	end
end

SWVR.Weapons:Register(CANNON, "swvr_base_cannon")
