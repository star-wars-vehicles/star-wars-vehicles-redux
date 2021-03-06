--- SWVR Base Module
-- @author Doctor Jew
-- @module swvr

swvr = swvr or {}

--- Current SWVR version
swvr.Version = 48

--- Author of SWVR
swvr.Author = "Doctor Jew"

AddCSLuaFile("swvr_enum.lua")
AddCSLuaFile("swvr_menu.lua")
AddCSLuaFile("swvr_meta.lua")
AddCSLuaFile("swvr_util.lua")

include("swvr_enum.lua")
include("swvr_menu.lua")
include("swvr_meta.lua")
include("swvr_util.lua")

local LAND_SURFACES = {
  ["prop_physics"] = true,
  ["func_rotating"] = true,
  ["func_movelinear"] = true,
  ["func_tracktrain"] = true,
  ["func_door_rotating"] = true,
  ["func_door"] = true,
  ["func_brush"] = true,
  ["func_conveyor"] = true,
  ["func_reflective_glass"] = true
}

--- Retrieve all existing SWVR vehicles
-- @shared
-- @treturn table Table of `Entity` classes
function swvr.GetVehicles()
  local vehicles = {}
  for _, ent in ipairs(ents.GetAll()) do
    if not ent.IsSWVRVehicle then continue end

    vehicles[#vehicles + 1] = ent
  end

  return vehicles
end

--- Retrieve all players current in a SWVR vehicle
-- @shared
-- @treturn table Table of Players
-- @usage for _, ply in ipairs(swvr.GetPlayers()) do
-- 	print(ply:SteamID64())
-- end
function swvr.GetPlayers()
  local players = {}
  for _, ply in ipairs(player.GetAll()) do
    local vehicle = ply:GetVehicle()

    if not (IsValid(vehicle) and IsValid(vehicle:GetNWBool("SWVRSeat", NULL))) then continue end

    players[#players + 1] = ply
  end

  return players
end

function swvr.GetLandingSurfaces()
  return LAND_SURFACES
end

--- Retrieve the cached config value for better performance
-- @shared
-- @string key The category or sub-category to retrieve
-- @param default Default value returned in case key is not found
-- @return The retrieved value if found or the default
-- @usage local value = swvr.Config("volume.engine", 100)
function swvr.Config(key, default)
  local cat, sub = string.match(key, "([a-z]+).([a-z]*)")

  local tbl = swvr.config[cat]

  if sub then
    if tbl == nil then
      tbl = {}
    end

    return Either(tbl[sub] ~= nil, tbl[sub], default)
  end

  return Either(tbl ~= nil, tbl, default)
end

--- Configuration cache
-- @field volume Volume levels for sounds
-- @field hud HUD settings, such as color or components
swvr.config = swvr.config or {}

if CLIENT then
  swvr.config.volume = {
    effect = cvars.Number("swvr_effect_volume", 100),
    engine = cvars.Number("swvr_engine_volume", 100)
  }

  for cvar in pairs(swvr.config.volume) do
    cvars.AddChangeCallback("swvr_" .. cvar .. "_volume", function(name, old, new)
      swvr.config.volume[cvar] = new
    end)
  end

  swvr.config.hud = {
    color = Color(cvars.Number("swvr_hud_color_r"), cvars.Number("swvr_hud_color_g"), cvars.Number("swvr_hud_color_b"), cvars.Number("swvr_hud_color_a"))
  }

  for _, cvar in ipairs({"r", "g", "b", "a"}) do
    cvars.AddChangeCallback("swvr_hud_color_" .. cvar, function(name, old, new)
      swvr.config.hud.color = Color(cvars.Number("swvr_hud_color_r"), cvars.Number("swvr_hud_color_g"), cvars.Number("swvr_hud_color_b"), cvars.Number("swvr_hud_color_a"))
    end)
  end

  swvr.config.debug = {
    visuals = cvars.Bool("swvr_debug_visuals"),
    statistics = cvars.Bool("swvr_debug_statistics")
  }

  for cvar in pairs(swvr.config.debug) do
    cvars.AddChangeCallback("swvr_debug_" .. cvar, function(name, old, new)
      swvr.config.debug[cvar] = new
    end)
  end
end

if CLIENT then
  surface.CreateFont("SWVR_Health", {
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

  surface.CreateFont("SWVR_Altimeter", {
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

  surface.CreateFont("SWVR_Transponder", {
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

  surface.CreateFont( "SWVR_Debug", {
    font = "Verdana",
    extended = false,
    size = 20,
    weight = 2000,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
  })
end

sound.Add({
  name = "YWING_ENGINE",
  channel = CHAN_STATIC,
  volume = 1.0,
  level = 125,
  pitch = 100,
  sound = "swvr/vehicles/ywing_eng_loop2.wav"
})

sound.Add({
  name = "ENGINE_START_COLD",
  channel = CHAN_STATIC,
  volume = 1.0,
  level = 100,
  pitch = 100,
  sound = "swvr/shared/swvr_startup.wav"
})

sound.Add({
  name = "ENGINE_SHUTDOWN",
  channel = CHAN_STATIC,
  volume = 1.0,
  level = 100,
  pitch = 100,
  sound = "swvr/shared/swvr_shutdown.wav"
})

sound.Add({
  name = "ENGINE_SHUTDOWN2",
  channel = CHAN_STATIC,
  volume = 1.0,
  level = 100,
  pitch = 100,
  sound = "swvr/shared/swvr_shutdown2.wav"
})
