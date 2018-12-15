--DO NOT EDIT OR REUPLOAD THIS FILE

EFFECT.Mat = Material("effects/sw_laser_red_main") -- Material( "effects/spark" )
EFFECT.Mat2 = Material("effects/sw_laser_red_front") -- Material( "sprites/light_glow02_add" )

function EFFECT:Init( data )

	self.StartPos = data:GetStart()
	self.EndPos = data:GetOrigin()

	self.Dir = self.EndPos - self.StartPos

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	self.TracerTime = math.min( 1, self.StartPos:Distance( self.EndPos ) / 15000 )
	self.Length = math.Rand( 0.1, 0.15 )

	-- Die when it reaches its target
	self.DieTime = CurTime() + self.TracerTime
end

function EFFECT:Think()

	if CurTime() > self.DieTime then
		return false
	end

	return true

end

function EFFECT:Render()

	local fDelta = ( self.DieTime - CurTime() ) / self.TracerTime
	fDelta = math.Clamp( fDelta, 0, 1 ) ^ 1

	local sinWave = math.sin( fDelta * math.pi )

	local start_pos = self.EndPos - self.Dir * ( fDelta - sinWave * self.Length )
	local end_pos = self.EndPos - self.Dir * ( fDelta + sinWave * self.Length )

	render.SetMaterial( self.Mat )
	render.DrawBeam( start_pos, end_pos, 15, 1, 0, Color(255,220,220,255) )

	render.SetMaterial( self.Mat2 )
	render.DrawSprite( start_pos, 30, 30, Color(255,220,220,255) )
end
