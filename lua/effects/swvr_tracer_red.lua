EFFECT.Speed          = 6500
EFFECT.Length         = 64
--EFFECT.WhizSound			 = Sound( "nomad/whiz.wav" )
EFFECT.WhizDistance   = 72

TRACER_FLAG_USEATTACHMENT = 0x0002
SOUND_FROM_WORLD          = 0
CHAN_STATIC               = 6

local MaterialMain  = Material("effects/sw_laser_red_main")
local MaterialFront = Material("effects/sw_laser_red_front")

function EFFECT:GetTracerOrigin(data)
	local start = data:GetStart()

	if (bit.band(data:GetFlags(), TRACER_FLAG_USEATTACHMENT) == TRACER_FLAG_USEATTACHMENT) then
		local entity = data:GetEntity()
		if (not IsValid(entity)) then return start end
		if (not game.SinglePlayer() and entity:IsEFlagSet(EFL_DORMANT)) then return start end

		if (entity:IsWeapon() and entity:IsCarriedByLocalPlayer()) then
			local pl = entity:GetOwner()

			if (IsValid(pl)) then
				local vm = pl:GetViewModel()

				if (IsValid(vm) and not LocalPlayer():ShouldDrawLocalPlayer()) then
					entity = vm
				else
					-- HACK: fix the model in multiplayer
					if (entity.WorldModel) then
						entity:SetModel(entity.WorldModel)
					end
				end
			end
		end

		local attachment = entity:GetAttachment(data:GetAttachment())

		if (attachment) then
			start = attachment.Pos
		end
	end

	return start
end

function EFFECT:Init(data)
	self.StartPos  = self:GetTracerOrigin(data)
	self.EndPos    = data:GetOrigin()

	self.Entity:SetRenderBoundsWS(self.StartPos, self.EndPos)

	local diff     = (self.EndPos - self.StartPos)
	self.Normal    = diff:GetNormal()
	self.StartTime = 0
	self.LifeTime  = (diff:Length() + self.Length) / self.Speed
end

function EFFECT:Think()
	self.LifeTime = self.LifeTime - FrameTime()
	self.StartTime = self.StartTime + FrameTime()

	return self.LifeTime > 0
end

function EFFECT:Render()
	local endDistance   = self.Speed * self.StartTime
	local startDistance = endDistance - self.Length
	startDistance       = math.max(0, startDistance)
	endDistance         = math.max(0, endDistance)
	local startPos      = self.StartPos + self.Normal * startDistance
	local endPos        = self.StartPos + self.Normal * (endDistance * 1.2)

	render.SetMaterial(MaterialFront)
	render.DrawSprite(endPos, 32, 24, color_white)
	render.SetMaterial(MaterialMain)
	render.DrawBeam(startPos, endPos, 20, 0, 1, color_white)
end
