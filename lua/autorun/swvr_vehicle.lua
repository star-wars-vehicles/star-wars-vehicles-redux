if SERVER then
	function SWVR_Create(data)
		local vehicle = ents.Create(data.entity)
		vehicle.name = data.entity
		vehicle.WorldModel = data.model
		vehicle.Overheat = data.overheat or true
		vehicle.OverheatAmount = data.overheat_amount or 50
		vehicle.CapitalShip = data.capital_ship or false
		vehicle.Hyperdrive = data.hyperdrive or false
		vehicle.Seats = data.seats or nil

		if vehicle.CapitalShip then
			vehicle.Eject = false
		else
			vehicle.Eject = data.eject
		end

		sound.Add({
			name = vehicle.name .. "_fire",
			channel = CHAN_WEAPON,
			volume = 1.0,
			level = 100,
			pitch = {95, 105},
			sound = data.sounds.fire
		})

		sound.Add({
			name = vehicle.name .. "_engine",
			channel = CHAN_STATIC,
			volume = 1.0,
			level = 100,
			pitch = 100,
			sound = data.sounds.engine
		})

		sound.Add({
			name = vehicle.name .. "_torpedo",
			channel = CHAN_WEAPON,
			volume = 1.0,
			level = 100,
			pitch = {90, 110},
			sound = data.sounds.torpedo or "weapons/proton_torpedo.wav"
		})

		vehicle.Cooldown = {
			wings = CurTime(),
			use = CurTime(),
			fire = CurTime(),
			mode = CurTime(),
			torpedo = CurTime(),
			dock = CurTime(),
			lock = CurTime(),
			correct = CurTime(),
			hyperdrive = CurTime(),
			switch = CurTime(),
			view = CurTime()
		}

		vehicle.Allegiance = data.allegiance or "Neutral"
		vehicle.FlightModel = data.flight_model or nil
		vehicle.StartHealth = data.health or 700
		vehicle.FirstPerson = data.fpv or nil

		vehicle.Bullet = data.weapons.bullet or swvr.get_bullet{
			color = "blue",
			damage = 75
		}

		return vehicle
	end
end