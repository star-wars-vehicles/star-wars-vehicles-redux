--- SWVR enumerations and constants
-- @module swvr
-- @author Doctor Jew

swvr = swvr or {}

--- SWVR enumerations and constants
local enum = {}

--- Contains shorthand to full allegiance name mapping
enum.Allegiances = {
  REP = "Galactic Republic", -- Galactic Republic
  EMP = "Galactic Empire", -- Galactic Empire
  CIS = "Confederacy of Independent Systems", -- Confederacy of Independent Systems
  FO = "First Order", -- First Order
  REB = "Rebel Alliance", -- Rebel Alliance
  NEU = "Neutral", -- Neutral
  IND = "Independent", -- Independent
  DEV = "In Development" -- In Development
}

--- Maps allegiances to side numerical constants
-- @field 1 Neutral allegiances
-- @field 2 Light allegiances
-- @field 3 Dark allegiances
enum.Sides = {
  { swvr.enum.Allegiances.NEU, swvr.enum.Allegiances.IND, swvr.enum.Allegiances.DEV },
  { swvr.enum.Allegiances.REP, swvr.enum.Allegiances.REB },
  { swvr.enum.Allegiances.EMP, swvr.enum.Allegiances.CIS, swvr.enum.Allegiances.FO }
}

--- Landing surfaces that vehicles can land on
enum.LandingSurfaces = {
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

enum.LfsTeam = {
  [1] = 3,
  [2] = 2
}

swvr.enum = enum
