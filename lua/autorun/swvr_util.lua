--- SWVR utility  functions
-- @module swvr
-- @author Doctor Jew

swvr = swvr or {}

--- SWVR utility functions
local util = {}

--- Generate a transponder for an entity.
-- @entity The entity to use to generate
-- @treturn string The transponder code
function util.GenerateTransponder(entity)
  local steamid = entity:GetCreator():SteamID()

  if (steamid == "STEAM_ID_PENDING") then
    steamid = "STEAM_0:0:00000"
  end

  local transponder = hook.Run("SWVR.GenerateTransponder", steamid)
  local code = string.upper(string.sub(string.gsub(string.gsub(entity.PrintName, " ", ""), "-", ""), 0, 3))
  steamid = string.sub(string.Split(steamid, ":")[3], 1, 4)

  if transponder and isstring(transponder) then
    code = transponder
  end

  return code .. " " .. steamid .. util.CountOwnedEntities(entity:GetClass(), entity:GetCreator())
end

function util.CountOwnedEntities(ply, class)
  local count = 0

  for k, v in pairs(isstring(class) and ents.FindByClass(class) or ents.GetAll()) do
    if (v:GetCreator() == ply) then
      count = count + 1
    end
  end

  return count
end

function util.AccessorBool(tbl, name, prefix)
  tbl[prefix .. name] = function(self, value)
    if value == nil then
      return tobool(self["Get" .. name](self))
    end

    self["Set" .. name](self, value)
  end
end

swvr.util = util
