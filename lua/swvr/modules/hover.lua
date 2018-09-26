local HOVER = {}

HOVER.Name = "Hover"
HOVER.Type = "Movement"
HOVER.Options = {
    Delay = "Time, in seconds, before hover begins. (Default: 3)",
    Multiplier = "How far the ship can hover from its initiali position. (Default: 0.25)"
}

function HOVER:Install(ent, options)
    local index = ent:EntIndex()

    ent:SetNWFloat("HoverStart", 0)

    hook.Add("Think", "SWVR.Hover.Think." .. index, function()
        if not IsValid(ent) then hook.Remove("Think", "SWVR.Hover.Think." .. index) return end

        if (not ent:IsTakingOff() and not ent:IsLanding() and ent.Accel.FWD == 0 and ent.Accel.UP == 0 and ent.Accel.RIGHT == 0) then
            if ent:GetNWFloat("HoverStart", 0) > 0 and CurTime() - ent:GetNWFloat("HoverStart", 0) > 3 then
                local curPos = ent:GetPos()
                ent:SetPos(Vector(curPos.x, curPos.y, curPos.z + (math.sin(CurTime() * 0.25 * math.pi * 2) * 0.25)))
            else
                ent:SetNWFloat("HoverStart", CurTime())
            end
        else
            ent:SetNWFloat("HoverStart", 0)
        end
    end)
end

function HOVER:Remove(ent)
    hook.Remove("Think", "SWVR.Hover.Think" .. ent:EntIndex())
end

SWVR:RegisterModule(HOVER)
