if CLIENT then
	surface.CreateFont("HUD_Health", {
		font = "Arial",
		size = ScrH() / 60,
		weight = 1000,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = true,
		rotary = false,
		shadow = false,
		additive = true,
		--outline = true,
		outline = false
	})

	surface.CreateFont("HUD_Altimeter", {
		font = "Arial",
		size = ScrH() / 60,
		weight = 1000,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false
	})

	surface.CreateFont("HUD_Transponder", {
		font = "Arial",
		size = ScrH() / 65,
		weight = 1000,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false
	})
end
