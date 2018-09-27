local GROUP = {}
GROUP.Options = {}

AccessorFunc(GROUP, "Name", "Name", FORCE_STRING)
AccessorFunc(GROUP, "Class", "Class", FORCE_STRING)

AccessorFunc(GROUP, "Delay", "Delay", FORCE_NUMBER)
AccessorFunc(GROUP, "Cooldown", "Cooldown", FORCE_NUMBER)
AccessorFunc(GROUP, "OverheatCooldown", "OverheatCooldown", FORCE_NUMBER)
AccessorFunc(GROUP, "Overheat", "Overheat", FORCE_NUMBER)
AccessorFunc(GROUP, "MaxOverheat", "MaxOverheat", FORCE_NUMBER)

AccessorFunc(GROUP, "CanOverheat", "CanOverheat", FORCE_BOOL)
AccessorFunc(GROUP, "Overheated", "Overheated", FORCE_BOOL)
AccessorFunc(GROUP, "CanLock", "CanLock", FORCE_BOOL)

AccessorFunc(GROUP, "Parent", "Parent")

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

	self:SetParent(NULL)
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

function GROUP:SetOptions(tbl)
	self.Options = table.Merge(self.Options, tbl or {})

	for k, v in pairs(self.Options) do
		if self["Set" .. k] then
			self["Set" .. k](self, v)
		end
	end

	for _, weapon in ipairs(self.Weapons) do
		weapon:SetOptions(tbl)
	end
end

function GROUP:GetOptions()
	return self.Options
end

function GROUP:Fire(cond)
	for _, weapon in ipairs(self.Weapons) do
		if type(cond) == "function" and not cond(weapon) then continue end
		weapon:Fire()
		self.Parent:EmitSound("ywing_fire")
	end
end

function GROUP:Serialize()
	return {
		Name = self:GetName(),
		Class = self:GetClass(),
		Delay = self:GetDelay(),
		Cooldown = self:GetCooldown(),
		OverheatMax = self:GetMaxOverheat(),
		Overheat = self:GetOverheat(),
		Overheated = self:GetOverheated()
	}
end

function GROUP:AddWeapon(options)
	local weapon = SWVR:Weapon(self.Class)
	weapon:Initialize()

	local index = table.insert(self.Weapons, weapon)
	weapon:SetIndex(index)
	weapon:SetParent(self:GetParent() or NULL)

	if istable(options) then
		self:SetOptions(options)
	end

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
