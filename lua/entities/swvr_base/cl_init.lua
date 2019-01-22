--- Star Wars Vehicles Flight Base
-- @module Vehicle
-- @alias ENT
-- @author Doctor Jew

include("shared.lua")

function ENT:Initialize()
  self.FXEmitter = ParticleEmitter(self:GetPos(), false)

  self.Seats = {}

  self:AddEvent("OnEngineStart", function()
    self.SoundPatches = {}

    for name, path in pairs(self.Sounds) do
      self.SoundPatches[name] = CreateSound(self, path)
      self.SoundPatches[name]:PlayEx(0, 0)
    end
  end)

  self:AddEvent("OnEngineStop", function()
    for name, patch in pairs(self.SoundPatches or {}) do
      patch:Stop()
    end
  end)

  self:AddEvent("OnShieldDamage", function()
    self:EmitSound("swvr/shields/swvr_shield_absorb_" .. math.Round(math.random(1, 4)) .. ".wav", 500, 100,  cvars.Number("swvr_effect_volume", 100) / 100, CHAN_BODY)
  end)

  if istable(self.Engines) then
    local engines = {}
    for k, v in pairs(self.Engines) do
      if isvector(v) then
        engines[#engines + 1] = { Pos = v, Options = {} }
      elseif istable(v) then
        engines[#engines + 1] = { Pos = v.Pos, Options = v.Options or {} }
      end
    end

    self.Engines = engines
  end

  if istable(self.DamageVectors) then
    local dmg = {}
    for k, v in pairs(self.DamageVectors) do
      if isvector(v) then
        dmg[#dmg + 1] = { Pos = v, Callback = nil }
      elseif istable(v) then
        dmg[#dmg + 1] = v
      end
    end

    self.DamageVectors = dmg
  end

  self:OnInitialize()

  self.Initialized = true
end

--- Called every frame by the engine
-- @internal
function ENT:Think()
  self:UpdateSounds()

  self.NextAlarm = self.NextAlarm or 0

  if self.NextAlarm < CurTime() and self:Health() < self:GetMaxHealth() * 0.1 then
    self.NextAlarm = CurTime() + 0.5

    local vol = LocalPlayer():GetSWVehicle() == self and 1 or 0.25

    self:EmitSound("swvr/shared/swvr_alarm.wav", 75, 100, cvars.Number("swvr_effect_volume", 1) / 100 * vol)
  end

  self:OnThink()

  self:SetNextClientThink(CurTime())

  return true
end

function ENT:UpdateSounds()
  if not self:EngineActive() then return end

  local dist = (LocalPlayer():GetViewEntity():GetPos() - self:GetPos()):Length()

  self.PitchOffset = self.PitchOffset and self.PitchOffset + (math.Clamp((dist - self.LastDist) * FrameTime() * 150,-40,40) - self.PitchOffset) * FrameTime() * 5 or 0
  self.LastDist = dist

  local pitch = self:GetThrust() / self:GetBoostThrust()

  for name, patch in pairs(self.SoundPatches or {}) do
    patch:ChangePitch(math.Clamp(math.Clamp(60 + pitch * 50, 80, 255) - self.PitchOffset, 0, 255))
    patch:ChangeVolume(math.Clamp(-1 + pitch * 6, 0.5, 1) * (cvars.Number("swvr_engine_volume", 100) / 100))
  end
end

--- Called by the engine when removed
-- @internal
function ENT:OnRemove()
  for name, patch in pairs(self.SoundPatches or {}) do
    patch:Stop()
  end

  if IsValid(self.FXEmitter) then
    self.FXEmitter:Finish()
  end
end

function ENT:OnThink()

end

function ENT:AddDamagePosition(pos, cb)
  self.DamageVectors = self.DamageVectors or {}

  self.DamageVectors[#self.DamageVectors + 1] = { Pos = pos, Callback = cb }
end

function ENT:GetDamagePositions()
  return self.DamageVectors
end

function ENT:AddEngine(pos, options)
  self.Engines = self.Engines or {}

  self.Engines[#self.Engines + 1] = { Pos = pos, Options = options or {} }
end

function ENT:GetEngines()
  return self.Engines
end

--- Drawing Functions
-- @section drawing

--- Called every frame to draw the entity. Do not override unless experienced.
-- @client
function ENT:Draw()
  self:DrawModel()

  -- Damage Effects

  self:DrawDamageEffects()

  -- Engine Effects

  self:DrawExhaust()
  self:DrawGlow()
end

--- Draw the engine exhaust
-- @client
-- @internal
function ENT:DrawExhaust()
  if not self:EngineActive() then return end

  self.NextFX = self.NextFX or 0

  local pilot = self:GetPilot()
  if IsValid(pilot) then
    local throttle = pilot:ControlDown("forward")

    if throttle ~= self.oldThrottle then
      self.oldThrottle = throttle

      if throttle then
        self.BoostAdd = 80
      end
    end
  end

  self.BoostAdd = self.BoostAdd and (self.BoostAdd - self.BoostAdd * FrameTime()) or 0

  local color = self.Settings.Engine.Color

  if self.Settings.Engine.Type == 1 then
    for _, v in ipairs(self:GetEngines()) do
      if v.Options.Callback and v.Options.Callback(self) == false then continue end

      local normal = (self:GetForward() * -1):GetNormalized()
      local roll = math.Rand(-90, 90)
      local pos = self:LocalToWorld(v.Pos * self:GetModelScale())
      local sprite = self.FXEmitter:Add(self.Settings.Engine.Sprite, pos)

      sprite:SetVelocity(normal)
      sprite:SetDieTime(0.02)
      sprite:SetStartAlpha(color.a)
      sprite:SetEndAlpha(0)
      sprite:SetStartSize(25 * self:GetModelScale())
      sprite:SetEndSize(15 * self:GetModelScale())
      sprite:SetRoll(roll)
      sprite:SetColor(color.r, color.g, color.b)
    end
  else
    if self.NextFX < CurTime() then
      self.NextFX = CurTime() + 0.01

      if self.FXEmitter then
        for _, v in ipairs(self:GetEngines()) do
          if v.Options.Callback and v.Options.Callback(self) == false then continue end

          local vOffset = self:LocalToWorld(v.Pos * self:GetModelScale())
          local vNormal = -self:GetForward()

          vOffset = vOffset + vNormal * 5

          local particle = self.FXEmitter:Add(self.Settings.Engine.Sprite, vOffset)

          if not particle then return end

          particle:SetVelocity(vNormal * math.Rand(500, 1000) + self:GetVelocity())
          particle:SetLifeTime(0)
          particle:SetDieTime(0.1)
          particle:SetStartAlpha(255)
          particle:SetEndAlpha(0)
          particle:SetStartSize(math.Rand(15, 25))
          particle:SetEndSize(math.Rand(0, 10))
          particle:SetRoll(math.Rand(-1, 1) * 100)
          particle:SetColor(color.r, color.g, color.b)
        end
      end
    end
  end
end

--- Draw vehicle damage effects
-- @client
-- @internal
function ENT:DrawDamageEffects()
  local health = self:Health()

  if health ~= 0 and health < self:GetMaxHealth() * 0.5 then
    self.NextDFX = self.NextDFX or 0

    if self.NextDFX < CurTime() then
      self.NextDFX = CurTime() + 0.05

      local vectors = self:GetDamagePositions()

      if vectors then
        for _, v in ipairs(vectors) do
          if isfunction(v.Options.Callback) and v.Options.Callback(self) ~= false then
            local fx = EffectData()
            fx:SetOrigin(self:LocalToWorld(v.Pos * self:GetModelScale()))
            util.Effect("swvr_smoke", fx)
          end
        end

        return
      end

      local fx = EffectData()
      fx:SetOrigin(self:LocalToWorld(self.Controls.Thrust * self:GetModelScale()) - self:GetForward() * 50)
      util.Effect("swvr_smoke", fx)
    end
  end
end

local mat = Material("sprites/light_glow02_add")

--- Draw vehicle engine glow
-- @client
-- @internal
function ENT:DrawGlow()
  if not self:EngineActive() then return end
  if not self.Settings.Engine.Glow then return end

  local boost = self.BoostAdd or 0
  local size = 100 + (self:GetThrust() / self:GetBoostThrust()) * 40 + boost
  local color = self.Settings.Engine.Color

  render.SetMaterial(mat)

  for _, v in ipairs(self:GetEngines()) do
    if v.Options and v.Options.Callback and v.Options.Callback(self) == false then continue end

    render.DrawSprite(self:LocalToWorld(v.Pos * self:GetModelScale()), size, size, color)
  end
end

--- HUD Functions
-- @section hud

--- Draw the vehicle crosshair
-- @client
-- @bool isPilot If the local player is the pilot
function ENT:HUDDrawCrosshair(isPilot)
  local ply = LocalPlayer()

  local startpos =  self.Controls.Thrust

  local find_vehicle = util.TraceLine({
    start = startpos,
    endpos = startpos + self:GetForward() * 50000,
    filter = { self }
  })

  local find_pilot = util.TraceLine({
    start = startpos,
    endpos = startpos + ply:EyeAngles():Forward() * 50000,
    filter = function() return false end
  })

  local vehicle = find_vehicle.HitPos:ToScreen()
  local pilot = find_pilot.HitPos:ToScreen()

  local diff = Vector(pilot.x, pilot.y, 0) - Vector(vehicle.x, vehicle.y, 0)
  local len = diff:Length()
  local dir = diff:GetNormalized()

  surface.SetDrawColor(255, 255, 255, 100)

  if len > 34 and not ply:KeyDown(IN_WALK) then
    surface.DrawLine(vehicle.x + dir.x * 10, vehicle.y + dir.y * 10, pilot.x - dir.x * 34, pilot.y - dir.y * 34)
  end

  surface.DrawCircle(vehicle.x, vehicle.y, 10, Color(255, 255, 255, 100))

  surface.DrawLine(vehicle.x + 10, vehicle.y, vehicle.x + 20, vehicle.y)
  surface.DrawLine(vehicle.x - 10, vehicle.y, vehicle.x - 20, vehicle.y)
  surface.DrawLine(vehicle.x, vehicle.y + 10, vehicle.x, vehicle.y + 20)
  surface.DrawLine(vehicle.x, vehicle.y - 10, vehicle.x, vehicle.y - 20)

  surface.DrawCircle(pilot.x, pilot.y, 34, Color(255, 255, 255, 100))
end

function ENT:HUDDrawHull()
  surface.SetFont("SWVR_Health")
  local w, h = ScrW() / 100 * 20, ScrW() / 100 * 20 / 4
  local x, y = ScrW() - w - w / 8, ScrH() / 4 * 3.4
  local per = self:Health() / self:GetMaxHealth()
  local barW, barH = w * 0.90625, h * 0.4
  local barX, barY = x + w * 0.02832, y + h * 0.27343

  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/hull/hp_frame_under.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  if (self:Health() < self:GetMaxHealth() * 0.1) then
    surface.SetDrawColor(Color(255, 35, 35, 255))
  end

  surface.SetMaterial(Material("hud/hull/hp_bar.png", "noclamp"))
  surface.DrawTexturedRectUV(barX, barY, barW * (self:Health() / self:GetMaxHealth()), barH, 0, 0, per, 1)

  surface.SetMaterial(Material("hud/hull/hp_bar.png", "noclamp"))
  surface.SetDrawColor(Color(50, 120, 255, 255))
  surface.DrawTexturedRectUV(barX, barY, barW * self:GetShield() / self:GetMaxShield(), barH / 2, 0, 0, per, 1)

  surface.SetMaterial(Material("hud/hull/hp_frame_over.png", "noclamp"))
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  local health = math.Round(per * 100) .. "%"
  local tW, tH = surface.GetTextSize(health)

  surface.SetTextColor(Color(255, 255, 255, 255))

  x, y = x + w * 0.35 - tW / 2, y - tH / 2 + h * 0.06

  surface.SetTextPos(x, y + tH / 2)
  surface.DrawText(health)
end

function ENT:HUDDrawSpeedometer()
  local speed = self:GetThrust()
  local color = Color(255, 255, 255, 255)

  if (speed < 0) then
    color = Color(255, 50, 50)
    speed = speed * -1
  end

  local w, h = ScrW() / 100 * 20, ScrW() / 100 * 20 / 4
  local x, y = ScrW() - w - w / 8, ScrH() / 4 * 3.4 + h / 2 * 1.5
  local per = math.Clamp(speed / self:GetMaxThrust(), 0, 1)

  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/speedo/speed_frame_under.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  local barX, barY = x + w * 0.01953125, y + h * 0.234375
  local barW, barH = w * 0.9541015625, h * 0.53515625

  surface.SetDrawColor(color)
  surface.SetMaterial(Material("hud/speedo/speed_bar.png", "noclamp"))
  surface.DrawTexturedRectUV(barX, barY, barW * per, barH, 0, 0, per, 1)

  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/speedo/speed_frame_over.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
end

function ENT:HUDDrawCompass(fpvX, fpvY)
  local size = ScrW() / 10
  local x, y

  if (false and self:GetFirstPerson()) then
    x = fpvX or ScrW() / 2
    y = fpvY or ScrH() / 4 * 3.1
  else
    x = size * 0.65
    y = x
  end

  surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_BG"))
  surface.SetDrawColor(swvr.Config("hud.color", Color(255, 255, 255, 255)))
  surface.DrawTexturedRectRotated(x, y, size, size, 0)

  local rotate = (self:GetAngles().y - 90) * -1
  local al = swvr.GetSide(self)
  local maxDist = 5000

  for k, v in pairs(ents.FindInSphere(self:GetPos(), maxDist)) do
    if (IsValid(v) and (v.IsSWVRVehicle or v.IsSWVehicle) and v ~= self and al ~= swvr.GetSide(v)) then
      local dist = (self:GetPos() - v:GetPos()):Length() / maxDist
      local a = 1 - dist
      local r = ((self:GetPos() - v:GetPos()):Angle().y - 90) + rotate - 180

      surface.SetDrawColor(255, 255, 255, 255 * a)
      surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_locator")) -- Print the texture to the screen
      surface.DrawTexturedRectRotated(x, y, size, size, r)
    end
  end

  surface.SetDrawColor(swvr.Config("hud.color", Color(255, 255, 255, 255)))
  surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_disk"))
  surface.DrawTexturedRectRotated(x, y, size, size, rotate)
end

function ENT:HUDDrawReticle()
  local group = nil

  local tr
  if group and group.IsTracking then
    tr = util.TraceLine({
      start = LocalPlayer():EyePos(),
      endpos = LocalPlayer():EyePos() + LocalPlayer():GetAimVector():Angle():Forward() * 10000,
      filter = {self, LocalPlayer()}
    })
  else
    tr = util.TraceLine({
      start = self:GetPos(),
      endpos = self:GetPos() + self:GetForward() * 10000,
      filter = {self, LocalPlayer()}
    })
  end

  surface.SetTextColor(Color(255, 255, 255, 255))
  local vpos = tr.HitPos
  local material = "hud/reticle.png"
  surface.SetMaterial(Material(material, "noclamp"))

  if (group and group.CanLock) then
    local target = self:FindTarget()

    if IsValid(target) then
      local lock = target:GetPos() + target:GetUp() * (target:GetModelRadius() / 3)
      if (lock) then
        vpos = lock
        material = "hud/reticle_lock.png"
      end
    end
  end

  local screenpos = vpos:ToScreen()
  local x, y = screenpos.x, screenpos.y
  local w, h = ScrW() / 100 * 2, ScrW() / 100 * 2
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material(material, "noclamp"))
  surface.DrawTexturedRectUV(x - w / 2, y - h / 2, w, h, 0, 0, 1, 1)
end

function ENT:HUDDrawOverheating()
  local group = NULL

  if not (group and group.CanOverheat) then return end

  if group.Overheated then
    surface.SetDrawColor(Color(255, 0, 0, 255))
  else
    local ratio = group.Overheat / group.MaxOverheat

    if ratio >= 0 and ratio <= 0.4 then
      surface.SetDrawColor(Color(128, 255, 0, 255))
    elseif ratio > 0.4 and ratio <= 0.8 then
      surface.SetDrawColor(Color(255, 255, 0, 255))
    else
      surface.SetDrawColor(Color(255, 128, 0, 255))
    end
  end

  local w, h = ScrW() / 100 * 3.5, ScrH() / 100 * 0.5
  local tr

  if group.IsTracking then
    tr = util.TraceLine({
      start = LocalPlayer():EyePos(),
      endpos = LocalPlayer():EyePos() + LocalPlayer():GetAimVector():Angle():Forward() * 10000,
      filter = {self, LocalPlayer()}
    })
  else
    tr = util.TraceLine({
      start = self:GetPos(),
      endpos = self:GetPos() + self:GetForward() * 10000,
      filter = {self, LocalPlayer()}
    })
  end

  local vpos = tr.HitPos

  if (group and group.CanLock) then
    local target = self:FindTarget()

    if IsValid(target) then
      local lock = target:GetPos() + target:GetUp() * (target:GetModelRadius() / 3)
      if (lock) then
        vpos = lock
      end
    end
  end

  local screenpos = vpos:ToScreen()
  local x, y = screenpos.x, screenpos.y
  local o = group.Overheat / group.MaxOverheat * 100
  local per = o / 100
  w = w * per
  surface.DrawRect(x - w / 2, y + ScrW() / 100 * 1.5, w, h)
end

--- Draw the vehicle's altimeter.
-- @client
-- @number fpvX First person view X
-- @number fpvY First person view Y
function ENT:HUDDrawAltimeter(fpvX, fpvY)
  local p = LocalPlayer()
  local size = ScrW() / 10

  local x, y

  if false then -- self:GetFirstPerson()
    x = fpvX or ScrW() / 2
    y = fpvY or ScrH() / 4 * 3.1
  else
    x = size * 0.65
    y = x
  end

  -- Altimeter
  local max_ld = 20000
  local ld = 300

  -- if (self:GetLandHeight() > 0) then
  --   ld = self:GetLandHeight()
  -- end

  if (ld > 500) then
    max_ld = 1000
  elseif (ld > 1000) then
    max_ld = 1500
  end

  local tr = util.TraceLine({
    start = self:GetPos(),
    endpos = self:GetPos() + Vector(0, 0, -max_ld * 2),
    filter = {self}
  })

  local a = p.SW_Alt_Alpha or 255
  tMod = " m"

  if (tr.Hit and tr.HitWorld) then
    p.SW_Alt_Alpha = math.Clamp(a + 4, 130, 255)
  else
    tMod = tMod .. "+"
    p.SW_Alt_Alpha = math.Clamp(a - 4, 130, 255)
  end

  surface.SetTextColor(Color(255, 255, 255, a))
  surface.SetDrawColor(Color(255, 255, 255, a))
  --local dist = math.Clamp(math.Round(self:GetPos().z - tr.HitPos.z), 0, max_ld * 2)
  local dist = math.Round((self:GetPos().z - tr.HitPos.z) / 59.49)
  local t = dist
  local w = size
  local h = size / 2
  x = x - w / 2
  y = y + size / 2 * 1.1

  surface.SetFont("SWVR_Altimeter")
  surface.SetMaterial(Material("hud/altimeter/altimeter_frame.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
  surface.SetTextPos(x + w * 0.45, y + h * 0.125)

  if (not self:EngineActive()) then
    t = "N/A"
    surface.DrawText(t)
  else
    surface.DrawText(t .. tMod)
  end

  if (dist <= ld) then
    surface.SetMaterial(Material("hud/altimeter/altimeter_light1.png", "noclamp"))
    surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

    if (not self:EngineActive()) then
      surface.SetMaterial(Material("hud/altimeter/altimeter_light2.png", "noclamp"))
      surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
    end
  end
end

function ENT:HUDDrawTransponder()
  local size = ScrW() / 10
  local w, h = size, size / 3.08
  local x, y = ScrW() - w / 2 - size * 0.65, ScrW() / 100
  local transponder = self:GetTransponder()

  surface.SetMaterial(Material("hud/clearance_code.png", "noclamp"))
  surface.SetFont("SWVR_Transponder")
  surface.SetDrawColor(255, 255, 255, 255)
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  surface.SetTextPos(x + w * 0.32, y + h * 0.45)
  surface.DrawText(transponder)
end

local MIN_ALT = 0

function ENT:HUDDrawDebug()
  local x = ScrW() / 2

  local throttle = math.max(math.Round((self:GetThrust() - 1) / (self:GetBoostThrust() - 1) * 100, 0), 0)
  draw.SimpleText("Throttle\t\t" .. throttle .. "%", "SWVR_Debug", x, 10, throttle <= 100 and Color(255, 255, 255) or Color(255, 0 ,0), TEXT_ALIGN_CENTER)

  local vel = math.Round(self:GetVelocity():Length() * 0.09144, 0)
  draw.SimpleText("Velocity\t\t" .. vel .. "km/h", "SWVR_Debug", x, 35, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  local alt = math.Round(self:GetPos().z, 0)

  if alt + MIN_ALT < 0 then MIN_ALT = math.abs(alt) end

  draw.SimpleText("Altitude\t\t" .. math.Round((self:GetPos().z + MIN_ALT) * 0.0254, 0) .. "m", "SWVR_Debug", x, 60, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  draw.SimpleText("Thrust\t\t" .. math.Round(self:GetThrust(), 0), "SWVR_Debug", x, 85, Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

-- VIEW FUNCTIONS

function ENT:CalcView(ply, pos, ang, fov)
  local seat = ply:GetVehicle()

  ply.SW_ViewOffset = ply.SW_ViewOffset or 0

  ply.SW_ViewOffset = ply.SW_ViewOffset + ((ply:KeyDown(IN_WALK) and 0 or 0.8) - ply.SW_ViewOffset) * RealFrameTime() * 10

  local view = {}
  view.origin = pos
  view.fov = fov
  view.drawviewer = true
  view.angles = ((self:GetForward() * ply.SW_ViewOffset + ply:EyeAngles():Forward()) * 0.5):Angle()

  view.angles.r = 0

  if self:GetSeat(1) ~= seat then
    view.angles = ply:EyeAngles()
  end

  if not seat:GetThirdPersonMode() then
    view.drawviewer = false

    return self:CalcFirstPersonView(view, ply)
  end

  local radius = 550
  radius = radius + radius * seat:GetCameraDistance()

  local target = view.origin - view.angles:Forward() * radius + view.angles:Up() * radius * 0.2
  local offset = 4

  local tr = util.TraceHull({
    start = view.origin,
    endpos = target,
    filter = function(e)
      local cls = e:GetClass()

      return not (cls:StartWith("prop_physics") or cls:StartWith("prop_dynamic") or cls:StartWith("prop_ragdoll") or e:IsVehicle() or cls:StartWith("gmod_") or cls:StartWith("player") or e.IsSWVRVehicle)
    end,
    mins = Vector(-offset, -offset, -offset),
    maxs = Vector(offset, offset, offset)
  })

  view.origin = tr.HitPos

  if tr.Hit and not tr.StartSolid then
    view.origin = view.origin + tr.HitNormal * offset
  end

  return self:CalcThirdPersonView(view, ply)
end

--- View functions
-- @section view

--- Override first person view calculations
-- @client
-- @tparam table view The view information
function ENT:CalcFirstPersonView(view, ply)
  return view
end

--- Override third person view calculations
-- @client
-- @tparam table view The view information
function ENT:CalcThirdPersonView(view, ply)
  return view
end

hook.Add("CalcView", "SW_CalcView", function(ply, pos, ang, fov)
  if ply:GetViewEntity() ~= ply then return end

  local seat = ply:GetVehicle()

  if not IsValid(seat) then return end

  local vehicle = seat:GetParent()

  if not (IsValid(vehicle) and vehicle.IsSWVRVehicle) then return end

  return vehicle:CalcView(ply, pos, ang, fov)
end)

hook.Add( "HUDPaint", "SWVR.HUDPaint", function()
  local ply = LocalPlayer()

  if ply:GetViewEntity() ~= ply then return end

  local seat = ply:GetVehicle()

  if not IsValid(seat) then return end

  local parent = seat:GetParent()

  if not parent.IsSWVRVehicle then return end

  if cvars.Bool("swvr_debug_statistics") then
    parent:HUDDrawDebug()
  end

  if hook.Run("SWVR.HUDPaint", parent) == false then return end

  if hook.Run("SWVR.HUDShouldDraw", "Reticle") ~= false then
    parent:HUDDrawReticle()
  end


  if hook.Run("SWVR.HUDShouldDraw", "Hull") ~= false then
    parent:HUDDrawHull()
  end

  if hook.Run("SWVR.HUDShouldDraw", "Speedometer") ~= false then
    parent:HUDDrawSpeedometer()
  end

  if hook.Run("SWVR.HUDShouldDraw", "Altimeter") ~= false then
    parent:HUDDrawAltimeter()
  end

  parent:HUDDrawCompass()
  parent:HUDDrawTransponder()
end)

hook.Add("PostDrawTranslucentRenderables", "SWVR.DebugVisuals", function()
  if not cvars.Bool("swvr_debug_visuals") then return end

  render.SetColorMaterial()

  for _, ent in ipairs(ents.GetAll()) do
    if not IsValid(ent) or not ent.IsSWVRVehicle then continue end
    -- The position to render the sphere at, in this case, the looking position of the local player

    local controls = ent.Controls

    cam.IgnoreZ(true)

    -- Draw the spheres!
    render.DrawSphere(ent:LocalToWorld(controls.Thrust * ent:GetModelScale()), 15, 20, 20, Color(0, 175, 175, 100))
    render.DrawSphere(ent:LocalToWorld(controls.Wings * ent:GetModelScale()), 15, 20, 20, Color(175, 175, 0, 100))
    render.DrawSphere(ent:LocalToWorld(controls.Elevator * ent:GetModelScale()), 15, 20, 20, Color(175, 0, 175, 100))
    render.DrawSphere(ent:LocalToWorld(controls.Rudder * ent:GetModelScale()), 15, 20, 20, Color(0, 175, 0, 100))
  end
end)
