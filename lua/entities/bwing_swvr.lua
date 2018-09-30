ENT.Base = "swvr_base"

ENT.Category = "In Development"
ENT.Class = "Bomber"

ENT.PrintName = "A/SF-01 B-Wing"
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
            Model = "models/bwing/bwing.mdl",
            Health = 2500,
            Speed = 1250,
            BoostSpeed = 2500,
            VerticalSpeed = 700,
            Acceleration = 8,
            Roll = true
        })

        self:AddWeaponGroup("Pilot", "rg9_cannon", {
            Delay = 0.15,
            Damage = 50,
            CanOverheat = true,
            MaxOverheat = 40
        })

        self:AddWeapon("Pilot", "MainTop", Vector(175, -890, 205))
        self:AddWeapon("Pilot", "MainBot", Vector(175, -890, 150))

        self:AddWeaponGroup("Cockpit", "rg9_cannon", {
            Delay = 0.5,
            Damage = 30,
        })

        self:AddWeapon("Cockpit", "Left", Vector(140, -22.5, 158))
        self:AddWeapon("Cockpit", "Right", Vector(140, -9, 158))

        self:AddPilot(nil, nil, {
            FPVPos = Vector(96, 0, 88),
            Weapons = {"Pilot", "Cockpit"}
        })

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            EngineSound = "ambient/atmosphere/ambience_base.wav",
            ViewDistance = 700,
            ViewHeight = 200
        })

        self:SetupDefaults()

        self:AddEngine(Vector(-170, -188, 205), {
            StartSize = 30,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-170, -243, 205), {
            StartSize = 30,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-170, -188, 150), {
            StartSize = 30,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-170, -243, 150), {
            StartSize = 30,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 100, 0),
            Sprite = "sprites/orangecore1"
        })

        self.BaseClass.Initialize(self)
    end
end
