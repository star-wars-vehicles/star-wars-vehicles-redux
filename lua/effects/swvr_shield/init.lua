local matRefract = Material("models/spawn_effect")
local matLight = Material("models/spawn_effect2")

--[[---------------------------------------------------------
   Initializes the effect. The data is a table of data
   which was passed from the server.
---------------------------------------------------------]]
function EFFECT:Init(data)
  -- This is how long the spawn effect
  -- takes from start to finish.
  self.Time = 1.5
  self.LifeTime = CurTime() + self.Time

  local ent = data:GetEntity()

  if not IsValid(ent) then return end

  local mdl = ent:GetModel()

  if ent == NULL then return end
  if mdl == "" or mdl == "models/error.mdl" then return end

  self.ParentEntity = ent
  self:SetModel(mdl)
  self:SetPos(ent:LocalToWorld(Vector(0, 0, 0)))
  self:SetAngles(ent:GetAngles())
  self:SetRenderMode(RENDERMODE_TRANSALPHA)
  self:SetParent(ent)
  self:SetModelScale(ent:GetModelScale())
end

--[[---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------]]
function EFFECT:Think()
  if (not self.ParentEntity or not self.ParentEntity:IsValid()) then
    return false
  end

  return self.LifeTime > CurTime()
end

--[[---------------------------------------------------------
   Draw the effect
---------------------------------------------------------]]
function EFFECT:Render()
  -- What fraction towards finishing are we at
  local Fraction = (self.LifeTime - CurTime()) / self.Time
  local ColFrac = (Fraction - 0.5) * 2

  Fraction = math.Clamp(Fraction, 0, 1)
  ColFrac = math.Clamp(ColFrac, 0, 1)

  -- Change our model's alpha so the texture will fade out

  self:SetColor(Color(0, 160, 255, 1 + 150 * ColFrac))

  -- Place the camera a tiny bit closer to the entity.
  -- It will draw a big bigger and we will skip any z buffer problems
  local EyeNormal = self:GetPos() - EyePos()
  local Distance = EyeNormal:Length()
  EyeNormal:Normalize()

  local Pos = EyePos() + EyeNormal * Distance * 0
  local scale = Vector(1, 1, 1) --Vector( 1.01, 1.01, 1.05 )

  -- Start the new 3d camera position
  cam.Start3D(Pos, EyeAngles())

  -- Draw our model with the Light material
  -- This is the underlying blue effect and it doubles as the DX7 only effect
  if (ColFrac > 0) then
    --matLight:SetFloat( "$refractamount", Fraction * 0.1 )
    render.MaterialOverride(matLight)

    local mat = Matrix()
    mat:Scale(scale)

    self:EnableMatrix("RenderMultiply", mat)
    self:DrawModel()

    render.MaterialOverride(0)
  end

  -- If our card is DX8 or above draw the refraction effect
  if (render.GetDXLevel() >= 80) then
    -- Update the refraction texture with whatever is drawn right now
    render.UpdateRefractTexture()

    matRefract:SetFloat("$refractamount", Fraction * 0.01)

    -- Draw model with refraction texture
    render.MaterialOverride(matRefract)

    local mat = Matrix()
    mat:Scale(scale)

    self:EnableMatrix("RenderMultiply", mat)
    self:DrawModel()

    render.MaterialOverride(0)
  end

  -- Set the camera back to how it was
  cam.End3D()
end
