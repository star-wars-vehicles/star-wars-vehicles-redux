include("shared.lua")

function ENT:Initialize()
  self.ViewDistance = 950
  self.ViewHeight = 200

  -- Adding a clientside sound
  self:AddSound("Engine", "vehicles/rz2_engine_loop.wav")

  -- Adding a clientside part
  self:AddPart("Cockpit", "models/awing/new_awing_cockpit.mdl")

  -- Adding engine effects
  self:AddEngine(Vector(-105, 42, 40), 18, 10, 2.7, Color(255, 204, 102), "sprites/orangecore1")
  self:AddEngine(Vector(-105, -42, 40), 18, 10, 2.7, Color(255, 204, 102), "sprites/orangecore1")

  self:AddEvent("OnCritical", function()
    if LocalPlayer():GetNWEntity("Ship") ~= self then return end
    surface.PlaySound("atat/atat_shoot.wav")
  end)

  -- Initialize the base, do not remove.
  self.BaseClass.Initialize(self)
end
