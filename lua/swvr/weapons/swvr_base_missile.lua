local MISSILE = {}

MISSILE.Base = "swvr_base_weapon"
MISSILE.Type = "missile"

DEFINE_BASECLASS("swvr_base_weapon")

function MISSILE:Initialize()
	BaseClass.Initialize(self)
end

function MISSILE:Fire()

end

SWVR.Weapons:Register(MISSILE, "swvr_base_missile")
