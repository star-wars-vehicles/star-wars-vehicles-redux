function EFFECT:Init(data)
  local pos = data:GetOrigin()

  local emitter = ParticleEmitter(pos, false)

  if emitter then
    local index = math.random(1, 16)
    local particle = emitter:Add("particle/smokesprites_00" .. (#tostring(index) == 1 and "0" or "") .. index, pos)

    if particle then
      particle:SetVelocity(VectorRand() * 100)
      particle:SetDieTime(1.5)
      particle:SetAirResistance(600) 
      particle:SetStartAlpha(150)
      particle:SetStartSize(30)
      particle:SetEndSize(math.Rand(150,200))
      particle:SetRoll(math.Rand(-1,1) * 100)
      particle:SetColor(40,40,40)
      particle:SetGravity(Vector( 0, 0, 500 ))
      particle:SetCollide(false)
    end

    emitter:Finish()
  end
end

function EFFECT:Think()
  return false
end

function EFFECT:Render()
end
