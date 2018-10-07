local GROUP = {}
GROUP.Options = {}

AccessorFunc(GROUP, "Name", "Name", FORCE_STRING)

AccessorFunc(GROUP, "Delay", "Delay", FORCE_NUMBER)
AccessorFunc(GROUP, "Cooldown", "Cooldown", FORCE_NUMBER)
AccessorFunc(GROUP, "OverheatCooldown", "OverheatCooldown", FORCE_NUMBER)
AccessorFunc(GROUP, "Overheat", "Overheat", FORCE_NUMBER)
AccessorFunc(GROUP, "MaxOverheat", "MaxOverheat", FORCE_NUMBER)

AccessorFunc(GROUP, "CanOverheat", "CanOverheat", FORCE_BOOL)
AccessorFunc(GROUP, "Overheated", "Overheated", FORCE_BOOL)
AccessorFunc(GROUP, "CanLock", "CanLock", FORCE_BOOL)
AccessorFunc(GROUP, "IsTracking", "IsTracking", FORCE_BOOL)

AccessorFunc(GROUP, "Sound", "Sound")
AccessorFunc(GROUP, "Callback", "Callback")

AccessorFunc(GROUP, "Owner", "Owner")

function GROUP:Initialize()
	self.Weapons = {}

	self:SetName("")
	self:SetClass("")

	self:SetCanOverheat(false)
	self:SetOverheated(false)

	self:SetMaxOverheat(40)
	self:SetOverheat(0)
	self:SetDelay(0.2)
	self:SetCooldown(4)
	self:SetOverheatCooldown(0)

	self:SetOwner(NULL)
	self:SetParent(NULL)
end

function GROUP:SetClass(class)
	if not isstring(class) then error("Invalid class set for weapon group! Classes must be strings!") end

	self.Class = class

	if #class == 0 then return end

	self.Sound = SWVR:Weapon(class).Sound
end

function GROUP:GetClass()
	return self.Class
end

function GROUP:SetTarget(ent)
	self.Target = ent

	for _, weapon in ipairs(self.Weapons) do
		weapon:SetTarget(ent)
	end
end

function GROUP:GetTarget()
	return self.Target
end

function GROUP:SetParent(ent)
	if not ent == NULL or not isentity(ent) then error("Expected entity but got " .. type(ent) .. " (" .. tostring(ent) .. ") instead!") end

	self.Parent = ent
end

function GROUP:GetParent()
	return self.Parent
end

function GROUP:SetPlayer(ply)
	self.Player = (isentity(ply) and ply:IsPlayer()) and ply or NULL

	for _, weapon in ipairs(self.Weapons) do
			weapon:SetOptions({ Player = self.Player })
	end
end

function GROUP:GetPlayer()
	return self.Player
end

function GROUP:SetOptions(tbl)
	self.Options = table.Merge(self.Options, tbl or {})

	for k, v in pairs(self.Options) do
		if self["Set" .. k] then
			--print("Setting " .. k .. " in group '" .. self:GetName() .. "' to " .. tostring(v))
			self["Set" .. k](self, v)
		end
	end

	for _, weapon in ipairs(self.Weapons) do
		weapon:SetOptions(tbl)
	end
end

function GROUP:GetOptions()
	return self.Options or {}
end

function GROUP:Fire(cond)
	if self:GetCooldown() > CurTime() or self:GetOverheated() then return end

	if self:GetCanLock() then
		self:SetTarget(self:GetOwner():FindTarget())
	end

	if self.Sound then
		if istable(sound.GetProperties(self.Sound)) then
			self.Owner:StopSound(self.Sound)
		end

		self.Owner:EmitSound(self.Sound)
	end

	for _, weapon in ipairs(self.Weapons) do
		if type(cond) == "function" and not cond(weapon) then continue end
		weapon:Fire()
	end

	if isfunction(self:GetCallback()) then
		(self:GetCallback())(self)
	end

	self:SetCooldown(CurTime() + self:GetDelay())
end

function GROUP:Serialize()
	return {
		Name = self:GetName(),
		Class = self:GetClass(),
		Delay = self:GetDelay(),
		Cooldown = self:GetCooldown(),
		CanOverheat = self:GetCanOverheat(),
		MaxOverheat = self:GetMaxOverheat(),
		Overheat = self:GetOverheat(),
		OverheatCooldown = self:GetOverheatCooldown(),
		Overheated = self:GetOverheated(),
		IsTracking = self:GetIsTracking()
	}
end

function GROUP:AddWeapon(options)
	local weapon = SWVR:Weapon(self.Class)
	weapon:Initialize()

	local index = table.insert(self.Weapons, weapon)
	weapon:SetIndex(index)
	weapon:SetOwner(self:GetOwner())
	weapon:SetParent(self:GetParent())
	weapon:SetGroup(self)

	weapon:SetOptions(table.Merge(self:GetOptions(), options or {}))

	return weapon, index
end

function GROUP:RemoveWeapon(weapon)
	if istable(weapon) then
		weapon = weapon:GetIndex()
	end

	weapon:Remove()

	return table.remove(self.Weapons, index)
end

function GROUP:Remove()
	for _, weapon in ipairs(self.Weapons) do
		self:RemoveWeapon(weapon)
	end
end

function GROUP:GetWeapons()
	return self.Weapons
end

function SWVR:WeaponGroup(class)
	local group = table.Copy(GROUP)
	group:Initialize()
	group:SetClass(class)

	return group
end

local WEAPON = {}
WEAPON.Base = "swvr_base_weapon"
WEAPON.Options = {}

AccessorFunc(WEAPON, "Cooldown", "Cooldown", FORCE_NUMBER)
AccessorFunc(WEAPON, "Overheat", "Overheat", FORCE_NUMBER)
AccessorFunc(WEAPON, "Delay", "Delay", FORCE_NUMBER)
AccessorFunc(WEAPON, "Index", "Index", FORCE_NUMBER)
AccessorFunc(WEAPON, "Damage", "Damage", FORCE_NUMBER)

AccessorFunc(WEAPON, "CanLock", "CanLock", FORCE_BOOL)
AccessorFunc(WEAPON, "IsTracking", "IsTracking", FORCE_BOOL)

AccessorFunc(WEAPON, "Sound", "Sound", FORCE_STRING)

AccessorFunc(WEAPON, "Entity", "Entity")
AccessorFunc(WEAPON, "Target", "Target")
AccessorFunc(WEAPON, "Owner", "Owner")
AccessorFunc(WEAPON, "Group", "Group")
AccessorFunc(WEAPON, "Player", "Player")


AccessorFunc(WEAPON, "Name", "Name", FORCE_STRING)

function WEAPON:Initialize()
	local e = ents.Create("prop_dynamic")
	e:SetModel("models/props_junk/PopCan01a.mdl")

	if IsValid(self:GetPos()) then
		e:SetPos(self:GetPos())
		e:Spawn()
		e.Spawned = true
	end

	e:SetSolid(SOLID_NONE)
	e:PhysicsInit(SOLID_NONE)

	e:SetRenderMode(RENDERMODE_TRANSALPHA)
	e:AddFlags(FL_DONTTOUCH)
	e:SetColor(Color(255, 255, 255, 0))
	e:DrawShadow(false)


	if IsValid(self:GetParent()) then
		e:SetParent(self:GetParent())
	end

	self.Entity = e
end

function WEAPON:SetParent(parent)
	if not parent == NULL or not isentity(parent) then error("Expected entity but got " .. type(ent) .. " instead!") end

	self.Parent = parent

	if IsValid(self.Entity) then
		self.Entity:SetParent(parent)

		if not IsValid(self.Entity:GetParent()) then return end
		self.Entity:SetAngles(self.Entity:GetParent():GetAngles())
	end
end

function WEAPON:GetParent()
	return self.Parent
end

function WEAPON:SetOptions(tbl)
	self.Options = table.Merge(self.Options, tbl or {})

	for k, v in pairs(self.Options) do
		if self["Set" .. k] then
			-- print("Setting " .. k .. " in weapon '" .. self:GetName() .. "' to " .. tostring(v))
			self["Set" .. k](self, v)
		end
	end
end

function WEAPON:GetOptions()
	return self.Options
end

function WEAPON:SetPos(pos)
	if not IsValid(self.Entity) then return end

	self.Entity:SetPos(pos)

	if not self.Entity.Spawned then
		self.Entity:Spawn()
	end
end

function WEAPON:GetPos()
	if not IsValid(self.Entity) then return end

	return self.Entity:GetPos()
end

function WEAPON:Fire()
	if self.Sound and not self.Group then
		self.Owner:EmitSound(self.Sound)
	end
end

function WEAPON:Remove()
	SafeRemoveEntity(self.Entity)
end

local BaseClasses = {}
BaseClasses["weapon"] = "swvr_base_weapon"
BaseClasses["cannon"]  = "swvr_base_cannon"
BaseClasses["missile"] = "swvr_base_missile"

local Weapons = Weapons or {}

SWVR.Weapons = {}

function SWVR.Weapons:Register(weapon, name)
	local Base = weapon.Base
	if not Base then Base = BaseClasses[string.lower(weapon.Type)] end

	--local old = Weapons[name]
	local tab = {}
	tab.type 		= weapon.Type
	tab.t 	 		= weapon
	tab.isBaseType  = true
	tab.Base 		= Base
	tab.t.ClassName = name

	if not Base then
		error("Trying to register SWVR weapon without a valid base/type!")
	end

	Weapons[name] = tab

	-- if old ~= nil then
	-- 	for _, wep in ipairs(Weapons) do
	-- 		table.Merge(wep, tab.t)

	-- 		if wep.OnReloaded then
	-- 			wep:OnReloaded()
	-- 		end
	-- 	end
	-- end

	list.Set("SWVR.Weapons", name, {
		Name = weapon.Name,
		Author = weapon.Author
	})
end

function SWVR.Weapons:Get(name)
	if Weapons[name] == nil then return nil end

	local retval = {}
	for k, v in pairs(Weapons[name].t) do
		-- Copy the damn table or else they'll all share the same weapon base table
		if istable(v) then
			retval[k] = table.Copy(v)
		else
			retval[k] = v
		end
	end

	if name ~= Weapons[name].Base then
		local base = self:Get(Weapons[name].Base)

		if not base then
			error("Trying to derive SWVR weapon '" .. name .. "' from non existant base '" .. Weapons[name].Base .. "'!")
		end

		retval = table.Inherit(retval, base)
	end

	return retval
end

function SWVR.Weapons:GetTable()
	local results = {}
	for k, v in pairs(Weapons) do
		results[k] = v
	end

	return results
end

hook.Add("InitPostEntity", "SWVROnLoaded", function()
	for k, v in pairs(Weapons) do
		baseclass.Set(k, SWVR.Weapons:Get(k))
	end
end)

SWVR.Weapons:Register(WEAPON, "swvr_base_weapon")

function SWVR:Weapon(class)
	return self.Weapons:Get(class)
end
