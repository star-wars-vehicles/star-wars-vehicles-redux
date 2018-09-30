ENT.Base = "swvr_base"

ENT.Category = "CIS"
ENT.Class = "Interceptor"

ENT.PrintName = "Droid Tri-Fighter"
ENT.Author = "Doctor Jew"

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
        self:Setup({
            Model = "models/tri/tri1.mdl",
            Health = 750,
            Speed = 1500,
            BoostSpeed = 2250,
            VerticalSpeed = 550,
            Acceleration = 9,
            Roll = true,
        })

        self:AddWeaponGroup("Pilot", "ls1_cannon", {
            Delay = 0.1,
            Damage = 25,
            CanOverheat = true,
            MaxOverheat = 20
        })

        self:AddWeapon("Pilot", "MainT", Vector(102, 3, 195))
        self:AddWeapon("Pilot", "MainR", Vector(102, 84, 43))
        self:AddWeapon("Pilot", "MainL", Vector(102, -87, 43))

        self:AddWeaponGroup("Center", "gn40_cannon", {
            Delay = 0.5,
            Damage = 80,
            CanOverheat = true,
            MaxOverheat = 10,
            Cooldown = 10
        })

        self:AddWeapon("Center", "Center", Vector(170, 3, 100))

        self:AddPilot(nil, nil, {
            FPVPos = Vector(100, 3, 120),
            Weapons = { "Pilot", "Center" }
        })

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            Cockpit = "vgui/droid_cockpit",
            AlwaysDraw = true,
            EngineSound = "vehicles/droid/droid_fly.wav",
            ViewDistance = 700,
            ViewHeight = 200
        })

        self:SetupDefaults()

        self:AddEngine(Vector(-170, 30, 75), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-170, 3, 130), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-170, -27, 75), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self.BaseClass.Initialize(self)
    end
end
