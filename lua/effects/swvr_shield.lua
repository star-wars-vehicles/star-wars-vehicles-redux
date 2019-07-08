local mat_refract = Material("models/spawn_effect")
local mat_light = Material("models/spawn_effect2")

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

  if mdl == "" or mdl == "models/error.mdl" then return end

  self:SetModel(mdl)
  self:SetPos(ent:GetPos())
  self:SetAngles(ent:GetAngles())
  self:SetRenderMode(RENDERMODE_TRANSALPHA)
  self:SetParent(ent)

  ent.Shields = ent.Shields or 0
  ent.Shields = ent.Shields + 1

  local RenderOverride = function(e)
    e:DrawModel()

    if not cvars.Bool("swvr_shields_draw") then return end

    -- What fraction towards finishing are we at
    local frac = (self.LifeTime - CurTime()) / self.Time
    local col_frac = (frac - 0.5) * 2

    frac = math.Clamp(frac, 0, 1)
    col_frac = math.Clamp(col_frac, 0, 1)

    -- Change our model's alpha so the texture will fade out
    local color = e:GetColor()
    local mode = e:GetRenderMode()
    e:SetRenderMode(RENDERMODE_TRANSALPHA)
    e:SetColor(ColorAlpha(color, 1 + 150 * col_frac))

    local col = e:GetNW2Vector("SWVR.ShieldColor")

    -- Draw our model with the Light material
    -- This is the underlying blue effect and it doubles as the DX7 only effect
    if col_frac > 0 then
      render.SetColorModulation(col.x / 255, col.y / 255, col.z / 255)
      render.MaterialOverride(mat_light)
        e:DrawModel()
      render.MaterialOverride(nil)
      render.SetColorModulation(1, 1, 1)
    end

    -- If our card is DX8 or above draw the refraction effect
    if render.GetDXLevel() >= 80 then
      -- Update the refraction texture with whatever is drawn right now
      render.UpdateRefractTexture()

      mat_refract:SetFloat("$refractamount", frac * 0.01)

      -- Draw model with refraction texture
      render.MaterialOverride(mat_refract)
        e:DrawModel()
      render.MaterialOverride(nil)
    end

    e:SetColor(color)
    e:SetRenderMode(mode)
  end

  ent.RenderOverride = RenderOverride
end

--[[---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------]]
function EFFECT:Think()
  if not IsValid(self:GetParent()) then
    return false
  end

  if self.LifeTime < CurTime() then
    if IsValid(self:GetParent()) then
      self:GetParent().Shields = self:GetParent().Shields - 1
      if self:GetParent().Shields == 0 then
        self:GetParent().RenderOverride = nil
      end
    end

    return false
  end

  return true
end

--[[---------------------------------------------------------
   Draw the effect
---------------------------------------------------------]]
function EFFECT:Render()

end
