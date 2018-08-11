SWVR = SWVR or {
    Buttons = {IN_ATTACK, IN_ATTACK2, IN_ZOOM},
    Allegiances = {
        Light = {
            "Rebel Alliance", "Galactic Republic"
        },
        Dark = {
            "Imperial Empire",  "Confederacy of Independent Systems", "First Order"
        },
        Neutral = {}
    },
    InputMap = {[MOUSE_LEFT] = IN_ATTACK, [MOUSE_RIGHT] = IN_ATTACK2, [MOUSE_MIDDLE] = IN_ZOOM},
    CountPlayerOwnedSENTs = function(class, p)
        local count = 0

        for k, v in pairs(ents.FindByClass(class)) do
            if (v:GetCreator() == p) then
                count = count + 1
            end
        end

        return count
    end
}

function SWVR:LightOrDark(allegiance)
    return table.HasValue(self.Allegiances.Light, allegiance) and "Light" or table.HasValue(self.Allegiances.Dark, allegiance) and "Dark" or "Neutral"
end

local entity = FindMetaTable("Entity")

function entity:IsStarWarsVehicle()
    return Either(isbool(self.IsSWVehicle) or isbool(self.IsSWVRVehicle), self.IsSWVehicle or self.IsSWVRVehicle, false)
end

WEAPON_CANNON = 0
WEAPON_PROTON_BOMB = 1
WEAPON_PROTON_TORPEDO = 2
WEAPON_CONCUSSION_MISSILE = 3

COOLDOWN_OVERHEAT = 0
COOLDOWN_AMOUNT = 1
COOLDOWN_OFF = 2

SIDE_LIGHT = 0
SIDE_DARK = 1
SIDE_NEUTRAL = 2
