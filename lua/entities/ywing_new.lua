ENT.Base = "swvr_base"
ENT.Category = "Rebels"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.PrintName = "BTL-A4 Y-Wing"
ENT.Author = "Doctor Jew"
ENT.WorldModel = "models/ywing/ywing1.mdl"
ENT.Vehicle = "YWingNew"
ENT.Allegiance = "Rebels"
ENT.Class = "Bomber"

util.PrecacheModel("models/ywing/ywing1.mdl")

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
            health = 1500,
            shields = 0,
            speed = 1250,
            boostspeed = 2100,
            verticalspeed = 500,
            acceleration = 7,
            roll = true
        })

        self:AddWeaponGroup("Main", "rg9_cannon", {
            Delay = 0.2,
            Damage = 85,
            CanOverheat = true,
            MaxOverheat = 10
        })

        self:AddWeapon("Main", "MainR", Vector(200, 18, 50))
        self:AddWeapon("Main", "MainL", Vector(200, -18, 50))

        self:AddWeaponGroup("Turret", "rg9_cannon", {
            Delay = 0.5,
            Damage = 40,
            Tracer = "blue_tracer_fx"
        })

        self:AddWeapon("Turret", "Left", Vector(80, -4, 100))
        self:AddWeapon("Turret", "Right", Vector(80, 4, 100))

        self:AddPilot(nil, nil, {
            FPVPos = Vector(96, 0, 88),
            Weapons = {"Main", "Turret"}
        })

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            Cockpit = "vgui/ywing_cockpit",
            EngineSound = "vehicles/xwing/xwing_fly2.wav",
            ViewDistance = 700,
            ViewHeight = 200
        })

        self:SetupDefaults()

        self:AddEngine(Vector(-270, 122, 53), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(255, 100, 100),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-270, -122, 53), {
            StartSize = 15,
            EndSize = 13.5,
            Lifetime = 2.7,
            Color = Color(255, 100, 100),
            Sprite = "sprites/orangecore1"
        })

        self.BaseClass.Initialize(self)
    end
end
