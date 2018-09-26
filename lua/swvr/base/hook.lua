hook.Add("OnEntityCreated", "SWVRSetupPlayer", function(ent)
  if ent:IsPlayer() then
    ent:SetNWEntity("Ship", nil)
    ent:SetNWEntity("Seat", nil)
    ent:SetNWBool("Flying", false)
    ent:SetNWBool("Pilot", false)
    ent:SetNWVector("ExitPos", Vector(0, 0, 0))
  end
end)
