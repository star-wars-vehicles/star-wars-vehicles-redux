function ENT:_OnShieldsDown()
  self:DispatchListeners("OnShieldsDown")
end

function ENT:_OnCritical()
  local ent = net.ReadEntity()
  self:DispatchListeners("OnCritical", ent)
end

function ENT:_OnEnter()
  local ply = net.ReadEntity()
  self:DispatchListeners("OnEnter", ply)
end

function ENT:_OnFire()
  local group = net.ReadTable()
  local seat = net.ReadString()

  self:DispatchListeners("OnFire", group, seat)
end

function ENT:_OnOverheat()
  local group = net.ReadTable()
  local seat = net.ReadString()

  self:DispatchListeners("OnOverheat", group, seat)
end

function ENT:_OnOverheatReset()
  local group = net.ReadTable()
  local seat = net.ReadString()

  self:DispatchListeners("OnOverheatReset", group, seat)
end

function ENT:_OnCollision()
  local damage = net.ReadFloat()

  self:DispatchListeners("OnCollision", damage)
end

function ENT:OnFire(callback)
  self:AddEvent("OnFire", callback)
end

function ENT:OnShieldsDown(callback)
  self:AddEvent("OnShieldsDown", callback)
end

function ENT:OnEnter(callback)
  self:AddEvent("OnEnter", callback)
end

function ENT:OnCritical(callback)
  self:AddEvent("OnCritical", callback)
end

function ENT:OnOverheat(callback)
  self:AddEvent("OnOverheat", callback)
end

function ENT:OnOverheatReset(callback)
  self:AddEvent("OnOverheatReset", callback)
end

function ENT:OnCollision(callback)
  self:AddEvent("OnCollision", callback)
end
