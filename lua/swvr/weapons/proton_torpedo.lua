local WEAPON = {}

WEAPON.Base = "swvr_weapon_base"
WEAPON.Type = "missile"

function WEAPON:Initialize()
end

function WEAPON:Fire()

end

SWVR:RegisterWeapon("proton_torpedo", WEAPON)
