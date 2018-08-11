include("shared.lua")

function ENT:Initialize()
  self.ViewDistance = 1200
  self.ViewHeight = 375

  -- Adding a clientside sound
  self:AddSound("Engine", "vehicles/ywing_eng_loop2.wav")

  self:AddSound("Chatter", {
    "vehicles/starviper/chatter/attack1.wav", "vehicles/starviper/chatter/formation2.wav", "vehicles/starviper/chatter/moving5.wav", "vehicles/starviper/chatter/rightaway.wav",
  }, {
    once = false,
    cooldown = 5
  })

  -- Adding a clientside part
  self:AddPart("Cockpit", "models/ywing/ywing_btlb_test_cockpit.mdl")

  local engineOptions = {
    startsize = 65,
    endsize = 40,
    lifetime =  2.7,
    color =  Color(255, 0, 0),
    spirte = "sprites/bluecore"
  }

  -- Adding engine effects
  self:AddEngine(Vector(-630, 240, 60), engineOptions)
  self:AddEngine(Vector(-630, -240, 60), engineOptions)

  self:AddLight(Vector(-630, 240, 60), {
    size = 100
  })

  -- Initialize the base, do not remove.
  self.BaseClass.Initialize(self)
end
