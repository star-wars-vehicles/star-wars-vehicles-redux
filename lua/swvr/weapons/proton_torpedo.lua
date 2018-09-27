local WEAPON = {}

WEAPON.Base = "swvr_base_missile"
WEAPON.Type = "missile"

function WEAPON:Initialize()
	self.BaseClass.Initialize(self)
end

function WEAPON:Fire()
	self.BaseClass.Fire(self)
end

SWVR.Weapons:Register(WEAPON, "proton_torpedo")
