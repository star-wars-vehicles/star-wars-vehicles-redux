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

enum.State = {
  Flight = 0,
  Takeoff = 1,
  Landing = 2,
  Idle = 3
}

--- Maps allegiances to side numerical constants
enum.Sides = {
  [1] = { enum.Allegiances.NEU, enum.Allegiances.IND, enum.Allegiances.DEV }, -- Neutral, Independent, In Development
  [2] = { enum.Allegiances.REP, enum.Allegiances.REB }, -- Galactic Republic, Rebel Alliance
  [3] = { enum.Allegiances.EMP, enum.Allegiances.CIS, enum.Allegiances.FO } -- Galactic Empire, Confederacy of Independent Systems, First Order
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

swvr.enum = enum
