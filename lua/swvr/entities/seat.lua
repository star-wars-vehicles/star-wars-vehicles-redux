local ENT = {}

ENT.Type = "anim"
ENT.PrintName = "SWVR Seat"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.DisableDuplicator = true

ENT.Spawnable = true

AccessorFunc(ENT, "SeatClass", "SeatClass", FORCE_STRING)

function ENT:SetupDataTables()
  self:NetworkVar("Vector", 0, "ExitPos")

  self:NetworkVar("Bool", 0, "ThirdPersonDisabled")
  self:NetworkVar("Bool", 1, "UseVehicle")

  self:NetworkVar("Entity", 0, "Avatar")
  self:NetworkVar("Entity", 1, "Seat")
end

function ENT:SpawnFunction(ply, tr, ClassName)
  if not tr.Hit then
    return
  end

  local ent = ents.Create(ClassName)
  ent:SetPos(tr.HitPos + tr.HitNormal * 20)
  ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
  ent:Spawn()
  ent:Activate()

  return ent
end

function ENT:Initialize()
  self.Controls = self.Controls or {}

  if CLIENT then return end

  self.Cooldown = { Use = CurTime() }

  self:SetModel("models/props_junk/PopCan01a.mdl")
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:StartMotionController()
  self:SetRenderMode(RENDERMODE_TRANSALPHA)
  self:SetUseType(SIMPLE_USE)

  self:DrawShadow(false)

  self:SetOwner(NULL)

  self:SetUseVehicle(true)

  if not self:GetUseVehicle() then return end

  print("CREATING SEAT")

  local e = ents.Create(self:GetSeatClass() or "prop_vehicle_prisoner_pod")

  e:SetPos(self:GetPos())
  e:SetAngles(self:GetAngles())
  e:SetParent(self)
  e:SetModel("models/nova/airboat_seat.mdl")
  e:SetRenderMode(RENDERMODE_TRANSALPHA)
  e:SetColor(self:GetColor())
  e:SetModelScale(self:GetValidParent():GetModelScale())
  e:Spawn()
  e:Activate()
  e:GetPhysicsObject():EnableMotion(false)
  e:GetPhysicsObject():EnableCollisions(false)
  e:SetCollisionGroup(COLLISION_GROUP_WEAPON)
  e:SetNWBool("ThirdPersonDisabled", self:GetThirdPersonDisabled())
  e:DrawShadow(false)
  e.IsSWVRSeat = true

  self:DeleteOnRemove(e)
  self:SetSeat(e)
end

function ENT:GetValidParent()
  local parent = self:GetParent()

  return IsValid(parent) and parent or self
end

function ENT:Use(ply)
  if IsValid(self:GetOwner()) then return end
  if self.Cooldown.Use > CurTime() then return end

  self.Cooldown.Use = CurTime() + 1

  self:Enter(ply)
end

function ENT:Enter(ply)
  if not (IsValid(ply) and ply:IsPlayer()) then return end

  self:SetOwner(ply)

  if self:GetUseVehicle() then
    if not IsValid(ply:GetVehicle()) then
      ply:EnterVehicle(self:GetSeat())
    end

    self:SavePlayer(ply)
  else
    ply:Spectate(OBS_MODE_CHASE)
    ply:DrawWorldModel(false)
    ply:DrawViewModel(false)
    ply:SetRenderMode(RENDERMODE_TRANSALPHA)
    ply:SetColor(Color(255, 255, 255, 0))
    ply:SetMoveType(MOVETYPE_NOCLIP)
    ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    self:SavePlayer(ply)

    ply:StripWeapons()
    ply:SetViewEntity(self:GetValidParent())
    ply:SetModelScale(self:GetValidParent():GetModelScale())

    local e = ents.Create("prop_dynamic")
    e:SetParent(self)
    e:SetModel(ply:GetModel())
    e:SetPos(self:GetPos())
    e:SetAngles(self:GetAngles())
    e:Spawn()
    e:SetModelScale(self:GetValidParent():GetModelScale())
    e:Activate()
    e:SetSequence("drive_jeep")

    self:DeleteOnRemove(e)
    self:SetAvatar(e)
  end

  ply:SetEyeAngles(self:GetValidParent():GetAngles())
end

function ENT:Exit()
  if not (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then return end

  local p = self:GetOwner()

  if IsValid(p) then
    p:UnSpectate()
    p:DrawViewModel(true)
    p:DrawWorldModel(true)
    p:Spawn()

    p:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    p:SetViewEntity(NULL)

    p:SetRenderMode(RENDERMODE_NORMAL)
    p:SetColor(Color(255, 255, 255, 255))
    p:SetVelocity(self:GetVelocity())
    p:SetModelScale(1)
  end

  if IsValid(self:GetAvatar()) then
    self:GetAvatar():Remove()
    self:SetAvatar(nil)
  end

  self:LoadPlayer()
  self:SetOwner(NULL)

  return p
end

function ENT:SavePlayer()
  if not (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then return end

  local ply = self:GetOwner()

  self.Data = {
    Health = ply:Health(),
    Armor = ply:Armor(),
    ActiveWeapon = ply:GetActiveWeapon():GetClass(),
    Weapons = {},
    Ammo = {}
  }

  for k, v in pairs(ply:GetWeapons()) do
    table.insert(self.Data.Weapons, v:GetClass())
    self.Data.Ammo[k] = {v:GetPrimaryAmmoType(), ply:GetAmmoCount(v:GetPrimaryAmmoType())}
  end

  ply:SetCanZoom(false)
  ply:Flashlight(false)
  ply:AllowFlashlight(false)
end

function ENT:LoadPlayer()
  if not (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then return NULL end

  local data, ply = self.Data, self:GetOwner()

  if istable(data) then
    ply:SetHealth(data.Health)
    ply:SetArmor(data.Armor)

    for k, v in pairs(data.Weapons) do
      if not ply:HasWeapon(tostring(v)) then
        ply:Give(tostring(v))
      end
    end

    if data.ActiveWeapon ~= "" then
      ply:SelectWeapon(data.ActiveWeapon)
    end

    ply:StripAmmo()

    for k, v in pairs(data.Ammo) do
      ply:SetAmmo(v[2], v[1])
    end

    ply:SetCanZoom(true)
    ply:AllowFlashlight(true)

    self.Data = {}
  end

  ply:SetPos(self:GetValidParent():LocalToWorld(self:GetExitPos()))

  if kill and ply:Alive() and not ply:HasGodMode() then
    ply:Kill()
  end

  return ply
end

function ENT:Think()
  if CLIENT then return end

  if not self:GetUseVehicle() and IsValid(self:GetOwner()) and self:GetOwner():KeyDown(IN_USE) and self.Cooldown.Use < CurTime() then
    self:Exit()
  end

  if self:GetUseVehicle() then
    self:GetSeat():SetThirdPersonMode(false)
  end
end

function ENT:Draw()
  self:DrawModel()

  local avatar = self:GetAvatar()

  if not IsValid(avatar) then return end

  if self:GetNoDraw() then avatar:SetNoDraw(true) return end

  avatar:SetNoDraw(false)
  avatar:DrawModel()
end

hook.Add("PlayerEnteredVehicle", "SWVR.Seat.PlayerEnteredVehicle", function(p, v)
  if not (IsValid(p) and IsValid(v) and v.IsSWVRSeat) then return end

  v:GetParent():Enter(p)
end)

hook.Add("PlayerLeaveVehicle", "SWVR.Seat.PlayerLeaveVehicle", function(p, v)
  if IsValid(p) and IsValid(v) and v.IsSWVRSeat then
    print("LEAVING SEAT")
    v:SetThirdPersonMode(false)
    v:GetParent():Exit(p)
  end
end)

scripted_ents.Register(ENT, "swvr_seat")