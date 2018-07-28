function ENT:_OnFire(default, group, seat)
  if not default then
    return
  end
end

function ENT:_OnShieldsDown(default)
  if not default then
    return
  end
end

function ENT:_OnEnter(default)
  if not default then
    return
  end
end

function ENT:_OnCritical(default)
  if not default then
    return
  end
end

function ENT:_OnOverheat(default, group, seat)
  if not default then
    return
  end
end

function ENT:_OnOverheatReset(default, group, seat)
  if not default then
    return
  end
end

function ENT:_OnCollision(default, damage)
  if not default then
    return
  end
end

function ENT:OnFire(callback, default)
  self:AddEvent("OnFire", callback, default)
end

function ENT:OnShieldsDown(callback, default)
  self:AddEvent("OnShieldsDown", callback, default)
end

function ENT:OnEnter(callback, default)
  self:AddEvent("OnEnter", callback, default)
end

function ENT:OnCritical(callback, default)
  self:AddEvent("OnCritical", callback, default)
end

function ENT:OnOverheat(callback, default)
  self:AddEvent("OnOverheat", callback, default)
end

function ENT:OnOverheatReset(callback, default)
  self:AddEvent("OnOverheatReset", callback, default)
end

function ENT:OnCollision(callback, default)
  self:AddEvent("OnCollision", callback, default)
end
