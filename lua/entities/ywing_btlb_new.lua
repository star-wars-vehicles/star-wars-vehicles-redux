ENT.Base = "swvr_base"
ENT.Category = "Empire"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.PrintName = "Y-Wing BTL-B"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/ywing/ywing_btlb_test.mdl"
ENT.Vehicle = "YWingBtlB"
ENT.Allegiance = "Galactic Empire"
ENT.Class = "Capital"

list.Set("SWVRVehicles", ENT.Folder, ENT)
util.PrecacheModel("models/ywing/ywing_btlb_test_cockpit.mdl")

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
        self:AddWeaponGroup("Pilot", "rg9_cannon", {
            Damage = 80,
            Tracer = "blue_tracer_fx",
            Delay = 0.15
        })

        -- Adding weapons
        self:AddWeapon("Pilot", "Right", Vector(520, 25, 40))
        self:AddWeapon("Pilot", "Left", Vector(520, -25, 40))

        -- self:AddWeaponGroup("Torpedo", "proton_torpedo", {

        -- })

         -- self:AddWeapon("Torpedo", "Front", Vector(530, 0, -40))

        self:AddWeaponGroup("Back", "rg9_cannon", {
            Damage = 75,
            Tracer = "blue_tracer_fx",
            Delay = 0.2,
            --CanLock = true
        })

        -- Please note, if you are adding a seat/pilot with weapon groups, those groups must be added BEFORE (the weapons can be added to the groups whenever)
        -- Setting up the pilot seat.
        self:AddPilot(Vector(300, 0, 60), nil, {
            ExitPos = Vector(-400, 0, 0),
            FPVPos = Vector(300, 0, 95),
            Weapons = {"Pilot"--[[, "Torpedo"]]}
        })

        -- Adding a seat.
        self:AddSeat("Back", Vector(255, 0, 85), self:GetAngles() + Angle(0, 90, 0), {
            Visible = false,
            ExitPos = Vector(0, 35, -20),
            Weapons = {"Back"}
        })

        -- Adding a parent with a custom callback, the callback gets called every tick to update the part's position and angles
        self:AddPart("TurretGuard", "models/ywing/ywing_btlb_turret.mdl", Vector(256, 0, 105), nil, {
            Seat = "Back",
            Callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()

                return nil, Angle(ship:GetAngles().p, aim.y + 180, ship:GetAngles().r)
            end
        })

        -- Adding a part with a parent that is another part, by default the parent is the ship
        self:AddPart("Turret", "models/ywing/ywing_btlb_guns.mdl", Vector(242, 0, 114), nil, {
            Parent = "TurretGuard",
            Seat = "Back",
            Callback = function(ship, part, ply)
                local aim = ply:GetAimVector():Angle()
                local p = aim.p * -1

                return nil, Angle(p, aim.y + 180, 0)
            end
        })

        -- These weapons techincally could have been added before the parts, but good practice says to initialize them AFTER the parent
        local wep = self:AddWeapon("Back", "TurretRight", Vector(195, 18, 120), {
            Parent = "Turret"
        })

        self:AddWeapon("Back", "TurretLeft", Vector(195, -18, 120), {
            Parent = "Turret"
        })

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            viewdistance = 1200,
            viewheight = 375,
            cockpit = {
                path = "models/ywing/ywing_btlb_test_cockpit.mdl"
            },
            enginesound = "vehicles/ywing_eng_loop2.wav"
        })

        self:SetupDefaults()


        self:AddSound("Chatter", {"vehicles/starviper/chatter/attack1.wav", "vehicles/starviper/chatter/formation2.wav", "vehicles/starviper/chatter/moving5.wav", "vehicles/starviper/chatter/rightaway.wav"}, {
            Repeat = true,
            Cooldown = 5
        })

        local engineOptions = {
            startsize = 65,
            endsize = 40,
            lifetime = 2.7,
            color = Color(255, 0, 0),
            spirte = "sprites/bluecore"
        }

        -- Adding engine effects
        self:AddEngine(Vector(-630, 240, 60), engineOptions)
        self:AddEngine(Vector(-630, -240, 60), engineOptions)

        self:AddLight(Vector(-630, 240, 60), {
            size = 100
        })

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end
