local ENT = {}

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
	self:NetworkVar("Entity", 1, "Group")

	AccessorFunc(self, "Sound", "Sound")

	AccessorBool(self, "Lock", "Can")
	AccessorBool(self, "Tracking", "Is")
	AccessorBool(self, "Overheated", "Is")
	AccessorBool(self, "Disabled", "Is")
end

function ENT:Initialize()
	self.Options = self.Options or {}
	self.Callbacks = self.Callbacks or {}

	if CLIENT then return end

	self:SetCooldown(CurTime())
	self:SetOverheat(0)
	self:SetMaxOverheat(40)
	self:SetDelay(0.25)

	self:CanOverheat(false)
	self:IsOverheated(false)
end

function ENT:Think()
	if CLIENT then return end

	if IsValid(self:GetGroup()) then return end

	if self:CanOverheat() and self:GetCooldown() < CurTime() and self:GetOverheat() > 0 then
		self:SetOverheat(self:GetOverheat() - self:GetOverheatCooldown() * 2.5)
		self:SetOverheatCooldown(math.Approach(self:GetOverheatCooldown(), 4, 1))

		if self:IsOverheated() and self:GetOverheat() <= 0 then
			self:RunCallback("OnOverheatReset")
		end
	end

	if self:CanOverheat() then
		if self:GetOverheat() >= self:GetMaxOverheat() then
			self:IsOverheated(true)
		elseif self:GetOverheat() <= 0 then
			self:IsOverheated(false)
		end
	end
end

function ENT:FireWeapon()
	if CLIENT then return end
	if not self:CanFire() then return end

	if not IsValid(self:GetGroup()) then
		if self:CanLock() then
			self:SetTarget(self:GetParent():GetTarget())
		end

		(self:GetParent() or self):EmitSound(self:GetSound())
	end

	self:SetOverheat(self:GetOverheat() + 1)
	self:SetOverheatCooldown(2)

	self:RunCallback("OnFire")

	if self:CanOverheat() and self:GetOverheat() >= self:GetMaxOverheat() then
		self:RunCallback("OnOverheat")
	end

	self:SetCooldown(CurTime() + self:GetDelay())
end

function ENT:CanFire()
	if IsValid(self:GetGroup()) then return true end

	if self:GetCooldown() > CurTime() or self:IsOverheated() then return false end

	return true
end

-- ACCESSORS -

function ENT:SetOptions(options)
	self.Options = table.Merge(self.Options or {}, options or {})

	if CLIENT then return end

	for k, v in pairs(options) do
		if not self["Set" .. k] then continue end

		self["Set" .. k](self, v)
	end
end

function ENT:GetOptions()
	return self.Options or {}
end

function ENT:CanOverheat(value)
	if value == nil then
		return tobool(self["GetCanOverheat"](self))
	end

	if CLIENT then return end

	self["SetCanOverheat"](self, value)
end

-- CALLBACKS --

function ENT:RunCallback(event, ...)
	for _, callback in pairs(self.Callbacks[event] or {}) do
		if not isfunction(callback) then continue end

		callback(self, ...)
	end
end

function ENT:AddCallback(event, callback)
	self.Callbacks = self.Callbacks or {}

	self.Callbacks[event] = self.Callbacks[event] or {}

	return table.insert(self.Callbacks[event], callback)
end

function ENT:RemoveCallback(event, callbackid)
	self.Callbacks = self.Callbacks or {}

	self.Callbacks[event] = self.Callbacks[event] or {}

	self.Callbacks[event][callbackid] = nil
end

function ENT:GetCallbacks(event)
	local callbacks = {}
	for id, callback in pairs(self.Callbacks[event] or {}) do
		if not isfunction(callback) then continue end

		callbacks[id] = callback
	end

	return callbacks
end

function ENT:Serialize()
	return {
		Name = self:GetName(),
		Class = self:GetClass(),
		Delay = self:GetDelay(),
		Cooldown = self:GetCooldown(),
		CanOverheat = self:GetCanOverheat(),
		MaxOverheat = self:GetMaxOverheat(),
		Overheat = self:GetOverheat(),
		OverheatCooldown = self:GetOverheatCooldown(),
		Overheated = self:IsOverheated(),
		IsTracking = self:IsTracking(),
		CanLock = self:CanLock()
	}
end

scripted_ents.Register(ENT, "swvr_weapon")
