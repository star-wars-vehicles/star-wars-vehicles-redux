local GROUP = {}

AccessorFunc(GROUP, "Name", "Name", FORCE_STRING)
AccessorFunc(GROUP, "Class", "Class", FORCE_STRING)

AccessorFunc(GROUP, "Entity", "Entity")

function GROUP:Initialize()
	self.Weapons = {}
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

function GROUP:Fire(cond)
	for _, weapon in ipairs(self.Weapons) do
		if type(cond) == "function" and not cond(weapon) then continue end
		weapon:Fire()
	end
end

function GROUP:Serialize()
	return {
		Name = self.Name
	}
end

function GROUP:Add()
	local weapon = SWVR:Weapon(self.Class)
	weapon:Initialize()

	local index = table.insert(self.Weapons, weapon)
	weapon:SetIndex(index)

	return index
end

function GROUP:Delete(weapon)
	if istable(weapon) then
		weapon = weapon:GetIndex()
	end

	weapon:Remove()

	return table.remove(self.Weapons, index)
end

function GROUP:Remove()
	for _, weapon in ipairs(self.Weapons) do
		self:Delete(weapon)
	end
end

function GROUP:GetWeapons()
	return self.Weapons
end

function SWVR:Group(class)
	local group = table.Copy(GROUP)
	group:Initialize()
	group:SetClass(class)

	return group
end
