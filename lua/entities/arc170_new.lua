ENT.Base = "swvr_base"
ENT.Category = "In Development"

ENT.PrintName = "ARC-170"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/arc170/arc170_bf2.mdl"
ENT.FlightModel = "models/arc170/arc170_bf2_wings.mdl"

ENT.Class = "Fighter"

if SERVER then
    AddCSLuaFile()

    function ENT:SpawnFunction(ply, tr, ClassName)
        if not tr.Hit then
            return
        end

        local ent = ents.Create(ClassName)
        ent:SetPos(tr.HitPos + tr.HitNormal * 5)
        ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:Initialize()
        -- MUST call setup to initialize ship limitations
        self:Setup{
            health = 1000,
            speed = 1500,
            shields = 800,
            verticalspeed = 550,
            acceleration = 6,
            back = true,
            freelook = true,
            roll = false
        }

        -- Adding a weapon group. Must be done BEFORE weapons are added to it.
        self:AddWeaponGroup("Pilot", "ywing_fire", self:InitBullet{
            damage = 80,
            color = "green",
            delay = 0.15,
            overheatAmount = 25
        })

        local torpedo = self:InitProtonTorpedo()
        torpedo.Overheat = false
        self:AddWeaponGroup("Torpedo", "proton_torpedo", torpedo)

        self:AddWeaponGroup("Back", "ywing_fire", self:InitBullet{
            damage = 75,
            color = "green",
            delay = 0.3,
            track = true
        })

        -- Adding weapons
        self:AddWeapon("Pilot", "Right", Vector(250, 390, 20))
        self:AddWeapon("Pilot", "Left", Vector(250, -390, 20))
        self:AddWeapon("Torpedo", "Front", Vector(530, 0, -40))

        -- Please note, if you are adding a seat/pilot with weapon groups, those groups must be added BEFORE (the weapons can be added to the groups whenever)
        -- Setting up the pilot seat.
        self:AddPilot(Vector(22, 0, 90), nil, {
            exitpos = Vector(-400, 0, 0),
            fpvpos = Vector(30, 0, 125),
            weapons = {"Pilot", "Torpedo"}
        })

        -- Adding a seat.
        self:AddSeat("Back", Vector(-180, 0, 110), self:GetAngles() + Angle(0, 90, 0), {
            visible = false,
            exitpos = Vector(0, 35, -20),
            weapons = {"Back"}
        })

        -- Adding a part with a parent that is another part, by default the parent is the ship
        self:AddPart("Wings", "models/arc170/arc170_bf2_wings.mdl")

        self:AddPart("GuardTop", "models/arc170/arc170_bf2_guard_top.mdl", Vector(-213.2, 0, 136), nil, {
            seat = "Back",
            callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()

                return nil, Angle(ship:GetAngles().p, aim.y + 180, ship:GetAngles().r)
            end
        })

        self:AddPart("GuardBottom", "models/arc170/arc170_bf2_guard_bottom.mdl", Vector(-206.53, 0, 91.43), nil, {
            seat = "Back",
            callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()

                return nil, Angle(ship:GetAngles().p, aim.y + 180, ship:GetAngles().r)
            end
        })

        self:AddPart("GunTop", "models/arc170/arc170_bf2_gun_top.mdl", Vector(-215.17, 0, 143.33), nil, {
            parent = "GuardTop",
            seat = "Back",
            callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()
                local p = aim.p * -1

                return nil, Angle(p, aim.y + 180, 0)
            end
        })

        self:AddPart("GunBot", "models/arc170/arc170_bf2_gun_bottom.mdl", Vector(-208.29, 0, 89.3), nil, {
            parent = "GuardTop",
            seat = "Back",
            callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()
                local p = aim.p * -1

                return nil, Angle(p, aim.y + 180, 0)
            end
        })

        self:AddWeapon("Back", "Top", Vector(-300, 0, 143.33), {
            parent = "GunTop"
        })

        self:AddWeapon("Back", "Bottom", Vector(-293, 0, 89.3), {
            parent = "GunBot"
        })

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            viewdistance = 1200,
            viewheight = 200,
            cockpit = {
                path = "models/arc170/arc170_bf2_cockpit.mdl"
            },
            enginesound = "ywing_engine_loop"
        })

        self:SetupDefaults()

        -- Adding a clientside sound
        -- self:AddSound("Engine", "ywing_engine_loop")

        -- Adding a clientside part
        -- self:AddPart("Cockpit", "models/arc170/arc170_bf2_cockpit.mdl")

        -- Adding engine effects
        self:AddEngine(Vector(-240, 85, 90), {
            startsize = 15,
            endsize = 10,
            lifetime = 2.7,
            color = Color(255, 40, 40),
            sprite = "sprites/bluecore"
        })

        self:AddEngine(Vector(-240, -85, 90), {
            startsize = 15,
            endsize = 10,
            lifetime = 2.7,
            color = Color(255, 40, 40),
            sprite = "sprites/bluecore"
        })

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end
