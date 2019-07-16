--- SWVR enumerations and constants
-- @module swvr
-- @author Doctor Jew

swvr = swvr or {}

swvr.Allegiances = swvr.Allegiances or {}
swvr.Sides = swvr.Sides or {}
swvr.AllegianceMap = swvr.AllegianceMap or {}


--- Retrieve all valid Allegiances
-- @shared
-- @treturn table Table of all valid registered Allegiances
function swvr.GetAllegiances()
  return swvr.Allegiances
end

function swvr.RegisterSide(side)
  assert(isstring(side), "Cannot register side with name of type \"" .. type(side) .. "\"! Side names must be of type \"string\".")

  for i, v in ipairs(swvr.Sides) do
    if string.upper(v) == string.upper(side) then return i end
  end

  swvr.Sides[#swvr.Sides + 1] = side

  swvr.AllegianceMap[string.upper(side)] = {}

  return #swvr.Sides
end

function swvr.RegisterAllegiance(name, side)
  assert(isstring(name), "Cannot register allegiance with name of type \"" .. type(side) .. "\"! Side names must be of type \"string\".")
  assert(isstring(side) or isnumber(side), "Cannot register allegiance with side of type \"" .. type(side) .. "\"! Side names must be of type \"string\" or \"number\".")

  for i, v in ipairs(swvr.Allegiances) do
    if isnumber(side) then
      if string.upper(v) == string.upper(name) then return i end
    elseif isstring(side) then
      if string.upper(v) == string.upper(side) then return i end
    end
  end

  swvr.Allegiances[#swvr.Allegiances + 1] = name

  if isnumber(side) then
    for i, v in ipairs(swvr.Sides) do
      if i == side then table.insert(swvr.AllegianceMap[v:upper()], name) end
    end
  elseif isstring(side) then
    for _, v in ipairs(swvr.Sides) do
      if v:lower() == side:lower() then table.insert(swvr.AllegianceMap[side:upper()], name) break end
    end
  end

  return #swvr.Allegiances
end

--- Get the side of an entity (light, dark, or neutral).
-- @shared
-- @param value An `Entity` or `string` to get the side value of.
-- @treturn number The side enumeration value
function swvr.GetSide(value)
  if isstring(value) then
    for i, side in ipairs(swvr.Sides) do
      for _, al in ipairs(swvr.AllegianceMap[side:upper()]) do
        if string.match(string.upper(al), string.upper(value)) then return i end
      end
    end
  elseif isentity(value) and value.GetAllegiance then
    return swvr.GetSide(value:GetAllegiance())
  elseif isnumber(value) then
    return math.Clamp(value, 1, #swvr.Sides)
  end

  -- All else fails return neutral
  return 1
end

function swvr.GetAllegiance(value)
  if isentity(value) and value.GetAllegiance then
    return value:GetAllegiance()
  elseif isstring(value) then
    for i, a in ipairs(swvr.Allegiances) do
      if string.match(string.upper(a), string.upper(value)) then return i end
    end
  elseif isnumber(value) then
    return math.Clamp(value, 1, #swvr.Allegiances)
  end

  return 1
end

SWVR_SIDE_INDEPENDENT = swvr.RegisterSide("Independent")
SWVR_SIDE_LIGHT = swvr.RegisterSide("Light")
SWVR_SIDE_DARK = swvr.RegisterSide("Dark")

SWVR_ALLEG_REPUBLIC = swvr.RegisterAllegiance("Galactic Republic", SWVR_SIDE_LIGHT)
SWVR_ALLEG_REBELS = swvr.RegisterAllegiance("Rebel Alliance", SWVR_SIDE_LIGHT)
SWVR_ALLEG_EMPIRE = swvr.RegisterAllegiance("Galactic Empire", SWVR_SIDE_DARK)
SWVR_ALLEG_CIS = swvr.RegisterAllegiance("Confederacy of Independent Systems", SWVR_SIDE_DARK)
SWVR_ALLEG_FO = swvr.RegisterAllegiance("First Order", SWVR_SIDE_DARK)
SWVR_ALLEG_NEUTRAL = swvr.RegisterAllegiance("Neutral", SWVR_SIDE_INDEPENDENT)
SWVR_ALLEG_INDEPENDENT = swvr.RegisterAllegiance("Independent", SWVR_SIDE_INDEPENDENT)
SWVR_ALLEG_DEVELOPMENT = swvr.RegisterAllegiance("In Development", SWVR_SIDE_INDEPENDENT)

SWVR_STATE_FLIGHT = 0
SWVR_STATE_TAKEOFF = 1
SWVR_STATE_LANDING = 2
SWVR_STATE_IDLE = 3
