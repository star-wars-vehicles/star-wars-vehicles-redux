local WEAPON = {}
WEAPON.Base = "swvr_base_weapon"
WEAPON.Options = {}

AccessorFunc(WEAPON, "Cooldown", "Cooldown", FORCE_NUMBER)
AccessorFunc(WEAPON, "Overheat", "Overheat", FORCE_NUMBER)
AccessorFunc(WEAPON, "Delay", "Delay", FORCE_NUMBER)
AccessorFunc(WEAPON, "Index", "Index", FORCE_NUMBER)
AccessorFunc(WEAPON, "Damage", "Damage", FORCE_NUMBER)

AccessorFunc(WEAPON, "Ion", "Ion", FORCE_BOOL)
AccessorFunc(WEAPON, "CanLock", "CanLock", FORCE_BOOL)

AccessorFunc(WEAPON, "Entity", "Entity")
AccessorFunc(WEAPON, "Target", "Target")
AccessorFunc(WEAPON, "Owner", "Owner")
AccessorFunc(WEAPON, "Group", "Group")

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
	--e:SetColor(Color(255, 255, 255, 0))
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
			print("Setting " .. k .. " in weapon '" .. self:GetName() .. "' to " .. tostring(v))
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

end

function WEAPON:Remove()
	SafeRemoveEntity(self.Entity)
end

local BaseClasses = {}
BaseClasses["weapon"] = "swvr_base_weapon"
BaseClasses["cannon"]  = "swvr_base_cannon"
BaseClasses["missile"] = "swvr_base_missile"

local Weapons = {}

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
		retval[k] = v
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
