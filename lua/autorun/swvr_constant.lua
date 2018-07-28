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

SWVR.WEAPON_GUN = 0
SWVR.WEAPON_PROTON_BOMB = 1
SWVR.WEAPON_PROTON_TORPEDO = 2
SWVR.WEAPON_CONCUSSION_MISSILE = 3
