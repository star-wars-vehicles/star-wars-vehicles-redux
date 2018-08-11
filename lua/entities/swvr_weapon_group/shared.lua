ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "base_point"
ENT.Type = "point"
ENT.Spawnable = false

local _ = include("libs/lodash.lua")

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "CanOverheat")
    self:NetworkVar("Bool", 1, "Overheated")
    self:NetworkVar("String", 0, "FireSound")
end

function ENT:CanOverheat(value)
    if not value and value == nil then
        return self:GetCanOverheat()
    end

    self:SetCanOverheat(tobool(value))

    return self
end

function ENT:FireSound(value)
    if not value and value == nil then
        return self:GetFireSound()
    end

    self:SetFireSound(tostring(value))

    return self
end

function ENT:IsOverheated(value)
    if not value and value == nil then
        return self:GetOverheated()
    end

    self:SetOverheated(tobool(value))

    return self
end
