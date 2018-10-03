ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Proton Torpedo"
ENT.Author = "Doctor Jew"
ENT.Category = "Star Wars"

ENT.IsTorpedo = true

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel("models/tri/missile.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:StartMotionController()
		self:SetUseType(SIMPLE_USE)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetColor(Color(255, 255, 255, 255))

		self.Damage = self.Damage or 1000
		self.Lifetime = self.Lifetime and CurTime() + self.Lifetime or -1

		local phys = self:GetPhysicsObject()
		phys:SetMass(50)
		phys:EnableGravity(false)
		phys:Wake()

		util.SpriteTrail(self, 0, Color(28, 102, 221), false, 15, 1, 4, 1 / ( 15 + 1 ) * 0.5, "trails/plasma.vmt" )
	end

	function ENT:Prepare(parent, options)
		options = options or {}
		local color = options.Color and Vector(options.Color.r / 255, options.Color.g / 255, options.Color.b / 255) or Vector(1, 1, 1)

		self:SetNWVector("Color", color)
		self:SetNWFloat("StartSize", options.StartSize or 20)
		self:SetNWFloat("EndSize", options.EndSize or 5)
		self:SetNWBool("IsWhite", tobool(options.White))

		self.Damage = options.Damage or 1000
		self.Lifetime = options.Lifetime or nil
		self.Target = options.Target or NULL
		self.Velocity = math.Clamp(options.Velocity or 500, 500, 2000)
		self.Shooter = parent
	end

	function ENT:Think()
		if not self.Targetting then return end

		if (self.Lifetime ~= -1 and self.Lifetime < CurTime()) then
			self:Bang()
		end

		if not IsValid(self.Target) then
			self.Targetting = false
		else
			self:SetAngles((self.Target:GetPos() - self:GetPos()):Angle())
		end
	end

	local FlightPhys = {
		secondstoarrive	= 1,
		maxangular		= 50000,
		maxangulardamp	= 10000000,
		maxspeed			= 100000000,
		maxspeeddamp		= 10,
		dampfactor		= 0.1,
		teleportdistance	= 5000
	}

	function ENT:PhysicsSimulate(phys, deltatime)
		local ang = self.Ang or self:GetForward():Angle()

		if (self.Targetting) then
			if (IsValid(self.Target)) then
				ang = (self.Target:GetPos() - self:GetPos()):Angle()
			else
				self.Targetting = false
			end
		end

		FlightPhys.angle = ang
		FlightPhys.pos = self:GetPos() + self:GetForward() * self.Velocity
		FlightPhys.deltatime = deltatime

		phys:ComputeShadowControl(FlightPhys)
	end

	function ENT:Bang()
		local pos = self:GetPos()
		local fx = EffectData()
		fx:SetOrigin(pos)

		util.Effect("HelicopterMegaBomb", fx, true, true)

		self:EmitSound("swvr/weapons/swvr_proton_torpedo.wav", 511, 100, 1)

		SafeRemoveEntityDelayed(self, 0.01)
	end

	function ENT:PhysicsCollide(colData, collider)
		if IsValid(self.Shooter) and colData.HitEntity == self.Shooter then return end



		local e = colData.HitEntity
		if (IsValid(e) and e.IsSWVRVehicle) then
			if (self.Ion) then
				e:SetIon(e:GetIon() + 10)
			end

			e:TakeDamage(self.Damage)
		end

		self:Bang()
	end
end

if CLIENT then
	function ENT:Initialize()
		self.FXEmitter = ParticleEmitter(self:GetPos())
	end

	function ENT:Think()
		self:Draw()
	end

	function ENT:OnRemove()
		self.FXEmitter:Finish()
	end

	function ENT:Draw()
		self:DrawModel()

		if self.FXEmitter:GetNumActiveParticles() > 300 then return end

		local isWhite = self:GetNWBool("IsWhite")
		local sprite = isWhite and "sprites/white_blast" or "sprites/bluecore"

		local fx = self.FXEmitter:Add(sprite, self:GetPos())
		if not fx then print("LIGMA") return end
		fx:SetVelocity((self:GetForward() * -1):GetNormalized())
		fx:SetDieTime(0.2)
		fx:SetStartAlpha(255)
		fx:SetEndAlpha(255)

		fx:SetStartSize(20)
		fx:SetEndSize(15)
		fx:SetRoll(90)
		fx:SetColor(Color(255, 255, 255))

		-- fx:SetStartSize(self:GetNWFloat("StartSize"))
		-- fx:SetEndSize(self:GetNWFloat("EndSize"))
		-- fx:SetRoll(math.Rand(-90, 90))
		-- fx:SetColor(self:GetNWVector("Color"):ToColor())
	end
end
