ENT.Base = "swvr_base"
ENT.Category = "In Development"

ENT.PrintName = "RZ-1 A-Wing"
ENT.Author = "Doctor Jew"

ENT.Class = "Interceptor"

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
        -- Call setup to initialize ship limitations
        self:Setup({
            Model = "models/awing/awing_bf2.mdl",
            Health = 1000,
            Shields = 600,
            Speed = 1500,
            VerticalSpeed = 550,
            Acceleration = 7,
            Back = false,
            Roll = true,
            Freelook = true
        })

        -- Adding a weapon group. Must be done BEFORE weapons are added to it.
        self:AddWeaponGroup("Pilot", "weapons/rz2_shoot.wav", {
            Damage = 50,
            Color = "red",
            Delay = 0.12,
            OverheatAmount = 40
        })

        -- Adding weapons
        self:AddWeapon("Pilot", "Right", Vector(120, 87, 45))
        self:AddWeapon("Pilot", "Left", Vector(120, -87, 45))

        -- Please note, if you are adding a seat/pilot with weapon groups, those groups must be added BEFORE (the weapons can be added to the groups whenever)
        -- Setting up the pilot seat.
        --- self:AddPilot(exitpos, fpvpos, pilotpos, pilotang, weapon(s)...)
        self:AddPilot(Vector(-20, 0, 35), nil, {
            ExitPos = Vector(-180, 0, 0),
            FPVPos = Vector(-15, 0, 75),
            Weapons = {"Pilot"}
        })

        self:AddEvent("OnCritical", function()
            self:EmitSound("startrek/ships/kelvin/torpedo/hit0" .. tostring(math.Round(math.random(1, 4))) .. ".wav", 500, 255, 1, CHAN_AUTO)
        end, false)

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end

if CLIENT then
    function ENT:Initialize()
        self:Setup({
            ViewDistance = 950,
            ViewHeight = 200,
            Cockpit = {
                Path = "models/awing/new_awing_cockpit.mdl"
            },
            EngineSound = "vehicles/rz2_engine_loop.wav"
        })

        self:SetupDefaults()

        -- Adding engine effects
        self:AddEngine(Vector(-105, 42, 40), {
            StartSize = 18,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 204, 102),
            Sprite = "sprites/orangecore1"
        })

        self:AddEngine(Vector(-105, -42, 40), {
            StartSize = 18,
            EndSize = 10,
            Lifetime = 2.7,
            Color = Color(255, 204, 102),
            Sprite = "sprites/orangecore1"
        })

        self:AddEvent("OnCritical", function()
            if LocalPlayer():GetNWEntity("Ship") ~= self then
                return
            end

            surface.PlaySound("atat/atat_shoot.wav")
        end)

        -- Initialize the base, do not remove.
        self.BaseClass.Initialize(self)
    end
end
