AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local _ = include("libs/lodash.lua")

function ENT:Initialize()
    self.Weapons = self.Weapons or {}
    self.Target = nil
end

function ENT:Fire()
end

function ENT:FindTarget()
    local c1, c2 = self:GetParent():GetModelBounds()
    c1, c2 = self:GetParent():LocalToWorld(c1), self:GetParent():LocalToWorld(c2) + self:GetParent():GetForward() * 10000

    self.Target = _.find(ents.FindInBox(c1, c2), function(ent)
        return IsValid(ent) and ent:IsStarWarsVehicle() and ent ~= self:GetParent() and not IsValid(ent:GetParent()) and ent:GetAllegiance() ~= self:GetParent():GetAllegiance()
    end)

    return self
end

function ENT:AddWeapon(options)
    self.Weapons = self.Weapons or {}

    return self
end

function ENT:SpawnWeapons()
    return self
end

function ENT:OnRemove()
end
