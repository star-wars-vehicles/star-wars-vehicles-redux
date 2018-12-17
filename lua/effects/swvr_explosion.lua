function EFFECT:Init(data)
  local pos = data:GetOrigin()

  self.DieTime = CurTime() + 1

  self:Explosion( pos, 2 )

  sound.Play("phx/explode0" .. math.random(0, 6), pos, 95, 140, 1)

  for i = 1, 20 do
    timer.Simple(math.Rand(0, 0.01) * i, function()
      if not IsValid(self) then return end

      local p = pos + VectorRand() * 10 * i

      self:Explosion(p, math.Rand(0.5, 0.8))
    end)
  end

  self:Debris(pos)
end

function EFFECT:Debris(pos)
  local emitter = ParticleEmitter(pos, false)

  for i = 0,60 do
    local particle = emitter:Add("effects/fleck_tile" .. math.random(1, 2), pos)
    local vel = VectorRand() * math.Rand(200,600)
    vel.z = math.Rand(200,600)
    if particle then
      particle:SetVelocity(vel)
      particle:SetDieTime(math.Rand(10, 15))
      particle:SetAirResistance(10)
      particle:SetStartAlpha(255)
      particle:SetStartSize(5)
      particle:SetEndSize(5)
      particle:SetRoll(math.Rand(-1,1))
      particle:SetColor(0,0,0)
      particle:SetGravity(Vector(0, 0, -600))
      particle:SetCollide(true)
      particle:SetBounce(0.3)
    end
  end

  emitter:Finish()
end

function EFFECT:Explosion(pos , scale)
  local emitter = ParticleEmitter(pos, false)

  if emitter then
    for i = 0,10 do
      local index = math.random(1, 16)
      local particle = emitter:Add("particle/smokesprites_00" .. (#tostring(index) == 1 and "0" or "") .. index, pos)

      if particle then
        particle:SetVelocity(VectorRand() * 1000 * scale)
        particle:SetDieTime(math.Rand(0.75,1.5) * scale)
        particle:SetAirResistance(math.Rand(200,600))
        particle:SetStartAlpha(255)
        particle:SetStartSize(math.Rand(60,120) * scale)
        particle:SetEndSize(math.Rand(160,280) * scale)
        particle:SetRoll(math.Rand(-1,1))
        particle:SetColor(40,40,40)
        particle:SetGravity(Vector(0, 0, 100))
        particle:SetCollide(false)
      end
    end

    for i = 0, 40 do
      local particle = emitter:Add("particles/flamelet" .. math.random(1, 5), pos)

      if particle then
        particle:SetVelocity(VectorRand() * 1000 * scale)
        particle:SetDieTime(0.14)
        particle:SetStartAlpha(255)
        particle:SetStartSize(10 * scale)
        particle:SetEndSize(math.Rand(60,120) * scale)
        particle:SetEndAlpha(100)
        particle:SetRoll(math.Rand(-1, 1))
        particle:SetColor(200,150,150)
        particle:SetCollide(false)
      end
    end

    emitter:Finish()
  end

  local dlight = DynamicLight(math.random(0, 9999))
  if dlight then
    dlight.pos = pos
    dlight.r = 255
    dlight.g = 180
    dlight.b = 100
    dlight.brightness = 8
    dlight.Decay = 2000
    dlight.Size = 300
    dlight.DieTime = CurTime() + 1
  end
end

function EFFECT:Think()
  if CurTime() < self.DieTime then return true end

  return false
end

function EFFECT:Render()
end
