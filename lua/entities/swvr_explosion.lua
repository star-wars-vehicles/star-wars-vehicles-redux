AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "SWVR Explosion"
ENT.Author = "Doctor Jew"

local DefaultGibs = {
  "models/XQM/wingpiece2.mdl",
  "models/XQM/wingpiece2.mdl",
  "models/XQM/jetwing2medium.mdl",
  "models/XQM/jetwing2medium.mdl",
  "models/props_phx/misc/propeller3x_small.mdl",
  "models/props_c17/TrapPropeller_Engine.mdl",
  "models/props_junk/Shoe001a.mdl",
  "models/XQM/jetbody2fuselage.mdl",
  "models/XQM/jettailpiece1medium.mdl",
  "models/XQM/pistontype1huge.mdl",
}

function ENT:Initialize()
  if CLIENT then
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(1000)

    util.Effect("swvr_explosion", effectdata)

    return
  end

  self:PhysicsInit()
  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_NONE)
  self:DrawShadow(false)

  local gibs = istable(self.Gibs) and self.Gibs or DefaultGibs

  for _, mdl in ipairs(gibs) do
    local ent = ents.Create("prop_physics")

    if not IsValid(ent) then continue end

    ent:SetPos(self:GetPos() + VectorRand() * 100)
    ent:SetAngles(self:LocalToWorldAngles(VectorRand():Angle()))
    ent:SetModel(mdl)
    ent:Spawn()
    ent:Activate()
    ent:SetMaterial("models/player/player_chrome1")
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

    self:DeleteOnRemove(ent)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
      phys:SetVelocityInstantaneous(VectorRand() * 1000)
      phys:AddAngleVelocity(VectorRand() * 500)
      phys:EnableDrag(false)
    end

    local effect = ents.Create("info_particle_system")
    effect:SetKeyValue("effect_name", "fire_small_03")
    effect:SetKeyValue("start_active", 1)
    effect:SetOwner(ent)
    effect:SetPos(ent:GetPos())
    effect:SetAngles(ent:GetAngles())
    effect:SetParent(ent)
    effect:Spawn()
    effect:Activate()
    effect:Fire("Stop", "", math.random(0.5, 3))

    self:DeleteOnRemove(effect)

    timer.Simple(4.5 + math.Rand(0, 0.5), function()
      if not IsValid(ent) then return end

      ent:SetRenderFX(kRenderFxFadeFast)
    end)
  end

  SafeRemoveEntityDelayed(self, 5)
end

function ENT:Draw()

end

function ENT:OnTakeDamage()

end

function ENT:PhysicsCollide()

end
