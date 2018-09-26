local WEAPON = {}

WEAPON.Base = "swvr_weapon_base"
WEAPON.Type = "cannon"

WEAPON.Name = "RG-9 Laser Cannon"
WEAPON.Author = "Borstel"

WEAPON.Cooldown = 4

function WEAPON:Initialize()

end

function WEAPON:Fire()

end

SWVR:RegisterWeapon("laser_cannon", WEAPON)
