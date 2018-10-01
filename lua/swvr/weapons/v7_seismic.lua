local WEAPON = {}

DEFINE_BASECLASS("swvr_base_weapon")

WEAPON.Base = "swvr_base_weapon"
WEAPON.Type = "bomb"

WEAPON.Name = "Void-7 Laser Cannon"
WEAPON.Author = "Krupx Munitions"

WEAPON.Model = Model("models/props/starwars/weapons/seismic_charge.mdl")

function WEAPON:Initialize()
	BaseClass.Initialize(self)
end

function WEAPON:Fire()
	local charge = ents.Create("prop_dynamic")
	charge:SetModel(self.Model)
	charge:SetPos(self:GetPos())
	charge:Spawn()
	charge:EmitSound("v7_seismic_pass")

	timer.Simple(5, function()
		charge:EmitSound("v7_seismic_pre")

		hook.Add("EntityEmitSound", "SWVR.SeismicCharge." .. charge:EntIndex(), function(data)
			if not (data.Pos or IsValid(data.Entity)) then return end -- Yikes, we can't do anything then

			if data.Pos then
				if IsValid(data.Entity) and charge:GetPos():DistToSqr(data.Pos) <= 700000 and data.Entity:EntIndex() ~= charge:EntIndex() then return false end

				return charge:GetPos():DistToSqr(data.Pos) > 700000
			end

			if IsValid(data.Entity) and data.Entity:EntIndex() ~= charge:EntIndex() then
				return charge:GetPos():DistToSqr(data.Entity:GetPos()) > 700000
			end
		end)

		hook.Add("PlayerFootstep", "SWVR.SeismicCharge." .. charge:EntIndex(), function(ply, pos)
			if charge:GetPos():DistToSqr(pos) <= 700000 then return true end
		end)

		net.Start("SeismicCharge")
			net.WriteBool(false)
			net.WriteUInt(charge:EntIndex(), 8)
		net.Broadcast()

		timer.Simple(0.86, function()
			timer.Simple(3, function()
				hook.Remove("EntityEmitSound", "SWVR.SeismicCharge." .. charge:EntIndex())
				hook.Remove("PlayerFootstep", "SWVR.SeismicCharge." .. charge:EntIndex())
			end)


			net.Start("SeismicCharge")
				net.WriteBool(true)
				net.WriteUInt(charge:EntIndex(), 8)
			net.Broadcast()

			charge:EmitSound("v7_seismic_charge")

			util.BlastDamage(charge, self:GetOwner(), charge:GetPos(), 500, 400)

			charge:SetColor(Color(255, 255, 255, 0))
			charge:SetRenderMode(RENDERMODE_TRANSALPHA)

			SafeRemoveEntityDelayed(charge, 4)
		end)
	end)

	BaseClass.Fire(self)
end

SWVR.Weapons:Register(WEAPON, "v7_seismic")

if SERVER then
	util.AddNetworkString("SeismicCharge")

	sound.Add({
		name = "v7_seismic_pre",
		channel = CHAN_AUTO,
		volume = 1,
		level = 100,
		pitch = { 95, 110 },
		sound = "swvr/abilities/swvr_seismic_pre.wav"
	})

	sound.Add({
		name = "v7_seismic_pass",
		channel = CHAN_AUTO,
		volume = 1,
		level = 100,
		pitch = { 95, 110 },
		sound = "swvr/abilities/swvr_seismic_pass.wav"
	})

	sound.Add({
		name = "v7_seismic_charge",
		channel = CHAN_AUTO,
		volume = 1,
		level = 100,
		pitch = { 95, 110 },
		sound = "swvr/abilities/swvr_seismic_charge.wav"
	})
end

if CLIENT then
	game.AddParticles("particles/gb5_emp.pcf")
	PrecacheParticleSystem("emp_main")

	net.Receive("SeismicCharge", function()
		local stop = net.ReadBool()
		local index = net.ReadUInt(8)
		local charge = Entity(index)

		if stop then
			hook.Remove("Think", "SWVR.SeismicCharge." .. index)

			-- Let's just make sure
			timer.Simple(1, function()
				hook.Remove("EntityEmitSound", "SWVR.SeismicCharge." .. index)
				hook.Remove("PlayerFootstep", "SWVR.SeismicCharge." .. index)

				for k, v in pairs(ents.GetAll()) do
					if not v.IsSWVRVehicle then continue end
					v.SoundDisabled = false
				end
			end)

			return
		end

		ParticleEffect("emp_main", charge:GetPos(), charge:GetAngles(), charge)

		hook.Add("EntityEmitSound", "SWVR.SeismicCharge." .. index, function(data)
			if not (data.Pos or IsValid(data.Entity)) then return end -- Yikes, we can't do anything then

			if data.Pos then
				if IsValid(data.Entity) and charge:GetPos():DistToSqr(data.Pos) <= 700000 and data.Entity:EntIndex() ~= charge:EntIndex() then return false end

				return charge:GetPos():DistToSqr(data.Pos) > 700000
			end

			if IsValid(data.Entity) and data.Entity:EntIndex() ~= charge:EntIndex() then
				return charge:GetPos():DistToSqr(data.Entity:GetPos()) > 700000
			end
		end)

		hook.Add("PlayerFootstep", "SWVR.SeismicCharge." .. index, function(ply, pos)
			if charge:GetPos():DistToSqr(pos) <= 700000 then return true end
		end)

		hook.Add("Think", "SWVR.SeismicCharge." .. index, function()
			for k, v in pairs(ents.GetAll()) do
				if not v.IsSWVRVehicle then continue end

				local disabled = charge:GetPos():DistToSqr(v:GetPos()) <= 700000
				v:StopClientsideSound("Engine")
				v.SoundDisabled = disabled
			end
		end)
	end)
end
