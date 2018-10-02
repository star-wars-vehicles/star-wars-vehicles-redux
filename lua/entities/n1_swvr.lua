ENT.Base = "swvr_base"

ENT.Category = "Republic"
ENT.Class = "Interceptor"

ENT.PrintName = "N-1 Starfighter"
ENT.Author = "Doctor Jew"

if SERVER then
    AddCSLuaFile()

    function ENT:SpawnFunction(ply, tr, ClassName)
        if not tr.Hit then
            return
        end

        local ent = ents.Create(ClassName)
        ent:SetPos(tr.HitPos + Vector(0, 0, 10))
        ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:Initialize()
        self:Setup({
            Model = "models/starwars/syphadias/ships/n1/n1-hull.mdl",
            Health = 1500,
            Shields = 500,
            Speed = 1500,
            BoostSpeed = 2250,
            VerticalSpeed = 550,
            Acceleration = 9,
            Roll = true
        })

        self:AddWeaponGroup("Pilot", "ms4_cannon", {
            Delay = 0.2,
            Damage = 75,
            CanOverheat = true,
            MaxOverheat = 20,
            Tracer = "green_tracer_fx"
        })

        self:AddWeapon("Pilot", "Left", Vector(150, -20, 50))
        self:AddWeapon("Pilot", "Right", Vector(150, 20, 50))

        self:AddPilot(nil, nil, {
            FPVPos = Vector(-31, 0, 67.5),
            Weapons = { "Pilot" },
            ExitPos = Vector(-100, 0, 0)
        })

        self:AddPart("Window", "models/starwars/syphadias/ships/n1/n1-window.mdl")
        self:AddPart("Engines", "models/starwars/syphadias/ships/n1/n1-engines.mdl")
        self:AddPart("R2D2", "models/starwars/syphadias/ships/n1/n1-r2.mdl")
        self:AddPart("Cockpit", "models/starwars/syphadias/ships/n1/n1-cockpit.mdl")

        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            EngineSound = "n1_engine",
            ViewDistance = 575,
            ViewHeight = 125
        })

        self:SetupDefaults()

        self:AddSound("Drone", "n1_drone", {
            Is3D = true,
            Looping = true,
            Volume = 0.3,
            Repeat = true,
            Callback = function(ship)
                return ship:GetFlight()
            end
        })

        self:AddEngine(Vector(36, 145, 32.5), {
            StartSize = 25,
            EndSize = 20,
            Lifetime = 1,
            Color = Color(255, 255, 255),
            Sprite = "sprites/bluecore"
        })

        self:AddEngine(Vector(36, -145, 32.5), {
            StartSize = 25,
            EndSize = 20,
            Lifetime = 1,
            Color = Color(255, 255, 255),
            Sprite = "sprites/bluecore"
        })

        self.BaseClass.Initialize(self)
    end
end
