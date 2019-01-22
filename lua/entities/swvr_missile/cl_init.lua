function ENT:Initialize()
  self.Emitter = ParticleEmitter(self:GetPos(), false)
  self.Materials = {
    "particle/smokesprites_0001", "particle/smokesprites_0002", "particle/smokesprites_0003",
    "particle/smokesprites_0004", "particle/smokesprites_0005", "particle/smokesprites_0006",
    "particle/smokesprites_0007", "particle/smokesprites_0008", "particle/smokesprites_0009",
    "particle/smokesprites_0010", "particle/smokesprites_0011", "particle/smokesprites_0012",
    "particle/smokesprites_0013", "particle/smokesprites_0014", "particle/smokesprites_0015",
    "particle/smokesprites_0016"
  }

  self.NextFX = 0

  self.Sound = CreateSound(self, "weapons/flaregun/burn.wav")
  self.Sound:Play()
end

local mat = Material("sprites/light_glow02_add")

function ENT:Draw()
  self:DrawModel()

  if self.Disabled then return end

  local pos = self:GetPos()
  local color = Color(255, 100, 0)

  render.SetMaterial(mat)

  if self:GetCleanMissile() then
    color = Color(0, 127, 255)

    for i = 0, 10 do
      local size = (10 - i) * 25.6
      render.DrawSprite(pos - self:GetForward() * i * 5, size, size, color)
    end
  end

  render.DrawSprite(pos, 256, 256, color)
end

function ENT:Think()
  if self.NextFX > CurTime() then return true end

  self.NextFX = CurTime() + 0.02

  local pos = self:LocalToWorld(Vector(-8, 0, 0))

  if self:GetDisabled() then
    if not self.Disabled then
      self.Disabled = true

      if self.Sound then
        self.Sound:Stop()
      end
    end

    self:doFXbroken(pos)

    return
  end

  self:doFX(pos)

  return true
end

function ENT:doFXbroken(pos)
  if not IsValid(self.Emitter) then return end

  do
    local particle = self.Emitter:Add(self.Materials[math.random(1, table.Count(self.Materials))], pos)

    if particle then
      particle:SetGravity(Vector(0, 0, 100) + VectorRand() * 50)
      particle:SetVelocity(-self:GetForward() * 500)
      particle:SetAirResistance(600)
      particle:SetDieTime(math.Rand(4, 6))
      particle:SetStartAlpha(150)
      particle:SetStartSize(math.Rand(6, 12))
      particle:SetEndSize(math.Rand(40, 90))
      particle:SetRoll(math.Rand(-1, 1))
      particle:SetColor(50, 50, 50)
      particle:SetCollide(false)
    end
  end

  do
    local particle = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self:GetPos())

    if particle then
      particle:SetVelocity(-self:GetForward() * 500 + VectorRand() * 50)
      particle:SetDieTime(0.25)
      particle:SetAirResistance(600)
      particle:SetStartAlpha(255)
      particle:SetStartSize(math.Rand(25, 40))
      particle:SetEndSize(math.Rand(10, 15))
      particle:SetRoll(math.Rand(-1, 1))
      particle:SetColor(255, 255, 255)
      particle:SetGravity(Vector(0, 0, 0))
      particle:SetCollide(false)
    end
  end
end

function ENT:doFX(pos)
  if not IsValid(self.Emitter) then return end

  if not self:GetCleanMissile() then
    local particle = self.Emitter:Add(self.Materials[math.random(1, table.Count(self.Materials))], pos)

    if particle then
      particle:SetGravity(Vector(0, 0, 100) + VectorRand() * 50)
      particle:SetVelocity(-self:GetForward() * 500)
      particle:SetAirResistance(600)
      particle:SetDieTime(math.Rand(4, 6))
      particle:SetStartAlpha(150)
      particle:SetStartSize(math.Rand(6, 12))
      particle:SetEndSize(math.Rand(40, 90))
      particle:SetRoll(math.Rand(-1, 1))
      particle:SetColor(50, 50, 50)
      particle:SetCollide(false)
    end
  end

  local particle = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), pos)

  if particle then
    particle:SetVelocity(-self:GetForward() * 300 + self:GetVelocity())
    particle:SetDieTime(0.1)
    particle:SetAirResistance(0)
    particle:SetStartAlpha(255)
    particle:SetStartSize(4)
    particle:SetEndSize(0)
    particle:SetRoll(math.Rand(-1, 1))
    particle:SetColor(255, 255, 255)
    particle:SetGravity(Vector(0, 0, 0))
    particle:SetCollide(false)
  end
end

function ENT:OnRemove()
  if IsValid(self.Sound) then
    self.Sound:Stop()
  end

  self:Explosion(self:GetPos() + self:GetVelocity() / 20)

  sound.Play("Explo.ww2bomb", self:GetPos(), 95, 140, 1)

  if IsValid(self.Emitter) then
    self.Emitter:Finish()
  end
end

function ENT:Explosion(pos)
  if not IsValid(self.Emitter) then return end

  for i = 0, 60 do
    local particle = self.Emitter:Add(self.Materials[math.random(1, table.Count(self.Materials))], pos)

    if not particle then continue end

    particle:SetVelocity(VectorRand(-1, 1) * 600)
    particle:SetDieTime(math.Rand(4, 6))
    particle:SetAirResistance(math.Rand(200, 600))
    particle:SetStartAlpha(255)
    particle:SetStartSize(math.Rand(10, 30))
    particle:SetEndSize(math.Rand(80, 120))
    particle:SetRoll(math.Rand(-1, 1))
    particle:SetColor(50, 50, 50)
    particle:SetGravity(Vector(0, 0, 100))
    particle:SetCollide(false)
  end

  for i = 0, 40 do
    local particle = self.Emitter:Add("sprites/flamelet" .. math.random(1, 5), pos)

    if not particle then continue end

    particle:SetVelocity(VectorRand(-1, 1) * 500)
    particle:SetDieTime(0.14)
    particle:SetStartAlpha(255)
    particle:SetStartSize(10)
    particle:SetEndSize(math.Rand(30, 60))
    particle:SetEndAlpha(100)
    particle:SetRoll(math.Rand(-1, 1))
    particle:SetColor(200, 150, 150)
    particle:SetCollide(false)
  end

  local dlight = DynamicLight(math.random(0, 9999))

  if dlight then
    dlight.pos = pos
    dlight.r = 255
    dlight.g = 180
    dlight.b = 100
    dlight.brightness = 8
    dlight.Decay = 2000
    dlight.Size = 200
    dlight.DieTime = CurTime() + 0.1
  end
end
