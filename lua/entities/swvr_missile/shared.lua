ENT.Type = "anim"

function ENT:SetupDataTables()
  self:NetworkVar("Bool", 0, "Disabled")
  self:NetworkVar("Bool", 1, "CleanMissile")

  self:NetworkVar("Entity", 0, "Attacker")
  self:NetworkVar("Entity", 1, "Inflictor")
  self:NetworkVar("Entity", 2, "LockOn")

  self:NetworkVar("Float", 0, "StartVelocity")
end
