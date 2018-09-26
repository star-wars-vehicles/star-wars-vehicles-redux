local WEAPON = {}

AccessorFunc(WEAPON, "Cooldown", "Cooldown", FORCE_NUMBER)
AccessorFunc(WEAPON, "Overheat", "Overheat", FORCE_NUMBER)
AccessorFunc(WEAPON, "Delay", "Delay", FORCE_NUMBER)
AccessorFunc(WEAPON, "Index", "Index", FORCE_NUMBER)

AccessorFunc(WEAPON, "Ion", "Ion", FORCE_BOOL)

AccessorFunc(WEAPON, "Entity", "Entity")
AccessorFunc(WEAPON, "Target", "Target")
AccessorFunc(WEAPON, "Parent", "Parent")

AccessorFunc(WEAPON, "Group", "Group", FORCE_STRING)

function WEAPON:Initialize()
	local e = ents.Create("prop_physics")
	e:SetModel("models/props_junk/PopCan01a.mdl")
	e:SetPos(self:GetPos())
	e:SetRenderMode(RENDERMODE_TRANSALPHA)
	e:GetPhysicsObject():EnableCollisions(false)
	e:GetPhysicsObject():EnableMotion(false)
	e:SetSolid(SOLID_NONE)
	e:AddFlags(FL_DONTTOUCH)
	e:SetColor(Color(255, 255, 255, 0))
	e:DrawShadow(false)
	e:SetParent(self:GetParent() or self:GetEntity())
	e:Spawn()
	e:Activate()

	self.Entity = e
end

function WEAPON:Fire()

end

function WEAPON:Remove()
	SafeRemoveEntity(self.Entity)
end

local CANNON = {}
CANNON.Base = "swvr_base_weapon"
CANNON.Type = "cannon"
CANNON.Bullet = {}

AccessorFunc(CANNON, "Bullet", "Bullet")
AccessorFunc(CANNON.Bullet, "TracerName", "Tracer", FORCE_STRING)
AccessorFunc(CANNON.Bullet, "Damage", "Damage", FORCE_NUMBER)

function CANNON:Initialize()
	self.BaseClass.Initialize(self)

	self.Bullet = {
		Callback = function(attacker, tr, dmgInfo)
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
		end
	}
end

function CANNON:Fire()
	if not (IsValid(self.Parent) and IsValid(self.Entity)) then return end

	if not self.Group then
		print("Yikes")
	end

	local tr = util.TraceLine({
		start = self.Parent:GetPos(),
		endpos = self.Parent:GetPos() + self.Parent:GetForward() * 10000,
		filter = { self.Parent }
	})

	local dir = tr.HitPos - self.Entity:GetPos()

	if IsValid(self.Target) then
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
	bullet.Src = self.Entity:GetPos()
	bullet.Attacker = self.Parent:GetPilot() or self.Parent
	bullet.Spread = Vector(1, 1, 1) * (self.Parent.Accel.FWD / 1000)
	bullet.Dir = dir

	self.Entity:FireBullets(self.Bullet)
end

local MISSILE = {}
MISSILE.Base = "swvr_base_weapon"
MISSILE.Type = "missile"

function MISSILE:Initialize()
	self.BaseClass.Initialize(self)
end

function MISSILE:Fire()

end

local BaseClasses = {}
BaseClasses["weapon"] = "swvr_base_weapon"
BaseClasses["cannon"]  = "swvr_base_cannon"
BaseClasses["missile"] = "swvr_base_missile"

SWVR.Weapons = {
	["swvr_base_weapon"] = WEAPON
}

function SWVR:RegisterWeapon(weapon, name)
	local Base = weapon.Base
	if not Base then Base = BaseClasses[string.lower(weapon.Type)] end

	local old = self.Weapons[name]
	local tab = {}
	tab.type 		= weapon.Type
	tab.t 	 		= weapon
	tab.isBaseType  = true
	tab.Base 		= Base
	tab.t.ClassName = weapon.Name

	if not Base then
		error("Trying to register SWVR weapon without a valid base/type!")
	end

	self.Weapons[name] = tab

	if old ~= nil then
		for _, wep in ipairs(SWVR:GetWeapons()) do
			table.Merge(wep, tab.t)

			if wep.OnReloaded then
				wep:OnReloaded()
			end
		end
	end
end

SWVR:RegisterWeapon(CANNON, "swvr_base_cannon")
SWVR:RegisterWeapon(MISSILE, "swvr_base_missile")

function SWVR:Weapon(class)
	return table.Copy(self.Weapons[class])
end
