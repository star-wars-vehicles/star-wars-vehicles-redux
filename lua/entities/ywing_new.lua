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

list.Set("SWVRVehicles", ENT.Folder, ENT)
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
            Tracer = "blue_tracer_fx"
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
            fpvpos = Vector(96, 0, 88),
            weapons = {"Main", "Turret"}
        })

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            cockpit = "vgui/ywing_cockpit",
            enginesound = "vehicles/xwing/xwing_fly2.wav",
            viewdistance = 700,
            viewheight = 200
        })

        self:SetupDefaults()

        self:AddEngine(Vector(-270, 122, 53), {
            startsize = 15,
            endsize = 13.5,
            lifetime = 2.7,
            color = Color(255, 100, 100),
            sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-270, -122, 53), {
            startsize = 15,
            endsize = 13.5,
            lifetime = 2.7,
            color = Color(255, 100, 100),
            sprite = "sprites/orangecore1"
        })

        self.BaseClass.Initialize(self)
    end
end
