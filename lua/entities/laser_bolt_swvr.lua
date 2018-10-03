ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.PrintName = "Laser Bolt"
ENT.Author = "Syntax Error, TFA, Nopeful, Doctor Jew"

ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.DoEffect = true
ENT.Delay = 10
ENT.Radius = 3

local TRACERS = {
	["RED"] = { Color(255, 0, 0) }, ["WHITE"] = { Color(255, 255, 255) }, ["YELLOW"] = { Color(246, 249, 47) },
	["PURPLE"] = { Color(176, 69, 247) }, ["GREEN"] = { Color(61, 204, 48) }, ["BLUE"] = { Color(39, 158, 232) }
}

for col, tbl in pairs(TRACERS) do
	tbl[2] = Material("effects/sw_laser_" .. string.lower(col) .. "_main")
	tbl[3] = Material("effects/sw_laser_" .. string.lower(col) .. "_front")
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		local mdl = self:GetModel()

		if mdl == "" or mdl == "models/error.mdl" then
			self:SetModel("models/weapons/w_eq_fraggrenade.mdl")
		end

		self:DrawShadow(false)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:PhysicsInitSphere(self.Radius, "default_silent")

		local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:Wake()
			phys:EnableDrag(false)
			phys:EnableGravity(false)
			phys:SetMass(1)
		end

		self.FlightVector        = self:GetForward() * 10
		self.Damage              = self.Damage
		self.ExplosiveProjectile = self.ExplosiveProjectile
		self.DieTime             = CurTime() + self.Delay

		self.LightEffect = ents.Create("light_dynamic")
		self.LightEffect:SetPos( self:GetPos() )
		self.LightEffect:SetOwner( self )
		self.LightEffect:SetParent(self)
		self.LightEffect:SetKeyValue( "_light", tostring(ColorAlpha(TRACERS[self:GetNWString("Color")][1], 255)) )
		self.LightEffect:SetKeyValue("distance", "96" )
		self.LightEffect:SetKeyValue( "brightness", "4" )
		self.LightEffect:Spawn()
	end

	function ENT:SetDamage(dmg)
		self.Damage = dmg
	end

	function ENT:SetTracer(color)
		if not TRACERS[string.upper(color)] then return end

		self:SetNWString("Color", string.upper(color))
	end

	function ENT:Think()
		self.FlightVector = self:GetForward() * 10

		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + self.FlightVector
		trace.filter = self

		local tr = util.TraceLine( trace )
		if tr.HitSky then
			self.DoEffect = false
		else
			self.DoEffect = true
		end

		if CurTime() > self.DieTime then return false end

		self:NextThink(CurTime())

		return true
	end

	function ENT:PhysicsCollide(colData, collider)
		SafeRemoveEntityDelayed(self, 0)

		if self.DoEffect then
			util.Decal( "fadingscorch", colData.HitPos + colData.HitNormal, colData.HitPos - colData.HitNormal )
		end

		if ( game.SinglePlayer() or SERVER or not self:IsCarriedByLocalPlayer() or IsFirstTimePredicted() ) then

			local choice = math.random(1, 24)
			local soundToPlay = "effects/sw_impact/sw752_hit_" .. (#tostring(choice) > 1 and choice or "0" .. choice)  .. ".wav"

			local impact = EffectData()
			impact:SetOrigin( colData.HitPos )
			impact:SetNormal( colData.HitNormal )

			util.Effect( "effect_sw_impact_2", impact )
			sound.Play( soundToPlay, colData.HitPos, 75, 100, 1 )

			local trace = {}
			trace.start = self:GetPos()
				trace.endpos = self:GetPos() --+ self.FlightVector
				trace.filter = self

				local tr = util.TraceLine( trace )

				local effect = EffectData()
				effect:SetOrigin( tr.HitPos )
				effect:SetStart( tr.StartPos )
				effect:SetDamageType( DMG_BULLET )

				util.Effect( "RagdollImpact", effect )
			end


		local ow = self:GetOwner()

		if not IsValid(ow) then return end

		if self.ExplosiveProjectile then
			local explo = ents.Create( "env_explosion" )
			explo:SetOwner( ow )
			explo:SetPos( colData.HitPos )
			explo:SetKeyValue( "iMagnitude", 1 )
			explo:SetKeyValue( "iRadiusOverride", 1 )
			explo:Spawn()
			explo:Activate()
			explo:Fire( "Explode", "", 0 )
		else
			local d = DamageInfo()
			d:SetAttacker(ow)
			d:SetInflictor((ow.GetActiveWeapon and IsValid( ow:GetActiveWeapon() )) and ow:GetActiveWeapon() or ow )
			d:SetDamage(self.Damage)

			colData.Normal = colData.OurOldVelocity
			colData.Normal:Normalize()

			d:SetDamageForce( colData.Normal * self.Damage * 100)
			d:SetDamageType(DMG_BULLET)
			d:SetDamagePosition( colData.HitPos )

			if IsValid(colData.HitEntity) then
				colData.HitEntity:DispatchTraceAttack(d, util.QuickTrace(colData.HitPos, -colData.HitNormal * 32, self), colData.Normal)
			end
		end
	end
end

if CLIENT then
	function ENT:DrawTranslucent()
		local vector = self:GetVelocity() * 0.009846153

		local tracer = self:GetNWString("Color", "NONE")

		if tracer == "NONE" then return end

		render.SetMaterial( TRACERS[tracer][3] )
		render.DrawSprite( self:GetPos() - vector, 52, 24, self:GetColor() )

		render.SetMaterial( TRACERS[tracer][2] )
		render.DrawBeam( self:GetPos(), self:GetPos() - vector, 30, 0, 1, self:GetColor() )
	end
end
