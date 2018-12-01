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

  local group = ents.Create("swvr_weapon_group")
  group:Spawn()
  group:SetWeaponClass(weapon)
  group:SetName(name)
  group:SetOwner(self)

  if not options.Parent then group:SetParent(self) end
  group:SetOptions(options)

  group:SetAngles(group:GetParent():GetAngles())

  self.WeaponGroups[name] = group

  self:CallOnRemove("RemoveGroup" .. name, function(ent)
    ent.WeaponGroups[name] = nil
  end)

  self:DeleteOnRemove(group)

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
  weapon:SetAngles(weapon:GetParent():GetAngles())

  self.Weapons[name] = weapon

  return weapon
end

--- Fire a specific weapon group.
-- @param g The weapon group to fire
function ENT:FireWeapons(g)
  local group = self.WeaponGroups[g]
  group:FireWeapon()
end

function ENT:FindTarget()
  local c1, c2 = self:GetModelBounds()
  c1, c2 = self:LocalToWorld(c1), self:LocalToWorld(c2) + self:GetForward() * 10000

  for _, ent in pairs(ents.FindInBox(c1, c2)) do
    if (IsValid(ent) and ent:IsStarWarsVehicle() and ent ~= self and not IsValid(ent:GetParent()) and ent:GetAllegiance() ~= self:GetAllegiance()) then
      return ent
    end
  end

  return NULL
end

function ENT:ThinkWeapons()
  if not cvars.Bool("swvr_weapons_enabled") then return end

  for _, button in pairs(SWVR.Buttons) do
    for _, tbl in pairs(self.Players or {}) do
      local ply = tbl.ent
      if not IsValid(ply) then continue end

      local seat = ply:GetNWString("SeatName")
      if not self.Seats[seat]["Weapons"][button] then continue end

      if ply:KeyDown(button) then
        self:FireWeapons(self.Seats[seat]["Weapons"][button])
      end
    end
  end
  self:NetworkWeapons()
end

function ENT:NetworkWeapons()
  for name, group in pairs(self.WeaponGroups) do
    if not group:GetOwner():IsPlayer() then continue end

    net.Start("SWVR.NetworkWeapons")
      net.WriteEntity(self)
      net.WriteTable(group:Serialize())
    net.Send(group:GetOwner())
  end
end
