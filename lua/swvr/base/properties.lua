properties.Add("allegiance", {
    MenuLabel = "Allegiance",
    Order = 999,
    MenuIcon = "icon16/flag_blue.png",
    Filter = function(self, ent, ply)
        if (not IsValid(ent)) then
            return false
        end

        if (ent:IsPlayer()) then
            return false
        end

        if (not ent.IsSWVRVehicle) then
            return false
        end

        if not (ply:IsAdmin() or ply:IsSuperAdmin()) then
            return false
        end

        return ent.IsSWVRVehicle
    end,
    MenuOpen = function(self, option, ent, tr)
        local submenu = option:AddSubMenu()

        for _, faction in pairs(SWVR.Allegiances) do
            for __, allegiance in pairs(faction) do
                local opt = submenu:AddOption(allegiance, function()
                    self:SetAllegiance(ent, allegiance)
                end)

                if (ent:GetAllegiance() == allegiance) then
                    opt:SetChecked(true)
                end
            end
        end
    end,
    Action = function(self, ent) end,
    SetAllegiance = function(self, ent, allegiance)
        self:MsgStart()
        net.WriteEntity(ent)
        net.WriteString(allegiance)
        self:MsgEnd()
    end,
    Receive = function(self, length, player)
        local ent = net.ReadEntity()
        local allegiance = net.ReadString()

        if (not self:Filter(ent, player)) then
            return
        end

        ent:SetAllegiance(allegiance)
    end
})

properties.Add("bang", {
    MenuLabel = "Destroy",
    Order = 999,
    MenuIcon = "icon16/bomb.png",
    Filter = function(self, ent, ply)
        if (not IsValid(ent)) then
            return false
        end

        if (ent:IsPlayer()) then
            return false
        end

        if (not ent.IsSWVRVehicle) then
            return false
        end

        if not (ply:IsAdmin() or ply:IsSuperAdmin()) then
            return false
        end

        return ent.IsSWVRVehicle
    end,
    Action = function(self, ent)
        self:MsgStart()
        net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, player)
        local ent = net.ReadEntity()

        if (not self:Filter(ent, player)) then
            return
        end

        ent:Bang()
    end
})

properties.Add("repair", {
    MenuLabel = "Repair",
    Order = 999,
    MenuIcon = "icon16/bullet_wrench.png",
    Filter = function(self, ent, ply)
        if (not IsValid(ent)) then
            return false
        end

        if (ent:IsPlayer()) then
            return false
        end

        if (not ent.IsSWVRVehicle) then
            return false
        end

        if not (ply:IsAdmin() or ply:IsSuperAdmin()) then
            return false
        end

        return ent.IsSWVRVehicle
    end,
    Action = function(self, ent)
        self:MsgStart()
        net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, player)
        local ent = net.ReadEntity()

        if (not self:Filter(ent, player)) then
            return
        end

        ent:SetCurHealth(ent:GetStartHealth())
        ent:SetShieldHealth(ent:GetStartShieldHealth())
    end
})
