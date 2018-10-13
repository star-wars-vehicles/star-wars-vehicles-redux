--- Add a new weapon group.
-- Create a weapon group for weapons to parent to.
-- @param name The name of the weapon group.
-- @param bullet The type of bullet the group will use.
function ENT:AddWeaponGroup(name, weapon, options)
  self.WeaponGroups = self.WeaponGroups or {}

  if self.WeaponGroups[name] then
    error("Tried to create weapon group '" .. name .. "' that already exists!")
  end

  options = options or {}
  if isstring(options.Parent) then
    options.Parent = self.Parts[options.Parent].Entity
  end

  options.Parent = options.Parent or self

  if options.Damage then options.Damage = options.Damage * cvars.Number("swvr_weapons_multiplier") end

  local group = SWVR:WeaponGroup(weapon)
  group:SetName(name)
  group:SetOwner(self)

  if not options.Parent then group:SetParent(self) end
  group:SetOptions(options)

  self.WeaponGroups[name] = group

  self:CallOnRemove("RemoveGroup" .. name, function(ent, g)
    ent.WeaponGroups[g]:Remove()
  end, name)

  return group
end

-- Add a new weapon.
-- Creates a new weapon on the ship.
-- @param group The weapon group the new weapon is part of.
-- @param name The name of weapon.
-- @param pos The position of the weapon.
function ENT:AddWeapon(group, name, pos, options)
  self.Weapons = self.Weapons or {}

  if not self.WeaponGroups[group] then
    return error("Tried to add weapon '" .. name .. "' to group '" .. group .. "' which doesn't exist! (Make sure to add the group first)")
  end

  for k, v in pairs(self.Weapons) do
    if v:GetName() == name then
      return error("Tried to add weapon '" .. name .. "' which already exists! (Weapons cannot have duplicate names)")
    end
  end

  local WeaponGroup = self.WeaponGroups[group]

  options = options or {}
  if isstring(options.Parent) then
    options.Parent = self.Parts[options.Parent].Entity
  end

  options.Parent = options.Parent or WeaponGroup:GetParent() or self
  options.Name = name

  local weapon = WeaponGroup:AddWeapon(options)
  weapon:SetPos(self:LocalToWorld(pos * self:GetModelScale()))

  self.Weapons[name] = weapon

  return weapon
end

--- Fire a specific weapon group.
-- @param g The weapon group to fire
function ENT:FireWeapons(g)
  local group = self.WeaponGroups[g]
  group:Fire()
end

function ENT:NetworkWeapons()
  local serialized = {}
  for name, group in pairs(self.WeaponGroups) do
    serialized[name] = group:Serialize()
  end

  net.Start("SWVR.NetworkWeapons")
    net.WriteEntity(self)
    net.WriteTable(serialized)
  net.Send(self:GetPlayers())
end
