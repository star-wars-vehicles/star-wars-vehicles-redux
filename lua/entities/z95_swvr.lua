ENT.Base = "swvr_base"

ENT.Category = "Rebels"
ENT.Class = "Fighter"

ENT.PrintName = "Z-95 Headhunter"
ENT.Author = "Doctor Jew"

if SERVER then
    AddCSLuaFile()

    function ENT:SpawnFunction(ply, tr, ClassName)
        if not tr.Hit then
            return
        end

        local ent = ents.Create(ClassName)
        ent:SetPos(tr.HitPos)
        ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:Initialize()
        self:Setup({
            Model = "models/z95/z951.mdl",
            Health = 1500,
            Speed = 1250,
            BoostSpeed = 2500,
            VerticalSpeed = 600,
            Acceleration = 8,
            Roll = true,
        })

        self:AddWeaponGroup("Pilot", "kx5_cannon", {
            Delay = 0.2,
            Damage = 75,
            CanOverheat = true,
            MaxOverheat = 20
        })

        self:AddWeapon("Pilot", "Left", Vector(70, -212.5, 65))
        self:AddWeapon("Pilot", "Right", Vector(70, 212.5, 65))

        self:AddPilot(nil, nil, {
            Weapons = { "Pilot" },
            ExitPos = Vector(0, -325, 100)
        })

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            EngineSound = "ywing_engine_loop",
            ViewDistance = 800,
            ViewHeight = 200
        })

        self:SetupDefaults()

        self:AddEngine(Vector(-185, 49, 42.5), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-185, -49, 42.5), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-185, 49, 75), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-185, -49, 75), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(150, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self.BaseClass.Initialize(self)
    end
end
