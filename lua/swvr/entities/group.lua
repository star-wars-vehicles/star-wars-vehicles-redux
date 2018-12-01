local ENT = { }
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OTHER
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
  self:NetworkVar("Bool", 0, "CanOverheat")
  self:NetworkVar("Bool", 1, "Lock")
  self:NetworkVar("Bool", 2, "Tracking")
  self:NetworkVar("Bool", 3, "Overheated")
  self:NetworkVar("Bool", 4, "Disabled")
  self:NetworkVar("Float", 0, "Delay")
  self:NetworkVar("Float", 1, "Cooldown")
  self:NetworkVar("Float", 2, "OverheatCooldown")
  self:NetworkVar("Float", 3, "MaxOverheat")
  self:NetworkVar("Float", 4, "Overheat")
  self:NetworkVar("String", 0, "WeaponClass")
  self:NetworkVar("Float", 0, "Delay")
  self:NetworkVar("Entity", 0, "_Target")

  AccessorFunc(self, "Sound", "Sound")
  AccessorFunc(self, "Callback", "Callback")

  AccessorBool(self, "Lock", "Can")
  AccessorBool(self, "Tracking", "Is")
  AccessorBool(self, "Overheated", "Is")
  AccessorBool(self, "Disabled", "Is")
end

function ENT:Initialize()
  self.Weapons = self.Weapons or { }
  self.Callbacks = self.Callbacks or { }
  if CLIENT then
    self:AddCallback("OnOverheat", function(e)
      print("RUNNING EVENT")
      surface.PlaySound("swvr/weapons/swvr_overheat_cooldown.wav")
    end)

    PrintTable(self:GetCallbacks("OnOverheat"))

    return
  end
  self:SetCooldown(CurTime())
  self:SetOverheat(0)
  self:SetMaxOverheat(40)
  self:SetDelay(0.25)
  self:CanOverheat(false)
  self:IsOverheated(false)
end

function ENT:Think()
  if CLIENT then return end

  if self:CanOverheat() then
    if self:GetCooldown() < CurTime() and self:GetOverheat() > 0 then
      self:SetOverheat(math.Clamp(self:GetOverheat() - self:GetOverheatCooldown() * 1 * FrameTime(), 0, self:GetMaxOverheat()))
      self:SetOverheatCooldown(math.Approach(self:GetOverheatCooldown(), 4, 1))

      if self:IsOverheated() and self:GetOverheat() <= 0 then
        self:RunCallback("OnOverheatReset")
      end
    end

    if not self:IsOverheated() and self:GetOverheat() >= self:GetMaxOverheat() then
      self:IsOverheated(true)
      self:RunCallback("OnOverheat")
    elseif self:GetOverheat() <= 0 then
      self:IsOverheated(false)
    end
  end

  --print(self:GetName(), self:GetOverheat())
  self:NextThink(CurTime())

  return true
end

function ENT:FireWeapon()
  if CLIENT then return end

  if self:CanFire() then
    if self:CanLock() then
      self:SetTarget(self:GetParent():GetTarget())
    end

    if self:GetSound() then
      (self:GetParent() or self):EmitSound(self:GetSound())
    end

    for _, weapon in pairs(self:GetWeapons()) do
      if not IsValid(weapon) then continue end
      weapon:FireWeapon()
    end

    if isfunction(self:GetCallback()) then
      self:GetCallback()(self)
    end

    self:SetOverheat(math.Clamp(self:GetOverheat() + 1, 0, self:GetMaxOverheat()))

    self:SetOverheatCooldown(2)
    self:RunCallback("OnFire")

    if self:CanOverheat() and self:GetOverheat() >= self:GetMaxOverheat() then
      self:RunCallback("OnOverheat")
      self:SetCooldown(CurTime() + 4)
    end

    self:SetCooldown(CurTime() + self:GetDelay())
  end
end

function ENT:CanFire()
  if self:GetCooldown() > CurTime() or self:IsDisabled() then return false end

  if self:IsOverheated() then
    return false
  end

  return true
end

-- ACCESSORS --
function ENT:SetOptions(options)
  self.Options = table.Merge(self.Options or { }, options or { })
  if CLIENT then return end

  for k, v in pairs(options) do
    if self["Set" .. k] then
      self["Set" .. k](self, v)
    end
  end

  for _, weapon in ipairs(self:GetWeapons()) do
    weapon:SetOptions(options)
  end
end

function ENT:GetOptions()
  return self.Options or { }
end

function ENT:SetTarget(ent)
  if CLIENT then return end
  self:Set_Target(ent)

  for _, weapon in ipairs(self:GetWeapons()) do
    weapon:SetTarget(self.Target)
  end
end

function ENT:GetTarget()
  return self:Get_Target()
end

function ENT:GetWeapons()
  return self.Weapons or { }
end

function ENT:CanOverheat(value)
  if value == nil then return tobool(self["GetCanOverheat"](self)) end
  self["SetCanOverheat"](self, value)
end

-- CALLBACKS --
function ENT:RunCallback(event, ...)
  for _, callback in pairs(self:GetCallbacks(event)) do
    if not isfunction(callback) then continue end
    callback(self, ...)
  end

  if SERVER then
    net.Start("ent.RunCallback")
      net.WriteEntity(self)
      net.WriteString(event)
      net.WriteTable(... or {})
    net.Broadcast()
  end
end

function ENT:AddCallback(event, callback)
  self.Callbacks = self.Callbacks or { }
  self.Callbacks[event] = self.Callbacks[event] or { }

  return table.insert(self.Callbacks[event], callback)
end

function ENT:RemoveCallback(event, callbackid)
  self.Callbacks = self.Callbacks or { }
  self.Callbacks[event] = self.Callbacks[event] or { }
  self.Callbacks[event][callbackid] = nil
end

function ENT:GetCallbacks(event)
  local callbacks = { }

  for id, callback in pairs(self.Callbacks[event] or { }) do
    if not isfunction(callback) then continue end
    callbacks[id] = callback
  end

  return callbacks
end

-- SERIALIZATION --
function ENT:Serialize()
  return {
    Name = self:GetName(),
    Class = self:GetWeaponClass(),
    Delay = self:GetDelay(),
    Cooldown = self:GetCooldown(),
    CanOverheat = self:CanOverheat(),
    MaxOverheat = self:GetMaxOverheat(),
    Overheat = self:GetOverheat(),
    OverheatCooldown = self:GetOverheatCooldown(),
    Overheated = self:IsOverheated(),
    IsTracking = self:IsTracking(),
    CanLock = self:CanLock()
  }
end

-- ADDING WEAPONS --
function ENT:AddWeapon(options)
  local weapon = ents.Create(self:GetWeaponClass())
  weapon:Spawn()
  weapon:SetOwner(self:GetOwner())
  weapon:SetParent(self:GetParent())
  weapon:SetGroup(self)
  weapon:SetOptions(table.Merge(self:GetOptions(), options or { }))

  weapon:CallOnRemove("RemoveFromGroup", function(w)
    self.Weapons[weapon:EntIndex()] = nil
  end)

  self:DeleteOnRemove(weapon)

  if not self.Sound then
    self.Sound = scripted_ents.GetMember(self:GetWeaponClass(), "Sound")
  end

  self.Weapons[weapon:EntIndex()] = weapon

  return weapon
end

-- NETWORKING

if SERVER then
  util.AddNetworkString("ent.RunCallback")
end

if CLIENT then
  net.Receive("ent.RunCallback", function()
    local ent = net.ReadEntity()
    local evt = net.ReadString()
    local tbl = net.ReadTable()

    ent:RunCallback(evt, unpack(tbl))
  end)
end

scripted_ents.Register(ENT, "swvr_weapon_group")
