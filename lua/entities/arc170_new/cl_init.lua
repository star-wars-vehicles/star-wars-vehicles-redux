include("shared.lua")

function ENT:Initialize()
  self:Setup({
    viewdistance = 1200,
    viewheight = 200
  })

  self:SetupDefaults()

  -- Adding a clientside sound
  self:AddSound("Engine", "ywing_engine_loop")

  -- Adding a clientside part
  self:AddPart("Cockpit", "models/arc170/arc170_bf2_cockpit.mdl")

  -- Adding engine effects
  self:AddEngine(Vector(-240, 85, 90), {
    startsize = 15,
    endsize = 10,
    lifetime = 2.7,
    color = Color(255, 40, 40),
    sprite = "sprites/bluecore"
  })

  self:AddEngine(Vector(-240, -85, 90), {
    startsize = 15,
    endsize = 10,
    lifetime = 2.7,
    color = Color(255, 40, 40),
    sprite = "sprites/bluecore"
  })

  -- Initialize the base, do not remove.
  self.BaseClass.Initialize(self)
end
