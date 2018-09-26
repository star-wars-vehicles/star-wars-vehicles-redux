local SHIELDS = {}
SHIELDS.Name = "Shields"
SHIELDS.Type = "Damage"

SHIELDS.Options = {
    Health = "Starting health of the shields. (Default: 600)",
    Multiplier = "How much reduced damage shields take. (Default 0.8)"
}

function SHIELDS:Install(ent, options)
    local index = ent:EntIndex()

    if SERVER then
        ent:SetNWFloat("Shields.MaxHealth", ent:GetStartHealth() * 0.6)
        ent:SetNWFloat("Shields.Health", ent:GetNWFloat("Shields.MaxHealth"))

        hook.Add("EntityTakeDamage", "SWVR.Shields.EntityTakeDamage." .. index, function(e, dmg)
            if not IsValid(ent) then
                hook.Remove("Think", "SWVR.Shields.EntityTakeDamage." .. index)

                return
            end

            if not e.IsSWVRVehicle or e ~= ent then
                return
            end

            local shield = e:GetNWFloat("Shields.Health", 0)

            if shield > 0 then
                e:SetNWFloat("Shields.Health", math.max(0, shield - dmg:GetDamage()))
                ent:DispatchEvent("OnShieldsHit")

                if e:GetNWFloat("Shields.Health", 0) <= 0 then
                    e:DispatchEvent("OnShieldsDown")
                end

                return true
            end
        end)
    end
end

function SHIELDS:Remove(ent)
    if SERVER then
        hook.Remove("EntityTakeDamage", "SWVR.Shields.EntityTakeDamage." .. ent:EntIndex())
    end
end

SWVR:RegisterModule(SHIELDS)
